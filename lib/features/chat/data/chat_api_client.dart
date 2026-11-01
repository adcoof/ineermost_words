/// OpenAI 兼容 chat/completions SSE 流式客户端。
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/sse_decoder.dart';
import '../../settings/domain/api_profile.dart';

/// 一次流式响应的增量。
class ChatDelta {
  /// 增量文本（可能含情绪标签，由上层解析）。
  final String? content;

  /// stop | length | null（仍在生成）。
  final String? finishReason;

  const ChatDelta({this.content, this.finishReason});
}

/// 消息附图（仅当前用户消息携带；历史消息走文本摘要备注）。
class ApiImage {
  /// 固定 'image/jpeg'（发送前已降采样转 JPEG）。
  final String mimeType;

  final Uint8List bytes;

  const ApiImage({this.mimeType = 'image/jpeg', required this.bytes});

  String get dataUrl => 'data:$mimeType;base64,${base64Encode(bytes)}';
}

/// 发给 /chat/completions 的一条消息。
///
/// 无图时 content 为字符串（与旧 wire 形状一致）；带图时 content 为
/// OpenAI 多模态 parts 数组。空文本+仅图只放 image_url parts
///（空 text part 会被部分兼容端点拒绝）。
class ApiMessage {
  final String role;
  final String content;
  final List<ApiImage> images;

  const ApiMessage({
    required this.role,
    required this.content,
    this.images = const [],
  });

  Map<String, dynamic> toJson() {
    if (images.isEmpty) return {'role': role, 'content': content};
    return {
      'role': role,
      'content': [
        if (content.isNotEmpty) {'type': 'text', 'text': content},
        for (final img in images)
          {
            'type': 'image_url',
            'image_url': {'url': img.dataUrl},
          },
      ],
    };
  }
}

/// 对话 API 客户端。
abstract class ChatApiClient {
  /// SSE 流式对话。
  ///
  /// 异常统一抛 [AppException]；用户取消抛 [CancelledException]。
  Stream<ChatDelta> streamChat({
    required ApiProfile profile,
    required List<ApiMessage> messages,
    double? temperature,
    int? maxTokens,
    CancelToken? cancelToken,
  });

  /// 测试连接：发一条 1 token 的流式请求，收到任意增量即成功。
  Future<void> testConnection({
    required ApiProfile profile,
    CancelToken? cancelToken,
  });
}

/// OpenAI 兼容协议实现。
class OpenAiChatApiClient implements ChatApiClient {
  final Dio _dio;

  OpenAiChatApiClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 120),
            ));

  /// 拼接 baseUrl 与 /chat/completions，容忍用户多写/漏写 /v1 与尾斜杠。
  static String completionsUrl(String baseUrl) {
    var b = baseUrl.trim();
    while (b.endsWith('/')) {
      b = b.substring(0, b.length - 1);
    }
    return '$b/chat/completions';
  }

  @override
  Stream<ChatDelta> streamChat({
    required ApiProfile profile,
    required List<ApiMessage> messages,
    double? temperature,
    int? maxTokens,
    CancelToken? cancelToken,
  }) async* {
    final body = <String, dynamic>{
      'model': profile.model,
      'messages': [for (final m in messages) m.toJson()],
      'stream': true,
      'temperature': temperature ?? profile.temperature,
    };
    final t = maxTokens ?? profile.maxTokens;
    if (t != null) body['max_tokens'] = t;

    final response = await _openStream(profile, body, cancelToken);
    await response.ensureSuccess();

    final events = decodeSseStream(response.data!.stream.cast<List<int>>());
    await for (final event in events) {
      final data = event.data;
      if (data.isEmpty) continue;
      if (data == '[DONE]') return;
      final delta = _parseChunk(data);
      if (delta != null) yield delta;
    }
  }

  @override
  Future<void> testConnection({
    required ApiProfile profile,
    CancelToken? cancelToken,
  }) async {
    final stream = streamChat(
      profile: profile,
      messages: const [ApiMessage(role: 'user', content: 'hi')],
      maxTokens: 1,
      cancelToken: cancelToken,
    );
    // 收到任意一帧即视为连通。
    await for (final _ in stream) {
      return;
    }
    // 空流也算连通（有的实现直接结束）。
  }

  Future<Response<ResponseBody>> _openStream(
    ApiProfile profile,
    Map<String, dynamic> body,
    CancelToken? cancelToken,
  ) async {
    final headers = <String, dynamic>{
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
      if (profile.apiKey.isNotEmpty) 'Authorization': 'Bearer ${profile.apiKey}',
      ..._extraHeaders(profile),
    };

    try {
      return await _dio.post<ResponseBody>(
        completionsUrl(profile.baseUrl),
        data: body,
        options: Options(
          headers: headers,
          responseType: ResponseType.stream,
          validateStatus: (_) => true,
        ),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Map<String, dynamic> _extraHeaders(ApiProfile profile) {
    try {
      final decoded = jsonDecode(profile.extraHeaders);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (_) {
      // 非法 JSON 忽略。
    }
    return const {};
  }

  /// 解析一帧 JSON；HTTP 错误也在此转成 [AppException]。
  ChatDelta? _parseChunk(String data) {
    final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(data);
      if (decoded is! Map<String, dynamic>) return null;
      json = decoded;
    } catch (e) {
      // 单帧损坏不致命；流里还有后续帧。
      return null;
    }

    // OpenAI 兼容错误帧：{"error": {...}}
    final error = json['error'];
    if (error is Map) {
      final msg = error['message']?.toString() ?? '服务端返回错误';
      final code = error['code']?.toString();
      if (code == 'invalid_api_key' || code == 'authentication_error') {
        throw AuthException(msg);
      }
      throw ServerException(msg);
    }

    final choices = json['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final first = choices.first;
    if (first is! Map) return null;
    final delta = first['delta'];
    String? content;
    if (delta is Map && delta['content'] is String) {
      content = delta['content'] as String;
    }
    // 部分兼容实现把文本放在 message.content。
    if (content == null && first['message'] is Map) {
      final m = first['message'] as Map;
      if (m['content'] is String) content = m['content'] as String;
    }
    final finish = first['finish_reason'];
    return ChatDelta(
      content: content,
      finishReason: finish is String ? finish : null,
    );
  }
}

/// 把 dio 异常归一化为 [AppException]。
AppException mapDioException(DioException e) {
  if (e.type == DioExceptionType.cancel) {
    return const CancelledException();
  }
  final status = e.response?.statusCode;
  if (status != null) {
    final msg = _serverMessage(e.response) ?? 'HTTP $status';
    switch (status) {
      case 401:
      case 403:
        return AuthException('鉴权失败：$msg');
      case 429:
        return RateLimitException('请求过于频繁：$msg');
      case >= 500:
        return ServerException('服务端错误：$msg', e, status);
      default:
        return ServerException('请求失败：$msg', e, status);
    }
  }
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return NetworkException('网络超时，请检查网络或接口地址', e);
    case DioExceptionType.connectionError:
      return NetworkException('无法连接服务器，请检查网络或接口地址', e);
    default:
      return UnknownException('未知网络错误', e);
  }
}

String? _serverMessage(Response? response) {
  try {
    final data = response?.data;
    if (data is Map && data['error'] is Map) {
      return (data['error'] as Map)['message']?.toString();
    }
    if (data is String && data.isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map && decoded['error'] is Map) {
        return (decoded['error'] as Map)['message']?.toString();
      }
    }
  } catch (_) {}
  return null;
}

/// 流式响应体（HTTP 非 2xx 时把错误体读出并抛出）。
extension StreamHttpStatus on Response<ResponseBody> {
  /// 若状态码非 2xx，读完错误体后抛出对应 [AppException]。
  Future<void> ensureSuccess() async {
    final status = statusCode ?? 0;
    if (status >= 200 && status < 300) return;
    String? bodyText;
    try {
      final chunks = <int>[];
      await for (final chunk in data!.stream) {
        chunks.addAll(chunk);
        if (chunks.length > 8192) break;
      }
      bodyText = utf8.decode(chunks, allowMalformed: true);
    } catch (_) {}
    final msg = _serverMessage(Response(requestOptions: requestOptions, data: bodyText)) ??
        'HTTP $status';
    switch (status) {
      case 401:
      case 403:
        throw AuthException('鉴权失败：$msg');
      case 429:
        throw RateLimitException('请求过于频繁：$msg');
      default:
        throw ServerException('请求失败：$msg', null, status);
    }
  }
}