import 'dart:convert';
import 'dart:typed_data';

import 'package:ai_roleplay_chat/core/errors/app_exception.dart';
import 'package:ai_roleplay_chat/features/chat/data/chat_api_client.dart';
import 'package:ai_roleplay_chat/features/settings/domain/api_profile.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// 返回固定字节流的假 HTTP 适配器。
class _FakeAdapter implements HttpClientAdapter {
  final int statusCode;
  final List<int> body;
  final String contentType;

  /// 最近一次请求的 JSON body（用于 wire 形状断言）。
  Map<String, dynamic>? lastRequestJson;

  _FakeAdapter(this.body, {this.statusCode = 200, this.contentType = 'text/event-stream'});

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (requestStream != null) {
      final builder = BytesBuilder(copy: false);
      await for (final chunk in requestStream) {
        builder.add(chunk);
      }
      lastRequestJson =
          jsonDecode(utf8.decode(builder.takeBytes())) as Map<String, dynamic>;
    }
    return ResponseBody.fromBytes(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [contentType],
      },
    );
  }
}

ApiProfile _profile({String extraHeaders = '{}'}) => ApiProfile(
      id: 'p1',
      name: 'test',
      baseUrl: 'https://example.com/v1/',
      apiKey: 'sk-test',
      model: 'test-model',
      temperature: 0.7,
      extraHeaders: extraHeaders,
      isDefault: true,
    );

OpenAiChatApiClient _clientWith(_FakeAdapter adapter) {
  final dio = Dio();
  dio.httpClientAdapter = adapter;
  return OpenAiChatApiClient(dio: dio);
}

void main() {
  group('ApiMessage.toJson', () {
    test('无图：content 为字符串，与旧 wire 形状逐字节一致', () {
      const m = ApiMessage(role: 'user', content: 'hi');
      expect(m.toJson(), {'role': 'user', 'content': 'hi'});
    });

    test('文+图：text + image_url parts，dataUrl 带 jpeg 前缀', () {
      final m = ApiMessage(
        role: 'user',
        content: '看这张图',
        images: [ApiImage(bytes: Uint8List.fromList([1, 2, 3]))],
      );
      final parts = m.toJson()['content'] as List;
      expect(parts, hasLength(2));
      expect(parts[0], {'type': 'text', 'text': '看这张图'});
      final img = parts[1] as Map<String, dynamic>;
      expect(img['type'], 'image_url');
      expect(img['image_url'], {
        'url': 'data:image/jpeg;base64,${base64Encode([1, 2, 3])}',
      });
    });

    test('空文本+仅图：只有 image_url parts，无空 text part', () {
      final m = ApiMessage(
        role: 'user',
        content: '',
        images: [
          ApiImage(bytes: Uint8List.fromList([1])),
          ApiImage(bytes: Uint8List.fromList([2])),
        ],
      );
      final parts = m.toJson()['content'] as List;
      expect(parts, hasLength(2));
      expect(parts.every((p) => (p as Map)['type'] == 'image_url'), isTrue);
    });

    test('const 构造不破：ApiMessage 默认无图', () {
      // memory_summarizer / testConnection 的 const 构造依赖默认 images=[]。
      const m = ApiMessage(role: 'system', content: 'x');
      expect(m.images, isEmpty);
      expect(m.toJson()['content'], 'x');
    });
  });

  group('OpenAiChatApiClient.completionsUrl', () {
    test('容忍尾斜杠', () {
      expect(OpenAiChatApiClient.completionsUrl('https://a.com/v1/'),
          'https://a.com/v1/chat/completions');
      expect(OpenAiChatApiClient.completionsUrl('https://a.com/v1'),
          'https://a.com/v1/chat/completions');
    });
  });

  group('OpenAiChatApiClient.streamChat', () {
    test('解析增量与 [DONE]', () async {
      const raw = 'data: {"choices":[{"delta":{"content":"你"}}]}\n\n'
          'data: {"choices":[{"delta":{"content":"好"}}]}\n\n'
          'data: {"choices":[{"delta":{},"finish_reason":"stop"}]}\n\n'
          'data: [DONE]\n\n';
      final client = _clientWith(_FakeAdapter(utf8.encode(raw)));

      final deltas = await client
          .streamChat(
            profile: _profile(),
            messages: const [ApiMessage(role: 'user', content: 'hi')],
          )
          .toList();

      expect(deltas.map((d) => d.content).whereType<String>().join(), '你好');
      expect(deltas.last.finishReason, 'stop');
    });

    test('兼容 message.content 兜底', () async {
      const raw = 'data: {"choices":[{"message":{"content":"hello"}}]}\n\n'
          'data: [DONE]\n\n';
      final client = _clientWith(_FakeAdapter(utf8.encode(raw)));
      final deltas = await client
          .streamChat(
            profile: _profile(),
            messages: const [ApiMessage(role: 'user', content: 'hi')],
          )
          .toList();
      expect(deltas.single.content, 'hello');
    });

    test('损坏帧被跳过不中断流', () async {
      const raw = 'data: {bad json\n\n'
          'data: {"choices":[{"delta":{"content":"ok"}}]}\n\n'
          'data: [DONE]\n\n';
      final client = _clientWith(_FakeAdapter(utf8.encode(raw)));
      final deltas = await client
          .streamChat(
            profile: _profile(),
            messages: const [ApiMessage(role: 'user', content: 'hi')],
          )
          .toList();
      expect(deltas.single.content, 'ok');
    });

    test('错误帧转 AuthException', () async {
      const raw = 'data: {"error":{"message":"Invalid API key","code":"invalid_api_key"}}\n\n';
      final client = _clientWith(_FakeAdapter(utf8.encode(raw)));
      expect(
        () => client
            .streamChat(
              profile: _profile(),
              messages: const [ApiMessage(role: 'user', content: 'hi')],
            )
            .toList(),
        throwsA(isA<AuthException>()),
      );
    });

    test('HTTP 401 转 AuthException', () async {
      final client = _clientWith(_FakeAdapter(
        utf8.encode('{"error":{"message":"bad key"}}'),
        statusCode: 401,
        contentType: 'application/json',
      ));
      expect(
        () => client
            .streamChat(
              profile: _profile(),
              messages: const [ApiMessage(role: 'user', content: 'hi')],
            )
            .toList(),
        throwsA(isA<AuthException>()),
      );
    });

    test('HTTP 429 转 RateLimitException', () async {
      final client = _clientWith(_FakeAdapter(
        utf8.encode('{"error":{"message":"rate limited"}}'),
        statusCode: 429,
        contentType: 'application/json',
      ));
      expect(
        () => client
            .streamChat(
              profile: _profile(),
              messages: const [ApiMessage(role: 'user', content: 'hi')],
            )
            .toList(),
        throwsA(isA<RateLimitException>()),
      );
    });

    test('请求体 wire 形状：无图字符串 / 带图 parts 数组', () async {
      const done = 'data: [DONE]\n\n';
      final adapter = _FakeAdapter(utf8.encode(done));
      final client = _clientWith(adapter);

      await client
          .streamChat(
            profile: _profile(),
            messages: [
              const ApiMessage(role: 'system', content: 'sys'),
              ApiMessage(
                role: 'user',
                content: '看图',
                images: [ApiImage(bytes: Uint8List.fromList([9, 9]))],
              ),
            ],
          )
          .toList();

      final msgs = adapter.lastRequestJson!['messages'] as List;
      // 无图消息走字符串 content（旧形状）。
      expect(msgs[0], {'role': 'system', 'content': 'sys'});
      // 带图消息走 parts 数组。
      final parts = (msgs[1] as Map<String, dynamic>)['content'] as List;
      expect(parts, hasLength(2));
      expect(parts[0], {'type': 'text', 'text': '看图'});
      expect((parts[1] as Map)['image_url'], {
        'url': 'data:image/jpeg;base64,${base64Encode([9, 9])}',
      });
    });
  });
}