/// 数据库迁移测试：旧版本库升级到当前 schemaVersion 无损。
///
/// 用 NativeDatabase.memory(setup:) 预置旧表结构与数据，
/// drift 打开时按 user_version 触发 onUpgrade——这是真机升级
/// 唯一会走的代码路径，必须有测试守护。
library;

import 'package:ai_roleplay_chat/data/local/app_database.dart';
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

void main() {
  test('v1 → 当前版本：旧数据无损，v2/v3 新表创建', () async {
    final executor = NativeDatabase.memory(setup: (db) {
      for (final ddl in _v1Tables) {
        db.execute(ddl);
      }
      db.execute('PRAGMA user_version = 1');
      db.execute(
          "INSERT INTO api_profiles (id, name, base_url, api_key, model, is_default) "
          "VALUES ('p1', '测试供应商', 'https://api.example.com/v1', 'sk-test', 'm1', 1)");
      db.execute(
          "INSERT INTO conversations (id, title, api_profile_id, created_at, updated_at) "
          "VALUES ('c1', '旧会话', 'p1', 1700000000000, 1700000000000)");
      db.execute(
          "INSERT INTO messages (id, conversation_id, role, content, raw_content, status, created_at) "
          "VALUES ('m1', 'c1', 'user', '旧消息', '旧消息', 'done', 1700000000000)");
    });

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

    final messages = await db.select(db.messages).get();
    expect(messages, hasLength(1));
    expect(messages.single.content, '旧消息');

    // v2/v3 新表已创建且可用。
    expect(await db.select(db.characters).get(), isEmpty);
    expect(await db.select(db.petModels).get(), isEmpty);
    expect(await db.select(db.emotionMappings).get(), isEmpty);

    // user_version 已推进。
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, db.schemaVersion);

    await db.close();
  });

  test('v2 → 当前版本：角色数据无损，仅补 v3 表', () async {
    final executor = NativeDatabase.memory(setup: (db) {
      for (final ddl in _v1Tables) {
        db.execute(ddl);
      }
      db.execute(_v2CharactersTable);
      db.execute('PRAGMA user_version = 2');
      db.execute(
          "INSERT INTO characters (id, name, created_at, updated_at) "
          "VALUES ('ch1', '星野雀', 1700000000000, 1700000000000)");
    });

    final db = AppDatabase.forTesting(executor);

    final characters = await db.select(db.characters).get();
    expect(characters, hasLength(1));
    expect(characters.single.name, '星野雀');
    // v3 新表存在。
    expect(await db.select(db.petModels).get(), isEmpty);
    expect(await db.select(db.emotionMappings).get(), isEmpty);

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, db.schemaVersion);

    await db.close();
  });
}
