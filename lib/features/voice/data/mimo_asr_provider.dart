/// MiMo ASR：小米 MiMo 语音识别（chat.completions + input_audio）。
///
/// 形态：POST {baseUrl}/chat/completions，model=mimo-v2.5-asr，
/// messages = [{role:user, content:[{type:input_audio,
///   input_audio:{data:"data:audio/wav;base64,...", format:"wav"}}]}]。
/// 注意：**不能带任何 text 片段**，否则 400（网关注入文本提示）。
/// 转写结果在 `choices[0].message.content`。
///
/// 按住说话的交互：start 用 `record` 录 WAV，stop 落盘后送识别并回调 onFinal。
library;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/errors/app_exception.dart';
import '../../chat/data/chat_api_client.dart'
    show OpenAiChatApiClient, mapDioException;
import '../../settings/data/api_profile_repository.dart';
import '../../settings/domain/api_profile.dart';
import '../domain/asr_provider.dart';

class MimoAsrProvider implements AsrProvider {
  final Dio _dio;

  /// 录音器懒加载：构造时不实例化（测试环境无平台通道会炸），start 时再建。
  AudioRecorder? _rec;

  /// 该 ASR 专用配置（可为空，回落到默认聊天配置）。
  final String baseUrl;
  final String apiKey;
  final String model;
  final ApiProfileRepository chatProfilesRepo;

  AsrCallbacks? _callbacks;
  bool _recording = false;
  String? _recordPath;

  MimoAsrProvider({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.chatProfilesRepo,
    Dio? dio,
    AudioRecorder? recorder,
  })  : _dio = dio ??
            Dio(BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 60))),
        _rec = recorder;

  static const String defaultModel = 'mimo-v2.5-asr';

  Future<ApiProfile> _resolveEndpoint() async {
    if (baseUrl.trim().isNotEmpty) {
      return ApiProfile(
        id: '',
        name: '',
        baseUrl: baseUrl.trim(),
        apiKey: apiKey.trim(),
        model: model,
        temperature: 1.0,
        extraHeaders: '{}',
        isDefault: false,
      );
    }
    final chat = await chatProfilesRepo.getDefault();
    if (chat == null) {
      throw const AuthException('请先在设置中添加 API 供应商配置');
    }
    return chat;
  }

  /// 该 ASR 能否启用：专用 baseUrl 非空，或存在默认聊天配置可回落。
  Future<bool> canUse() async {
    if (baseUrl.trim().isNotEmpty) return true;
    return (await chatProfilesRepo.getDefault()) != null;
  }

  @override
  Future<void> start(AsrCallbacks callbacks) async {
    if (_recording) return;
    _callbacks = callbacks;
    final dir = await getTemporaryDirectory();
    _recordPath =
        '${dir.path}/asr_${DateTime.now().millisecondsSinceEpoch}.wav';
    try {
      final rec = _rec ??= AudioRecorder();
      await rec.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _recordPath!,
      );
      _recording = true;
    } catch (e) {
      _recordPath = null;
      callbacks.onError(UnknownException('无法开始录音', e));
    }
  }

  @override
  Future<void> stop() async {
    if (!_recording) return;
    _recording = false;
    final cb = _callbacks;
    try {
      final path = await _rec?.stop();
      final file = File(path ?? _recordPath ?? '');
      if (path == null || !await file.exists() || await file.length() < 128) {
        // 录音过短/失败：按空结果收尾（不弹错，用户只是没说话）。
        cb?.onFinal('');
        return;
      }
      final bytes = await file.readAsBytes();
      await file.delete();
      final text = await transcribe(bytes);
      cb?.onFinal(text);
    } catch (e) {
      if (e is AppException) {
        cb?.onError(e);
      } else {
        cb?.onError(UnknownException('语音识别失败', e));
      }
    } finally {
      _recordPath = null;
    }
  }

  @override
  Future<void> cancel() async {
    if (!_recording) return;
    _recording = false;
    _callbacks = null;
    try {
      await _rec?.cancel();
    } catch (_) {}
    _recordPath = null;
  }

  /// 送云端识别；返回转写文本（可为空串）。
  ///
  /// 公开方法：供单测直调（不经过录音链路），录音链路在 [stop] 里调用它。
  Future<String> transcribe(List<int> wavBytes) async {
    final endpoint = await _resolveEndpoint();
    final wavB64 = base64Encode(wavBytes);
    try {
      final response = await _dio.post<dynamic>(
        OpenAiChatApiClient.completionsUrl(endpoint.baseUrl),
        data: {
          'model': model.trim().isEmpty ? defaultModel : model.trim(),
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'input_audio',
                  'input_audio': {
                    // data-url 形式（裸 base64 也可，统一 data-url）。
                    'data': 'data:audio/wav;base64,$wavB64',
                    'format': 'wav',
                  },
                },
              ],
            },
          ],
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (endpoint.apiKey.isNotEmpty)
              'Authorization': 'Bearer ${endpoint.apiKey}',
          },
          validateStatus: (_) => true,
        ),
      );
      final status = response.statusCode ?? 0;
      final data = response.data;
      if (status < 200 || status >= 300) {
        final msg = _errorMessage(data) ?? 'HTTP $status';
        if (status == 401 || status == 403) {
          throw AuthException('识别鉴权失败：$msg');
        }
        throw ServerException('识别请求失败：$msg', null, status);
      }
      return _content(data) ?? '';
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// 取 `choices[0].message.content`（可能是字符串或分段列表）。
  static String? _content(dynamic data) {
    try {
      if (data is String) data = jsonDecode(data);
      if (data is Map) {
        final choices = data['choices'];
        if (choices is List && choices.isNotEmpty) {
          final c = choices[0]['message']['content'];
          if (c is String) return c;
          if (c is List) {
            return [
              for (final part in c)
                if (part is Map && part['text'] is String) part['text'],
            ].join();
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static String? _errorMessage(dynamic data) {
    try {
      if (data is String) data = jsonDecode(data);
      if (data is Map && data['error'] is Map) {
        return (data['error'] as Map)['message']?.toString();
      }
    } catch (_) {}
    return null;
  }
}
