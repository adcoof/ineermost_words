/// 通用应用设置（settings KV）：主题、记忆开关等。
library;

import 'package:drift/drift.dart';

import '../../../data/local/app_database.dart';

/// 跨会话记忆全局开关的 KV 键。
const kMemoryEnabledSetting = 'memory_enabled';

/// 空回复自动重试一次（默认开）的 KV 键。
const kAutoRetryEnabledSetting = 'auto_retry_enabled';

/// 上下文窗口（token）与跨会话原文预算（token）的 KV 键。
const kContextWindowTokensSetting = 'context_window_tokens';
const kContextWindowOtherTokensSetting = 'context_window_other_tokens';

const int kContextWindowDefault = 4096;
const int kContextWindowMin = 1024;
const int kContextWindowMax = 32768;
const int kContextWindowStep = 512;
const int kContextWindowOtherDefault = 1024;
const int kContextWindowOtherMax = 8192;

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

  /// 零正文时是否允许自动重试一次（缺省开）。
  Future<bool> autoRetryEnabled() async {
    final q = db.select(db.settings)
      ..where((t) => t.key.equals(kAutoRetryEnabledSetting));
    final row = await q.getSingleOrNull();
    return row == null || row.value == '1';
  }

  Future<void> setAutoRetryEnabled(bool enabled) async {
    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
      key: const Value(kAutoRetryEnabledSetting),
      value: Value(enabled ? '1' : '0'),
    ));
  }

  /// 上下文窗口 token 数；缺省 4096，越界自动 clamp 到 1024..32768。
  Future<int> contextWindowTokens() async {
    final q = db.select(db.settings)
      ..where((t) => t.key.equals(kContextWindowTokensSetting));
    final row = await q.getSingleOrNull();
    final parsed = int.tryParse(row?.value ?? '');
    return (parsed ?? kContextWindowDefault).clamp(
      kContextWindowMin,
      kContextWindowMax,
    );
  }

  Future<void> setContextWindowTokens(int n) async {
    final value = n.clamp(kContextWindowMin, kContextWindowMax);
    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
      key: const Value(kContextWindowTokensSetting),
      value: Value('$value'),
    ));
  }

  /// 跨会话原文预算 token 数；缺省 1024，0 表示不注入其他会话原文。
  Future<int> contextWindowOtherTokens() async {
    final q = db.select(db.settings)
      ..where((t) => t.key.equals(kContextWindowOtherTokensSetting));
    final row = await q.getSingleOrNull();
    final parsed = int.tryParse(row?.value ?? '');
    return (parsed ?? kContextWindowOtherDefault).clamp(0, kContextWindowOtherMax);
  }

  Future<void> setContextWindowOtherTokens(int n) async {
    final value = n.clamp(0, kContextWindowOtherMax);
    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
      key: const Value(kContextWindowOtherTokensSetting),
      value: Value('$value'),
    ));
  }

}
