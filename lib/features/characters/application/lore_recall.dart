import '../domain/lore_entry.dart';

/// 世界书关键词匹配：大小写不敏感，中文按子串。
///
/// 只匹配 [enabled] 条目；按 priority 倒序、关键词长度、创建时间排序。
List<LoreEntry> matchLoreEntries({
  required List<LoreEntry> entries,
  required String query,
  int maxEntries = 20,
}) {
  final text = query.toLowerCase();
  if (text.trim().isEmpty) return const [];
  final scored = <({LoreEntry entry, int score})>[];
  for (final entry in entries) {
    if (!entry.enabled || entry.content.trim().isEmpty) continue;
    var best = 0;
    for (final key in entry.keys) {
      final k = key.trim().toLowerCase();
      if (k.isEmpty) continue;
      if (text.contains(k) && k.length > best) best = k.length;
    }
    if (best == 0) continue;
    scored.add((entry: entry, score: entry.priority * 100 + best));
  }
  scored.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    return byScore != 0
        ? byScore
        : b.entry.createdAt.compareTo(a.entry.createdAt);
  });
  return scored.take(maxEntries).map((e) => e.entry).toList();
}
