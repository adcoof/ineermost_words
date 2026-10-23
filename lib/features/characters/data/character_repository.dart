/// 角色卡仓库：CRUD + 头像文件管理 + ST 卡导入落库。
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/painting.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/id.dart';
import '../../../data/local/app_database.dart';
import '../domain/character.dart';
import 'silly_tavern_importer.dart';

class CharacterRepository {
  final AppDatabase db;
  final SillyTavernImporter _importer;

  CharacterRepository(this.db, {SillyTavernImporter? importer})
      : _importer = importer ?? const SillyTavernImporter();

  Stream<List<Character>> watchCharacters() {
    final q = db.select(db.characters)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    return q.watch().map((rows) => rows.map(_fromRow).toList());
  }

  Future<Character?> getById(String id) async {
    final q = db.select(db.characters)..where((t) => t.id.equals(id));
    final row = await q.getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// 新建或更新（按 id upsert）。
  Future<void> save(Character character) async {
    await db.into(db.characters).insertOnConflictUpdate(_toRow(character));
  }

  /// 创建一个空角色（编辑页新建时用）。
  Character blank() {
    final now = DateTime.now();
    return Character(id: newId(), name: '', createdAt: now, updatedAt: now);
  }

  Future<void> delete(String id) async {
    final character = await getById(id);
    await (db.delete(db.characters)..where((t) => t.id.equals(id))).go();
    final avatar = character?.avatarPath;
    if (avatar != null && avatar.isNotEmpty) {
      try {
        final file = File(avatar);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // 文件删除失败不影响角色删除。
      }
    }
  }

  /// 导入 ST 角色卡字节并落库；PNG 卡整图存为立绘。
  Future<Character> importFromBytes(Uint8List bytes) async {
    final draft = _importer.parse(bytes);
    var character = blank().copyWith(
      name: draft.name,
      description: draft.description,
      personality: draft.personality,
      scenario: draft.scenario,
      firstMessage: draft.firstMessage,
      exampleDialogue: draft.exampleDialogue,
    );
    character = _withSource(character, 'st_v2');
    await db.into(db.characters).insertOnConflictUpdate(_toRow(character));
    if (draft.pngBytes != null) {
      try {
        final avatarPath = await saveAvatar(character.id, draft.pngBytes!);
        character = character.copyWith(avatarPath: avatarPath);
        await db.into(db.characters).insertOnConflictUpdate(_toRow(character));
      } catch (e) {
        // 头像写入失败：回滚已插入的角色行与文件，避免半导入状态
        //（用户看到「导入失败」却在列表里发现角色）。
        await delete(character.id);
        rethrow;
      }
    }
    return character;
  }

  /// 保存头像字节到 documents/characters/{id}/avatar.png，返回绝对路径。
  ///
  /// FileImage 按路径缓存，覆盖同名文件后必须 evict，
  /// 否则 UI 继续显示旧图。
  Future<String> saveAvatar(String characterId, Uint8List bytes) async {
    final dir = Directory(p.join(
        (await getApplicationDocumentsDirectory()).path, 'characters', characterId));
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, 'avatar.png'));
    await file.writeAsBytes(bytes, flush: true);
    await FileImage(file).evict();
    return file.path;
  }

  Character _withSource(Character c, String source) => Character(
        id: c.id,
        name: c.name,
        description: c.description,
        personality: c.personality,
        scenario: c.scenario,
        firstMessage: c.firstMessage,
        exampleDialogue: c.exampleDialogue,
        avatarPath: c.avatarPath,
        source: source,
        createdAt: c.createdAt,
        updatedAt: c.updatedAt,
      );

  Character _fromRow(CharacterRow row) => Character(
        id: row.id,
        name: row.name,
        description: row.description,
        personality: row.personality,
        scenario: row.scenario,
        firstMessage: row.firstMessage,
        exampleDialogue: row.exampleDialogue,
        avatarPath: row.avatarPath,
        source: row.source,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  CharactersCompanion _toRow(Character c) => CharactersCompanion(
        id: Value(c.id),
        name: Value(c.name),
        description: Value(c.description),
        personality: Value(c.personality),
        scenario: Value(c.scenario),
        firstMessage: Value(c.firstMessage),
        exampleDialogue: Value(c.exampleDialogue),
        avatarPath: Value(c.avatarPath),
        source: Value(c.source),
        createdAt: Value(c.createdAt),
        updatedAt: Value(c.updatedAt),
      );
}
