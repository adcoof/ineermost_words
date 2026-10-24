/// 会话列表页：顶部横向角色头像条过滤（对话收纳），无角色会话只在「全部」。
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../characters/domain/character.dart';
import '../../characters/presentation/character_avatar.dart';
import '../../characters/presentation/start_chat.dart';
import '../domain/models.dart';
import 'chat_page.dart';

/// 有会话的角色（保持入参顺序，即 watchCharacters 的 updatedAt 降序）。
List<Character> charactersWithConversations(
    List<Conversation> convs, List<Character> chars) {
  final ids = {
    for (final c in convs)
      if (c.characterId != null) c.characterId!,
  };
  return [for (final c in chars) if (ids.contains(c.id)) c];
}

class ConversationListPage extends ConsumerStatefulWidget {
  const ConversationListPage({super.key});

  @override
  ConsumerState<ConversationListPage> createState() =>
      _ConversationListPageState();
}

class _ConversationListPageState extends ConsumerState<ConversationListPage> {
  /// 选中的角色过滤器；null=全部。
  String? _selectedCharacterId;

  @override
  Widget build(BuildContext context) {
    final conversations =
        ref.watch(conversationsStreamProvider).value ?? const <Conversation>[];
    final characters =
        ref.watch(charactersStreamProvider).value ?? const <Character>[];

    // 选中角色的最后一个会话被删/角色被删时自动回落「全部」
    //（build 内计算，不 setState，避免构建期改状态）。
    final withConvs = charactersWithConversations(conversations, characters);
    final idsWithConvs = {for (final c in withConvs) c.id};
    final effectiveSelected =
        idsWithConvs.contains(_selectedCharacterId) ? _selectedCharacterId : null;
    final filtered = effectiveSelected == null
        ? conversations
        : [
            for (final c in conversations)
              if (c.characterId == effectiveSelected) c,
          ];

    final fmt = DateFormat('MM-dd HH:mm');
    return Scaffold(
      appBar: AppBar(
        title: const Text('会话'),
      ),
      body: Column(
        children: [
          if (conversations.isNotEmpty) ...[
            _AvatarBar(
              characters: withConvs,
              selected: effectiveSelected,
              onSelected: (id) => setState(() => _selectedCharacterId = id),
            ),
            const Divider(height: 1),
          ],
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(effectiveSelected == null
                        ? '还没有会话，点右下角新建'
                        : '该角色还没有会话'),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final c = filtered[index];
                      return ListTile(
                        leading: const CircleAvatar(
                            child: Icon(Icons.chat_bubble_outline)),
                        title: Text(c.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(fmt.format(c.updatedAt)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(context, c),
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
                  ),
          ),
        ],
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
                leading: CharacterAvatar(
                    avatarPath: c.avatarPath, radius: 18),
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

  Future<void> _confirmDelete(BuildContext context, Conversation c) async {
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

/// 横向角色头像条：「全部」+ 有会话的角色，点选过滤。
class _AvatarBar extends StatelessWidget {
  final List<Character> characters;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _AvatarBar({
    required this.characters,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget item({required Widget avatar, required String? id, String? label}) {
      final isSelected = selected == id;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => onSelected(id),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? scheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: avatar,
              ),
              if (label != null) ...[
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        children: [
          item(
            id: null,
            label: '全部',
            avatar: CircleAvatar(
              radius: 22,
              backgroundColor: selected == null
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
              child: const Icon(Icons.people_outline),
            ),
          ),
          for (final c in characters)
            item(
              id: c.id,
              label: c.name,
              avatar: CharacterAvatar(avatarPath: c.avatarPath, radius: 22),
            ),
        ],
      ),
    );
  }
}
