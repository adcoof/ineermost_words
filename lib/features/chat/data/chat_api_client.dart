/// OpenAI 兼容 chat/completions SSE 流式客户端。
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/sse_decoder.dart';
import '../../settings/domain/api_profile.dart';

/// 一次流式响应的增量。
class ChatDelta {
  /// 增量正文（可能含情绪标签，由上层解析）。
  ///
  /// 推理内容（`reasoning_content`）不会进入这里，只放在 [reasoning]。
  final String? content;

  /// 推理模型的思考内容；仅用于诊断/日志，绝不写入正文。
  final String? reasoning;

  /// stop | length | content_filter | tool_calls | null（仍在生成）。
  final String? finishReason;

  /// 完整的工具调用；流结束时一次性给出（Agent 模块用）。
  final List<ApiToolCall>? toolCalls;

  /// SSE 帧中的工具调用增量，仅供客户端累加，不直接暴露给 UI。
  final List<ToolCallDelta>? toolCallDeltas;

  const ChatDelta({
    this.content,
    this.reasoning,
    this.finishReason,
    this.toolCalls,
    this.toolCallDeltas,
  });
}

/// 工具调用增量（OpenAI `delta.tool_calls[]` 的一项）。
class ToolCallDelta {
  final int index;
  final String? id;
  final String? name;
  final String? arguments;

  const ToolCallDelta({
    required this.index,
    this.id,
    this.name,
    this.arguments,
  });
}

/// 完整工具调用（assistant 消息里的 `tool_calls[]` 一项）。
class ApiToolCall {
  final String id;

  /// 固定 `function`。
  final String type;

  final String name;

  /// JSON 字符串（模型生成，可能不是合法 JSON）。
  final String arguments;

  const ApiToolCall({
    required this.id,
    this.type = 'function',
    required this.name,
    required this.arguments,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'function': {'name': name, 'arguments': arguments},
  };

  static ApiToolCall? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final fn = raw['function'];
    final name = fn is Map ? fn['name']?.toString() : null;
    if (name == null || name.isEmpty) return null;
    final args = fn is Map ? fn['arguments'] : null;
    return ApiToolCall(
      id: raw['id']?.toString() ?? '',
      type: raw['type']?.toString() ?? 'function',
      name: name,
      arguments: args is String ? args : jsonEncode(args ?? const {}),
    );
  }
}

/// 提供给模型的工具定义（OpenAI tools 数组的一项）。
class ApiTool {
  final String type;
  final String name;
  final String description;
  final Map<String, dynamic> parameters;

  const ApiTool({
    this.type = 'function',
    required this.name,
    required this.description,
    required this.parameters,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'function': {
      'name': name,
      'description': description,
      'parameters': parameters,
    },
  };
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

  /// assistant 消息携带的工具调用。
  final List<ApiToolCall> toolCalls;

  /// role=tool 时对应的 tool_call id。
  final String? toolCallId;

  /// role=tool 时的工具名（可选，部分端点要求）。
  final String? name;

  const ApiMessage({
    required this.role,
    required this.content,
    this.images = const [],
    this.toolCalls = const [],
    this.toolCallId,
    this.name,
  });

  Map<String, dynamic> toJson() {
    if (role == 'tool') {
      return {
        'role': role,
        'content': content,
        if (toolCallId != null) 'tool_call_id': toolCallId,
        if (name != null && name!.isNotEmpty) 'name': name,
      };
    }
    if (toolCalls.isNotEmpty) {
      return {
        'role': role,
        'content': content,
        'tool_calls': [for (final t in toolCalls) t.toJson()],
      };
    }
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
    List<ApiTool>? tools,
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

  static const int _maxJsonBodyBytes = 8 * 1024 * 1024;
  static const int _maxTeeBytes = 1024 * 1024;

  @override
  Stream<ChatDelta> streamChat({
    required ApiProfile profile,
    required List<ApiMessage> messages,
    double? temperature,
    int? maxTokens,
    List<ApiTool>? tools,
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
    if (tools != null && tools.isNotEmpty) {
      body['tools'] = [for (final tool in tools) tool.toJson()];
      body['tool_choice'] = 'auto';
    }

    final response = await _openStream(profile, body, cancelToken);
    await response.ensureSuccess(
      toolsRequested: tools != null && tools.isNotEmpty,
    );

    final raw = response.data!.stream.cast<List<int>>();
    final contentType =
        response.headers.value(Headers.contentTypeHeader)?.toLowerCase() ?? '';

    // 整包 JSON：部分兼容端点忽略 stream:true，直接返回一次 completion。
    if (contentType.contains('application/json')) {
      final text = utf8.decode(
        await _collectBytes(raw, _maxJsonBodyBytes),
        allowMalformed: true,
      );
      final delta = _parseCompletionJson(text);
      if (delta != null) yield delta;
      return;
    }

    // 边解析 SSE 边缓存原始字节（上限 1MB）：用于「标成 text/plain 的整包 JSON」
    // 兜底。tee 只旁路记录，不改变上游流。
    final tee = BytesBuilder(copy: false);
    var teeLen = 0;
    final tapped = raw.map((chunk) {
      if (teeLen < _maxTeeBytes) {
        final remain = _maxTeeBytes - teeLen;
        final take = chunk.length <= remain ? chunk : chunk.sublist(0, remain);
        tee.add(take);
        teeLen += take.length;
      }
      return chunk;
    });

    var sawContent = false;
    var sawDone = false;
    String? lastFinish;
    final toolAcc = <int, _ToolCallAcc>{};

    await for (final event in decodeSseStream(tapped)) {
      final data = event.data;
      if (data.isEmpty) continue;
      if (data == '[DONE]') {
        sawDone = true;
        final flushed = _flushToolCalls(toolAcc, lastFinish);
        if (flushed != null) yield flushed;
        return;
      }
      final delta = _parseChunk(data);
      if (delta == null) continue;
      if (delta.finishReason != null) lastFinish = delta.finishReason;
      if (delta.toolCallDeltas != null) {
        _mergeToolDeltas(toolAcc, delta.toolCallDeltas!);
      }
      if (delta.content != null && delta.content!.isNotEmpty) sawContent = true;
      if (delta.content != null ||
          delta.reasoning != null ||
          delta.finishReason != null) {
        yield ChatDelta(
          content: delta.content,
          reasoning: delta.reasoning,
          finishReason: delta.finishReason,
        );
      }
    }

    // 流结束但没有 [DONE]：同样把累积的工具调用交出去。
    final flushed = _flushToolCalls(toolAcc, lastFinish);
    if (flushed != null) yield flushed;

    // 零正文且没有 [DONE]：用缓存再试一次整包 JSON。
    if (!sawContent && !sawDone && toolAcc.isEmpty) {
      final text =
          utf8.decode(tee.takeBytes(), allowMalformed: true).trim();
      if (text.isNotEmpty) {
        final delta = _parseCompletionJson(text);
        if (delta != null) yield delta;
      }
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

  /// 解析一帧 SSE JSON；错误帧在此转成 [AppException]。
  ChatDelta? _parseChunk(String data) {
    final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(data);
      if (decoded is! Map<String, dynamic>) return null;
      json = decoded;
    } catch (e) {
      // 单帧损坏不致命；流里还有后续帧。
      if (kDebugMode) {
        debugPrint('[chat_api] bad frame: ${_clip(data)}');
      }
      return null;
    }

    _throwIfError(json, data);

    final choices = json['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final first = choices.first;
    if (first is! Map) return null;
    final delta = first['delta'];
    String? content;
    String? reasoning;
    if (delta is Map) {
      content = _extractText(delta['content']);
      reasoning = _extractText(delta['reasoning_content']) ??
          _extractText(delta['reasoning']);
    }
    // 部分兼容实现把文本放在 message.content。
    if (content == null && first['message'] is Map) {
      final m = first['message'] as Map;
      content = _extractText(m['content']);
      reasoning ??= _extractText(m['reasoning_content']) ??
          _extractText(m['reasoning']);
    }
    // 老式 completions：choices[0].text。
    content ??= _extractText(first['text']);
    final finish = first['finish_reason'];
    final toolDeltas =
        _parseToolCallDeltas(delta is Map ? delta['tool_calls'] : null) ??
        _parseToolCallDeltas(first['tool_calls']);
    final out = ChatDelta(
      content: content,
      reasoning: reasoning,
      finishReason: finish is String ? finish : null,
      toolCallDeltas: toolDeltas,
    );
    _logDelta(out);
    return out;
  }

  /// 解析整包 completion JSON（非流式响应）。
  ChatDelta? _parseCompletionJson(String text) {
    final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) return null;
      json = decoded;
    } catch (_) {
      return null;
    }

    _throwIfError(json, text);

    final choices = json['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final first = choices.first;
    if (first is! Map) return null;
    String? content;
    String? reasoning;
    final message = first['message'];
    if (message is Map) {
      content = _extractText(message['content']);
      reasoning = _extractText(message['reasoning_content']) ??
          _extractText(message['reasoning']);
    }
    content ??= _extractText(first['text']);
    final finish = first['finish_reason'];
    List<ApiToolCall>? toolCalls;
    if (message is Map) {
      toolCalls = _parseCompleteToolCalls(message['tool_calls']);
    }
    final out = ChatDelta(
      content: content,
      reasoning: reasoning,
      finishReason: finish is String ? finish : null,
      toolCalls: toolCalls,
    );
    _logDelta(out);
    return out;
  }

  void _throwIfError(Map<String, dynamic> json, String raw) {
    final error = json['error'];
    if (error is! Map) return;
    if (kDebugMode) {
      debugPrint('[chat_api] error frame: ${_clip(raw)}');
    }
    final msg = error['message']?.toString() ?? '服务端返回错误';
    final code = error['code']?.toString();
    if (code == 'invalid_api_key' || code == 'authentication_error') {
      throw AuthException(msg);
    }
    throw ServerException(msg);
  }

  void _logDelta(ChatDelta delta) {
    if (!kDebugMode) return;
    final finish = delta.finishReason;
    if (finish == null) return; // 只在收尾帧打一行，避免逐帧刷屏。
    debugPrint(
      '[chat_api] finish=$finish content=${delta.content?.length ?? 0} '
      'reasoning=${delta.reasoning?.length ?? 0} '
      'tools=${delta.toolCalls?.length ?? 0}',
    );
  }

  static String _clip(String s) => s.length <= 500 ? s : s.substring(0, 500);
}

/// 流式 tool_calls 累积器。
class _ToolCallAcc {
  String id = '';
  String name = '';
  final StringBuffer arguments = StringBuffer();
}

void _mergeToolDeltas(
  Map<int, _ToolCallAcc> acc,
  List<ToolCallDelta> deltas,
) {
  for (final delta in deltas) {
    final target = acc.putIfAbsent(delta.index, _ToolCallAcc.new);
    final id = delta.id;
    if (id != null && id.isNotEmpty) target.id = id;
    final name = delta.name;
    if (name != null && name.isNotEmpty) target.name = name;
    final args = delta.arguments;
    if (args != null) target.arguments.write(args);
  }
}

/// 把累积结果收束成一条 [ChatDelta]；无工具调用时返回 null。
ChatDelta? _flushToolCalls(
  Map<int, _ToolCallAcc> acc,
  String? finishReason,
) {
  if (acc.isEmpty) return null;
  final indexes = acc.keys.toList()..sort();
  final calls = <ApiToolCall>[];
  for (final index in indexes) {
    final item = acc[index]!;
    if (item.name.isEmpty) continue;
    calls.add(
      ApiToolCall(
        id: item.id.isEmpty ? 'call_$index' : item.id,
        name: item.name,
        arguments: item.arguments.toString(),
      ),
    );
  }
  if (calls.isEmpty) return null;
  return ChatDelta(toolCalls: calls, finishReason: finishReason);
}

/// 解析一帧里的 `delta.tool_calls[]`（片段）。
List<ToolCallDelta>? _parseToolCallDeltas(dynamic raw) {
  if (raw is! List) return null;
  final out = <ToolCallDelta>[];
  for (var i = 0; i < raw.length; i++) {
    final item = raw[i];
    if (item is! Map) continue;
    final fn = item['function'];
    out.add(
      ToolCallDelta(
        index: item['index'] is int ? item['index'] as int : i,
        id: item['id']?.toString(),
        name: fn is Map ? fn['name']?.toString() : null,
        arguments: fn is Map ? fn['arguments']?.toString() : null,
      ),
    );
  }
  return out.isEmpty ? null : out;
}

/// 解析完整 `tool_calls[]`（整包 JSON 响应）。
List<ApiToolCall>? _parseCompleteToolCalls(dynamic raw) {
  if (raw is! List) return null;
  final out = <ApiToolCall>[];
  for (final item in raw) {
    final call = ApiToolCall.fromJson(item);
    if (call != null) out.add(call);
  }
  return out.isEmpty ? null : out;
}

/// 从 content 提取纯文本：字符串、parts 数组、或 {text: ...}。
String? _extractText(dynamic content) {
  if (content is String) return content;
  if (content is List) {
    final buf = StringBuffer();
    for (final part in content) {
      if (part is Map) {
        final text = part['text'];
        if (text is String) {
          buf.write(text);
          continue;
        }
        final inner = part['content'];
        if (inner is String) buf.write(inner);
      } else if (part is String) {
        buf.write(part);
      }
    }
    return buf.isEmpty ? null : buf.toString();
  }
  if (content is Map && content['text'] is String) {
    return content['text'] as String;
  }
  return null;
}

/// 读完整个响应体（上限 [maxBytes]），用于整包 JSON。
Future<List<int>> _collectBytes(Stream<List<int>> stream, int maxBytes) async {
  final builder = BytesBuilder(copy: false);
  var total = 0;
  await for (final chunk in stream) {
    if (total >= maxBytes) break;
    final remain = maxBytes - total;
    if (chunk.length <= remain) {
      builder.add(chunk);
      total += chunk.length;
    } else {
      builder.add(chunk.sublist(0, remain));
      break;
    }
  }
  return builder.takeBytes();
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
  ///
  /// [toolsRequested] 为 true 时，400/422 且错误体提到 tool/function
  /// 视为模型不支持工具调用，抛 [AgentToolsUnsupportedException]。
  Future<void> ensureSuccess({bool toolsRequested = false}) async {
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
    if (toolsRequested && (status == 400 || status == 422)) {
      final lower = (bodyText ?? '').toLowerCase();
      if (lower.contains('tool') ||
          lower.contains('function') ||
          lower.contains('function_call')) {
        throw AgentToolsUnsupportedException('当前模型不支持工具调用：$msg');
      }
    }
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