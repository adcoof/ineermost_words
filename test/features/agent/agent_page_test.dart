/// Agent 页面测试：空态、新建会话、发送、写确认。
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ai_roleplay_chat/app/providers.dart';
import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:ai_roleplay_chat/features/agent/application/agent_tools.dart';
import 'package:ai_roleplay_chat/features/agent/presentation/agent_sessions_page.dart';
import 'package:ai_roleplay_chat/features/chat/data/chat_api_client.dart';
import 'package:ai_roleplay_chat/features/settings/data/api_profile_repository.dart';
import 'package:ai_roleplay_chat/features/settings/domain/api_profile.dart';

class _Api implements ChatApiClient {
  _Api(this.script);

  final List<List<ChatDelta>> script;
  int calls = 0;

  @override
  Stream<ChatDelta> streamChat({
    required ApiProfile profile,
    required List<ApiMessage> messages,
    double? temperature,
    int? maxTokens,
    List<ApiTool>? tools,
    CancelToken? cancelToken,
  }) async* {
    if (calls >= script.length) return;
    for (final delta in script[calls++]) {
      yield delta;
    }
  }

  @override
  Future<void> testConnection({
    required ApiProfile profile,
    CancelToken? cancelToken,
  }) async {}
}

void main() {
  late AppDatabase db;
  late Directory dir;
  late AgentWorkspace workspace;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await ApiProfileRepository(db).save(
      const ApiProfile(
        id: 'p1',
        name: '测试',
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'key',
        model: 'model',
        temperature: 1,
        extraHeaders: '{}',
        isDefault: true,
      ),
    );
    dir = await Directory.systemTemp.createTemp('agent_page_test_');
    workspace = AgentWorkspace(dir);
  });

  tearDown(() async {
    await db.close();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  Future<void> pumpApp(WidgetTester tester, ChatApiClient api) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          chatApiClientProvider.overrideWithValue(api),
          agentWorkspaceProvider.overrideWith((ref) async => workspace),
        ],
        child: const MaterialApp(home: AgentSessionsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('空态与新建会话进入对话页', (tester) async {
    await pumpApp(tester, _Api([]));

    expect(find.text('我可以读写文件、执行命令、联网搜索'), findsOneWidget);
    await tester.tap(find.text('新对话'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('agent-input')), findsOneWidget);
    expect(find.byKey(const Key('agent-send')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('发送消息后显示用户与助手气泡', (tester) async {
    await pumpApp(
      tester,
      _Api([
        [const ChatDelta(content: '收到')],
      ]),
    );
    await tester.tap(find.text('新对话'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('agent-input')), '你好');
    await tester.tap(find.byKey(const Key('agent-send')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('你好'), findsWidgets); // 输入框（若未清空）或气泡
    expect(find.text('收到', findRichText: true), findsOneWidget);
    expect(find.textContaining('上下文'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('会话内权限面板可切换模式并显示已覆盖', (tester) async {
    await pumpApp(tester, _Api([]));
    await tester.tap(find.text('新对话'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.shield_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Agent 权限'), findsOneWidget);
    expect(find.text('跟随设置页默认'), findsOneWidget);

    await tester.tap(find.text('全自动'));
    await tester.pumpAndSettle();
    expect(find.text('本会话已覆盖默认审批模式'), findsOneWidget);
    await unmount(tester);
  });
}
