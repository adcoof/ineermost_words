/// 系统 TTS 兜底：flutter_tts synthesizeToFile 落 WAV 后读回字节。
///
/// 断网/其他提供商失败时保底可用；依赖设备装有 TTS 引擎。
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/tts_provider.dart';

class SystemTtsProvider implements TtsProvider {
  final FlutterTts _tts;

  SystemTtsProvider({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  @override
  String get providerId => 'system';

  @override
  Future<TtsAudio> synthesize(TtsRequest req, {CancelToken? cancel}) async {
    // flutter_tts 本地合成通常很快（单句），忽略 cancelToken。
    await _tts.awaitSpeakCompletion(true);
    // flutter_tts 语速 0..1，映射自 0.5..2.0 倍率。
    await _tts.setSpeechRate((req.speed * 0.25).clamp(0.0, 1.0));
    if (req.voiceId.isNotEmpty) {
      try {
        await _tts.setVoice({'name': req.voiceId, 'locale': ''});
      } catch (_) {
        // 引擎不支持指定语音时用默认。
      }
    }
    final dir = Directory(
        (await getTemporaryDirectory()).path);
    final file = File(
        '${dir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.wav');
    try {
      final result = await _tts.synthesizeToFile(req.text, file.path);
      if (result != 1 || !await file.exists() ||
          await file.length() == 0) {
        throw const UnknownException('系统 TTS 合成失败（设备可能未安装语音引擎）');
      }
      final Uint8List bytes = await file.readAsBytes();
      return TtsAudio(mimeType: 'wav', bytes: bytes);
    } finally {
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  @override
  Future<List<TtsVoice>> listVoices() async {
    try {
      final voices = await _tts.getVoices;
      if (voices is List) {
        return [
          for (final v in voices)
            if (v is Map && v['name'] != null)
              TtsVoice(v['name'].toString(),
                  '${v['name']} (${v['locale'] ?? ''})'),
        ];
      }
    } catch (_) {}
    return const [];
  }
}
