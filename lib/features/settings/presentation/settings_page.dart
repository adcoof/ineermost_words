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
  String _themeKey = 'deep-space';
  bool _memoryEnabled = true;
  bool _autoRetryEnabled = true;
  int _contextWindowTokens = kContextWindowDefault;
  int _contextOtherTokens = kContextWindowOtherDefault;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _loadMemory();
    _loadAutoRetry();
    _loadContextWindow();
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

  Future<void> _loadAutoRetry() async {
    final enabled = await ref
        .read(appSettingsRepositoryProvider)
        .autoRetryEnabled();
    if (mounted) setState(() => _autoRetryEnabled = enabled);
  }

  Future<void> _setAutoRetry(bool enabled) async {
    setState(() => _autoRetryEnabled = enabled);
    await ref.read(appSettingsRepositoryProvider).setAutoRetryEnabled(enabled);
  }

  Future<void> _loadContextWindow() async {
    final repo = ref.read(appSettingsRepositoryProvider);
    final window = await repo.contextWindowTokens();
    final other = await repo.contextWindowOtherTokens();
    if (mounted) {
      setState(() {
        _contextWindowTokens = window;
        _contextOtherTokens = other;
      });
    }
  }

  Future<void> _openContextWindowSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _ContextWindowSheet(
        repo: ref.read(appSettingsRepositoryProvider),
        windowTokens: _contextWindowTokens,
        otherTokens: _contextOtherTokens,
      ),
    );
    await _loadContextWindow();
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
                  SwitchListTile(
                    secondary: const Icon(Icons.refresh_outlined),
                    title: const Text('空回复自动重试'),
                    subtitle: const Text('模型没有返回正文时自动重试一次，避免偶发空白气泡'),
                    value: _autoRetryEnabled,
                    onChanged: (v) => unawaited(_setAutoRetry(v)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.tune_outlined),
                    title: const Text('上下文窗口'),
                    subtitle: Text(
                      '约 ${_fmtTokens(_contextWindowTokens)} token'
                      '（≈ ${(_contextWindowTokens / 1.2 / 1000).toStringAsFixed(1)} 千字）',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => unawaited(_openContextWindowSheet()),
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

String _fmtTokens(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// 上下文窗口 + 跨会话原文预算的底部弹层；改动即时落库。
class _ContextWindowSheet extends StatefulWidget {
  final AppSettingsRepository repo;
  final int windowTokens;
  final int otherTokens;

  const _ContextWindowSheet({
    required this.repo,
    required this.windowTokens,
    required this.otherTokens,
  });

  @override
  State<_ContextWindowSheet> createState() => _ContextWindowSheetState();
}

class _ContextWindowSheetState extends State<_ContextWindowSheet> {
  late int _window = widget.windowTokens;
  late int _other = widget.otherTokens;

  void _setWindow(int value, {bool persist = true}) {
    setState(() => _window = value);
    if (persist) unawaited(widget.repo.setContextWindowTokens(value));
  }

  void _setOther(int value, {bool persist = true}) {
    setState(() => _other = value);
    if (persist) unawaited(widget.repo.setContextWindowOtherTokens(value));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('上下文窗口', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                '模型每次能看到的对话长度上限。超出后从最早的消息开始省略，'
                '当前输入永远保留。',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Text('窗口大小', style: TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(
                    '${_fmtTokens(_window)} token',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _window.toDouble(),
                min: kContextWindowMin.toDouble(),
                max: kContextWindowMax.toDouble(),
                divisions: (kContextWindowMax - kContextWindowMin) ~/
                    kContextWindowStep,
                label: '${_fmtTokens(_window)} token',
                onChanged: (v) => _setWindow(
                  (v / kContextWindowStep).round() * kContextWindowStep,
                  persist: false,
                ),
                onChangeEnd: (v) => _setWindow(
                  (v / kContextWindowStep).round() * kContextWindowStep,
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final preset in const [2048, 4096, 8192, 16384])
                    ChoiceChip(
                      label: Text('${preset ~/ 1024}K'),
                      selected: _window == preset,
                      onSelected: (_) => _setWindow(preset),
                    ),
                  ActionChip(
                    label: const Text('恢复默认'),
                    onPressed: () => _setWindow(kContextWindowDefault),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('跨会话引用', style: TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(
                    _other == 0 ? '只保留摘要' : '${_fmtTokens(_other)} token',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '同一角色的其他会话，最多带多少近期原文；0 表示不注入原文，只保留摘要。',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              Slider(
                value: _other.toDouble(),
                min: 0,
                max: kContextWindowOtherMax.toDouble(),
                divisions: kContextWindowOtherMax ~/ kContextWindowStep,
                label: '${_fmtTokens(_other)} token',
                onChanged: (v) => _setOther(
                  (v / kContextWindowStep).round() * kContextWindowStep,
                  persist: false,
                ),
                onChangeEnd: (v) => _setOther(
                  (v / kContextWindowStep).round() * kContextWindowStep,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '按估算 token 计算，实际可用预算为窗口的 90%。修改立即生效。',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
