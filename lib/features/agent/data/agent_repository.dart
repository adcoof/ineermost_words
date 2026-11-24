/// Agent 会话 / 消息仓库。
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/utils/id.dart';
import '../../../data/local/app_database.dart';
import '../../chat/data/chat_api_client.dart';
import '../domain/agent_approval.dart';
import '../domain/agent_models.dart';

class AgentSessionRepository {
  final AppDatabase db;

  AgentSessionRepository(this.db);

  Stream<List<AgentSession>> watchSessions() {
    final q = db.select(db.agentSessions)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    return q.watch().map((rows) => [for (final row in rows) _session(row)]);
  }

  Future<List<AgentSession>> listSessions() async {
    final q = db.select(db.agentSessions)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    final rows = await q.get();
    return [for (final row in rows) _session(row)];
  }

  Future<AgentSession?> getSession(String id) async {
    final q = db.select(db.agentSessions)..where((t) => t.id.equals(id));
    final row = await q.getSingleOrNull();
    return row == null ? null : _session(row);
  }

  Future<AgentSession> createSession({
    String? title,
    AgentApprovalMode? approvalMode,
    List<AgentGrantedFolder>? grantedFolders,
  }) async {
    final now = DateTime.now();
    final session = AgentSession(
      id: newId(),
      title: title ?? '新 Agent 会话',
      createdAt: now,
      updatedAt: now,
      approvalMode: approvalMode,
      grantedFolders: grantedFolders,
    );
    await db.into(db.agentSessions).insert(_sessionRow(session));
    return session;
  }

  /// 设置会话级审批模式；null = 跟随设置页默认。
  Future<void> setSessionApprovalMode(
    String id,
    AgentApprovalMode? mode,
  ) async {
    await (db.update(db.agentSessions)..where((t) => t.id.equals(id))).write(
      AgentSessionsCompanion(
        approvalMode: Value(mode?.storageValue),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 设置会话级授权文件夹；null = 跟随设置页默认。
  Future<void> setSessionGrantedFolders(
    String id,
    List<AgentGrantedFolder>? folders,
  ) async {
    await (db.update(db.agentSessions)..where((t) => t.id.equals(id))).write(
      AgentSessionsCompanion(
        grantedFoldersJson: Value(
          folders == null ? null : AgentGrantedFolder.encodeList(folders),
        ),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> renameSession(String id, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    await (db.update(db.agentSessions)..where((t) => t.id.equals(id))).write(
      AgentSessionsCompanion(
        title: Value(trimmed),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteSession(String id) async {
    await db.transaction(() async {
      await (db.delete(
        db.agentMessages,
      )..where((t) => t.sessionId.equals(id))).go();
      await (db.delete(db.agentSessions)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<void> touchSession(String id) async {
    await (db.update(db.agentSessions)..where((t) => t.id.equals(id))).write(
      AgentSessionsCompanion(updatedAt: Value(DateTime.now())),
    );
  }

  Stream<List<AgentMessage>> watchMessages(String sessionId) {
    final q = db.select(db.agentMessages)
      ..where((t) => t.sessionId.equals(sessionId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return q.watch().map((rows) => [for (final row in rows) _message(row)]);
  }

  Future<List<AgentMessage>> getMessages(String sessionId) async {
    final q = db.select(db.agentMessages)
      ..where((t) => t.sessionId.equals(sessionId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    final rows = await q.get();
    return [for (final row in rows) _message(row)];
  }

  Future<AgentMessage> insertMessage({
    required String sessionId,
    required String role,
    String content = '',
    List<ApiToolCall> toolCalls = const [],
    String? toolCallId,
    String? toolName,
    String status = 'done',
    DateTime? createdAt,
  }) async {
    final now = createdAt ?? DateTime.now();
    final msg = AgentMessage(
      id: newId(),
      sessionId: sessionId,
      role: role,
      content: content,
      toolCalls: toolCalls,
      toolCallId: toolCallId,
      toolName: toolName,
      status: status,
      createdAt: now,
    );
    await db.into(db.agentMessages).insert(_messageRow(msg));
    await touchSession(sessionId);
    return msg;
  }

  Future<void> updateMessage(
    String id, {
    String? content,
    List<ApiToolCall>? toolCalls,
    String? status,
  }) async {
    await (db.update(db.agentMessages)..where((t) => t.id.equals(id))).write(
      AgentMessagesCompanion(
        content: content == null ? const Value.absent() : Value(content),
        toolCallsJson: toolCalls == null
            ? const Value.absent()
            : Value(toolCalls.isEmpty ? null : _encodeCalls(toolCalls)),
        status: status == null ? const Value.absent() : Value(status),
      ),
    );
  }

  Future<void> deleteMessage(String id) async {
    await (db.delete(db.agentMessages)..where((t) => t.id.equals(id))).go();
  }

  AgentSession _session(AgentSessionRow row) => AgentSession(
    id: row.id,
    title: row.title,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    approvalMode: row.approvalMode == null
        ? null
        : AgentApprovalMode.parse(row.approvalMode),
    grantedFolders: row.grantedFoldersJson == null
        ? null
        : AgentGrantedFolder.decodeList(row.grantedFoldersJson),
  );

  AgentMessage _message(AgentMessageRow row) => AgentMessage(
    id: row.id,
    sessionId: row.sessionId,
    role: row.role,
    content: row.content,
    toolCalls: _decodeCalls(row.toolCallsJson),
    toolCallId: row.toolCallId,
    toolName: row.toolName,
    status: row.status,
    createdAt: row.createdAt,
  );

  AgentSessionsCompanion _sessionRow(AgentSession s) => AgentSessionsCompanion(
    id: Value(s.id),
    title: Value(s.title),
    createdAt: Value(s.createdAt),
    updatedAt: Value(s.updatedAt),
    approvalMode: Value(s.approvalMode?.storageValue),
    grantedFoldersJson: Value(
      s.grantedFolders == null
          ? null
          : AgentGrantedFolder.encodeList(s.grantedFolders!),
    ),
  );

  AgentMessagesCompanion _messageRow(AgentMessage m) => AgentMessagesCompanion(
    id: Value(m.id),
    sessionId: Value(m.sessionId),
    role: Value(m.role),
    content: Value(m.content),
    toolCallsJson: Value(m.toolCalls.isEmpty ? null : _encodeCalls(m.toolCalls)),
    toolCallId: Value(m.toolCallId),
    toolName: Value(m.toolName),
    status: Value(m.status),
    createdAt: Value(m.createdAt),
  );

  String _encodeCalls(List<ApiToolCall> calls) =>
      jsonEncode([for (final call in calls) call.toJson()]);

  List<ApiToolCall> _decodeCalls(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (ApiToolCall.fromJson(item) != null) ApiToolCall.fromJson(item)!,
      ];
    } catch (_) {
      return const [];
    }
  }
}
