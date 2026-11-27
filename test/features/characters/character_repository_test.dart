import 'dart:convert';
import 'dart:typed_data';

import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:ai_roleplay_chat/features/characters/data/character_repository.dart';
import 'package:ai_roleplay_chat/features/characters/data/lore_repository.dart';
import 'package:ai_roleplay_chat/features/characters/domain/character_extensions.dart';
import 'package:ai_roleplay_chat/features/characters/domain/character_profile.dart';
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

    test('alternateGreetings JSON 往返 + ST 导入', () async {
      final c = repo.blank().copyWith(
        name: '小雨',
        alternateGreetings: const ['第一句', '第二句'],
      );
      await repo.save(c);
      final loaded = await repo.getById(c.id);
      expect(loaded!.alternateGreetings, ['第一句', '第二句']);

      final imported = await repo.importFromBytes(
        Uint8List.fromList(
          utf8.encode(
            jsonEncode({
              'name': '阿雪',
              'first_mes': '主开场',
              'alternate_greetings': ['备用一', '备用二'],
            }),
          ),
        ),
      );
      expect(imported.alternateGreetings, ['备用一', '备用二']);
    });

    test('importCard 返回结果，档案/扩展/世界书原文全部落库', () async {
      final card = {
        'spec': 'chara_card_v3',
        'spec_version': '3.0',
        'data': {
          'name': '林小雨',
          'description': '银发',
          'first_mes': '……你来干什么？',
          'nickname': '小雨',
          'creator': '测试作者',
          'tags': ['校园'],
          'system_prompt': '保持冷淡',
          'unknown_field': '保留',
          'character_book': {
            'name': '世界观',
            'entries': [
              {
                'keys': ['天台'],
                'secondary_keys': ['夜'],
                'content': '天台的风很大',
                'extensions': {'x': 1},
              },
            ],
          },
        },
      };
      final result = await repo.importCard(
        Uint8List.fromList(utf8.encode(jsonEncode(card))),
      );

      expect(result.format, 'v3');
      expect(result.character.source, 'st_v3');
      expect(result.loreCount, 1);
      expect(result.preservedKeyCount, 1);
      expect(result.character.profile.basic.nickname, '小雨');
      expect(result.character.profile.creator.author, '测试作者');
      expect(result.character.profile.creator.tags, ['校园']);
      expect(result.character.profile.runConfig.systemPrompt, '保持冷淡');
      expect(result.character.extensions.unknownData['unknown_field'], '保留');
      expect(result.character.extensions.bookMeta['name'], '世界观');
      expect(result.warnings, contains('世界书 1 条待导入，默认禁用'));

      final lore =
          await LoreRepository(db).listForCharacter(result.character.id);
      expect(lore, hasLength(1));
      expect(lore.single.enabled, isFalse);
      expect(lore.single.keys, ['天台']);
      expect(lore.single.sourceJson, contains('secondary_keys'));
    });

    test('扁平卡 source=st_v1，旧入口仍返回 Character', () async {
      final c = await repo.importFromBytes(
        Uint8List.fromList(utf8.encode(jsonEncode({'name': '阿雪'}))),
      );
      expect(c.source, 'st_v1');
      expect(c.sourceLabel, 'SillyTavern 卡 · V1');
    });

    test('扩展档案与第三方扩展 JSON 往返', () async {
      const profile = CharacterProfile(
        basic: BasicProfile(nickname: '阿雪', age: '17'),
        creator: CreatorProfile(author: '作者', tags: ['校园']),
        runConfig: RunConfigProfile(systemPrompt: '保持冷淡'),
      );
      const extensions = CharacterExtensions(
        stExtensions: {'depth_prompt': {'depth': 4}},
        unknownData: {'nickname': '小雪'},
        unknownRoot: {'extra_root': true},
      );
      final c = repo.blank().copyWith(
        name: '阿雪',
        profile: profile,
        extensions: extensions,
      );
      await repo.save(c);

      final loaded = await repo.getById(c.id);
      expect(loaded!.profile.basic.nickname, '阿雪');
      expect(loaded.profile.basic.age, '17');
      expect(loaded.profile.creator.tags, ['校园']);
      expect(loaded.profile.runConfig.systemPrompt, '保持冷淡');
      expect(loaded.extensions.stExtensions['depth_prompt'], {'depth': 4});
      expect(loaded.extensions.unknownData['nickname'], '小雪');
      expect(loaded.extensions.unknownRoot['extra_root'], isTrue);
    });

    test('save 更新时快照旧状态，内容未变不重复', () async {
      final c = repo.blank().copyWith(
        name: '旧名',
        profile: const CharacterProfile(
          basic: BasicProfile(nickname: '旧昵称'),
        ),
      );
      await repo.save(c);
      expect(await repo.listVersions(c.id), isEmpty);

      // 第一次更新：旧状态入库。
      await repo.save(c.copyWith(name: '新名'));
      var versions = await repo.listVersions(c.id);
      expect(versions, hasLength(1));
      expect(versions.single.trigger, 'save');
      expect(versions.single.snapshot['name'], '旧名');
      expect(
        (versions.single.snapshot['profile'] as Map)['basic']['nickname'],
        '旧昵称',
      );

      // 再存一次完全相同的内容：不重复写快照。
      await repo.save(c.copyWith(name: '新名'));
      versions = await repo.listVersions(c.id);
      expect(versions, hasLength(1));
    });

    test('版本快照按角色裁剪到 20 条', () async {
      var c = repo.blank().copyWith(name: 'v0');
      await repo.save(c);
      for (var i = 1; i <= 25; i++) {
        c = c.copyWith(name: 'v$i');
        await repo.save(c);
      }
      final versions = await repo.listVersions(c.id, limit: 100);
      expect(versions, hasLength(kCharacterVersionMax));
      // 最新的快照是最后一次保存前的状态。
      expect(versions.first.snapshot['name'], 'v24');
      expect(versions.last.snapshot['name'], 'v5');
    });

    test('恢复版本：写回旧档案，并把当前状态存为 restore', () async {
      final c = repo.blank().copyWith(
        name: '旧名',
        profile: const CharacterProfile(
          basic: BasicProfile(nickname: '旧昵称'),
        ),
      );
      await repo.save(c);
      await repo.save(c.copyWith(name: '新名'));

      final versions = await repo.listVersions(c.id);
      expect(versions, hasLength(1));
      final ok = await repo.restoreVersion(versions.single.id);
      expect(ok, isTrue);

      final loaded = await repo.getById(c.id);
      expect(loaded!.name, '旧名');
      expect(loaded.profile.basic.nickname, '旧昵称');

      final after = await repo.listVersions(c.id);
      expect(after.map((v) => v.trigger), contains('restore'));
      expect(after.first.snapshot['name'], '新名');
    });

    test('手动版本与删除角色级联清理', () async {
      final c = repo.blank().copyWith(name: '小雨');
      await repo.save(c);
      expect(await repo.createVersion(c.id, label: '里程碑'), isTrue);
      final versions = await repo.listVersions(c.id);
      expect(versions, hasLength(1));
      expect(versions.single.trigger, 'manual');
      expect(versions.single.label, '里程碑');

      await repo.delete(c.id);
      expect(await db.select(db.characterVersions).get(), isEmpty);
    });
  });
}
