import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/app_database.dart';
import '../domain/lore_entry.dart';

/// 世界书条目的存取。
class LoreRepository {
  LoreRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Stream<List<LoreEntry>> watchForCharacter(String characterId) {
    final query = _db.select(_db.loreEntries)
      ..where((t) => t.characterId.equals(characterId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.priority, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.createdAt),
      ]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  Future<List<LoreEntry>> listForCharacter(
    String characterId, {
    bool enabledOnly = false,
  }) async {
    final query = _db.select(_db.loreEntries)
      ..where(
        (t) =>
            t.characterId.equals(characterId) &
            (enabledOnly ? t.enabled.equals(true) : const Constant(true)),
      )
      ..orderBy([
        (t) => OrderingTerm(expression: t.priority, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.createdAt),
      ]);
    return (await query.get()).map(_fromRow).toList();
  }

  Future<void> save(LoreEntry entry) async {
    await _db
        .into(_db.loreEntries)
        .insertOnConflictUpdate(_toCompanion(entry));
  }

  Future<void> delete(String id) async {
    await (_db.delete(_db.loreEntries)..where((t) => t.id.equals(id))).go();
  }

  Future<void> setEnabled(String id, bool enabled) async {
    await (_db.update(_db.loreEntries)..where((t) => t.id.equals(id))).write(
      LoreEntriesCompanion(enabled: Value(enabled)),
    );
  }

  /// 导入角色卡里的 world info；默认不启用，交由用户逐条确认。
  Future<int> importDrafts(
    String characterId,
    List<LoreImportDraft> drafts, {
    bool enabled = false,
  }) async {
    if (drafts.isEmpty) return 0;
    var count = 0;
    await _db.transaction(() async {
      for (final draft in drafts) {
        final content = draft.content.trim();
        final keys = draft.keys.where((k) => k.trim().isNotEmpty).toList();
        if (content.isEmpty || keys.isEmpty) continue;
        await save(
          LoreEntry(
            id: _uuid.v4(),
            characterId: characterId,
            keys: keys,
            content: content,
            position: draft.position,
            depth: draft.depth,
            priority: draft.priority,
            enabled: enabled,
            sourceJson: draft.sourceJson,
            createdAt: DateTime.now(),
          ),
        );
        count++;
      }
    });
    return count;
  }

  LoreEntry _fromRow(LoreEntryRow row) {
    List<String> keys;
    try {
      final raw = jsonDecode(row.keys);
      keys = raw is List
          ? raw.whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
          : const [];
    } catch (_) {
      keys = const [];
    }
    return LoreEntry(
      id: row.id,
      characterId: row.characterId,
      keys: keys,
      content: row.content,
      position: row.position,
      depth: row.depth,
      priority: row.priority,
      enabled: row.enabled,
      sourceJson: row.sourceJson,
      createdAt: row.createdAt,
    );
  }

  LoreEntriesCompanion _toCompanion(LoreEntry entry) => LoreEntriesCompanion(
    id: Value(entry.id),
    characterId: Value(entry.characterId),
    keys: Value(jsonEncode(entry.keys)),
    content: Value(entry.content),
    position: Value(entry.position),
    depth: Value(entry.depth),
    priority: Value(entry.priority),
    enabled: Value(entry.enabled),
    sourceJson: Value(entry.sourceJson),
    createdAt: Value(entry.createdAt),
  );
}

class LoreImportDraft {
  const LoreImportDraft({
    required this.keys,
    required this.content,
    this.position = 'before',
    this.depth = 0,
    this.priority = 0,
    this.sourceJson = '{}',
  });

  final List<String> keys;
  final String content;
  final String position;
  final int depth;
  final int priority;

  /// 导入时的完整条目原文，导出时合并。
  final String sourceJson;
}
