/// Agent 控制器测试：工具循环、写确认、失败兜底与步数上限。
library;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_roleplay_chat/core/errors/app_exception.dart';
import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:ai_roleplay_chat/features/agent/application/agent_controller.dart';
import 'package:ai_roleplay_chat/features/agent/application/agent_tools.dart';
import 'package:ai_roleplay_chat/features/agent/data/agent_repository.dart';
import 'package:ai_roleplay_chat/features/agent/domain/agent_approval.dart';
import 'package:ai_roleplay_chat/features/chat/data/chat_api_client.dart';
import 'package:ai_roleplay_chat/features/settings/data/api_profile_repository.dart';
import 'package:ai_roleplay_chat/features/settings/data/app_settings_repository.dart';
import 'package:ai_roleplay_chat/features/settings/domain/api_profile.dart';

class _ScriptedApi implements ChatApiClient {
  _ScriptedApi(this.script);

  final List<List<ChatDelta>> script;
  int calls = 0;
  final List<List<ApiMessage>> sentMessages = [];
  final List<List<ApiTool>> sentTools = [];
  Object? error;

  @override
  Stream<ChatDelta> streamChat({
    required ApiProfile profile,
    required List<ApiMessage> messages,
    double? temperature,
    int? maxTokens,
    List<ApiTool>? tools,
    CancelToken? cancelToken,
  }) async* {
    sentMessages.add(List.of(messages));
    sentTools.add(tools ?? const []);
    if (error != null) throw error!;
    if (calls >= script.length) {
      throw const ServerException('脚本已用尽');
    }
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
  late AgentSessionRepository repo;
  late ApiProfileRepository profiles;
  late AppSettingsRepository settings;
  late Directory dir;
  late AgentController controller;

  ApiToolCall call(String name, Map<String, dynamic> args) => ApiToolCall(
        id: 'call-${name.hashCode}',
        name: name,
        arguments: jsonEncode(args),
      );

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = AgentSessionRepository(db);
    profiles = ApiProfileRepository(db);
    await profiles.save(
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
    settings = AppSettingsRepository(db);
    await settings.setAgentAutoWrite(false);
    await settings.setAgentMaxSteps(6);
    dir = await Directory.systemTemp.createTemp('agent_controller_test_');
  });

  tearDown(() async {
    controller.dispose();
    await db.close();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  Future<String> newSession() async {
    final session = await repo.createSession();
    return session.id;
  }

  Future<void> waitUntil(bool Function() condition) async {
    for (var i = 0; i < 200; i++) {
      if (condition()) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('等待超时');
  }

  test('工具循环：模型 → 工具结果 → 最终回答', () async {
    await settings.setAgentApprovalMode(AgentApprovalMode.auto);
    final api = _ScriptedApi([
      [
        const ChatDelta(content: '我先看看'),
        ChatDelta(
          toolCalls: [call('list_files', const {})],
        ),
      ],
      [const ChatDelta(content: '工作区是空的')],
    ]);
    controller = AgentController(
      repo: repo,
      api: api,
      profiles: profiles,
      settings: settings,
      workspace: AgentWorkspace(dir),
    );
    final sessionId = await newSession();
    controller.attach(sessionId);

    await controller.send('看看文件');

    final messages = await repo.getMessages(sessionId);
    expect(messages.map((m) => m.role), ['user', 'assistant', 'tool', 'assistant']);
    expect(messages[1].toolCalls.single.name, 'list_files');
    expect(messages[1].status, 'done');
    final toolResult = jsonDecode(messages[2].content) as Map<String, dynamic>;
    expect(toolResult['ok'], isTrue);
    expect(messages[2].toolCallId, messages[1].toolCalls.single.id);
    expect(messages[3].content, '工作区是空的');
    expect(messages[3].status, 'done');
    expect(controller.errorText, isNull);
    expect(controller.sending, isFalse);
    expect(api.sentTools.first.map((t) => t.name), [
      'list_roots',
      'list_files',
      'read_file',
      'write_file',
      'delete_file',
      'move_file',
      'rename',
      'run_command',
      'http_request',
      'web_search',
      'convert_file',
      'device_status',
      'device_shell',
      'device_click_text',
      'device_ui_text',
    ]);
    // 第二轮历史里应包含 tool 结果。
    expect(api.sentMessages[1].last.role, 'tool');
  });

  test('写文件需要确认；确认后落盘', () async {
    final api = _ScriptedApi([
      [
        ChatDelta(
          toolCalls: [
            call('write_file', {'path': 'note.txt', 'content': '你好'}),
          ],
        ),
      ],
      [const ChatDelta(content: '写好了')],
    ]);
    controller = AgentController(
      repo: repo,
      api: api,
      profiles: profiles,
      settings: settings,
      workspace: AgentWorkspace(dir),
    );
    final sessionId = await newSession();
    controller.attach(sessionId);

    final future = controller.send('保存到 note.txt');
    await waitUntil(() => controller.pendingWrite != null);
    expect(controller.pendingWrite!.path, 'note.txt');
    expect(controller.pendingWrite!.chars, 2);
    controller.confirmWrite();
    await future;

    final file = File('${dir.path}/note.txt');
    expect(await file.exists(), isTrue);
    expect(await file.readAsString(), '你好');
    expect(controller.pendingWrite, isNull);
    final messages = await repo.getMessages(sessionId);
    expect(
      (jsonDecode(messages[2].content) as Map<String, dynamic>)['ok'],
      isTrue,
    );
  });

  test('拒绝写入：工具返回用户拒绝，文件不落盘', () async {
    final api = _ScriptedApi([
      [
        ChatDelta(
          toolCalls: [
            call('write_file', {'path': 'no.txt', 'content': 'x'}),
          ],
        ),
      ],
      [const ChatDelta(content: '好的，不写了')],
    ]);
    controller = AgentController(
      repo: repo,
      api: api,
      profiles: profiles,
      settings: settings,
      workspace: AgentWorkspace(dir),
    );
    final sessionId = await newSession();
    controller.attach(sessionId);

    final future = controller.send('写个文件');
    await waitUntil(() => controller.pendingWrite != null);
    controller.rejectWrite();
    await future;

    expect(await File('${dir.path}/no.txt').exists(), isFalse);
    final messages = await repo.getMessages(sessionId);
    expect(messages[2].content, contains('用户拒绝执行'));
  });

  test('autoWrite 打开后直接写入，不出现确认卡', () async {
    await settings.setAgentAutoWrite(true);
    final api = _ScriptedApi([
      [
        ChatDelta(
          toolCalls: [
            call('write_file', {'path': 'auto.txt', 'content': 'auto'}),
          ],
        ),
      ],
      [const ChatDelta(content: '已写入')],
    ]);
    controller = AgentController(
      repo: repo,
      api: api,
      profiles: profiles,
      settings: settings,
      workspace: AgentWorkspace(dir),
    );
    final sessionId = await newSession();
    controller.attach(sessionId);

    final future = controller.send('自动写');
    await waitUntil(() => !controller.sending);
    await future;

    expect(controller.pendingWrite, isNull);
    expect(await File('${dir.path}/auto.txt').readAsString(), 'auto');
  });

  test('达到最大步数时报错并停止', () async {
    await settings.setAgentMaxSteps(2);
    await settings.setAgentApprovalMode(AgentApprovalMode.auto);
    final api = _ScriptedApi([
      [ChatDelta(toolCalls: [call('list_files', const {})])],
      [ChatDelta(toolCalls: [call('list_files', const {})])],
    ]);
    controller = AgentController(
      repo: repo,
      api: api,
      profiles: profiles,
      settings: settings,
      workspace: AgentWorkspace(dir),
    );
    final sessionId = await newSession();
    controller.attach(sessionId);

    await controller.send('一直列目录');

    expect(controller.errorText, contains('已达到最大工具步数（2）'));
    final messages = await repo.getMessages(sessionId);
    expect(messages.where((m) => m.role == 'tool'), hasLength(2));
    expect(api.calls, 2);
  });

  test('模型不支持 tools 时给出提示并清理空占位', () async {
    final api = _ScriptedApi([])
      ..error = const AgentToolsUnsupportedException();
    controller = AgentController(
      repo: repo,
      api: api,
      profiles: profiles,
      settings: settings,
      workspace: AgentWorkspace(dir),
    );
    final sessionId = await newSession();
    controller.attach(sessionId);

    await controller.send('测试');

    expect(controller.errorText, '当前模型不支持工具调用');
    expect(controller.toolsUnsupported, isTrue);
    final messages = await repo.getMessages(sessionId);
    expect(messages.map((m) => m.role), ['user']);
  });

  test('空回复删除占位并提示', () async {
    final api = _ScriptedApi([
      [const ChatDelta()],
    ]);
    controller = AgentController(
      repo: repo,
      api: api,
      profiles: profiles,
      settings: settings,
      workspace: AgentWorkspace(dir),
    );
    final sessionId = await newSession();
    controller.attach(sessionId);

    await controller.send('空');

    expect(controller.errorText, contains('没有返回内容'));
    expect(await repo.getMessages(sessionId), hasLength(1));
  });

  test('自动审查：删除先确认，确认后执行', () async {
    await settings.setAgentApprovalMode(AgentApprovalMode.auto);
    final target = File('${dir.path}/del.txt');
    await target.writeAsString('x');
    final api = _ScriptedApi([
      [
        ChatDelta(
          toolCalls: [
            call('delete_file', {'path': 'del.txt'}),
          ],
        ),
      ],
      [const ChatDelta(content: '已删除')],
    ]);
    controller = AgentController(
      repo: repo,
      api: api,
      profiles: profiles,
      settings: settings,
      workspace: AgentWorkspace(dir),
    );
    final sessionId = await newSession();
    controller.attach(sessionId);

    final future = controller.send('删掉 del.txt');
    await waitUntil(() => controller.pendingAction != null);
    expect(controller.pendingAction!.risk, AgentToolRisk.destructive);
    expect(controller.pendingWrite, isNull);
    controller.confirmAction();
    await future;

    expect(await target.exists(), isFalse);
    expect(controller.pendingAction, isNull);
  });

  test('全自动：删除直接执行，不询问', () async {
    await settings.setAgentApprovalMode(AgentApprovalMode.full);
    final target = File('${dir.path}/auto-del.txt');
    await target.writeAsString('x');
    final api = _ScriptedApi([
      [
        ChatDelta(
          toolCalls: [
            call('delete_file', {'path': 'auto-del.txt'}),
          ],
        ),
      ],
      [const ChatDelta(content: '已删除')],
    ]);
    controller = AgentController(
      repo: repo,
      api: api,
      profiles: profiles,
      settings: settings,
      workspace: AgentWorkspace(dir),
    );
    final sessionId = await newSession();
    controller.attach(sessionId);

    await controller.send('直接删');

    expect(await target.exists(), isFalse);
    expect(controller.pendingAction, isNull);
    expect(controller.errorText, isNull);
  });

  test('会话级审批模式覆盖设置页默认', () async {
    // 默认全自动，但本会话要求每步确认。
    await settings.setAgentApprovalMode(AgentApprovalMode.full);
    final api = _ScriptedApi([
      [
        ChatDelta(
          toolCalls: [call('list_files', const {})],
        ),
      ],
      [const ChatDelta(content: '看完了')],
    ]);
    controller = AgentController(
      repo: repo,
      api: api,
      profiles: profiles,
      settings: settings,
      workspace: AgentWorkspace(dir),
    );
    final session = await repo.createSession(
      approvalMode: AgentApprovalMode.ask,
    );
    controller.attach(session.id);

    final future = controller.send('列一下文件');
    await waitUntil(() => controller.pendingAction != null);
    expect(controller.approvalMode, AgentApprovalMode.ask);
    expect(controller.sessionApprovalMode, AgentApprovalMode.ask);
    controller.confirmAction();
    await future;

    expect(controller.errorText, isNull);
    expect(controller.pendingAction, isNull);
  });

  test('发送后显示上下文用量', () async {
    await settings.setAgentApprovalMode(AgentApprovalMode.full);
    final api = _ScriptedApi([
      [const ChatDelta(content: '好的')],
    ]);
    controller = AgentController(
      repo: repo,
      api: api,
      profiles: profiles,
      settings: settings,
      workspace: AgentWorkspace(dir),
    );
    final sessionId = await newSession();
    controller.attach(sessionId);

    await controller.send('你好');

    final usage = controller.contextUsage;
    expect(usage, isNotNull);
    expect(usage!.windowTokens, kContextWindowDefault);
    expect(usage.systemTokens, greaterThan(0));
    expect(usage.toolsTokens, greaterThan(0));
    expect(usage.usedTokens, greaterThan(usage.toolsTokens));
  });

  test('历史预算会扣除系统提示与工具定义', () async {
    await settings.setAgentApprovalMode(AgentApprovalMode.full);
    await settings.setAgentContextWindowTokens(4096);
    final api = _ScriptedApi([
      [const ChatDelta(content: '好的')],
    ]);
    controller = AgentController(
      repo: repo,
      api: api,
      profiles: profiles,
      settings: settings,
      workspace: AgentWorkspace(dir),
    );
    final session = await repo.createSession();
    final filler = '这是一段用于占满上下文的旧对话内容。' * 16;
    for (var i = 0; i < 30; i++) {
      await repo.insertMessage(
        sessionId: session.id,
        role: 'user',
        content: '旧问题 $i：$filler',
      );
      await repo.insertMessage(
        sessionId: session.id,
        role: 'assistant',
        content: '旧回复 $i：$filler',
      );
    }
    controller.attach(session.id);

    await controller.send('最后的问题');

    final sent = api.sentMessages.single;
    expect(sent.first.role, 'system');
    expect(sent.first.content, contains('更早对话摘要'));
    expect(sent.last.role, 'user');
    expect(sent.last.content, '最后的问题');
    expect(sent.length, lessThan(40));
    // 系统提示 + 工具定义 + 历史 应落在窗口 90% 预算内。
    expect(
      controller.contextUsage!.usedTokens,
      lessThanOrEqualTo((4096 * 0.9).floor()),
    );
  });
}
