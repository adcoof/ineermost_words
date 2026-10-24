/// 会话列表头像条的纯函数：有会话的角色推导与计数。
library;

import 'package:ai_roleplay_chat/features/chat/domain/models.dart';
import 'package:ai_roleplay_chat/features/chat/presentation/conversation_list_page.dart';
import 'package:ai_roleplay_chat/features/characters/domain/character.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Character ch(String id, String name) => Character(
        id: id,
        name: name,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

  Conversation conv({required String id, String? characterId}) => Conversation(
        id: id,
        title: id,
        characterId: characterId,
        apiProfileId: 'p1',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        archived: false,
      );

  test('charactersWithConversations：保序过滤，无会话角色与孤儿 id 不出现', () {
    final chars = [ch('c1', '星野雀'), ch('c2', '芽衣'), ch('c3', '没会话的')];
    final convs = [
      conv(id: 'a', characterId: 'c1'),
      conv(id: 'b'), // 无角色
      conv(id: 'c', characterId: 'c1'),
      conv(id: 'd', characterId: 'ghost'), // 孤儿：角色已删
      conv(id: 'e', characterId: 'c2'),
    ];

    final withConvs = charactersWithConversations(convs, chars);
    expect(withConvs.map((c) => c.id), ['c1', 'c2']); // 保持 chars 原顺序
  });
}
