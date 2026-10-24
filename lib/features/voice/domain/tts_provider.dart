/// TTS 抽象：三种实现（Edge 免费 / OpenAI 兼容 / 系统引擎兜底）。
///
/// 统一契约为「合成出音频字节」，队列、口型、打断在上层与提供商无关；
/// 系统引擎通过 synthesizeToFile 落 WAV 再读回字节，同样满足契约。
library;

import 'package:dio/dio.dart';

/// 一次合成请求。
class TtsRequest {
  final String text;

  /// 发音人；空串=提供商默认。
  final String voiceId;

  /// 语速倍率（0.5–2.0）。
  final double speed;

  /// 自定义音色描述（自然语言，如「温柔甜美的年轻女声」）。
  /// 非空时 MiMo 走 mimo-v2.5-tts-voicedesign：描述进 user 消息，
  /// 朗读文本进 assistant 消息，无需 voice 参数。
  final String voiceDesign;

  const TtsRequest({
    required this.text,
    this.voiceId = '',
    this.speed = 1.0,
    this.voiceDesign = '',
  });
}

/// 合成结果。
class TtsAudio {
  /// mp3 | wav
  final String mimeType;
  final List<int> bytes;

  const TtsAudio({required this.mimeType, required this.bytes});
}

/// 可用发音人。
class TtsVoice {
  final String id;
  final String name;

  const TtsVoice(this.id, this.name);
}

/// TTS 提供商。
abstract class TtsProvider {
  /// 服务商标识：edge | openai | system。
  String get providerId;

  Future<TtsAudio> synthesize(TtsRequest req, {CancelToken? cancel});

  /// 列出可选发音人；不支持列举时返回空列表。
  Future<List<TtsVoice>> listVoices();
}
