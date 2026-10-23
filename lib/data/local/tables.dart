/// Drift 表定义：会话、消息、API 供应商配置、通用设置。
library;

import 'package:drift/drift.dart';

/// 会话：一次与某角色（可选）的对话流。
@DataClassName('ConversationRow')
class Conversations extends Table {
  TextColumn get id => text()();

  TextColumn get title => text().withDefault(const Constant('新会话'))();

  /// 绑定的角色卡 id（M2 起使用）。
  TextColumn get characterId => text().nullable()();

  /// 绑定的桌宠模型 id（M3 起使用）。
  TextColumn get petModelId => text().nullable()();

  /// 本会话使用的 API 供应商配置。
  TextColumn get apiProfileId => text()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 消息：content 为展示/朗读用的干净文本，rawContent 保留原始输出（含情绪标签）。
@DataClassName('MessageRow')
class Messages extends Table {
  TextColumn get id => text()();

  TextColumn get conversationId => text()();

  /// user | assistant | system
  TextColumn get role => text()();

  TextColumn get content => text().withDefault(const Constant(''))();

  TextColumn get rawContent => text().withDefault(const Constant(''))();

  /// JSON 数组：情绪/动作事件（M2 起填充）。
  TextColumn get emotionEvents => text().withDefault(const Constant('[]'))();

  /// streaming | done | error
  TextColumn get status => text().withDefault(const Constant('done'))();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// OpenAI 兼容 API 供应商配置（BYOK）。
@DataClassName('ApiProfileRow')
class ApiProfiles extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  /// 形如 https://api.deepseek.com/v1 （不含 /chat/completions 后缀）。
  TextColumn get baseUrl => text()();

  TextColumn get apiKey => text().withDefault(const Constant(''))();

  TextColumn get model => text()();

  RealColumn get temperature => real().withDefault(const Constant(1.0))();

  IntColumn get maxTokens => integer().nullable()();

  /// JSON 对象：额外请求头（覆盖中转站特殊鉴权）。
  TextColumn get extraHeaders => text().withDefault(const Constant('{}'))();

  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 角色卡：人设文本 + 本地立绘路径。
@DataClassName('CharacterRow')
class Characters extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  TextColumn get description => text().withDefault(const Constant(''))();

  TextColumn get personality => text().withDefault(const Constant(''))();

  TextColumn get scenario => text().withDefault(const Constant(''))();

  /// 开场白（SillyTavern first_mes）；绑定角色建会话时作为 assistant 消息插入。
  TextColumn get firstMessage => text().withDefault(const Constant(''))();

  TextColumn get exampleDialogue => text().withDefault(const Constant(''))();

  /// 立绘文件绝对路径。
  TextColumn get avatarPath => text().nullable()();

  /// manual | st_v2
  TextColumn get source => text().withDefault(const Constant('manual'))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 桌宠模型：zip 导入解压后的本地目录 + 解析出的表情/动作清单。
@DataClassName('PetModelRow')
class PetModels extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  /// 解压目录绝对路径。
  TextColumn get dirPath => text()();

  /// model3.json 绝对路径。
  TextColumn get entryJsonPath => text()();

  TextColumn get thumbnailPath => text().nullable()();

  /// JSON 数组：表情 id 列表。
  TextColumn get expressions => text().withDefault(const Constant('[]'))();

  /// JSON 对象：动作组名 → 数量。
  TextColumn get motionGroups => text().withDefault(const Constant('{}'))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 情绪/动作标签 → 桌宠指令的映射。petModelId 为 null 表示全局映射。
@DataClassName('EmotionMappingRow')
class EmotionMappings extends Table {
  TextColumn get id => text()();

  TextColumn get petModelId => text().nullable()();

  TextColumn get tag => text()();

  /// expression | motion
  TextColumn get actionType => text()();

  /// expression：表情 id；motion：动作组名或 组名:序号。
  TextColumn get targetId => text()();

  IntColumn get priority => integer().withDefault(const Constant(1))();

  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// TTS 供应商配置。provider: edge | openai | system。
@DataClassName('TtsProfileRow')
class TtsProfiles extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  /// edge | openai | system
  TextColumn get provider => text()();

  /// 发音人（edge: zh-CN-XiaoxiaoNeural 等；openai: alloy 等；system: 引擎语音 id）。
  TextColumn get voiceId => text().withDefault(const Constant(''))();

  /// 语速倍率。
  RealColumn get speed => real().withDefault(const Constant(1.0))();

  /// openai 提供商的模型名（如 tts-1）。
  TextColumn get model => text().withDefault(const Constant(''))();

  /// openai 提供商专用 apiKey/baseUrl（为空时回落到默认聊天 API 配置）。
  TextColumn get apiKey => text().withDefault(const Constant(''))();

  TextColumn get baseUrl => text().withDefault(const Constant(''))();

  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 通用键值设置。
@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();

  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}