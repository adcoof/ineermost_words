import 'package:ai_roleplay_chat/app/providers.dart';
import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:ai_roleplay_chat/features/assets/presentation/assets_page.dart';
import 'package:ai_roleplay_chat/features/characters/data/character_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('资产页展示四个入口，立绘入口可选角色并进入编辑页', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = CharacterRepository(db);
    final character = repo.blank().copyWith(name: '阿雪');
    await repo.save(character);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: AssetsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('角色资产'), findsOneWidget);
    expect(find.text('桌宠模型'), findsOneWidget);
    expect(find.text('角色立绘'), findsOneWidget);
    expect(find.text('表情包'), findsOneWidget);
    expect(find.text('音色'), findsOneWidget);

    await tester.tap(find.text('角色立绘'));
    await tester.pumpAndSettle();
    expect(
      find.text('还没有角色，先去工坊创建或导入一个'),
      findsNothing,
    );
    expect(find.text('阿雪'), findsOneWidget);
    await tester.tap(find.text('阿雪'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '编辑角色'), findsOneWidget);
  });
}
