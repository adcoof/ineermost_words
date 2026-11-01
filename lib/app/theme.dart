/// 应用主题：整套配色方案（深浅两亮度 × 多套二次元风格）。
///
/// [kThemePalettes] 是可切换主题清单，每套含背景/表面/文字/强调/
/// 点缀完整色板；[buildTheme] 按调色板装配 ThemeData。
/// 设置页「外观」区切换主题，key 存 settings KV `theme_accent`。
library;

import 'package:flutter/material.dart';

/// 品牌固定色（启动页等品牌视觉，不随主题变化）。
abstract final class BrandColors {
  /// 默认强调色（深空主题的霓虹紫）。
  static const violet = Color(0xFF8E7CFF);

  /// 星光青（官网链接等品牌点缀）。
  static const cyan = Color(0xFF4DC9FF);

  /// 启动页底色（深空靛黑）。
  static const background = Color(0xFF0D0B1E);

  /// 启动页主文字色。
  static const onSurface = Color(0xFFEDEBFF);

  /// 启动页次级文字色。
  static const muted = Color(0xFF9A94C0);
}

/// 一套完整主题调色板。
class ThemePalette {
  final String id;
  final String label;
  final Brightness brightness;

  /// 强调色（主按钮、选中态、导航高亮）。
  final Color accent;

  /// 点缀色（链接、次级强调）。
  final Color secondary;

  /// 页面底色。
  final Color background;

  /// 卡片/表面色。
  final Color surface;

  /// 高一级表面（输入框、选中态底色）。
  final Color surfaceHigh;

  /// 主文字色。
  final Color onSurface;

  /// 次级文字色。
  final Color muted;

  /// 分隔线。
  final Color divider;

  /// 底部导航栏底色。
  final Color navBackground;

  /// 错误色。
  final Color error;

  const ThemePalette({
    required this.id,
    required this.label,
    required this.brightness,
    required this.accent,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.onSurface,
    required this.muted,
    required this.divider,
    required this.navBackground,
    required this.error,
  });
}

/// 可切换主题清单（首个为默认）。
///
/// 旧版强调色 key（violet/cyan/rose/mint）在 [themePaletteOf] 里
/// 映射到对应主题，老用户设置无损迁移。
const List<ThemePalette> kThemePalettes = [
  ThemePalette(
    id: 'deep-space',
    label: '深空紫',
    brightness: Brightness.dark,
    accent: Color(0xFF8E7CFF),
    secondary: Color(0xFF4DC9FF),
    background: Color(0xFF0D0B1E),
    surface: Color(0xFF151230),
    surfaceHigh: Color(0xFF1E1A40),
    onSurface: Color(0xFFEDEBFF),
    muted: Color(0xFF9A94C0),
    divider: Color(0xFF2A2550),
    navBackground: Color(0xFF131029),
    error: Color(0xFFFF6B8A),
  ),
  ThemePalette(
    id: 'sakura',
    label: '樱夜粉',
    brightness: Brightness.dark,
    accent: Color(0xFFFF7BAC),
    secondary: Color(0xFFFFB3D1),
    background: Color(0xFF170E15),
    surface: Color(0xFF231420),
    surfaceHigh: Color(0xFF301B2C),
    onSurface: Color(0xFFFBEAF3),
    muted: Color(0xFFC09AAA),
    divider: Color(0xFF3A2435),
    navBackground: Color(0xFF1C1019),
    error: Color(0xFFFF8A80),
  ),
  ThemePalette(
    id: 'glacier',
    label: '青岚蓝',
    brightness: Brightness.dark,
    accent: Color(0xFF4DC9FF),
    secondary: Color(0xFF7BE0FF),
    background: Color(0xFF0A1218),
    surface: Color(0xFF101C25),
    surfaceHigh: Color(0xFF172632),
    onSurface: Color(0xFFE6F4FF),
    muted: Color(0xFF8FADC2),
    divider: Color(0xFF1F3542),
    navBackground: Color(0xFF0E1820),
    error: Color(0xFFFF6B8A),
  ),
  ThemePalette(
    id: 'minty',
    label: '薄荷绿',
    brightness: Brightness.dark,
    accent: Color(0xFF5CE0B0),
    secondary: Color(0xFF9AEED0),
    background: Color(0xFF0A1512),
    surface: Color(0xFF10201B),
    surfaceHigh: Color(0xFF172B24),
    onSurface: Color(0xFFE8FFF6),
    muted: Color(0xFF8FBFAD),
    divider: Color(0xFF1F3A31),
    navBackground: Color(0xFF0E1B17),
    error: Color(0xFFFF8A80),
  ),
  ThemePalette(
    id: 'daylight',
    label: '晨光白',
    brightness: Brightness.light,
    accent: Color(0xFF6C5CE7),
    secondary: Color(0xFF0091B5),
    background: Color(0xFFF6F4FB),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFECE9F6),
    onSurface: Color(0xFF1D1B33),
    muted: Color(0xFF6E6A8A),
    divider: Color(0xFFDDD8EC),
    navBackground: Color(0xFFFFFFFF),
    error: Color(0xFFD32F52),
  ),
];

/// 主题 key → 调色板；未知 key（含旧版强调色 key）回落默认深空紫。
ThemePalette themePaletteOf(String key) {
  for (final p in kThemePalettes) {
    if (p.id == key) return p;
  }
  // 旧版强调色 key 迁移：violet→深空紫、cyan→青岚蓝、rose→樱夜粉、mint→薄荷绿。
  return switch (key) {
    'cyan' => kThemePalettes[2],
    'rose' => kThemePalettes[1],
    'mint' => kThemePalettes[3],
    _ => kThemePalettes.first,
  };
}

/// 按调色板装配完整 ThemeData。
ThemeData buildTheme(ThemePalette p) {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: p.accent,
        brightness: p.brightness,
      ).copyWith(
        primary: p.accent,
        secondary: p.secondary,
        surface: p.surface,
        surfaceContainerHighest: p.surfaceHigh,
        onSurface: p.onSurface,
        error: p.error,
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.background,
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: p.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
      iconTheme: IconThemeData(color: p.onSurface),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.navBackground,
      surfaceTintColor: Colors.transparent,
      indicatorColor: p.accent.withValues(alpha: 0.28),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          letterSpacing: 0.5,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w400,
          color: states.contains(WidgetState.selected) ? p.accent : p.muted,
        ),
      ),
    ),
    dividerTheme: DividerThemeData(color: p.divider, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      border: const OutlineInputBorder(),
      isDense: true,
      fillColor: p.surfaceHigh,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.surfaceHigh,
      contentTextStyle: TextStyle(color: p.onSurface),
      behavior: SnackBarBehavior.floating,
    ),
    // 弹层玻璃化（v8）：半透明底 + 大圆角，与玻璃栏视觉一致。
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface.withValues(alpha: 0.96),
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
  );
}
