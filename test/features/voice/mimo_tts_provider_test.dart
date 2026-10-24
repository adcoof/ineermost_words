import 'dart:convert';
import 'dart:typed_data';

import 'package:ai_roleplay_chat/core/errors/app_exception.dart';
import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:ai_roleplay_chat/features/settings/data/api_profile_repository.dart';
import 'package:ai_roleplay_chat/features/voice/data/mimo_tts_provider.dart';
import 'package:ai_roleplay_chat/features/voice/domain/tts_provider.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// 返回固定字节流的假 HTTP 适配器，并记录最近一次请求。
class _FakeAdapter implements HttpClientAdapter {
  final int statusCode;
  final List<int> body;
  RequestOptions? lastRequest;

  _FakeAdapter(this.body, {this.statusCode = 200});

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromBytes(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

/// 取请求头（大小写不敏感），缺省空串。
String _header(RequestOptions o, String name) {
  for (final e in o.headers.entries) {
    if (e.key.toLowerCase() == name.toLowerCase()) return e.value.toString();
  }
  return '';
}

void main() {
  late AppDatabase db;
  late ApiProfileRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ApiProfileRepository(db);
  });

  tearDown(() => db.close());

  /// 构造被测对象；全程只用假 Key（sk-test），不触碰真实凭据。
  MimoTtsProvider provider(_FakeAdapter adapter) {
    final dio = Dio();
    dio.httpClientAdapter = adapter;
    return MimoTtsProvider(
      baseUrl: 'https://example.com/v1',
      apiKey: 'sk-test',
      model: 'mimo-v2.5-tts',
      chatProfilesRepo: repo,
      dio: dio,
    );
  }

  group('MimoTtsProvider.synthesize', () {
    test('请求形状：URL/model/messages/audio/鉴权头，voice 缺省 mimo_default',
        () async {
      final adapter = _FakeAdapter(utf8.encode(jsonEncode({
        'choices': [
          {
            'message': {
              'audio': {'data': base64Encode([1, 2, 3])}
            }
          }
        ],
      })));
      await provider(adapter).synthesize(const TtsRequest(text: '你好，世界'));

      final req = adapter.lastRequest!;
      expect(req.uri.toString(), 'https://example.com/v1/chat/completions');
      final body = req.data as Map;
      expect(body['model'], 'mimo-v2.5-tts');
      final messages = body['messages'] as List;
      expect(messages[0]['role'], 'user');
      // user 消息是风格描述：非空，且等于 styleFor(speed)。
      expect(messages[0]['content'], MimoTtsProvider.styleFor(1.0));
      expect((messages[0]['content'] as String), isNotEmpty);
      expect(messages[1]['role'], 'assistant');
      expect(messages[1]['content'], '你好，世界');
      final audio = body['audio'] as Map;
      expect(audio['format'], 'mp3');
      expect(audio['voice'], 'mimo_default');
      expect(_header(req, 'authorization'), 'Bearer sk-test');
    });

    test('显式 voiceId 透传', () async {
      final adapter = _FakeAdapter(utf8.encode(jsonEncode({
        'choices': [
          {
            'message': {
              'audio': {'data': base64Encode([1])}
            }
          }
        ],
      })));
      await provider(adapter)
          .synthesize(const TtsRequest(text: 'hi', voiceId: '茉莉'));

      final body = adapter.lastRequest!.data as Map;
      expect((body['audio'] as Map)['voice'], '茉莉');
    });

    test('audio.data base64 解码为 bytes，mimeType=mp3', () async {
      final bytes = [0x49, 0x44, 0x33, 0x00, 0xff, 0x10];
      final adapter = _FakeAdapter(utf8.encode(jsonEncode({
        'choices': [
          {
            'message': {
              'audio': {'data': base64Encode(bytes)}
            }
          }
        ],
      })));

      final audio =
          await provider(adapter).synthesize(const TtsRequest(text: 'x'));
      expect(audio.mimeType, 'mp3');
      expect(audio.bytes, bytes);
    });

    test('401 转 AuthException', () async {
      final adapter = _FakeAdapter(
        utf8.encode('{"error":{"message":"bad key"}}'),
        statusCode: 401,
      );
      await expectLater(
        provider(adapter).synthesize(const TtsRequest(text: 'x')),
        throwsA(isA<AuthException>()),
      );
    });

    test('400 且带 error.message 转 ServerException（含服务端文案）', () async {
      final adapter = _FakeAdapter(
        utf8.encode('{"error":{"message":"voice not found"}}'),
        statusCode: 400,
      );
      await expectLater(
        provider(adapter).synthesize(const TtsRequest(text: 'x')),
        throwsA(isA<ServerException>()
            .having((e) => e.message, 'message', contains('voice not found'))),
      );
    });

    test('200 缺 audio.data 转 ServerException', () async {
      final adapter =
          _FakeAdapter(utf8.encode('{"choices":[{"message":{"content":"x"}}]}'));
      await expectLater(
        provider(adapter).synthesize(const TtsRequest(text: 'x')),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('MimoTtsProvider.styleFor', () {
    test('0.6/0.95/1.15/1.5 四档风格提示', () {
      // 0.6→较慢档；0.95→中性档（无快慢修饰，仅基础语气）；
      // 1.15→稍快档；1.5→较快档。
      final slow = MimoTtsProvider.styleFor(0.6);
      final mid = MimoTtsProvider.styleFor(0.95);
      final slightlyFast = MimoTtsProvider.styleFor(1.15);
      final fast = MimoTtsProvider.styleFor(1.5);

      expect(slow, isNotEmpty);
      expect(slow, contains('语速较慢'));
      expect(mid, isNotEmpty);
      expect(mid, contains('自然、友好、清晰的对话语气'));
      expect(slightlyFast, isNotEmpty);
      expect(slightlyFast, contains('语速稍快'));
      expect(fast, isNotEmpty);
      expect(fast, contains('语速较快'));
    });
  });

  group('MimoTtsProvider 音色设计（voiceDesign）', () {
    test('voiceDesign 非空：model=voicedesign，user=描述，audio 无 voice',
        () async {
      final adapter = _FakeAdapter(utf8.encode(jsonEncode({
        'choices': [
          {
            'message': {
              'audio': {'data': base64Encode([1, 2])}
            }
          }
        ],
      })));
      await provider(adapter).synthesize(const TtsRequest(
        text: '你好呀',
        voiceDesign: '温柔甜美的年轻女声',
        voiceId: '茉莉', // 应被忽略：设计模式不带 voice 参数
      ));

      final body = adapter.lastRequest!.data as Map;
      expect(body['model'], 'mimo-v2.5-tts-voicedesign');
      final messages = body['messages'] as List;
      expect(messages[0]['role'], 'user');
      // 中性语速（1.0）时描述原样传递，不加语速提示。
      expect(messages[0]['content'], '温柔甜美的年轻女声');
      expect(messages[1]['role'], 'assistant');
      expect(messages[1]['content'], '你好呀');
      final audio = body['audio'] as Map;
      expect(audio['format'], 'mp3');
      expect(audio.containsKey('voice'), isFalse);
    });

    test('voiceDesign + 语速：描述后追加语速提示', () async {
      final adapter = _FakeAdapter(utf8.encode(jsonEncode({
        'choices': [
          {
            'message': {
              'audio': {'data': base64Encode([1])}
            }
          }
        ],
      })));
      await provider(adapter).synthesize(const TtsRequest(
          text: 'x', voiceDesign: '低沉的男声', speed: 1.5));

      final body = adapter.lastRequest!.data as Map;
      final content = (body['messages'] as List)[0]['content'] as String;
      expect(content, contains('低沉的男声'));
      expect(content, contains('语速较快'));
    });

    test('designFor：档位与 styleFor 一致，1.0/0.95 中性不加提示', () {
      expect(MimoTtsProvider.designFor('清亮少年音', 1.0), '清亮少年音');
      expect(MimoTtsProvider.designFor('清亮少年音', 0.95), '清亮少年音');
      expect(MimoTtsProvider.designFor('清亮少年音', 0.6), contains('语速较慢'));
      expect(MimoTtsProvider.designFor('清亮少年音', 0.9), contains('语速稍慢'));
      expect(MimoTtsProvider.designFor('清亮少年音', 1.15), contains('语速稍快'));
      expect(MimoTtsProvider.designFor('清亮少年音', 1.5), contains('语速较快'));
    });
  });
}
