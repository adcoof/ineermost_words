/// 桌宠模型与情绪映射仓库。
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';

import '../../../core/utils/id.dart';
import '../../../data/local/app_database.dart';
import '../../chat/application/emotion_tag_parser.dart';
import '../domain/pet_command.dart';
import '../domain/pet_model.dart';

/// 一条标签 → 桌宠指令的映射。
class EmotionMapping {
  final String id;

  /// null = 全局映射（对所有模型生效）。
  final String? petModelId;
  final String tag;

  /// expression | motion
  final String actionType;

  /// expression：表情 id；motion：动作组名或 组名:序号。
  final String targetId;
  final int priority;
  final bool enabled;

  const EmotionMapping({
    required this.id,
    this.petModelId,
    required this.tag,
    required this.actionType,
    required this.targetId,
    this.priority = 1,
    this.enabled = true,
  });

  EmotionMapping copyWith({
    String? tag,
    String? actionType,
    String? targetId,
    int? priority,
    bool? enabled,
  }) =>
      EmotionMapping(
        id: id,
        petModelId: petModelId,
        tag: tag ?? this.tag,
        actionType: actionType ?? this.actionType,
        targetId: targetId ?? this.targetId,
        priority: priority ?? this.priority,
        enabled: enabled ?? this.enabled,
      );

  /// 转成桌宠指令；motion 的 targetId 形如 `TapBody` 或 `TapBody:2`。
  PetCommand? toCommand() {
    switch (actionType) {
      case 'expression':
        return PetCommand.expression(targetId);
      case 'motion':
        final parts = targetId.split(':');
        final group = parts.first;
        final index = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
        if (group.isEmpty) return null;
        return PetCommand.motion(group, index: index, priority: priority);
      default:
        return null;
    }
  }
}

class PetModelRepository {
  final AppDatabase db;

  PetModelRepository(this.db);

  Stream<List<PetModel>> watchModels() {
    final q = db.select(db.petModels)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    return q.watch().map((rows) => rows.map(_modelFromRow).toList());
  }

  Future<PetModel?> getModel(String id) async {
    final q = db.select(db.petModels)..where((t) => t.id.equals(id));
    final row = await q.getSingleOrNull();
    return row == null ? null : _modelFromRow(row);
  }

  Future<void> saveModel(PetModel model) async {
    await db.into(db.petModels).insertOnConflictUpdate(_modelToRow(model));
  }

  Future<void> deleteModel(String id) async {
    final model = await getModel(id);
    await (db.delete(db.petModels)..where((t) => t.id.equals(id))).go();
    final dir = model?.dirPath;
    if (dir != null && dir.isNotEmpty) {
      try {
        final d = Directory(dir);
        if (await d.exists()) await d.delete(recursive: true);
      } catch (_) {
        // 目录删除失败不影响记录删除。
      }
    }
  }

  // ---- 情绪映射 ----

  /// 某模型可见的映射：全局（petModelId=null）+ 模型级，按优先级倒序。
  Stream<List<EmotionMapping>> watchMappings(String petModelId) {
    final q = db.select(db.emotionMappings)
      ..where((t) =>
          t.petModelId.equals(petModelId) | t.petModelId.isNull())
      ..orderBy([
        (t) => OrderingTerm.desc(t.priority),
        (t) => OrderingTerm.asc(t.tag),
      ]);
    return q.watch().map((rows) => rows.map(_mappingFromRow).toList());
  }

  /// 解析一个事件 → 桌宠指令。模型级映射优先于全局（同 tag 时）。
  ///
  /// 目标适配规则：
  /// - 表情目标不区分大小写匹配；仍找不到时，若模型有表情库则按 tag 的
  ///   稳定哈希落到一个表情上——保证任何模型对任何情绪都"有反应"，
  ///   精确映射可在编辑器里覆盖；
  /// - 动作目标的组不存在时静默跳过（避免 JS 报错），序号越界回退到 0。
  Future<PetCommand?> resolve(EmotionEvent event, String petModelId) async {
    final model = await getModel(petModelId);
    // 不在 SQL 里过滤 enabled：需要区分「用户从未配置」与「显式禁用」。
    final q = db.select(db.emotionMappings)
      ..where((t) =>
          t.tag.equals(event.value) &
          (t.petModelId.equals(petModelId) | t.petModelId.isNull()));
    final rows = await q.get();
    final all = rows.map(_mappingFromRow).toList();

    // 该 tag 有映射但全部被禁用：尊重用户的显式静音，不做兜底。
    if (all.isNotEmpty && all.every((m) => !m.enabled)) return null;

    final enabled = all.where((m) => m.enabled).toList()
      ..sort((a, b) {
        // 模型级优先。
        final aModel = a.petModelId != null ? 1 : 0;
        final bModel = b.petModelId != null ? 1 : 0;
        if (aModel != bModel) return bModel - aModel;
        return b.priority.compareTo(a.priority);
      });

    PetCommand? command;
    for (final m in enabled) {
      final c = m.toCommand();
      if (c != null) {
        command = c;
        break;
      }
    }

    // 无映射时：情绪事件兜底到哈希表情（模型有表情库才兜底）。
    if (command == null &&
        event.kind == 'emotion' &&
        (model?.expressions.isNotEmpty ?? false)) {
      command = PetCommand.expression(_hashExpression(event.value, model!));
    }
    if (command == null) return null;

    switch (command.type) {
      case PetCommandType.setExpression:
        return _adaptExpression(command, event.value, model);
      case PetCommandType.startMotion:
        return _adaptMotion(command, model);
      case PetCommandType.setLipSync:
        return command;
    }
  }

  /// expression 目标适配：精确 → 大小写容错 → tag 哈希兜底。
  PetCommand? _adaptExpression(
      PetCommand command, String tag, PetModel? model) {
    final expressions = model?.expressions ?? const [];
    if (expressions.isEmpty) return command; // 模型未知时不拦截。
    if (expressions.contains(command.expressionId)) return command;
    // 大小写容错（如映射写 F03、模型是 f03）。
    for (final e in expressions) {
      if (e.toLowerCase() == command.expressionId.toLowerCase()) {
        return PetCommand.expression(e);
      }
    }
    // 目标不存在：兜底哈希表情。
    return PetCommand.expression(_hashExpression(tag, model!));
  }

  /// 供「试触发」使用：把单条映射按与事件相同的适配逻辑转成指令。
  Future<PetCommand?> resolveForMapping(
      EmotionMapping mapping, String petModelId) async {
    if (!mapping.enabled) return null;
    final command = mapping.toCommand();
    if (command == null) return null;
    final model = await getModel(petModelId);
    switch (command.type) {
      case PetCommandType.setExpression:
        return _adaptExpression(command, mapping.tag, model);
      case PetCommandType.startMotion:
        return _adaptMotion(command, model);
      case PetCommandType.setLipSync:
        return command;
    }
  }

  /// motion 组名校验：组不存在返回 null（静默跳过），组名大小写容错，
  /// 序号越界回退到 0。
  PetCommand? _adaptMotion(PetCommand command, PetModel? model) {
    if (model == null) return command;
    String? group;
    var count = 0;
    for (final entry in model.motionGroups.entries) {
      if (entry.key == command.motionGroup) {
        group = entry.key;
        count = entry.value;
        break;
      }
      if (group == null &&
          entry.key.toLowerCase() == command.motionGroup.toLowerCase()) {
        group = entry.key; // 大小写容错候选，可能被精确匹配覆盖。
        count = entry.value;
      }
    }
    if (group == null || count <= 0) return null;
    if (command.motionIndex >= count || command.motionIndex < 0) {
      return PetCommand.motion(group, index: 0, priority: command.priority);
    }
    return PetCommand.motion(group,
        index: command.motionIndex, priority: command.priority);
  }

  /// tag → 表情列表的稳定哈希下标（djb2，跨进程一致）。
  static String _hashExpression(String tag, PetModel model) {
    var h = 5381;
    for (final c in tag.codeUnits) {
      h = ((h << 5) + h + c) & 0x7FFFFFFF;
    }
    return model.expressions[h % model.expressions.length];
  }

  Future<void> saveMapping(EmotionMapping mapping) async {
    await db
        .into(db.emotionMappings)
        .insertOnConflictUpdate(_mappingToRow(mapping));
  }

  Future<void> deleteMapping(String id) async {
    await (db.delete(db.emotionMappings)..where((t) => t.id.equals(id))).go();
  }

  /// 全局映射为空时导入内置默认映射（幂等）。
  Future<void> seedDefaultMappings() async {
    final rows = await db.select(db.emotionMappings).get();
    if (rows.any((r) => r.petModelId == null)) return;
    // 内置默认：情绪 → 同名表情；动作 → TapBody 组首帧。
    const defaults = [
      ('happy', 'expression', 'happy', 2),
      ('sad', 'expression', 'sad', 2),
      ('angry', 'expression', 'angry', 2),
      ('shy', 'expression', 'shy', 2),
      ('surprised', 'expression', 'surprised', 2),
      ('wave', 'motion', 'TapBody:0', 1),
      ('nod', 'motion', 'TapBody:0', 1),
      ('shake_head', 'motion', 'TapBody:1', 1),
    ];
    for (final (tag, type, target, priority) in defaults) {
      await saveMapping(EmotionMapping(
        id: newId(),
        tag: tag,
        actionType: type,
        targetId: target,
        priority: priority,
      ));
    }
  }

  PetModel _modelFromRow(PetModelRow row) => PetModel(
        id: row.id,
        name: row.name,
        dirPath: row.dirPath,
        entryJsonPath: row.entryJsonPath,
        thumbnailPath: row.thumbnailPath,
        expressions: (jsonDecode(row.expressions) as List)
            .map((e) => e.toString())
            .toList(),
        motionGroups: (jsonDecode(row.motionGroups) as Map)
            .map((k, v) => MapEntry(k.toString(), v as int)),
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  PetModelsCompanion _modelToRow(PetModel m) => PetModelsCompanion(
        id: Value(m.id),
        name: Value(m.name),
        dirPath: Value(m.dirPath),
        entryJsonPath: Value(m.entryJsonPath),
        thumbnailPath: Value(m.thumbnailPath),
        expressions: Value(jsonEncode(m.expressions)),
        motionGroups: Value(jsonEncode(m.motionGroups)),
        createdAt: Value(m.createdAt),
        updatedAt: Value(m.updatedAt),
      );

  EmotionMapping _mappingFromRow(EmotionMappingRow row) => EmotionMapping(
        id: row.id,
        petModelId: row.petModelId,
        tag: row.tag,
        actionType: row.actionType,
        targetId: row.targetId,
        priority: row.priority,
        enabled: row.enabled,
      );

  EmotionMappingsCompanion _mappingToRow(EmotionMapping m) =>
      EmotionMappingsCompanion(
        id: Value(m.id),
        petModelId: Value(m.petModelId),
        tag: Value(m.tag),
        actionType: Value(m.actionType),
        targetId: Value(m.targetId),
        priority: Value(m.priority),
        enabled: Value(m.enabled),
      );
}
