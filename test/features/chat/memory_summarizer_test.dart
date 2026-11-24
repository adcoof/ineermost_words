/// MemorySummarizer v2：阈值门、多会话聚合、游标、容忍标记、事实抽取、补跑。
library;

import 'dart:async';

import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:ai_roleplay_chat/features/characters/data/character_repository.dart';
import 'package:ai_roleplay_chat/features/characters/domain/character.dart';
import 'package:ai_roleplay_chat/features/chat/application/memory_summarizer.dart';
import 'package:ai_roleplay_chat/features/chat/data/chat_api_client.dart';
import 'package:ai_roleplay_chat/features/chat/data/chat_repository.dart';
import 'package:ai_roleplay_chat/features/chat/domain/models.dart';
import 'package:ai_roleplay_chat/features/settings/data/api_profile_repository.dart';
import 'package:ai_roleplay_chat/features/settings/domain/api_profile.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// 可控假客户端：记录调用与最后一次 messages，可失败/阻塞/按次给输出。
class _FakeApi implements ChatApiClient {
  static const String defaultOutput =
      '## 近期\n'
      '# 近况\n'
      '【01-01】记得：喜欢草莓\n'
      '## 新事实\n'
      '[2026-01-01] 用户喜欢草莓\n'
      '## 对用户的了解\n'
      '# 印象\n'
      '用户很爱聊天';

  /// 前 N 次调用抛错（补跑测试）。
  int failFirst = 0;

  /// 每次都抛错。
  bool throwAlways = false;

  /// 非空时第一次调用等 gate 完成再吐增量（并发测试用）。
  Completer<void>? gate;

  /// 覆盖输出。
  String? outputOverride;

  int calls = 0;
  List<ApiMessage>? lastMessages;

  @override
  Stream<ChatDelta> streamChat({
    required ApiProfile profile,
    required List<ApiMessage> messages,
    double? temperature,
    int? maxTokens,
    List<ApiTool>? tools,
    CancelToken? cancelToken,
  }) {
    calls++;
    lastMessages = messages;
    if (throwAlways || calls <= failFirst) throw StateError('boom');
    final out = outputOverride ?? defaultOutput;
    final g = gate;
    if (g != null && calls == 1) {
      return Stream.fromFuture(g.future)
          .asyncExpand((_) => Stream.value(ChatDelta(content: out)));
    }
    return Stream.value(ChatDelta(content: out));
  }

  @override
  Future<void> testConnection({
    required ApiProfile profile,
    CancelToken? cancelToken,
  }) async {}
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

  var seq = 0;

  /// 插入 [n] 条完成消息；[startHour]/[at] 控制时间先后。
  Future<void> insertDone(
    String convId,
    int n, {
    String tag = '第',
    int startHour = 0,
    String? imageSummary,
    DateTime? at,
  }) async {
    for (var i = 0; i < n; i++) {
      seq++;
      final last = i == n - 1 && imageSummary != null;
      await db.into(db.messages).insert(
        MessagesCompanion(
          id: Value('m${seq}_$convId'),
          conversationId: Value(convId),
          role: Value(i.isEven ? ChatRole.user.wire : ChatRole.assistant.wire),
          content: Value(last ? '' : '$tag$i句'),
          rawContent: Value(last ? '' : '$tag$i句'),
          imageSummary: Value(last ? imageSummary : ''),
          status: Value(MessageStatus.done.wire),
          createdAt: Value(
            at == null
                ? DateTime(2026, 1, 1, startHour, i)
                : at.add(Duration(minutes: i)),
          ),
        ),
      );
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
      apiProfileId: 'p1',
      characterId: 'ch1',
    );
    await insertDone(conv.id, kMemoryUpdateThreshold - 1);

    await summarizer.maybeUpdateMemory(
      conversationId: conv.id,
      characterId: 'ch1',
    );
    expect(api.calls, 0);
    expect((await characterRepo.getMemory('ch1')).summary, '');
    expect((await characterRepo.getMemory('ch1')).updatedAt, isNull);
  });

  test('达标：三段更新、事实入库、游标推进；提示词含旧记忆与会话名', () async {
    await newCharacter();
    final conv = await chatRepo.createConversation(
      apiProfileId: 'p1',
      characterId: 'ch1',
      title: '新会话',
    );
    await insertDone(conv.id, kMemoryUpdateThreshold);
    await characterRepo.setMemory(
      'ch1',
      summary: '用户叫小明',
      updatedAt: DateTime(2020),
    );

    await summarizer.maybeUpdateMemory(
      conversationId: conv.id,
      characterId: 'ch1',
    );

    expect(api.calls, 1);
    final memory = await characterRepo.getMemory('ch1');
    expect(memory.summary, contains('记得：喜欢草莓'));
    expect(memory.userSummary, contains('用户很爱聊天'));
    expect(memory.updatedAt!.isAfter(DateTime(2020)), isTrue);
    final facts = await characterRepo.getMemoryFacts('ch1');
    expect(facts, hasLength(1));
    expect(facts.single.fact, '用户喜欢草莓');
    expect(facts.single.occurredAt, DateTime(2026, 1, 1));
    expect(
      (await characterRepo.getMemoryCursors('ch1'))[conv.id],
      isNotNull,
    );

    final user = api.lastMessages!.last;
    expect(user.role, 'user');
    expect(user.content, contains('现有近期记忆'));
    expect(user.content, contains('用户叫小明'));
    expect(user.content, contains('现有对用户的了解'));
    expect(user.content, contains('【会话：新会话】'));
    expect(user.content, contains('【01-01】【用户】第0句'));
    expect(user.content, contains('【01-01】【星野雀】第1句'));
  });

  test('缺分隔标记：整段当近期记忆，画像保留旧值，游标推进', () async {
    await newCharacter();
    final conv = await chatRepo.createConversation(
      apiProfileId: 'p1',
      characterId: 'ch1',
    );
    await insertDone(conv.id, kMemoryUpdateThreshold);
    final stale = DateTime(2020);
    await characterRepo.setMemory(
      'ch1',
      summary: '旧记忆',
      userSummary: '旧画像',
      updatedAt: stale,
    );
    api.outputOverride = '只有记忆没有分隔';

    await summarizer.maybeUpdateMemory(
      conversationId: conv.id,
      characterId: 'ch1',
    );

    final memory = await characterRepo.getMemory('ch1');
    expect(memory.summary, '只有记忆没有分隔');
    expect(memory.userSummary, '旧画像');
    expect(memory.updatedAt!.isAfter(stale), isTrue);
  });

  test('模型返回英文拒绝：保留旧文档、不推进游标', () async {
    await newCharacter();
    final conv = await chatRepo.createConversation(
      apiProfileId: 'p1',
      characterId: 'ch1',
    );
    await insertDone(conv.id, kMemoryUpdateThreshold);
    final stale = DateTime(2020);
    await characterRepo.setMemory(
      'ch1',
      summary: '旧记忆',
      userSummary: '旧画像',
      updatedAt: stale,
    );
    api.outputOverride =
        'The request was rejected because it was considered high risk';

    await summarizer.maybeUpdateMemory(
      conversationId: conv.id,
      characterId: 'ch1',
    );

    final memory = await characterRepo.getMemory('ch1');
    expect(memory.summary, '旧记忆');
    expect(memory.userSummary, '旧画像');
    expect(memory.updatedAt, stale);
    expect(await characterRepo.getMemoryCursors('ch1'), isEmpty);
  });

  test('API 失败：保留旧文档与旧游标、补跑一次后不抛出', () async {
    await newCharacter();
    final conv = await chatRepo.createConversation(
      apiProfileId: 'p1',
      characterId: 'ch1',
    );
    await insertDone(conv.id, kMemoryUpdateThreshold);
    final stale = DateTime(2020);
    await characterRepo.setMemory('ch1', summary: '旧记忆', updatedAt: stale);
    api.throwAlways = true;
    summarizer = MemorySummarizer(
      chatRepo: chatRepo,
      characterRepo: characterRepo,
      profileRepo: ApiProfileRepository(db),
      api: api,
    );

    await expectLater(
      summarizer.maybeUpdateMemory(
        conversationId: conv.id,
        characterId: 'ch1',
      ),
      completes,
    );
    expect(api.calls, 2); // 首次 + 补跑一次
    final memory = await characterRepo.getMemory('ch1');
    expect(memory.summary, '旧记忆');
    expect(memory.updatedAt, stale);
    expect(await characterRepo.getMemoryCursors('ch1'), isEmpty);
  });

  test('首次失败、补跑成功：记忆正常更新', () async {
    await newCharacter();
    final conv = await chatRepo.createConversation(
      apiProfileId: 'p1',
      characterId: 'ch1',
    );
    await insertDone(conv.id, kMemoryUpdateThreshold);
    api.failFirst = 1;

    await summarizer.maybeUpdateMemory(
      conversationId: conv.id,
      characterId: 'ch1',
    );

    expect(api.calls, 2);
    expect(
      (await characterRepo.getMemory('ch1')).summary,
      contains('记得：喜欢草莓'),
    );
  });

  test('同角色并发：in-flight 期间第二次被挂起，不并发打 API', () async {
    await newCharacter();
    final conv = await chatRepo.createConversation(
      apiProfileId: 'p1',
      characterId: 'ch1',
    );
    await insertDone(conv.id, kMemoryUpdateThreshold);
    api.gate = Completer<void>();

    final first = summarizer.maybeUpdateMemory(
      conversationId: conv.id,
      characterId: 'ch1',
    );
    while (api.calls == 0) {
      await Future<void>.delayed(Duration.zero);
    }
    await summarizer.maybeUpdateMemory(
      conversationId: conv.id,
      characterId: 'ch1',
    );
    expect(api.calls, 1); // 第二次没有并发调用

    api.gate!.complete();
    await first;
    expect(
      (await characterRepo.getMemory('ch1')).summary,
      contains('喜欢草莓'),
    );
  });

  test('多会话：一次整理聚合两个会话，各自游标推进', () async {
    await newCharacter();
    final a = await chatRepo.createConversation(
      apiProfileId: 'p1',
      characterId: 'ch1',
      title: '旧会话',
    );
    final b = await chatRepo.createConversation(
      apiProfileId: 'p1',
      characterId: 'ch1',
      title: '新会话',
    );
    await insertDone(a.id, 3, tag: '旧A');
    await insertDone(b.id, 3, tag: '新B');
    await chatRepo.touchConversation(a.id);
    await chatRepo.touchConversation(b.id);

    await summarizer.maybeUpdateMemory(
      conversationId: b.id,
      characterId: 'ch1',
    );

    final prompt = api.lastMessages!.last.content;
    expect(prompt, contains('【会话：旧会话】'));
    expect(prompt, contains('【会话：新会话】'));
    expect(prompt, contains('旧A0句'));
    expect(prompt, contains('新B0句'));
    final cursors = await characterRepo.getMemoryCursors('ch1');
    expect(cursors[a.id], isNotNull);
    expect(cursors[b.id], isNotNull);
  });

  test('游标：第二次只看新消息，不重复旧对话', () async {
    await newCharacter();
    final conv = await chatRepo.createConversation(
      apiProfileId: 'p1',
      characterId: 'ch1',
      title: '主会话',
    );
    await insertDone(conv.id, 6, tag: '旧');
    await summarizer.maybeUpdateMemory(
      conversationId: conv.id,
      characterId: 'ch1',
    );
    await insertDone(
      conv.id,
      6,
      tag: '新',
      at: DateTime.now().add(const Duration(minutes: 1)),
    );

    await summarizer.maybeUpdateMemory(
      conversationId: conv.id,
      characterId: 'ch1',
    );

    final prompt = api.lastMessages!.last.content;
    expect(prompt, contains('新0句'));
    expect(prompt, isNot(contains('旧0句')));
  });

  test('纯图消息（content 空 + imageSummary）纳入摘要', () async {
    await newCharacter();
    final conv = await chatRepo.createConversation(
      apiProfileId: 'p1',
      characterId: 'ch1',
    );
    await insertDone(conv.id, 6, imageSummary: '一只橘猫趴在窗台');

    await summarizer.maybeUpdateMemory(
      conversationId: conv.id,
      characterId: 'ch1',
    );

    expect(api.lastMessages!.last.content, contains('[图片：一只橘猫趴在窗台]'));
  });

  test('事实去重：完全重复与高相似只保留一条', () async {
    await newCharacter();
    final conv = await chatRepo.createConversation(
      apiProfileId: 'p1',
      characterId: 'ch1',
    );
    await insertDone(conv.id, kMemoryUpdateThreshold);
    await characterRepo.addMemoryFact(
      characterId: 'ch1',
      fact: '用户喜欢草莓',
      occurredAt: DateTime(2026, 1, 1),
    );
    api.outputOverride =
        '## 近期\n【01-01】记得喜欢草莓\n'
        '## 新事实\n'
        '[2026-01-01] 用户喜欢草莓\n'
        '[2026-01-01] 用户喜欢草莓。\n'
        '[2026-01-01] 用户喜欢草莓呀\n'
        '## 对用户的了解\n用户很爱聊天';

    await summarizer.maybeUpdateMemory(
      conversationId: conv.id,
      characterId: 'ch1',
    );

    final facts = await characterRepo.getMemoryFacts('ch1');
    expect(facts, hasLength(1));
    expect(facts.single.fact, '用户喜欢草莓');
  });

  test('超长记忆按节丢弃，不劈开半句', () async {
    await newCharacter();
    final conv = await chatRepo.createConversation(
      apiProfileId: 'p1',
      characterId: 'ch1',
    );
    await insertDone(conv.id, kMemoryUpdateThreshold);
    final block = '一' * 420;
    api.outputOverride =
        '## 近期\n# 小节一\n$block。\n# 小节二\n$block。\n'
        '## 新事实\n[2026-01-01] 用户去关山游玩\n'
        '## 对用户的了解\n用户很爱聊天';

    await summarizer.maybeUpdateMemory(
      conversationId: conv.id,
      characterId: 'ch1',
    );

    final summary = (await characterRepo.getMemory('ch1')).summary;
    expect(summary.length, lessThanOrEqualTo(kMemorySummaryMaxChars));
    expect(summary, contains('小节一'));
    expect(summary, isNot(contains('小节二')));
    expect(summary.endsWith('。'), isTrue);
  });

  test('角色已删：直接返回，不调 API 不写库', () async {
    final conv = await chatRepo.createConversation(
      apiProfileId: 'p1',
      characterId: 'gone',
    );
    await insertDone(conv.id, kMemoryUpdateThreshold);
    await summarizer.maybeUpdateMemory(
      conversationId: conv.id,
      characterId: 'gone',
    );
    expect(api.calls, 0);
  });
}
