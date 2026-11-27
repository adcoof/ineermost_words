import 'package:ai_roleplay_chat/features/characters/application/prompt_assembler.dart';
import 'package:ai_roleplay_chat/features/chat/presentation/context_usage_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PromptUsage usage({int window = 4096, int history = 600}) => PromptUsage(
    systemTokens: 500,
    memoryTokens: 200,
    otherSessionTokens: 100,
    historyTokens: history,
    currentInputTokens: 100,
    windowTokens: window,
  );

  Widget host(PromptUsage? u) => MaterialApp(
    home: Scaffold(
      appBar: AppBar(actions: [ContextUsageChip(usage: u)]),
    ),
  );

  testWidgets('没有用量时显示占位 --', (tester) async {
    await tester.pumpWidget(host(null));
    expect(find.text('上下文 --'), findsOneWidget);
  });

  testWidgets('按已用/窗口显示百分比', (tester) async {
    // 1500 / 4096 = 36.6% -> 37%
    await tester.pumpWidget(host(usage()));
    expect(find.text('上下文 37%'), findsOneWidget);
  });

  testWidgets('点击打开明细弹层，展示分类与剩余', (tester) async {
    await tester.pumpWidget(host(usage()));
    await tester.tap(find.text('上下文 37%'));
    await tester.pumpAndSettle();

    expect(find.text('上下文用量'), findsOneWidget);
    expect(find.text('系统人设 / 时间 / 示例'), findsOneWidget);
    expect(find.text('记忆（近期+画像）'), findsOneWidget);
    expect(find.text('跨会话片段'), findsOneWidget);
    expect(find.text('本会话历史'), findsOneWidget);
    expect(find.text('当前输入'), findsOneWidget);
    expect(find.text('角色档案'), findsNothing);
    expect(find.text('卡内提示'), findsNothing);
    expect(find.textContaining('剩余'), findsWidgets);
  });

  testWidgets('档案与卡内提示分类在用量弹层显示', (tester) async {
    await tester.pumpWidget(
      host(
        const PromptUsage(
          systemTokens: 100,
          profileTokens: 50,
          cardPromptTokens: 30,
          historyTokens: 100,
          windowTokens: 4096,
        ),
      ),
    );
    await tester.tap(find.textContaining('上下文 '));
    await tester.pumpAndSettle();

    expect(find.text('角色档案'), findsOneWidget);
    expect(find.text('卡内提示'), findsOneWidget);
    expect(find.text('50 token'), findsOneWidget);
    expect(find.text('30 token'), findsOneWidget);
  });

  testWidgets('超过 90% 显示红色，70%~90% 显示琥珀色', (tester) async {
    await tester.pumpWidget(host(usage(history: 3500))); // 4400/4096 > 90%，显示封顶 100%
    final red = tester.widget<Text>(find.text('上下文 100%'));
    expect(red.style?.color, const Color(0xFFE5484D));

    await tester.pumpWidget(host(usage(history: 2700))); // 3600/4096 ≈ 88%
    final amber = tester.widget<Text>(find.text('上下文 88%'));
    expect(amber.style?.color, const Color(0xFFD99A1E));
  });
}
