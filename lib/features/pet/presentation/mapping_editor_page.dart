/// 映射编辑器：标签 → 表情/动作 的映射表，含试触发。
///
/// 列出全局（对所有模型生效）+ 当前模型级映射；下拉框展示模型
/// 真实的表情 id 与动作组，避免手输错误。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../data/pet_controller_webview.dart';
import '../data/pet_model_repository.dart';
import '../domain/pet_command.dart';
import '../domain/pet_model.dart';

class MappingEditorPage extends ConsumerStatefulWidget {
  final PetModel model;
  final PetModelRepository repo;
  final PetControllerWebview controller;

  const MappingEditorPage({
    super.key,
    required this.model,
    required this.repo,
    required this.controller,
  });

  @override
  ConsumerState<MappingEditorPage> createState() => _MappingEditorPageState();
}

class _MappingEditorPageState extends ConsumerState<MappingEditorPage> {
  @override
  void initState() {
    super.initState();
    // 保证有内置默认映射可编辑。
    widget.repo.seedDefaultMappings();
  }

  PetModel get model => widget.model;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('映射 · ${model.name}')),
      body: StreamBuilder<List<EmotionMapping>>(
        stream: widget.repo.watchMappings(model.id),
        builder: (context, snapshot) {
          final mappings = snapshot.data ?? const [];
          if (mappings.isEmpty) {
            return const Center(child: Text('暂无映射，点右下角添加'));
          }
          return ListView.separated(
            itemCount: mappings.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final m = mappings[index];
              final isModelLevel = m.petModelId != null;
              return ListTile(
                title: Text('<${m.tag}> → ${m.actionType} · ${m.targetId}'),
                subtitle: Text(
                  '优先级 ${m.priority} · ${isModelLevel ? '本模型' : '全局'}',
                ),
                leading: isModelLevel
                    ? const Icon(Icons.smart_toy_outlined)
                    : const Icon(Icons.public),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: '试触发',
                      icon: const Icon(Icons.play_arrow),
                      onPressed: () => _test(m),
                    ),
                    Switch(
                      value: m.enabled,
                      onChanged: (v) =>
                          widget.repo.saveMapping(m.copyWith(enabled: v)),
                    ),
                    IconButton(
                      tooltip: '删除',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(m),
                    ),
                  ],
                ),
                onTap: () => _edit(m),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(null),
        icon: const Icon(Icons.add),
        label: const Text('添加映射'),
      ),
    );
  }

  Future<void> _test(EmotionMapping m) async {
    // 走与真实事件相同的适配链（大小写容错/组校验/兜底），
    // 避免试触发与实际执行行为分叉。
    final command = await widget.repo.resolveForMapping(m, model.id);
    if (!mounted) return;
    if (command == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该映射在当前模型上无法执行（目标不存在或已禁用）')),
      );
      return;
    }
    switch (command.type) {
      case PetCommandType.setExpression:
        await widget.controller.setExpression(command.expressionId);
      case PetCommandType.startMotion:
        await widget.controller.startMotion(command.motionGroup,
            index: command.motionIndex, priority: command.priority);
      case PetCommandType.setLipSync:
        await widget.controller.setLipSync(command.lipSyncValue);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已触发：$command'), duration: const Duration(seconds: 1)),
      );
    }
  }

  Future<void> _confirmDelete(EmotionMapping m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除映射'),
        content: Text('删除 <${m.tag}> → ${m.targetId}？'),
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
    if (ok == true) await widget.repo.deleteMapping(m.id);
  }

  /// 新建/编辑映射对话框。
  Future<void> _edit(EmotionMapping? existing) async {
    final tagCtrl = TextEditingController(text: existing?.tag ?? '');
    var actionType = existing?.actionType ?? 'expression';
    var targetId = existing?.targetId ??
        (model.expressions.isNotEmpty
            ? model.expressions.first
            : (model.motionGroups.keys.isNotEmpty
                ? '${model.motionGroups.keys.first}:0'
                : ''));
    var priority = existing?.priority ?? 1;
    var modelLevel = existing?.petModelId != null;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final targets = actionType == 'expression'
              ? model.expressions
              : [
                  for (final g in model.motionGroups.entries)
                    for (var i = 0; i < g.value; i++) '${g.key}:$i',
                ];
          return AlertDialog(
            title: Text(existing == null ? '添加映射' : '编辑映射'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: tagCtrl,
                    decoration: const InputDecoration(
                      labelText: '标签（如 happy / wave）',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'expression', label: Text('表情')),
                      ButtonSegment(value: 'motion', label: Text('动作')),
                    ],
                    selected: {actionType},
                    onSelectionChanged: (s) => setDialogState(() {
                      actionType = s.first;
                      targetId = targets.isNotEmpty ? targets.first : '';
                    }),
                  ),
                  const SizedBox(height: 12),
                  if (targets.isEmpty)
                    const Text('该模型没有可选的表情/动作',
                        style: TextStyle(color: Colors.grey))
                  else
                    DropdownButtonFormField<String>(
                      // key 随候选变化重建，绕过 initialValue 只生效一次的限制。
                      key: ValueKey('$actionType:${targets.join(',')}'),
                      initialValue:
                          targets.contains(targetId) ? targetId : targets.first,
                      decoration: const InputDecoration(
                        labelText: '目标',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final t in targets)
                          DropdownMenuItem(value: t, child: Text(t)),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => targetId = v ?? targetId),
                    ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: priority,
                    decoration: const InputDecoration(
                      labelText: '优先级（动作掩蔽用）',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1（低）')),
                      DropdownMenuItem(value: 2, child: Text('2（中）')),
                      DropdownMenuItem(value: 3, child: Text('3（高）')),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => priority = v ?? priority),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('仅本模型（关闭=全局）'),
                    value: modelLevel,
                    onChanged: (v) => setDialogState(() => modelLevel = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消')),
              FilledButton(
                onPressed: () {
                  final tag = tagCtrl.text.trim();
                  if (tag.isEmpty || targetId.isEmpty) return;
                  final mapping = EmotionMapping(
                    id: existing?.id ?? const Uuid().v4(),
                    petModelId: modelLevel ? model.id : null,
                    tag: tag,
                    actionType: actionType,
                    targetId: targetId,
                    priority: priority,
                    enabled: existing?.enabled ?? true,
                  );
                  // ignore: discarded_futures
                  widget.repo.saveMapping(mapping);
                  Navigator.pop(context);
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
    if (!mounted) return;
    // ref 用于刷新外层 StreamBuilder（saveMapping 已触发流，无需额外操作）。
    ref.read(petModelRepositoryProvider);
  }
}
