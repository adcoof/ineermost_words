import 'package:ai_roleplay_chat/app/app.dart';
import 'package:ai_roleplay_chat/app/providers.dart';
import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('启动页过渡到主界面，底部导航切换角色页', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final overrides = [
      // 测试进程内内存库。
      appDatabaseProvider.overrideWithValue(db),
    ];

    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const AiRoleplayApp()),
    );
    // 启动页：应用名与工作室署名先亮相。
    expect(find.text('心语'), findsOneWidget);
    expect(find.text('由奇点重现工作室制作'), findsOneWidget);

    // 等待启动页 2.2s 自动过渡 + 转场动画。
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // 聊天页标题 + 四栏导航。
    expect(find.widgetWithText(AppBar, '聊天'), findsOneWidget);
    expect(find.text('工坊'), findsOneWidget);
    expect(find.text('资产'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);

    // 切到工坊：AI 创作入口 + 我的角色。
    await tester.tap(find.text('工坊'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '角色工坊'), findsOneWidget);
    expect(find.text('AI 创作角色'), findsOneWidget);
    expect(find.text('我的角色'), findsOneWidget);
    expect(find.textContaining('还没有角色'), findsOneWidget);

    // 切到资产：四个入口。
    await tester.tap(find.text('资产'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '角色资产'), findsOneWidget);
    expect(find.text('桌宠模型'), findsOneWidget);
    expect(find.text('角色立绘'), findsOneWidget);
    expect(find.text('表情包'), findsOneWidget);
    expect(find.text('音色'), findsOneWidget);

    // 卸载树并排空 Drift 查询流关闭时调度的 0ms 清理定时器，
    // 否则 flutter_test 会因 "Timer is still pending" 失败。
    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const SizedBox()),
    );
    await tester.pump(const Duration(milliseconds: 1));
    await db.close();
  });
}
