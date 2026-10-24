/// 角色列表页：手动新建、ST 卡导入、开始对话。
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/character.dart';
import 'character_avatar.dart';
import 'character_edit_page.dart';
import 'start_chat.dart';

class CharacterListPage extends ConsumerStatefulWidget {
  const CharacterListPage({super.key});

  @override
  ConsumerState<CharacterListPage> createState() => _CharacterListPageState();
}

class _CharacterListPageState extends ConsumerState<CharacterListPage> {
  /// 「与 TA 对话」在途标记，防双击重复建会话。
  bool _startingChat = false;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(characterRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('角色'),
        actions: [
          IconButton(
            tooltip: '导入角色卡（PNG/JSON）',
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: () => _importCard(context, ref),
          ),
        ],
      ),
      body: StreamBuilder<List<Character>>(
        stream: repo.watchCharacters(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final characters = snapshot.data ?? const [];
          if (characters.isEmpty) {
            return const Center(
              child: Text('还没有角色\n点右上角导入 SillyTavern 角色卡，或点 + 手动新建',
                  textAlign: TextAlign.center),
            );
          }
          return ListView.separated(
            itemCount: characters.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final c = characters[index];
              return ListTile(
                leading: CharacterAvatar(avatarPath: c.avatarPath),
                title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  c.source == 'st_v2' ? 'SillyTavern 卡' : '手动创建',
                  maxLines: 1,
                ),
                trailing: IconButton(
                  tooltip: '与 TA 对话',
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () => _startChat(context, ref, c),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => CharacterEditPage(character: c)),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        // 与会话页 FAB 同屏（IndexedStack），需不同 heroTag 防 Hero 撞车。
        heroTag: 'fab-characters',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => const CharacterEditPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('新建角色'),
      ),
    );
  }

  Future<void> _importCard(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(characterRepositoryProvider);
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['png', 'json'],
    );
    if (picked == null) return;
    try {
      final bytes = await picked.xFile.readAsBytes();
      final character = await repo.importFromBytes(bytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导入角色「${character.name}」')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('导入失败：$e')));
      }
    }
  }

  /// 与角色开一场新会话：绑定角色 + 插入开场白 + 进入聊天页。
  Future<void> _startChat(
      BuildContext context, WidgetRef ref, Character character) async {
    if (_startingChat) return; // 防双击产生重复会话。
    _startingChat = true;
    try {
      await startChatWithCharacter(context, ref, character);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('创建会话失败：$e')));
      }
    } finally {
      _startingChat = false;
    }
  }
}
