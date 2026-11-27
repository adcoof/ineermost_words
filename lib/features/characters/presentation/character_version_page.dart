/// 角色版本历史：查看自动快照、恢复或删除。
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/character.dart';
import '../domain/character_version.dart';

class CharacterVersionPage extends ConsumerStatefulWidget {
  final String characterId;
  final String characterName;

  const CharacterVersionPage({
    super.key,
    required this.characterId,
    required this.characterName,
  });

  @override
  ConsumerState<CharacterVersionPage> createState() =>
      _CharacterVersionPageState();
}

class _CharacterVersionPageState extends ConsumerState<CharacterVersionPage> {
  List<CharacterVersion>? _versions;
  Character? _current;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(characterRepositoryProvider);
    final versions = await repo.listVersions(widget.characterId);
    final current = await repo.getById(widget.characterId);
    if (!mounted) return;
    setState(() {
      _versions = versions;
      _current = current;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final versions = _versions;
    return Scaffold(
      appBar: AppBar(title: Text('${widget.characterName} · 版本历史')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (versions == null || versions.isEmpty)
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  '还没有版本记录。\n保存角色后会自动生成快照，每角色最多保留 20 条。\n立绘不参与版本回滚。',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
              itemCount: versions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final version = versions[index];
                final changed = _changedFields(version);
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    isThreeLine: true,
                    title: Text(
                      version.snapshotName.isEmpty
                          ? '未命名版本'
                          : version.snapshotName,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          '${_triggerLabel(version.trigger)} · '
                          '${_formatTime(version.createdAtMs)}',
                        ),
                        Text(
                          changed.isEmpty
                              ? '与当前内容一致'
                              : '变更：${changed.join('、')}',
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'view') _showSnapshot(version);
                        if (action == 'restore') _restore(version);
                        if (action == 'delete') _delete(version);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'view', child: Text('查看快照')),
                        PopupMenuItem(value: 'restore', child: Text('恢复此版本')),
                        PopupMenuItem(value: 'delete', child: Text('删除此版本')),
                      ],
                    ),
                    onTap: () => _showSnapshot(version),
                  ),
                );
              },
            ),
    );
  }

  List<String> _changedFields(CharacterVersion version) {
    final current = _current;
    if (current == null) return const [];
    final snap = version.snapshot;
    final changed = <String>[];

    void check(String label, String currentValue, Object? snapValue) {
      final value = snapValue is String ? snapValue : '';
      if (currentValue != value) changed.add(label);
    }

    check('名字', current.name, snap['name']);
    check('描述', current.description, snap['description']);
    check('性格', current.personality, snap['personality']);
    check('场景', current.scenario, snap['scenario']);
    check('开场白', current.firstMessage, snap['firstMessage']);
    check('对话示例', current.exampleDialogue, snap['exampleDialogue']);
    if (jsonEncode(current.alternateGreetings) !=
        jsonEncode(snap['alternateGreetings'] ?? const [])) {
      changed.add('备用开场白');
    }
    if (jsonEncode(current.profile.toJson()) !=
        jsonEncode(snap['profile'] ?? const {})) {
      changed.add('档案');
    }
    return changed;
  }

  void _showSnapshot(CharacterVersion version) {
    final text = const JsonEncoder.withIndent('  ').convert(version.snapshot);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          version.snapshotName.isEmpty
              ? '版本快照'
              : '版本快照 · ${version.snapshotName}',
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: SelectableText(text)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _restore(version);
            },
            child: const Text('恢复此版本'),
          ),
        ],
      ),
    );
  }

  Future<void> _restore(CharacterVersion version) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复这个版本？'),
        content: const Text(
          '会覆盖角色当前的文本档案（立绘不恢复），并先把当前状态存为一条快照。'
          '编辑页未保存的修改也会丢失。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('恢复'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final restored =
        await ref.read(characterRepositoryProvider).restoreVersion(version.id);
    if (!mounted) return;
    if (!restored) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('恢复失败：角色可能已删除或快照已损坏')),
      );
      return;
    }
    Navigator.of(context).pop(true);
  }

  Future<void> _delete(CharacterVersion version) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这条版本快照？'),
        content: const Text('删除后无法恢复；不会影响角色当前内容。'),
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
    if (ok != true) return;
    await ref.read(characterRepositoryProvider).deleteVersion(version.id);
    if (mounted) await _load();
  }

  String _triggerLabel(String trigger) => switch (trigger) {
    'save' => '自动保存',
    'manual' => '手动保存',
    'restore' => '恢复前快照',
    'import' => '导入',
    _ => trigger,
  };

  String _formatTime(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}';
  }
}
