import '../../../core/utils/token_estimate.dart';
import '../domain/memory_fact.dart';

/// 按当前对话内容召回长期事实（不新增表，只做筛选与排序）。
///
/// 规则：关键词命中（中文按子串/二元组，英文按词）、越近权重越高、最多
/// [maxFacts] 条且不超过 [maxTokens]。
List<MemoryFact> recallMemoryFacts({
  required List<MemoryFact> facts,
  required String query,
  int maxFacts = 12,
  int maxTokens = 800,
  DateTime? now,
}) {
  if (facts.isEmpty || query.trim().isEmpty) return const [];
  final tokens = _queryTokens(query);
  final current = now ?? DateTime.now();
  final scored = <({MemoryFact fact, double score})>[];
  for (final fact in facts) {
    final text = fact.fact.toLowerCase();
    var hits = 0.0;
    for (final token in tokens) {
      if (text.contains(token)) hits += token.length.toDouble();
    }
    if (hits <= 0) continue;
    final days = current.difference(fact.occurredAt).inHours / 24.0;
    final recency = 1.0 / (1.0 + days.abs() / 30.0);
    scored.add((fact: fact, score: hits + recency));
  }
  scored.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    return byScore != 0
        ? byScore
        : b.fact.occurredAt.compareTo(a.fact.occurredAt);
  });
  final result = <MemoryFact>[];
  var used = 0;
  for (final item in scored) {
    if (result.length >= maxFacts) break;
    final line = '[${_date(item.fact.occurredAt)}] ${item.fact.fact}';
    final cost = estimateTokens(line);
    if (result.isNotEmpty && used + cost > maxTokens) break;
    result.add(item.fact);
    used += cost;
  }
  return result;
}

/// 中文取 2 字滑窗，英文/数字取长度 ≥2 的词。
List<String> _queryTokens(String query) {
  final lower = query.toLowerCase();
  final tokens = <String>{};
  for (final match in RegExp(r'[a-z0-9_]{2,}').allMatches(lower)) {
    tokens.add(match.group(0)!);
  }
  final cjk = RegExp(r'[\u3400-\u9fff]+').allMatches(lower);
  for (final match in cjk) {
    final run = match.group(0)!;
    if (run.length == 1) {
      tokens.add(run);
      continue;
    }
    for (var i = 0; i + 1 < run.length; i++) {
      tokens.add(run.substring(i, i + 2));
    }
  }
  return tokens.toList();
}

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
