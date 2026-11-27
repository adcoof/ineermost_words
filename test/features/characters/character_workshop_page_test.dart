/// 角色工坊 M2：多字段 patch 的应用与保存门禁。
library;

import 'package:ai_roleplay_chat/app/providers.dart';
import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:ai_roleplay_chat/features/characters/application/character_assistant_service.dart';
import 'package:ai_roleplay_chat/features/characters/data/character_repository.dart';
import 'package:ai_roleplay_chat/features/characters/presentation/character_workshop_page.dart';
import 'package:ai_roleplay_chat/features/chat/data/chat_api_client.dart';
import 'package:ai_roleplay_chat/features/settings/data/api_profile_repository.dart';
import 'package:ai_roleplay_chat/features/settings/domain/api_profile.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoopApi implements ChatApiClient {
  @override
  Stream<ChatDelta> streamChat({
    required ApiProfile profile,
    required List<ApiMessage> messages,
    double? temperature,
    int? maxTokens,
    CancelToken? cancelToken,
    List<ApiTool>? tools,
  }) =>
      const Stream.empty();

  @override
  Future<void> testConnection({
    required ApiProfile profile,
    CancelToken? cancelToken,
  }) async {}
}

class _FakeAssistant extends CharacterAssistantService {
  _FakeAssistant(ApiProfileRepository profiles)
      : super(api: _NoopApi(), profiles: profiles);

  @override
  Future<CharacterPatch> revise(CharacterPatchRequest request) async {
    return const CharacterPatch(
      justification: '把性格写得更具体',
      changes: [
        CharacterFieldChange(field: 'personality', value: '嘴上嫌弃，行动护短'),
        CharacterFieldChange(field: 'firstMessage', value: '……又来？'),
      ],
    );
  }
}

void main() {
  testWidgets('工坊：生成提案 → 应用 → 保存', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = CharacterRepository(db);
    final base = repo.blank().copyWith(
      name: '星野雀',
      description: '银白短发的傲娇大小姐',
      personality: '嘴硬心软',
      scenario: '放学后的天台',
      firstMessage: '……你怎么又来了？',
    );
    await repo.save(base);
    final assistant = _FakeAssistant(ApiProfileRepository(db));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          characterAssistantProvider.overrideWithValue(assistant),
        ],
        child: MaterialApp(home: CharacterWorkshopPage(character: base)),
      ),
    );

    await tester.enterText(find.byType(TextField), '把性格改得更嘴硬');
    await tester.tap(find.byIcon(Icons.auto_awesome));
    await tester.pumpAndSettle();

    expect(find.textContaining('把性格写得更具体'), findsWidgets);
    expect(find.textContaining('嘴上嫌弃，行动护短'), findsWidgets);

    await tester.ensureVisible(find.text('全部应用'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('全部应用'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final saved = await repo.getById(base.id);
    expect(saved!.personality, '嘴上嫌弃，行动护短');
    expect(saved.firstMessage, '……又来？');
  });
}
