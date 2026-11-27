/// 资产页（v2.1）：桌宠、立绘、表情包、音色的聚合入口。
///
/// 本版只做入口聚合；统一资产表、多立绘/服装、角色-Live2D 绑定留到后续。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../characters/domain/character.dart';
import '../../characters/presentation/character_avatar.dart';
import '../../characters/presentation/character_edit_page.dart';
import '../../characters/presentation/sticker_library_page.dart';
import '../../pet/presentation/pet_page.dart';
import '../../voice/presentation/voice_settings_page.dart';

class AssetsPage extends ConsumerWidget {
  const AssetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('角色资产')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(
            context,
            icon: Icons.pets_outlined,
            title: '桌宠模型',
            subtitle: 'Live2D 模型导入、切换与表情动作',
            onTap: () => _push(context, const PetPage()),
          ),
          _tile(
            context,
            icon: Icons.photo_library_outlined,
            title: '角色立绘',
            subtitle: '选择角色查看或更换立绘',
            onTap: () => _pickCharacter(
              context,
              ref,
              (character) => CharacterEditPage(character: character),
            ),
          ),
          _tile(
            context,
            icon: Icons.emoji_emotions_outlined,
            title: '表情包',
            subtitle: '按心情管理角色的贴纸库',
            onTap: () => _pickCharacter(
              context,
              ref,
              (character) => StickerLibraryPage(characterId: character.id),
            ),
          ),
          _tile(
            context,
            icon: Icons.record_voice_over_outlined,
            title: '音色',
            subtitle: 'TTS 引擎、发音人与音色工坊',
            onTap: () => _push(context, const VoiceSettingsPage()),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Future<void> _push(BuildContext context, Widget page) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// 立绘/表情包都先选角色，再打开对应子页面。
  Future<void> _pickCharacter(
    BuildContext context,
    WidgetRef ref,
    Widget Function(Character character) builder,
  ) async {
    final characters =
        await ref.read(characterRepositoryProvider).listCharacters();
    if (!context.mounted) return;
    if (characters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('还没有角色，先去工坊创建或导入一个')),
      );
      return;
    }

    final selected = await showModalBottomSheet<Character>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final character in characters)
              ListTile(
                leading: CharacterAvatar(avatarPath: character.avatarPath),
                title: Text(character.name),
                subtitle: Text(character.sourceLabel),
                onTap: () => Navigator.pop(context, character),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => builder(selected)),
    );
  }
}
