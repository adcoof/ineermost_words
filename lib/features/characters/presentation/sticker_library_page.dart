/// 角色表情包库管理页（v8）：按固定心情分组上传/删除贴纸。
///
/// 心情列表系统写死（kStickerMoods，14 项）；一心情可多张，
/// 聊天时按角色回复的最后一个情绪标签随机取一张自动发送。
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/local/app_database.dart';
import '../../chat/data/sticker_repository.dart';

class StickerLibraryPage extends ConsumerWidget {
  final String characterId;

  const StickerLibraryPage({super.key, required this.characterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('表情包库')),
      body: StreamBuilder<List<StickerRow>>(
        stream: ref
            .read(stickerRepositoryProvider)
            .watchByCharacter(characterId),
        builder: (context, snapshot) {
          final all = snapshot.data ?? const <StickerRow>[];
          final byMood = <String, List<StickerRow>>{
            for (final m in kStickerMoods.keys) m: [],
          };
          for (final s in all) {
            byMood[s.mood]?.add(s);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '为每个心情上传贴纸，角色回复带对应情绪时会自动发一张。'
                '没有完全匹配的心情时会自动借用相近心情（如「哭泣」借用「哀」）。',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 12),
              for (final entry in kStickerMoods.entries) ...[
                _MoodSection(
                  characterId: characterId,
                  mood: entry.key,
                  label: entry.value,
                  stickers: byMood[entry.key] ?? const [],
                ),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MoodSection extends ConsumerWidget {
  final String characterId;
  final String mood;
  final String label;
  final List<StickerRow> stickers;

  const _MoodSection({
    required this.characterId,
    required this.mood,
    required this.label,
    required this.stickers,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${stickers.length} 张',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
              const Spacer(),
              _AddButton(characterId: characterId, mood: mood),
            ],
          ),
          const SizedBox(height: 8),
          if (stickers.isEmpty)
            Text(
              '暂无贴纸',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withValues(alpha: 0.35),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in stickers)
                  GestureDetector(
                    onLongPress: () => _confirmDelete(context, ref, s),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(s.filePath),
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 72,
                          height: 72,
                          color: scheme.errorContainer,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    StickerRow row,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除「$label」贴纸？'),
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
      await ref.read(stickerRepositoryProvider).delete(row.id);
    }
  }
}

class _AddButton extends ConsumerWidget {
  final String characterId;
  final String mood;

  const _AddButton({required this.characterId, required this.mood});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: '添加贴纸',
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
      onPressed: () => _pick(context, ref),
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final files = await FilePicker.pickFiles(type: FileType.image);
    if (files.isEmpty) return;
    final bytes = <Uint8List>[];
    for (final f in files) {
      bytes.add(await f.xFile.readAsBytes());
    }
    await ref
        .read(stickerRepositoryProvider)
        .addStickers(characterId, mood, bytes);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已添加 ${bytes.length} 张「$mood」贴纸'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}
