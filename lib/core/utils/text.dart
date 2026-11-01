/// 文本工具：会话标题截取、LLM 单行输出清洗。
library;

/// 从消息文本截取会话标题（按 rune 截断，避免劈开 emoji 代理对）。
String titleFrom(String text, [int maxRunes = 20]) {
  final t = text.trim();
  final runes = t.runes.toList();
  if (runes.length <= maxRunes) return t;
  return '${String.fromCharCodes(runes.take(maxRunes))}…';
}

/// 清洗 LLM 单行输出（标题/图片概括）：取首行、剥包裹引号。
String cleanLlmLine(String raw) {
  var t = raw.trim();
  final nl = t.indexOf('\n');
  if (nl >= 0) t = t.substring(0, nl).trim();
  const quotes = "「」“”\"'";
  while (t.isNotEmpty && quotes.contains(t[0])) {
    t = t.substring(1);
  }
  while (t.isNotEmpty && quotes.contains(t[t.length - 1])) {
    t = t.substring(0, t.length - 1);
  }
  return t.trim();
}
