/// 桌宠模型领域模型：导入解压后的 Cubism 3/4 模型。
library;

/// 一个桌宠模型（.moc3 + model3.json 及其资源）。
class PetModel {
  final String id;
  final String name;

  /// 解压目录绝对路径。
  final String dirPath;

  /// model3.json 绝对路径。
  final String entryJsonPath;

  final String? thumbnailPath;

  /// 表情 id 列表（model3.json Expressions[].Name）。
  final List<String> expressions;

  /// 动作组名 → 动作数量。
  final Map<String, int> motionGroups;

  final DateTime createdAt;
  final DateTime updatedAt;

  const PetModel({
    required this.id,
    required this.name,
    required this.dirPath,
    required this.entryJsonPath,
    this.thumbnailPath,
    this.expressions = const [],
    this.motionGroups = const {},
    required this.createdAt,
    required this.updatedAt,
  });
}
