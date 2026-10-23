/// TTS 播放队列：逐句合成 → 顺序播放 → 预合成下一句；支持打断。
///
/// 播放后端抽象成 [AudioPlayerBackend]（真机为 just_audio，单测为假实现）。
/// 单句合成失败跳过不中断；[clear] 立即停播并清空队列（barge-in 打断）。
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import '../../../core/errors/app_exception.dart';
import '../domain/tts_provider.dart';

/// 音频播放后端。
abstract class AudioPlayerBackend {
  /// 播放一段内存音频；完成时 future 结束。
  Future<void> playAudio(Uint8List bytes, String mimeType);

  Future<void> stop();

  void dispose();
}

/// 合成 + 播放编排。
class TtsQueueService {
  final TtsProvider provider;
  final AudioPlayerBackend player;

  /// 口型值流（0..1）：播放期间由包络驱动，静止时推送 0。
  final _lip = StreamController<double>.broadcast();
  Stream<double> get lipValues => _lip.stream;

  final _busy = StreamController<bool>.broadcast();
  Stream<bool> get busy => _busy.stream;

  /// 合成/播放失败上报（应用层弹提示，去抖由监听方负责）。
  final _errors = StreamController<String>.broadcast();
  Stream<String> get errors => _errors.stream;

  final List<TtsRequest> _queue = [];
  bool _draining = false;
  int _generation = 0;
  Timer? _lipTimer;
  double _t = 0;

  TtsQueueService({required this.provider, required this.player});

  /// 入队一句话；空文本忽略。
  void enqueue(String text, {double speed = 1.0, String voiceId = ''}) {
    // 已 dispose：静默忽略。否则 _drain 里未守卫的 _busy.add 会抛
    // StateError 且落在 try 之外，把 _draining 永久闩死成僵尸队列。
    if (_lip.isClosed) return;
    final t = text.trim();
    if (t.isEmpty) return;
    _queue.add(TtsRequest(text: t, speed: speed, voiceId: voiceId));
    if (!_draining) unawaited(_drain());
  }

  /// 是否有内容在播/待播。
  bool get isBusy => _draining || _queue.isNotEmpty;

  /// 打断：停播 + 清队列（进行中的合成作废）。
  void clear() {
    _generation++;
    _queue.clear();
    _draining = false;
    _stopLip();
    unawaited(player.stop());
    if (!_busy.isClosed) _busy.add(false);
  }

  Future<void> dispose() async {
    clear();
    await _lip.close();
    await _busy.close();
    await _errors.close();
    player.dispose();
  }

  Future<void> _drain() async {
    // dispose 后的残留调用直接放弃（与 enqueue 入口守卫同理）；
    // 守卫与 add(true) 之间无 await，单线程下 add 不可能再抛。
    if (_busy.isClosed) return;
    _draining = true;
    _busy.add(true);
    final gen = _generation;
    // 流水线预合成：播放第 N 句的同时后台合成第 N+1 句。云端 TTS 每次调用
    // 有 1~3s 延迟，严格串行会把它全变成句间静音；预合成让「合成比播得快」
    // 时句间零间隙，首句延迟不受影响（首句仍立即合成）。
    Future<TtsAudio>? lookahead;

    /// 从队列头预取下一句开始合成（立刻挂吞错句柄：clear/dispose 后可能
    /// 无人 await，防止未处理异常；真实错误在取用处 await 时仍会上报）。
    void armLookahead() {
      if (_queue.isEmpty || _generation != gen) return;
      final next = _queue.removeAt(0);
      final f = provider.synthesize(next);
      unawaited(f.catchError(
          (_) => TtsAudio(mimeType: 'mp3', bytes: const <int>[])));
      lookahead = f;
    }

    try {
      while ((_queue.isNotEmpty || lookahead != null) && _generation == gen) {
        TtsAudio audio;
        if (lookahead != null) {
          try {
            audio = await lookahead!;
          } catch (e) {
            _reportSynthError(gen, e);
            lookahead = null;
            continue;
          }
          lookahead = null;
        } else {
          final req = _queue.removeAt(0);
          try {
            audio = await provider.synthesize(req);
          } catch (e) {
            _reportSynthError(gen, e);
            continue;
          }
        }
        if (_generation != gen) return;
        // 播放前先武装下一句的预合成，使其与本次播放重叠。
        armLookahead();
        if (audio.bytes.isEmpty) continue;
        _startLip();
        try {
          await player.playAudio(
              Uint8List.fromList(audio.bytes), audio.mimeType);
        } catch (e) {
          if (_generation == gen && !_errors.isClosed) {
            _errors.add(
                '语音播放失败：${e is AppException ? e.message : '未知错误'}');
          }
        } finally {
          _stopLip();
        }
        if (_generation != gen) return;
      }
    } finally {
      if (_generation == gen) {
        _draining = false;
        if (!_busy.isClosed) _busy.add(false);
      }
    }
  }

  /// 合成失败上报：只带面向用户的 message，原始异常 toString 不进 UI。
  void _reportSynthError(int gen, Object e) {
    if (gen == _generation && !_errors.isClosed) {
      _errors.add(
          '语音合成失败：${e is AppException ? e.message : '未知错误'}');
    }
  }

  /// 播放期口型包络：位置无关的平滑伪包络（MP3 无法逐帧取 RMS 时的
  /// 计划方案），停播即归零。
  void _startLip() {
    _stopLip();
    _t = 0;
    _lipTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      _t += 0.12;
      // 两组正弦叠加 + 高频微扰，模拟说话开合。
      final v = 0.5 +
          0.3 * math.sin(_t * 2.3) * math.sin(_t * 0.7) +
          0.12 * math.sin(_t * 11.0);
      _lip.add(v.clamp(0.0, 1.0));
    });
  }

  void _stopLip() {
    _lipTimer?.cancel();
    _lipTimer = null;
    if (!_lip.isClosed) _lip.add(0);
  }
}
