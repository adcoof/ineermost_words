/// 自定义音色（音色工坊）：用一句话描述定义音色，新建/编辑/试听/删除。
///
/// 描述合成走 mimo-v2.5-tts-voicedesign（MiMo 云端）：描述进 user 消息、
/// 文本进 assistant 消息，无需音色 ID。选中后的音色以 `custom:<id>` 存进
/// TTS 配置，在语音设置的发音人下拉里与其他发音人并列。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/custom_voice_repository.dart';

/// 试听默认文本。
const _defaultSample = '你好呀，今天过得怎么样？我一直在等你回来。';

class VoiceDesignPage extends ConsumerWidget {
  const VoiceDesignPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(customVoiceRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('自定义音色')),
      body: StreamBuilder<List<CustomVoice>>(
        stream: repo.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final voices = snapshot.data ?? const [];
          if (voices.isEmpty) {
            return const Center(
              child: Text('还没有自定义音色\n用一句话描述想要的声音，点下方按钮新建',
                  textAlign: TextAlign.center),
            );
          }
          return ListView.separated(
            itemCount: voices.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final v = voices[index];
              return ListTile(
                leading: const Icon(Icons.graphic_eq),
                title: Text(v.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(v.description,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  tooltip: '删除',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, ref, v),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => VoiceDesignEditPage(voice: v)),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-voice-design',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const VoiceDesignEditPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('新建音色'),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, CustomVoice voice) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除「${voice.name}」？'),
        content: const Text('删除后发音人列表里不再显示该音色。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(customVoiceRepositoryProvider).delete(voice.id);
  }
}

/// 新建/编辑音色：名称 + 描述 + 试听 + 保存。
class VoiceDesignEditPage extends ConsumerStatefulWidget {
  /// 为空表示新建。
  final CustomVoice? voice;

  const VoiceDesignEditPage({super.key, this.voice});

  @override
  ConsumerState<VoiceDesignEditPage> createState() =>
      _VoiceDesignEditPageState();
}

class _VoiceDesignEditPageState extends ConsumerState<VoiceDesignEditPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _sampleController;
  bool _saving = false;

  bool get _isEdit => widget.voice != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.voice?.name ?? '');
    _descController =
        TextEditingController(text: widget.voice?.description ?? '');
    _sampleController = TextEditingController(text: _defaultSample);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _sampleController.dispose();
    super.dispose();
  }

  /// 试听：用当前描述直接合成（不必先保存），语速跟随全局设置。
  Future<void> _preview() async {
    final desc = _descController.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请先填写音色描述')));
      return;
    }
    final speed = await ref.read(ttsProfileRepositoryProvider).voiceSpeed();
    if (!mounted) return;
    final sample = _sampleController.text.trim();
    final queue = ref.read(voiceOrchestratorProvider).queue;
    queue.clear();
    queue.enqueue(sample.isEmpty ? _defaultSample : sample,
        speed: speed, voiceDesign: desc);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();
    if (name.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('名称和描述都不能为空')));
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(customVoiceRepositoryProvider);
      final existing = widget.voice;
      final now = DateTime.now();
      await repo.save(CustomVoice(
        id: existing?.id ?? repo.newVoiceId(),
        name: name,
        description: desc,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ));
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除「${widget.voice!.name}」？'),
        content: const Text('删除后发音人列表里不再显示该音色。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(customVoiceRepositoryProvider).delete(widget.voice!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '编辑音色' : '新建音色'),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: '删除',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '音色名称',
              hintText: '如：萝莉音、磁性男声',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: '音色描述',
              hintText: '如：温柔甜美的年轻女声，语速稍慢，像在耳边轻轻说话',
              helperText: '描述越具体越准确，可用「低沉」「清亮」「少年感」「慵懒」等词组合',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _sampleController,
            decoration: const InputDecoration(
              labelText: '试听文本',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('试听'),
                  onPressed: () => unawaited(_preview()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_saving ? '保存中…' : '保存'),
                  onPressed: _saving ? null : () => unawaited(_save()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '保存后，在「语音设置 → 发音人」里选择该音色即可用于朗读。音色由 MiMo 云端定制合成。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
