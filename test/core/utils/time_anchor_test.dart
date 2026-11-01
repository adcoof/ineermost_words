/// timeAnchorLabel / formatCurrentTime：时间锚点纯函数测试。
library;

import 'package:ai_roleplay_chat/core/utils/time_anchor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 31, 15, 30); // 周六

  group('timeAnchorLabel', () {
    test('今天', () {
      expect(timeAnchorLabel(now, DateTime(2026, 10, 31, 9, 5)), '今天 09:05');
    });

    test('昨天', () {
      expect(
          timeAnchorLabel(now, DateTime(2026, 10, 30, 21, 35)), '昨天 21:35');
    });

    test('2~6 天前', () {
      expect(timeAnchorLabel(now, DateTime(2026, 10, 29, 8, 0)), '2天前 08:00');
      expect(timeAnchorLabel(now, DateTime(2026, 10, 25, 8, 0)), '6天前 08:00');
    });

    test('跨月同年：M月d日', () {
      expect(timeAnchorLabel(now, DateTime(2026, 10, 24, 8, 0)), '10月24日 08:00');
      expect(timeAnchorLabel(now, DateTime(2026, 1, 2, 8, 0)), '1月2日 08:00');
    });

    test('跨年：带年份', () {
      expect(
          timeAnchorLabel(now, DateTime(2025, 12, 3, 9, 0)), '2025年12月3日 09:00');
    });

    test('未来时间戳（时钟偏差）按今天处理', () {
      expect(timeAnchorLabel(now, DateTime(2026, 10, 31, 16, 0)), '今天 16:00');
    });
  });

  group('formatCurrentTime', () {
    test('固定格式：YYYY-MM-DD HH:mm（星期X）', () {
      expect(formatCurrentTime(now), '2026-10-31 15:30（星期六）');
    });

    test('单位数补零', () {
      expect(formatCurrentTime(DateTime(2026, 1, 2, 9, 5)),
          '2026-01-02 09:05（星期五）');
    });
  });
}
