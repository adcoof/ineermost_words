/// MessageList 自动滚底行为测试。
///
/// 覆盖：首次数据跳底、贴底跟随（新消息/流式变长）、
/// 翻历史不拉回、conversationId 变化重新跳底。
library;

import 'package:ai_roleplay_chat/app/providers.dart';
import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:ai_roleplay_chat/features/chat/data/chat_repository.dart';
import 'package:ai_roleplay_chat/features/chat/domain/models.dart';
import 'package:ai_roleplay_chat/features/chat/presentation/message_list.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('时间分隔（微信式）', () {
    final now = DateTime(2026, 10, 24, 15, 30);

    test('formatMessageTime：今天/昨天/同年/跨年四档', () {
      expect(formatMessageTime(DateTime(2026, 10, 24, 9, 5), now: now), '09:05');
      expect(formatMessageTime(DateTime(2026, 10, 23, 23, 59), now: now),
          '昨天 23:59');
      expect(formatMessageTime(DateTime(2026, 1, 3, 8, 0), now: now),
          '1月3日 08:00');
      expect(formatMessageTime(DateTime(2025, 12, 31, 0, 0), now: now),
          '2025年12月31日 00:00');
    });

    ChatMessage msg(DateTime at, {String id = 'm'}) => ChatMessage(
          id: id,
          conversationId: 'c',
          role: ChatRole.user,
          content: 'x',
          rawContent: 'x',
          emotionEvents: '[]',
          status: MessageStatus.done,
          createdAt: at,
        );

    test('首条必显示；相邻间隔 >5 分钟才显示，≤5 分钟不显示', () {
      final t0 = DateTime(2026, 10, 24, 10, 0);
      final labels = timeSeparators([
        msg(t0, id: 'a'),
        msg(t0.add(const Duration(minutes: 5)), id: 'b'), // 恰好 5 分钟：不显示
        msg(t0.add(const Duration(minutes: 10, seconds: 1)),
            id: 'c'), // 距 b 5分01秒：显示
        msg(t0.add(const Duration(minutes: 11)), id: 'd'), // 距 c 59 秒：不显示
      ], now: now);
      expect(labels[0], '10:00');
      expect(labels[1], isNull);
      expect(labels[2], '10:10');
      expect(labels[3], isNull);
    });

    test('空列表不产分隔', () {
      expect(timeSeparators(const [], now: now), isEmpty);
    });
  });

  late AppDatabase db;
  late ChatRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ChatRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  /// 生成一条足够长的消息内容，保证 8 条能撑出滚动高度。
  String longContent(String tag) =>
      '$tag：${'这是一段用来撑出滚动高度的长文本内容。' * 8}';

  /// 插入一条消息。
  Future<void> insert(String conversationId, String content,
      {ChatRole role = ChatRole.assistant}) async {
    await repo.insertMessage(
      conversationId: conversationId,
      role: role,
      content: content,
      rawContent: content,
    );
  }

  /// 把 MessageList 挂到 400 高的固定容器里并等待稳定。
  Future<void> pumpList(WidgetTester tester, String conversationId) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [chatRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: MessageList(conversationId: conversationId),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 卸载树并排空 Drift 查询流关闭时调度的 0ms 清理定时器，
  /// 否则 flutter_test 会因 "Timer is still pending" 失败。
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  }

  /// 取 MessageList 挂接的滚动控制器。
  ScrollController controllerOf(WidgetTester tester) =>
      tester.widget<ListView>(find.byType(ListView)).controller!;

  /// 断言列表当前停在底部（容忍 1px）。
  void expectAtBottom(WidgetTester tester) {
    final c = controllerOf(tester);
    expect(c.hasClients, isTrue);
    expect(c.offset, closeTo(c.position.maxScrollExtent, 1.0));
  }

  /// 泵帧直至消息流落地（maxScrollExtent 超过 [baseline]），返回新的 max。
  ///
  /// 每帧只推进 1ms 假时钟：构造『动画在途时更新到达』的用例不能让 200ms 的
  /// 贴底动画在数据落地前跑完；步数上限保证累计时长仍远小于 200ms。
  Future<double> pumpUntilMaxGrows(
      WidgetTester tester, ScrollController c, double baseline) async {
    for (var i = 0; i < 30; i++) {
      final max = c.position.maxScrollExtent;
      if (max > baseline) return max;
      await tester.pump(const Duration(milliseconds: 1));
    }
    fail('消息未在 30 帧内进入列表');
  }

  /// 查询当前流序下的末条消息行（与 MessageList 的 ORDER BY 一致）。
  ///
  /// 不走 watchMessages().first：测试里额外订阅再取消 drift 查询流，
  /// 会让后续 pumpWidget 挂死（markAsClosed 清理定时器的已知坑）。
  Future<MessageRow> lastRow(String conversationId) async {
    final q = db.select(db.messages)
      ..where((t) => t.conversationId.equals(conversationId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    final rows = await q.get();
    return rows.last;
  }

  testWidgets('首次有数据后 jumpTo 到列表底部（最新消息可见）', (tester) async {
    for (var i = 1; i <= 8; i++) {
      await insert('c1', longContent('消息$i'));
    }
    await pumpList(tester, 'c1');
    expectAtBottom(tester);

    // 最新消息（列表最下方）应停在视口内。
    final last = await lastRow('c1');
    final lastRect = tester.getRect(find.text(last.content));
    final listRect = tester.getRect(find.byType(ListView));
    expect(lastRect.top, lessThanOrEqualTo(listRect.bottom));
    await unmount(tester);
  });

  testWidgets('贴底状态下新消息到达 animateTo 跟随底部', (tester) async {
    for (var i = 1; i <= 8; i++) {
      await insert('c1', longContent('消息$i'));
    }
    await pumpList(tester, 'c1');
    expectAtBottom(tester);

    await insert('c1', longContent('追加的新消息'));
    await tester.pumpAndSettle();
    expectAtBottom(tester);
    await unmount(tester);
  });

  testWidgets('翻到顶部后新消息到达不被拉回', (tester) async {
    for (var i = 1; i <= 8; i++) {
      await insert('c1', longContent('消息$i'));
    }
    await pumpList(tester, 'c1');
    expectAtBottom(tester);

    // 手动拖回顶部。
    final c = controllerOf(tester);
    c.jumpTo(0);
    await tester.pumpAndSettle();
    expect(c.offset, closeTo(0, 1));

    await insert('c1', longContent('翻历史时到达的消息'));
    await tester.pumpAndSettle();
    // 仍停在顶部附近，不被强行拉回。
    expect(c.offset, closeTo(0, 1));
    await unmount(tester);
  });

  testWidgets('贴底时末条消息内容增长（流式变长）跟随底部', (tester) async {
    for (var i = 1; i <= 8; i++) {
      await insert('c1', longContent('消息$i'));
    }
    await pumpList(tester, 'c1');
    expectAtBottom(tester);

    final c = controllerOf(tester);
    final maxBefore = c.position.maxScrollExtent;
    final last = await lastRow('c1');
    // 增长串明显多行（3 段），确保 maxScrollExtent 真的增长：
    // 否则 expectAtBottom 在 max==offset 时恒真，丢失『流式变长跟随』的钉子。
    await repo.updateMessage(last.id, content: longContent('流式增长后的消息') * 3);
    await tester.pumpAndSettle();
    expect(c.position.maxScrollExtent, greaterThan(maxBefore + 100));
    expectAtBottom(tester);
    await unmount(tester);
  });

  testWidgets('贴底动画在途时更新被丢弃，动画结束后仍补跟随到底部', (tester) async {
    for (var i = 1; i <= 8; i++) {
      await insert('c1', longContent('消息$i'));
    }
    await pumpList(tester, 'c1');
    expectAtBottom(tester);

    final c = controllerOf(tester);
    final max0 = c.position.maxScrollExtent;

    // 第一跳：超长消息（远大于 5 行）使 animate 距离超过 nearBottom 阈值 120。
    await insert('c1', longContent('第一跳长消息') * 4);
    final max1 = await pumpUntilMaxGrows(tester, c, max0);
    expect(max1 - max0, greaterThan(200));

    // 动画在途（假时钟只前进毫秒级，像素仍在旧坐标附近）时第二跳到达：
    // 此刻 distance = 剩余动画距离 + 新增量 > 120，本次跟随被丢弃是预期行为；
    // 缺陷在于动画结束后若无补跳，列表会永久卡在底部上方。
    await insert('c1', longContent('第二跳') * 2);
    final max2 = await pumpUntilMaxGrows(tester, c, max1);
    expect(max2, greaterThan(max1));
    expect(c.position.isScrollingNotifier.value, isTrue,
        reason: '贴底动画应仍在途');
    // 复现 nearBottom 判定所用的『布局前』距离：必须超阈值才构成本用例前提。
    expect(max1 - c.position.pixels, greaterThan(120));

    await tester.pumpAndSettle(); // 动画结束 → 兜底补跟随到底
    expectAtBottom(tester);
    await unmount(tester);
  });

  testWidgets('conversationId 变化后重新跳到新会话底部', (tester) async {
    for (var i = 1; i <= 5; i++) {
      await insert('c1', longContent('会话一消息$i'));
    }
    await pumpList(tester, 'c1');
    expectAtBottom(tester);

    for (var i = 1; i <= 8; i++) {
      await insert('c2', longContent('会话二消息$i'));
    }
    // 同位置复用 MessageList，仅 conversationId 变化。
    await pumpList(tester, 'c2');
    expectAtBottom(tester);
    final last = await lastRow('c2');
    final lastRect = tester.getRect(find.text(last.content));
    final listRect = tester.getRect(find.byType(ListView));
    expect(lastRect.top, lessThanOrEqualTo(listRect.bottom));
    await unmount(tester);
  });
}
