/// Agent 会话的上下文用量 chip 与明细弹层。
library;

import 'package:flutter/material.dart';

import '../domain/agent_usage.dart';

class AgentContextChip extends StatelessWidget {
  const AgentContextChip({super.key, required this.usage});

  final AgentUsage? usage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = usage?.ratio.clamp(0.0, 1.0) ?? 0.0;
    final color = usage == null
        ? theme.colorScheme.onSurfaceVariant
        : ratio >= 0.9
            ? const Color(0xFFE5484D)
            : ratio >= 0.7
                ? const Color(0xFFD99A1E)
                : theme.colorScheme.primary;
    final label = usage == null
        ? '上下文 --'
        : '上下文 ${(ratio * 100).round()}%';
    return TextButton(
      onPressed: usage == null
          ? null
          : () => showAgentContextSheet(context, usage!),
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        visualDensity: VisualDensity.compact,
      ),
      child: Text(label, style: theme.textTheme.labelMedium),
    );
  }
}

Future<void> showAgentContextSheet(
  BuildContext context,
  AgentUsage usage,
) {
  final theme = Theme.of(context);
  final ratio = usage.ratio.clamp(0.0, 1.0);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('上下文用量', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '估算 token；实际可用预算为窗口的 90%。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '已用 ${(ratio * 100).round()}%',
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${_fmtInt(usage.usedTokens)} / ${_fmtInt(usage.budgetTokens)} token',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 16),
            _UsageRow(label: '系统提示词', value: usage.systemTokens),
            _UsageRow(label: '工具定义', value: usage.toolsTokens),
            _UsageRow(label: '对话消息', value: usage.historyTokens),
            const Divider(height: 24),
            _UsageRow(
              label: '窗口总量',
              value: usage.windowTokens,
              muted: true,
            ),
            _UsageRow(
              label: '剩余预算',
              value: usage.remainingTokens,
              muted: true,
            ),
          ],
        ),
      ),
    ),
  );
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({
    required this.label,
    required this.value,
    this.muted = false,
  });

  final String label;
  final int value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: muted ? theme.colorScheme.onSurfaceVariant : null,
            ),
          ),
          const Spacer(),
          Text(
            '${_fmtInt(value)} token',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: muted ? theme.colorScheme.onSurfaceVariant : null,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtInt(int value) {
  final text = value.toString();
  final out = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) out.write(',');
    out.write(text[i]);
  }
  return out.toString();
}
