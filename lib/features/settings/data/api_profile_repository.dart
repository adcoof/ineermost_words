/// API 供应商配置仓库。
library;

import 'package:drift/drift.dart';

import '../../../core/utils/id.dart';
import '../../../data/local/app_database.dart';
import '../domain/api_profile.dart';

class ApiProfileRepository {
  final AppDatabase db;

  ApiProfileRepository(this.db);

  Stream<List<ApiProfile>> watchAll() {
    final q = db.select(db.apiProfiles)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return q.watch().map((rows) => rows.map(_fromRow).toList());
  }

  Future<List<ApiProfile>> getAll() async {
    final q = db.select(db.apiProfiles)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return (await q.get()).map(_fromRow).toList();
  }

  Future<ApiProfile?> getById(String id) async {
    final q = db.select(db.apiProfiles)..where((t) => t.id.equals(id));
    final row = await q.getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<ApiProfile?> getDefault() async {
    final q = db.select(db.apiProfiles)..where((t) => t.isDefault.equals(true));
    final row = await q.getSingleOrNull();
    if (row != null) return _fromRow(row);
    final all = await getAll();
    return all.isEmpty ? null : all.first;
  }

  Future<void> save(ApiProfile profile) async {
    await db.into(db.apiProfiles).insertOnConflictUpdate(_toRow(profile));
  }

  Future<void> delete(String id) async {
    await (db.delete(db.apiProfiles)..where((t) => t.id.equals(id))).go();
  }

  /// 新建一个空配置（保存时用）。
  ApiProfile blank() => ApiProfile(
        id: newId(),
        name: '新供应商',
        baseUrl: 'https://api.deepseek.com/v1',
        apiKey: '',
        model: 'deepseek-chat',
        temperature: 1.0,
        extraHeaders: '{}',
        isDefault: false,
      );

  ApiProfile _fromRow(ApiProfileRow row) => ApiProfile(
        id: row.id,
        name: row.name,
        baseUrl: row.baseUrl,
        apiKey: row.apiKey,
        model: row.model,
        temperature: row.temperature,
        maxTokens: row.maxTokens,
        extraHeaders: row.extraHeaders,
        isDefault: row.isDefault,
      );

  ApiProfilesCompanion _toRow(ApiProfile p) => ApiProfilesCompanion(
        id: Value(p.id),
        name: Value(p.name),
        baseUrl: Value(p.baseUrl),
        apiKey: Value(p.apiKey),
        model: Value(p.model),
        temperature: Value(p.temperature),
        maxTokens: Value(p.maxTokens),
        extraHeaders: Value(p.extraHeaders),
        isDefault: Value(p.isDefault),
      );
}