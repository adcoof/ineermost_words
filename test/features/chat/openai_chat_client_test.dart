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

  _FakeAdapter(this.body, {this.statusCode = 200, this.contentType = 'text/event-stream'});

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
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
  });
}