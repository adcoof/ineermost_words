/// 表情包仓库：每角色一个库，按固定心情键分组，一心情可多张。
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/painting.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/id.dart';
import '../../../core/utils/image_utils.dart';
import '../../../data/local/app_database.dart';

/// 系统写死的心情键列表（英文情绪标签值 → 中文标签）。
/// 与 PromptAssembler 的 emotion 词表保持一致。
const Map<String, String> kStickerMoods = {
  'happy': '喜',
  'angry': '怒',
  'sad': '哀',
  'amused': '乐',
  'confused': '疑惑',
  'shy': '害羞',
  'surprised': '惊讶',
  'smug': '得意',
  'speechless': '无语',
  'scared': '害怕',
  'crying': '哭泣',
  'loving': '爱心',
  'thinking': '思考',
  'sleepy': '困倦',
};

/// 心情兜底链：主键无贴纸时依次尝试的近义心情。
const Map<String, List<String>> kMoodFallbacks = {
  'crying': ['sad'],
  'loving': ['happy'],
  'smug': ['amused', 'happy'],
  'confused': ['surprised'],
  'scared': ['surprised'],
  'amused': ['happy'],
};

class StickerRepository {
  final AppDatabase db;

  StickerRepository(this.db);

  /// 单张贴纸降采样后的长边上限（贴纸不需要大图）。
  static const int kStickerMaxDim = 512;

  Stream<List<StickerRow>> watchByCharacter(String characterId) {
    final q = db.select(db.stickers)
      ..where((t) => t.characterId.equals(characterId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return q.watch();
  }

  /// 批量添加贴纸（自动降采样 JPEG），返回落盘路径列表。
  ///
  /// [root] 注入便于纯单测（测试环境 path_provider 会 MissingPluginException）。
  Future<List<String>> addStickers(
    String characterId,
    String mood,
    List<Uint8List> images, {
    Directory? root,
  }) async {
    if (images.isEmpty) return const [];
    final dir =
        root ??
        Directory(
          p.join(
            (await getApplicationDocumentsDirectory()).path,
            'stickers',
            characterId,
          ),
        );
    await dir.create(recursive: true);
    final paths = <String>[];
    for (final bytes in images) {
      final id = newId();
      final file = File(p.join(dir.path, '$id.jpg'));
      await file.writeAsBytes(
        downscaleToJpeg(bytes, maxDim: kStickerMaxDim),
        flush: true,
      );
      await db
          .into(db.stickers)
          .insert(
            StickersCompanion(
              id: Value(id),
              characterId: Value(characterId),
              mood: Value(mood),
              filePath: Value(file.path),
              createdAt: Value(DateTime.now()),
            ),
          );
      paths.add(file.path);
    }
    return paths;
  }

  /// 删除单张贴纸（行 + 文件 + 图片缓存）。
  Future<void> delete(String id) async {
    final q = db.select(db.stickers)..where((t) => t.id.equals(id));
    final row = await q.getSingleOrNull();
    if (row == null) return;
    await (db.delete(db.stickers)..where((t) => t.id.equals(id))).go();
    try {
      final file = File(row.filePath);
      if (await file.exists()) await file.delete();
      await FileImage(file).evict();
    } catch (_) {
      // 文件删除失败不影响行删除。
    }
  }

  /// 为角色+心情挑一张贴纸：本心情随机一张；无则走近义兜底链；再无返回 null。
  Future<String?> pickForMood(String characterId, String mood) async {
    final direct = await _randomFilePath(characterId, mood);
    if (direct != null) return direct;
    for (final alt in kMoodFallbacks[mood] ?? const <String>[]) {
      final hit = await _randomFilePath(characterId, alt);
      if (hit != null) return hit;
    }
    return null;
  }

  Future<String?> _randomFilePath(String characterId, String mood) async {
    final q = db.select(db.stickers)
      ..where((t) => t.characterId.equals(characterId) & t.mood.equals(mood));
    final rows = await q.get();
    if (rows.isEmpty) return null;
    final picked = rows[DateTime.now().microsecondsSinceEpoch % rows.length];
    return File(picked.filePath).existsSync() ? picked.filePath : null;
  }
}
