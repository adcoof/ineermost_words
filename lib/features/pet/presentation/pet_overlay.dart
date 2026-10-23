/// 聊天页桌宠悬浮层：透明 WebView + 情绪事件编排。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:async';

import '../../../app/providers.dart';
import '../application/pet_orchestrator.dart';
import '../data/pet_controller_webview.dart';
import '../domain/pet_model.dart';
import 'pet_webview.dart';

/// 悬浮在聊天页右下角的桌宠。
class PetOverlay extends ConsumerStatefulWidget {
  final PetModel model;

  const PetOverlay({super.key, required this.model});

  @override
  ConsumerState<PetOverlay> createState() => _PetOverlayState();
}

class _PetOverlayState extends ConsumerState<PetOverlay> {
  late final PetControllerWebview _controller;
  PetOrchestrator? _orchestrator;
  StreamSubscription<double>? _lipSub;

  @override
  void initState() {
    super.initState();
    _controller = PetControllerWebview();
    _orchestrator = PetOrchestrator(
      controller: _controller,
      repo: ref.read(petModelRepositoryProvider),
      petModelId: widget.model.id,
    );
    // 订阅聊天情绪流（控制器为全局单例，事件即发即收）。
    _orchestrator!
        .bindEmotionStream(ref.read(chatControllerProvider.notifier).emotionEvents);
    // 订阅 TTS 口型值 → Live2D 嘴型。
    _lipSub = ref.read(voiceOrchestratorProvider).lipValues.listen((v) {
      _controller.setLipSync(v);
    });
  }

  @override
  void dispose() {
    _lipSub?.cancel();
    _orchestrator?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 交互区域就是外层 Positioned 的矩形：框内点桌宠、框外照常聊天。
    return PetWebView(
      controller: _controller,
      entryJsonPath: widget.model.entryJsonPath,
    );
  }
}
