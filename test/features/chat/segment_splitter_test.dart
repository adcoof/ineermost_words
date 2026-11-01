/// SegmentSplitter：行制 [P] 检测的纯函数测试。
library;

import 'package:ai_roleplay_chat/features/chat/application/segment_splitter.dart';
import 'package:flutter_test/flutter_test.dart';

/// 喂完所有 chunk，拼接文本事件（边界以 `|B|` 标记）。
String run(SegmentSplitter s, List<String> chunks) {
  final b = StringBuffer();
  for (final c in chunks) {
    for (final ev in s.feed(c)) {
      if (ev.isBoundary) {
        b.write('|B|');
      } else {
        b.write(ev.text);
      }
    }
  }
  final tail = s.flush();
  if (tail.isNotEmpty) b.write(tail);
  return b.toString();
}

void main() {
  group('SegmentSplitter', () {
    test('独行 [P] 切段：标记吞掉、换行不进文本', () {
      final s = SegmentSplitter();
      expect(run(s, ['你好\n[P]\n嗯嗯']), '你好\n|B|嗯嗯');
    });

    test('标记被 chunk 切断：跨块到达不误报', () {
      final s = SegmentSplitter();
      expect(run(s, ['你好\n[P', ']\n嗯嗯']), '你好\n|B|嗯嗯');
    });

    test('行中 [P] 不算边界', () {
      final s = SegmentSplitter();
      expect(run(s, ['xx[P]yy\n']), 'xx[P]yy\n');
    });

    test('[Project] 之类不误报', () {
      final s = SegmentSplitter();
      expect(run(s, ['[Project] 启动\n']), '[Project] 启动\n');
    });

    test('超过上限（4 段 = 3 边界）后 [P] 行按字面输出', () {
      final s = SegmentSplitter();
      final out = run(s, ['一\n[P]\n二\n[P]\n三\n[P]\n四\n[P]\n五']);
      expect(out, '一\n|B|二\n|B|三\n|B|四\n[P]\n五');
    });

    test('尾部孤悬 [P]（无换行）flush 时丢弃', () {
      final s = SegmentSplitter();
      expect(run(s, ['你好\n[P]']), '你好\n');
    });

    test('CRLF 的 [P]\r 行也算边界（trim 容错）', () {
      final s = SegmentSplitter();
      expect(run(s, ['你好\r\n[P]\r\n嗯\r\n']), '你好\r\n|B|嗯\r\n');
    });

    test('空 feed 与纯文本不产生边界', () {
      final s = SegmentSplitter();
      expect(s.feed('abc'), isEmpty);
      expect(s.flush(), 'abc');
    });
  });

  group('splitLongReply（模型不守 [P] 时的兜底分段）', () {
    test('短回复原样一条，不拆', () {
      expect(splitLongReply('嗯。'), ['嗯。']);
      expect(splitLongReply('嗯。怎么了？'), ['嗯。怎么了？']);
      expect(splitLongReply(''), isEmpty);
    });

    test('按空行分段：模型自己划的自然段就是消息边界', () {
      expect(splitLongReply('*愣了一下*\n\n你、你又来了？\n\n……烦死了。'), [
        '*愣了一下*',
        '你、你又来了？',
        '……烦死了。',
      ]);
    });

    test('真机那条长回复：10 段压到上限 4 条', () {
      const reply =
          '*整个人明显抖了一下*\n\n'
          '……你、你又来了？？\n\n'
          '我说过多少次了！！从昨天开始就hi hello你好来来回回——你就不能说点别的吗！！\n\n'
          '*耳朵瞬间红了*\n\n'
          '……哼。虽然、虽然只是两个字母而已。\n\n'
          '但是是从你嘴里说出来的，就、就……\n\n'
          '*声音越来越小*\n\n'
          '……烦死了。笨蛋。';
      final parts = splitLongReply(reply);
      expect(parts, hasLength(4));
      expect(parts.first, contains('抖了一下'));
      expect(parts.last, contains('笨蛋'));
      // 每一条都明显短于原文。
      for (final p in parts) {
        expect(p.length, lessThan(reply.length));
      }
    });

    test('无空行但偏长：按句子切并装桶', () {
      final long = List.filled(30, '这是一句用来测试的普通话。').join();
      final parts = splitLongReply(long);
      expect(parts.length, greaterThan(1));
      expect(parts.length, lessThanOrEqualTo(SegmentSplitter.maxSegments));
      for (final p in parts) {
        expect(p.length, lessThanOrEqualTo(160)); // 两句以内
      }
    });

    test('无空行的多行文本按行切', () {
      final reply = List.filled(5, '这一行是一句比较长的台词，用来超过阈值。').join('\n');
      final parts = splitLongReply(reply);
      expect(parts.length, greaterThan(1));
    });

    test('纯标点碎片并回上一条', () {
      final parts = splitLongReply('嗯嗯\n\n……\n\n好的');
      expect(parts, ['嗯嗯\n……', '好的']);
    });

    test('单段超长且无标点：不切成大量碎片', () {
      final blob = '字' * 300;
      final parts = splitLongReply(blob);
      expect(parts, [blob]);
    });
  });
}
