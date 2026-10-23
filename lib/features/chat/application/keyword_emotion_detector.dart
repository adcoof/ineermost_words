/// 基于关键词的情绪探测：模型没输出 <emotion:> 标签时的兜底触发。
///
/// 与 [EmotionTagParser] 互补：标签是精确通道（有事件就用），
/// 关键词是宽松通道（仅当本段干净文本没有产生任何标签事件时扫描），
/// 命中的事件走同一条 EmotionEvent 流，由 EmotionMapper 映射到桌宠。
///
/// 误触发抑制：
/// - 中文触发词前一个字（或「没有」两字）为 不/没/别/莫/无/非 时跳过
///   （「别生气」「我没有生气」不触发）；
/// - 英文触发词按 \\b 词边界匹配（unhappy/hangry 不触发）。
library;

import 'emotion_tag_parser.dart';

class KeywordEmotionDetector {
  const KeywordEmotionDetector();

  /// 情绪 tag → 触发词（中英混合，扫描时统一小写）。
  static const Map<String, List<String>> keywords = {
    'angry': [
      '生气', '愤怒', '气呼呼', '恼火', '火大', '发怒', '气死', '气炸',
      'furious', 'so mad', 'angry',
    ],
    'happy': [
      '开心', '高兴', '快乐', '笑嘻嘻', '嘻嘻', '哈哈', '太好了', '喜悦',
      'happy', 'glad', 'so cute',
    ],
    'sad': [
      '难过', '伤心', '呜呜', '泪水', '悲伤', '哭了', '眼眶红',
      'sad', 'tears',
    ],
    'shy': [
      '害羞', '脸红', '不好意思', '难为情', '羞涩',
      'blush', 'shy',
    ],
    'surprised': [
      '惊讶', '吃惊', '吓到', '没想到', '居然',
      'surprised', 'startled',
    ],
  };

  static final RegExp _asciiWordRe = RegExp(r'^[a-z ]+$');
  static const _negationChars = '不没别莫无非';

  /// 扫描一段干净文本，返回命中的情绪事件（每种情绪最多一次，按固定顺序）。
  List<EmotionEvent> detect(String text) {
    if (text.trim().isEmpty) return const [];
    final lower = text.toLowerCase();
    final out = <EmotionEvent>[];
    keywords.forEach((tag, words) {
      for (final w in words) {
        if (_contains(lower, w)) {
          out.add(EmotionEvent('emotion', tag));
          return; // 该情绪已命中，跳出单词循环。
        }
      }
    });
    return out;
  }

  /// 单个触发词是否命中（含否定/词边界抑制）。
  bool _contains(String lowerText, String word) {
    final w = word.toLowerCase();
    if (_asciiWordRe.hasMatch(w)) {
      // 英文短语/单词：词边界匹配，避免 unhappy→happy、hangry→angry。
      return RegExp('\\b${RegExp.escape(w)}\\b').hasMatch(lowerText);
    }
    // 中文：逐个出现位置检查否定前缀。
    var idx = lowerText.indexOf(w);
    while (idx != -1) {
      if (idx == 0 || !_isNegated(lowerText, idx)) {
        return true;
      }
      idx = lowerText.indexOf(w, idx + w.length);
    }
    return false;
  }

  /// 位置 [idx] 处的中文触发词是否被否定（前一字或「没有」两字）。
  bool _isNegated(String text, int idx) {
    if (_negationChars.contains(text[idx - 1])) return true;
    if (idx >= 2 && text.substring(idx - 2, idx) == '没有') return true;
    return false;
  }
}
