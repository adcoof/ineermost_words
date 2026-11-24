/// 角色记忆页（M3）：分段解析、三段切换、长期记忆长按删除。
library;

import 'package:ai_roleplay_chat/app/providers.dart';
import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:ai_roleplay_chat/features/characters/data/character_repository.dart';
import 'package:ai_roleplay_chat/features/characters/domain/character.dart';
import 'package:ai_roleplay_chat/features/characters/presentation/character_memory_page.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseDocSections', () {
    test('识别 # 小标题与独占一行的 **小标题**', () {
      final sections = parseDocSections(
        '开场白\n# 近期\n今天去了关山\n**喜好**\n喜欢草莓',
      );
      expect(sections, hasLength(3));
      expect(sections[0].heading, isNull);
      expect(sections[0].body, '开场白');
      expect(sections[1].heading, '近期');
      expect(sections[1].body, '今天去了关山');
      expect(sections[2].heading, '喜好');
      expect(sections[2].body, '喜欢草莓');
    });

    test('超过 24 字的 **…** 不当作标题，保留为正文', () {
      final long = '这是一个特别特别长的加粗句子，不应该被当成小标题解析';
      final sections = parseDocSections('**$long**');
      expect(sections, hasLength(1));
      expect(sections.single.heading, isNull);
      expect(sections.single.body, contains(long));
    });

    test('空文档返回空列表', () {
      expect(parseDocSections('   \n\n'), isEmpty);
    });
  });

  testWidgets('三段切换：近期记忆 / 长期记忆 / TA眼中的你', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = CharacterRepository(db);
    await repo.save(Character(
      id: 'ch1',
      name: '小雨',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ));
    await repo.setMemory(
      'ch1',
      summary: '# 近期\n今天去了关山',
      userSummary: '**喜好**\n喜欢草莓',
      updatedAt: DateTime(2026, 1, 3, 9, 5),
    );
    await repo.addMemoryFact(
      characterId: 'ch1',
      fact: '和用户去了关山',
      occurredAt: DateTime(2026, 1, 2),
      createdAt: DateTime(2026, 1, 2),
    );
    await repo.addMemoryFact(
      characterId: 'ch1',
      fact: '用户喜欢草莓',
      occurredAt: DateTime(2026, 1, 1),
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const MaterialApp(
        home: CharacterMemoryPage(characterId: 'ch1', characterName: '小雨'),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('今天去了关山'), findsOneWidget);
    expect(find.textContaining('上次整理'), findsOneWidget);

    await tester.tap(find.text('长期记忆'));
    await tester.pumpAndSettle();
    expect(find.text('共 2 条 · 长按可删除'), findsOneWidget);
    expect(find.text('和用户去了关山'), findsOneWidget);
    expect(find.text('2026-01-02'), findsOneWidget);

    await tester.tap(find.text('TA眼中的你'));
    await tester.pumpAndSettle();
    expect(find.text('喜欢草莓'), findsOneWidget);
    expect(find.text('喜好'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('长按长期记忆：确认后删除并重载', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = CharacterRepository(db);
    await repo.save(Character(
      id: 'ch1',
      name: '小雨',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ));
    await repo.addMemoryFact(
      characterId: 'ch1',
      fact: '和用户去了关山',
      occurredAt: DateTime(2026, 1, 2),
      createdAt: DateTime(2026, 1, 2),
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const MaterialApp(
        home: CharacterMemoryPage(characterId: 'ch1', characterName: '小雨'),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('长期记忆'));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('和用户去了关山'));
    await tester.pumpAndSettle();
    expect(find.text('删除这条长期记忆？'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();
    expect(find.text('和用户去了关山'), findsNothing);
    expect(find.text('共 0 条 · 长按可删除'), findsOneWidget);
    expect(find.text('还没有长期记忆'), findsOneWidget);
    expect(await repo.getMemoryFacts('ch1'), isEmpty);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}
