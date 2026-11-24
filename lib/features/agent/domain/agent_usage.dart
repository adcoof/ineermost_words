/// Agent 单次请求的上下文用量估算。
library;

import 'dart:math' as math;

class AgentUsage {
  const AgentUsage({
    required this.systemTokens,
    required this.toolsTokens,
    required this.historyTokens,
    required this.windowTokens,
  });

  final int systemTokens;
  final int toolsTokens;
  final int historyTokens;
  final int windowTokens;

  int get usedTokens => systemTokens + toolsTokens + historyTokens;

  /// 实际可用预算为窗口的 90%（与聊天共用同一规则）。
  int get budgetTokens => (windowTokens * 0.9).floor();

  int get remainingTokens => math.max(0, budgetTokens - usedTokens);

  double get ratio => windowTokens <= 0 ? 0 : usedTokens / windowTokens;
}
