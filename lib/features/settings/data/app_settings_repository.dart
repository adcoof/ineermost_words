/// 通用应用设置（settings KV）：主题、记忆开关等。
library;

import 'package:drift/drift.dart';

import '../../../data/local/app_database.dart';

/// 跨会话记忆全局开关的 KV 键。
const kMemoryEnabledSetting = 'memory_enabled';

class AppSettingsRepository {
  final AppDatabase db;

  AppSettingsRepository(this.db);

  /// 当前主题 key（缺省 kThemePalettes 首个；旧版强调色 key 由
  /// themePaletteOf 兼容映射）。
  Future<String> themeKey() async {
    final q = db.select(db.settings)
      ..where((t) => t.key.equals('theme_accent'));
    final row = await q.getSingleOrNull();
    return row?.value ?? 'deep-space';
  }

  Future<void> setThemeKey(String key) async {
    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
      key: const Value('theme_accent'),
      value: Value(key),
    ));
  }

  /// 跨会话记忆开关（缺省开；与 voice_enabled 缺省关相反）。
  Future<bool> memoryEnabled() async {
    final q = db.select(db.settings)
      ..where((t) => t.key.equals(kMemoryEnabledSetting));
    final row = await q.getSingleOrNull();
    return row == null || row.value == '1';
  }

  Future<void> setMemoryEnabled(bool enabled) async {
    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
      key: const Value(kMemoryEnabledSetting),
      value: Value(enabled ? '1' : '0'),
    ));
  }
}
