/// 聊天页顶栏的上下文用量入口：百分比 chip + 明细弹层。
library;

import 'package:flutter/material.dart';

import '../../characters/application/prompt_assembler.dart';

/// 顶栏右侧的小 chip。未发送过消息时显示 `--`，点击查看上次发送的
/// 分类用量（系统人设 / 记忆 / 跨会话 / 本会话历史 / 当前输入）。
class ContextUsageChip extends StatelessWidget {
  final PromptUsage? usage;

  const ContextUsageChip({super.key, this.usage});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = (usage?.ratio ?? 0).clamp(0.0, 1.0);
    final color = usage == null
        ? scheme.onSurfaceVariant
        : ratio >= 0.9
        ? const Color(0xFFE5484D)
        : ratio >= 0.7
        ? const Color(0xFFD99A1E)
        : scheme.primary;
    final label = usage == null
        ? '上下文 --'
        : '上下文 ${(ratio * 100).round()}%';
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: usage == null
            ? null
            : () => showContextUsageSheet(context, usage!),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: color.withValues(alpha: 0.08),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              height: 1.1,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

/// 打开用量明细底部弹层。
Future<void> showContextUsageSheet(
  BuildContext context,
  PromptUsage usage,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _ContextUsageSheet(usage: usage),
  );
}

class _ContextUsageSheet extends StatelessWidget {
  final PromptUsage usage;

  const _ContextUsageSheet({required this.usage});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = usage.ratio.clamp(0.0, 1.0);
    final color = ratio >= 0.9
        ? const Color(0xFFE5484D)
        : ratio >= 0.7
        ? const Color(0xFFD99A1E)
        : scheme.primary;
    final rows = <({String label, IconData icon, int tokens})>[
      (
        label: '系统人设 / 时间 / 示例',
        icon: Icons.badge_outlined,
        tokens: usage.systemTokens,
      ),
      if (usage.profileTokens > 0)
        (
          label: '角色档案',
          icon: Icons.person_pin_outlined,
          tokens: usage.profileTokens,
        ),
      if (usage.cardPromptTokens > 0)
        (
          label: '卡内提示',
          icon: Icons.sticky_note_2_outlined,
          tokens: usage.cardPromptTokens,
        ),
      (label: '记忆（近期+画像）', icon: Icons.psychology_outlined, tokens: usage.memoryTokens),
      if (usage.factTokens > 0)
        (label: '长期记忆（事实）', icon: Icons.timeline_outlined, tokens: usage.factTokens),
      if (usage.loreTokens > 0)
        (label: '世界书', icon: Icons.menu_book_outlined, tokens: usage.loreTokens),
      (
        label: '跨会话片段',
        icon: Icons.forum_outlined,
        tokens: usage.otherSessionTokens,
      ),
      (
        label: '本会话历史',
        icon: Icons.chat_bubble_outline,
        tokens: usage.historyTokens,
      ),
      (label: '当前输入', icon: Icons.edit_outlined, tokens: usage.currentInputTokens),
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '上下文用量',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Text(
                    '${(ratio * 100).round()}%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '剩余 ${_fmtInt(usage.remainingTokens)} / 总量 ${_fmtInt(usage.windowTokens)} token',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.12),
                ),
              ),
              const SizedBox(height: 18),
              for (final row in rows) ...[
                Row(
                  children: [
                    Icon(row.icon, size: 17, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(child: Text(row.label)),
                    Text(
                      '${_fmtInt(row.tokens)} token',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 4),
              Text(
                '按估算 token 计算；实际可用预算为窗口的 90%，剩余空间留给回复。',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _fmtInt(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
