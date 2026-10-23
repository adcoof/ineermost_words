/// 角色卡领域模型。
library;

/// 一个可绑定到会话的角色。
///
/// 字段语义与 SillyTavern 卡对齐：description=角色描述、personality=性格、
/// scenario=场景、firstMessage=开场白（first_mes）、exampleDialogue=对话示例（mes_example）。
class Character {
  final String id;
  final String name;
  final String description;
  final String personality;
  final String scenario;
  final String firstMessage;
  final String exampleDialogue;

  /// 本地立绘路径；导入 ST PNG 卡时整卡图片也存为立绘。
  final String? avatarPath;

  /// manual | st_v2
  final String source;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Character({
    required this.id,
    required this.name,
    this.description = '',
    this.personality = '',
    this.scenario = '',
    this.firstMessage = '',
    this.exampleDialogue = '',
    this.avatarPath,
    this.source = 'manual',
    required this.createdAt,
    required this.updatedAt,
  });

  Character copyWith({
    String? name,
    String? description,
    String? personality,
    String? scenario,
    String? firstMessage,
    String? exampleDialogue,
    String? avatarPath,
    bool clearAvatar = false,
  }) =>
      Character(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        personality: personality ?? this.personality,
        scenario: scenario ?? this.scenario,
        firstMessage: firstMessage ?? this.firstMessage,
        exampleDialogue: exampleDialogue ?? this.exampleDialogue,
        avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
        source: source,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
