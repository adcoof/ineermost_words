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
    ])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'ai_roleplay_chat'));

  /// 测试用：注入内存执行器。
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
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
        },
      );
}
