/// TtsProfileRepository：ASR 引擎档位与独立配置 KV。
library;

import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:ai_roleplay_chat/features/voice/data/tts_profile_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TtsProfileRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = TtsProfileRepository(db);
  });

  tearDown(() => db.close());

  test('asrEngine 缺省 mimo，setAsrEngine 往返（含 custom 档）', () async {
    expect(await repo.asrEngine(), 'mimo');
    await repo.setAsrEngine('custom');
    expect(await repo.asrEngine(), 'custom');
    await repo.setAsrEngine('system');
    expect(await repo.asrEngine(), 'system');
  });

  test('TTS/ASR 语音 API 供应商 id 缺省为空，可独立设置', () async {
    expect(await repo.ttsApiProfileId(), isEmpty);
    expect(await repo.asrApiProfileId(), isEmpty);

    await repo.setTtsApiProfileId('p-mimo');
    await repo.setAsrApiProfileId('p-mimo');
    expect(await repo.ttsApiProfileId(), 'p-mimo');
    expect(await repo.asrApiProfileId(), 'p-mimo');

    await repo.setTtsApiProfileId('p-deepseek');
    expect(await repo.ttsApiProfileId(), 'p-deepseek');
    expect(await repo.asrApiProfileId(), 'p-mimo');

    await repo.setTtsApiProfileId(' ');
    await repo.setAsrApiProfileId(' ');
    expect(await repo.ttsApiProfileId(), isEmpty);
    expect(await repo.asrApiProfileId(), isEmpty);
  });

  test('asrCustomConfig 缺省全空，setAsrCustomConfig 往返与覆盖', () async {
    final empty = await repo.asrCustomConfig();
    expect(empty.baseUrl, isEmpty);
    expect(empty.apiKey, isEmpty);
    expect(empty.model, isEmpty);

    await repo.setAsrCustomConfig(
      baseUrl: 'https://asr.example.com/v1',
      apiKey: 'sk-asr',
      model: 'my-asr',
    );
    final c = await repo.asrCustomConfig();
    expect(c.baseUrl, 'https://asr.example.com/v1');
    expect(c.apiKey, 'sk-asr');
    expect(c.model, 'my-asr');

    await repo.setAsrCustomConfig(baseUrl: ' ', apiKey: ' ', model: ' ');
    final cleared = await repo.asrCustomConfig();
    expect(cleared.baseUrl, isEmpty);
    expect(cleared.apiKey, isEmpty);
    expect(cleared.model, isEmpty);
  });
}
