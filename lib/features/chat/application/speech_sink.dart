/// 助手语音出口抽象：聊天控制器把流式干净文本喂给它，
/// 由语音域决定是否/如何朗读（避免 chat → voice 的反向依赖）。
library;

abstract class AssistantSpeechSink {
  /// 助手流式增量（干净文本）。
  Future<void> onAssistantDelta(String cleanDelta);

  /// 本条回复完成。
  Future<void> onAssistantDone();

  /// 本条回复被打断/出错：停止播报。
  Future<void> onAssistantInterrupted();
}

/// 语音未启用时的空实现。
class NoopSpeechSink implements AssistantSpeechSink {
  const NoopSpeechSink();

  @override
  Future<void> onAssistantDelta(String cleanDelta) async {}

  @override
  Future<void> onAssistantDone() async {}

  @override
  Future<void> onAssistantInterrupted() async {}
}
