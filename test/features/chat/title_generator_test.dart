/// TitleGenerator：一次性触发（首条回复后）、清洗、失败零副作用。
library;

import 'dart:async';

import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:ai_roleplay_chat/features/chat/application/title_generator.dart';
import 'package:ai_roleplay_chat/features/chat/data/chat_api_client.dart';
import 'package:ai_roleplay_chat/features/chat/data/chat_repository.dart';
import 'package:ai_roleplay_chat/features/chat/domain/models.dart';
import 'package:ai_roleplay_chat/features/settings/data/api_profile_repository.dart';
import 'package:ai_roleplay_chat/features/settings/domain/api_profile.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// 可控假客户端：记录调用与最后一次 messages，可切换失败/自定义输出。
class _FakeApi implements ChatApiClient {
  final String output;
  final bool throwOnCall;

  /// true 时返回永不发事件的流（模拟 SSE 挂起）。
  final bool hang;

  int calls = 0;
  List<ApiMessage>? lastMessages;
  int? lastMaxTokens;

  _FakeApi({this.output = '湖边告白', this.throwOnCall = false, this.hang = false});

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
    lastMaxTokens = maxTokens;
    if (throwOnCall) throw StateError('boom');
    if (hang) return StreamController<ChatDelta>().stream;
    return Stream.value(ChatDelta(content: output));
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
  late _FakeApi api;
  late TitleGenerator generator;

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

  /// 插入一条消息（角色/状态可调）。
  Future<void> insertMsg(
    String convId,
    String id,
    ChatRole role,
    String content, {
    MessageStatus status = MessageStatus.done,
  }) async {
    await db
        .into(db.messages)
        .insert(
          MessagesCompanion(
            id: Value(id),
            conversationId: Value(convId),
            role: Value(role.wire),
            content: Value(content),
            rawContent: Value(content),
            status: Value(status.wire),
            createdAt: Value(DateTime(2026, 1, 1)),
          ),
        );
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    chatRepo = ChatRepository(db);
    await ApiProfileRepository(db).save(profile);
    api = _FakeApi();
    generator = TitleGenerator(
      chatRepo: chatRepo,
      profileRepo: ApiProfileRepository(db),
      api: api,
    );
  });

  tearDown(() => db.close());

  test('尚无回复：不调 API、标题不变', () async {
    final conv = await chatRepo.createConversation(
      apiProfileId: 'p1',
      title: '新会话',
    );
    await insertMsg(conv.id, 'u1', ChatRole.user, '我们去湖边吧');

    await generator.maybeRefine(conversationId: conv.id);
    expect(api.calls, 0);
    expect((await chatRepo.getConversation(conv.id))!.title, '新会话');
  });

  test('首条回复后：调用一次并写入精炼标题', () async {
    final conv = await chatRepo.createConversation(
      apiProfileId: 'p1',
      title: '我们去湖边吧',
    );
    await insertMsg(conv.id, 'u1', ChatRole.user, '我们去湖边吧，聊聊心事');
    await insertMsg(conv.id, 'a1', ChatRole.assistant, '好呀，湖边的风很舒服呢。');

    await generator.maybeRefine(conversationId: conv.id);
    expect(api.calls, 1);
    // 推理模型 reasoning_tokens 计入预算且推理长度随机（实测 28~130+），
    // 预算过小会在正文前 length 截断 → content 恒空 → 静默保留旧标题。
    expect(api.lastMaxTokens, greaterThanOrEqualTo(512));
    final title = (await chatRepo.getConversation(conv.id))!.title;
    expect(title, '湖边告白');
    // user prompt 同时含首条用户消息与回复。
    final user = api.lastMessages!.last;
    expect(user.content, contains('我们去湖边吧，聊聊心事'));
    expect(user.content, contains('湖边的风很舒服呢'));
  });

  test('角色开场白不计入：开场白 + 一条回复仍触发', () async {
    final conv = await chatRepo.createConversation(
      apiProfileId: 'p1',
      characterId: 'ch1',
      title: '星野雀',
    );
    await insertMsg(conv.id, 'a0', ChatRole.assistant, '（开场白）今天天气不错哦。');
    await insertMsg(conv.id, 'u1', ChatRole.user, '你好呀');
    await insertMsg(conv.id, 'a1', ChatRole.assistant, '你好你好！');

    await generator.maybeRefine(conversationId: conv.id);
    expect(api.calls, 1);
    expect((await chatRepo.getConversation(conv.id))!.title, '湖边告白');
  });

  test('多段首回复（多行 assistant）也触发：输入合并各段', () async {
    final conv = await chatRepo.createConversation(
      apiProfileId: 'p1',
      title: '旧标题',
    );
    await insertMsg(conv.id, 'u1', ChatRole.user, '我们去湖边吧');
    await insertMsg(conv.id, 'a1', ChatRole.assistant, '好呀。');
    await insertMsg(conv.id, 'a2', ChatRole.assistant, '湖边的风很舒服呢。');

    await generator.maybeRefine(conversationId: conv.id);
    expect(api.calls, 1);
    final user = api.lastMessages!.last;
    expect(user.content, contains('好呀。'));
    expect(user.content, contains('湖边的风很舒服呢'));
    expect((await chatRepo.getConversation(conv.id))!.title, '湖边告白');
  });

  test('第二条回复后不再触发（一次性）', () async {
    final conv = await chatRepo.createConversation(
      apiProfileId: 'p1',
      title: '旧标题',
    );
    await insertMsg(conv.id, 'u1', ChatRole.user, '第一问');
    await insertMsg(conv.id, 'a1', ChatRole.assistant, '第一答');
    await insertMsg(conv.id, 'u2', ChatRole.user, '第二问');
    await insertMsg(conv.id, 'a2', ChatRole.assistant, '第二答');

    await generator.maybeRefine(conversationId: conv.id);
    expect(api.calls, 0);
    expect((await chatRepo.getConversation(conv.id))!.title, '旧标题');
  });

  test('API 失败：不抛出、保留旧标题', () async {
    final conv = await chatRepo.createConversation(
      apiProfileId: 'p1',
      title: '旧标题',
    );
    await insertMsg(conv.id, 'u1', ChatRole.user, '问');
    await insertMsg(conv.id, 'a1', ChatRole.assistant, '答');
    api = _FakeApi(throwOnCall: true);
    generator = TitleGenerator(
      chatRepo: chatRepo,
      profileRepo: ApiProfileRepository(db),
      api: api,
    );

    await expectLater(
      generator.maybeRefine(conversationId: conv.id),
      completes,
    );
    expect((await chatRepo.getConversation(conv.id))!.title, '旧标题');
  });

  test('输出含引号与解释行：清洗后为纯标题', () async {
    final conv = await chatRepo.createConversation(
      apiProfileId: 'p1',
      title: '旧标题',
    );
    await insertMsg(conv.id, 'u1', ChatRole.user, '问');
    await insertMsg(conv.id, 'a1', ChatRole.assistant, '答');
    api = _FakeApi(output: '「晚安故事」\n这是解释行');
    generator = TitleGenerator(
      chatRepo: chatRepo,
      profileRepo: ApiProfileRepository(db),
      api: api,
    );

    await generator.maybeRefine(conversationId: conv.id);
    expect((await chatRepo.getConversation(conv.id))!.title, '晚安故事');
  });

  test('SSE 挂起：超时后保留旧标题，in-flight 不卡死', () async {
    final conv = await chatRepo.createConversation(
      apiProfileId: 'p1',
      title: '旧标题',
    );
    await insertMsg(conv.id, 'u1', ChatRole.user, '问');
    await insertMsg(conv.id, 'a1', ChatRole.assistant, '答');
    api = _FakeApi(hang: true);
    generator = TitleGenerator(
      chatRepo: chatRepo,
      profileRepo: ApiProfileRepository(db),
      api: api,
      streamTimeout: const Duration(milliseconds: 20),
    );

    await expectLater(
      generator.maybeRefine(conversationId: conv.id),
      completes,
    );
    expect((await chatRepo.getConversation(conv.id))!.title, '旧标题');
    // 超时必须释放 _inFlight：同一会话还能再次尝试（挂起态下再触发一次）。
    await generator.maybeRefine(conversationId: conv.id);
    expect(api.calls, 2);
  });
}
