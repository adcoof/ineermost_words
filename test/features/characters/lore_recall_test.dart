import 'package:flutter_test/flutter_test.dart';

import 'package:ai_roleplay_chat/features/characters/application/lore_recall.dart';
import 'package:ai_roleplay_chat/features/characters/domain/lore_entry.dart';

LoreEntry _entry(
  String id,
  List<String> keys, {
  int priority = 0,
  bool enabled = true,
  DateTime? createdAt,
  String position = 'before',
  int depth = 0,
}) => LoreEntry(
  id: id,
  characterId: 'ch1',
  keys: keys,
  content: '$id 的内容',
  position: position,
  depth: depth,
  priority: priority,
  enabled: enabled,
  createdAt: createdAt ?? DateTime(2026, 1, 1),
);

void main() {
  test('大小写不敏感、中文子串命中', () {
    final entries = [
      _entry('a', ['Rooftop']),
      _entry('b', ['天台']),
      _entry('c', ['教室']),
    ];
    final hit = matchLoreEntries(entries: entries, query: '我们在 rooftop 和天台');
    expect(hit.map((e) => e.id), ['a', 'b']);
  });

  test('禁用条目不命中', () {
    final entries = [_entry('a', ['天台'], enabled: false)];
    expect(matchLoreEntries(entries: entries, query: '天台'), isEmpty);
  });

  test('按优先级/关键词长度排序，最多 20 条', () {
    final entries = [
      for (var i = 0; i < 25; i++)
        _entry('e$i', ['天台'], priority: i),
    ];
    final hit = matchLoreEntries(entries: entries, query: '天台');
    expect(hit, hasLength(20));
    expect(hit.first.id, 'e24');
  });

  test('空关键词/空查询不命中', () {
    final entries = [_entry('a', [''])];
    expect(matchLoreEntries(entries: entries, query: '天台'), isEmpty);
    expect(
      matchLoreEntries(entries: [_entry('b', ['天台'])], query: '   '),
      isEmpty,
    );
  });
}
