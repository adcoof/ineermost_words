/// MiMo TTS：小米 MiMo 语音合成（chat.completions + audio 参数）。
///
/// 官方形态：POST {baseUrl}/chat/completions，
/// messages = [user: 风格描述, assistant: 要朗读的文本]，
/// audio = {format, voice}，音频在 `choices[0].message.audio.data`（base64）。
/// 注意：不是 /audio/speech，那个路径在 MiMo 上 404。
///
/// baseUrl/apiKey 为空时回落到默认聊天 API 配置（同源同 Key）。
library;

import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../chat/data/chat_api_client.dart'
    show OpenAiChatApiClient, mapDioException;
import '../../settings/data/api_profile_repository.dart';
import '../../settings/domain/api_profile.dart';
import '../domain/tts_provider.dart';

class MimoTtsProvider implements TtsProvider {
  final Dio _dio;

  /// 该 TTS 专用配置（可为空，回落到默认聊天配置）。
  final String baseUrl;
  final String apiKey;
  final String model;
  final ApiProfileRepository chatProfilesRepo;

  MimoTtsProvider({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.chatProfilesRepo,
    Dio? dio,
  }) : _dio = dio ??
            Dio(BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 60)));

  @override
  String get providerId => 'mimo';

  static const String defaultModel = 'mimo-v2.5-tts';
  static const String defaultVoice = 'mimo_default';

  /// 官方发音人清单（错误信息实测枚举）。
  static const _voices = [
    TtsVoice('mimo_default', '默认'),
    TtsVoice('冰糖', '冰糖'),
    TtsVoice('茉莉', '茉莉'),
    TtsVoice('苏打', '苏打'),
    TtsVoice('白桦', '白桦'),
    TtsVoice('Mia', 'Mia'),
    TtsVoice('Chloe', 'Chloe'),
    TtsVoice('Milo', 'Milo'),
    TtsVoice('Dean', 'Dean'),
  ];

  /// 静态发音人清单。
  static List<TtsVoice> get staticVoices => _voices;

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

  /// 风格描述：基础对话语气 + 语速提示（audio 参数不支持 speed）。
  static String styleFor(double speed) {
    const base = '自然、友好、清晰的对话语气。';
    if (speed >= 1.3) return '$base 语速较快，干脆利落。';
    if (speed >= 1.1) return '$base 语速稍快。';
    if (speed <= 0.7) return '$base 语速较慢，从容不迫。';
    if (speed <= 0.9) return '$base 语速稍慢。';
    return base;
  }

  @override
  Future<TtsAudio> synthesize(TtsRequest req, {CancelToken? cancel}) async {
    final endpoint = await _resolveEndpoint();
    try {
      final response = await _dio.post<dynamic>(
        OpenAiChatApiClient.completionsUrl(endpoint.baseUrl),
        data: {
          'model': model.trim().isEmpty ? defaultModel : model.trim(),
          'messages': [
            {'role': 'user', 'content': styleFor(req.speed)},
            {'role': 'assistant', 'content': req.text},
          ],
          'audio': {
            'format': 'mp3',
            'voice': req.voiceId.isEmpty ? defaultVoice : req.voiceId,
          },
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (endpoint.apiKey.isNotEmpty)
              'Authorization': 'Bearer ${endpoint.apiKey}',
          },
          validateStatus: (_) => true,
        ),
        cancelToken: cancel,
      );
      final status = response.statusCode ?? 0;
      final data = response.data;
      if (status < 200 || status >= 300) {
        final msg = _errorMessage(data) ?? 'HTTP $status';
        if (status == 401 || status == 403) {
          throw AuthException('TTS 鉴权失败：$msg');
        }
        throw ServerException('TTS 请求失败：$msg', null, status);
      }
      final audioB64 = _audioData(data);
      if (audioB64 == null || audioB64.isEmpty) {
        throw const ServerException('TTS 响应中没有音频数据', null, 200);
      }
      return TtsAudio(mimeType: 'mp3', bytes: base64Decode(audioB64));
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// 取 `choices[0].message.audio.data`。
  static String? _audioData(dynamic data) {
    try {
      if (data is String) data = jsonDecode(data);
      if (data is Map) {
        final choices = data['choices'];
        if (choices is List && choices.isNotEmpty) {
          final message = choices[0]['message'];
          final audio = message['audio'];
          final d = audio['data'];
          if (d is String) return d;
        }
      }
    } catch (_) {}
    return null;
  }

  /// 取错误信息（非 2xx 时）。
  static String? _errorMessage(dynamic data) {
    try {
      if (data is String) data = jsonDecode(data);
      if (data is Map && data['error'] is Map) {
        return (data['error'] as Map)['message']?.toString();
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<TtsVoice>> listVoices() async => _voices;
}
