/// 世界书条目（Lorebook / World Info）。
///
/// 只在 [keys] 命中当前对话时注入提示词；[position] 决定插在历史消息前还是后，
/// [depth] 越小越贴近当前消息，[priority] 越大越优先。
class LoreEntry {
  const LoreEntry({
    required this.id,
    required this.characterId,
    required this.keys,
    required this.content,
    this.position = 'before',
    this.depth = 0,
    this.priority = 0,
    this.enabled = true,
    this.sourceJson = '{}',
    required this.createdAt,
  });

  final String id;
  final String characterId;
  final List<String> keys;
  final String content;
  final String position;
  final int depth;
  final int priority;
  final bool enabled;

  /// 导入时的完整条目原文（`{}` 表示非导入 / 已无原文）。
  final String sourceJson;

  final DateTime createdAt;

  bool get isBefore => position != 'after';

  LoreEntry copyWith({
    String? id,
    String? characterId,
    List<String>? keys,
    String? content,
    String? position,
    int? depth,
    int? priority,
    bool? enabled,
    String? sourceJson,
    DateTime? createdAt,
  }) {
    return LoreEntry(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      keys: keys ?? this.keys,
      content: content ?? this.content,
      position: position ?? this.position,
      depth: depth ?? this.depth,
      priority: priority ?? this.priority,
      enabled: enabled ?? this.enabled,
      sourceJson: sourceJson ?? this.sourceJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoreEntry &&
          other.id == id &&
          other.characterId == characterId &&
          other.content == content &&
          other.position == position &&
          other.depth == depth &&
          other.priority == priority &&
          other.enabled == enabled &&
          other.sourceJson == sourceJson;

  @override
  int get hashCode => Object.hash(
    id,
    characterId,
    content,
    position,
    depth,
    priority,
    enabled,
    sourceJson,
  );
}
