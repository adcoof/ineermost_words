/// 角色编辑页：手动新建/编辑人设字段与立绘。
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/character.dart';

class CharacterEditPage extends ConsumerStatefulWidget {
  /// null 表示新建。
  final Character? character;

  const CharacterEditPage({super.key, this.character});

  @override
  ConsumerState<CharacterEditPage> createState() => _CharacterEditPageState();
}

class _CharacterEditPageState extends ConsumerState<CharacterEditPage> {
  late Character _character;
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _personality;
  late final TextEditingController _scenario;
  late final TextEditingController _firstMessage;
  late final TextEditingController _exampleDialogue;
  Uint8List? _pendingAvatar;

  @override
  void initState() {
    super.initState();
    final repo = ref.read(characterRepositoryProvider);
    _character = widget.character ?? repo.blank();
    _name = TextEditingController(text: _character.name);
    _description = TextEditingController(text: _character.description);
    _personality = TextEditingController(text: _character.personality);
    _scenario = TextEditingController(text: _character.scenario);
    _firstMessage = TextEditingController(text: _character.firstMessage);
    _exampleDialogue = TextEditingController(text: _character.exampleDialogue);
  }

  @override
  void dispose() {
    for (final c in [
      _name, _description, _personality, _scenario, _firstMessage, _exampleDialogue
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.character == null ? '新建角色' : '编辑角色'),
        actions: [
          TextButton(onPressed: _save, child: const Text('保存')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickAvatar,
              child: CircleAvatar(
                radius: 48,
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                backgroundImage: _avatarProvider(),
                child: _avatarProvider() == null
                    ? const Icon(Icons.add_a_photo_outlined, size: 32)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(child: Text('点击设置立绘')),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: '名字 *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: '描述（外貌、背景等）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _personality,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: '性格',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _scenario,
            minLines: 2,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: '场景背景',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _firstMessage,
            minLines: 2,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: '开场白（角色先说的话）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _exampleDialogue,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: '对话示例（可选）',
              hintText: '例如：\n{{user}}：你好\n{{char}}：哼，谁要跟你打招呼啊。',
              border: OutlineInputBorder(),
            ),
          ),
          if (widget.character != null) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error),
              icon: const Icon(Icons.delete_outline),
              label: const Text('删除角色'),
              onPressed: _delete,
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  ImageProvider? _avatarProvider() {
    final pending = _pendingAvatar;
    if (pending != null) return MemoryImage(pending);
    final path = _character.avatarPath;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return FileImage(File(path));
    }
    return null;
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.pickFile(type: FileType.image);
    if (result == null) return;
    final bytes = await result.xFile.readAsBytes();
    if (!mounted) return;
    setState(() => _pendingAvatar = bytes);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('名字不能为空')));
      return;
    }
    final repo = ref.read(characterRepositoryProvider);
    var character = _character.copyWith(
      name: name,
      description: _description.text,
      personality: _personality.text,
      scenario: _scenario.text,
      firstMessage: _firstMessage.text,
      exampleDialogue: _exampleDialogue.text,
    );
    final pending = _pendingAvatar;
    if (pending != null) {
      final path = await repo.saveAvatar(character.id, pending);
      character = character.copyWith(avatarPath: path);
    }
    await repo.save(character);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除角色'),
        content: Text(
            '确定删除「${_character.name}」？已绑定的会话将转为普通聊天，不再按 TA 的人设回复。'),
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
      await ref.read(characterRepositoryProvider).delete(_character.id);
      if (mounted) Navigator.of(context).pop();
    }
  }
}
