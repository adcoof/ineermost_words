/// 设置主页：API / 语音 入口分列，外观主题卡片与版本信息，更多区展示工作室官网。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/glass.dart';
import 'api_profiles_page.dart';
import '../../voice/presentation/voice_settings_page.dart';

/// 奇点重现官网。
const String kSigbornSite = 'www.sigborn.xyz';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _themeKey = 'deep-space';
  bool _memoryEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _loadMemory();
  }

  Future<void> _loadTheme() async {
    final key = await ref.read(appSettingsRepositoryProvider).themeKey();
    if (mounted) setState(() => _themeKey = key);
  }

  Future<void> _selectTheme(String key) async {
    if (key == _themeKey) return;
    setState(() => _themeKey = key);
    await ref.read(appSettingsRepositoryProvider).setThemeKey(key);
    // 让 MaterialApp 重建取新主题。
    ref.invalidate(themePaletteProvider);
  }

  Future<void> _loadMemory() async {
    final enabled = await ref
        .read(appSettingsRepositoryProvider)
        .memoryEnabled();
    if (mounted) setState(() => _memoryEnabled = enabled);
  }

  Future<void> _setMemory(bool enabled) async {
    setState(() => _memoryEnabled = enabled);
    await ref.read(appSettingsRepositoryProvider).setMemoryEnabled(enabled);
  }

  Future<void> _openSite(BuildContext context) async {
    var ok = false;
    try {
      ok = await launchUrl(
        Uri.parse('https://$kSigbornSite'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      ok = false;
    }
    if (ok || !context.mounted) return;
    // 打不开（无浏览器等）：复制到剪贴板兜底。
    await Clipboard.setData(const ClipboardData(text: 'https://$kSigbornSite'));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('无法直接打开，网址已复制到剪贴板')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // 滚动列表里的卡片不做真模糊（性能铁律），用半透明 + 渐变描边的
    // 伪玻璃质感（v8）。
    final cardDeco = glassBubbleDecoration(
      base: scheme.surface,
      fillOpacity: 0.55,
      radius: BorderRadius.circular(16),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader('配置'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DecoratedBox(
              decoration: cardDeco,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.cloud_outlined),
                    title: const Text('API 供应商'),
                    subtitle: const Text('聊天模型的接口地址与密钥（BYOK）'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ApiProfilesPage(),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.record_voice_over_outlined),
                    title: const Text('语音'),
                    subtitle: const Text('TTS 引擎、发音人与按住说话识别'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const VoiceSettingsPage(),
                      ),
                    ),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.psychology_outlined),
                    title: const Text('跨会话记忆'),
                    subtitle: const Text('同一角色在不同会话间共享近期片段与摘要记忆'),
                    value: _memoryEnabled,
                    onChanged: (v) => unawaited(_setMemory(v)),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 32),
          _SectionHeader('外观'),
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: kThemePalettes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final p = kThemePalettes[index];
                return _ThemeCard(
                  palette: p,
                  selected: p.id == _themeKey,
                  onTap: () => unawaited(_selectTheme(p.id)),
                );
              },
            ),
          ),
          const Divider(height: 32),
          _SectionHeader('更多'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DecoratedBox(
              decoration: cardDeco,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.language, color: scheme.secondary),
                    title: const Text('奇点重现官网'),
                    subtitle: Text(
                      kSigbornSite,
                      style: TextStyle(color: scheme.secondary),
                    ),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => _openSite(context),
                  ),
                  // Live2D 示例模型署名（Haru 随包分发许可义务，v8）。
                  ListTile(
                    leading: Icon(
                      Icons.pets_outlined,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                    title: const Text('Powered by Live2D'),
                    subtitle: const Text(
                      '内置桌宠 Haru 为 Live2D 官方示例模型（Sample Model License）',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 32),
          Center(
            child: Opacity(
              opacity: 0.75,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/branding/sigborn_logo.png',
                    width: 22,
                    height: 22,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.bolt,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '心语 · 由奇点重现工作室制作',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(child: _VersionText()),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// 版本信息：心语 vX.Y.Z（build）。
class _VersionText extends StatelessWidget {
  const _VersionText();

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.55);
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        final text = info == null
            ? '心语'
            : '心语 v${info.version}（${info.buildNumber}）';
        return Text(text, style: TextStyle(fontSize: 11, color: muted));
      },
    );
  }
}

/// 主题预览卡片：用该调色板的底色/表面/强调色拼一个迷你聊天界面预览。
class _ThemeCard extends StatelessWidget {
  final ThemePalette palette;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 104,
            height: 80,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: p.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? p.accent : p.divider,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 迷你气泡：表面色卡片 + 强调色小点，示意该主题的层感。
                Container(
                  height: 14,
                  width: 64,
                  decoration: BoxDecoration(
                    color: p.surfaceHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    height: 14,
                    width: 44,
                    decoration: BoxDecoration(
                      color: p.accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: p.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      height: 4,
                      width: 28,
                      color: p.muted.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            p.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface
              .withValues(alpha: 0.55),
          fontSize: 12,
          letterSpacing: 2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
