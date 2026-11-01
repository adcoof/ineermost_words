/// 提示词时间锚点：让角色感知消息时间与当前时间。
library;

/// 消息间隔超过该值才插时间锚点（同一天连续对话零开销）。
const Duration kTimeAnchorGap = Duration(hours: 6);

const List<String> _weekdays = [
  '星期一',
  '星期二',
  '星期三',
  '星期四',
  '星期五',
  '星期六',
  '星期日',
];

/// 当前时间的提示词表述，如 `2026-10-31 15:30（星期五）`。
String formatCurrentTime(DateTime now) {
  final local = now.toLocal();
  final md = '${_pad(local.month)}-${_pad(local.day)}';
  final hm = '${_pad(local.hour)}:${_pad(local.minute)}';
  return '${local.year}-$md $hm（${_weekdays[local.weekday - 1]}）';
}

/// 历史消息相对当前时间的锚点标签，如 `今天 14:00` / `昨天 21:35` /
/// `3天前 09:12` / `10月29日 15:00` / `2025年12月3日 09:00`。
String timeAnchorLabel(DateTime now, DateTime ts) {
  final n = now.toLocal();
  final t = ts.toLocal();
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(t.year, t.month, t.day);
  final diffDays = today.difference(day).inDays;
  final hm = '${_pad(t.hour)}:${_pad(t.minute)}';
  if (diffDays <= 0) return '今天 $hm';
  if (diffDays == 1) return '昨天 $hm';
  if (diffDays < 7) return '$diffDays天前 $hm';
  if (t.year != n.year) return '${t.year}年${t.month}月${t.day}日 $hm';
  return '${t.month}月${t.day}日 $hm';
}

String _pad(int v) => v.toString().padLeft(2, '0');
