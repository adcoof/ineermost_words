/// 语音设置：语音回复开关/语速、TTS 引擎与发音人（MiMo 默认）、
/// ASR 引擎与语言、试听。
///
/// API 配置跟着引擎选项走：TTS 的 OpenAI 档挂 URL/Key/模型名表单
///（存 tts_profiles 行，空则回落聊天配置）；ASR 的「独立配置」档挂
/// 同样表单（存 settings KV）。MiMo 档永远复用聊天配置。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/edge_tts_provider.dart';
import '../data/mimo_tts_provider.dart';
import '../data/openai_tts_provider.dart';
import '../data/system_tts_provider.dart';
import '../domain/tts_provider.dart';
import 'voice_design_page.dart';

class VoiceSettingsPage extends ConsumerStatefulWidget {
  const VoiceSettingsPage({super.key});

  @override
  ConsumerState<VoiceSettingsPage> createState() => _VoiceSettingsPageState();
}

class _VoiceSettingsPageState extends ConsumerState<VoiceSettingsPage> {
  bool _enabled = false;
  double _speed = 1.0;
  String _provider = 'edge';
  String _voiceId = 'zh-CN-XiaoxiaoNeural';
  String _model = 'tts-1';

  /// ASR 引擎：'mimo'（复用聊天配置）| 'custom'（独立配置）| 'system'（本机）。
  String _asrEngine = 'mimo';
  String _asrLocale = 'zh_CN';

  bool _loaded = false;
  List<TtsVoice> _voices = const [];
  late final TextEditingController _modelController;

  /// TTS OpenAI 档的独立 API（存 tts_profiles 行；Key 落库前不回填明文到 UI）。
  late final TextEditingController _openaiUrlController;
  late final TextEditingController _openaiKeyController;

  /// ASR 独立配置档的表单（存 settings KV）。
  late final TextEditingController _asrUrlController;
  late final TextEditingController _asrKeyController;
  late final TextEditingController _asrModelController;

  @override
  void initState() {
    super.initState();
    _modelController = TextEditingController(text: _model);
    _openaiUrlController = TextEditingController();
    _openaiKeyController = TextEditingController();
    _asrUrlController = TextEditingController();
    _asrKeyController = TextEditingController();
    _asrModelController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _modelController.dispose();
    _openaiUrlController.dispose();
    _openaiKeyController.dispose();
    _asrUrlController.dispose();
    _asrKeyController.dispose();
    _asrModelController.dispose();
    super.dispose();
  }

  /// 各引擎发音人清单；MiMo 档尾部并入自定义音色（音色工坊创建）。
  Future<List<TtsVoice>> _voicesFor(String provider) async {
    final base = switch (provider) {
      'mimo' => MimoTtsProvider.staticVoices,
      'openai' => OpenAiTtsProvider.staticVoices,
      // 系统分支取设备系统音色，不能用解析器列表（那会显示默认引擎的发音人）。
      'system' => await SystemTtsProvider().listVoices(),
      _ => EdgeTtsProvider.staticVoices,
    };
    if (provider != 'mimo') return base;
    final customs = await ref.read(customVoiceRepositoryProvider).listAll();
    return [
      ...base,
      for (final v in customs)
        TtsVoice('custom:${v.id}', '${v.name}（自定义）'),
    ];
  }

  Future<void> _load() async {
    final repo = ref.read(ttsProfileRepositoryProvider);
    // 一次性把默认 TTS 迁移为 MiMo（Key/地址为空时回落默认聊天配置）。
    await repo.ensureMimoDefault(() async =>
        (await ref.read(apiProfileRepositoryProvider).getDefault()) != null);
    // 缺省档与运行时 ResolvingTtsProvider._primary() 一致：
    // 无已存 profile 时按有无聊天配置决定 MiMo/Edge，避免设置页与运行时所指不一。
    final profile = await repo.getDefault() ??
        ((await ref.read(apiProfileRepositoryProvider).getDefault()) != null
            ? repo.builtinMimo()
            : repo.builtinEdge());
    final voices = await _voicesFor(profile.provider);
    final enabled = await repo.voiceEnabled();
    final speed = await repo.voiceSpeed();
    final asrEngine = await repo.asrEngine();
    final asrLocale = await repo.asrLocale();
    final asrCustom = await repo.asrCustomConfig();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _speed = speed;
      _asrEngine = asrEngine;
      _asrLocale = asrLocale;
      _provider = profile.provider;
      _voiceId = profile.voiceId.isEmpty
          ? (voices.isNotEmpty ? voices.first.id : '')
          : profile.voiceId;
      // 模型缺省值按引擎取：MiMo 用 mimo-v2.5-tts，其余用 tts-1。
      _model = profile.model.isEmpty
          ? (profile.provider == 'mimo' ? MimoTtsProvider.defaultModel : 'tts-1')
          : profile.model;
      _modelController.text = _model;
      _openaiUrlController.text = profile.baseUrl;
      _openaiKeyController.text = profile.apiKey;
      _asrUrlController.text = asrCustom.baseUrl;
      _asrKeyController.text = asrCustom.apiKey;
      _asrModelController.text = asrCustom.model;
      _voices = voices;
      _loaded = true;
    });
  }

  /// 从音色工坊返回时只刷新发音人清单，保留本页未保存的其他编辑。
  Future<void> _refreshVoices() async {
    final voices = await _voicesFor(_provider);
    if (!mounted) return;
    setState(() => _voices = voices);
  }

  Future<void> _providerChanged(String? v) async {
    final provider = v ?? 'edge';
    final voices = await _voicesFor(provider);
    setState(() {
      _provider = provider;
      _voices = voices;
      _voiceId = voices.isNotEmpty ? voices.first.id : '';
      // 模型框里残留的其他引擎默认值换成当前引擎默认；自定义模型名保留。
      final text = _modelController.text.trim();
      final fallback =
          provider == 'mimo' ? MimoTtsProvider.defaultModel : 'tts-1';
      if (text.isEmpty ||
          text == 'tts-1' ||
          text == MimoTtsProvider.defaultModel) {
        _model = fallback;
        _modelController.text = fallback;
      }
    });
  }

  Future<void> _save() async {
    final repo = ref.read(ttsProfileRepositoryProvider);
    final existing = await repo.getDefault();
    final profile = (existing ??
            (_provider == 'mimo' ? repo.builtinMimo() : repo.builtinEdge()))
        .copyWith(
      provider: _provider,
      voiceId: _voiceId,
      speed: _speed,
      model: _modelController.text.trim(),
      // 独立 API 只在 OpenAI 档生效（存 profile 行）；其余引擎清空，
      // 保持「MiMo 永远复用聊天配置」的语义。
      baseUrl: _provider == 'openai' ? _openaiUrlController.text.trim() : '',
      apiKey: _provider == 'openai' ? _openaiKeyController.text.trim() : '',
      isDefault: true,
      name: switch (_provider) {
        'mimo' => 'MiMo 语音',
        'openai' => 'OpenAI 兼容 TTS',
        'system' => '系统语音',
        _ => 'Edge 免费语音',
      },
    );
    // 一律落库（含 builtin-edge 首次配置），否则用户选的引擎/发音人
    // 重启后丢失，会静默回落到 Edge 默认 —— 「没声音」的元凶之一。
    await repo.save(profile);
    await repo.setVoiceEnabled(_enabled);
    await repo.setVoiceSpeed(_speed);
    await repo.setAsrEngine(_asrEngine);
    await repo.setAsrLocale(_asrLocale);
    await repo.setAsrCustomConfig(
      baseUrl: _asrUrlController.text,
      apiKey: _asrKeyController.text,
      model: _asrModelController.text,
    );
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('语音设置已保存')));
    }
  }

  Future<void> _preview() async {
    await _save();
    final queue = ref.read(voiceOrchestratorProvider).queue;
    queue.clear();
    queue.enqueue('你好，我是你的桌宠搭档，试听效果如何？',
        speed: _speed, voiceId: _voiceId);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('语音')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('语音回复'),
            subtitle: const Text('AI 的回复逐句朗读，桌宠同步口型'),
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
          ),
          ListTile(
            title: Text('语速 ${_speed.toStringAsFixed(1)}x'),
            subtitle: Slider(
              value: _speed,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              onChanged: (v) => setState(() => _speed = v),
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('TTS 引擎', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'mimo', label: Text('MiMo')),
                ButtonSegment(value: 'edge', label: Text('Edge')),
                ButtonSegment(value: 'openai', label: Text('OpenAI')),
                ButtonSegment(value: 'system', label: Text('系统')),
              ],
              selected: {_provider},
              onSelectionChanged: (s) => unawaited(_providerChanged(s.first)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              switch (_provider) {
                'mimo' =>
                  '小米 MiMo 云端语音（chat/completions + audio），Key/地址复用聊天配置，推荐',
                'openai' => '走中转站或官方 /audio/speech 接口，可配独立 API（留空回落聊天配置）',
                'system' => '离线兜底，依赖设备自带 TTS 引擎',
                _ => '微软神经语音，免费，需联网',
              },
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (_provider == 'mimo')
            ListTile(
              title: TextField(
                decoration: const InputDecoration(
                  labelText: 'MiMo 模型（默认 mimo-v2.5-tts，API Key 走默认供应商配置）',
                  border: OutlineInputBorder(),
                ),
                controller: _modelController,
                maxLines: 1,
              ),
            ),
          if (_provider == 'openai') ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _openaiUrlController,
                decoration: const InputDecoration(
                  labelText: 'API 地址（如 https://api.openai.com/v1）',
                  helperText: '留空则复用「API 供应商」里的默认配置',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
                maxLines: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _openaiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                maxLines: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: '模型名（留空用 tts-1）',
                  border: OutlineInputBorder(),
                ),
                maxLines: 1,
              ),
            ),
          ],
          if (_voices.isNotEmpty)
            ListTile(
              title: const Text('发音人'),
              trailing: DropdownButton<String>(
                value: _voices.any((v) => v.id == _voiceId) ? _voiceId : null,
                hint: Text(_voiceId.isEmpty ? '默认' : _voiceId),
                items: [
                  for (final v in _voices)
                    DropdownMenuItem(value: v.id, child: Text(v.name)),
                ],
                onChanged: (v) =>
                    setState(() => _voiceId = v ?? _voiceId),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.record_voice_over_outlined),
            title: const Text('音色工坊（自定义音色）'),
            subtitle: const Text('用一句话描述定制音色，由 MiMo voicedesign 合成'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VoiceDesignPage()),
              );
              // 返回后刷新发音人清单（可能新增/删除了自定义音色）。
              await _refreshVoices();
            },
          ),
          const Divider(),
          const ListTile(
            title: Text('按住说话 · 识别引擎',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'mimo', label: Text('MiMo 云端')),
                ButtonSegment(value: 'custom', label: Text('独立配置')),
                ButtonSegment(value: 'system', label: Text('系统本机')),
              ],
              selected: {_asrEngine},
              onSelectionChanged: (s) => setState(() => _asrEngine = s.first),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              switch (_asrEngine) {
                'custom' => '识别走下方独立的接口配置，失败自动回退本机',
                'system' => '系统识别依赖设备自带服务',
                _ => '云端识别复用「API 供应商」里的默认配置，失败自动回退本机',
              },
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (_asrEngine == 'custom') ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _asrUrlController,
                decoration: const InputDecoration(
                  labelText: 'API 地址（如 https://api.example.com/v1）',
                  helperText: '需兼容 MiMo ASR 协议（chat/completions + input_audio）',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
                maxLines: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _asrKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                maxLines: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _asrModelController,
                decoration: const InputDecoration(
                  labelText: '模型名（留空用 mimo-v2.5-asr）',
                  border: OutlineInputBorder(),
                ),
                maxLines: 1,
              ),
            ),
          ],
          ListTile(
            title: const Text('识别语言（按住说话）'),
            trailing: DropdownButton<String>(
              value: _asrLocale,
              items: const [
                DropdownMenuItem(value: 'zh_CN', child: Text('中文')),
                DropdownMenuItem(value: 'en_US', child: Text('English')),
              ],
              onChanged: (v) => setState(() => _asrLocale = v ?? 'zh_CN'),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.record_voice_over),
            label: const Text('保存并试听'),
            onPressed: _preview,
          ),
        ],
      ),
    );
  }
}
