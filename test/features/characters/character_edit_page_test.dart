/// 角色编辑页布局（v2.1）：基础 / 档案 / 高级三页签。
library;

import 'package:ai_roleplay_chat/app/providers.dart';
import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:ai_roleplay_chat/features/characters/data/character_repository.dart';
import 'package:ai_roleplay_chat/features/characters/domain/character.dart';
import 'package:ai_roleplay_chat/features/characters/presentation/character_edit_page.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Character makeCharacter() => Character(
  id: 'c1',
  name: '星野雀',
  description: '银白短发的傲娇大小姐',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

Future<AppDatabase> pumpPage(
  WidgetTester tester, {
  Character? character,
}) async {
  // 长表单在默认 800x600 测试视口下会懒加载不到下半部分，调高视口。
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(home: CharacterEditPage(character: character)),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

void main() {
  testWidgets('基础页展示核心输入框与记忆/世界书/表情包入口', (tester) async {
    await pumpPage(tester, character: makeCharacter());

    expect(find.text('记忆与用户画像'), findsOneWidget);
    expect(find.text('世界书'), findsOneWidget);
    expect(find.text('表情包库'), findsOneWidget);
    expect(find.text('基础'), findsOneWidget);
    expect(find.text('档案'), findsOneWidget);
    expect(find.text('高级'), findsOneWidget);
    expect(find.text('名字 *'), findsOneWidget);
    expect(find.text('描述（外貌、背景等）'), findsOneWidget);
    expect(find.text('性格'), findsOneWidget);
    expect(find.text('场景背景'), findsOneWidget);
    expect(find.text('开场白（角色先说的话）'), findsOneWidget);
    expect(find.text('对话示例（可选）'), findsOneWidget);
    expect(find.byTooltip('AI 改写'), findsNWidgets(6));
    expect(find.text('备用开场白（0）'), findsOneWidget);
    expect(find.text('标签'), findsOneWidget);
  });

  testWidgets('档案页签展示五个分区；高级页签展示用量与版本入口', (tester) async {
    await pumpPage(tester, character: makeCharacter());

    await tester.tap(find.text('档案'));
    await tester.pumpAndSettle();
    expect(find.text('外貌设定'), findsOneWidget);
    expect(find.text('背景故事'), findsOneWidget);
    expect(find.text('关系设定'), findsOneWidget);
    expect(find.text('语言风格'), findsOneWidget);
    expect(find.text('互动方式'), findsOneWidget);
    // 外貌默认展开。
    expect(find.text('发型'), findsOneWidget);

    await tester.tap(find.text('高级'));
    await tester.pumpAndSettle();
    expect(find.text('创作者信息'), findsOneWidget);
    expect(find.text('高级提示词'), findsOneWidget);
    expect(find.text('档案用量'), findsOneWidget);
    expect(find.text('版本历史'), findsOneWidget);
    expect(find.text('导出角色卡'), findsOneWidget);
  });

  testWidgets('新建角色：没有记忆/表情包入口', (tester) async {
    await pumpPage(tester);

    expect(find.text('名字 *'), findsOneWidget);
    expect(find.text('记忆与用户画像'), findsNothing);
    expect(find.text('表情包库'), findsNothing);
  });

  testWidgets('编辑档案字段并保存会写入 profile_json', (tester) async {
    final character = makeCharacter();
    final db = await pumpPage(tester, character: character);

    await tester.tap(find.text('档案'));
    await tester.pumpAndSettle();
    final hair = find.widgetWithText(TextField, '发型');
    expect(hair, findsOneWidget);
    await tester.enterText(hair, '银白长发');

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final loaded =
        await CharacterRepository(db).getById(character.id);
    expect(loaded, isNotNull);
    expect(loaded!.profile.appearance.hair, '银白长发');
  });

  testWidgets('有未保存修改时返回会二次确认', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          CharacterEditPage(character: makeCharacter()),
                    ),
                  ),
                  child: const Text('打开编辑页'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开编辑页'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, '名字 *'),
      '新名字',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('放弃未保存的修改？'), findsOneWidget);

    await tester.tap(find.text('继续编辑'));
    await tester.pumpAndSettle();
    expect(find.text('放弃未保存的修改？'), findsNothing);
    expect(find.text('编辑角色'), findsOneWidget);
  });

  testWidgets('导出菜单展示三种格式，并打开损失提示', (tester) async {
    await pumpPage(tester, character: makeCharacter());

    await tester.tap(find.byTooltip('导出角色卡'));
    await tester.pumpAndSettle();
    expect(find.text('导出 ST V2 JSON'), findsOneWidget);
    expect(find.text('导出 ST V3 JSON'), findsOneWidget);
    expect(find.text('导出 PNG 角色卡'), findsOneWidget);

    await tester.tap(find.text('导出 ST V3 JSON'));
    await tester.pumpAndSettle();
    expect(find.text('以下数据不会写入角色卡：'), findsOneWidget);
    expect(find.text('写入心语扩展（便于导回心语）'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('导出'), findsOneWidget);
  });
}
