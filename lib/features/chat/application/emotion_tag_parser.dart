/// 流式安全的情绪/动作标签解析器。
///
/// 语法：`<emotion:happy>` / `<action:wave>`（名字为 [A-Za-z0-9_-]+）。
/// 输出：剥离标签后的干净文本 + 事件序列。标签可能被 SSE chunk 任意切断，
/// 解析器把"可能仍是标签前缀"的部分滞留在 pending，等后续 feed 补全。
///
/// 容错（v8.1 真机反馈）：模型常输出变体——
/// `<action>`/`</action>`、`<Action:Wave>`、`< action : wave >`、
/// `<action wave>`、`<emotion：开心>`（全角冒号/中文名）、
/// `＜action：wave＞`（全角尖括号）。这些也必须剥离，否则标签会漏到
/// 气泡文本里（用户可见）。
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

  static EmotionEvent fromJson(Map<String, dynamic> json) => EmotionEvent(
    json['kind']?.toString() ?? 'emotion',
    json['value']?.toString() ?? '',
  );

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

  /// 情绪/动作标签内层（< 与 > 之间），大小写不敏感：
  /// - `<emotion:happy>` / `<action:wave/>`（关键字 + 可选分隔 + 名字 + 可选自闭合斜杠）
  /// - `<action wave>` / `<emotion：开心>`（空白分隔、全角冒号、非英文名字）
  /// - `<emotion>` / `</emotion>`（模型常输出的无名/闭合变体，剥离但不产事件）
  static final RegExp _tagRe = RegExp(
    r'^\/?\s*(emotion|action)\s*(?:(?:[:：]\s*|\s+)([^<>]*?))?\s*\/?$',
    caseSensitive: false,
  );

  /// 任意"形如标签"的标记内层（v8.2）：模型还会自造 `<whisper>`、`<shout>`、
  /// `<run_away>`、`<glare>` 之类的舞台提示，漏一个就会显示在气泡里。
  /// 首个字符必须是字母（排除 `<3`、`< 4`），内容限 30 字符且不含标点，
  /// 因此普通文本里的数学小于号不会被误伤。
  static final RegExp _anyTagRe = RegExp(
    r'^\/?\s*\p{L}[\p{L}\p{N}_:\-./ ]{0,29}\/?$',
    unicode: true,
  );

  /// 标签字符集（用于流式中判断"这个 '<' 还可能是标签前缀"）。
  static final RegExp _tagCharsRe = RegExp(
    r'^[\s\p{L}\p{N}_:\-./]*$',
    unicode: true,
  );

  /// 整段文本一次性剥离用的全局版本（[stripTagMarkup]），先剥情绪/动作
  /// 标签（名字不限字符），再剥任意形似标签的标记。
  static final RegExp _tagMarkupRe = RegExp(
    r'<\s*\/?\s*(?:emotion|action)\s*(?:(?:[:：]\s*|\s+)[^<>]*?)?\s*\/?[>＞]',
    caseSensitive: false,
  );

  static final RegExp _anyTagMarkupRe = RegExp(
    r'<\s*\/?\s*\p{L}[\p{L}\p{N}_:\-./ ]{0,29}\/?\s*>',
    unicode: true,
  );

  /// 喂入一段增量，返回可立即展示的干净文本与新事件。
  TagFeedResult feed(String chunk) {
    final buffer = _normalize(_pending + chunk);
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
      final inner = buffer.substring(i + 1, gt);
      final m = _tagRe.firstMatch(inner);
      // 情绪/动作标签产事件；其余形似标签的标记（<whisper> 等）只剥离。
      if (m != null || _anyTagRe.hasMatch(inner)) {
        out.write(buffer.substring(safeStart, i));
        if (m != null) {
          final kind = m.group(1)!.toLowerCase();
          final name = (m.group(2) ?? '').trim();
          if (name.isNotEmpty) {
            events.add(EmotionEvent(kind, name.toLowerCase()));
          }
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

  /// 全角尖括号归一：模型偶尔输出 `＜action：wave＞`。
  static String _normalize(String s) {
    if (!s.contains('＜') && !s.contains('＞')) return s;
    return s.replaceAll('＜', '<').replaceAll('＞', '>');
  }

  /// 从 `s` 起（紧跟 '<' 之后）是否仍可能补全为一个标签（含自造标签）。
  ///
  /// 只要已收到的片段仍落在"标签字符集"内就继续观望；一旦出现标点等
  /// 非标签字符（如 `a < b，c`），立刻判定为普通文本里的 '<'，不滞留——
  /// 否则流式输出会卡住后面的正文直到段落结束。
  static bool _couldBeTagPrefix(String s) {
    if (s.isEmpty) return true; // 只来了一个 '<'，先观望。
    if (s.length > 32) return false;
    if (s.contains('<')) return false;
    if (s.trim().isEmpty) return true;
    return _tagCharsRe.hasMatch(s);
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
          if (e is Map) EmotionEvent.fromJson(Map<String, dynamic>.from(e)),
      ];
    } catch (_) {
      return const [];
    }
  }
}

/// 非流式一次性剥离标签标记（气泡展示 / 历史脏数据清洗用）。
///
/// 与 [EmotionTagParser] 判定口径一致；`<` 后必须是字母，且内容是纯
/// 标签字符，所以 'a < b'、'2<3>4'、'3 < 4' 不会被误伤。
String stripTagMarkup(String text) {
  if (!text.contains('<') && !text.contains('＜') && !text.contains('＞')) {
    return text;
  }
  final normalized = text.replaceAll('＜', '<').replaceAll('＞', '>');
  return normalized
      .replaceAll(EmotionTagParser._tagMarkupRe, '')
      .replaceAll(EmotionTagParser._anyTagMarkupRe, '');
}
