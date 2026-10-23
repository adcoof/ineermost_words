/// 句级切分：把助手回复的干净文本按终止标点切成可逐句朗读的片段。
library;

class SentenceSplitter {
  SentenceSplitter();

  static const _terminators = '。！？!?…\n';

  /// 增量切分器：喂入流式文本，吐出"已完整"的句子；
  /// 尾部不完整的片段滞留，[flush] 时作为最后一句吐出。
  String _pending = '';

  /// 喂入一段增量，返回本次新完整的句子列表。
  List<String> feed(String chunk) {
    _pending += chunk;
    final out = <String>[];
    var start = 0;
    for (var i = 0; i < _pending.length; i++) {
      if (_terminators.contains(_pending[i])) {
        // 吞掉连续的终止符/空白（含换行）。
        var end = i + 1;
        while (end < _pending.length &&
            (_terminators.contains(_pending[end]) ||
                _pending[end] == ' ' ||
                _pending[end] == '”' ||
                _pending[end] == '」' ||
                _pending[end] == '）' ||
                _pending[end] == '"')) {
          end++;
        }
        final sentence = _pending.substring(start, end).trim();
        if (sentence.isNotEmpty) out.add(sentence);
        start = end;
        i = end - 1;
      }
    }
    _pending = start == 0 ? _pending : _pending.substring(start);
    return out;
  }

  /// 流结束：吐出滞留的尾段（若有实质内容）。
  String flush() {
    final rest = _pending.trim();
    _pending = '';
    return rest;
  }

  /// 一次性切分整段文本（设置页试听等场景）。
  List<String> splitAll(String text) {
    final s = SentenceSplitter();
    final out = s.feed(text);
    final tail = s.flush();
    if (tail.isNotEmpty) out.add(tail);
    return out;
  }
}
