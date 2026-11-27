/// 角色版本快照（v2.1）。
///
/// 只保存文本档案（核心字段 + 扩展档案 + 第三方扩展 + source），
/// 立绘、记忆、世界书不参与回滚。
library;

import 'dart:convert';

class CharacterVersion {
  final String id;
  final String characterId;

  /// save | manual | restore | import
  final String trigger;
  final String label;

  /// 毫秒时间戳：Drift 的 dateTime() 按秒存储，同秒多次保存无法稳定排序。
  final int createdAtMs;

  /// 快照 JSON 原文。
  final String snapshotJson;

  const CharacterVersion({
    required this.id,
    required this.characterId,
    required this.trigger,
    required this.label,
    required this.createdAtMs,
    required this.snapshotJson,
  });

  DateTime get createdAt => DateTime.fromMillisecondsSinceEpoch(createdAtMs);

  Map<String, dynamic> get snapshot {
    try {
      final decoded = jsonDecode(snapshotJson);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // 坏快照按空对象处理；恢复时由仓储兜底。
    }
    return const {};
  }

  String get snapshotName {
    final name = snapshot['name'];
    return name is String ? name : '';
  }
}
