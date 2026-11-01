/// 会话与消息仓库。
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
    return q.watchSingleOrNull().map(
      (row) => row == null ? null : _convFromRow(row),
    );
  }

  Future<Conversation> createConversation({
    required String apiProfileId,
    String? characterId,
    String? title,
  }) async {
    final now = DateTime.now();
    // 默认桌宠（v8）：内置 Haru 存在时新会话自动绑定；「不使用桌宠」仍可事后解绑。
    String? defaultPetId;
    final haru = await (db.select(
      db.petModels,
    )..where((t) => t.id.equals('haru'))).getSingleOrNull();
    if (haru != null) defaultPetId = 'haru';
    final conv = Conversation(
      id: newId(),
      title: title ?? '新会话',
      characterId: characterId,
      petModelId: defaultPetId,
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
    await (db.update(db.conversations)..where((t) => t.id.equals(id))).write(
      ConversationsCompanion(petModelId: Value(petModelId)),
    );
  }

  /// 设置会话级自动朗读开关。
  Future<void> setConversationVoiceEnabled(String id, bool enabled) async {
    await (db.update(db.conversations)..where((t) => t.id.equals(id))).write(
      ConversationsCompanion(voiceEnabled: Value(enabled)),
    );
  }

  /// 设置/清除会话背景板（v8）。
  Future<void> setConversationBackground(String id, String? path) async {
    await (db.update(db.conversations)..where((t) => t.id.equals(id))).write(
      ConversationsCompanion(backgroundPath: Value(path)),
    );
  }

  Future<void> touchConversation(String id) async {
    await (db.update(db.conversations)..where((t) => t.id.equals(id))).write(
      ConversationsCompanion(updatedAt: Value(DateTime.now())),
    );
  }

  Future<void> renameConversation(String id, String title) async {
    await (db.update(db.conversations)..where((t) => t.id.equals(id))).write(
      ConversationsCompanion(title: Value(title)),
    );
  }

  Future<void> deleteConversation(String id) async {
    await db.transaction(() async {
      await (db.delete(
        db.messages,
      )..where((t) => t.conversationId.equals(id))).go();
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
    String? id,
    required String conversationId,
    required ChatRole role,
    String content = '',
    String rawContent = '',
    MessageStatus status = MessageStatus.done,
    List<String> imagePaths = const [],
    String imageSummary = '',
    MessageKind kind = MessageKind.text,
    DateTime? createdAt,
  }) async {
    final msg = ChatMessage(
      id: id ?? newId(),
      conversationId: conversationId,
      role: role,
      content: content,
      rawContent: rawContent,
      emotionEvents: '[]',
      imagePaths: jsonEncode(imagePaths),
      imageSummary: imageSummary,
      status: status,
      kind: kind,
      createdAt: createdAt ?? DateTime.now(),
    );
    await db.into(db.messages).insert(_msgToRow(msg));
    await touchConversation(conversationId);
    return msg;
  }

  Future<void> deleteMessage(String id) async {
    await (db.delete(db.messages)..where((t) => t.id.equals(id))).go();
  }

  /// 同角色其他会话中最近的完成消息，按时间升序返回（跨会话记忆·近期原文）。
  ///
  /// 两步查询（无 join，对齐项目风格）：先取同角色其他会话 id，
  /// 再按 createdAt 倒序取 [limit] 条后反转为时序。archived 不过滤
  ///（全库无置 true 的路径，保持与 watchConversations 同口径）。
  Future<List<ChatMessage>> getRecentOtherMessages({
    required String characterId,
    required String excludeConversationId,
    int limit = 40,
  }) async {
    final convQ = db.select(db.conversations)
      ..where(
        (t) =>
            t.characterId.equals(characterId) &
            t.id.equals(excludeConversationId).not(),
      );
    final ids = (await convQ.get()).map((r) => r.id).toList();
    if (ids.isEmpty) return const []; // isIn 空列表语义不可靠，显式短路。
    final q = db.select(db.messages)
      ..where(
        (t) =>
            t.conversationId.isIn(ids) &
            t.status.equals(MessageStatus.done.wire) &
            t.kind.equals(MessageKind.text.wire) &
            t.content.equals('').not(),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit);
    return (await q.get()).reversed.map(_msgFromRow).toList();
  }

  /// 本会话自 [since]（null=全部）之后的完成消息数（摘要触发阈值用）。
  Future<int> countDoneMessagesSince(
    String conversationId,
    DateTime? since,
  ) async {
    final q = db.select(db.messages)
      ..where(
        (t) =>
            t.conversationId.equals(conversationId) &
            t.status.equals(MessageStatus.done.wire) &
            t.kind.equals(MessageKind.text.wire) &
            t.content.equals('').not(),
      );
    if (since != null) {
      q.where((t) => t.createdAt.isBiggerThanValue(since));
    }
    return (await q.get()).length;
  }

  /// 本会话用户消息数（首条消息即时标题判定用）。
  Future<int> countUserMessages(String conversationId) async {
    final q = db.select(db.messages)
      ..where(
        (t) =>
            t.conversationId.equals(conversationId) &
            t.role.equals(ChatRole.user.wire),
      );
    return (await q.get()).length;
  }

  /// 保存消息附图到 documents/messages/{messageId}/img_{i}.jpg，返回绝对路径列表。
  ///
  /// 消息附图不可变（无覆盖写），无需 FileImage.evict。
  /// [root] 注入便于纯单测（测试环境 path_provider 会 MissingPluginException）。
  Future<List<String>> saveMessageImages(
    String messageId,
    List<Uint8List> images, {
    Directory? root,
  }) async {
    if (images.isEmpty) return const [];
    final dir =
        root ??
        Directory(
          p.join(
            (await getApplicationDocumentsDirectory()).path,
            'messages',
            messageId,
          ),
        );
    await dir.create(recursive: true);
    final paths = <String>[];
    for (var i = 0; i < images.length; i++) {
      final file = File(p.join(dir.path, 'img_$i.jpg'));
      await file.writeAsBytes(images[i], flush: true);
      paths.add(file.path);
    }
    return paths;
  }

  Future<void> updateMessage(
    String id, {
    String? content,
    String? rawContent,
    String? emotionEvents,
    String? imageSummary,
    MessageStatus? status,
  }) async {
    await (db.update(db.messages)..where((t) => t.id.equals(id))).write(
      MessagesCompanion(
        content: content == null ? const Value.absent() : Value(content),
        rawContent: rawContent == null
            ? const Value.absent()
            : Value(rawContent),
        emotionEvents: emotionEvents == null
            ? const Value.absent()
            : Value(emotionEvents),
        imageSummary: imageSummary == null
            ? const Value.absent()
            : Value(imageSummary),
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
    voiceEnabled: row.voiceEnabled,
    backgroundPath: row.backgroundPath,
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
    voiceEnabled: Value(c.voiceEnabled),
    backgroundPath: Value(c.backgroundPath),
  );

  ChatMessage _msgFromRow(MessageRow row) => ChatMessage(
    id: row.id,
    conversationId: row.conversationId,
    role: ChatRole.fromWire(row.role),
    content: row.content,
    rawContent: row.rawContent,
    emotionEvents: row.emotionEvents,
    imagePaths: row.imagePaths,
    imageSummary: row.imageSummary,
    status: MessageStatus.fromWire(row.status),
    kind: MessageKind.fromWire(row.kind),
    createdAt: row.createdAt,
  );

  MessagesCompanion _msgToRow(ChatMessage m) => MessagesCompanion(
    id: Value(m.id),
    conversationId: Value(m.conversationId),
    role: Value(m.role.wire),
    content: Value(m.content),
    rawContent: Value(m.rawContent),
    emotionEvents: Value(m.emotionEvents),
    imagePaths: Value(m.imagePaths),
    imageSummary: Value(m.imageSummary),
    status: Value(m.status.wire),
    kind: Value(m.kind.wire),
    createdAt: Value(m.createdAt),
  );
}
