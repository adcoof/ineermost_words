/// 桌宠页：模型列表、zip 导入、进入试衣间。
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/pet_model_importer.dart';
import '../data/pet_model_repository.dart';
import '../domain/pet_model.dart';
import 'pet_preview_page.dart';

class PetPage extends ConsumerStatefulWidget {
  const PetPage({super.key});

  @override
  ConsumerState<PetPage> createState() => _PetPageState();
}

class _PetPageState extends ConsumerState<PetPage> {
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(petModelRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('桌宠'),
        actions: [
          IconButton(
            tooltip: '导入模型包（zip）',
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: _importing ? null : () => _importZip(repo),
          ),
        ],
      ),
      body: StreamBuilder<List<PetModel>>(
        stream: repo.watchModels(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final models = snapshot.data ?? const [];
          if (models.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '还没有桌宠模型\n点右上角导入 Live2D 模型包（zip，需含 .moc3 与 model3.json）',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: models.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final m = models[index];
                    return ListTile(
                      leading: const CircleAvatar(
                          child: Icon(Icons.pets_outlined)),
                      title:
                          Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '表情 ${m.expressions.length} · 动作组 ${m.motionGroups.length}',
                      ),
                      trailing: IconButton(
                        tooltip: '删除',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(repo, m),
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              PetPreviewPage(model: m, repo: repo),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Live2D 模型相关内容由 Live2D Cubism SDK 渲染 · Powered by Live2D',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _importZip(PetModelRepository repo) async {
    setState(() => _importing = true);
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (picked == null) return;
      final bytes = await picked.xFile.readAsBytes();
      final model = await PetModelImporter().importZip(bytes);
      await repo.saveModel(model);
      await repo.seedDefaultMappings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导入桌宠「${model.name}」')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('导入失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _confirmDelete(
      PetModelRepository repo, PetModel model) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除桌宠'),
        content: Text('确定删除「${model.name}」及其模型文件？'),
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
    if (ok == true) await repo.deleteModel(model.id);
  }
}
