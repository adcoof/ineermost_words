/// 消息列表：气泡流 + 微信式时间戳分隔（间隔>5分钟或首条时居中显示）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/models.dart';

/// 相邻消息间隔超过该值才插入时间分隔（微信同款规则）。
const Duration kTimeSeparatorGap = Duration(minutes: 5);

/// 格式化消息时间（微信式）：今天 HH:mm；昨天 HH:mm；同年 M月d日 HH:mm；
/// 跨年 yyyy年M月d日 HH:mm。
String formatMessageTime(DateTime t, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  final hm = '${two(t.hour)}:${two(t.minute)}';
  final today = DateTime(ref.year, ref.month, ref.day);
  final day = DateTime(t.year, t.month, t.day);
  final diffDays = today.difference(day).inDays;
  if (diffDays == 0) return hm;
  if (diffDays == 1) return '昨天 $hm';
  if (t.year == ref.year) return '${t.month}月${t.day}日 $hm';
  return '${t.year}年${t.month}月${t.day}日 $hm';
}

/// 逐条计算时间分隔文案；不需要分隔的位置为 null。
List<String?> timeSeparators(List<ChatMessage> messages, {DateTime? now}) {
  final labels = List<String?>.filled(messages.length, null);
  for (var i = 0; i < messages.length; i++) {
    final t = messages[i].createdAt;
    final show = i == 0 ||
        t.difference(messages[i - 1].createdAt) > kTimeSeparatorGap;
    if (show) labels[i] = formatMessageTime(t, now: now);
  }
  return labels;
}

class MessageList extends ConsumerStatefulWidget {
  final String conversationId;

  const MessageList({super.key, required this.conversationId});

  @override
  ConsumerState<MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<MessageList> {
  /// 列表滚动控制器。
  final ScrollController _controller = ScrollController();

  /// 首次跳底是否已完成（一次性 jumpTo，无动画）。
  bool _initialDone = false;

  /// 上一帧消息数（检测列表增删）。
  int _lastCount = -1;

  /// 上一帧末条消息内容（检测流式增长）。
  String _lastContent = '';

  @override
  void didUpdateWidget(covariant MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      // 会话切换（widget 可能被复用）：重置跟踪状态，新会话重新跳底。
      _initialDone = false;
      _lastCount = -1;
      _lastContent = '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 布局前（上一帧坐标系）判断用户是否已在底部附近。
  ///
  /// 无坐标（列表尚未挂载）视作贴底：没有需要保留的浏览位置。
  bool get _nearBottom {
    if (!_controller.hasClients) return true;
    final position = _controller.position;
    return position.maxScrollExtent - position.pixels <= 120;
  }

  /// 比对消息指纹并在需要时安排滚到底部。
  ///
  /// 必须在本帧布局前调用：[nearBottom] 取自上一帧坐标，
  /// 保证「贴底跟随」与「用户翻历史不拉回」的判定基于更新前状态。
  void _maybeScheduleScroll(List<ChatMessage> messages) {
    final count = messages.length;
    final lastContent = messages.isEmpty ? '' : messages.last.content;
    // 「该滚」的变化：首帧数据 || 消息数变化 || 末条消息 content 变化。
    final changed =
        !_initialDone || count != _lastCount || lastContent != _lastContent;
    final nearBottom = _nearBottom;
    _lastCount = count;
    _lastContent = lastContent;

    if (!changed || messages.isEmpty) return;
    final isFirst = !_initialDone;
    // 用户翻历史中，绝不强行拉回。
    if (!isFirst && !nearBottom) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 防 stale：回调时再校验挂载与坐标。
      if (!mounted || !_controller.hasClients) return;
      final target = _controller.position.maxScrollExtent;
      if (isFirst) {
        // 首次有数据：一次性跳底，无动画，避免先闪顶部再跳。
        // 首帧 maxScrollExtent 基于已构建子项估算，气泡高矮不一时会偏小，
        // 跳完若 extent 仍增长要连续补跳直到收敛（见 _settleInitialJump）。
        _initialDone = true;
        if (_controller.offset != target) _controller.jumpTo(target);
        _settleInitialJump(0);
      } else if (_controller.offset != target) {
        // 贴底跟随：短动画；动画结束回调兜底补跳，见 [_followUpAfterAnimate]。
        _controller
            .animateTo(
              target,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            )
            .then((_) => _followUpAfterAnimate(target));
      }
    });
  }

  /// 首次跳底后的收敛补跳。
  ///
  /// ListView.builder 首帧的 maxScrollExtent 是估算值（仅基于视口+缓存区
  /// 已构建的子项外推），消息气泡高矮差异大时会明显偏小，一次 jumpTo 落不到
  /// 真底。每帧跳后由下一帧的 post-frame 再比对，extent 稳定才收手；
  /// 文本气泡高度无异步加载，通常 1~2 帧内收敛。
  void _settleInitialJump(int round) {
    if (round >= 5) return; // 上限护栏，防极端布局反复跳
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      final position = _controller.position;
      if (position.maxScrollExtent - position.pixels > 1.0) {
        _controller.jumpTo(position.maxScrollExtent);
        _settleInitialJump(round + 1);
      }
    });
  }

  /// animateTo 结束后的兜底跟随。
  ///
  /// 动画在途（200ms 窗口）内到达的更新会被 [_nearBottom] 判定丢弃：build 时
  /// 读到的像素仍在向旧 target 途中，距离 = 剩余动画距离 + 已布局增量，易超
  /// 阈值；动画按旧 target 结束后与新 max 仍可能有差距，若不补跳，后续每次
  /// 更新会继续被丢弃，列表永久卡在底部上方。
  /// 仅当像素停在旧 target（滚动未被用户接管）且确实没到底时才继续贴底；
  /// 用户拖走接管滚动时 animateTo 的 future 不会正常结束，天然不进本回调。
  void _followUpAfterAnimate(double target) {
    if (!mounted || !_controller.hasClients) return;
    final position = _controller.position;
    if ((position.pixels - target).abs() > 1.0) return; // 用户已接管滚动
    if (position.maxScrollExtent - position.pixels <= 1.0) return; // 已到底
    final next = position.maxScrollExtent;
    _controller
        .animateTo(
          next,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        )
        .then((_) => _followUpAfterAnimate(next));
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(chatRepositoryProvider);
    return StreamBuilder<List<ChatMessage>>(
      stream: repo.watchMessages(widget.conversationId),
      builder: (context, snapshot) {
        final messages = snapshot.data ?? const [];
        if (messages.isEmpty) {
          // 空列表不挂 controller；仍记录指纹，数据到达后能正确跳底。
          _maybeScheduleScroll(messages);
          return const Center(child: Text('输入第一条消息开始对话'));
        }
        _maybeScheduleScroll(messages);
        final separators = timeSeparators(messages);
        return ListView.builder(
          controller: _controller,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final m = messages[index];
            final bubble = _MessageBubble(
              message: m,
              isStreaming: m.status == MessageStatus.streaming,
            );
            final label = separators[index];
            if (label == null) return bubble;
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 4 : 12, bottom: 6),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
                bubble,
              ],
            );
          },
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isStreaming;

  const _MessageBubble({required this.message, required this.isStreaming});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final scheme = Theme.of(context).colorScheme;
    final bg = isUser ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final fg = isUser ? scheme.onPrimaryContainer : scheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.content.isEmpty && isStreaming)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fg,
                ),
              )
            else
              SelectableText(
                message.content,
                style: TextStyle(color: fg, fontSize: 15, height: 1.4),
              ),
            if (message.status == MessageStatus.error)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '生成失败',
                  style: TextStyle(
                      color: scheme.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
            if (isStreaming && message.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '生成中…',
                  style: TextStyle(color: fg.withValues(alpha: 0.6), fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
