/// 按当前默认 TTS 配置动态解析具体提供商（设置里切换即生效）。
///
/// 默认引擎是 MiMo 云端（内置 builtin-mimo），降级链：
/// 首选 → MiMo（云端兜底）→ Edge（免费在线）→ 系统（离线）。
library;

import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../settings/data/api_profile_repository.dart';
import '../domain/tts_provider.dart';
import 'edge_tts_provider.dart';
import 'mimo_tts_provider.dart';
import 'openai_tts_provider.dart';
import 'system_tts_provider.dart';
import 'tts_profile_repository.dart';

class ResolvingTtsProvider implements TtsProvider {
  final TtsProfileRepository profiles;
  final ApiProfileRepository chatProfiles;

  ResolvingTtsProvider({required this.profiles, required this.chatProfiles});

  bool _ensured = false;

  Future<TtsProvider> _primary() async {
    // 一次性 MiMo 默认迁移（幂等，避免每句都写库）。
    if (!_ensured) {
      _ensured = true;
      await profiles.ensureMimoDefault(
          () async => (await chatProfiles.getDefault()) != null);
    }
    final profile = await profiles.getDefault() ??
        // 无已存 profile：有聊天配置走 MiMo，否则 Edge 开箱即用。
        ((await chatProfiles.getDefault()) != null
            ? profiles.builtinMimo()
            : profiles.builtinEdge());
    switch (profile.provider) {
      case 'mimo':
        return MimoTtsProvider(
          baseUrl: profile.baseUrl,
          apiKey: profile.apiKey,
          model: profile.model,
          chatProfilesRepo: chatProfiles,
        );
      case 'openai':
        return OpenAiTtsProvider(
          baseUrl: profile.baseUrl,
          apiKey: profile.apiKey,
          model: profile.model,
          chatProfilesRepo: chatProfiles,
        );
      case 'system':
        return SystemTtsProvider();
      case 'edge':
      default:
        return EdgeTtsProvider();
    }
  }

  @override
  String get providerId => 'resolving';

  @override
  Future<TtsAudio> synthesize(TtsRequest req, {CancelToken? cancel}) async {
    // 失败自动降级链：首选 → MiMo（云端兜底）→ Edge（免费在线）→ 系统（离线）。
    // MiMo 放在第二位：免费引擎失败时用云端兜底；无聊天配置时它会快速抛
    // AuthException 自动跳过。任何一环成功即返回；全失败抛统一错误（应用层会弹提示）。
    final primary = await _primary();
    final chain = <TtsProvider>[
      primary,
      MimoTtsProvider(
          baseUrl: '', apiKey: '', model: '', chatProfilesRepo: chatProfiles),
      EdgeTtsProvider(),
      SystemTtsProvider(),
    ];
    // 按 providerId 去重保持顺序。
    final seen = <String>{};
    final unique =
        chain.where((p) => seen.add(p.providerId)).toList(growable: false);
    Object? lastError;
    for (final p in unique) {
      try {
        // 各引擎音色互不通用：逐引擎归一化 voiceId，不属于该引擎清单的
        // 按该引擎默认音色处理，否则兜底腿拿到主引擎音色必然失败。
        return await p.synthesize(_requestFor(p, req), cancel: cancel);
      } catch (e) {
        lastError = e;
      }
    }
    // 只拼面向用户的 message；原始异常留在 cause，不进 UI。
    final detail = lastError is AppException ? lastError.message : '未知错误';
    throw UnknownException(
        '语音合成失败（已尝试 ${unique.length} 个引擎）：$detail', lastError);
  }

  /// 按引擎归一化音色：不属于该引擎清单的音色回落为空（各引擎自持默认音色）。
  static TtsRequest _requestFor(TtsProvider p, TtsRequest req) {
    final voiceId = req.voiceId;
    if (voiceId.isEmpty) return req;
    final known = switch (p.providerId) {
      'mimo' => MimoTtsProvider.staticVoices.map((v) => v.id),
      'edge' => EdgeTtsProvider.staticVoices.map((v) => v.id),
      'openai' => OpenAiTtsProvider.staticVoices.map((v) => v.id),
      // 系统引擎音色随设备而定，无法静态校验，原样传入（setVoice 失败会静默回落默认）。
      _ => null,
    };
    if (known == null || known.contains(voiceId)) return req;
    return TtsRequest(text: req.text, voiceId: '', speed: req.speed);
  }

  @override
  Future<List<TtsVoice>> listVoices() async =>
      (await _primary()).listVoices();
}
