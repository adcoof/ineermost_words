/// 流式安全的情绪/动作标签解析器。
///
/// 语法：`<emotion:happy>` / `<action:wave>`（名字为 [A-Za-z0-9_-]+）。
/// 输出：剥离标签后的干净文本 + 事件序列。标签可能被 SSE chunk 任意切断，
/// 解析器把"可能仍是标签前缀"的部分滞留在 pending，等后续 feed 补全。
library;

import 'dart:convert';

/// 一个情绪/动作事件。
class EmotionEvent {
  /// emotion | action
  final String kind;

  /// 标签名，如 happy / wave。
  final String value;

  const EmotionEvent(this.kind, this.value);

  Map<String, dynamic> toJson() => {'kind': kind, 'value': value};

  static EmotionEvent fromJson(Map<String, dynamic> json) =>
      EmotionEvent(json['kind']?.toString() ?? 'emotion',
          json['value']?.toString() ?? '');

  @override
  bool operator ==(Object other) =>
      other is EmotionEvent && other.kind == kind && other.value == value;

  @override
  int get hashCode => Object.hash(kind, value);

  @override
  String toString() => '<$kind:$value>';
}

/// 一次 [EmotionTagParser.feed] 的结果。
class TagFeedResult {
  /// 本次吐出的干净文本（标签已剥离）。
  final String flushed;

  /// 本次解析出的事件。
  final List<EmotionEvent> events;

  const TagFeedResult(this.flushed, this.events);
}

class EmotionTagParser {
  /// 尚未判定的滞留文本（可能是被切断的标签前缀）。
  String _pending = '';

  /// 合法标签内层（< 与 > 之间）：
  /// - `<emotion:happy>` / `<action:wave/>`（名字 + 可选自闭合斜杠）
  /// - `<emotion>` / `</emotion>`（模型常输出的无名/闭合变体，剥离但不产事件）
  static final RegExp _tagRe =
      RegExp(r'^\/?(emotion|action)(:([A-Za-z0-9_\-]+))?\/?$');

  /// 喂入一段增量，返回可立即展示的干净文本与新事件。
  TagFeedResult feed(String chunk) {
    final buffer = _pending + chunk;
    final out = StringBuffer();
    final events = <EmotionEvent>[];

    var i = 0;
    var safeStart = 0;
    var held = false;

    while (i < buffer.length) {
      if (buffer[i] != '<') {
        i++;
        continue;
      }
      final gt = buffer.indexOf('>', i + 1);
      if (gt == -1) {
        // 还没等到 '>'：判断从这里起是否仍可能构成标签。
        if (_couldBeTagPrefix(buffer.substring(i + 1))) {
          held = true;
          break; // 安全输出边界停在 '<' 之前。
        }
        i++; // '<' 是普通字符，继续扫描。
        continue;
      }
      final m = _tagRe.firstMatch(buffer.substring(i + 1, gt));
      if (m != null) {
        out.write(buffer.substring(safeStart, i));
        final name = m.group(3);
        if (name != null) {
          events.add(EmotionEvent(m.group(1)!, name));
        }
        i = gt + 1;
        safeStart = i;
      } else {
        i++; // 形似但非法的标签，按普通文本处理。
      }
    }

    if (held) {
      out.write(buffer.substring(safeStart, i));
      _pending = buffer.substring(i);
    } else {
      out.write(buffer.substring(safeStart));
      _pending = '';
    }
    return TagFeedResult(out.toString(), events);
  }

  /// 流结束：把滞留内容按普通文本吐出（如被 max_tokens 截断的半个标签）。
  String flush() {
    final rest = _pending;
    _pending = '';
    return rest;
  }

  /// 从 `s` 起（紧跟 '<' 之后）是否仍可能补全为一个合法标签。
  static bool _couldBeTagPrefix(String s) {
    if (s.isEmpty) return true; // 只来了一个 '<'，先观望。
    var t = s.startsWith('/') ? s.substring(1) : s;
    if ('emotion'.startsWith(t) || 'action'.startsWith(t)) return true;
    for (final kw in const ['emotion', 'action']) {
      if (!t.startsWith(kw)) continue;
      var rest = t.substring(kw.length);
      if (rest.startsWith('/')) {
        rest = rest.substring(1);
        // 自闭合结尾后不应再有名字；'emotion/:x' 形状永远不会匹配 _tagRe，
        // 继续滞留只会让 pending 无界增长。
        if (rest.startsWith(':')) return false;
      }
      if (rest.isEmpty || rest == ':') return true;
      if (rest.startsWith(':')) {
        var name = rest.substring(1);
        if (name.endsWith('/')) name = name.substring(0, name.length - 1);
        return RegExp(r'^[A-Za-z0-9_\-]*$').hasMatch(name);
      }
      return false;
    }
    return false;
  }

  /// 事件列表 → 存库用 JSON 数组。
  static String encodeEvents(List<EmotionEvent> events) =>
      jsonEncode([for (final e in events) e.toJson()]);

  /// 存库 JSON 数组 → 事件列表。
  static List<EmotionEvent> decodeEvents(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List) return const [];
      return [
        for (final e in decoded)
          if (e is Map) EmotionEvent.fromJson(Map<String, dynamic>.from(e))
      ];
    } catch (_) {
      return const [];
    }
  }
}
