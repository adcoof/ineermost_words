/// 角色列表页：手动新建、ST 卡导入、开始对话。
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/character.dart';
import '../domain/character_import_result.dart';
import 'character_avatar.dart';
import 'character_edit_page.dart';
import 'character_workshop_page.dart';
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
        title: const Text('角色工坊'),
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
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            children: [
              _aiCreateCard(context),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '我的角色',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              if (characters.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    '还没有角色\n点右上角导入 SillyTavern 角色卡，或从上面的 AI 创作开始',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                for (var i = 0; i < characters.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _characterTile(context, ref, characters[i]),
                ],
            ],
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

  Widget _aiCreateCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CharacterWorkshopPage()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.auto_awesome,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI 创作角色', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '从一句话生成完整角色草稿，再逐字段调整',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _characterTile(
    BuildContext context,
    WidgetRef ref,
    Character character,
  ) {
    return ListTile(
      leading: CharacterAvatar(avatarPath: character.avatarPath),
      title: Text(
        character.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(character.sourceLabel, maxLines: 1),
      trailing: IconButton(
        tooltip: '与 TA 对话',
        icon: const Icon(Icons.chat_bubble_outline),
        onPressed: () => _startChat(context, ref, character),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CharacterEditPage(character: character),
        ),
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
      final result = await repo.importCard(bytes);
      if (!context.mounted) return;
      final view = await showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => _ImportResultSheet(result: result),
      );
      if (view == true && context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CharacterEditPage(character: result.character),
          ),
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

/// 导入结果卡片：格式、世界书数量、保留字段与警告；可跳转查看角色。
class _ImportResultSheet extends StatelessWidget {
  final CharacterImportResult result;

  const _ImportResultSheet({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('导入完成', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  'ST ${result.formatLabel}',
                  style: theme.textTheme.labelLarge?.copyWith(color: muted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(result.character.name, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            _infoRow(
              context,
              Icons.menu_book_outlined,
              '世界书',
              result.loreCount == 0
                  ? '无'
                  : '${result.loreCount} 条（默认禁用）',
            ),
            _infoRow(
              context,
              Icons.inventory_2_outlined,
              '保留第三方/未识别字段',
              '${result.preservedKeyCount} 个',
            ),
            if (result.warnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('提示', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              for (final warning in result.warnings)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '· $warning',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('完成'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('查看角色'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 17, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
