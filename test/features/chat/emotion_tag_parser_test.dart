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

    test('大小写变体同样剥离并归一为小写事件（v8.1）', () {
      final p = EmotionTagParser();
      final r = p.feed('<EMOTION:happy>和<Action:Wave>');
      expect(r.flushed, '和');
      expect(r.events, const [
        EmotionEvent('emotion', 'happy'),
        EmotionEvent('action', 'wave'),
      ]);
    });

    test('空白/全角冒号/中文名字的变体也剥离（v8.1 真机漏标签）', () {
      final p = EmotionTagParser();
      final r = p.feed(
        'a< action : wave >b<emotion：开心>c<action 挥手>d<'
        'emotion>e</ emotion>f',
      );
      expect(r.flushed, 'abcdef');
      expect(r.events, const [
        EmotionEvent('action', 'wave'),
        EmotionEvent('emotion', '开心'),
        EmotionEvent('action', '挥手'),
      ]);
    });

    test('全角尖括号 ＜action：wave＞ 也剥离', () {
      final p = EmotionTagParser();
      final r = p.feed('嗯＜action：wave＞好');
      expect(r.flushed, '嗯好');
      expect(r.events, const [EmotionEvent('action', 'wave')]);
    });

    test('空名字的标签剥离但不产事件', () {
      final p = EmotionTagParser();
      final r = p.feed('<emotion:!!>a<action:>');
      expect(r.flushed, 'a');
      expect(r.events, const [EmotionEvent('emotion', '!!')]);
    });

    test('普通小于号遇到标点立刻放行（不滞留后续正文）', () {
      final p = EmotionTagParser();
      final r = p.feed('a < b，c < d');
      // 第一个 '<' 后面紧跟标点，立刻判定为普通文本；
      // 第二个 '<' 后面只有标签字符，观望到段落结束再吐出（不丢字）。
      expect(r.flushed, 'a < b，c ');
      expect(p.flush(), '< d');
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
      // '<x' 仍在标签字符集内，继续观望；出现标点即放行。
      expect(p.feed('x').flushed, '');
      final r = p.feed('，好');
      expect(r.flushed, '<x，好');
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

    test('自造标签（whisper/glare 等舞台提示）一并剥离且不产事件（v8.2）', () {
      final p = EmotionTagParser();
      final r = p.feed(
        '<whisper>……hi。<glare>……还不跟上来。'
        '<run_away>不许笑！！<Shout>好',
      );
      expect(r.flushed, '……hi。……还不跟上来。不许笑！！好');
      expect(r.events, isEmpty);
    });

    test('数学小于号与数字不被当标签剥离', () {
      final p = EmotionTagParser();
      final r = p.feed('3 < 4 且 2<3>1');
      expect(r.flushed, '3 < 4 且 2<3>1');
      expect(r.events, isEmpty);
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

  group('stripTagMarkup', () {
    test('一次性清洗各类标签变体', () {
      expect(
        stripTagMarkup('哼<emotion:shy>才没有< action : wave >呢</emotion>'),
        '哼才没有呢',
      );
      expect(stripTagMarkup('＜emotion：开心＞好'), '好');
    });

    test('自造标签（whisper/glare/run_away）也清掉（v8.2 真机脏数据）', () {
      expect(
        stripTagMarkup('<whisper>……hi。<glare>还不跟上来。<run_away>不、不许笑！'),
        '……hi。还不跟上来。不、不许笑！',
      );
    });

    test('真机库里那批脏数据：shake_head/sigh/stare/facepalm/rage 都清掉', () {
      // 摘自 MuMu 真机库的原文（模型自造下划线动作名，无 action: 前缀）。
      expect(
        stripTagMarkup(
          '<angry>你、你再说一遍？<shake_head>hi hi hi 的。<sigh>算了，'
          '<roll_eyes>没救了。<stare>hi。<facepalm>烦死了。<rage>滚。',
        ),
        '你、你再说一遍？hi hi hi 的。算了，没救了。hi。烦死了。滚。',
      );
    });

    test('普通文本与数学小于号不受影响', () {
      expect(stripTagMarkup('1 < 2 且 3 > 2'), '1 < 2 且 3 > 2');
      expect(stripTagMarkup('没有标签'), '没有标签');
    });
  });
}
