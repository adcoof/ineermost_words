/// 角色卡仓库：CRUD + 头像文件管理 + ST 卡导入落库。
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/painting.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/id.dart';
import '../../../data/local/app_database.dart';
import '../domain/character.dart';
import '../domain/character_extensions.dart';
import '../domain/character_import_result.dart';
import '../domain/character_profile.dart';
import '../domain/character_version.dart';
import '../domain/memory_fact.dart';
import 'lore_repository.dart';
import 'silly_tavern_importer.dart';

/// 每角色保留的版本快照数量。
const int kCharacterVersionMax = 20;

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

  /// 一次性读取全部角色（资产页选角色用）。
  ///
  /// UI 里不要用 `watchCharacters().first` 等首帧：widget 测试的 FakeAsync
  /// 不会自动推进 drift watch，容易挂死；一次性查询更直接。
  Future<List<Character>> listCharacters() async {
    final rows = await (db.select(db.characters)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<Character?> getById(String id) async {
    final q = db.select(db.characters)..where((t) => t.id.equals(id));
    final row = await q.getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// 新建或更新（按 id upsert）。
  ///
  /// 更新已有角色时，先把旧状态存成版本快照（内容未变则跳过），
  /// 再写新值；新建不产生空快照。
  Future<void> save(Character character) async {
    await db.transaction(() async {
      final existing = await getById(character.id);
      if (existing != null) {
        final oldSnapshot = _snapshotJson(existing);
        final newSnapshot = _snapshotJson(character);
        // 内容没变（仅 updatedAt 变化）不产生快照。
        if (oldSnapshot != newSnapshot) {
          final latest = await _latestVersion(character.id);
          if (latest == null || latest.snapshotJson != oldSnapshot) {
            await _insertVersion(character.id, oldSnapshot, 'save');
          }
        }
      }
      await db.into(db.characters).insertOnConflictUpdate(_toRow(character));
    });
  }

  /// 创建一个空角色（编辑页新建时用）。
  Character blank() {
    final now = DateTime.now();
    return Character(id: newId(), name: '', createdAt: now, updatedAt: now);
  }

  /// 读取角色跨会话记忆（记忆摘要、用户画像与水位线）。
  ///
  /// 记忆列不进 Character 领域模型：save() 是整行 upsert，
  /// 若领域模型带记忆字段，编辑角色卡会用陈旧值覆盖 summarizer 刚写入的记忆。
  Future<({String summary, String userSummary, DateTime? updatedAt})> getMemory(
      String characterId) async {
    final q = db.select(db.characters)..where((t) => t.id.equals(characterId));
    final row = await q.getSingleOrNull();
    if (row == null) return (summary: '', userSummary: '', updatedAt: null);
    return (
      summary: row.memorySummary,
      userSummary: row.userSummary,
      updatedAt: row.memoryUpdatedAt,
    );
  }

  /// 更新记忆、用户画像与水位线（只写这三列）。角色已删时静默无操作。
  Future<void> setMemory(
    String characterId, {
    required String summary,
    String userSummary = '',
    required DateTime updatedAt,
  }) async {
    await (db.update(db.characters)..where((t) => t.id.equals(characterId)))
        .write(CharactersCompanion(
      memorySummary: Value(summary),
      userSummary: Value(userSummary),
      memoryUpdatedAt: Value(updatedAt),
    ));
  }

  /// 该角色各会话已摘要到的时间点（v9）。
  Future<Map<String, DateTime>> getMemoryCursors(String characterId) async {
    final rows =
        await (db.select(db.memoryCursors)
              ..where((t) => t.characterId.equals(characterId)))
            .get();
    return {for (final r in rows) r.conversationId: r.summarizedAt};
  }

  /// 推进单个会话的记忆游标（只写摘要成功后的水位线）。
  Future<void> setMemoryCursor(
    String characterId,
    String conversationId,
    DateTime summarizedAt,
  ) async {
    await db.into(db.memoryCursors).insertOnConflictUpdate(
      MemoryCursorsCompanion.insert(
        characterId: characterId,
        conversationId: conversationId,
        summarizedAt: summarizedAt,
      ),
    );
  }

  /// 该角色的长期事实，按发生日期倒序（同一天按入库时间倒序）。
  Future<List<MemoryFact>> getMemoryFacts(
    String characterId, {
    int limit = 240,
  }) async {
    final q = db.select(db.memoryFacts)
      ..where((t) => t.characterId.equals(characterId))
      ..orderBy([
        (t) => OrderingTerm.desc(t.occurredAt),
        (t) => OrderingTerm.desc(t.createdAt),
      ])
      ..limit(limit);
    return (await q.get()).map(_factFromRow).toList();
  }

  /// 插入一条事实并裁剪到每角色 240 条上限（超额淘汰发生日期最旧的）。
  Future<MemoryFact> addMemoryFact({
    required String characterId,
    required String fact,
    required DateTime occurredAt,
    String? sourceConversationId,
    DateTime? createdAt,
  }) async {
    final f = MemoryFact(
      id: newId(),
      characterId: characterId,
      fact: fact,
      occurredAt: occurredAt,
      sourceConversationId: sourceConversationId,
      createdAt: createdAt ?? DateTime.now(),
    );
    await db.transaction(() async {
      await db.into(db.memoryFacts).insert(
        MemoryFactsCompanion.insert(
          id: f.id,
          characterId: f.characterId,
          fact: f.fact,
          occurredAt: f.occurredAt,
          sourceConversationId: Value(f.sourceConversationId),
          createdAt: f.createdAt,
        ),
      );
      await _trimMemoryFacts(characterId);
    });
    return f;
  }

  Future<void> deleteMemoryFact(String id) async {
    await (db.delete(db.memoryFacts)..where((t) => t.id.equals(id))).go();
  }

  Future<void> _trimMemoryFacts(String characterId) async {
    final rows = await (db.select(db.memoryFacts)
          ..where((t) => t.characterId.equals(characterId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.occurredAt),
            (t) => OrderingTerm.desc(t.createdAt),
          ])
          ..limit(1000))
        .get();
    if (rows.length <= kMemoryFactsMax) return;
    final stale = rows.skip(kMemoryFactsMax).map((r) => r.id).toList();
    await (db.delete(db.memoryFacts)..where((t) => t.id.isIn(stale))).go();
  }

  Future<void> delete(String id) async {
    final character = await getById(id);
    await (db.delete(db.characters)..where((t) => t.id.equals(id))).go();
    // 级联清理版本快照（v17）。
    await (db.delete(db.characterVersions)
          ..where((t) => t.characterId.equals(id)))
        .go();
    // 级联清理表情包（v8）：库行 + 目录。
    await (db.delete(db.stickers)..where((t) => t.characterId.equals(id)))
        .go();
    try {
      final docs = await getApplicationDocumentsDirectory();
      final stickerDir = Directory(p.join(docs.path, 'stickers', id));
      if (await stickerDir.exists()) {
        await stickerDir.delete(recursive: true);
      }
    } catch (_) {
      // 目录删除失败不影响角色删除。
    }
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
  ///
  /// 返回完整结果（格式、世界书数量、保留字段数、警告），供 UI 展示；
  /// 兼容旧调用方保留 [importFromBytes]。
  Future<CharacterImportResult> importCard(Uint8List bytes) async {
    final draft = _importer.parse(bytes);
    final warnings = [...draft.warnings];
    var character = blank().copyWith(
      name: draft.name,
      description: draft.description,
      personality: draft.personality,
      scenario: draft.scenario,
      firstMessage: draft.firstMessage,
      exampleDialogue: draft.exampleDialogue,
      alternateGreetings: draft.alternateGreetings,
      profile: draft.profile,
      extensions: draft.extensions,
      source: _sourceOf(draft.format),
    );
    await db.into(db.characters).insertOnConflictUpdate(_toRow(character));
    var loreCount = 0;
    if (draft.loreDrafts.isNotEmpty) {
      try {
        loreCount = await LoreRepository(db).importDrafts(
          character.id,
          [
            for (final d in draft.loreDrafts)
              LoreImportDraft(
                keys: d.keys,
                content: d.content,
                position: d.position,
                depth: d.depth,
                priority: d.priority,
                sourceJson: d.sourceJson,
              ),
          ],
        );
      } catch (e) {
        // 世界书导入失败不应让整张角色卡导入失败。
        warnings.add('世界书导入失败：$e');
      }
    }
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
    return CharacterImportResult(
      character: character,
      format: draft.format,
      loreCount: loreCount,
      preservedKeyCount: draft.preservedKeyCount,
      warnings: warnings,
    );
  }

  /// 兼容旧调用方：只返回角色。
  Future<Character> importFromBytes(Uint8List bytes) async =>
      (await importCard(bytes)).character;

  String _sourceOf(String format) => switch (format) {
    'v3' => 'st_v3',
    'v2' => 'st_v2',
    'v1' => 'st_v1',
    _ => 'st_v2',
  };

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

  Character _fromRow(CharacterRow row) => Character(
        id: row.id,
        name: row.name,
        description: row.description,
        personality: row.personality,
        scenario: row.scenario,
        firstMessage: row.firstMessage,
        exampleDialogue: row.exampleDialogue,
        alternateGreetings: _decodeStringList(row.alternateGreetings),
        avatarPath: row.avatarPath,
        source: row.source,
        profile: CharacterProfile.decode(row.profileJson),
        extensions: CharacterExtensions.decode(row.extensionsJson),
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  List<String> _decodeStringList(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
      }
    } catch (_) {
      // 坏数据按空列表处理。
    }
    return const [];
  }

  MemoryFact _factFromRow(MemoryFactRow row) => MemoryFact(
        id: row.id,
        characterId: row.characterId,
        fact: row.fact,
        occurredAt: row.occurredAt,
        sourceConversationId: row.sourceConversationId,
        createdAt: row.createdAt,
      );

  CharactersCompanion _toRow(Character c) => CharactersCompanion(
        id: Value(c.id),
        name: Value(c.name),
        description: Value(c.description),
        personality: Value(c.personality),
        scenario: Value(c.scenario),
        firstMessage: Value(c.firstMessage),
        exampleDialogue: Value(c.exampleDialogue),
        alternateGreetings: Value(jsonEncode(c.alternateGreetings)),
        avatarPath: Value(c.avatarPath),
        source: Value(c.source),
        profileJson: Value(c.profile.encode()),
        extensionsJson: Value(c.extensions.encode()),
        createdAt: Value(c.createdAt),
        updatedAt: Value(c.updatedAt),
      );

  // ── 版本快照（v2.1）────────────────────────────────────────────────

  /// 角色版本列表，按毫秒时间倒序。
  Future<List<CharacterVersion>> listVersions(
    String characterId, {
    int limit = kCharacterVersionMax,
  }) async {
    final rows = await (db.select(db.characterVersions)
          ..where((t) => t.characterId.equals(characterId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAtMs)])
          ..limit(limit))
        .get();
    return rows.map(_versionFromRow).toList();
  }

  /// 手动存一个当前版本（即使与上一条相同也保留，作为显式检查点）。
  Future<bool> createVersion(String characterId, {String label = ''}) async {
    final character = await getById(characterId);
    if (character == null) return false;
    await _insertVersion(
      characterId,
      _snapshotJson(character),
      'manual',
      label: label,
    );
    return true;
  }

  /// 恢复某条版本：先把当前状态存成 `restore` 快照，再写回旧值。
  ///
  /// 立绘不参与回滚（按角色 id 固定路径）；角色已删除时返回 false。
  Future<bool> restoreVersion(String versionId) async {
    final row = await (db.select(db.characterVersions)
          ..where((t) => t.id.equals(versionId)))
        .getSingleOrNull();
    if (row == null) return false;
    final current = await getById(row.characterId);
    if (current == null) return false;
    final snapshot = _versionFromRow(row).snapshot;
    // 坏快照直接拒绝，避免用空对象覆盖现有角色。
    if (snapshot.isEmpty) return false;
    await db.transaction(() async {
      await _insertVersion(current.id, _snapshotJson(current), 'restore');
      final restored = _applySnapshot(current, snapshot);
      await db.into(db.characters).insertOnConflictUpdate(_toRow(restored));
    });
    return true;
  }

  Future<void> deleteVersion(String versionId) async {
    await (db.delete(db.characterVersions)
          ..where((t) => t.id.equals(versionId)))
        .go();
  }

  Future<void> _insertVersion(
    String characterId,
    String snapshotJson,
    String trigger, {
    String label = '',
  }) async {
    final latest = await _latestVersion(characterId);
    var createdAtMs = DateTime.now().millisecondsSinceEpoch;
    // 同一毫秒内连续保存时保证严格递增，列表顺序才稳定。
    if (latest != null && createdAtMs <= latest.createdAtMs) {
      createdAtMs = latest.createdAtMs + 1;
    }
    await db.into(db.characterVersions).insert(
          CharacterVersionsCompanion.insert(
            id: newId(),
            characterId: characterId,
            trigger: Value(trigger),
            label: Value(label),
            createdAtMs: createdAtMs,
            snapshotJson: Value(snapshotJson),
          ),
        );
    await _pruneVersions(characterId);
  }

  Future<void> _pruneVersions(String characterId) async {
    final rows = await (db.select(db.characterVersions)
          ..where((t) => t.characterId.equals(characterId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAtMs)])
          ..limit(1000))
        .get();
    if (rows.length <= kCharacterVersionMax) return;
    final stale = rows.skip(kCharacterVersionMax).map((r) => r.id).toList();
    await (db.delete(db.characterVersions)
          ..where((t) => t.id.isIn(stale)))
        .go();
  }

  Future<CharacterVersion?> _latestVersion(String characterId) async {
    final row = await (db.select(db.characterVersions)
          ..where((t) => t.characterId.equals(characterId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAtMs)])
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : _versionFromRow(row);
  }

  CharacterVersion _versionFromRow(CharacterVersionRow row) => CharacterVersion(
        id: row.id,
        characterId: row.characterId,
        trigger: row.trigger,
        label: row.label,
        createdAtMs: row.createdAtMs,
        snapshotJson: row.snapshotJson,
      );

  String _snapshotJson(Character c) => jsonEncode({
        'name': c.name,
        'description': c.description,
        'personality': c.personality,
        'scenario': c.scenario,
        'firstMessage': c.firstMessage,
        'exampleDialogue': c.exampleDialogue,
        'alternateGreetings': c.alternateGreetings,
        'profile': c.profile.toJson(),
        'extensions': c.extensions.toJson(),
        'source': c.source,
      });

  Character _applySnapshot(Character base, Map<String, dynamic> snapshot) {
    final name = _stringOr(snapshot['name'], base.name);
    return Character(
      id: base.id,
      name: name.trim().isEmpty ? base.name : name,
      description: _stringOr(snapshot['description'], ''),
      personality: _stringOr(snapshot['personality'], ''),
      scenario: _stringOr(snapshot['scenario'], ''),
      firstMessage: _stringOr(snapshot['firstMessage'], ''),
      exampleDialogue: _stringOr(snapshot['exampleDialogue'], ''),
      alternateGreetings: _stringListOr(snapshot['alternateGreetings']),
      avatarPath: base.avatarPath,
      source: _stringOr(snapshot['source'], base.source),
      profile: snapshot['profile'] is Map
          ? CharacterProfile.fromJson(
              Map<String, dynamic>.from(snapshot['profile'] as Map),
            )
          : CharacterProfile.empty,
      extensions: snapshot['extensions'] is Map
          ? CharacterExtensions.fromJson(
              Map<String, dynamic>.from(snapshot['extensions'] as Map),
            )
          : CharacterExtensions.empty,
      createdAt: base.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  String _stringOr(Object? value, String fallback) =>
      value is String ? value : fallback;

  List<String> _stringListOr(Object? value) {
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }
}
