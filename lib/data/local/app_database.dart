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
    AgentSessions,
    AgentMessages,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'ai_roleplay_chat'));

  /// 测试用：注入内存执行器。
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createMemoryIndexes();
      await _createAgentIndexes();
      await _createMessageIndexes();
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
      // v10：Agent 会话与消息。
      if (from < 10) {
        await m.createTable(agentSessions);
        await m.createTable(agentMessages);
        await _createAgentIndexes();
      }
      // v11：会话级 Agent 权限（审批模式 + 授权文件夹）。
      // from<10 时 createTable 已按当前定义建出这两列，不能再 addColumn。
      if (from >= 10 && from < 11) {
        await m.addColumn(agentSessions, agentSessions.approvalMode);
        await m.addColumn(agentSessions, agentSessions.grantedFoldersJson);
      }
      // v12：消息/会话查询索引，长会话打开与流式落盘不再全表扫描。
      if (from < 12) await _createMessageIndexes();
    },
  );

  /// 事实表按「角色 + 发生日期」查询，量小但记忆页按日期倒序读。
  Future<void> _createMemoryIndexes() => customStatement(
    'CREATE INDEX IF NOT EXISTS idx_memory_facts_character_occurred '
    'ON memory_facts (character_id, occurred_at DESC)',
  );

  /// Agent 消息按「会话 + 时间」顺序读取。
  Future<void> _createAgentIndexes() => customStatement(
    'CREATE INDEX IF NOT EXISTS idx_agent_messages_session_created '
    'ON agent_messages (session_id, created_at)',
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
