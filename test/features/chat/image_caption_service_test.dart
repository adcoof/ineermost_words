/// ImageCaptionService：成功写概括、失败零副作用、幂等/并发跳过。
library;

import 'dart:async';
import 'dart:io';

import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:ai_roleplay_chat/features/chat/application/image_caption_service.dart';
import 'package:ai_roleplay_chat/features/chat/data/chat_api_client.dart';
import 'package:ai_roleplay_chat/features/chat/data/chat_repository.dart';
import 'package:ai_roleplay_chat/features/chat/domain/models.dart';
import 'package:ai_roleplay_chat/features/settings/data/api_profile_repository.dart';
import 'package:ai_roleplay_chat/features/settings/domain/api_profile.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// 可控假客户端：记录调用与最后一次 messages，可切换失败/自定义输出/阻塞。
class _FakeApi implements ChatApiClient {
  final String output;
  final bool throwOnCall;

  /// 非空时等 gate 完成再吐增量（并发测试用）。
  Completer<void>? gate;

  /// true 时返回永不发事件的流（模拟 SSE 挂起）。
  final bool hang;

  int calls = 0;
  List<ApiMessage>? lastMessages;
  int? lastMaxTokens;

  _FakeApi({
    this.output = '窗台上的橘猫',
    this.throwOnCall = false,
    this.hang = false,
  });

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
    final g = gate;
    if (g != null) {
      return Stream.fromFuture(g.future)
          .asyncExpand((_) => Stream.value(ChatDelta(content: output)));
    }
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
  late ImageCaptionService service;
  late Directory tmp;
  late String convId;

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

  /// 写一张最小 JPEG 假图文件。
  Future<File> writeImage(String name) async {
    final f = File('${tmp.path}/$name.jpg');
    await f.writeAsBytes([0xFF, 0xD8, 0xFF, 0xD9]);
    return f;
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    chatRepo = ChatRepository(db);
    await ApiProfileRepository(db).save(profile);
    api = _FakeApi();
    service = ImageCaptionService(
      chatRepo: chatRepo,
      profileRepo: ApiProfileRepository(db),
      api: api,
    );
    tmp = await Directory.systemTemp.createTemp('caption_test');
    convId = (await chatRepo.createConversation(apiProfileId: 'p1')).id;
  });

  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  test('成功：写入 imageSummary；请求带 images parts 与描述指令', () async {
    final img = await writeImage('a');
    final msg = await chatRepo.insertMessage(
      id: 'msg1',
      conversationId: convId,
      role: ChatRole.user,
      content: '看这张图',
      imagePaths: [img.path],
    );

    await service.maybeCaption(messageId: msg.id);
    expect(api.calls, 1);
    // 推理模型 reasoning_tokens 计入预算且推理长度随机（实测 28~130+），
    // 多图概括正文也长，预算过小会截断概括。
    expect(api.lastMaxTokens, greaterThanOrEqualTo(512));
    expect((await chatRepo.getMessage(msg.id))!.imageSummary, '窗台上的橘猫');
    final user = api.lastMessages!.last;
    expect(user.role, 'user');
    expect(user.images, hasLength(1));
    expect(user.content, contains('请描述'));
  });

  test('多图：全部带上并概括', () async {
    final img1 = await writeImage('a');
    final img2 = await writeImage('b');
    final msg = await chatRepo.insertMessage(
      id: 'msg1',
      conversationId: convId,
      role: ChatRole.user,
      content: '',
      imagePaths: [img1.path, img2.path],
    );

    await service.maybeCaption(messageId: msg.id);
    expect(api.lastMessages!.last.images, hasLength(2));
    expect((await chatRepo.getMessage(msg.id))!.imageSummary, '窗台上的橘猫');
  });

  test('API 失败：imageSummary 保持空、不抛出', () async {
    final img = await writeImage('a');
    final msg = await chatRepo.insertMessage(
      id: 'msg1',
      conversationId: convId,
      role: ChatRole.user,
      content: '看这张图',
      imagePaths: [img.path],
    );
    api = _FakeApi(throwOnCall: true);
    service = ImageCaptionService(
      chatRepo: chatRepo,
      profileRepo: ApiProfileRepository(db),
      api: api,
    );

    await expectLater(service.maybeCaption(messageId: msg.id), completes);
    expect((await chatRepo.getMessage(msg.id))!.imageSummary, '');
  });

  test('空输出：imageSummary 保持空', () async {
    final img = await writeImage('a');
    final msg = await chatRepo.insertMessage(
      id: 'msg1',
      conversationId: convId,
      role: ChatRole.user,
      content: '看这张图',
      imagePaths: [img.path],
    );
    api = _FakeApi(output: '  ');
    service = ImageCaptionService(
      chatRepo: chatRepo,
      profileRepo: ApiProfileRepository(db),
      api: api,
    );
    await service.maybeCaption(messageId: msg.id);
    expect((await chatRepo.getMessage(msg.id))!.imageSummary, '');
  });

  test('已有概括：跳过不调 API', () async {
    final img = await writeImage('a');
    final msg = await chatRepo.insertMessage(
      id: 'msg1',
      conversationId: convId,
      role: ChatRole.user,
      content: '看这张图',
      imagePaths: [img.path],
      imageSummary: '已有概括',
    );
    await service.maybeCaption(messageId: msg.id);
    expect(api.calls, 0);
    expect((await chatRepo.getMessage(msg.id))!.imageSummary, '已有概括');
  });

  test('无图消息：跳过不调 API', () async {
    final msg = await chatRepo.insertMessage(
      id: 'msg1',
      conversationId: convId,
      role: ChatRole.user,
      content: '纯文本',
    );
    await service.maybeCaption(messageId: msg.id);
    expect(api.calls, 0);
  });

  test('SSE 挂起：超时后摘要留空、in-flight 不卡死', () async {
    final img = await writeImage('a');
    final msg = await chatRepo.insertMessage(
      id: 'msg1',
      conversationId: convId,
      role: ChatRole.user,
      content: '看这张图',
      imagePaths: [img.path],
    );
    api = _FakeApi(hang: true);
    service = ImageCaptionService(
      chatRepo: chatRepo,
      profileRepo: ApiProfileRepository(db),
      api: api,
      streamTimeout: const Duration(milliseconds: 20),
    );

    await expectLater(service.maybeCaption(messageId: msg.id), completes);
    expect((await chatRepo.getMessage(msg.id))!.imageSummary, '');
    // 超时必须释放 _inFlight：同一消息还能再次尝试。
    await service.maybeCaption(messageId: msg.id);
    expect(api.calls, 2);
  });

  test('并发：第二次调用被 in-flight 跳过', () async {
    final img = await writeImage('a');
    final msg = await chatRepo.insertMessage(
      id: 'msg1',
      conversationId: convId,
      role: ChatRole.user,
      content: '看这张图',
      imagePaths: [img.path],
    );
    api.gate = Completer<void>();

    final first = service.maybeCaption(messageId: msg.id);
    while (api.calls == 0) {
      await Future<void>.delayed(Duration.zero);
    }
    await service.maybeCaption(messageId: msg.id);
    expect(api.calls, 1); // 第二次被跳过

    api.gate!.complete();
    await first;
    expect((await chatRepo.getMessage(msg.id))!.imageSummary, '窗台上的橘猫');
  });
}
