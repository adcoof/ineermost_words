/// 通用应用设置（settings KV）：主题强调色等。
library;

import 'package:drift/drift.dart';

import '../../../data/local/app_database.dart';

/// 主题强调色选项：key ↔ 颜色 ↔ 展示名。
class ThemeAccent {
  final String key;
  final String label;
  final int argb;

  const ThemeAccent(this.key, this.label, this.argb);
}

/// 可选强调色清单（首个为默认）。
const kThemeAccents = [
  ThemeAccent('violet', '霓虹紫', 0xFF8E7CFF),
  ThemeAccent('cyan', '星光青', 0xFF4DC9FF),
  ThemeAccent('rose', '樱粉', 0xFFFF7BAC),
  ThemeAccent('mint', '薄荷', 0xFF5CE0B0),
];

class AppSettingsRepository {
  final AppDatabase db;

  AppSettingsRepository(this.db);

  /// 当前强调色 key（缺省 'violet'）。
  Future<String> themeAccent() async {
    final q = db.select(db.settings)
      ..where((t) => t.key.equals('theme_accent'));
    final row = await q.getSingleOrNull();
    return row?.value ?? kThemeAccents.first.key;
  }

  Future<void> setThemeAccent(String key) async {
    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
      key: const Value('theme_accent'),
      value: Value(key),
    ));
  }

  /// key → 选项；未知 key 回落默认。
  static ThemeAccent accentOf(String key) => kThemeAccents.firstWhere(
        (a) => a.key == key,
        orElse: () => kThemeAccents.first,
      );
}
