/// 群聊成员面板：启用/静音、排序、添加/移除、让 TA 回复。
///
/// P0 策略：默认按成员顺序轮转；点成员 = Force Talk，只作用于下一条消息。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../characters/domain/character.dart';
import '../../characters/presentation/character_avatar.dart';
import '../domain/models.dart';

Future<bool> showGroupRosterSheet(
  BuildContext context, {
  required String conversationId,
  required ValueChanged<String?> onForceSpeaker,
}) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => GroupRosterSheet(
      conversationId: conversationId,
      onForceSpeaker: onForceSpeaker,
    ),
  );
  return changed == true;
}

class GroupRosterSheet extends ConsumerStatefulWidget {
  final String conversationId;
  final ValueChanged<String?> onForceSpeaker;

  const GroupRosterSheet({
    super.key,
    required this.conversationId,
    required this.onForceSpeaker,
  });

  @override
  ConsumerState<GroupRosterSheet> createState() => _GroupRosterSheetState();
}

class _GroupRosterSheetState extends ConsumerState<GroupRosterSheet> {
  List<ConversationParticipant> _participants = const [];
  Map<String, Character> _characters = const {};
  bool _loading = true;
  bool _busy = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final participants = await ref
        .read(chatRepositoryProvider)
        .listParticipants(widget.conversationId);
    final all = await ref.read(characterRepositoryProvider).listCharacters();
    if (!mounted) return;
    setState(() {
      _participants = participants;
      _characters = {for (final c in all) c.id: c};
      _loading = false;
    });
  }

  Future<void> _afterChange() async {
    _changed = true;
    await _load();
    if (!mounted) return;
    final names = [
      for (final p in _participants) _characters[p.characterId]?.name ?? '角色',
    ].join('、');
    if (names.isNotEmpty) {
      await ref
          .read(chatRepositoryProvider)
          .renameConversation(widget.conversationId, names);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setEnabled(
    ConversationParticipant participant,
    bool enabled,
  ) async {
    final enabledCount = _participants.where((p) => p.enabled).length;
    if (!enabled && enabledCount <= 1) {
      _snack('至少保留一位启用成员');
      return;
    }
    await _run(() async {
      await ref
          .read(chatRepositoryProvider)
          .setParticipantEnabled(
            widget.conversationId,
            participant.characterId,
            enabled,
          );
      await _afterChange();
    });
  }

  Future<void> _reorder(int index, int delta) async {
    final target = index + delta;
    if (target < 0 || target >= _participants.length) return;
    final reordered = [..._participants];
    final item = reordered.removeAt(index);
    reordered.insert(target, item);
    await _run(() async {
      await ref.read(chatRepositoryProvider).reorderParticipants(
            widget.conversationId,
            [for (final p in reordered) p.characterId],
          );
      await _afterChange();
    });
  }

  Future<void> _remove(ConversationParticipant participant) async {
    if (_participants.length <= 2) {
      _snack('群聊至少保留两位角色');
      return;
    }
    final name = _characters[participant.characterId]?.name ?? '该角色';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除群成员'),
        content: Text('确定把「$name」移出群聊？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('移除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      await ref
          .read(chatRepositoryProvider)
          .removeParticipant(widget.conversationId, participant.characterId);
      await _afterChange();
    });
  }

  Future<void> _add() async {
    if (_participants.length >= 3) {
      _snack('群聊最多三位角色');
      return;
    }
    final existing = {for (final p in _participants) p.characterId};
    final candidates = _characters.values
        .where((c) => !existing.contains(c.id))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    if (candidates.isEmpty) {
      _snack('没有可添加的角色');
      return;
    }
    final selected = await showModalBottomSheet<Character>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('添加群成员')),
            for (final character in candidates)
              ListTile(
                leading: CharacterAvatar(avatarPath: character.avatarPath),
                title: Text(character.name),
                onTap: () => Navigator.pop(context, character),
              ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    await _run(() async {
      await ref
          .read(chatRepositoryProvider)
          .addParticipant(widget.conversationId, selected.id);
      await _afterChange();
    });
  }

  void _force(ConversationParticipant participant) {
    widget.onForceSpeaker(participant.characterId);
    Navigator.pop(context, true);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('群成员', style: theme.textTheme.titleLarge),
                const SizedBox(width: 8),
                Text(
                  '${_participants.length} / 3',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed:
                      _busy || _participants.length >= 3 ? null : _add,
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('添加'),
                ),
              ],
            ),
            Text(
              '点成员：下一条由 TA 回复；开关：是否参与自动轮转。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _participants.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final participant = _participants[index];
                    final character = _characters[participant.characterId];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CharacterAvatar(
                        avatarPath: character?.avatarPath,
                      ),
                      title: Text(
                        character?.name ?? '角色',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        participant.enabled ? '参与轮转' : '已静音（仍可强制发言）',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: participant.enabled
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.error,
                        ),
                      ),
                      onTap: _busy ? null : () => _force(participant),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: participant.enabled,
                            onChanged: _busy
                                ? null
                                : (v) => _setEnabled(participant, v),
                          ),
                          PopupMenuButton<String>(
                            enabled: !_busy,
                            onSelected: (value) {
                              if (value == 'up') _reorder(index, -1);
                              if (value == 'down') _reorder(index, 1);
                              if (value == 'remove') _remove(participant);
                            },
                            itemBuilder: (_) => [
                              if (index > 0)
                                const PopupMenuItem(
                                  value: 'up',
                                  child: Text('上移'),
                                ),
                              if (index < _participants.length - 1)
                                const PopupMenuItem(
                                  value: 'down',
                                  child: Text('下移'),
                                ),
                              if (_participants.length > 2)
                                const PopupMenuItem(
                                  value: 'remove',
                                  child: Text('移除'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _changed),
                child: const Text('完成'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
