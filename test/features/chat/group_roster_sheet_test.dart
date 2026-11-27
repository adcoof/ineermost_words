import 'package:ai_roleplay_chat/app/providers.dart';
import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:ai_roleplay_chat/features/characters/data/character_repository.dart';
import 'package:ai_roleplay_chat/features/chat/data/chat_repository.dart';
import 'package:ai_roleplay_chat/features/chat/presentation/group_roster_sheet.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('群成员面板：静音开关与点击强制发言', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final charRepo = CharacterRepository(db);
    final a = charRepo.blank().copyWith(name: '角色A');
    final b = charRepo.blank().copyWith(name: '角色B');
    await charRepo.save(a);
    await charRepo.save(b);
    final chatRepo = ChatRepository(db);
    final conv = await chatRepo.createGroupConversation(
      apiProfileId: 'p1',
      characterIds: [a.id, b.id],
    );

    String? forced;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () {
                    showGroupRosterSheet(
                      context,
                      conversationId: conv.id,
                      onForceSpeaker: (id) => forced = id,
                    );
                  },
                  child: const Text('打开成员面板'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开成员面板'));
    await tester.pumpAndSettle();

    expect(find.text('群成员'), findsOneWidget);
    expect(find.text('角色A'), findsOneWidget);
    expect(find.text('角色B'), findsOneWidget);

    // 关闭 A 的自动轮转（B 仍启用，允许关闭）。
    await tester.tap(
      find.byKey(ValueKey('group-member-switch-${a.id}')),
    );
    await tester.pumpAndSettle();
    final participants = await chatRepo.listParticipants(conv.id);
    expect(
      participants.firstWhere((p) => p.characterId == a.id).enabled,
      isFalse,
    );

    // 点 B = Force Talk，面板关闭并回调角色 id。
    await tester.tap(find.text('角色B'));
    await tester.pumpAndSettle();
    expect(forced, b.id);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
