import 'dart:convert';
import 'dart:typed_data';

import 'package:ai_roleplay_chat/core/errors/app_exception.dart';
import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:ai_roleplay_chat/features/settings/data/api_profile_repository.dart';
import 'package:ai_roleplay_chat/features/settings/domain/api_profile.dart';
import 'package:ai_roleplay_chat/features/voice/data/mimo_asr_provider.dart';
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

/// 递归收集 [node] 内所有 Map 的键（用于「body 不得含 text 键」断言）。
Set<String> _findKeys(dynamic node) {
  final keys = <String>{};
  void walk(dynamic n) {
    if (n is Map) {
      n.forEach((k, v) {
        keys.add(k.toString());
        walk(v);
      });
    } else if (n is List) {
      for (final e in n) {
        walk(e);
      }
    }
  }

  walk(node);
  return keys;
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
  /// model 传空串走默认 mimo-v2.5-asr。
  MimoAsrProvider provider(
    _FakeAdapter adapter, {
    String baseUrl = 'https://example.com/v1',
  }) {
    final dio = Dio();
    dio.httpClientAdapter = adapter;
    return MimoAsrProvider(
      baseUrl: baseUrl,
      apiKey: 'sk-test',
      model: '',
      chatProfilesRepo: repo,
      dio: dio,
    );
  }

  group('MimoAsrProvider.transcribe', () {
    test('请求形状：model/input_audio/data-url/wav，且整个 body 无 text 键',
        () async {
      final adapter = _FakeAdapter(utf8.encode(jsonEncode({
        'choices': [
          {
            'message': {'content': '你好'}
          }
        ],
      })));
      final wav = [0x52, 0x49, 0x46, 0x46, 0x00, 0x01]; // 假 WAV 字节
      await provider(adapter).transcribe(wav);

      final req = adapter.lastRequest!;
      expect(req.uri.toString(), 'https://example.com/v1/chat/completions');
      final body = req.data as Map;
      expect(body['model'], 'mimo-v2.5-asr');
      final messages = body['messages'] as List;
      expect(messages, hasLength(1));
      expect(messages[0]['role'], 'user');
      final content = messages[0]['content'] as List;
      expect(content, hasLength(1));
      expect(content[0]['type'], 'input_audio');
      final inputAudio = content[0]['input_audio'] as Map;
      expect(inputAudio['data'], startsWith('data:audio/wav;base64,'));
      expect(inputAudio['data'], 'data:audio/wav;base64,${base64Encode(wav)}');
      expect(inputAudio['format'], 'wav');
      // 硬约束：content 数组里绝对不能有 text 片段，整个 body 不得含 text 键。
      expect(_findKeys(body), isNot(contains('text')));
      expect(jsonEncode(body), isNot(contains('"text"')));
    });

    test('content 为字符串时原样返回', () async {
      final adapter = _FakeAdapter(utf8.encode(jsonEncode({
        'choices': [
          {
            'message': {'content': '今天天气不错'}
          }
        ],
      })));
      expect(await provider(adapter).transcribe([0x00]), '今天天气不错');
    });

    test('content 为 [{"text":"a"},{"text":"b"}] 时拼接为 ab', () async {
      final adapter = _FakeAdapter(utf8.encode(jsonEncode({
        'choices': [
          {
            'message': {
              'content': [
                {'text': 'a'},
                {'text': 'b'},
              ]
            }
          }
        ],
      })));
      expect(await provider(adapter).transcribe([0x00]), 'ab');
    });

    test('401 转 AuthException', () async {
      final adapter = _FakeAdapter(
        utf8.encode('{"error":{"message":"bad key"}}'),
        statusCode: 401,
      );
      await expectLater(
        provider(adapter).transcribe([0x00]),
        throwsA(isA<AuthException>()),
      );
    });

    test('400 且带 error.message 转 ServerException（含服务端文案）', () async {
      final adapter = _FakeAdapter(
        utf8.encode('{"error":{"message":"audio too short"}}'),
        statusCode: 400,
      );
      await expectLater(
        provider(adapter).transcribe([0x00]),
        throwsA(isA<ServerException>()
            .having((e) => e.message, 'message', contains('audio too short'))),
      );
    });
  });

  group('MimoAsrProvider 构造与 canUse', () {
    test('构造不实例化录音器（懒加载，测试环境无平台通道不炸）', () {
      expect(() => provider(_FakeAdapter([])), returnsNormally);
    });

    test('canUse：专用 baseUrl 非空即可用', () async {
      expect(await provider(_FakeAdapter([])).canUse(), isTrue);
    });

    test('canUse：baseUrl 为空时回落到默认聊天配置', () async {
      final p = provider(_FakeAdapter([]), baseUrl: '');
      // 空库：无默认聊天配置，不可用。
      expect(await p.canUse(), isFalse);
      await repo.save(const ApiProfile(
        id: 'c1',
        name: 'chat',
        baseUrl: 'https://token-plan-cn.xiaomimimo.com/v1',
        apiKey: 'sk-test',
        model: 'm',
        temperature: 1.0,
        extraHeaders: '{}',
        isDefault: true,
      ));
      // 有默认聊天配置：可用。
      expect(await p.canUse(), isTrue);
    });
  });

  group('ASR 独立配置（customConfigGet 注入）', () {
    /// 构造带独立配置回调的被测对象（模拟语音界面「独立配置」档）。
    MimoAsrProvider customProvider(
      _FakeAdapter adapter, {
      ({String baseUrl, String apiKey, String model})? config,
    }) {
      final dio = Dio();
      dio.httpClientAdapter = adapter;
      return MimoAsrProvider(
        baseUrl: '',
        apiKey: '',
        model: '',
        chatProfilesRepo: repo,
        customConfigGet: () async => config,
        dio: dio,
      );
    }

    test('独立配置非空：优先于聊天配置，canUse 为真，模型名用配置值', () async {
      // 只有独立配置，没有任何聊天配置。
      final p = customProvider(_FakeAdapter([]), config: (
        baseUrl: 'https://voice.example.com/v1',
        apiKey: 'sk-voice',
        model: 'my-asr-1',
      ));
      expect(await p.canUse(), isTrue);

      // 转写请求应打到独立配置的地址，带独立 Key 与模型名。
      final adapter = _FakeAdapter(utf8.encode(jsonEncode({
        'choices': [
          {
            'message': {'content': 'hi'}
          }
        ],
      })));
      await customProvider(adapter, config: (
        baseUrl: 'https://voice.example.com/v1',
        apiKey: 'sk-voice',
        model: 'my-asr-1',
      )).transcribe([0x00]);
      final req = adapter.lastRequest!;
      expect(req.uri.toString(), 'https://voice.example.com/v1/chat/completions');
      expect(_header(req, 'authorization'), 'Bearer sk-voice');
      expect((req.data as Map)['model'], 'my-asr-1');
    });

    test('独立配置为空：回落聊天配置；两者皆无：canUse 为假', () async {
      final p = customProvider(_FakeAdapter([]));
      expect(await p.canUse(), isFalse);

      await repo.save(const ApiProfile(
        id: 'c1',
        name: 'chat',
        baseUrl: 'https://chat.example.com/v1',
        apiKey: 'sk-chat',
        model: 'm',
        temperature: 1.0,
        extraHeaders: '{}',
        isDefault: true,
      ));
      expect(await p.canUse(), isTrue);
      final adapter = _FakeAdapter(utf8.encode(jsonEncode({
        'choices': [
          {
            'message': {'content': 'hi'}
          }
        ],
      })));
      await customProvider(adapter).transcribe([0x00]);
      expect(adapter.lastRequest!.uri.toString(),
          'https://chat.example.com/v1/chat/completions');
      // 聊天回落档不拿聊天模型名当 ASR 模型。
      expect((adapter.lastRequest!.data as Map)['model'], 'mimo-v2.5-asr');
    });
  });
}

/// 取请求头（大小写不敏感），缺省空串。
String _header(RequestOptions o, String name) {
  for (final e in o.headers.entries) {
    if (e.key.toLowerCase() == name.toLowerCase()) return e.value.toString();
  }
  return '';
}
