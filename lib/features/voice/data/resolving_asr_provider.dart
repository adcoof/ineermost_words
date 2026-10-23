/// 按设置选择 ASR 引擎（'mimo' 云端 / 'system' 本机），
/// 启动失败且尚无结果时自动回退另一引擎；
/// 回退只在 start 阶段发生（初始化失败场景），识别中途出错、
/// stop/cancel 之后的错误直接上报，避免松手后再开一路僵尸识别会话。
library;

import '../../../core/errors/app_exception.dart';
import '../domain/asr_provider.dart';
import 'mimo_asr_provider.dart';
import 'speech_to_text_asr_provider.dart';

class ResolvingAsrProvider implements AsrProvider {
  /// 读取设置里的 ASR 引擎（'mimo' | 'system'）。
  final Future<String> Function() engineGet;
  final MimoAsrProvider mimo;
  final SpeechToTextAsrProvider system;

  /// 当前实际生效的引擎。
  AsrProvider? _active;
  bool _gotResult = false;
  bool _fellBack = false;

  /// start() 是否仍在进行中（仅此阶段允许回退）。
  bool _starting = false;

  /// stop()/cancel() 已开始：本次话语已结束，此后禁止回退、禁止再开识别。
  bool _ending = false;

  ResolvingAsrProvider({
    required this.engineGet,
    required this.mimo,
    required this.system,
  });

  /// 是否允许回退备引擎：仅 start 阶段、话语未结束、尚无结果、未回退过。
  bool _canFallback(AsrProvider? secondary) =>
      _starting && !_ending && !_gotResult && !_fellBack && secondary != null;

  @override
  Future<void> start(AsrCallbacks callbacks) async {
    _gotResult = false;
    _fellBack = false;
    _ending = false;
    _starting = true;
    final engine = await engineGet();
    late final AsrProvider primary;
    AsrProvider? secondary;
    if (engine == 'system') {
      primary = system;
      secondary = await mimo.canUse() ? mimo : null;
    } else if (await mimo.canUse()) {
      primary = mimo;
      secondary = system;
    } else {
      // 没聊天配置时云端不可用，直接本机，且此时无备引擎。
      primary = system;
      secondary = null;
    }
    // 话语可能在解析引擎期间就已结束（stop/cancel 已调用）：
    // 不再开启识别，避免留下没人 stop 的僵尸录音。
    if (_ending) {
      _starting = false;
      return;
    }
    _active = primary;

    // 只给主引擎包一层结果标记：首个 partial/final 落地后不再回退。
    final wrapped = AsrCallbacks(
      onPartial: (text) {
        _gotResult = true;
        callbacks.onPartial(text);
      },
      onFinal: (text) {
        _gotResult = true;
        callbacks.onFinal(text);
      },
      onError: (error) {
        final sec = secondary;
        if (sec != null && _canFallback(sec)) {
          // 吞掉 start 阶段的首个错误，让本机/云端接手（初始化失败场景）。
          _fellBack = true;
          _active = sec;
          _startSecondary(sec, callbacks);
        } else {
          // 识别中途/stop 后的错误：直接上报，不再开备引擎（会变僵尸会话）。
          callbacks.onError(error);
        }
      },
    );

    try {
      await primary.start(wrapped);
    } catch (e) {
      // primary.start 直接抛异常：同样只在 start 阶段尝试备引擎，无备引擎则原样抛出。
      final sec = secondary;
      if (sec != null && _canFallback(sec)) {
        _fellBack = true;
        _active = sec;
        await _startSecondary(sec, callbacks);
      } else {
        rethrow;
      }
    } finally {
      _starting = false;
    }
  }

  /// 启动备引擎；备引擎再抛就透传给 onError（不向外抛）。
  Future<void> _startSecondary(AsrProvider secondary, AsrCallbacks callbacks) async {
    try {
      await secondary.start(callbacks);
    } catch (e) {
      callbacks.onError(
          e is AppException ? e : UnknownException('识别启动失败', e));
    }
  }

  @override
  Future<void> stop() async {
    _ending = true;
    _starting = false;
    final active = _active;
    if (active == null) return;
    await active.stop();
  }

  @override
  Future<void> cancel() async {
    _ending = true;
    _starting = false;
    final active = _active;
    if (active == null) return;
    await active.cancel();
  }
}
