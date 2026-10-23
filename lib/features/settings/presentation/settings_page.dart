/// 设置主页：API / 语音 入口分列，外观主题色与版本信息，更多区展示工作室官网。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../data/app_settings_repository.dart';
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
  String _accentKey = kThemeAccents.first.key;
  bool _accentLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAccent();
  }

  Future<void> _loadAccent() async {
    final key =
        await AppSettingsRepository(ref.read(appDatabaseProvider)).themeAccent();
    if (mounted) {
      setState(() {
        _accentKey = key;
        _accentLoaded = true;
      });
    }
  }

  Future<void> _selectAccent(String key) async {
    if (key == _accentKey) return;
    setState(() => _accentKey = key);
    await AppSettingsRepository(ref.read(appDatabaseProvider))
        .setThemeAccent(key);
    // 让 MaterialApp 重建取新强调色。
    ref.invalidate(themeAccentProvider);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法直接打开，网址已复制到剪贴板')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader('配置'),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('API 供应商'),
            subtitle: const Text('聊天模型的接口地址与密钥（BYOK）'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ApiProfilesPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.record_voice_over_outlined),
            title: const Text('语音'),
            subtitle: const Text('TTS 引擎、发音人与按住说话识别'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const VoiceSettingsPage()),
            ),
          ),
          const Divider(height: 32),
          _SectionHeader('外观'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                for (final a in kThemeAccents)
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: _AccentDot(
                      accent: a,
                      selected: _accentLoaded && a.key == _accentKey,
                      onTap: () => unawaited(_selectAccent(a.key)),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 32),
          _SectionHeader('更多'),
          ListTile(
            leading: const Icon(Icons.language, color: BrandColors.cyan),
            title: const Text('奇点重现官网'),
            subtitle: const Text(
              kSigbornSite,
              style: TextStyle(color: BrandColors.cyan),
            ),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openSite(context),
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
                    errorBuilder: (_, _, _) => const Icon(Icons.bolt,
                        size: 16, color: BrandColors.muted),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '心语 · 由奇点重现工作室制作',
                    style: TextStyle(fontSize: 12, color: BrandColors.muted),
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
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        final text = info == null
            ? '心语'
            : '心语 v${info.version}（${info.buildNumber}）';
        return Text(
          text,
          style: const TextStyle(fontSize: 11, color: BrandColors.muted),
        );
      },
    );
  }
}

/// 强调色圆点选择器。
class _AccentDot extends StatelessWidget {
  final ThemeAccent accent;
  final bool selected;
  final VoidCallback onTap;

  const _AccentDot({
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(accent.argb);
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.6),
                          blurRadius: 12,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 20, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              accent.label,
              style: TextStyle(
                fontSize: 11,
                color: selected ? color : BrandColors.muted,
              ),
            ),
          ],
        ),
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
        style: const TextStyle(
          color: BrandColors.muted,
          fontSize: 12,
          letterSpacing: 2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
