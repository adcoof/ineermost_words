/// 会话与消息仓库。
library;

import 'package:drift/drift.dart';

import '../../../core/utils/id.dart';
import '../../../data/local/app_database.dart';
import '../domain/models.dart';

class ChatRepository {
  final AppDatabase db;

  ChatRepository(this.db);

  Stream<List<Conversation>> watchConversations() {
    final q = db.select(db.conversations)
      ..where((t) => t.archived.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    return q.watch().map((rows) => rows.map(_convFromRow).toList());
  }

  Future<Conversation?> getConversation(String id) async {
    final q = db.select(db.conversations)..where((t) => t.id.equals(id));
    final row = await q.getSingleOrNull();
    return row == null ? null : _convFromRow(row);
  }

  Stream<Conversation?> watchConversation(String id) {
    final q = db.select(db.conversations)..where((t) => t.id.equals(id));
    return q
        .watchSingleOrNull()
        .map((row) => row == null ? null : _convFromRow(row));
  }

  Future<Conversation> createConversation({
    required String apiProfileId,
    String? characterId,
    String? title,
  }) async {
    final now = DateTime.now();
    final conv = Conversation(
      id: newId(),
      title: title ?? '新会话',
      characterId: characterId,
      apiProfileId: apiProfileId,
      createdAt: now,
      updatedAt: now,
      archived: false,
    );
    await db.into(db.conversations).insert(_convToRow(conv));
    return conv;
  }

  /// 绑定/解绑会话的桌宠模型。
  Future<void> setConversationPetModel(String id, String? petModelId) async {
    await (db.update(db.conversations)..where((t) => t.id.equals(id)))
        .write(ConversationsCompanion(petModelId: Value(petModelId)));
  }

  Future<void> touchConversation(String id) async {
    await (db.update(db.conversations)..where((t) => t.id.equals(id)))
        .write(ConversationsCompanion(updatedAt: Value(DateTime.now())));
  }

  Future<void> renameConversation(String id, String title) async {
    await (db.update(db.conversations)..where((t) => t.id.equals(id)))
        .write(ConversationsCompanion(title: Value(title)));
  }

  Future<void> deleteConversation(String id) async {
    await db.transaction(() async {
      await (db.delete(db.messages)..where((t) => t.conversationId.equals(id)))
          .go();
      await (db.delete(db.conversations)..where((t) => t.id.equals(id))).go();
    });
  }

  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    final q = db.select(db.messages)
      ..where((t) => t.conversationId.equals(conversationId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return q.watch().map((rows) => rows.map(_msgFromRow).toList());
  }

  Future<ChatMessage?> getMessage(String id) async {
    final q = db.select(db.messages)..where((t) => t.id.equals(id));
    final row = await q.getSingleOrNull();
    return row == null ? null : _msgFromRow(row);
  }

  Future<ChatMessage> insertMessage({
    required String conversationId,
    required ChatRole role,
    String content = '',
    String rawContent = '',
    MessageStatus status = MessageStatus.done,
  }) async {
    final msg = ChatMessage(
      id: newId(),
      conversationId: conversationId,
      role: role,
      content: content,
      rawContent: rawContent,
      emotionEvents: '[]',
      status: status,
      createdAt: DateTime.now(),
    );
    await db.into(db.messages).insert(_msgToRow(msg));
    await touchConversation(conversationId);
    return msg;
  }

  Future<void> deleteMessage(String id) async {
    await (db.delete(db.messages)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateMessage(
    String id, {
    String? content,
    String? rawContent,
    String? emotionEvents,
    MessageStatus? status,
  }) async {
    await (db.update(db.messages)..where((t) => t.id.equals(id))).write(
      MessagesCompanion(
        content: content == null ? const Value.absent() : Value(content),
        rawContent: rawContent == null ? const Value.absent() : Value(rawContent),
        emotionEvents:
            emotionEvents == null ? const Value.absent() : Value(emotionEvents),
        status: status == null ? const Value.absent() : Value(status.wire),
      ),
    );
  }

  Conversation _convFromRow(ConversationRow row) => Conversation(
        id: row.id,
        title: row.title,
        characterId: row.characterId,
        petModelId: row.petModelId,
        apiProfileId: row.apiProfileId,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        archived: row.archived,
      );

  ConversationsCompanion _convToRow(Conversation c) => ConversationsCompanion(
        id: Value(c.id),
        title: Value(c.title),
        characterId: Value(c.characterId),
        petModelId: Value(c.petModelId),
        apiProfileId: Value(c.apiProfileId),
        createdAt: Value(c.createdAt),
        updatedAt: Value(c.updatedAt),
        archived: Value(c.archived),
      );

  ChatMessage _msgFromRow(MessageRow row) => ChatMessage(
        id: row.id,
        conversationId: row.conversationId,
        role: ChatRole.fromWire(row.role),
        content: row.content,
        rawContent: row.rawContent,
        emotionEvents: row.emotionEvents,
        status: MessageStatus.fromWire(row.status),
        createdAt: row.createdAt,
      );

  MessagesCompanion _msgToRow(ChatMessage m) => MessagesCompanion(
        id: Value(m.id),
        conversationId: Value(m.conversationId),
        role: Value(m.role.wire),
        content: Value(m.content),
        rawContent: Value(m.rawContent),
        emotionEvents: Value(m.emotionEvents),
        status: Value(m.status.wire),
        createdAt: Value(m.createdAt),
      );
}