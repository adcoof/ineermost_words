import 'package:ai_roleplay_chat/app/providers.dart';
import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:ai_roleplay_chat/features/characters/data/character_repository.dart';
import 'package:ai_roleplay_chat/features/characters/presentation/character_version_page.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('版本历史展示自动快照、变更摘要与恢复确认', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = CharacterRepository(db);
    final character = repo.blank().copyWith(name: '阿雪');
    await repo.save(character);
    await repo.save(character.copyWith(name: '阿雪2'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: CharacterVersionPage(
            characterId: character.id,
            characterName: '阿雪2',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('阿雪2 · 版本历史'), findsOneWidget);
    expect(find.textContaining('自动保存'), findsOneWidget);
    expect(find.text('变更：名字'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('查看快照'), findsOneWidget);
    expect(find.text('恢复此版本'), findsOneWidget);

    await tester.tap(find.text('恢复此版本'));
    await tester.pumpAndSettle();
    expect(find.text('恢复这个版本？'), findsOneWidget);
    expect(find.text('恢复'), findsOneWidget);
  });

  testWidgets('没有版本时展示空态', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = CharacterRepository(db);
    final character = repo.blank().copyWith(name: '阿雪');
    await repo.save(character);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: CharacterVersionPage(
            characterId: character.id,
            characterName: '阿雪',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('还没有版本记录'), findsOneWidget);
  });
}
