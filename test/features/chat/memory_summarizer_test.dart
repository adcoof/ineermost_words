/// MemorySummarizer：阈值门、成功更新、失败零副作用、并发跳过。
library;

import 'dart:async';

import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:ai_roleplay_chat/features/chat/application/memory_summarizer.dart';
import 'package:ai_roleplay_chat/features/chat/data/chat_api_client.dart';
import 'package:ai_roleplay_chat/features/chat/data/chat_repository.dart';
import 'package:ai_roleplay_chat/features/chat/domain/models.dart';
import 'package:ai_roleplay_chat/features/characters/data/character_repository.dart';
import 'package:ai_roleplay_chat/features/characters/domain/character.dart';
import 'package:ai_roleplay_chat/features/settings/data/api_profile_repository.dart';
import 'package:ai_roleplay_chat/features/settings/domain/api_profile.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// 可控假客户端：记录调用与最后一次 messages，可切换失败/阻塞。
class _FakeApi implements ChatApiClient {
  static const String _output = '记得：喜欢草莓';

  final bool throwOnCall;

  /// 非空时等 gate 完成再吐增量（并发测试用）。
  Completer<void>? gate;

  int calls = 0;
  List<ApiMessage>? lastMessages;

  _FakeApi({this.throwOnCall = false});

  @override
  Stream<ChatDelta> streamChat({
    required ApiProfile profile,
    required List<ApiMessage> messages,
    double? temperature,
    int? maxTokens,
    CancelToken? cancelToken,
  }) {
    calls++;
    lastMessages = messages;
    if (throwOnCall) throw StateError('boom');
    final g = gate;
    if (g != null) {
      return Stream.fromFuture(g.future)
          .asyncExpand((_) => Stream.value(ChatDelta(content: _output)));
    }
    return Stream.value(ChatDelta(content: _output));
  }

  @override
  Future<void> testConnection(
      {required ApiProfile profile, CancelToken? cancelToken}) async {}
}

void main() {
  late AppDatabase db;
  late ChatRepository chatRepo;
  late CharacterRepository characterRepo;
  late _FakeApi api;
  late MemorySummarizer summarizer;

  const profile = ApiProfile(
    id: 'p1',
    name: '测试',
    baseUrl: 'https://example.com/v1',
    apiKey: 'sk-test',
    model: 'm1',
    temperature: 1.0,
    extraHeaders: '{}',
    isDefault: true,
  );

  Future<Character> newCharacter() async {
    final c = Character(
      id: 'ch1',
      name: '星野雀',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    await characterRepo.save(c);
    return c;
  }

  /// 插入 [n] 条完成消息（时序递增）。
  Future<void> insertDone(String convId, int n) async {
    for (var i = 0; i < n; i++) {
      await db.into(db.messages).insert(MessagesCompanion(
            id: Value('m$i'),
            conversationId: Value(convId),
            role: Value(i.isEven ? ChatRole.user.wire : ChatRole.assistant.wire),
            content: Value('第$i句'),
            rawContent: Value('第$i句'),
            status: Value(MessageStatus.done.wire),
            createdAt: Value(DateTime(2026, 1, 1, 0, i)),
          ));
    }
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    chatRepo = ChatRepository(db);
    characterRepo = CharacterRepository(db);
    await ApiProfileRepository(db).save(profile);
    api = _FakeApi();
    summarizer = MemorySummarizer(
      chatRepo: chatRepo,
      characterRepo: characterRepo,
      profileRepo: ApiProfileRepository(db),
      api: api,
    );
  });

  tearDown(() => db.close());

  test('阈值门：不足 6 条不调 API', () async {
    await newCharacter();
    final conv = await chatRepo.createConversation(
        apiProfileId: 'p1', characterId: 'ch1');
    await insertDone(conv.id, kMemoryUpdateThreshold - 1);

    await summarizer.maybeUpdateMemory(
        conversationId: conv.id, characterId: 'ch1');
    expect(api.calls, 0);
    expect((await characterRepo.getMemory('ch1')).summary, '');
    expect((await characterRepo.getMemory('ch1')).updatedAt, isNull);
  });

  test('达标：更新 summary 并推进水位线；提示词含旧记忆与对话', () async {
    await newCharacter();
    final conv = await chatRepo.createConversation(
        apiProfileId: 'p1', characterId: 'ch1');
    await insertDone(conv.id, kMemoryUpdateThreshold);
    await characterRepo.setMemory('ch1',
        summary: '用户叫小明', updatedAt: DateTime(2020));

    await summarizer.maybeUpdateMemory(
        conversationId: conv.id, characterId: 'ch1');

    expect(api.calls, 1);
    final memory = await characterRepo.getMemory('ch1');
    expect(memory.summary, '记得：喜欢草莓');
    expect(memory.updatedAt!.isAfter(DateTime(2020)), isTrue);
    // 提示词：system 是整理器指令，user 含旧记忆 + 新对话行。
    final user = api.lastMessages!.last;
    expect(user.role, 'user');
    expect(user.content, contains('用户叫小明'));
    expect(user.content, contains('第0句'));
    expect(user.content, contains('星野雀：第1句'));
  });

  test('API 失败：旧记忆保留、水位线不推进、不抛出', () async {
    await newCharacter();
    final conv = await chatRepo.createConversation(
        apiProfileId: 'p1', characterId: 'ch1');
    await insertDone(conv.id, kMemoryUpdateThreshold);
    final stale = DateTime(2020);
    await characterRepo.setMemory('ch1', summary: '旧记忆', updatedAt: stale);
    api = _FakeApi(throwOnCall: true);
    summarizer = MemorySummarizer(
      chatRepo: chatRepo,
      characterRepo: characterRepo,
      profileRepo: ApiProfileRepository(db),
      api: api,
    );

    await expectLater(
      summarizer.maybeUpdateMemory(conversationId: conv.id, characterId: 'ch1'),
      completes,
    );
    final memory = await characterRepo.getMemory('ch1');
    expect(memory.summary, '旧记忆');
    expect(memory.updatedAt, stale);
  });

  test('同角色并发：第二次调用被 in-flight 跳过', () async {
    await newCharacter();
    final conv = await chatRepo.createConversation(
        apiProfileId: 'p1', characterId: 'ch1');
    await insertDone(conv.id, kMemoryUpdateThreshold);
    api.gate = Completer<void>();

    final first = summarizer.maybeUpdateMemory(
        conversationId: conv.id, characterId: 'ch1');
    // 等第一次真正进入 API 调用。
    while (api.calls == 0) {
      await Future<void>.delayed(Duration.zero);
    }
    await summarizer.maybeUpdateMemory(
        conversationId: conv.id, characterId: 'ch1');
    expect(api.calls, 1); // 第二次被跳过

    api.gate!.complete();
    await first;
    expect((await characterRepo.getMemory('ch1')).summary, '记得：喜欢草莓');
  });

  test('角色已删：直接返回，不调 API 不写库', () async {
    final conv = await chatRepo.createConversation(
        apiProfileId: 'p1', characterId: 'gone');
    await insertDone(conv.id, kMemoryUpdateThreshold);
    await summarizer.maybeUpdateMemory(
        conversationId: conv.id, characterId: 'gone');
    expect(api.calls, 0);
  });
}
