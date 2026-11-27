import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../domain/lore_entry.dart';

/// 世界书（Lorebook）：关键词命中后才注入提示词。
class CharacterLorePage extends ConsumerWidget {
  const CharacterLorePage({
    super.key,
    required this.characterId,
    required this.characterName,
  });

  final String characterId;
  final String characterName;

  static const _uuid = Uuid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(
      loreRepositoryProvider,
    ).watchForCharacter(characterId);
    return Scaffold(
      appBar: AppBar(title: Text('$characterName · 世界书')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-lore',
        onPressed: () => _edit(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('新增条目'),
      ),
      body: StreamBuilder<List<LoreEntry>>(
        stream: entries,
        builder: (context, snapshot) {
          final list = snapshot.data ?? const <LoreEntry>[];
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  '还没有世界书条目。\n添加关键词和设定，只有聊到相关词时才会注入，节省上下文。',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = list[index];
              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  title: Text(
                    entry.keys.isEmpty ? '（无关键词）' : entry.keys.join(' / '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    entry.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  leading: Switch(
                    value: entry.enabled,
                    onChanged: (v) => ref
                        .read(loreRepositoryProvider)
                        .setEnabled(entry.id, v),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'edit') {
                        _edit(context, ref, entry);
                      } else if (action == 'delete') {
                        _delete(context, ref, entry);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('编辑')),
                      PopupMenuItem(value: 'delete', child: Text('删除')),
                    ],
                  ),
                  onTap: () => _edit(context, ref, entry),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    LoreEntry entry,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这个世界书条目？'),
        content: Text(entry.keys.join(' / ')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(loreRepositoryProvider).delete(entry.id);
    }
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    LoreEntry? entry,
  ) async {
    final keys = TextEditingController(text: entry?.keys.join(', ') ?? '');
    final content = TextEditingController(text: entry?.content ?? '');
    var position = entry?.position ?? 'before';
    var depth = entry?.depth ?? 0;
    var priority = entry?.priority ?? 0;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(entry == null ? '新增世界书条目' : '编辑世界书条目'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: keys,
                  decoration: const InputDecoration(
                    labelText: '关键词（逗号分隔）',
                    hintText: '天台风, 放学后',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: content,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: '设定内容',
                    hintText: '命中后注入给角色的背景事实',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: position,
                        decoration: const InputDecoration(labelText: '插入位置'),
                        items: const [
                          DropdownMenuItem(value: 'before', child: Text('历史前')),
                          DropdownMenuItem(value: 'after', child: Text('历史后')),
                        ],
                        onChanged: (v) => setState(() => position = v ?? 'before'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: '$depth',
                        decoration: const InputDecoration(labelText: '深度'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => depth = int.tryParse(v) ?? 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: '$priority',
                        decoration: const InputDecoration(labelText: '优先级'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => priority = int.tryParse(v) ?? 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                final keyList = keys.text
                    .split(RegExp(r'[,，\n]'))
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
                if (keyList.isEmpty || content.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('关键词和设定内容都不能为空')),
                  );
                  return;
                }
                final now = DateTime.now();
                await ref
                    .read(loreRepositoryProvider)
                    .save(
                      LoreEntry(
                        id: entry?.id ?? _uuid.v4(),
                        characterId: characterId,
                        keys: keyList,
                        content: content.text.trim(),
                        position: position,
                        depth: depth,
                        priority: priority,
                        enabled: entry?.enabled ?? true,
                        sourceJson: entry?.sourceJson ?? '{}',
                        createdAt: entry?.createdAt ?? now,
                      ),
                    );
                if (context.mounted) Navigator.pop(context, true);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已保存；下一轮对话生效')),
      );
    }
  }
}
