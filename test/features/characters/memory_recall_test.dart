import 'package:flutter_test/flutter_test.dart';

import 'package:ai_roleplay_chat/features/characters/application/memory_recall.dart';
import 'package:ai_roleplay_chat/features/characters/domain/memory_fact.dart';

MemoryFact _fact(String text, DateTime at) => MemoryFact(
  id: text,
  characterId: 'ch1',
  fact: text,
  occurredAt: at,
  createdAt: at,
);

void main() {
  final now = DateTime(2026, 11, 26);

  test('关键词命中才召回，中文按二元组', () {
    final facts = [
      _fact('和用户去了关山', now.subtract(const Duration(days: 2))),
      _fact('用户喜欢草莓', now.subtract(const Duration(days: 10))),
    ];
    final hit = recallMemoryFacts(
      facts: facts,
      query: '你还记得关山吗',
      now: now,
    );
    expect(hit.map((e) => e.fact), contains('和用户去了关山'));
    expect(hit.map((e) => e.fact), isNot(contains('用户喜欢草莓')));
  });

  test('无命中返回空，避免无关事实占预算', () {
    final facts = [_fact('用户喜欢草莓', now)];
    expect(
      recallMemoryFacts(facts: facts, query: '今天天气怎么样', now: now),
      isEmpty,
    );
  });

  test('多条命中时越近权重越高', () {
    final facts = [
      _fact('关山旅行', now.subtract(const Duration(days: 120))),
      _fact('关山旅行', now.subtract(const Duration(days: 1))),
    ];
    final hit = recallMemoryFacts(facts: facts, query: '关山', now: now);
    expect(hit, hasLength(2));
    expect(hit.first.occurredAt, now.subtract(const Duration(days: 1)));
  });

  test('最多 12 条', () {
    final facts = [
      for (var i = 0; i < 20; i++)
        _fact('关山 $i', now.subtract(Duration(days: i))),
    ];
    expect(
      recallMemoryFacts(facts: facts, query: '关山', now: now),
      hasLength(12),
    );
  });

  test('token 预算截断（保留至少 1 条）', () {
    final facts = [
      _fact('关山' * 200, now),
      _fact('关山' * 200, now.subtract(const Duration(days: 1))),
    ];
    final hit = recallMemoryFacts(
      facts: facts,
      query: '关山',
      maxTokens: 10,
      now: now,
    );
    expect(hit, hasLength(1));
  });
}
