import 'package:ai_roleplay_chat/features/chat/application/emotion_tag_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmotionTagParser', () {
    test('整段文本无标签原样吐出', () {
      final p = EmotionTagParser();
      final r = p.feed('你好，今天天气不错。');
      expect(r.flushed, '你好，今天天气不错。');
      expect(r.events, isEmpty);
      expect(p.flush(), '');
    });

    test('单帧完整标签被剥离并产出事件', () {
      final p = EmotionTagParser();
      final r = p.feed('哼<emotion:happy>才不是高兴呢<action:wave>');
      expect(r.flushed, '哼才不是高兴呢');
      expect(r.events, const [
        EmotionEvent('emotion', 'happy'),
        EmotionEvent('action', 'wave'),
      ]);
    });

    test('逐字符喂入（最极端的切断）', () {
      final p = EmotionTagParser();
      const text = '啊<emotion:shy>唔<action:nod>好';
      var out = '';
      final events = <EmotionEvent>[];
      for (final ch in text.split('')) {
        final r = p.feed(ch);
        out += r.flushed;
        events.addAll(r.events);
      }
      out += p.flush();
      expect(out, '啊唔好');
      expect(events, const [
        EmotionEvent('emotion', 'shy'),
        EmotionEvent('action', 'nod'),
      ]);
    });

    test('在每个可能的切断位置二分喂入，输出恒等', () {
      const text = '开头<emotion:happy>中段<action:wave_head-2>结尾';
      String run(List<int> feedSizes) {
        final p = EmotionTagParser();
        var out = '';
        var i = 0;
        for (final size in feedSizes) {
          final end = (i + size).clamp(0, text.length);
          out += p.feed(text.substring(i, end)).flushed;
          i = end;
        }
        out += p.flush();
        return out;
      }

      for (var cut = 0; cut <= text.length; cut++) {
        final out = run([cut, text.length - cut]);
        expect(out, '开头中段结尾', reason: '切断位置 $cut');
      }
    });

    test('标签名含连字符与数字可识别', () {
      final p = EmotionTagParser();
      final r = p.feed('<action:wave_hand-2>');
      expect(r.flushed, '');
      expect(r.events, const [EmotionEvent('action', 'wave_hand-2')]);
    });

    test('大小写不同的伪标签按普通文本处理', () {
      final p = EmotionTagParser();
      final r = p.feed('<EMOTION:happy>和<Emotion:x>');
      expect(r.flushed, '<EMOTION:happy>和<Emotion:x>');
      expect(r.events, isEmpty);
    });

    test('非法标签名按普通文本处理', () {
      final p = EmotionTagParser();
      final r = p.feed('<emotion:!!>a<action:>');
      expect(r.flushed, '<emotion:!!>a<action:>');
      expect(r.events, isEmpty);
    });

    test('普通小于号不被永久滞留', () {
      final p = EmotionTagParser();
      final r = p.feed('a < b，c < d');
      expect(r.flushed, 'a < b，c < d');
      expect(p.flush(), '');
    });

    test('连续两个小于号：先字面量后标签，尾部多余尖括号是字面量', () {
      final p = EmotionTagParser();
      final r = p.feed('<<emotion:happy>>');
      expect(r.flushed, '<>');
      expect(r.events, const [EmotionEvent('emotion', 'happy')]);
      expect(p.flush(), '');
    });

    test('流被截断在半个标签中间：flush 按普通文本吐出不丢字', () {
      final p = EmotionTagParser();
      var out = p.feed('你好<emo').flushed;
      out += p.flush();
      expect(out, '你好<emo');
    });

    test('孤立小于号结尾先滞留，后续证实非标签后吐出', () {
      final p = EmotionTagParser();
      expect(p.feed('你好<').flushed, '你好');
      final r = p.feed('x');
      expect(r.flushed, '<x');
    });

    test('模型输出的闭合/无名变体被剥离且不产事件', () {
      final p = EmotionTagParser();
      final r = p.feed('什、什么啊！</emotion>*别过脸去*<emotion>好</action>');
      expect(r.flushed, '什、什么啊！*别过脸去*好');
      expect(r.events, isEmpty);
    });

    test('自闭合变体 <emotion:happy/> 产事件', () {
      final p = EmotionTagParser();
      final r = p.feed('哼<emotion:shy/>才没有。');
      expect(r.flushed, '哼才没有。');
      expect(r.events, const [EmotionEvent('emotion', 'shy')]);
    });

    test('闭合标签切断位置二分恒等', () {
      const text = '啊</emotion>啊<action:nod/>啊';
      String run(int cut) {
        final p = EmotionTagParser();
        var out = '';
        out += p.feed(text.substring(0, cut)).flushed;
        out += p.feed(text.substring(cut)).flushed;
        out += p.flush();
        return out;
      }

      for (var cut = 0; cut <= text.length; cut++) {
        expect(run(cut), '啊啊啊', reason: '切断位置 $cut');
      }
    });

    test('斜杠当冒号用的畸形形状不滞留（emotion/:x 永远不成标签）', () {
      final p = EmotionTagParser();
      // '>' 未到也不应滞留。
      final r = p.feed('<emotion/:');
      expect(r.flushed, '<emotion/:');
      expect(p.flush(), '');
    });

    test('事件 JSON 编解码往返', () {
      const events = [
        EmotionEvent('emotion', 'happy'),
        EmotionEvent('action', 'wave'),
      ];
      final json = EmotionTagParser.encodeEvents(events);
      expect(EmotionTagParser.decodeEvents(json), events);
      expect(EmotionTagParser.decodeEvents('not json'), isEmpty);
    });
  });
}
