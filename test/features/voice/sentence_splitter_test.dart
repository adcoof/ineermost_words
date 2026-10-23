import 'package:ai_roleplay_chat/features/voice/application/sentence_splitter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SentenceSplitter', () {
    test('整段一次性切分', () {
      final s = SentenceSplitter();
      final out = s.splitAll('你好！今天天气不错。真的吗？真的。');
      expect(out, ['你好！', '今天天气不错。', '真的吗？', '真的。']);
    });

    test('流式逐段喂入：跨增量句子在完整时才吐出', () {
      final s = SentenceSplitter();
      expect(s.feed('你好，今天'), isEmpty);
      expect(s.feed('天气不错。下'), ['你好，今天天气不错。']);
      expect(s.feed('一句。'), ['下一句。']);
      expect(s.flush(), '');
    });

    test('尾段无终止符：flush 吐出', () {
      final s = SentenceSplitter();
      s.feed('最后一句没有标点');
      expect(s.flush(), '最后一句没有标点');
    });

    test('连续终止符与收尾引号合并进前句', () {
      final s = SentenceSplitter();
      final out = s.splitAll('「你说什么？！」\n嗯。');
      expect(out, ['「你说什么？！」', '嗯。']);
    });

    test('换行视为句子边界', () {
      final s = SentenceSplitter();
      final out = s.splitAll('第一行\n第二行\n');
      expect(out, ['第一行', '第二行']);
    });

    test('空文本与纯空白', () {
      final s = SentenceSplitter();
      expect(s.splitAll(''), isEmpty);
      expect(s.splitAll('   \n  '), isEmpty);
    });

    test('逐字符喂入（极端切断）', () {
      final s = SentenceSplitter();
      const text = '啊。嗯！好？';
      final out = <String>[];
      for (final ch in text.split('')) {
        out.addAll(s.feed(ch));
      }
      final tail = s.flush();
      if (tail.isNotEmpty) out.add(tail);
      expect(out, ['啊。', '嗯！', '好？']);
    });
  });
}
