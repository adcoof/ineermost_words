/// 长期事实记忆：一条事件 + 发生日期，不含过程细节。
///
/// 由记忆整理器从对话中抽取（v1.4 M3 记忆压缩），注入提示词时只给
/// 「日期 + 事实」，让角色记得发生过什么、但被问细节时自然说记不清。
library;

/// 每角色保留的事实上限；超出按发生日期淘汰最旧。
const int kMemoryFactsMax = 240;

class MemoryFact {
  final String id;
  final String characterId;

  /// 一事一条的短事实（如「用户去关山游玩」）。
  final String fact;

  /// 事件发生日（本地 00:00），不是整理时间。
  final DateTime occurredAt;

  final String? sourceConversationId;

  /// 入库时间（用于同一天多条事实的稳定排序）。
  final DateTime createdAt;

  const MemoryFact({
    required this.id,
    required this.characterId,
    required this.fact,
    required this.occurredAt,
    this.sourceConversationId,
    required this.createdAt,
  });
}
