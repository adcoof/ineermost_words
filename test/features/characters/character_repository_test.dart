import 'dart:convert';
import 'dart:typed_data';

import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:ai_roleplay_chat/features/characters/data/character_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late CharacterRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = CharacterRepository(db);
  });

  tearDown(() => db.close());

  group('CharacterRepository', () {
    test('blank + save + getById 往返', () async {
      final c = repo.blank().copyWith(name: '小雨', personality: '毒舌');
      await repo.save(c);
      final loaded = await repo.getById(c.id);
      expect(loaded, isNotNull);
      expect(loaded!.name, '小雨');
      expect(loaded.personality, '毒舌');
      expect(loaded.source, 'manual');
    });

    test('save 同 id 覆盖更新', () async {
      final c = repo.blank().copyWith(name: '旧名');
      await repo.save(c);
      await repo.save(c.copyWith(name: '新名'));
      final all = await repo.watchCharacters().first;
      expect(all.length, 1);
      expect(all.single.name, '新名');
    });

    test('JSON 卡导入：source=st_v2，字段映射', () async {
      final card = utf8.encode(jsonEncode({
        'spec': 'chara_card_v2',
        'data': {
          'name': '林小雨',
          'description': '银发',
          'personality': '冷淡',
          'scenario': '天台',
          'first_mes': '……你来干什么？',
          'mes_example': '{{user}}：你好',
        },
      }));
      final c = await repo.importFromBytes(Uint8List.fromList(card));
      expect(c.name, '林小雨');
      expect(c.source, 'st_v2');
      expect(c.firstMessage, contains('你来干什么'));
      final loaded = await repo.getById(c.id);
      expect(loaded!.exampleDialogue, contains('{{user}}'));
    });

    test('watchCharacters 按更新时间倒序', () async {
      final a = repo.blank().copyWith(name: 'A');
      await repo.save(a);
      final b = repo.blank().copyWith(name: 'B');
      await repo.save(b);
      // 再更新 A，使其排最前。
      await repo.save(a.copyWith(name: 'A2'));
      final all = await repo.watchCharacters().first;
      expect(all.first.name, 'A2');
      expect(all.last.name, 'B');
    });

    test('delete 移除记录', () async {
      final c = repo.blank().copyWith(name: '待删');
      await repo.save(c);
      await repo.delete(c.id);
      expect(await repo.getById(c.id), isNull);
    });
  });
}
