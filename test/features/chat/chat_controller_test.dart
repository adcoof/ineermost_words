/// ChatController 空回复兜底：判空、单次自动重试、删除空占位、
/// 面向用户的错误提示，以及错误/取消路径不留空泡。
library;

import 'dart:async';

import 'package:ai_roleplay_chat/app/providers.dart';
import 'package:ai_roleplay_chat/core/errors/app_exception.dart';
import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:ai_roleplay_chat/features/characters/data/character_repository.dart';
import 'package:ai_roleplay_chat/features/characters/domain/character.dart';
import 'package:ai_roleplay_chat/features/chat/application/chat_controller.dart';
import 'package:ai_roleplay_chat/features/chat/application/memory_summarizer.dart';
import 'package:ai_roleplay_chat/features/chat/application/speech_sink.dart';
import 'package:ai_roleplay_chat/features/chat/application/title_generator.dart';
import 'package:ai_roleplay_chat/features/chat/data/chat_api_client.dart';
import 'package:ai_roleplay_chat/features/chat/data/chat_repository.dart';
import 'package:ai_roleplay_chat/features/chat/domain/models.dart';
import 'package:ai_roleplay_chat/features/settings/data/api_profile_repository.dart';
import 'package:ai_roleplay_chat/features/settings/data/app_settings_repository.dart';
import 'package:ai_roleplay_chat/features/settings/domain/api_profile.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Responder = Stream<ChatDelta> Function();

/// 按调用次序返回预设流；超出后复用最后一条。记录每次的 maxTokens。
class _ScriptedApi implements ChatApiClient {
  _ScriptedApi(this.responses);

  List<_Responder> responses;
  int calls = 0;
  final List<int?> maxTokensHistory = [];
  final List<List<ApiMessage>> sentMessages = [];

  @override
  Stream<ChatDelta> streamChat({
    required ApiProfile profile,
    required List<ApiMessage> messages,
    double? temperature,
    int? maxTokens,
    List<ApiTool>? tools,
    CancelToken? cancelToken,
  }) {
    maxTokensHistory.add(maxTokens);
    sentMessages.add(List<ApiMessage>.from(messages));
    final index = calls < responses.length ? calls : responses.length - 1;
    calls++;
    return responses[index]();
  }

  @override
  Future<void> testConnection({
    required ApiProfile profile,
    CancelToken? cancelToken,
  }) async {}
}

class _NoopTitleGenerator extends TitleGenerator {
  _NoopTitleGenerator({
    required super.chatRepo,
    required super.profileRepo,
    required super.api,
  });

  @override
  Future<void> maybeRefine({required String conversationId}) async {}
}

class _NoopMemorySummarizer extends MemorySummarizer {
  _NoopMemorySummarizer({
    required super.chatRepo,
    required super.characterRepo,
    required super.profileRepo,
    required super.api,
  });

  @override
  Future<void> maybeUpdateMemory({
    required String conversationId,
    required String characterId,
  }) async {}
}

void main() {
  late AppDatabase db;
  late ChatRepository chatRepo;
  late ApiProfileRepository profileRepo;
  late _ScriptedApi api;
  late ProviderContainer container;
  late ChatController controller;

  const profile = ApiProfile(
    id: 'p1',
    name: '测试',
    baseUrl: 'https://example.com/v1',
    apiKey: 'sk-test',
    model: 'm1',
    temperature: 1.0,
    maxTokens: 512,
    extraHeaders: '{}',
    isDefault: true,
  );

  _Responder text(String value, {String finish = 'stop'}) => () =>
      Stream.fromIterable([
        ChatDelta(content: value),
        ChatDelta(finishReason: finish),
      ]);

  _Responder empty({String? finish}) => () => Stream.fromIterable([
    ChatDelta(finishReason: finish),
  ]);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    chatRepo = ChatRepository(db);
    profileRepo = ApiProfileRepository(db);
    await profileRepo.save(profile);
    api = _ScriptedApi([]);
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        chatApiClientProvider.overrideWithValue(api),
        speechSinkProvider.overrideWithValue(const NoopSpeechSink()),
        titleGeneratorProvider.overrideWith(
          (ref) => _NoopTitleGenerator(
            chatRepo: chatRepo,
            profileRepo: profileRepo,
            api: api,
          ),
        ),
        memorySummarizerProvider.overrideWith(
          (ref) => _NoopMemorySummarizer(
            chatRepo: chatRepo,
            characterRepo: CharacterRepository(db),
            profileRepo: profileRepo,
            api: api,
          ),
        ),
      ],
    );
    controller = container.read(chatControllerProvider.notifier);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<List<ChatMessage>> assistantMessages() async {
    final convId = container.read(chatControllerProvider).conversationId!;
    final all = await chatRepo.watchMessages(convId).first;
    return all.where((m) => m.role == ChatRole.assistant).toList();
  }

  test('正常回复：落一条 done 正文，无错误提示', () async {
    api.responses = [text('你好')];
    await controller.send('hi');

    final replies = await assistantMessages();
    expect(replies, hasLength(1));
    expect(replies.single.content, '你好');
    expect(replies.single.status, MessageStatus.done);
    expect(container.read(chatControllerProvider).errorText, isNull);
    expect(container.read(chatControllerProvider).isStreaming, isFalse);
  });

  test('旧会话 pin 的供应商不存在时回退默认配置', () async {
    final conv = await chatRepo.createConversation(apiProfileId: 'ghost');
    controller.bindConversation(conv.id);
    api.responses = [text('回退成功')];

    await controller.send('hi');

    final replies = await assistantMessages();
    expect(replies, hasLength(1));
    expect(replies.single.content, '回退成功');
    expect(container.read(chatControllerProvider).errorText, isNull);
  });

  test('重试上一条失败消息：不重复用户消息', () async {
    api.responses = [
      () => Stream<ChatDelta>.error(const ServerException('boom')),
      () => Stream.value(const ChatDelta(content: '重试成功')),
    ];
    await controller.send('hi');
    expect(container.read(chatControllerProvider).errorText, isNotNull);

    await controller.retryLastTurn();

    final convId = container.read(chatControllerProvider).conversationId!;
    final all = await chatRepo.watchMessages(convId).first;
    expect(all.where((m) => m.role == ChatRole.user), hasLength(1));
    expect(all.last.content, '重试成功');
    expect(all.last.status, MessageStatus.done);
  });

  test('发送后写入 contextUsage，窗口大小来自设置', () async {
    await AppSettingsRepository(db).setContextWindowTokens(1024);
    api.responses = [text('你好')];
    await controller.send('hi');

    final usage = container.read(chatControllerProvider).contextUsage;
    expect(usage, isNotNull);
    expect(usage!.windowTokens, 1024);
    expect(usage.usedTokens, greaterThan(0));
  });

  test('首轮空流：自动重试一次，第二轮成功且只留一条消息', () async {
    api.responses = [empty(), text('第二次')];
    await controller.send('hi');

    expect(api.calls, 2);
    final replies = await assistantMessages();
    expect(replies, hasLength(1));
    expect(replies.single.content, '第二次');
    expect(replies.single.status, MessageStatus.done);
    expect(container.read(chatControllerProvider).errorText, isNull);
  });

  test('两轮都空：删除空占位、只留用户消息、给出提示', () async {
    api.responses = [empty(), empty()];
    await controller.send('hi');

    expect(api.calls, 2);
    final replies = await assistantMessages();
    expect(replies, isEmpty);
    final convId = container.read(chatControllerProvider).conversationId!;
    final all = await chatRepo.watchMessages(convId).first;
    expect(all, hasLength(1));
    expect(all.single.role, ChatRole.user);
    expect(container.read(chatControllerProvider).errorText, isNotNull);
    expect(container.read(chatControllerProvider).errorText, contains('没有返回内容'));
  });

  test('关闭自动重试：空流只调用一次', () async {
    await AppSettingsRepository(db).setAutoRetryEnabled(false);
    api.responses = [empty(), text('不该出现')];
    await controller.send('hi');

    expect(api.calls, 1);
    expect(await assistantMessages(), isEmpty);
    expect(container.read(chatControllerProvider).errorText, isNotNull);
  });

  test('length 截断重试：预算提升到 max(2x, 1024)', () async {
    api.responses = [empty(finish: 'length'), text('加预算后')];
    await controller.send('hi');

    expect(api.calls, 2);
    expect(api.maxTokensHistory, [null, 1024]);
    final replies = await assistantMessages();
    expect(replies.single.content, '加预算后');
  });

  test('reasoning-only：正文不误写推理内容，提示检查输出预算', () async {
    _Responder reasoningOnly() => () => Stream.fromIterable([
      const ChatDelta(reasoning: '让我想想'),
      const ChatDelta(finishReason: 'stop'),
    ]);
    api.responses = [reasoningOnly(), reasoningOnly()];
    await controller.send('hi');

    expect(api.calls, 2);
    expect(await assistantMessages(), isEmpty);
    final error = container.read(chatControllerProvider).errorText;
    expect(error, isNotNull);
    expect(error, contains('推理'));
  });

  test('content_filter：不重试，提示安全策略', () async {
    api.responses = [empty(finish: 'content_filter')];
    await controller.send('hi');

    expect(api.calls, 1);
    expect(await assistantMessages(), isEmpty);
    expect(container.read(chatControllerProvider).errorText, contains('安全策略'));
  });

  test('流中途异常但已有正文：保留半截并标记 error', () async {
    api.responses = [
      () async* {
        yield const ChatDelta(content: '半句');
        throw const ServerException('boom');
      },
    ];
    await controller.send('hi');

    final replies = await assistantMessages();
    expect(replies, hasLength(1));
    expect(replies.single.content, '半句');
    expect(replies.single.status, MessageStatus.error);
    expect(container.read(chatControllerProvider).errorText, 'boom');
  });

  test('流中途取消但已有正文：保留半截并标记 done', () async {
    api.responses = [
      () async* {
        yield const ChatDelta(content: '半句');
        throw const CancelledException('用户停止');
      },
    ];
    await controller.send('hi');

    final replies = await assistantMessages();
    expect(replies, hasLength(1));
    expect(replies.single.content, '半句');
    expect(replies.single.status, MessageStatus.done);
    expect(container.read(chatControllerProvider).isStreaming, isFalse);
    expect(container.read(chatControllerProvider).errorText, isNull);
  });

  test('模型输出 [P] 分段：落两条消息，不触发兜底补切', () async {
    api.responses = [
      text('第一段\n[P]\n第二段\n'),
    ];
    await controller.send('hi');

    final replies = await assistantMessages();
    expect(replies, hasLength(2));
    expect(replies[0].content, contains('第一段'));
    expect(replies[1].content, contains('第二段'));
    expect(replies.every((m) => m.status == MessageStatus.done), isTrue);
  });

  group('候选回复 / 重新生成 / 编辑 / 开场白（v14）', () {
    test('重新生成：旧正文落候选，新正文成为当前候选', () async {
      final conv = await chatRepo.createConversation(apiProfileId: profile.id);
      controller.bindConversation(conv.id);
      await chatRepo.insertMessage(
        conversationId: conv.id,
        role: ChatRole.user,
        content: 'hi',
        rawContent: 'hi',
      );
      final assistant = await chatRepo.insertMessage(
        conversationId: conv.id,
        role: ChatRole.assistant,
        content: '旧回复',
        rawContent: '旧回复',
        status: MessageStatus.done,
      );
      api.responses = [text('新回复')];
      expect(await controller.regenerateMessage(assistant.id), isTrue);

      final message = await chatRepo.getMessage(assistant.id);
      expect(message!.content, '新回复');
      expect(message.status, MessageStatus.done);
      final variants = await chatRepo.getVariants(assistant.id);
      expect(variants.length, 2);
      expect(
        variants.firstWhere((v) => v.id == message.activeVariantId).content,
        '新回复',
      );
    });

    test('swipe 切换候选不发请求，编辑保存为候选', () async {
      final conv = await chatRepo.createConversation(apiProfileId: profile.id);
      controller.bindConversation(conv.id);
      await chatRepo.insertMessage(
        conversationId: conv.id,
        role: ChatRole.user,
        content: 'hi',
        rawContent: 'hi',
      );
      final assistant = await chatRepo.insertMessage(
        conversationId: conv.id,
        role: ChatRole.assistant,
        content: '旧回复',
        rawContent: '旧回复',
        status: MessageStatus.done,
      );
      api.responses = [text('新回复')];
      await controller.regenerateMessage(assistant.id);

      final callsBefore = api.calls;
      expect(await controller.switchVariant(assistant.id, -1), isTrue);
      expect(api.calls, callsBefore);
      expect((await chatRepo.getMessage(assistant.id))!.content, '旧回复');

      expect(await controller.editMessage(assistant.id, '编辑版'), isTrue);
      final message = await chatRepo.getMessage(assistant.id);
      expect(message!.content, '编辑版');
      final variants = await chatRepo.getVariants(assistant.id);
      expect(variants.any((v) => v.content == '编辑版'), isTrue);
    });

    test('无用户消息时可循环开场白', () async {
      final chars = CharacterRepository(db);
      final character = chars.blank().copyWith(
        name: '小雨',
        firstMessage: '主开场',
        alternateGreetings: const ['备用开场'],
      );
      await chars.save(character);
      final conv = await chatRepo.createConversation(
        apiProfileId: profile.id,
        characterId: character.id,
      );
      controller.bindConversation(conv.id);
      final first = await chatRepo.insertMessage(
        conversationId: conv.id,
        role: ChatRole.assistant,
        content: '主开场',
        rawContent: '主开场',
        status: MessageStatus.done,
      );

      expect(await controller.cycleAlternateGreeting(), isTrue);
      expect((await chatRepo.getMessage(first.id))!.content, '备用开场');
      expect(await controller.cycleAlternateGreeting(), isTrue);
      expect((await chatRepo.getMessage(first.id))!.content, '主开场');
    });
  });
  group('群聊与分支（v16）', () {
    Future<void> seedChar(String id, String name) async {
      await CharacterRepository(db).save(
        Character(
          id: id,
          name: name,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      );
    }

    test('群聊轮换：A 之后 B 发言，消息带 speaker', () async {
      await seedChar('a', '角色A');
      await seedChar('b', '角色B');
      final conv = await chatRepo.createGroupConversation(
        apiProfileId: 'p1',
        characterIds: ['a', 'b'],
      );
      controller.bindConversation(conv.id);
      api.responses = [text('from A'), text('from B')];

      await controller.send('hi');
      await controller.send('again');

      final assistants = await assistantMessages();
      expect(assistants.map((m) => m.speakerCharacterId), ['a', 'b']);
    });

    test('群聊历史把其他角色发言转成带名字的 user', () async {
      await seedChar('a', '角色A');
      await seedChar('b', '角色B');
      final conv = await chatRepo.createGroupConversation(
        apiProfileId: 'p1',
        characterIds: ['a', 'b'],
      );
      controller.bindConversation(conv.id);
      api.responses = [text('from A'), text('from B'), text('from A again')];

      await controller.send('hi');
      await controller.send('again');
      await controller.send('third');

      final sent = api.sentMessages[1];
      expect(
        sent.any((m) => m.role == 'user' && m.content.contains('【角色A】')),
        isTrue,
      );
    });

    test('branchFromMessage 返回新会话并复制前缀', () async {
      final conv = await chatRepo.createConversation(
        apiProfileId: 'p1',
        characterId: 'a',
      );
      controller.bindConversation(conv.id);
      final u = await chatRepo.insertMessage(
        conversationId: conv.id,
        role: ChatRole.user,
        content: '起点',
      );
      final newId = await controller.branchFromMessage(u.id);
      expect(newId, isNotNull);
      final branch = await chatRepo.getConversation(newId!);
      expect(branch!.parentConversationId, conv.id);
      expect(branch.branchFromMessageId, u.id);
      final msgs = await chatRepo.watchMessages(newId).first;
      expect(msgs.map((m) => m.content), ['起点']);
    });
  });

}
