/// API 供应商配置管理：列表、编辑、测试连接。
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/api_profile.dart';

class ApiProfilesPage extends ConsumerWidget {
  const ApiProfilesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(apiProfileRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('API 供应商'),
      ),
      body: StreamBuilder<List<ApiProfile>>(
        stream: repo.watchAll(),
        builder: (context, snapshot) {
          final profiles = snapshot.data ?? const [];
          if (profiles.isEmpty) {
            return const Center(
              child: Text('还没有供应商配置，点右下角添加'),
            );
          }
          return ListView.separated(
            itemCount: profiles.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final p = profiles[index];
              return ListTile(
                leading: Icon(
                  p.isDefault ? Icons.star : Icons.cloud_outlined,
                  color: p.isDefault
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(p.name),
                subtitle: Text('${p.model} · ${p.baseUrl}'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => ApiProfileEditPage(profile: p)),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final blank = ref.read(apiProfileRepositoryProvider).blank();
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => ApiProfileEditPage(profile: blank, isNew: true)),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ApiProfileEditPage extends ConsumerStatefulWidget {
  final ApiProfile profile;
  final bool isNew;

  const ApiProfileEditPage({super.key, required this.profile, this.isNew = false});

  @override
  ConsumerState<ApiProfileEditPage> createState() => _ApiProfileEditPageState();
}

class _ApiProfileEditPageState extends ConsumerState<ApiProfileEditPage> {
  late final TextEditingController _name;
  late final TextEditingController _baseUrl;
  late final TextEditingController _apiKey;
  late final TextEditingController _model;
  late final TextEditingController _temperature;
  late final TextEditingController _maxTokens;
  late final TextEditingController _extraHeaders;
  late bool _isDefault;
  bool _obscureKey = true;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _name = TextEditingController(text: p.name);
    _baseUrl = TextEditingController(text: p.baseUrl);
    _apiKey = TextEditingController(text: p.apiKey);
    _model = TextEditingController(text: p.model);
    _temperature = TextEditingController(text: p.temperature.toString());
    _maxTokens = TextEditingController(text: p.maxTokens?.toString() ?? '');
    _extraHeaders = TextEditingController(text: p.extraHeaders);
    _isDefault = p.isDefault;
  }

  @override
  void dispose() {
    _name.dispose();
    _baseUrl.dispose();
    _apiKey.dispose();
    _model.dispose();
    _temperature.dispose();
    _maxTokens.dispose();
    _extraHeaders.dispose();
    super.dispose();
  }

  ApiProfile _collect() => widget.profile.copyWith(
        name: _name.text.trim().isEmpty ? '未命名' : _name.text.trim(),
        baseUrl: _baseUrl.text.trim(),
        apiKey: _apiKey.text.trim(),
        model: _model.text.trim(),
        temperature: double.tryParse(_temperature.text.trim()) ?? 1.0,
        maxTokens: int.tryParse(_maxTokens.text.trim()),
        extraHeaders:
            _extraHeaders.text.trim().isEmpty ? '{}' : _extraHeaders.text.trim(),
        isDefault: _isDefault,
      );

  Future<void> _save() async {
    final repo = ref.read(apiProfileRepositoryProvider);
    final profile = _collect();
    if (_isDefault) {
      // 唯一默认：清掉其它默认标记。
      for (final other in await repo.getAll()) {
        if (other.id != profile.id && other.isDefault) {
          await repo.save(other.copyWith(isDefault: false));
        }
      }
    }
    await repo.save(profile);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _test() async {
    setState(() => _testing = true);
    final api = ref.read(chatApiClientProvider);
    final cancel = CancelToken();
    try {
      await api.testConnection(profile: _collect(), cancelToken: cancel);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('连接成功')),
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('连接失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _delete() async {
    if (widget.isNew) {
      Navigator.of(context).pop();
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除供应商配置'),
        content: Text('确定删除「${widget.profile.name}」？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('删除')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(apiProfileRepositoryProvider).delete(widget.profile.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? '添加供应商' : '编辑供应商'),
        actions: [
          if (!widget.isNew)
            IconButton(
              tooltip: '删除',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: '名称'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _baseUrl,
            decoration: const InputDecoration(
              labelText: 'Base URL',
              hintText: 'https://api.deepseek.com/v1',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKey,
            obscureText: _obscureKey,
            decoration: InputDecoration(
              labelText: 'API Key',
              suffixIcon: IconButton(
                icon: Icon(
                    _obscureKey ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _model,
            decoration: const InputDecoration(
              labelText: '模型名',
              hintText: 'deepseek-chat',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _temperature,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'temperature'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxTokens,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'max tokens（可空）'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _extraHeaders,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: '额外请求头（JSON，可空）',
              hintText: '{"X-Custom": "value"}',
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('设为默认供应商'),
            value: _isDefault,
            onChanged: (v) => setState(() => _isDefault = v),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _testing ? null : _test,
            icon: _testing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.wifi_tethering),
            label: const Text('测试连接'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}