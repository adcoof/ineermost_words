/// 与角色开一场新会话的共享流程（角色页与会话页复用）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../chat/domain/models.dart';
import '../../chat/presentation/chat_page.dart';
import '../domain/character.dart';

/// 绑定角色 + 插入开场白 + 进入聊天页。
Future<void> startChatWithCharacter(
  BuildContext context,
  WidgetRef ref,
  Character character,
) async {
  final chatRepo = ref.read(chatRepositoryProvider);
  final profileRepo = ref.read(apiProfileRepositoryProvider);
  final profile = await profileRepo.getDefault();
  if (profile == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在设置中添加 API 供应商配置')),
      );
    }
    return;
  }
  final conv = await chatRepo.createConversation(
    apiProfileId: profile.id,
    characterId: character.id,
    title: character.name,
  );
  if (character.firstMessage.trim().isNotEmpty) {
    await chatRepo.insertMessage(
      conversationId: conv.id,
      role: ChatRole.assistant,
      content: character.firstMessage.trim(),
      rawContent: character.firstMessage.trim(),
    );
  }
  if (context.mounted) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatPage(conversationId: conv.id)),
    );
  }
}
