/// just_audio 播放后端：内存音频经临时文件播放。
///
/// 两处防御（「没声音」排查结论）：
/// 1. 主动配置并激活音频会话，避免静默无声；
/// 2. [AudioPlayer.play] 的 future 在会话激活失败时可能永不完成
///    （just_audio 内部 playCompleter 无人 complete），用时长+余量兜底超时，
///    否则整个 TTS 队列会永久卡死在这一句。
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/errors/app_exception.dart';
import '../application/tts_queue_service.dart';

class JustAudioPlayerBackend implements AudioPlayerBackend {
  final AudioPlayer _player = AudioPlayer();
  Future<void>? _sessionReady;

  /// 配置并激活音频会话（music）；失败不阻塞播放尝试。
  Future<void> _ensureSession() {
    return _sessionReady ??= () async {
      try {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.music());
        await session.setActive(true);
      } catch (_) {
        // 会话配置失败时仍尝试播放（play 内部还会再激活一次）。
      }
    }();
  }

  @override
  Future<void> playAudio(Uint8List bytes, String mimeType) async {
    await _ensureSession();
    // 落临时文件播放（兼容所有 just_audio 版本）。
    final dir = await getTemporaryDirectory();
    final ext = mimeType.contains('wav') ? 'wav' : 'mp3';
    final file =
        File('${dir.path}/tts_play_${DateTime.now().microsecondsSinceEpoch}.$ext');
    await file.writeAsBytes(bytes, flush: true);
    try {
      await _player.setFilePath(file.path);
      // play() 完成于播放结束/停止；时长+余量兜底防内部挂起。
      final duration = _player.duration ?? const Duration(seconds: 30);
      await _player.play().timeout(
            duration + const Duration(seconds: 5),
            onTimeout: () =>
                throw const UnknownException('播放超时（音频会话可能被其他应用占用）'),
          );
    } finally {
      // just_audio 的坑：playing 在自然播完后保持 true（直到 pause/stop），
      // 而 play() 在 playing==true 时立即返回；setFilePath/load 都不复位它。
      // 若不 stop，下一句换源会带着 playWhenReady 自动开播、play() 秒回，
      // 队列随即又换下一句 → 上一句被掐断（语音断续）。每句播完必须
      // stop 复位；超时抛错路径也靠它掐掉后台残留的播放。
      try {
        await _player.stop();
      } catch (_) {}
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  void dispose() {
    unawaited(_player.stop());
    _player.dispose();
  }
}
