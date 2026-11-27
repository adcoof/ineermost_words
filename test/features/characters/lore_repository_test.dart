import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:ai_roleplay_chat/features/characters/data/lore_repository.dart';
import 'package:ai_roleplay_chat/features/characters/domain/lore_entry.dart';

void main() {
  late AppDatabase db;
  late LoreRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LoreRepository(db);
  });

  tearDown(() => db.close());

  test('保存、按优先级读取、启停与删除', () async {
    final now = DateTime(2026, 1, 1);
    await repo.save(
      LoreEntry(
        id: 'a',
        characterId: 'ch1',
        keys: ['天台'],
        content: '天台的风很大',
        priority: 1,
        createdAt: now,
      ),
    );
    await repo.save(
      LoreEntry(
        id: 'b',
        characterId: 'ch1',
        keys: ['教室'],
        content: '教室很安静',
        priority: 5,
        createdAt: now,
      ),
    );
    final list = await repo.listForCharacter('ch1');
    expect(list.map((e) => e.id), ['b', 'a']);

    await repo.setEnabled('b', false);
    expect((await repo.listForCharacter('ch1', enabledOnly: true)).length, 1);

    await repo.delete('a');
    expect((await repo.listForCharacter('ch1')).length, 1);
  });

  test('导入草稿默认禁用，跳过空内容/空关键词', () async {
    final count = await repo.importDrafts('ch1', const [
      LoreImportDraft(keys: ['天台'], content: '描述 A'),
      LoreImportDraft(keys: ['教室'], content: ''),
      LoreImportDraft(keys: [], content: '描述 B'),
    ]);
    expect(count, 1);
    final list = await repo.listForCharacter('ch1');
    expect(list, hasLength(1));
    expect(list.single.enabled, false);
    expect(list.single.keys, ['天台']);
  });

  test('世界书原文 sourceJson 导入与编辑后保留', () async {
    await repo.importDrafts('ch1', const [
      LoreImportDraft(
        keys: ['天台'],
        content: '天台的风很大',
        sourceJson: '{"secondary_keys":["夜"],"extensions":{"x":1}}',
      ),
    ]);
    var list = await repo.listForCharacter('ch1');
    expect(list.single.sourceJson, contains('secondary_keys'));

    await repo.save(list.single.copyWith(content: '改过的内容'));
    list = await repo.listForCharacter('ch1');
    expect(list.single.content, '改过的内容');
    expect(list.single.sourceJson, contains('secondary_keys'));
  });

  test('坏 JSON 关键词按空处理', () async {
    await db.into(db.loreEntries).insert(
      LoreEntriesCompanion.insert(
        id: 'bad',
        characterId: 'ch1',
        keys: const Value('not-json'),
        createdAt: DateTime(2026, 1, 1),
      ),
    );
    final list = await repo.listForCharacter('ch1');
    expect(list.single.keys, isEmpty);
  });
}
