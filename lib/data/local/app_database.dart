/// 应用唯一 SQLite 数据库（Drift）。
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Conversations,
    Messages,
    ApiProfiles,
    Characters,
    PetModels,
    EmotionMappings,
    TtsProfiles,
    Settings,
    CustomVoices,
    Stickers,
    MemoryCursors,
    MemoryFacts,
    MessageVariants,
    LoreEntries,
    ConversationParticipants,
    CharacterVersions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'ai_roleplay_chat'));

  /// 测试用：注入内存执行器。
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 17;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createMemoryIndexes();
      await _createMessageIndexes();
      await _createVariantIndexes();
      await _createLoreIndexes();
      await _createParticipantIndexes();
      await _createCharacterVersionIndexes();
    },
    onUpgrade: (m, from, to) async {
      // v2：新增角色卡表（v1 的会话表已含 character_id 列）。
      if (from < 2) await m.createTable(characters);
      // v3：新增桌宠模型与情绪映射表（conversations 已含 pet_model_id 列）。
      if (from < 3) {
        await m.createTable(petModels);
        await m.createTable(emotionMappings);
      }
      // v4：新增 TTS 配置表。
      if (from < 4) await m.createTable(ttsProfiles);
      // v5：新增自定义音色表（M5 音色设计）。
      if (from < 5) await m.createTable(customVoices);
      // v6：会话级语音开关 + 角色跨会话记忆（存量行拿到新列默认值）。
      // 注意：characters 表在 from<2 时按当前定义 createTable（已含记忆列），
      // 只有旧版本已存在该表（from>=2）才需要补列，否则 duplicate column。
      if (from < 6) {
        await m.addColumn(conversations, conversations.voiceEnabled);
        if (from >= 2) {
          await m.addColumn(characters, characters.memorySummary);
          await m.addColumn(characters, characters.memoryUpdatedAt);
        }
      }
      // v7：消息附图（路径 JSON 数组 + LLM 图片摘要）。
      // messages 表只在 onCreate 建（所有升级路径都已存在该表，历史上无
      // createTable(messages)），直接 addColumn 安全，无需 from 门槛。
      if (from < 7) {
        await m.addColumn(messages, messages.imagePaths);
        await m.addColumn(messages, messages.imageSummary);
      }
      // v8：消息 kind（text|sticker）+ 角色用户画像 + 会话背景板 + 表情包表。
      // messages/conversations 同 v7 论证裸 addColumn 安全；characters 表
      // 仅在 from>=2 时已存在（v6 同款 from 门槛，否则 duplicate column）。
      if (from < 8) {
        await m.addColumn(messages, messages.kind);
        await m.addColumn(conversations, conversations.backgroundPath);
        if (from >= 2) {
          await m.addColumn(characters, characters.userSummary);
        }
        await m.createTable(stickers);
      }
      // v9：多会话记忆游标 + 长期事实记忆（记忆压缩）。
      if (from < 9) {
        await m.createTable(memoryCursors);
        await m.createTable(memoryFacts);
        await _createMemoryIndexes();
      }
      // v12：消息/会话查询索引，长会话打开与流式落盘不再全表扫描。
      if (from < 12) await _createMessageIndexes();
      // v13：移除 Agent，删除其会话与消息表。
      if (from < 13) {
        await customStatement('DROP TABLE IF EXISTS agent_messages');
        await customStatement('DROP TABLE IF EXISTS agent_sessions');
      }
      // v14：消息候选回复 + 当前候选 + 多开场白。
      // from<2 时 createTable(characters) 已按当前定义建出 alternate_greetings，
      // 不能再 addColumn；messages 从 v1 就存在，需要补列。
      if (from < 14) {
        await m.addColumn(messages, messages.activeVariantId);
        if (from >= 2) {
          await m.addColumn(characters, characters.alternateGreetings);
        }
        await m.createTable(messageVariants);
        await _createVariantIndexes();
      }
      if (from < 15) {
        await m.createTable(loreEntries);
        await _createLoreIndexes();
      }
      // v16：群聊参与者 + 会话分支指针。
      if (from < 16) {
        await m.addColumn(conversations, conversations.parentConversationId);
        await m.addColumn(conversations, conversations.branchFromMessageId);
        await m.addColumn(messages, messages.speakerCharacterId);
        await m.createTable(conversationParticipants);
        await _createParticipantIndexes();
      }
      // v17：角色扩展档案 + 第三方扩展保留 + 版本快照 + 世界书条目原文。
      // from<2 时 characters 已按当前定义建出；from<15 时 lore_entries 同理，
      // 不能再 addColumn（否则 duplicate column）。
      if (from < 17) {
        if (from >= 2) {
          await m.addColumn(characters, characters.profileJson);
          await m.addColumn(characters, characters.extensionsJson);
        }
        if (from >= 15) {
          await m.addColumn(loreEntries, loreEntries.sourceJson);
        }
        await m.createTable(characterVersions);
        await _createCharacterVersionIndexes();
      }
    },
  );

  /// 事实表按「角色 + 发生日期」查询，量小但记忆页按日期倒序读。
  Future<void> _createMemoryIndexes() => customStatement(
    'CREATE INDEX IF NOT EXISTS idx_memory_facts_character_occurred '
    'ON memory_facts (character_id, occurred_at DESC)',
  );

  /// 候选回复按「消息 + 创建时间」读取。
  Future<void> _createVariantIndexes() => customStatement(
    'CREATE INDEX IF NOT EXISTS idx_message_variants_message '
    'ON message_variants (message_id, created_at)',
  );

  /// 世界书按角色 + 启停读取。
  Future<void> _createLoreIndexes() => customStatement(
    'CREATE INDEX IF NOT EXISTS idx_lore_character '
    'ON lore_entries (character_id, enabled)',
  );

  /// 群聊参与者按「会话 + 顺序」读取。
  Future<void> _createParticipantIndexes() => customStatement(
    'CREATE INDEX IF NOT EXISTS idx_participants_conversation '
    'ON conversation_participants (conversation_id, sort_order)',
  );

  /// 角色版本按「角色 + 毫秒时间倒序」读取。
  Future<void> _createCharacterVersionIndexes() => customStatement(
    'CREATE INDEX IF NOT EXISTS idx_character_versions_character '
    'ON character_versions (character_id, created_at_ms DESC)',
  );

  /// 会话消息按「会话 + 时间」读取；会话列表按「角色 + 更新时间」过滤。
  Future<void> _createMessageIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_messages_conversation_created '
      'ON messages (conversation_id, created_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_conversations_character_updated '
      'ON conversations (character_id, updated_at)',
    );
  }
}
