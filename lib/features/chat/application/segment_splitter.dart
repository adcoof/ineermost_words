/// 流式分段器：识别模型输出中的 `[P]` 独行分隔符，把一轮回复切成多段。
///
/// 检测是**行制**的：只有当 `[P]` 占满一整行（trim 后精确相等）才算边界。
/// 标记被切成多个 chunk 送入时行未完成、不会触发，天然免疫
/// `[Project]`、句中 `[P]`、跨 chunk 误报。超过段数上限后 `[P]` 行按字面输出。
library;

/// 分段事件：一段文本（可安全喂给 EmotionTagParser）或一个分段边界。
class SplitEvent {
  final String? text;

  final bool isBoundary;

  const SplitEvent.text(String this.text) : isBoundary = false;

  const SplitEvent.boundary() : text = null, isBoundary = true;
}

class SegmentSplitter {
  /// 一轮回复最多 4 段 = 最多 3 个边界。
  static const int maxSegments = 4;

  static const String marker = '[P]';

  /// 已发出的边界数。
  int _boundaries = 0;

  /// 当前未完成行（不含换行符）。
  final StringBuffer _line = StringBuffer();

  /// 喂入一个原始 chunk，返回按序的文本/边界事件。
  ///
  /// 非边界行连同其换行符作为文本事件发出；`[P]` 边界行本身被吞掉
  /// （不进文本、换行也不进），由调用方负责结束当前段。
  List<SplitEvent> feed(String chunk) {
    final events = <SplitEvent>[];
    var start = 0;
    for (var i = 0; i < chunk.length; i++) {
      if (chunk.codeUnitAt(i) != 0x0A) continue; // '\n'
      final line = '$_line${chunk.substring(start, i)}';
      _line.clear();
      start = i + 1;
      if (_boundaries < maxSegments - 1 && line.trim() == marker) {
        _boundaries++;
        events.add(const SplitEvent.boundary());
      } else {
        // 普通行（含上限后的字面 [P] 行）原样进文本。
        events.add(SplitEvent.text('$line\n'));
      }
    }
    if (start < chunk.length) {
      _line.write(chunk.substring(start));
    }
    return events;
  }

  /// 流结束：返回未完成的尾行文本；孤悬的尾部 `[P]`（无换行收尾）丢弃。
  String flush() {
    final rest = _line.toString();
    _line.clear();
    if (rest.trim() == marker && _boundaries < maxSegments - 1) return '';
    return rest;
  }
}

/// 兜底分段（v8.3 真机）：模型不守 `[P]` 规范时，一轮回复依旧是一大段。
///
/// 真机观察：提示词已放在最后一条 system、带正例，模型（不同供应商/角色卡
/// 差异很大）仍会整段输出，还夹着空行分自然段。客户端不能指望模型自觉，
/// 于是在**一轮只产生一条文本消息**时按下面的规则补切：
/// 1. 优先按空行分段——模型自己划的自然段就是消息边界；
/// 2. 没有空行但明显偏长时，退到逐行 / 逐句；
/// 3. 单元仍过长（> 2×[softLimit]）时按句末标点切并贪心装桶；
/// 4. 总条数超过 [maxParts] 时按顺序均匀合并；
/// 5. 过短的碎片（如单独的"……"）并回上一条，避免发一串逗号气泡。
///
/// 返回原样单条（长度 1）表示不需要拆。
List<String> splitLongReply(
  String text, {
  int maxParts = SegmentSplitter.maxSegments,
  int softLimit = 80,
}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const [];
  if (maxParts <= 1) return [trimmed];

  // 1. 空行分段。
  var units = trimmed
      .split(RegExp(r'\n[ \t]*\n'))
      .map((u) => u.trim())
      .where((u) => u.isNotEmpty)
      .toList();

  // 2. 没有空行但偏长：退到逐行，再退到逐句。
  if (units.length <= 1 && trimmed.length > softLimit) {
    final lines = trimmed
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    units = lines.length > 1 ? lines : _splitSentences(trimmed);
  }

  if (units.length <= 1) return [trimmed];

  // 3. 单个单元过长时再按句子切。
  final expanded = <String>[];
  for (final unit in units) {
    if (unit.length > softLimit * 2) {
      expanded.addAll(_packSentences(_splitSentences(unit), softLimit));
    } else {
      expanded.add(unit);
    }
  }

  // 4. 条数超上限：均匀合并。
  final limited = expanded.length <= maxParts
      ? expanded
      : _mergeEvenly(expanded, maxParts);

  // 5. 纯标点碎片（如单独的"……"）并回上一条，避免发一串逗号气泡。
  final merged = <String>[];
  for (final part in limited) {
    if (merged.isNotEmpty && !_hasWordRe.hasMatch(part)) {
      merged[merged.length - 1] = '${merged.last}\n$part';
    } else {
      merged.add(part);
    }
  }
  return merged;
}

/// 含至少一个文字/数字（纯标点碎片判据）。
final RegExp _hasWordRe = RegExp(r'[\p{L}\p{N}]', unicode: true);

const _sentenceEnders = '。！？!?…；;';

List<String> _splitSentences(String text) {
  final out = <String>[];
  final buf = StringBuffer();
  for (final rune in text.runes) {
    final ch = String.fromCharCode(rune);
    buf.write(ch);
    if (_sentenceEnders.contains(ch)) {
      final piece = buf.toString().trim();
      if (piece.isNotEmpty) out.add(piece);
      buf.clear();
    }
  }
  final rest = buf.toString().trim();
  if (rest.isNotEmpty) out.add(rest);
  return out;
}

/// 贪心装桶：把句子按顺序拼进不超过 [limit] 字的桶。
List<String> _packSentences(List<String> sentences, int limit) {
  if (sentences.isEmpty) return const [];
  final out = <String>[];
  var buf = StringBuffer();
  for (final s in sentences) {
    if (buf.isNotEmpty && buf.length + s.length > limit) {
      out.add(buf.toString());
      buf = StringBuffer();
    }
    buf.write(s);
  }
  if (buf.isNotEmpty) out.add(buf.toString());
  return out;
}

List<String> _mergeEvenly(List<String> units, int maxParts) {
  final chunk = (units.length / maxParts).ceil();
  final out = <String>[];
  for (var i = 0; i < units.length; i += chunk) {
    final end = i + chunk < units.length ? i + chunk : units.length;
    out.add(units.sublist(i, end).join('\n'));
  }
  return out;
}
