/// ChatRepository 新增方法：会话语音开关 + 跨会话记忆查询。
library;

import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:ai_roleplay_chat/features/chat/data/chat_repository.dart';
import 'package:ai_roleplay_chat/features/chat/domain/models.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ChatRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ChatRepository(db);
  });

  tearDown(() => db.close());

  Future<Conversation> newConv({String? characterId, String id = 'c'}) =>
      repo.createConversation(apiProfileId: 'p1', characterId: characterId, title: id);

  /// 直接插入消息并指定 createdAt（drift dateTime 按秒存，
  /// 依赖 insertMessage 的 DateTime.now() 无法构造确定时序）。
  Future<void> insertMsg({
    required String id,
    required String conversationId,
    ChatRole role = ChatRole.user,
    String? content,
    MessageStatus status = MessageStatus.done,
    required DateTime createdAt,
  }) async {
    final text = content ?? '内容$id';
    await db.into(db.messages).insert(MessagesCompanion(
          id: Value(id),
          conversationId: Value(conversationId),
          role: Value(role.wire),
          content: Value(text),
          rawContent: Value(text),
          status: Value(status.wire),
          createdAt: Value(createdAt),
        ));
  }

  group('setConversationVoiceEnabled', () {
    test('写读回环', () async {
      final c = await newConv();
      expect(c.voiceEnabled, isTrue); // 域模型默认开
      await repo.setConversationVoiceEnabled(c.id, false);
      expect((await repo.getConversation(c.id))!.voiceEnabled, isFalse);
      await repo.setConversationVoiceEnabled(c.id, true);
      expect((await repo.getConversation(c.id))!.voiceEnabled, isTrue);
    });
  });

  group('getRecentOtherMessages', () {
    test('排除当前会话、只取 done 非空、超限取最近并反转为时序', () async {
      final c1 = await newConv(characterId: 'ch1', id: 'c1');
      final c2 = await newConv(characterId: 'ch1', id: 'c2');
      final cOther = await newConv(characterId: 'ch2', id: 'c-other');
      final t = DateTime(2026, 1, 1);

      await insertMsg(id: 'a1', conversationId: c1.id, createdAt: t);
      await insertMsg(
          id: 'a2', conversationId: c1.id, role: ChatRole.assistant, createdAt: t.add(const Duration(minutes: 1)));
      await insertMsg(id: 'b1', conversationId: c2.id, createdAt: t.add(const Duration(minutes: 2)));
      await insertMsg(
          id: 'b2', conversationId: c2.id, role: ChatRole.assistant, createdAt: t.add(const Duration(minutes: 3)));
      await insertMsg(
          id: 'b3',
          conversationId: c2.id,
          status: MessageStatus.streaming,
          createdAt: t.add(const Duration(minutes: 4))); // 非 done：排除
      await insertMsg(
          id: 'b4',
          conversationId: c2.id,
          content: '',
          createdAt: t.add(const Duration(minutes: 5))); // 空内容：排除
      await insertMsg(id: 'x1', conversationId: cOther.id, createdAt: t.add(const Duration(minutes: 6)));

      final got = await repo.getRecentOtherMessages(
          characterId: 'ch1', excludeConversationId: c1.id);
      expect(got.map((m) => m.id), ['b1', 'b2']); // 时序升序；c1/非 done/空/他角色均排除

      final limited = await repo.getRecentOtherMessages(
          characterId: 'ch1', excludeConversationId: c1.id, limit: 1);
      expect(limited.map((m) => m.id), ['b2']); // 只取最近 1 条
    });

    test('同角色无其他会话：空返回（isIn 短路）', () async {
      final c1 = await newConv(characterId: 'ch1');
      await insertMsg(id: 'a1', conversationId: c1.id, createdAt: DateTime(2026));
      expect(
        await repo.getRecentOtherMessages(
            characterId: 'ch1', excludeConversationId: c1.id),
        isEmpty,
      );
    });
  });

  group('countDoneMessagesSince', () {
    test('null=全部 done 非空；有水位线只数更新的', () async {
      final c = await newConv();
      final t = DateTime(2026, 1, 1);
      await insertMsg(id: 'm1', conversationId: c.id, createdAt: t);
      await insertMsg(
          id: 'm2', conversationId: c.id, createdAt: t.add(const Duration(minutes: 1)));
      await insertMsg(
          id: 'm3',
          conversationId: c.id,
          status: MessageStatus.error,
          createdAt: t.add(const Duration(minutes: 2))); // 非 done：排除
      await insertMsg(
          id: 'm4',
          conversationId: c.id,
          content: '',
          createdAt: t.add(const Duration(minutes: 3))); // 空内容：排除

      expect(await repo.countDoneMessagesSince(c.id, null), 2);
      expect(await repo.countDoneMessagesSince(c.id, t), 1); // 只有 m2
      expect(
          await repo.countDoneMessagesSince(c.id, t.add(const Duration(minutes: 5))),
          0);
    });
  });
}
