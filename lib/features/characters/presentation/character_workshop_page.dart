/// 角色工坊（v1.8 M2）：多轮需求 → 多字段 patch → diff → 人工应用。
///
/// 门禁：只调用 CharacterAssistantService（仅聊天接口），提案不自动保存；
/// 草稿只在内存里，退出页面即丢弃。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../application/character_assistant_service.dart';
import '../data/character_repository.dart';
import '../domain/character.dart';

class CharacterWorkshopPage extends ConsumerStatefulWidget {
  /// null 表示从零起草；否则在已保存角色上多轮修改。
  final Character? character;

  const CharacterWorkshopPage({super.key, this.character});

  @override
  ConsumerState<CharacterWorkshopPage> createState() =>
      _CharacterWorkshopPageState();
}

class _WorkshopTurn {
  final String instruction;
  CharacterPatch? patch;
  String? error;
  List<String> applied = const [];
  bool discarded = false;

  _WorkshopTurn(this.instruction);
}

class _CharacterWorkshopPageState extends ConsumerState<CharacterWorkshopPage> {
  final TextEditingController _instruction = TextEditingController();
  final List<Character> _undo = [];
  final List<_WorkshopTurn> _turns = [];

  late CharacterRepository _repo;
  late CharacterAssistantService _assistant;
  late Character _draft;

  _WorkshopTurn? _pendingTurn;
  Set<String> _selected = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(characterRepositoryProvider);
    _assistant = ref.read(characterAssistantProvider);
    _draft = widget.character ?? _repo.blank();
  }

  @override
  void dispose() {
    _instruction.dispose();
    super.dispose();
  }

  bool get _isNew => widget.character == null;

  Future<void> _generate() async {
    final text = _instruction.text.trim();
    if (text.isEmpty) {
      _toast('先写下想要的角色设定');
      return;
    }
    if (_busy) return;
    setState(() {
      _busy = true;
      _pendingTurn = null;
    });
    final turn = _WorkshopTurn(text);
    try {
      final patch = await _assistant.revise(
        CharacterPatchRequest(base: _draft, instruction: text),
      );
      if (!mounted) return;
      turn.patch = patch;
      setState(() {
        _turns.add(turn);
        _pendingTurn = turn;
        _selected = {
          for (final c in patch.changes)
            if (c.field != 'name' || _draft.name.trim().isEmpty) c.field,
        };
      });
      _instruction.clear();
    } on CharacterAssistantException catch (e) {
      turn.error = e.message;
      if (mounted) setState(() => _turns.add(turn));
    } catch (e) {
      turn.error = '生成失败：$e';
      if (mounted) setState(() => _turns.add(turn));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _applySelected({bool all = false}) {
    final turn = _pendingTurn;
    final patch = turn?.patch;
    if (turn == null || patch == null) return;
    final fields = all
        ? patch.changes.map((c) => c.field).toSet()
        : Set<String>.from(_selected);
    if (fields.isEmpty) {
      _toast('至少选择一个字段');
      return;
    }
    _undo.add(_draft);
    if (_undo.length > 20) _undo.removeAt(0);
    var next = _draft;
    for (final change in patch.changes) {
      if (!fields.contains(change.field)) continue;
      next = switch (change.field) {
        'name' => next.copyWith(name: change.value),
        'description' => next.copyWith(description: change.value),
        'personality' => next.copyWith(personality: change.value),
        'scenario' => next.copyWith(scenario: change.value),
        'firstMessage' => next.copyWith(firstMessage: change.value),
        'exampleDialogue' => next.copyWith(exampleDialogue: change.value),
        _ => next,
      };
    }
    turn.applied = fields.toList();
    setState(() {
      _draft = next;
      _pendingTurn = null;
      _selected = {};
    });
    _toast('已应用 ${fields.length} 个字段，点右上角「保存」才会写入角色卡');
  }

  void _discard() {
    final turn = _pendingTurn;
    if (turn == null) return;
    turn.discarded = true;
    setState(() {
      _pendingTurn = null;
      _selected = {};
    });
  }

  void _undoLast() {
    if (_undo.isEmpty) return;
    setState(() {
      _draft = _undo.removeLast();
      _pendingTurn = null;
    });
    _toast('已撤销上一次应用');
  }

  Future<void> _save() async {
    final name = _draft.name.trim();
    if (name.isEmpty) {
      _toast('角色名不能为空');
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _repo.save(_draft.copyWith(name: name));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _toast('保存失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 角色工坊'),
        actions: [
          if (_undo.isNotEmpty)
            IconButton(
              tooltip: '撤销上一次应用',
              onPressed: _undoLast,
              icon: const Icon(Icons.undo),
            ),
          TextButton(onPressed: _busy ? null : _save, child: const Text('保存')),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              children: [
                _DraftCard(draft: _draft, isNew: _isNew),
                const SizedBox(height: 12),
                if (_turns.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      '用一句话描述想要的角色，例如：\n「一个嘴硬心软的银发大小姐，天台场景，开场白短一点」',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                for (final turn in _turns) _TurnCard(turn: turn),
                if (_pendingTurn != null && _pendingTurn!.patch != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _PatchCard(
                      patch: _pendingTurn!.patch!,
                      base: _draft,
                      selected: _selected,
                      onToggle: (field) => setState(() {
                        if (!_selected.add(field)) _selected.remove(field);
                      }),
                      onApply: () => _applySelected(),
                      onApplyAll: () => _applySelected(all: true),
                      onDiscard: _discard,
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _instruction,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _generate(),
                      decoration: const InputDecoration(
                        hintText: '描述想要的角色，或下一轮修改要求…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _busy ? null : _generate,
                    tooltip: '生成提案',
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  final Character draft;
  final bool isNew;

  const _DraftCard({required this.draft, required this.isNew});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(isNew ? '新角色草稿（未保存）' : '当前草稿',
                    style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              draft.name.trim().isEmpty ? '（还没有名字）' : draft.name,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              _summary(draft),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _summary(Character c) {
    final parts = <String>[];
    if (c.description.trim().isNotEmpty) parts.add('描述 ${c.description.runes.length} 字');
    if (c.personality.trim().isNotEmpty) parts.add('性格 ${c.personality.runes.length} 字');
    if (c.scenario.trim().isNotEmpty) parts.add('场景 ${c.scenario.runes.length} 字');
    if (c.firstMessage.trim().isNotEmpty) parts.add('开场白 ${c.firstMessage.runes.length} 字');
    if (c.exampleDialogue.trim().isNotEmpty) {
      parts.add('示例 ${c.exampleDialogue.runes.length} 字');
    }
    return parts.isEmpty ? '还没有内容，先描述一句需求。' : parts.join(' · ');
  }
}

class _TurnCard extends StatelessWidget {
  final _WorkshopTurn turn;

  const _TurnCard({required this.turn});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('你：${turn.instruction}', style: theme.textTheme.bodyMedium),
            if (turn.error != null) ...[
              const SizedBox(height: 6),
              Text(turn.error!,
                  style: TextStyle(color: theme.colorScheme.error)),
            ],
            if (turn.patch != null) ...[
              const SizedBox(height: 6),
              Text('助手：${turn.patch!.justification}',
                  style: theme.textTheme.bodyMedium),
              if (turn.applied.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '已应用：${turn.applied.map(_label).join('、')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ] else if (turn.discarded)
                Text('已放弃本次提案',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
            ],
          ],
        ),
      ),
    );
  }
}

class _PatchCard extends StatelessWidget {
  final CharacterPatch patch;
  final Character base;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onApply;
  final VoidCallback onApplyAll;
  final VoidCallback onDiscard;

  const _PatchCard({
    required this.patch,
    required this.base,
    required this.selected,
    required this.onToggle,
    required this.onApply,
    required this.onApplyAll,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.difference_outlined,
                    color: theme.colorScheme.onSecondaryContainer),
                const SizedBox(width: 8),
                Text('本次提案', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(patch.justification),
            const SizedBox(height: 8),
            for (final change in patch.changes)
              _ChangeTile(
                change: change,
                oldValue: _current(base, change.field),
                checked: selected.contains(change.field),
                onChanged: () => onToggle(change.field),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.end,
              children: [
                TextButton(onPressed: onDiscard, child: const Text('放弃')),
                OutlinedButton(onPressed: onApply, child: const Text('应用选中')),
                FilledButton(onPressed: onApplyAll, child: const Text('全部应用')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _current(Character c, String field) {
    return switch (field) {
      'name' => c.name,
      'description' => c.description,
      'personality' => c.personality,
      'scenario' => c.scenario,
      'firstMessage' => c.firstMessage,
      'exampleDialogue' => c.exampleDialogue,
      _ => '',
    };
  }
}

class _ChangeTile extends StatelessWidget {
  final CharacterFieldChange change;
  final String oldValue;
  final bool checked;
  final VoidCallback onChanged;

  const _ChangeTile({
    required this.change,
    required this.oldValue,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final oldText = oldValue.trim().isEmpty ? '（空）' : oldValue;
    return InkWell(
      onTap: onChanged,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(value: checked, onChanged: (_) => onChanged()),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_label(change.field),
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text('原文：$oldText',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                  const SizedBox(height: 2),
                  Text('建议：${change.value}',
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _label(String field) => switch (field) {
      'name' => '名字',
      'description' => '描述',
      'personality' => '性格',
      'scenario' => '场景',
      'firstMessage' => '开场白',
      'exampleDialogue' => '对话示例',
      _ => field,
    };
