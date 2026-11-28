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

/// 跨会话片段：一个会话 + 该会话最近的若干条消息（按时间升序）。
class CrossSessionGroup {
  final Conversation conversation;
  final List<ChatMessage> messages;

  const CrossSessionGroup({required this.conversation, required this.messages});
}

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
    String? parentConversationId,
    String? branchFromMessageId,
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
      parentConversationId: parentConversationId,
      branchFromMessageId: branchFromMessageId,
    );
    await db.into(db.conversations).insert(_convToRow(conv));
    return conv;
  }

  Future<List<ConversationParticipant>> listParticipants(
    String conversationId,
  ) async {
    final q = db.select(db.conversationParticipants)
      ..where((t) => t.conversationId.equals(conversationId))
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    return (await q.get()).map(_participantFromRow).toList();
  }

  Future<void> replaceParticipants(
    String conversationId,
    List<String> characterIds,
  ) async {
    await db.transaction(() async {
      await (db.delete(
        db.conversationParticipants,
      )..where((t) => t.conversationId.equals(conversationId))).go();
      for (var i = 0; i < characterIds.length; i++) {
        await db
            .into(db.conversationParticipants)
            .insert(
              ConversationParticipantsCompanion.insert(
                id: newId(),
                conversationId: conversationId,
                characterId: characterIds[i],
                sortOrder: Value(i),
                createdAt: DateTime.now(),
              ),
            );
      }
    });
  }

  /// 创建群聊：第一位角色作为会话主角色，其余按顺序进入参与者。
  Future<Conversation> createGroupConversation({
    required String apiProfileId,
    required List<String> characterIds,
    String? title,
  }) async {
    final ids = characterIds.toSet().toList();
    if (ids.length < 2) {
      throw ArgumentError('群聊至少需要两个角色');
    }
    if (ids.length > 3) {
      throw ArgumentError('群聊最多三位角色');
    }
    final conv = await createConversation(
      apiProfileId: apiProfileId,
      characterId: ids.first,
      title: title ?? '群聊',
    );
    await replaceParticipants(conv.id, ids);
    return conv;
  }

  /// 静音/启用群聊成员（只影响自动轮转，不影响强制发言）。
  Future<void> setParticipantEnabled(
    String conversationId,
    String characterId,
    bool enabled,
  ) async {
    await (db.update(db.conversationParticipants)..where(
          (t) =>
              t.conversationId.equals(conversationId) &
              t.characterId.equals(characterId),
        ))
        .write(ConversationParticipantsCompanion(enabled: Value(enabled)));
  }

  /// 添加群聊成员（最多 3 人）；自动排到末尾。
  Future<void> addParticipant(String conversationId, String characterId) async {
    final existing = await listParticipants(conversationId);
    if (existing.any((p) => p.characterId == characterId)) return;
    if (existing.length >= 3) {
      throw StateError('群聊最多三位角色');
    }
    final nextOrder = existing.isEmpty ? 0 : existing.last.sortOrder + 1;
    await db
        .into(db.conversationParticipants)
        .insert(
          ConversationParticipantsCompanion.insert(
            id: newId(),
            conversationId: conversationId,
            characterId: characterId,
            sortOrder: Value(nextOrder),
            createdAt: DateTime.now(),
          ),
        );
    await _setPrimaryCharacter(
      conversationId,
      existing.isEmpty ? characterId : existing.first.characterId,
    );
  }

  /// 移除群聊成员；主角色会同步为剩余第一位。
  Future<void> removeParticipant(
    String conversationId,
    String characterId,
  ) async {
    await (db.delete(db.conversationParticipants)..where(
          (t) =>
              t.conversationId.equals(conversationId) &
              t.characterId.equals(characterId),
        ))
        .go();
    final remaining = await listParticipants(conversationId);
    await _setPrimaryCharacter(
      conversationId,
      remaining.isEmpty ? null : remaining.first.characterId,
    );
  }

  /// 设置群成员使用的 API 供应商；null=跟随会话/默认。
  Future<void> setParticipantApiProfile(
    String conversationId,
    String characterId,
    String? apiProfileId,
  ) async {
    await (db.update(db.conversationParticipants)..where(
          (t) =>
              t.conversationId.equals(conversationId) &
              t.characterId.equals(characterId),
        ))
        .write(
          ConversationParticipantsCompanion(
            apiProfileId: apiProfileId == null || apiProfileId.isEmpty
                ? const Value(null)
                : Value(apiProfileId),
          ),
        );
  }

  /// 按给定顺序重排群聊成员；主角色同步为第一位。
  Future<void> reorderParticipants(
    String conversationId,
    List<String> characterIds,
  ) async {
    final participants = await listParticipants(conversationId);
    final byId = {for (final p in participants) p.characterId: p};
    await db.transaction(() async {
      for (var i = 0; i < characterIds.length; i++) {
        final participant = byId[characterIds[i]];
        if (participant == null) continue;
        await (db.update(db.conversationParticipants)
              ..where((t) => t.id.equals(participant.id)))
            .write(ConversationParticipantsCompanion(sortOrder: Value(i)));
      }
    });
    final ordered = await listParticipants(conversationId);
    await _setPrimaryCharacter(
      conversationId,
      ordered.isEmpty ? null : ordered.first.characterId,
    );
  }

  Future<void> _setPrimaryCharacter(
    String conversationId,
    String? characterId,
  ) async {
    await (db.update(db.conversations)
          ..where((t) => t.id.equals(conversationId)))
        .write(ConversationsCompanion(characterId: Value(characterId)));
  }

  /// 从某条消息分支：复制该消息及之前的全部消息到新会话。
  Future<Conversation> branchConversation({
    required String sourceConversationId,
    required String messageId,
  }) async {
    final source = await getConversation(sourceConversationId);
    final cut = await getMessage(messageId);
    if (source == null || cut == null || cut.conversationId != source.id) {
      throw StateError('分支源不存在');
    }
    final participants = await listParticipants(source.id);
    final branch = await createConversation(
      apiProfileId: source.apiProfileId,
      characterId: source.characterId,
      title: '${source.title} · 分支',
      parentConversationId: source.id,
      branchFromMessageId: cut.id,
    );
    final rows =
        await (db.select(db.messages)
              ..where(
                (t) =>
                    t.conversationId.equals(source.id) &
                    t.createdAt.isSmallerOrEqualValue(cut.createdAt),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    await setGroupSettings(
      branch.id,
      autoReply: source.groupAutoReply,
      banterRounds: source.groupBanterRounds,
    );
    await db.transaction(() async {
      for (final row in rows) {
        final msg = _msgFromRow(row);
        final copy = ChatMessage(
          id: newId(),
          conversationId: branch.id,
          role: msg.role,
          content: msg.content,
          rawContent: msg.rawContent,
          emotionEvents: msg.emotionEvents,
          imagePaths: msg.imagePaths,
          imageSummary: msg.imageSummary,
          status: msg.status,
          kind: msg.kind,
          speakerCharacterId: msg.speakerCharacterId,
          createdAt: msg.createdAt,
        );
        await db.into(db.messages).insert(_msgToRow(copy));
      }
      for (var i = 0; i < participants.length; i++) {
        await db
            .into(db.conversationParticipants)
            .insert(
              ConversationParticipantsCompanion.insert(
                id: newId(),
                conversationId: branch.id,
                characterId: participants[i].characterId,
                sortOrder: Value(participants[i].sortOrder),
                enabled: Value(participants[i].enabled),
                apiProfileId: Value(participants[i].apiProfileId),
                createdAt: DateTime.now(),
              ),
            );
      }
    });
    return branch;
  }

  /// 群聊行为：用户发言后是否全员回复、自动拌嘴轮数。
  Future<void> setGroupSettings(
    String conversationId, {
    bool? autoReply,
    int? banterRounds,
  }) async {
    await (db.update(
      db.conversations,
    )..where((t) => t.id.equals(conversationId))).write(
      ConversationsCompanion(
        groupAutoReply: autoReply == null
            ? const Value.absent()
            : Value(autoReply),
        groupBanterRounds: banterRounds == null
            ? const Value.absent()
            : Value(banterRounds.clamp(0, 3)),
      ),
    );
  }

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
      final messageIds =
          await (db.selectOnly(db.messages)
                ..addColumns([db.messages.id])
                ..where(db.messages.conversationId.equals(id)))
              .map((row) => row.read(db.messages.id)!)
              .get();
      if (messageIds.isNotEmpty) {
        await (db.delete(
          db.messageVariants,
        )..where((t) => t.messageId.isIn(messageIds))).go();
      }
      await (db.delete(
        db.messages,
      )..where((t) => t.conversationId.equals(id))).go();
      await (db.delete(
        db.conversationParticipants,
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
    String? speakerCharacterId,
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
      speakerCharacterId: speakerCharacterId,
      createdAt: createdAt ?? DateTime.now(),
    );
    await db.into(db.messages).insert(_msgToRow(msg));
    await touchConversation(conversationId);
    return msg;
  }

  Future<void> deleteMessage(String id) async {
    await db.transaction(() async {
      await (db.delete(
        db.messageVariants,
      )..where((t) => t.messageId.equals(id))).go();
      await (db.delete(db.messages)..where((t) => t.id.equals(id))).go();
    });
  }

  /// 读取某条消息的全部候选，按创建时间正序。
  Future<List<MessageVariant>> getVariants(String messageId) async {
    final q = db.select(db.messageVariants)
      ..where((t) => t.messageId.equals(messageId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return (await q.get()).map(_variantFromRow).toList();
  }

  /// 追加候选并把它设为当前候选。
  Future<void> addVariant(MessageVariant variant) async {
    await db.transaction(() async {
      await db
          .into(db.messageVariants)
          .insertOnConflictUpdate(
            MessageVariantsCompanion(
              id: Value(variant.id),
              messageId: Value(variant.messageId),
              content: Value(variant.content),
              rawContent: Value(variant.rawContent),
              emotionEvents: Value(variant.emotionEvents),
              createdAt: Value(variant.createdAt),
            ),
          );
      await (db.update(db.messages)
            ..where((t) => t.id.equals(variant.messageId)))
          .write(MessagesCompanion(activeVariantId: Value(variant.id)));
    });
  }

  /// 切换当前候选；variantId 为 null 时回到正文。
  Future<void> setActiveVariant(String messageId, String? variantId) async {
    await (db.update(db.messages)..where((t) => t.id.equals(messageId))).write(
      MessagesCompanion(activeVariantId: Value(variantId)),
    );
  }

  MessageVariant _variantFromRow(MessageVariantRow row) => MessageVariant(
    id: row.id,
    messageId: row.messageId,
    content: row.content,
    rawContent: row.rawContent,
    emotionEvents: row.emotionEvents,
    createdAt: row.createdAt,
  );

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

  /// 同角色未归档会话，按最近活跃倒序（记忆整理/跨会话片段用）。
  Future<List<Conversation>> getConversationsForCharacter(
    String characterId, {
    int limit = 8,
  }) async {
    final q = db.select(db.conversations)
      ..where(
        (t) => t.characterId.equals(characterId) & t.archived.equals(false),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
      ..limit(limit);
    return (await q.get()).map(_convFromRow).toList();
  }

  /// 会话自 [since]（null=全部，含边界）之后的完成文本消息，取最近 [limit] 条后升序。
  ///
  /// 用 `>=` 而非 `>`：Drift dateTime 存秒级，边界那一秒的消息宁可重复
  /// 计入（由提示词去重），不能丢；纯图但有 imageSummary 的消息也算内容。
  Future<List<ChatMessage>> getDoneMessagesAfter(
    String conversationId,
    DateTime? since, {
    int limit = 80,
  }) async {
    final q = db.select(db.messages)
      ..where(
        (t) =>
            t.conversationId.equals(conversationId) &
            t.status.equals(MessageStatus.done.wire) &
            t.kind.equals(MessageKind.text.wire) &
            (t.content.equals('').not() | t.imageSummary.equals('').not()),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit);
    if (since != null) {
      q.where((t) => t.createdAt.isBiggerOrEqualValue(since));
    }
    return (await q.get()).reversed.map(_msgFromRow).toList();
  }

  /// 跨会话片段 v2：按会话分组，每组取最新 [perConversation] 条，
  /// 取最近活跃的 [maxConversations] 个会话。纯图 + imageSummary 不再丢失。
  Future<List<CrossSessionGroup>> getCrossSessionDigest({
    required String characterId,
    required String excludeConversationId,
    int maxConversations = 4,
    int perConversation = 8,
  }) async {
    final convQ = db.select(db.conversations)
      ..where(
        (t) =>
            t.characterId.equals(characterId) &
            t.archived.equals(false) &
            t.id.equals(excludeConversationId).not(),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
      ..limit(maxConversations);
    final groups = <CrossSessionGroup>[];
    for (final row in await convQ.get()) {
      final q = db.select(db.messages)
        ..where(
          (t) =>
              t.conversationId.equals(row.id) &
              t.status.equals(MessageStatus.done.wire) &
              t.kind.equals(MessageKind.text.wire) &
              (t.content.equals('').not() | t.imageSummary.equals('').not()),
        )
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
        ..limit(perConversation);
      final messages = (await q.get()).reversed.map(_msgFromRow).toList();
      if (messages.isNotEmpty) {
        groups.add(
          CrossSessionGroup(
            conversation: _convFromRow(row),
            messages: messages,
          ),
        );
      }
    }
    return groups;
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
    parentConversationId: row.parentConversationId,
    branchFromMessageId: row.branchFromMessageId,
    groupAutoReply: row.groupAutoReply,
    groupBanterRounds: row.groupBanterRounds,
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
    parentConversationId: Value(c.parentConversationId),
    branchFromMessageId: Value(c.branchFromMessageId),
    groupAutoReply: Value(c.groupAutoReply),
    groupBanterRounds: Value(c.groupBanterRounds),
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
    activeVariantId: row.activeVariantId,
    speakerCharacterId: row.speakerCharacterId,
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
    activeVariantId: Value(m.activeVariantId),
    speakerCharacterId: Value(m.speakerCharacterId),
    createdAt: Value(m.createdAt),
  );

  ConversationParticipant _participantFromRow(ConversationParticipantRow row) =>
      ConversationParticipant(
        id: row.id,
        conversationId: row.conversationId,
        characterId: row.characterId,
        sortOrder: row.sortOrder,
        enabled: row.enabled,
        apiProfileId: row.apiProfileId,
        createdAt: row.createdAt,
      );
}
