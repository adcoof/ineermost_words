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

  group('消息附图（v7）', () {
    test('insertMessage 带 id/附图/概括：写读回环 + 路径解析', () async {
      final c = await newConv();
      final inserted = await repo.insertMessage(
        id: 'm-img',
        conversationId: c.id,
        role: ChatRole.user,
        content: '看这两张图',
        imagePaths: const ['/a/img_0.jpg', '/a/img_1.jpg'],
        imageSummary: '湖边的两只猫',
      );
      expect(inserted.id, 'm-img');

      final got = await repo.getMessage('m-img');
      expect(got, isNotNull);
      expect(got!.imagePaths, '["/a/img_0.jpg","/a/img_1.jpg"]');
      expect(got.imageFilePaths, ['/a/img_0.jpg', '/a/img_1.jpg']);
      expect(got.imageSummary, '湖边的两只猫');
    });

    test('imageFilePaths：坏 JSON 解析失败按无图处理', () {
      ChatMessage msg(String imagePaths) => ChatMessage(
            id: 'm',
            conversationId: 'c',
            role: ChatRole.user,
            content: 'x',
            rawContent: 'x',
            emotionEvents: '[]',
            imagePaths: imagePaths,
            status: MessageStatus.done,
            createdAt: DateTime(2026),
          );
      expect(msg('not-json').imageFilePaths, isEmpty);
      expect(msg('{"a":1}').imageFilePaths, isEmpty); // 非数组
    });

    test('contentWithImageNote 三分支', () {
      ChatMessage msg({
        String content = '正文',
        String imagePaths = '["/a.jpg"]',
        String imageSummary = '',
      }) =>
          ChatMessage(
            id: 'm',
            conversationId: 'c',
            role: ChatRole.user,
            content: content,
            rawContent: content,
            emotionEvents: '[]',
            imagePaths: imagePaths,
            imageSummary: imageSummary,
            status: MessageStatus.done,
            createdAt: DateTime(2026),
          );
      // 无图：原样返回正文。
      expect(msg(imagePaths: '[]').contentWithImageNote, '正文');
      // 有图有概括：正文 + [图片：概括]。
      expect(msg(imageSummary: '湖边的两只猫').contentWithImageNote,
          '正文\n[图片：湖边的两只猫]');
      // 有图无概括：[图片] 占位。
      expect(msg().contentWithImageNote, '正文\n[图片]');
      // 纯图空文：备注本身。
      expect(msg(content: '', imageSummary: '一只猫').contentWithImageNote,
          '[图片：一只猫]');
      expect(msg(content: '').contentWithImageNote, '[图片]');
    });

    test('updateMessage：imageSummary 单字段更新，其余列不受影响', () async {
      final c = await newConv();
      await repo.insertMessage(
        id: 'm1',
        conversationId: c.id,
        role: ChatRole.user,
        content: '正文',
        imagePaths: const ['/a.jpg'],
      );
      await repo.updateMessage('m1', imageSummary: '概括');
      final got = await repo.getMessage('m1');
      expect(got!.imageSummary, '概括');
      expect(got.content, '正文'); // absent 守卫：未传列不被覆盖
      expect(got.imagePaths, '["/a.jpg"]');
    });

    test('countUserMessages：只数 role=user', () async {
      final c = await newConv();
      await insertMsg(id: 'u1', conversationId: c.id, createdAt: DateTime(2026));
      await insertMsg(
          id: 'a1',
          conversationId: c.id,
          role: ChatRole.assistant,
          createdAt: DateTime(2026, 1, 1, 0, 1));
      await insertMsg(
          id: 'u2', conversationId: c.id, createdAt: DateTime(2026, 1, 1, 0, 2));
      expect(await repo.countUserMessages(c.id), 2);
    });
  });

  group('消息 kind 与背景板（v8）', () {
    test('insertMessage kind 默认 text、sticker 写读回环', () async {
      final c = await newConv();
      final textMsg = await repo.insertMessage(
          conversationId: c.id, role: ChatRole.assistant, content: '你好');
      expect(textMsg.kind, MessageKind.text);
      expect((await repo.getMessage(textMsg.id))!.kind, MessageKind.text);

      final sticker = await repo.insertMessage(
        conversationId: c.id,
        role: ChatRole.assistant,
        imagePaths: const ['/tmp/s.jpg'],
        imageSummary: '表情包',
        kind: MessageKind.sticker,
      );
      final got = await repo.getMessage(sticker.id);
      expect(got!.kind, MessageKind.sticker);
      expect(got.imageFilePaths, ['/tmp/s.jpg']);
    });

    test('getRecentOtherMessages / countDoneMessagesSince 排除贴纸行',
        () async {
      final c1 = await newConv(characterId: 'ch1', id: 'c1');
      final c2 = await newConv(characterId: 'ch1', id: 'c2');
      await repo.insertMessage(
          conversationId: c2.id,
          role: ChatRole.assistant,
          content: '普通回复');
      await repo.insertMessage(
        conversationId: c2.id,
        role: ChatRole.assistant,
        imagePaths: const ['/tmp/s.jpg'],
        imageSummary: '表情包',
        kind: MessageKind.sticker,
      );

      final recent = await repo.getRecentOtherMessages(
          characterId: 'ch1', excludeConversationId: c1.id);
      expect(recent, hasLength(1));
      expect(recent.single.kind, MessageKind.text);

      final count = await repo.countDoneMessagesSince(c2.id, null);
      expect(count, 1); // 贴纸行不计数
    });

    test('setConversationBackground 写读回环（含清除）', () async {
      final c = await newConv();
      expect(c.backgroundPath, isNull);
      await repo.setConversationBackground(c.id, '/bg/a.jpg');
      expect(
          (await repo.getConversation(c.id))!.backgroundPath, '/bg/a.jpg');
      await repo.setConversationBackground(c.id, null);
      expect((await repo.getConversation(c.id))!.backgroundPath, isNull);
    });
  });

  group('createConversation 默认桌宠（v8）', () {
    test('库中无 haru：petModelId 为 null', () async {
      final c = await newConv();
      expect(c.petModelId, isNull);
    });

    test('种入 haru 行后：新会话自动绑定', () async {
      await db.into(db.petModels).insert(PetModelsCompanion.insert(
            id: 'haru',
            name: 'Haru',
            dirPath: '/x/pets/haru',
            entryJsonPath: '/x/pets/haru/Haru.model3.json',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ));
      final c = await newConv();
      expect(c.petModelId, 'haru');
    });
  });
}
