/// 自定义音色仓库测试：CRUD + `custom:<id>` 解析为 voicedesign 请求。
library;

import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:ai_roleplay_chat/features/voice/data/custom_voice_repository.dart';
import 'package:ai_roleplay_chat/features/voice/data/resolving_tts_provider.dart';
import 'package:ai_roleplay_chat/features/voice/domain/tts_provider.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late CustomVoiceRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = CustomVoiceRepository(db);
  });

  tearDown(() => db.close());

  CustomVoice voice(
          {String id = 'v1',
          String name = '萝莉音',
          DateTime? createdAt}) =>
      CustomVoice(
        id: id,
        name: name,
        description: '软糯可爱的幼女声线，语调上扬',
        createdAt: createdAt ?? DateTime(2026, 10, 24),
        updatedAt: DateTime(2026, 10, 24),
      );

  group('CustomVoiceRepository', () {
    test('保存后可读回，listAll 按创建时间倒序', () async {
      await repo.save(voice(id: 'a', name: '早', createdAt: DateTime(2026, 1)));
      await repo.save(voice(id: 'b', name: '晚', createdAt: DateTime(2026, 9)));

      final all = await repo.listAll();
      expect(all, hasLength(2));
      expect(all.first.name, '晚');

      final got = await repo.getById('a');
      expect(got, isNotNull);
      expect(got!.name, '早');
      expect(got.description, '软糯可爱的幼女声线，语调上扬');
    });

    test('save 按 id upsert 并刷新 updatedAt', () async {
      // Drift dateTime() 按秒存时间戳，同秒两次 save 时间戳相同——
      // 故直接插旧时间戳作对照，验证 save 后 updatedAt 被刷新。
      final stale = DateTime(2020);
      await db.into(db.customVoices).insert(CustomVoicesCompanion(
            id: const Value('v1'),
            name: const Value('旧名'),
            description: const Value('软糯可爱的幼女声线，语调上扬'),
            createdAt: Value(stale),
            updatedAt: Value(stale),
          ));
      final before = (await repo.getById('v1'))!;

      // 与编辑页一致：二次保存沿用原 createdAt（save 会按入参写回）。
      await repo.save(voice(name: '新名', createdAt: stale));

      final all = await repo.listAll();
      expect(all, hasLength(1)); // upsert 不新增行
      final after = all.single;
      expect(after.name, '新名');
      expect(after.createdAt, before.createdAt); // createdAt 不变
      expect(after.updatedAt.isAfter(stale), isTrue); // updatedAt 已刷新
    });

    test('delete 后查不到', () async {
      await repo.save(voice());
      await repo.delete('v1');
      expect(await repo.getById('v1'), isNull);
      expect(await repo.listAll(), isEmpty);
    });

    test('watchAll 发出增删变化', () async {
      await repo.save(voice());
      final first = await repo.watchAll().first;
      expect(first, hasLength(1));

      await repo.delete('v1');
      final second = await repo.watchAll().first;
      expect(second, isEmpty);
    });
  });

  group('ResolvingTtsProvider.resolveCustomVoice', () {
    test('custom:<id> → voiceDesign 填描述、voiceId 复位', () async {
      await repo.save(voice(id: 'abc'));

      final resolved = await ResolvingTtsProvider.resolveCustomVoice(
        repo,
        const TtsRequest(text: 'hi', voiceId: 'custom:abc', speed: 1.2),
      );
      expect(resolved.voiceDesign, '软糯可爱的幼女声线，语调上扬');
      expect(resolved.voiceId, isEmpty);
      expect(resolved.text, 'hi');
      expect(resolved.speed, 1.2);
    });

    test('custom:<id> 已删除 → voiceDesign 空（按引擎默认音色处理）', () async {
      final resolved = await ResolvingTtsProvider.resolveCustomVoice(
        repo,
        const TtsRequest(text: 'hi', voiceId: 'custom:gone'),
      );
      expect(resolved.voiceDesign, isEmpty);
      expect(resolved.voiceId, isEmpty);
    });

    test('显式 voiceDesign（未保存试听）直接透传，不查库', () async {
      final resolved = await ResolvingTtsProvider.resolveCustomVoice(
        repo,
        const TtsRequest(text: 'hi', voiceId: 'custom:gone', voiceDesign: '磁性男声'),
      );
      expect(resolved.voiceDesign, '磁性男声');
    });

    test('普通 voiceId 不受影响', () async {
      const req = TtsRequest(text: 'hi', voiceId: '茉莉');
      final resolved = await ResolvingTtsProvider.resolveCustomVoice(repo, req);
      expect(resolved.voiceId, '茉莉');
      expect(resolved.voiceDesign, isEmpty);
    });
  });
}
