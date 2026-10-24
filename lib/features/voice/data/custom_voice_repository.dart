/// 自定义音色仓库（settings 库的 custom_voices 表）。
///
/// 音色 = 一条自然语言描述（如「温柔甜美的年轻女声，语速稍慢」），
/// 合成时经 mimo-v2.5-tts-voicedesign 的 user 消息传递——
/// 实测（2026-10-24）该接口无需音色 ID，描述即音色。
library;

import 'package:drift/drift.dart';

import '../../../core/utils/id.dart';
import '../../../data/local/app_database.dart';

/// 一条自定义音色。
class CustomVoice {
  final String id;
  final String name;

  /// 音色描述（自然语言，合成时进 user 消息）。
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomVoice({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  CustomVoice copyWith({String? name, String? description}) => CustomVoice(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

class CustomVoiceRepository {
  final AppDatabase db;

  CustomVoiceRepository(this.db);

  /// 全量列表，按创建时间倒序。
  Future<List<CustomVoice>> listAll() async {
    final q = db.select(db.customVoices)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return (await q.get()).map(_fromRow).toList();
  }

  /// 全量监听（列表页用）。
  Stream<List<CustomVoice>> watchAll() {
    final q = db.select(db.customVoices)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return q.watch().map((rows) => rows.map(_fromRow).toList());
  }

  Future<CustomVoice?> getById(String id) async {
    final q = db.select(db.customVoices)..where((t) => t.id.equals(id));
    final row = await q.getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// 新建或更新（按 id upsert）；updatedAt 刷新为当前时间。
  Future<void> save(CustomVoice voice) async {
    final now = DateTime.now();
    await db.into(db.customVoices).insertOnConflictUpdate(CustomVoicesCompanion(
          id: Value(voice.id),
          name: Value(voice.name),
          description: Value(voice.description),
          createdAt: Value(voice.createdAt),
          updatedAt: Value(now),
        ));
  }

  Future<void> delete(String id) async {
    await (db.delete(db.customVoices)..where((t) => t.id.equals(id))).go();
  }

  /// 新建用 id。
  String newVoiceId() => newId();

  CustomVoice _fromRow(CustomVoiceRow row) => CustomVoice(
        id: row.id,
        name: row.name,
        description: row.description,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );
}
