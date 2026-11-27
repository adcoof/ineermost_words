/// 角色卡领域模型。
library;

import 'character_extensions.dart';
import 'character_profile.dart';

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

  /// 多开场白（不含 firstMessage）；ST V2 alternate_greetings。
  final List<String> alternateGreetings;

  /// 本地立绘路径；导入 ST PNG 卡时整卡图片也存为立绘。
  final String? avatarPath;

  /// manual | st_v1 | st_v2 | st_v3
  final String source;

  /// 列表页展示用的来源文案。
  String get sourceLabel => switch (source) {
    'st_v1' => 'SillyTavern 卡 · V1',
    'st_v2' => 'SillyTavern 卡 · V2',
    'st_v3' => 'SillyTavern 卡 · V3',
    _ => '手动创建',
  };

  /// 扩展档案（v2.1）：外貌/背景/关系/语言风格/创作者/运行配置等。
  final CharacterProfile profile;

  /// 第三方扩展与未识别字段（v2.1）：只读保留，导出时合并。
  final CharacterExtensions extensions;

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
    this.alternateGreetings = const [],
    this.avatarPath,
    this.source = 'manual',
    this.profile = CharacterProfile.empty,
    this.extensions = CharacterExtensions.empty,
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
    List<String>? alternateGreetings,
    String? avatarPath,
    bool clearAvatar = false,
    String? source,
    CharacterProfile? profile,
    CharacterExtensions? extensions,
  }) =>
      Character(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        personality: personality ?? this.personality,
        scenario: scenario ?? this.scenario,
        firstMessage: firstMessage ?? this.firstMessage,
        exampleDialogue: exampleDialogue ?? this.exampleDialogue,
        alternateGreetings: alternateGreetings ?? this.alternateGreetings,
        avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
        source: source ?? this.source,
        profile: profile ?? this.profile,
        extensions: extensions ?? this.extensions,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
