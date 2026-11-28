/// 数据库迁移测试：旧版本库升级到当前 schemaVersion 无损。
///
/// 用 NativeDatabase.memory(setup:) 预置旧表结构与数据，
/// drift 打开时按 user_version 触发 onUpgrade——这是真机升级
/// 唯一会走的代码路径，必须有测试守护。
library;

import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// v1 时代即存在的四张表（DDL 与 schemaVersion=1 时的导出一致）。
const _v1Tables = [
  '''CREATE TABLE IF NOT EXISTS "conversations" ("id" TEXT NOT NULL, "title" TEXT NOT NULL DEFAULT '新会话', "character_id" TEXT NULL, "pet_model_id" TEXT NULL, "api_profile_id" TEXT NOT NULL, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "archived" INTEGER NOT NULL DEFAULT 0 CHECK ("archived" IN (0, 1)), PRIMARY KEY ("id"))''',
  '''CREATE TABLE IF NOT EXISTS "messages" ("id" TEXT NOT NULL, "conversation_id" TEXT NOT NULL, "role" TEXT NOT NULL, "content" TEXT NOT NULL DEFAULT '', "raw_content" TEXT NOT NULL DEFAULT '', "emotion_events" TEXT NOT NULL DEFAULT '[]', "status" TEXT NOT NULL DEFAULT 'done', "created_at" INTEGER NOT NULL, PRIMARY KEY ("id"))''',
  '''CREATE TABLE IF NOT EXISTS "api_profiles" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "base_url" TEXT NOT NULL, "api_key" TEXT NOT NULL DEFAULT '', "model" TEXT NOT NULL, "temperature" REAL NOT NULL DEFAULT 1.0, "max_tokens" INTEGER NULL, "extra_headers" TEXT NOT NULL DEFAULT '{}', "is_default" INTEGER NOT NULL DEFAULT 0 CHECK ("is_default" IN (0, 1)), PRIMARY KEY ("id"))''',
  '''CREATE TABLE IF NOT EXISTS "settings" ("key" TEXT NOT NULL, "value" TEXT NOT NULL, PRIMARY KEY ("key"))''',
];

/// v2 新增的角色卡表。
const _v2CharactersTable =
    '''CREATE TABLE IF NOT EXISTS "characters" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "description" TEXT NOT NULL DEFAULT '', "personality" TEXT NOT NULL DEFAULT '', "scenario" TEXT NOT NULL DEFAULT '', "first_message" TEXT NOT NULL DEFAULT '', "example_dialogue" TEXT NOT NULL DEFAULT '', "avatar_path" TEXT NULL, "source" TEXT NOT NULL DEFAULT 'manual', "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, PRIMARY KEY ("id"))''';

/// v3~v5 增量表（v6 未改动，DDL 与 schemaVersion=5 时的定义一致）。
const _v3ToV5Tables = [
  '''CREATE TABLE IF NOT EXISTS "pet_models" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "dir_path" TEXT NOT NULL, "entry_json_path" TEXT NOT NULL, "thumbnail_path" TEXT NULL, "expressions" TEXT NOT NULL DEFAULT '[]', "motion_groups" TEXT NOT NULL DEFAULT '{}', "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, PRIMARY KEY ("id"))''',
  '''CREATE TABLE IF NOT EXISTS "emotion_mappings" ("id" TEXT NOT NULL, "pet_model_id" TEXT NULL, "tag" TEXT NOT NULL, "action_type" TEXT NOT NULL, "target_id" TEXT NOT NULL, "priority" INTEGER NOT NULL DEFAULT 1, "enabled" INTEGER NOT NULL DEFAULT 1 CHECK ("enabled" IN (0, 1)), PRIMARY KEY ("id"))''',
  '''CREATE TABLE IF NOT EXISTS "tts_profiles" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "provider" TEXT NOT NULL, "voice_id" TEXT NOT NULL DEFAULT '', "speed" REAL NOT NULL DEFAULT 1.0, "model" TEXT NOT NULL DEFAULT '', "api_key" TEXT NOT NULL DEFAULT '', "base_url" TEXT NOT NULL DEFAULT '', "is_default" INTEGER NOT NULL DEFAULT 0 CHECK ("is_default" IN (0, 1)), PRIMARY KEY ("id"))''',
  '''CREATE TABLE IF NOT EXISTS "custom_voices" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "description" TEXT NOT NULL, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, PRIMARY KEY ("id"))''',
];

/// v6 时代的 conversations（v1 DDL + voice_enabled 列）。
const _v6ConversationsTable =
    '''CREATE TABLE IF NOT EXISTS "conversations" ("id" TEXT NOT NULL, "title" TEXT NOT NULL DEFAULT '新会话', "character_id" TEXT NULL, "pet_model_id" TEXT NULL, "api_profile_id" TEXT NOT NULL, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "archived" INTEGER NOT NULL DEFAULT 0 CHECK ("archived" IN (0, 1)), "voice_enabled" INTEGER NOT NULL DEFAULT 1 CHECK ("voice_enabled" IN (0, 1)), PRIMARY KEY ("id"))''';

/// v6 时代的 characters（v2 DDL + 记忆列）。
const _v6CharactersTable =
    '''CREATE TABLE IF NOT EXISTS "characters" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "description" TEXT NOT NULL DEFAULT '', "personality" TEXT NOT NULL DEFAULT '', "scenario" TEXT NOT NULL DEFAULT '', "first_message" TEXT NOT NULL DEFAULT '', "example_dialogue" TEXT NOT NULL DEFAULT '', "avatar_path" TEXT NULL, "source" TEXT NOT NULL DEFAULT 'manual', "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "memory_summary" TEXT NOT NULL DEFAULT '', "memory_updated_at" INTEGER NULL, PRIMARY KEY ("id"))''';

/// v7 时代的 messages（v1 DDL + 附图列，无 kind）。
const _v7MessagesTable =
    '''CREATE TABLE IF NOT EXISTS "messages" ("id" TEXT NOT NULL, "conversation_id" TEXT NOT NULL, "role" TEXT NOT NULL, "content" TEXT NOT NULL DEFAULT '', "raw_content" TEXT NOT NULL DEFAULT '', "emotion_events" TEXT NOT NULL DEFAULT '[]', "status" TEXT NOT NULL DEFAULT 'done', "created_at" INTEGER NOT NULL, "image_paths" TEXT NOT NULL DEFAULT '[]', "image_summary" TEXT NOT NULL DEFAULT '', PRIMARY KEY ("id"))''';

/// v8 时代的 conversations（v6 + 背景板）。
const _v8ConversationsTable =
    '''CREATE TABLE IF NOT EXISTS "conversations" ("id" TEXT NOT NULL, "title" TEXT NOT NULL DEFAULT '新会话', "character_id" TEXT NULL, "pet_model_id" TEXT NULL, "api_profile_id" TEXT NOT NULL, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "archived" INTEGER NOT NULL DEFAULT 0 CHECK ("archived" IN (0, 1)), "voice_enabled" INTEGER NOT NULL DEFAULT 1 CHECK ("voice_enabled" IN (0, 1)), "background_path" TEXT NULL, PRIMARY KEY ("id"))''';

/// v8 时代的 messages（v7 + kind）。
const _v8MessagesTable =
    '''CREATE TABLE IF NOT EXISTS "messages" ("id" TEXT NOT NULL, "conversation_id" TEXT NOT NULL, "role" TEXT NOT NULL, "content" TEXT NOT NULL DEFAULT '', "raw_content" TEXT NOT NULL DEFAULT '', "emotion_events" TEXT NOT NULL DEFAULT '[]', "status" TEXT NOT NULL DEFAULT 'done', "created_at" INTEGER NOT NULL, "image_paths" TEXT NOT NULL DEFAULT '[]', "image_summary" TEXT NOT NULL DEFAULT '', "kind" TEXT NOT NULL DEFAULT 'text', PRIMARY KEY ("id"))''';

/// v8 时代的 characters（v6 + 用户画像）。
const _v8CharactersTable =
    '''CREATE TABLE IF NOT EXISTS "characters" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "description" TEXT NOT NULL DEFAULT '', "personality" TEXT NOT NULL DEFAULT '', "scenario" TEXT NOT NULL DEFAULT '', "first_message" TEXT NOT NULL DEFAULT '', "example_dialogue" TEXT NOT NULL DEFAULT '', "avatar_path" TEXT NULL, "source" TEXT NOT NULL DEFAULT 'manual', "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "memory_summary" TEXT NOT NULL DEFAULT '', "memory_updated_at" INTEGER NULL, "user_summary" TEXT NOT NULL DEFAULT '', PRIMARY KEY ("id"))''';

const _v8StickersTable =
    '''CREATE TABLE IF NOT EXISTS "stickers" ("id" TEXT NOT NULL, "character_id" TEXT NOT NULL, "mood" TEXT NOT NULL, "file_path" TEXT NOT NULL, "created_at" INTEGER NOT NULL, PRIMARY KEY ("id"))''';

/// v10 时代的 agent_sessions（还没有会话级权限两列）。
void main() {
  test('v1 → 当前版本：旧数据无损，v2/v3 新表创建', () async {
    final executor = NativeDatabase.memory(
      setup: (db) {
        for (final ddl in _v1Tables) {
          db.execute(ddl);
        }
        db.execute('PRAGMA user_version = 1');
        db.execute(
          "INSERT INTO api_profiles (id, name, base_url, api_key, model, is_default) "
          "VALUES ('p1', '测试供应商', 'https://api.example.com/v1', 'sk-test', 'm1', 1)",
        );
        db.execute(
          "INSERT INTO conversations (id, title, api_profile_id, created_at, updated_at) "
          "VALUES ('c1', '旧会话', 'p1', 1700000000000, 1700000000000)",
        );
        db.execute(
          "INSERT INTO messages (id, conversation_id, role, content, raw_content, status, created_at) "
          "VALUES ('m1', 'c1', 'user', '旧消息', '旧消息', 'done', 1700000000000)",
        );
      },
    );

    final db = AppDatabase.forTesting(executor);

    // 旧数据完好。
    final profiles = await db.select(db.apiProfiles).get();
    expect(profiles, hasLength(1));
    expect(profiles.single.name, '测试供应商');
    expect(profiles.single.baseUrl, 'https://api.example.com/v1');

    final convs = await db.select(db.conversations).get();
    expect(convs, hasLength(1));
    expect(convs.single.title, '旧会话');
    // v1 已含 character_id 列（M1 起即存在），升级后可正常读取。
    expect(convs.single.characterId, isNull);
    // v6 新列：存量会话拿到默认 voice_enabled=1。
    expect(convs.single.voiceEnabled, isTrue);

    final messages = await db.select(db.messages).get();
    expect(messages, hasLength(1));
    expect(messages.single.content, '旧消息');
    // v7 新列：存量消息拿到默认附图列。
    expect(messages.single.imagePaths, '[]');
    expect(messages.single.imageSummary, '');

    // 新列写读回环。
    await (db.update(db.messages)..where((t) => t.id.equals('m1'))).write(
      const MessagesCompanion(
        imagePaths: Value('["/a.jpg"]'),
        imageSummary: Value('一张图'),
      ),
    );
    final msg = await db.select(db.messages).getSingle();
    expect(msg.imagePaths, '["/a.jpg"]');
    expect(msg.imageSummary, '一张图');

    // v2/v3/v5 新表已创建且可用。
    expect(await db.select(db.characters).get(), isEmpty);
    expect(await db.select(db.petModels).get(), isEmpty);
    expect(await db.select(db.emotionMappings).get(), isEmpty);
    expect(await db.select(db.ttsProfiles).get(), isEmpty);
    expect(await db.select(db.customVoices).get(), isEmpty);

    // v6 新列：此路径 characters 由 createTable 按当前定义创建，
    // 新行的记忆列拿到默认值。
    await db
        .into(db.characters)
        .insert(
          CharactersCompanion.insert(
            id: 'ch1',
            name: '星野雀',
            createdAt: DateTime(2023),
            updatedAt: DateTime(2023),
          ),
        );
    final ch = await db.select(db.characters).getSingle();
    expect(ch.memorySummary, '');
    expect(ch.memoryUpdatedAt, isNull);

    // user_version 已推进。
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, db.schemaVersion);

    await db.close();
  });

  test('v2 → 当前版本：角色数据无损，仅补 v3 表', () async {
    final executor = NativeDatabase.memory(
      setup: (db) {
        for (final ddl in _v1Tables) {
          db.execute(ddl);
        }
        db.execute(_v2CharactersTable);
        db.execute('PRAGMA user_version = 2');
        db.execute(
          "INSERT INTO characters (id, name, created_at, updated_at) "
          "VALUES ('ch1', '星野雀', 1700000000000, 1700000000000)",
        );
      },
    );

    final db = AppDatabase.forTesting(executor);

    final characters = await db.select(db.characters).get();
    expect(characters, hasLength(1));
    expect(characters.single.name, '星野雀');
    // v6 新列：v2 预置的角色表走 addColumn 路径，存量行拿到默认记忆列。
    expect(characters.single.memorySummary, '');
    expect(characters.single.memoryUpdatedAt, isNull);
    // v3 新表存在。
    expect(await db.select(db.petModels).get(), isEmpty);
    expect(await db.select(db.emotionMappings).get(), isEmpty);

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, db.schemaVersion);

    await db.close();
  });

  test('v5 → 当前版本：补会话语音列与角色记忆列，存量行拿到默认值', () async {
    final executor = NativeDatabase.memory(
      setup: (db) {
        for (final ddl in [
          ..._v1Tables,
          _v2CharactersTable,
          ..._v3ToV5Tables,
        ]) {
          db.execute(ddl);
        }
        db.execute('PRAGMA user_version = 5');
        db.execute(
          "INSERT INTO api_profiles (id, name, base_url, api_key, model, is_default) "
          "VALUES ('p1', '测试供应商', 'https://api.example.com/v1', 'sk-test', 'm1', 1)",
        );
        db.execute(
          "INSERT INTO characters (id, name, created_at, updated_at) "
          "VALUES ('ch1', '星野雀', 1700000000000, 1700000000000)",
        );
        db.execute(
          "INSERT INTO conversations (id, title, character_id, api_profile_id, created_at, updated_at) "
          "VALUES ('c1', '旧会话', 'ch1', 'p1', 1700000000000, 1700000000000)",
        );
        db.execute(
          "INSERT INTO messages (id, conversation_id, role, content, raw_content, status, created_at) "
          "VALUES ('m1', 'c1', 'user', '旧消息', '旧消息', 'done', 1700000000000)",
        );
      },
    );

    final db = AppDatabase.forTesting(executor);

    // 存量会话：voice_enabled 默认 true。
    final convs = await db.select(db.conversations).get();
    expect(convs, hasLength(1));
    expect(convs.single.voiceEnabled, isTrue);

    // 存量角色：记忆列默认空、水位线 null。
    final ch = await db.select(db.characters).getSingle();
    expect(ch.memorySummary, '');
    expect(ch.memoryUpdatedAt, isNull);

    // v7 新列：存量消息拿到默认附图列。
    final messages = await db.select(db.messages).get();
    expect(messages.single.imagePaths, '[]');
    expect(messages.single.imageSummary, '');

    // 新列可正常读写。
    await (db.update(db.conversations)..where((t) => t.id.equals('c1'))).write(
      const ConversationsCompanion(voiceEnabled: Value(false)),
    );
    expect(
      (await db.select(db.conversations).getSingle()).voiceEnabled,
      isFalse,
    );
    await (db.update(db.characters)..where((t) => t.id.equals('ch1'))).write(
      CharactersCompanion(
        memorySummary: const Value('喜欢草莓'),
        memoryUpdatedAt: Value(DateTime(2026)),
      ),
    );
    final updated = await db.select(db.characters).getSingle();
    expect(updated.memorySummary, '喜欢草莓');
    expect(updated.memoryUpdatedAt, isNotNull);
    await (db.update(db.messages)..where((t) => t.id.equals('m1'))).write(
      const MessagesCompanion(
        imagePaths: Value('["/a.jpg"]'),
        imageSummary: Value('一张图'),
      ),
    );
    final msg = await db.select(db.messages).getSingle();
    expect(msg.imagePaths, '["/a.jpg"]');
    expect(msg.imageSummary, '一张图');

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, db.schemaVersion);

    await db.close();
  });

  test('v6 → 当前版本：补消息附图列，存量行拿到默认值', () async {
    final executor = NativeDatabase.memory(
      setup: (db) {
        for (final ddl in [
          _v6ConversationsTable,
          _v1Tables[1], // messages（v6 时代仍为 v1 DDL）
          _v1Tables[2], // api_profiles
          _v1Tables[3], // settings
          _v6CharactersTable,
          ..._v3ToV5Tables,
        ]) {
          db.execute(ddl);
        }
        db.execute('PRAGMA user_version = 6');
        db.execute(
          "INSERT INTO api_profiles (id, name, base_url, api_key, model, is_default) "
          "VALUES ('p1', '测试供应商', 'https://api.example.com/v1', 'sk-test', 'm1', 1)",
        );
        db.execute(
          "INSERT INTO characters (id, name, created_at, updated_at) "
          "VALUES ('ch1', '星野雀', 1700000000000, 1700000000000)",
        );
        db.execute(
          "INSERT INTO conversations (id, title, character_id, api_profile_id, created_at, updated_at) "
          "VALUES ('c1', '旧会话', 'ch1', 'p1', 1700000000000, 1700000000000)",
        );
        db.execute(
          "INSERT INTO messages (id, conversation_id, role, content, raw_content, status, created_at) "
          "VALUES ('m1', 'c1', 'user', '旧消息', '旧消息', 'done', 1700000000000)",
        );
      },
    );

    final db = AppDatabase.forTesting(executor);

    // 旧数据完好。
    final messages = await db.select(db.messages).get();
    expect(messages, hasLength(1));
    expect(messages.single.content, '旧消息');
    // v7 新列：存量消息拿到默认附图列。
    expect(messages.single.imagePaths, '[]');
    expect(messages.single.imageSummary, '');

    // v6 列不受影响。
    expect(
      (await db.select(db.conversations).getSingle()).voiceEnabled,
      isTrue,
    );
    expect((await db.select(db.characters).getSingle()).memorySummary, '');

    // 新列写读回环。
    await (db.update(db.messages)..where((t) => t.id.equals('m1'))).write(
      const MessagesCompanion(
        imagePaths: Value('["/a.jpg","/b.jpg"]'),
        imageSummary: Value('两张图'),
      ),
    );
    final msg = await db.select(db.messages).getSingle();
    expect(msg.imagePaths, '["/a.jpg","/b.jpg"]');
    expect(msg.imageSummary, '两张图');

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, db.schemaVersion); // 7

    await db.close();
  });

  test('v7 → 当前版本：补消息 kind、角色用户画像、会话背景板，创建表情包表', () async {
    final executor = NativeDatabase.memory(
      setup: (db) {
        for (final ddl in [
          _v6ConversationsTable,
          _v7MessagesTable,
          _v1Tables[2], // api_profiles
          _v1Tables[3], // settings
          _v6CharactersTable,
          ..._v3ToV5Tables,
        ]) {
          db.execute(ddl);
        }
        db.execute('PRAGMA user_version = 7');
        db.execute(
          "INSERT INTO api_profiles (id, name, base_url, api_key, model, is_default) "
          "VALUES ('p1', '测试供应商', 'https://api.example.com/v1', 'sk-test', 'm1', 1)",
        );
        db.execute(
          "INSERT INTO characters (id, name, memory_summary, created_at, updated_at) "
          "VALUES ('ch1', '星野雀', '旧记忆', 1700000000000, 1700000000000)",
        );
        db.execute(
          "INSERT INTO conversations (id, title, character_id, api_profile_id, created_at, updated_at) "
          "VALUES ('c1', '旧会话', 'ch1', 'p1', 1700000000000, 1700000000000)",
        );
        db.execute(
          "INSERT INTO messages (id, conversation_id, role, content, raw_content, status, created_at) "
          "VALUES ('m1', 'c1', 'user', '旧消息', '旧消息', 'done', 1700000000000)",
        );
      },
    );

    final db = AppDatabase.forTesting(executor);

    // v8 新列默认值：存量行无损。
    final msg = await db.select(db.messages).getSingle();
    expect(msg.content, '旧消息');
    expect(msg.kind, 'text');
    final ch = await db.select(db.characters).getSingle();
    expect(ch.memorySummary, '旧记忆');
    expect(ch.userSummary, '');
    final conv = await db.select(db.conversations).getSingle();
    expect(conv.voiceEnabled, isTrue);
    expect(conv.backgroundPath, isNull);

    // v8 新表存在且可用。
    expect(await db.select(db.stickers).get(), isEmpty);
    await db
        .into(db.stickers)
        .insert(
          StickersCompanion.insert(
            id: 's1',
            characterId: 'ch1',
            mood: 'happy',
            filePath: '/tmp/s1.jpg',
            createdAt: DateTime(2026),
          ),
        );
    expect(await db.select(db.stickers).get(), hasLength(1));

    // 新列写读回环。
    await (db.update(db.messages)..where((t) => t.id.equals('m1'))).write(
      const MessagesCompanion(kind: Value('sticker')),
    );
    await (db.update(db.characters)..where((t) => t.id.equals('ch1'))).write(
      const CharactersCompanion(userSummary: Value('用户爱夜聊')),
    );
    await (db.update(db.conversations)..where((t) => t.id.equals('c1'))).write(
      const ConversationsCompanion(backgroundPath: Value('/bg.jpg')),
    );
    expect((await db.select(db.messages).getSingle()).kind, 'sticker');
    expect((await db.select(db.characters).getSingle()).userSummary, '用户爱夜聊');
    expect(
      (await db.select(db.conversations).getSingle()).backgroundPath,
      '/bg.jpg',
    );

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, db.schemaVersion); // 8

    await db.close();
  });

  test('v8 → v9：创建记忆游标/长期事实表与索引，旧数据无损', () async {
    final executor = NativeDatabase.memory(
      setup: (db) {
        for (final ddl in [
          _v8ConversationsTable,
          _v8MessagesTable,
          _v1Tables[2], // api_profiles
          _v1Tables[3], // settings
          _v8CharactersTable,
          ..._v3ToV5Tables,
          _v8StickersTable,
        ]) {
          db.execute(ddl);
        }
        db.execute('PRAGMA user_version = 8');
        db.execute(
          "INSERT INTO api_profiles (id, name, base_url, api_key, model, is_default) "
          "VALUES ('p1', '测试供应商', 'https://api.example.com/v1', 'sk-test', 'm1', 1)",
        );
        db.execute(
          "INSERT INTO characters (id, name, memory_summary, user_summary, created_at, updated_at) "
          "VALUES ('ch1', '星野雀', '旧记忆', '旧画像', 1700000000000, 1700000000000)",
        );
        db.execute(
          "INSERT INTO conversations (id, title, character_id, api_profile_id, background_path, created_at, updated_at) "
          "VALUES ('c1', '旧会话', 'ch1', 'p1', '/bg8.jpg', 1700000000000, 1700000000000)",
        );
        db.execute(
          "INSERT INTO messages (id, conversation_id, role, content, raw_content, status, kind, created_at) "
          "VALUES ('m1', 'c1', 'user', '旧消息', '旧消息', 'done', 'sticker', 1700000000000)",
        );
        db.execute(
          "INSERT INTO stickers (id, character_id, mood, file_path, created_at) "
          "VALUES ('s1', 'ch1', 'happy', '/s1.jpg', 1700000000000)",
        );
      },
    );

    final db = AppDatabase.forTesting(executor);

    // 旧数据完好。
    final conv = await db.select(db.conversations).getSingle();
    expect(conv.title, '旧会话');
    expect(conv.backgroundPath, '/bg8.jpg');
    final ch = await db.select(db.characters).getSingle();
    expect(ch.memorySummary, '旧记忆');
    expect(ch.userSummary, '旧画像');
    final msg = await db.select(db.messages).getSingle();
    expect(msg.content, '旧消息');
    expect(msg.kind, 'sticker');
    expect(await db.select(db.stickers).get(), hasLength(1));

    // v9 新表为空且可写。
    expect(await db.select(db.memoryCursors).get(), isEmpty);
    expect(await db.select(db.memoryFacts).get(), isEmpty);
    await db
        .into(db.memoryCursors)
        .insert(
          MemoryCursorsCompanion.insert(
            characterId: 'ch1',
            conversationId: 'c1',
            summarizedAt: DateTime(2026, 1, 2),
          ),
        );
    await db
        .into(db.memoryFacts)
        .insert(
          MemoryFactsCompanion.insert(
            id: 'f1',
            characterId: 'ch1',
            fact: '和用户去了关山',
            occurredAt: DateTime(2026, 1, 2),
            createdAt: DateTime(2026, 1, 2),
          ),
        );
    final cursor = await db.select(db.memoryCursors).getSingle();
    expect(cursor.conversationId, 'c1');
    final fact = await db.select(db.memoryFacts).getSingle();
    expect(fact.fact, '和用户去了关山');

    // 索引已建（跨角色最近事实查询依赖它）。
    final index = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name = 'idx_memory_facts_character_occurred'",
        )
        .get();
    expect(index, hasLength(1));

    // v10/v11 Agent 表已随 v13 移除。
    final agentTables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name IN ('agent_sessions', 'agent_messages')",
        )
        .get();
    expect(agentTables, isEmpty);

    // v14：候选回复表 + 新列；旧消息默认无候选，旧角色默认空开场白列表。
    expect(msg.activeVariantId, isNull);
    expect(ch.alternateGreetings, '[]');
    expect(await db.select(db.messageVariants).get(), isEmpty);
    await db
        .into(db.messageVariants)
        .insert(
          MessageVariantsCompanion.insert(
            id: 'v1',
            messageId: 'm1',
            content: const Value('旧消息'),
            rawContent: const Value('旧消息'),
            emotionEvents: const Value('[]'),
            createdAt: DateTime(2026, 1, 2),
          ),
        );
    expect((await db.select(db.messageVariants).getSingle()).messageId, 'm1');
    final variantIndex = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name = 'idx_message_variants_message'",
        )
        .get();
    expect(variantIndex, hasLength(1));

    // v15：世界书表与索引。
    expect(await db.select(db.loreEntries).get(), isEmpty);
    await db
        .into(db.loreEntries)
        .insert(
          LoreEntriesCompanion.insert(
            id: 'lore1',
            characterId: 'ch1',
            createdAt: DateTime(2026, 1, 3),
          ),
        );
    expect((await db.select(db.loreEntries).getSingle()).characterId, 'ch1');
    final loreIndex = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name = 'idx_lore_character'",
        )
        .get();
    expect(loreIndex, hasLength(1));

    // v16：群聊参与者 + 分支指针；旧会话/消息默认无值。
    expect(conv.parentConversationId, isNull);
    expect(conv.branchFromMessageId, isNull);
    expect(msg.speakerCharacterId, isNull);
    expect(await db.select(db.conversationParticipants).get(), isEmpty);
    await db
        .into(db.conversationParticipants)
        .insert(
          ConversationParticipantsCompanion.insert(
            id: 'p1',
            conversationId: 'c1',
            characterId: 'ch1',
            createdAt: DateTime(2026, 1, 4),
          ),
        );
    expect(
      (await db.select(db.conversationParticipants).getSingle()).characterId,
      'ch1',
    );
    final participantIndex = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name = 'idx_participants_conversation'",
        )
        .get();
    expect(participantIndex, hasLength(1));

    // v17：扩展档案 / 第三方扩展 / 世界书原文 / 角色版本表。
    expect(ch.profileJson, '{}');
    expect(ch.extensionsJson, '{}');
    expect((await db.select(db.loreEntries).getSingle()).sourceJson, '{}');
    expect(await db.select(db.characterVersions).get(), isEmpty);
    await db
        .into(db.characterVersions)
        .insert(
          CharacterVersionsCompanion.insert(
            id: 'ver1',
            characterId: 'ch1',
            createdAtMs: 1700000000000,
          ),
        );
    expect(
      (await db.select(db.characterVersions).getSingle()).characterId,
      'ch1',
    );
    final versionIndex = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name = 'idx_character_versions_character'",
        )
        .get();
    expect(versionIndex, hasLength(1));

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, db.schemaVersion);

    await db.close();
  });

  test('v16 → v17：补扩展档案列、世界书原文列、角色版本表', () async {
    final executor = NativeDatabase.memory(
      setup: (db) {
        db.execute(
          'CREATE TABLE "characters" ('
          '"id" TEXT NOT NULL, "name" TEXT NOT NULL, '
          '"description" TEXT NOT NULL DEFAULT \'\', '
          '"personality" TEXT NOT NULL DEFAULT \'\', '
          '"scenario" TEXT NOT NULL DEFAULT \'\', '
          '"first_message" TEXT NOT NULL DEFAULT \'\', '
          '"example_dialogue" TEXT NOT NULL DEFAULT \'\', '
          '"avatar_path" TEXT NULL, '
          '"source" TEXT NOT NULL DEFAULT \'manual\', '
          '"created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, '
          '"memory_summary" TEXT NOT NULL DEFAULT \'\', '
          '"memory_updated_at" INTEGER NULL, '
          '"user_summary" TEXT NOT NULL DEFAULT \'\', '
          '"alternate_greetings" TEXT NOT NULL DEFAULT \'[]\', '
          'PRIMARY KEY ("id"))',
        );
        db.execute(
          'CREATE TABLE "lore_entries" ('
          '"id" TEXT NOT NULL, "character_id" TEXT NOT NULL, '
          '"keys" TEXT NOT NULL DEFAULT \'[]\', '
          '"content" TEXT NOT NULL DEFAULT \'\', '
          '"position" TEXT NOT NULL DEFAULT \'before\', '
          '"depth" INTEGER NOT NULL DEFAULT 0, '
          '"priority" INTEGER NOT NULL DEFAULT 0, '
          '"enabled" INTEGER NOT NULL DEFAULT 1 CHECK ("enabled" IN (0, 1)), '
          '"created_at" INTEGER NOT NULL, '
          'PRIMARY KEY ("id"))',
        );
        // v16 已存在群聊参与者表（尚无 v18 的 enabled 列）。
        db.execute(
          'CREATE TABLE "conversation_participants" ('
          '"id" TEXT NOT NULL, "conversation_id" TEXT NOT NULL, '
          '"character_id" TEXT NOT NULL, '
          '"sort_order" INTEGER NOT NULL DEFAULT 0, '
          '"created_at" INTEGER NOT NULL, '
          'PRIMARY KEY ("id"))',
        );
        // v19 会向 conversations 补群聊设置列；此测试只关心其他表，建最小表即可。
        db.execute(
          'CREATE TABLE "conversations" ("id" TEXT NOT NULL, PRIMARY KEY ("id"))',
        );
        db.execute('PRAGMA user_version = 16');
        db.execute(
          "INSERT INTO characters (id, name, memory_summary, created_at, updated_at) "
          "VALUES ('ch1', '星野雀', '旧记忆', 1700000000000, 1700000000000)",
        );
        db.execute(
          "INSERT INTO lore_entries (id, character_id, keys, content, created_at) "
          "VALUES ('lore1', 'ch1', '[\"天台\"]', '天台设定', 1700000000000)",
        );
        db.execute(
          "INSERT INTO conversation_participants (id, conversation_id, character_id, sort_order, created_at) "
          "VALUES ('part1', 'conv1', 'ch1', 0, 1700000000000)",
        );
      },
    );

    final db = AppDatabase.forTesting(executor);

    final ch = await db.select(db.characters).getSingle();
    expect(ch.name, '星野雀');
    expect(ch.memorySummary, '旧记忆');
    expect(ch.profileJson, '{}');
    expect(ch.extensionsJson, '{}');

    final lore = await db.select(db.loreEntries).getSingle();
    expect(lore.content, '天台设定');
    expect(lore.sourceJson, '{}');

    // v18/v20：存量群成员默认启用，独立供应商默认跟随会话。
    final participant = await db
        .select(db.conversationParticipants)
        .getSingle();
    expect(participant.enabled, isTrue);
    expect(participant.apiProfileId, isNull);

    expect(await db.select(db.characterVersions).get(), isEmpty);
    await db
        .into(db.characterVersions)
        .insert(
          CharacterVersionsCompanion.insert(
            id: 'ver1',
            characterId: 'ch1',
            createdAtMs: 1700000000001,
            trigger: const Value('manual'),
          ),
        );
    expect(
      (await db.select(db.characterVersions).getSingle()).trigger,
      'manual',
    );
    final versionIndex = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name = 'idx_character_versions_character'",
        )
        .get();
    expect(versionIndex, hasLength(1));

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, db.schemaVersion); // 20

    await db.close();
  });

  test('v17 → 当前版本：群聊参与者 enabled + 群聊设置列', () async {
    final executor = NativeDatabase.memory(
      setup: (db) {
        db.execute(
          'CREATE TABLE "conversation_participants" ('
          '"id" TEXT NOT NULL, "conversation_id" TEXT NOT NULL, '
          '"character_id" TEXT NOT NULL, '
          '"sort_order" INTEGER NOT NULL DEFAULT 0, '
          '"created_at" INTEGER NOT NULL, '
          'PRIMARY KEY ("id"))',
        );
        db.execute(
          'CREATE TABLE "conversations" ("id" TEXT NOT NULL, PRIMARY KEY ("id"))',
        );
        db.execute('PRAGMA user_version = 17');
        db.execute(
          "INSERT INTO conversation_participants (id, conversation_id, character_id, sort_order, created_at) "
          "VALUES ('part1', 'conv1', 'ch1', 0, 1700000000000)",
        );
      },
    );

    final db = AppDatabase.forTesting(executor);
    final participant = await db
        .select(db.conversationParticipants)
        .getSingle();
    expect(participant.characterId, 'ch1');
    expect(participant.enabled, isTrue);
    expect(participant.apiProfileId, isNull);

    await (db.update(
      db.conversationParticipants,
    )..where((t) => t.id.equals('part1'))).write(
      const ConversationParticipantsCompanion(
        enabled: Value(false),
        apiProfileId: Value('p2'),
      ),
    );
    final updated = await db.select(db.conversationParticipants).getSingle();
    expect(updated.enabled, isFalse);
    expect(updated.apiProfileId, 'p2');

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, db.schemaVersion); // 20
    await db.close();
  });

  test('v18 → v19：会话补群聊设置列，默认全员回复 + 2 轮拌嘴', () async {
    final executor = NativeDatabase.memory(
      setup: (db) {
        db.execute(
          'CREATE TABLE "conversations" ("id" TEXT NOT NULL, PRIMARY KEY ("id"))',
        );
        // v18 已存在群聊参与者表（含 enabled，尚无 api_profile_id）。
        db.execute(
          'CREATE TABLE "conversation_participants" ('
          '"id" TEXT NOT NULL, "conversation_id" TEXT NOT NULL, '
          '"character_id" TEXT NOT NULL, '
          '"sort_order" INTEGER NOT NULL DEFAULT 0, '
          '"enabled" INTEGER NOT NULL DEFAULT 1 CHECK ("enabled" IN (0, 1)), '
          '"created_at" INTEGER NOT NULL, '
          'PRIMARY KEY ("id"))',
        );
        db.execute('PRAGMA user_version = 18');
        db.execute("INSERT INTO conversations (id) VALUES ('c1')");
        db.execute(
          "INSERT INTO conversation_participants (id, conversation_id, character_id, sort_order, created_at) "
          "VALUES ('part1', 'conv1', 'ch1', 0, 1700000000000)",
        );
      },
    );

    final db = AppDatabase.forTesting(executor);
    final row = await db
        .customSelect(
          'SELECT group_auto_reply, group_banter_rounds FROM conversations '
          "WHERE id = 'c1'",
        )
        .getSingle();
    expect(row.data['group_auto_reply'], 1);
    expect(row.data['group_banter_rounds'], 2);
    // v20：存量群成员没有独立供应商，默认跟随会话。
    expect(
      (await db.select(db.conversationParticipants).getSingle()).apiProfileId,
      isNull,
    );

    await (db.update(db.conversations)..where((t) => t.id.equals('c1'))).write(
      const ConversationsCompanion(
        groupAutoReply: Value(false),
        groupBanterRounds: Value(3),
      ),
    );
    final updated = await db
        .customSelect(
          'SELECT group_auto_reply, group_banter_rounds FROM conversations '
          "WHERE id = 'c1'",
        )
        .getSingle();
    expect(updated.data['group_auto_reply'], 0);
    expect(updated.data['group_banter_rounds'], 3);

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, db.schemaVersion); // 20
    await db.close();
  });

  test('v19 → v20：群成员补独立供应商列，默认 null', () async {
    final executor = NativeDatabase.memory(
      setup: (db) {
        db.execute(
          'CREATE TABLE "conversation_participants" ('
          '"id" TEXT NOT NULL, "conversation_id" TEXT NOT NULL, '
          '"character_id" TEXT NOT NULL, '
          '"sort_order" INTEGER NOT NULL DEFAULT 0, '
          '"enabled" INTEGER NOT NULL DEFAULT 1 CHECK ("enabled" IN (0, 1)), '
          '"created_at" INTEGER NOT NULL, '
          'PRIMARY KEY ("id"))',
        );
        db.execute('PRAGMA user_version = 19');
        db.execute(
          "INSERT INTO conversation_participants (id, conversation_id, character_id, sort_order, created_at) "
          "VALUES ('part1', 'conv1', 'ch1', 0, 1700000000000)",
        );
      },
    );

    final db = AppDatabase.forTesting(executor);
    var participant = await db.select(db.conversationParticipants).getSingle();
    expect(participant.enabled, isTrue);
    expect(participant.apiProfileId, isNull);

    await (db.update(
      db.conversationParticipants,
    )..where((t) => t.id.equals('part1'))).write(
      const ConversationParticipantsCompanion(apiProfileId: Value('p2')),
    );
    participant = await db.select(db.conversationParticipants).getSingle();
    expect(participant.apiProfileId, 'p2');

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, db.schemaVersion); // 20
    await db.close();
  });
}
