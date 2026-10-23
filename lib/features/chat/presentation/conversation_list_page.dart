/// 会话列表页。
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../characters/domain/character.dart';
import '../../characters/presentation/start_chat.dart';
import '../domain/models.dart';
import 'chat_page.dart';

class ConversationListPage extends ConsumerWidget {
  const ConversationListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(chatRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('会话'),
      ),
      body: StreamBuilder<List<Conversation>>(
        stream: repo.watchConversations(),
        builder: (context, snapshot) {
          final conversations = snapshot.data ?? const [];
          if (conversations.isEmpty) {
            return const Center(child: Text('还没有会话，点右下角新建'));
          }
          final fmt = DateFormat('MM-dd HH:mm');
          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final c = conversations[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.chat_bubble_outline)),
                title: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(fmt.format(c.updatedAt)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, ref, c),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatPage(conversationId: c.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        // 与角色页 FAB 同屏（IndexedStack），需不同 heroTag 防 Hero 撞车。
        heroTag: 'fab-conversation',
        onPressed: () => _showNewConversationSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('新会话'),
      ),
    );
  }

  /// 新会话入口：无角色直接聊 / 选已有角色 / 导入角色卡并开始。
  Future<void> _showNewConversationSheet(
      BuildContext context, WidgetRef ref) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('无角色，直接聊天'),
              onTap: () => Navigator.pop(context, 'blank'),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('选择已有角色'),
              onTap: () => Navigator.pop(context, 'pick'),
            ),
            ListTile(
              leading: const Icon(Icons.file_upload_outlined),
              title: const Text('导入角色卡并开始（PNG/JSON）'),
              onTap: () => Navigator.pop(context, 'import'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;

    if (choice == 'blank') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ChatPage()),
      );
      return;
    }

    final characterRepo = ref.read(characterRepositoryProvider);
    if (choice == 'import') {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['png', 'json'],
      );
      if (picked == null || !context.mounted) return;
      try {
        final bytes = await picked.xFile.readAsBytes();
        final character = await characterRepo.importFromBytes(bytes);
        if (context.mounted) {
          await startChatWithCharacter(context, ref, character);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('导入失败：$e')));
        }
      }
      return;
    }

    // choice == 'pick'
    final characters = await characterRepo.watchCharacters().first;
    if (!context.mounted) return;
    if (characters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('还没有角色，先导入一张角色卡吧')),
      );
      return;
    }
    final selected = await showModalBottomSheet<Character>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final c in characters)
              ListTile(
                leading: const CircleAvatar(
                    child: Icon(Icons.person_outline, size: 20)),
                title: Text(c.name),
                subtitle: Text(c.source == 'st_v2' ? 'SillyTavern 卡' : '手动创建'),
                onTap: () => Navigator.pop(context, c),
              ),
          ],
        ),
      ),
    );
    if (selected != null && context.mounted) {
      await startChatWithCharacter(context, ref, selected);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Conversation c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除会话'),
        content: Text('确定删除「${c.title}」及其全部消息？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('删除')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(chatRepositoryProvider).deleteConversation(c.id);
    }
  }
}