/// 聊天输入栏：文本框 + 发送 + 按住说话（ASR）。
///
/// 按住麦克风：打断 TTS 播报并开始识别；松手：识别结果直接发送。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/providers.dart';
import '../../voice/domain/asr_provider.dart';

class ChatInputBar extends ConsumerStatefulWidget {
  const ChatInputBar({super.key});

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  bool _listening = false;
  String _partial = '';
  String _finalText = '';
  bool _sent = false;
  Timer? _releaseFallback;

  @override
  void dispose() {
    _releaseFallback?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    ref.read(chatControllerProvider.notifier).send(text);
    _focusNode.requestFocus();
  }

  Future<void> _startListening() async {
    if (_listening) return;
    // 打断：TTS 播报立即停；流式生成中也停。
    ref.read(voiceOrchestratorProvider).bargeIn();
    if (ref.read(chatControllerProvider).isStreaming) {
      ref.read(chatControllerProvider.notifier).stop();
    }
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('需要麦克风权限才能语音输入')),
        );
      }
      return;
    }
    _partial = '';
    _finalText = '';
    _sent = false;
    setState(() => _listening = true);
    final asr = ref.read(asrProviderProvider);
    await asr.start(AsrCallbacks(
      onPartial: (p) {
        if (!mounted || !_listening) return;
        setState(() {
          _partial = p;
          _controller.text = p;
        });
      },
      onFinal: (t) {
        if (!mounted || _sent) return;
        _finalText = t;
        _releaseFallback?.cancel();
        _commitResult();
      },
      onError: (e) {
        if (!mounted) return;
        setState(() => _listening = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      },
    ));
  }

  Future<void> _stopListening() async {
    if (!_listening) return;
    setState(() => _listening = false); // 图标先复位，结果稍后到。
    await ref.read(asrProviderProvider).stop();
    // 兜底：最终结果回调迟迟不来时，用部分结果或放弃。
    _releaseFallback?.cancel();
    _releaseFallback = Timer(const Duration(milliseconds: 1500), () {
      if (!_sent) _commitResult();
    });
  }

  void _commitResult() {
    if (_sent) return;
    _sent = true;
    final text = (_finalText.isNotEmpty ? _finalText : _partial).trim();
    _partial = '';
    _finalText = '';
    _controller.clear();
    if (text.isNotEmpty) {
      ref.read(chatControllerProvider.notifier).send(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStreaming = ref.watch(chatControllerProvider).isStreaming;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: _listening ? '松手发送，识别中…' : '输入消息…',
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 按住说话。
            Listener(
              onPointerDown: (_) => unawaited(_startListening()),
              onPointerUp: (_) => unawaited(_stopListening()),
              onPointerCancel: (_) => unawaited(_stopListening()),
              child: IconButton.filledTonal(
                tooltip: '按住说话',
                onPressed: () {}, // 事件走 Listener。
                icon: Icon(_listening ? Icons.mic : Icons.mic_none),
                color: _listening ? Theme.of(context).colorScheme.error : null,
              ),
            ),
            const SizedBox(width: 4),
            IconButton.filled(
              tooltip: isStreaming ? '生成中' : '发送',
              onPressed: isStreaming ? null : _send,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
