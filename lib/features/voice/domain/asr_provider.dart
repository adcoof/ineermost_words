/// ASR 抽象：按住说话的短句识别（M4 用系统 SpeechRecognizer）。
library;

import '../../../core/errors/app_exception.dart';

/// 识别回调。
class AsrCallbacks {
  /// 部分结果（识别过程中变化）。
  final void Function(String partial) onPartial;

  /// 最终结果（松手 stop 后）。
  final void Function(String text) onFinal;

  final void Function(AppException error) onError;

  const AsrCallbacks({
    required this.onPartial,
    required this.onFinal,
    required this.onError,
  });
}

abstract class AsrProvider {
  /// 开始聆听（已聆听时调用无效）。
  Future<void> start(AsrCallbacks callbacks);

  /// 停止并提交最终结果。
  Future<void> stop();

  /// 立即取消（不出结果）。
  Future<void> cancel();
}
