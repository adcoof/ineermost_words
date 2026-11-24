/// Agent 会话/消息仓库测试：排序、工具调用编解码、级联删除。
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:ai_roleplay_chat/features/agent/data/agent_repository.dart';
import 'package:ai_roleplay_chat/features/agent/domain/agent_approval.dart';
import 'package:ai_roleplay_chat/features/chat/data/chat_api_client.dart';

void main() {
  late AppDatabase db;
  late AgentSessionRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = AgentSessionRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('会话按 updatedAt 倒序，重命名与删除', () async {
    final first = await repo.createSession(title: '第一个');
    final second = await repo.createSession(title: '第二个');
    await repo.renameSession(first.id, '改过的');

    final sessions = await repo.listSessions();
    expect(sessions.length, 2);
    expect(sessions.first.id, first.id); // 重命名 touch 了 updatedAt
    expect(sessions.first.title, '改过的');

    await repo.deleteSession(first.id);
    final after = await repo.listSessions();
    expect(after.single.id, second.id);
  });

  test('消息按 createdAt 升序，toolCalls 往返', () async {
    final session = await repo.createSession();
    final call = const ApiToolCall(
      id: 'call-1',
      name: 'read_file',
      arguments: '{"path":"a.txt"}',
    );
    await repo.insertMessage(
      sessionId: session.id,
      role: 'user',
      content: '读一下',
    );
    await repo.insertMessage(
      sessionId: session.id,
      role: 'assistant',
      content: '我看看',
      toolCalls: [call],
    );
    await repo.insertMessage(
      sessionId: session.id,
      role: 'tool',
      content: '{"ok":true}',
      toolCallId: 'call-1',
      toolName: 'read_file',
    );

    final messages = await repo.getMessages(session.id);
    expect(messages.map((m) => m.role), ['user', 'assistant', 'tool']);
    expect(messages[1].toolCalls.single.id, 'call-1');
    expect(messages[1].toolCalls.single.name, 'read_file');
    expect(messages[1].toolCalls.single.arguments, '{"path":"a.txt"}');
    expect(messages[2].toolCallId, 'call-1');
    expect(messages[2].isTool, isTrue);
  });

  test('updateMessage 只改传入字段，status 可更新', () async {
    final session = await repo.createSession();
    final message = await repo.insertMessage(
      sessionId: session.id,
      role: 'assistant',
      status: 'streaming',
    );
    await repo.updateMessage(message.id, content: '半截', status: 'error');

    final messages = await repo.getMessages(session.id);
    expect(messages.single.content, '半截');
    expect(messages.single.status, 'error');
  });

  test('会话级权限可写入、保留与清空', () async {
    const folder = AgentGrantedFolder(
      uri: 'content://tree/primary%3ADownload%2Fnotes',
      name: 'notes',
    );
    final session = await repo.createSession(
      approvalMode: AgentApprovalMode.auto,
      grantedFolders: const [folder],
    );
    final loaded = await repo.getSession(session.id);
    expect(loaded!.approvalMode, AgentApprovalMode.auto);
    expect(loaded.grantedFolders, hasLength(1));
    expect(loaded.grantedFolders!.single.name, 'notes');

    await repo.setSessionApprovalMode(session.id, null);
    await repo.setSessionGrantedFolders(session.id, null);
    final cleared = await repo.getSession(session.id);
    expect(cleared!.approvalMode, isNull);
    expect(cleared.grantedFolders, isNull);
  });

  test('删除会话级联删除消息', () async {
    final session = await repo.createSession();
    await repo.insertMessage(
      sessionId: session.id,
      role: 'user',
      content: 'hi',
    );
    await repo.deleteSession(session.id);
    expect(await repo.getMessages(session.id), isEmpty);
    expect(await repo.listSessions(), isEmpty);
  });
}
