/// 角色编辑页布局（v8.4）：人设字段收进可折叠分组，记忆/表情包库放在首屏。
library;

import 'package:ai_roleplay_chat/app/providers.dart';
import 'package:ai_roleplay_chat/data/local/app_database.dart';
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

Future<void> pumpPage(WidgetTester tester, {Character? character}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(home: CharacterEditPage(character: character)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('编辑已有角色：记忆/表情包库在首屏，人设默认收起', (tester) async {
    await pumpPage(tester, character: makeCharacter());

    expect(find.text('记忆与用户画像'), findsOneWidget);
    expect(find.text('表情包库'), findsOneWidget);
    expect(find.text('角色人设'), findsOneWidget);
    // ExpansionTile 收起时 children 处于 Offstage，默认 finder 找不到。
    expect(find.text('名字 *'), findsNothing);
    expect(find.text('描述（外貌、背景等）'), findsNothing);
  });

  testWidgets('点开「角色人设」后六个输入框出现', (tester) async {
    await pumpPage(tester, character: makeCharacter());

    await tester.tap(find.text('角色人设'));
    await tester.pumpAndSettle();

    expect(find.text('名字 *'), findsOneWidget);
    expect(find.text('描述（外貌、背景等）'), findsOneWidget);
    expect(find.text('性格'), findsOneWidget);
    expect(find.text('场景背景'), findsOneWidget);
    expect(find.text('开场白（角色先说的话）'), findsOneWidget);
    expect(find.text('对话示例（可选）'), findsOneWidget);
  });

  testWidgets('新建角色：人设默认展开，且没有记忆/表情包入口', (tester) async {
    await pumpPage(tester);

    expect(find.text('名字 *'), findsOneWidget);
    expect(find.text('记忆与用户画像'), findsNothing);
    expect(find.text('表情包库'), findsNothing);
  });
}
