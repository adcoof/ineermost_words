/// 桌宠试衣间：大预览 + 手动触发表情/动作 + 进入映射编辑。
library;

import 'package:flutter/material.dart';

import '../data/pet_controller_webview.dart';
import '../data/pet_model_repository.dart';
import '../domain/pet_command.dart';
import '../domain/pet_model.dart';
import 'mapping_editor_page.dart';
import 'pet_webview.dart';

class PetPreviewPage extends StatefulWidget {
  final PetModel model;
  final PetModelRepository repo;

  const PetPreviewPage({super.key, required this.model, required this.repo});

  @override
  State<PetPreviewPage> createState() => _PetPreviewPageState();
}

class _PetPreviewPageState extends State<PetPreviewPage> {
  late final PetControllerWebview _controller;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _controller = PetControllerWebview();
    _controller.events.listen((e) {
      if (!mounted) return;
      setState(() {
        if (e.type == 'error') _lastError = e.message;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  PetModel get model => widget.model;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(model.name),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.tune),
            label: const Text('映射编辑'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    MappingEditorPage(model: model, repo: widget.repo, controller: _controller),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: PetWebView(
                      controller: _controller,
                      entryJsonPath: model.entryJsonPath),
                ),
                if (_lastError != null)
                  Positioned(
                    left: 8, right: 8, top: 8,
                    child: Material(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text('加载错误：$_lastError',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildControls(context),
          const Padding(
            padding: EdgeInsets.only(bottom: 8, top: 2),
            child: Text('Powered by Live2D Cubism SDK',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('复位表情'),
            onPressed: () =>
                _controller.executeReset(),
          ),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.mood),
            label: Text('表情（${model.expressions.length}）'),
            onPressed: model.expressions.isEmpty
                ? null
                : () => _pickExpression(context),
          ),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.directions_run),
            label: Text('动作（${model.motionGroups.length} 组）'),
            onPressed: model.motionGroups.isEmpty
                ? null
                : () => _pickMotion(context),
          ),
        ],
      ),
    );
  }

  Future<void> _pickExpression(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            for (final e in model.expressions)
              ListTile(
                title: Text(e),
                onTap: () => Navigator.pop(context, e),
              ),
          ],
        ),
      ),
    );
    if (selected != null) {
      await _controller.execute(PetCommand.expression(selected));
    }
  }

  /// 动作选择器：列出每个具体动作（组名 · 序号），点选即播。
  Future<void> _pickMotion(BuildContext context) async {
    final entries = <MapEntry<String, int>>[
      for (final g in model.motionGroups.entries)
        for (var i = 0; i < g.value; i++) MapEntry(g.key, i),
    ];
    final selected = await showModalBottomSheet<MapEntry<String, int>>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final e in entries)
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: Text('${e.key} · ${e.value + 1}'),
                subtitle: Text('${e.key} 组第 ${e.value + 1} 个动作'),
                onTap: () => Navigator.pop(context, e),
              ),
          ],
        ),
      ),
    );
    if (selected != null) {
      await _controller.execute(
          PetCommand.motion(selected.key, index: selected.value));
    }
  }
}

extension on PetControllerWebview {
  Future<void> execute(PetCommand command) async {
    switch (command.type) {
      case PetCommandType.setExpression:
        await setExpression(command.expressionId);
      case PetCommandType.startMotion:
        await startMotion(command.motionGroup,
            index: command.motionIndex, priority: command.priority);
      case PetCommandType.setLipSync:
        await setLipSync(command.lipSyncValue);
    }
  }

  Future<void> executeReset() => setExpression('');
}
