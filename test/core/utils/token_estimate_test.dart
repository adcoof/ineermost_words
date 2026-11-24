import 'package:ai_roleplay_chat/core/utils/token_estimate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('estimateTokens', () {
    test('空字符串为 0', () {
      expect(estimateTokens(''), 0);
    });

    test('中文按 1.2 token/字估算并向上取整', () {
      expect(estimateTokens('你好'), 3); // 2 * 1.2 = 2.4 -> 3
      expect(estimateTokens('心语'), 3);
    });

    test('英文/数字按 3.5 字符/token 估算并向上取整', () {
      expect(estimateTokens('hello world'), 4); // 11 / 3.5 = 3.14 -> 4
      expect(estimateTokens('1234567'), 2); // 7 / 3.5 = 2
    });

    test('中英混合分别累计', () {
      // 4 个汉字 = 4.8；"abc" = 0.857 -> 合计 5.657 -> 6
      expect(estimateTokens('你好世界abc'), 6);
    });

    test('emoji 按非中文计，不因代理对翻倍', () {
      expect(estimateTokens('😀'), 1); // 1 / 3.5 -> ceil 1
    });

    test('换行与标点也计入', () {
      expect(estimateTokens('你好，\n世界'), greaterThan(estimateTokens('你好世界')));
    });
  });

  group('truncateToTokens', () {
    test('未超预算时原样返回', () {
      expect(truncateToTokens('短句', 10), '短句');
    });

    test('maxTokens <= 0 返回空串', () {
      expect(truncateToTokens('你好世界', 0), '');
      expect(truncateToTokens('你好世界', -1), '');
    });

    test('超预算时截断并带省略号，估算不超过上限', () {
      final text = '这是一段很长很长的测试文本，用来验证截断功能是否正常工作。';
      final cut = truncateToTokens(text, 10);
      expect(cut.endsWith('…'), isTrue);
      expect(estimateTokens(cut), lessThanOrEqualTo(10));
      expect(cut.length, lessThan(text.length));
    });

    test('尽量在标点处收尾，避免半句', () {
      final cut = truncateToTokens('第一句。第二句很长很长很长。', 12);
      expect(cut, '第一句。…');
    });
  });
}
