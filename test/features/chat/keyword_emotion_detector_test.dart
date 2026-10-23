import 'package:ai_roleplay_chat/features/chat/application/emotion_tag_parser.dart';
import 'package:ai_roleplay_chat/features/chat/application/keyword_emotion_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const detector = KeywordEmotionDetector();

  group('KeywordEmotionDetector', () {
    test('中文情绪词命中', () {
      expect(detector.detect('你、你在说什么啊！！气死我了！'),
          const [EmotionEvent('emotion', 'angry')]);
      expect(
          detector.detect('今天好开心啊哈哈'), const [EmotionEvent('emotion', 'happy')]);
      expect(detector.detect('呜呜……你怎么能这么说'), const [EmotionEvent('emotion', 'sad')]);
      expect(detector.detect('*脸红* 才、才没有害羞！'),
          const [EmotionEvent('emotion', 'shy')]);
      expect(detector.detect('居然是你？！没想到'),
          const [EmotionEvent('emotion', 'surprised')]);
    });

    test('英文词不区分大小写', () {
      expect(detector.detect('I am SO MAD at you!'),
          const [EmotionEvent('emotion', 'angry')]);
      expect(detector.detect('That is Happy news'), const [EmotionEvent('emotion', 'happy')]);
    });

    test('多情绪各命中一次且不重复', () {
      final events = detector.detect('生气生气，然后又伤心地哭了，最后害羞地脸红');
      expect(events.where((e) => e.value == 'angry').length, 1);
      expect(events.where((e) => e.value == 'sad').length, 1);
      expect(events.where((e) => e.value == 'shy').length, 1);
      expect(events.length, 3);
    });

    test('无情绪词不误报', () {
      expect(detector.detect('我们去天台看风景吧，风很大。'), isEmpty);
      expect(detector.detect(''), isEmpty);
    });

    test('否定语境不触发（别生气/我没有生气/别不开心）', () {
      expect(detector.detect('别生气了嘛'), isEmpty);
      expect(detector.detect('我没有生气'), isEmpty);
      expect(detector.detect('别不开心啊'), isEmpty);
    });

    test('英文词边界：unhappy/hangry 不触发', () {
      expect(detector.detect('I am unhappy today'), isEmpty);
      expect(detector.detect('I feel hangry'), isEmpty);
    });

    test('否定词只抑制紧邻前缀，稍远的真情绪仍触发', () {
      expect(detector.detect('我才没有不开心，只是有点生气'), const [EmotionEvent('emotion', 'angry')]);
    });
  });
}
