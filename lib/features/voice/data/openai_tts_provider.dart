/// OpenAI 兼容 TTS：POST {baseUrl}/audio/speech，输出 MP3。
///
/// baseUrl/apiKey 为空时回落到默认聊天 API 配置（多数中转站同源）。
library;

import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../chat/data/chat_api_client.dart' show mapDioException;
import '../../settings/data/api_profile_repository.dart';
import '../../settings/domain/api_profile.dart';
import '../domain/tts_provider.dart';

class OpenAiTtsProvider implements TtsProvider {
  final Dio _dio;

  /// 该 TTS 专用配置（可为空，回落到默认聊天配置）。
  final String baseUrl;
  final String apiKey;
  final String model;
  final ApiProfileRepository chatProfilesRepo;

  OpenAiTtsProvider({
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
  String get providerId => 'openai';

  static const _voices = [
    TtsVoice('alloy', 'alloy'),
    TtsVoice('echo', 'echo'),
    TtsVoice('fable', 'fable'),
    TtsVoice('onyx', 'onyx'),
    TtsVoice('nova', 'nova'),
    TtsVoice('shimmer', 'shimmer'),
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

  static String _speechUrl(String baseUrl) {
    var b = baseUrl.trim();
    while (b.endsWith('/')) {
      b = b.substring(0, b.length - 1);
    }
    return '$b/audio/speech';
  }

  @override
  Future<TtsAudio> synthesize(TtsRequest req, {CancelToken? cancel}) async {
    final endpoint = await _resolveEndpoint();
    try {
      final response = await _dio.post<List<int>>(
        _speechUrl(endpoint.baseUrl),
        data: {
          'model': model.trim().isEmpty ? 'tts-1' : model.trim(),
          'voice': req.voiceId.isEmpty ? 'alloy' : req.voiceId,
          'input': req.text,
          'response_format': 'mp3',
          'speed': req.speed,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (endpoint.apiKey.isNotEmpty)
              'Authorization': 'Bearer ${endpoint.apiKey}',
          },
          responseType: ResponseType.bytes,
          validateStatus: (_) => true,
        ),
        cancelToken: cancel,
      );
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        if (status == 401 || status == 403) {
          throw AuthException('TTS 鉴权失败（HTTP $status）');
        }
        throw ServerException('TTS 请求失败（HTTP $status）', null, status);
      }
      return TtsAudio(mimeType: 'mp3', bytes: response.data ?? const []);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<List<TtsVoice>> listVoices() async => _voices;
}
