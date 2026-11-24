/// Agent 会话列表页：独立于角色聊天的本地文件助手会话。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../domain/agent_models.dart';
import 'agent_chat_page.dart';

class AgentSessionsPage extends ConsumerWidget {
  const AgentSessionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions =
        ref.watch(agentSessionsStreamProvider).value ?? const <AgentSession>[];
    final fmt = DateFormat('MM-dd HH:mm');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent'),
        actions: [
          IconButton(
            tooltip: '说明',
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showIntro(context),
          ),
        ],
      ),
      body: sessions.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.smart_toy_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    const Text('我可以读写文件、执行命令、联网搜索'),
                    const SizedBox(height: 6),
                    Text(
                      '工作区与授权文件夹可在会话内单独调整',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              itemCount: sessions.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final session = sessions[index];
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.smart_toy_outlined),
                  ),
                  title: Text(
                    session.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(fmt.format(session.updatedAt)),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'rename') {
                        await _rename(context, ref, session);
                      } else if (value == 'delete') {
                        await _delete(context, ref, session);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'rename', child: Text('重命名')),
                      PopupMenuItem(value: 'delete', child: Text('删除')),
                    ],
                  ),
                  onTap: () => _open(context, session.id),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-agent',
        onPressed: () async {
          final session =
              await ref.read(agentSessionRepositoryProvider).createSession();
          if (!context.mounted) return;
          _open(context, session.id);
        },
        icon: const Icon(Icons.add),
        label: const Text('新对话'),
      ),
    );
  }

  void _open(BuildContext context, String sessionId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AgentChatPage(sessionId: sessionId)),
    );
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    AgentSession session,
  ) async {
    final controller = TextEditingController(text: session.title);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '会话标题'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.trim().isEmpty) return;
    await ref
        .read(agentSessionRepositoryProvider)
        .renameSession(session.id, value);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    AgentSession session,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这个 Agent 会话？'),
        content: const Text('会话消息会一并删除，工作区文件不受影响。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(agentSessionRepositoryProvider).deleteSession(session.id);
  }

  void _showIntro(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agent 能做什么'),
        content: const Text(
          'Agent 可以读写工作区与授权文件夹、执行 shell 命令、发起 HTTP 请求，'
          '也可以联网搜索公开资料。\n\n'
          '• 文件访问限制在工作区与你授权的文件夹内\n'
          '• 高风险操作是否确认，由会话内的审批模式决定\n'
          '• shell 禁止 su，HTTP 禁止本机与内网地址',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}
