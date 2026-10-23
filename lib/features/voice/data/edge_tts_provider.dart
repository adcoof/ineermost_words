/// Edge TTS：免费神经语音（微软 Edge 的在线接口），输出 MP3。
library;

import 'package:dio/dio.dart';
import 'package:edge_tts/edge_tts.dart';

import '../domain/tts_provider.dart';

class EdgeTtsProvider implements TtsProvider {
  @override
  String get providerId => 'edge';

  /// 常用中英文神经语音（内置精选，避免每次都在线拉 400+ 列表）。
  static const _voices = [
    TtsVoice('zh-CN-XiaoxiaoNeural', '晓晓（女·通用）'),
    TtsVoice('zh-CN-YunxiNeural', '云希（男·阳光）'),
    TtsVoice('zh-CN-YunjianNeural', '云健（男·浑厚）'),
    TtsVoice('zh-CN-XiaoyiNeural', '晓伊（女·活泼）'),
    TtsVoice('zh-CN-YunyangNeural', '云扬（男·新闻）'),
    TtsVoice('zh-TW-HsiaoChenNeural', '晓臻（台湾腔）'),
    TtsVoice('en-US-AriaNeural', 'Aria（美式女）'),
    TtsVoice('en-US-GuyNeural', 'Guy（美式男）'),
  ];

  static const String defaultVoice = 'zh-CN-XiaoxiaoNeural';

  /// 静态发音人清单（供设置页切换提供商时立即展示）。
  static List<TtsVoice> get staticVoices => _voices;

  @override
  Future<TtsAudio> synthesize(TtsRequest req, {CancelToken? cancel}) async {
    // edge_tts 不支持取消：请求较短（单句），忽略 cancelToken。
    final pct = ((req.speed - 1.0) * 100).round();
    final communicate = Communicate(
      text: req.text,
      voice: req.voiceId.isEmpty ? defaultVoice : req.voiceId,
      rate: '${pct >= 0 ? '+' : ''}$pct%',
    );
    final bytes = await communicate.toBytes();
    return TtsAudio(mimeType: 'mp3', bytes: bytes);
  }

  @override
  Future<List<TtsVoice>> listVoices() async => _voices;
}
