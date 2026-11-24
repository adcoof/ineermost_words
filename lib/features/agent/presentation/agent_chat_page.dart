/// Agent 对话页：工具循环、工具结果卡片、写入确认、工作区面板。
library;

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../app/providers.dart';
import '../application/agent_controller.dart';
import '../application/agent_tools.dart';
import '../data/download_gateway.dart';
import '../data/saf_gateway.dart';
import '../domain/agent_approval.dart';
import '../domain/agent_models.dart';
import 'agent_context_chip.dart';

class AgentChatPage extends ConsumerWidget {
  const AgentChatPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(agentWorkspaceProvider);
    return workspace.when(
      data: (ws) => _AgentChatView(sessionId: sessionId, workspace: ws),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Agent')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Agent')),
        body: Center(child: Text('工作区打开失败：$error')),
      ),
    );
  }
}

class _AgentChatView extends ConsumerStatefulWidget {
  const _AgentChatView({required this.sessionId, required this.workspace});

  final String sessionId;
  final AgentWorkspace workspace;

  @override
  ConsumerState<_AgentChatView> createState() => _AgentChatViewState();
}

class _AgentChatViewState extends ConsumerState<_AgentChatView> {
  late final AgentController _controller;
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AgentController(
      repo: ref.read(agentSessionRepositoryProvider),
      api: ref.read(chatApiClientProvider),
      profiles: ref.read(apiProfileRepositoryProvider),
      settings: ref.read(appSettingsRepositoryProvider),
      workspace: widget.workspace,
      saf: ref.read(safGatewayProvider),
      device: ref.read(deviceGatewayProvider),
    )..attach(widget.sessionId);
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages =
        ref.watch(agentMessagesStreamProvider(widget.sessionId)).value ??
            const <AgentMessage>[];
    final sessions =
        ref.watch(agentSessionsStreamProvider).value ?? const <AgentSession>[];
    var title = 'Agent';
    for (final session in sessions) {
      if (session.id == widget.sessionId) title = session.title;
    }

    if (messages.length != _lastCount) {
      _lastCount = messages.length;
      _scrollToBottom();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          AgentContextChip(usage: _controller.contextUsage),
          IconButton(
            tooltip: '本会话权限',
            icon: const Icon(Icons.shield_outlined),
            onPressed: _openPermissions,
          ),
          IconButton(
            tooltip: '工作区',
            icon: const Icon(Icons.folder_outlined),
            onPressed: _openWorkspace,
          ),
          if (_controller.sending)
            IconButton(
              tooltip: '停止',
              icon: const Icon(Icons.stop_circle_outlined),
              onPressed: _controller.stop,
            ),
        ],
      ),
      body: Column(
        children: [
          if (_controller.errorText != null)
            _ErrorBar(
              message: _controller.errorText!,
              onClose: _controller.clearError,
            ),
          Expanded(
            child: messages.isEmpty
                ? _EmptyView(onPick: _fillInput)
                : ListView.builder(
                    controller: _scroll,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[messages.length - 1 - index];
                      if (message.isTool) {
                        return _ToolResultCard(message: message);
                      }
                      return _MessageBubble(message: message);
                    },
                  ),
          ),
          if (_controller.pendingAction != null)
            _ActionConfirmCard(
              pending: _controller.pendingAction!,
              onConfirm: _controller.confirmAction,
              onReject: _controller.rejectAction,
            ),
          _InputBar(
            controller: _input,
            sending: _controller.sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      // reverse: true 的列表，offset 0 即最新一条。
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _fillInput(String text) {
    _input.text = text;
    _input.selection = TextSelection.collapsed(offset: text.length);
    setState(() {});
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _controller.sending) return;
    _input.clear();
    setState(() {});
    await _controller.send(text);
  }

  Future<void> _openWorkspace() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _WorkspaceSheet(
        workspace: widget.workspace,
        downloads: ref.read(downloadGatewayProvider),
      ),
    );
  }

  Future<void> _openPermissions() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SessionPermissionSheet(
        controller: _controller,
        saf: ref.read(safGatewayProvider),
      ),
    );
  }
}

/// 会话级权限：审批模式 + 授权文件夹；不改设置页的全局默认。
class _SessionPermissionSheet extends StatefulWidget {
  const _SessionPermissionSheet({
    required this.controller,
    required this.saf,
  });

  final AgentController controller;
  final SafGateway saf;

  @override
  State<_SessionPermissionSheet> createState() =>
      _SessionPermissionSheetState();
}

class _SessionPermissionSheetState extends State<_SessionPermissionSheet> {
  bool get _followDefault =>
      widget.controller.sessionApprovalMode == null;

  Future<void> _setMode(AgentApprovalMode? mode) async {
    await widget.controller.setSessionApprovalMode(mode);
    if (mounted) setState(() {});
  }

  Future<void> _addFolder() async {
    final folder = await widget.saf.pickDirectory();
    if (folder == null) return;
    final current = widget.controller.effectiveGrantedFolders;
    if (current.any((f) => f.uri == folder.uri)) return;
    await widget.controller.setSessionGrantedFolders([...current, folder]);
    if (mounted) setState(() {});
  }

  Future<void> _removeFolder(AgentGrantedFolder folder) async {
    final next = widget.controller.effectiveGrantedFolders
        .where((f) => f.uri != folder.uri)
        .toList();
    await widget.controller.setSessionGrantedFolders(next);
    if (mounted) setState(() {});
  }

  Future<void> _reset() async {
    await widget.controller.setSessionApprovalMode(null);
    await widget.controller.setSessionGrantedFolders(null);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = widget.controller;
    final folders = controller.effectiveGrantedFolders;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Agent 权限', style: theme.textTheme.titleLarge),
                const Spacer(),
                if (!_followDefault ||
                    controller.sessionGrantedFolders != null)
                  TextButton(onPressed: _reset, child: const Text('恢复默认')),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '只影响当前会话。设置页的选项作为新会话的默认。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('跟随设置页默认'),
              subtitle: Text('当前默认：${controller.defaultApprovalMode.label}'),
              value: _followDefault,
              onChanged: (value) async {
                await _setMode(value ? null : controller.approvalMode);
              },
            ),
            RadioGroup<AgentApprovalMode>(
              groupValue: controller.approvalMode,
              onChanged: (value) {
                if (value != null) _setMode(value);
              },
              child: Column(
                children: [
                  for (final mode in AgentApprovalMode.values)
                    RadioListTile<AgentApprovalMode>(
                      contentPadding: EdgeInsets.zero,
                      value: mode,
                      title: Text(mode.label),
                      subtitle: Text(mode.description),
                    ),
                ],
              ),
            ),
            if (controller.sessionApprovalMode != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '本会话已覆盖默认审批模式',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            const Divider(height: 28),
            Row(
              children: [
                Text('授权文件夹', style: theme.textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addFolder,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加'),
                ),
              ],
            ),
            if (folders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '本会话暂无授权文件夹，只能访问工作区。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (final folder in folders)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(folder.name),
                  subtitle: Text(folder.uri, maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    tooltip: '移除',
                    icon: const Icon(Icons.close),
                    onPressed: () => _removeFolder(folder),
                  ),
                ),
            const SizedBox(height: 8),
            Text(
              '只影响 Agent 的访问列表，不会删除文件；系统授权可随时在系统设置中撤销。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                key: const Key('agent-input'),
                controller: controller,
                minLines: 1,
                maxLines: 4,
                enabled: !sending,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: '让 Agent 读写本地文件…',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              key: const Key('agent-send'),
              onPressed: sending ? null : onSend,
              icon: const Icon(Icons.arrow_upward),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AgentMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final scheme = Theme.of(context).colorScheme;
    final text = message.content.trim();
    final calls = message.toolCalls;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        decoration: BoxDecoration(
          color: isUser ? scheme.primaryContainer : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (text.isNotEmpty)
              if (isUser)
                SelectableText(
                  text,
                  style: TextStyle(color: scheme.onPrimaryContainer),
                )
              else
                MarkdownBody(
                  data: text,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet.fromTheme(
                    Theme.of(context),
                  ).copyWith(
                    p: const TextStyle(fontSize: 14, height: 1.45),
                    h1: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    h2: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    h3: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    code: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    codeblockPadding: const EdgeInsets.all(10),
                    blockSpacing: 8,
                    listIndent: 18,
                  ),
                ),
            if (message.status == 'streaming' && text.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            for (final call in calls)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: const Icon(Icons.build_outlined, size: 16),
                  label: Text('调用 ${call.name}'),
                ),
              ),
            if (message.status == 'error')
              Text(
                '（这条回复未完成）',
                style: TextStyle(fontSize: 12, color: scheme.error),
              ),
          ],
        ),
      ),
    );
  }
}

class _ToolResultCard extends StatelessWidget {
  const _ToolResultCard({required this.message});

  final AgentMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pretty = _pretty(message.content);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: scheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.terminal, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    message.toolName ?? 'tool',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: '查看完整结果',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.open_in_full, size: 16),
                  onPressed: () => _showFull(context, pretty),
                ),
              ],
            ),
            Text(
              pretty,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  static String _pretty(String raw) {
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(raw));
    } catch (_) {
      return raw;
    }
  }

  void _showFull(BuildContext context, String text) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message.toolName ?? '工具结果'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              text,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

class _ActionConfirmCard extends StatelessWidget {
  const _ActionConfirmCard({
    required this.pending,
    required this.onConfirm,
    required this.onReject,
  });

  final AgentPendingAction pending;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = switch (pending.risk) {
      AgentToolRisk.shell => Icons.terminal,
      AgentToolRisk.network => Icons.language,
      AgentToolRisk.destructive => Icons.delete_outline,
      AgentToolRisk.write => Icons.edit_note,
      AgentToolRisk.read => Icons.visibility_outlined,
    };
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 6),
                Text(
                  pending.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: scheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              pending.detail,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onReject, child: const Text('拒绝')),
                FilledButton(onPressed: onConfirm, child: const Text('允许执行')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBar extends StatelessWidget {
  const _ErrorBar({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 18, color: scheme.onErrorContainer),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer, fontSize: 12),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.close, size: 16, color: scheme.onErrorContainer),
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onPick});

  final void Function(String text) onPick;

  @override
  Widget build(BuildContext context) {
    const suggestions = [
      '列出工作区与授权文件夹里的文件',
      '把「明天的待办」保存到 todo.txt',
      '读取 note.txt 并总结',
      '搜索今天有哪些 AI 新闻',
    ];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.smart_toy_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            const Text('我可以读写文件、执行命令、联网搜索'),
            const SizedBox(height: 4),
            Text(
              '文件只限工作区与授权文件夹，高风险操作会先请你确认',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            for (final text in suggestions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: () => onPick(text),
                  child: Text(text),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WsItem {
  const _WsItem({required this.name, required this.path, required this.isDir});

  final String name;
  final String path;
  final bool isDir;
}

class _WorkspaceSheet extends StatefulWidget {
  const _WorkspaceSheet({required this.workspace, required this.downloads});

  final AgentWorkspace workspace;
  final DownloadGateway downloads;

  @override
  State<_WorkspaceSheet> createState() => _WorkspaceSheetState();
}

class _WorkspaceSheetState extends State<_WorkspaceSheet> {
  var _items = const <_WsItem>[];
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await widget.workspace.listFiles('.');
      final decoded = jsonDecode(raw);
      final list = decoded is Map ? decoded['items'] : null;
      final items = <_WsItem>[];
      if (list is List) {
        for (final item in list) {
          if (item is! Map) continue;
          items.add(
            _WsItem(
              name: item['name']?.toString() ?? '',
              path: item['path']?.toString() ?? '',
              isDir: item['type']?.toString() == 'dir',
            ),
          );
        }
      }
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_outlined),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Agent 工作区',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
                IconButton(
                  tooltip: '关闭',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SelectableText(
              widget.workspace.rootPath,
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Text('读取失败：$_error', style: TextStyle(color: scheme.error))
            else if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('工作区还是空的'),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        item.isDir ? Icons.folder : Icons.description_outlined,
                      ),
                      title: Text(item.name),
                      subtitle: Text(item.path),
                      trailing: item.isDir
                          ? null
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: '保存到下载',
                                  icon: const Icon(Icons.download_outlined),
                                  onPressed: () => _saveToDownloads(item),
                                ),
                                IconButton(
                                  tooltip: '复制内容',
                                  icon: const Icon(Icons.copy_all_outlined),
                                  onPressed: () => _copy(item),
                                ),
                              ],
                            ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _import,
                  icon: const Icon(Icons.file_upload_outlined, size: 18),
                  label: const Text('导入文本'),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _clear,
                  style: TextButton.styleFrom(foregroundColor: scheme.error),
                  icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                  label: const Text('清空'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy(_WsItem item) async {
    try {
      final file = File(p.join(widget.workspace.rootPath, item.path));
      final text = await file.readAsString();
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已复制到剪贴板')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('复制失败：$e')),
      );
    }
  }

  Future<void> _saveToDownloads(_WsItem item) async {
    try {
      final file = File(p.join(widget.workspace.rootPath, item.path));
      final text = await file.readAsString();
      final result = await widget.downloads.saveText(
        name: item.name,
        content: text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已保存到 ${result.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存到下载失败：$e')),
      );
    }
  }

  Future<void> _import() async {
    try {
      final files = await FilePicker.pickFiles();
      if (files.isEmpty) return;
      var count = 0;
      for (final file in files) {
        final path = file.path;
        if (path == null) continue;
        final text = await File(path).readAsString();
        await widget.workspace.writeFile('导入/${file.name}', text);
        count++;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已导入 $count 个文件')),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败（仅支持 UTF-8 文本）：$e')),
      );
    }
  }

  Future<void> _clear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空工作区？'),
        content: const Text('里面的文件会全部删除，不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.workspace.clear();
    await _reload();
  }
}
