/// 粗略 token 估算：不依赖供应商 tokenizer，只用于上下文预算。
///
/// 经验值：中文 1 字 ≈ 1.2 token，其他（英文/数字/标点）约 3.5 字符 ≈ 1 token。
/// 估算不承诺与真实 tokenizer 完全一致；调用方按窗口的 90% 使用，留出误差。
library;

int estimateTokens(String text) {
  if (text.isEmpty) return 0;
  var cjk = 0;
  var other = 0;
  for (final r in text.runes) {
    if (_isCjk(r)) {
      cjk++;
    } else {
      other++;
    }
  }
  return (cjk * 1.2 + other / 3.5).ceil();
}

/// 按估算 token 从头部截断，尽量在标点/空白处收尾，避免劈开代理对。
String truncateToTokens(String text, int maxTokens) {
  if (maxTokens <= 0) return '';
  if (estimateTokens(text) <= maxTokens) return text;
  var cost = 0.0;
  var end = 0;
  var lastBreak = -1;
  for (final r in text.runes) {
    final next = cost + (_isCjk(r) ? 1.2 : 1 / 3.5);
    if (next > maxTokens) break;
    cost = next;
    end++;
    if (r == 0x0A || r == 0x3002 || r == 0xFF01 || r == 0xFF1F ||
        r == 0x21 || r == 0x3F || r == 0x2E) {
      lastBreak = end;
    }
  }
  final cut = lastBreak > 0 ? lastBreak : end;
  final body = String.fromCharCodes(text.runes.take(cut)).trimRight();
  return '$body…';
}

bool _isCjk(int r) =>
    (r >= 0x3400 && r <= 0x9FFF) || // 扩展 A + 基本区
    (r >= 0xF900 && r <= 0xFAFF) || // 兼容区
    (r >= 0x3040 && r <= 0x30FF) || // 日文假名
    (r >= 0xAC00 && r <= 0xD7AF); // 韩文
