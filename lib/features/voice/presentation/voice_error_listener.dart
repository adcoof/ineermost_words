/// 应用级语音错误提示：监听 TTS 队列错误流，去抖后弹 SnackBar。
///
/// 合成/播放失败必须让用户看见（去抖 3s，避免逐句失败刷屏），
/// 静默跳过正是「没声音」排查时最坑的行为。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

class VoiceErrorListener extends ConsumerStatefulWidget {
  final Widget child;

  const VoiceErrorListener({super.key, required this.child});

  @override
  ConsumerState<VoiceErrorListener> createState() =>
      _VoiceErrorListenerState();
}

class _VoiceErrorListenerState extends ConsumerState<VoiceErrorListener> {
  StreamSubscription<String>? _sub;
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _sub = ref.read(voiceOrchestratorProvider).queue.errors.listen(_onError);
  }

  void _onError(String message) {
    final now = DateTime.now();
    if (now.difference(_last) < const Duration(seconds: 3)) return;
    _last = now;
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
