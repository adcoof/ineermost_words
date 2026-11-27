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

  /// 本会话是否自动朗读（v6）：与全局 voice_enabled 相与决定实际发声。
  BoolColumn get voiceEnabled => boolean().withDefault(const Constant(true))();

  /// 自定义聊天背景板文件绝对路径（v8）；null=默认主题背景。
  TextColumn get backgroundPath => text().nullable()();

  /// 分支来源会话（v16）：从某条消息 fork 出的新会话。
  TextColumn get parentConversationId => text().nullable()();

  /// 分支点消息 id（v16）。
  TextColumn get branchFromMessageId => text().nullable()();

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

  /// JSON 数组：附图文件绝对路径（v7）。
  TextColumn get imagePaths => text().withDefault(const Constant('[]'))();

  /// 图片内容一句话概括（LLM 生成；失败留空走 [图片] 占位，v7）。
  TextColumn get imageSummary => text().withDefault(const Constant(''))();

  /// streaming | done | error
  TextColumn get status => text().withDefault(const Constant('done'))();

  /// text | sticker（v8）：sticker 为纯图表情包消息，不进提示词/记忆/标题。
  TextColumn get kind => text().withDefault(const Constant('text'))();

  /// 当前选中的候选回复 id（v14）；null=正文即唯一候选。
  TextColumn get activeVariantId => text().nullable()();

  /// 群聊中说这句话的角色 id（v16）；null=单角色会话。
  TextColumn get speakerCharacterId => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 消息候选回复（v14）：同一 assistant 消息的多次生成/编辑历史。
@DataClassName('MessageVariantRow')
class MessageVariants extends Table {
  TextColumn get id => text()();

  TextColumn get messageId => text()();

  TextColumn get content => text().withDefault(const Constant(''))();

  TextColumn get rawContent => text().withDefault(const Constant(''))();

  /// JSON 数组：情绪/动作事件。
  TextColumn get emotionEvents => text().withDefault(const Constant('[]'))();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 群聊会话的参与者（v16）：按 sortOrder 轮流发言。
@DataClassName('ConversationParticipantRow')
class ConversationParticipants extends Table {
  TextColumn get id => text()();

  TextColumn get conversationId => text()();

  TextColumn get characterId => text()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// 是否参与自动轮转（v18）。静音成员仍可被“让 TA 回复”强制发言。
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 世界书 / Lorebook 条目（v15）：关键词命中后注入提示词。
@DataClassName('LoreEntryRow')
class LoreEntries extends Table {
  TextColumn get id => text()();

  TextColumn get characterId => text()();

  /// JSON 数组：触发关键词。
  TextColumn get keys => text().withDefault(const Constant('[]'))();

  TextColumn get content => text().withDefault(const Constant(''))();

  /// before|after：相对历史消息的位置。
  TextColumn get position => text().withDefault(const Constant('before'))();

  /// 0 表示贴近当前消息；数字越大越靠前。
  IntColumn get depth => integer().withDefault(const Constant(0))();

  IntColumn get priority => integer().withDefault(const Constant(0))();

  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  /// 导入时的完整条目原文（v17）：导出时合并，保留未映射字段。
  TextColumn get sourceJson => text().withDefault(const Constant('{}'))();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 角色版本快照（v17）：只存文本档案，立绘/记忆/世界书不参与回滚。
@DataClassName('CharacterVersionRow')
class CharacterVersions extends Table {
  TextColumn get id => text()();

  TextColumn get characterId => text()();

  /// save | manual | restore | import
  TextColumn get trigger => text().withDefault(const Constant('save'))();

  TextColumn get label => text().withDefault(const Constant(''))();

  /// 毫秒时间戳：dateTime() 按秒存，同秒保存无法稳定排序。
  IntColumn get createdAtMs => integer()();

  /// 快照 JSON：核心字段 + 扩展档案 + 第三方扩展 + source。
  TextColumn get snapshotJson => text().withDefault(const Constant('{}'))();

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

  /// 多开场白 JSON 数组（v14）；firstMessage 仍是主开场白。
  TextColumn get alternateGreetings =>
      text().withDefault(const Constant('[]'))();

  /// 立绘文件绝对路径。
  TextColumn get avatarPath => text().nullable()();

  /// manual | st_v1 | st_v2 | st_v3
  TextColumn get source => text().withDefault(const Constant('manual'))();

  /// 扩展档案 JSON（v17）：外貌/背景/关系/语言风格/创作者/运行配置等。
  TextColumn get profileJson => text().withDefault(const Constant('{}'))();

  /// 第三方扩展与未识别字段 JSON（v17）：只读保留，导出时合并。
  TextColumn get extensionsJson => text().withDefault(const Constant('{}'))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  /// 跨会话长期记忆（LLM 摘要，第一人称要点，v6）。
  /// 注意：CharacterRepository.save 是整行 upsert，本列不进 Character
  /// 领域模型，只经 getMemory/setMemory 读写，防止编辑角色卡时覆盖。
  TextColumn get memorySummary => text().withDefault(const Constant(''))();

  /// 角色眼中的用户画像（LLM 摘要，角色视角，v8）。同上不进域模型。
  TextColumn get userSummary => text().withDefault(const Constant(''))();

  /// 记忆水位线：该时点（含）之前的 done 消息已纳入摘要；null=从未摘要。
  DateTimeColumn get memoryUpdatedAt => dateTime().nullable()();

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

/// 自定义音色（音色设计）：一条自然语言描述定义音色，
/// 合成时经 mimo-v2.5-tts-voicedesign 的 user 消息传递（无需音色 ID）。
@DataClassName('CustomVoiceRow')
class CustomVoices extends Table {
  TextColumn get id => text()();

  /// 显示名（如「萝莉音」「磁性男声」）。
  TextColumn get name => text()();

  /// 音色描述（如「温柔甜美的年轻女声，语速稍慢」）。
  TextColumn get description => text()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 记忆游标（v9）：按「角色 + 会话」记录该会话已摘要到的时间点。
/// 旧实现只有一个角色级水位线，切换会话后旧会话的新消息永远进不了摘要；
/// v9 起每个会话独立推进，升级后无游标按 epoch 处理（首次回填）。
@DataClassName('MemoryCursorRow')
class MemoryCursors extends Table {
  TextColumn get characterId => text()();

  TextColumn get conversationId => text()();

  DateTimeColumn get summarizedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {characterId, conversationId};
}

/// 长期事实记忆（v9）：把「去关山游玩」这类事件压缩成
/// 一条事实 + 发生日期；细节在近期摘要过期后消失，事实长期保留。
@DataClassName('MemoryFactRow')
class MemoryFacts extends Table {
  TextColumn get id => text()();

  TextColumn get characterId => text()();

  /// 一事一条的短事实（如「用户去关山游玩」），不含过程细节。
  TextColumn get fact => text()();

  /// 事件发生日（本地 00:00），不是整理时间。
  DateTimeColumn get occurredAt => dateTime()();

  TextColumn get sourceConversationId => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 表情包：每角色一个库，按固定心情键（happy/angry/… 英文情绪标签值）分组，
/// 一心情可多张（发送时随机选取）。文件存 documents/stickers/{characterId}/{id}.jpg。
@DataClassName('StickerRow')
class Stickers extends Table {
  TextColumn get id => text()();

  TextColumn get characterId => text()();

  /// 心情键：英文情绪标签值（happy/angry/sad/amused/confused/shy/…）。
  TextColumn get mood => text()();

  /// 图片文件绝对路径。
  TextColumn get filePath => text()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
