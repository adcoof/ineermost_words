/// 应用主题：深空黑底 + 霓虹强调色的二次元科技风（视觉参考 SIGBORN 标志）。
///
/// 强调色可由用户在设置页切换（[ThemeAccents] 清单），
/// [buildTheme] 的所有 primary 相关元素随强调色联动。
library;

import 'package:flutter/material.dart';

import '../features/settings/data/app_settings_repository.dart';

/// 品牌中性色板（不随强调色变化）。
abstract final class BrandColors {
  /// 页面底色（深空靛黑）。
  static const background = Color(0xFF0D0B1E);

  /// 卡片/表面色。
  static const surface = Color(0xFF151230);

  /// 高一级表面（输入框、选中态）。
  static const surfaceHigh = Color(0xFF1E1A40);

  /// 主文字色（偏冷的白）。
  static const onSurface = Color(0xFFEDEBFF);

  /// 次级文字色（冷灰紫）。
  static const muted = Color(0xFF9A94C0);

  /// 星光青（点缀色，官网链接等固定用色）。
  static const cyan = Color(0xFF4DC9FF);

  /// 默认强调色（等价 ThemeAccents 里的霓虹紫）。
  static const violet = Color(0xFF8E7CFF);
}

/// 把强调色 key 解析为 ARGB 颜色（缺省霓虹紫）。
Color accentColorOf(String key) => Color(AppSettingsRepository.accentOf(key).argb);

ThemeData buildTheme(Color accent) {
  final scheme = ColorScheme.fromSeed(
    seedColor: accent,
    brightness: Brightness.dark,
  ).copyWith(
    primary: accent,
    secondary: BrandColors.cyan,
    surface: BrandColors.surface,
    surfaceContainerHighest: BrandColors.surfaceHigh,
    onSurface: BrandColors.onSurface,
    error: const Color(0xFFFF6B8A),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: BrandColors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: BrandColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: BrandColors.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
      iconTheme: const IconThemeData(color: BrandColors.onSurface),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF131029),
      surfaceTintColor: Colors.transparent,
      indicatorColor: accent.withValues(alpha: 0.28),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          letterSpacing: 0.5,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w400,
          color: states.contains(WidgetState.selected)
              ? accent
              : BrandColors.muted,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF2A2550),
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      isDense: true,
      fillColor: BrandColors.surfaceHigh,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: BrandColors.surfaceHigh,
      contentTextStyle: TextStyle(color: BrandColors.onSurface),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
