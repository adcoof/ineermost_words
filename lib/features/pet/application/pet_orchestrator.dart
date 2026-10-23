/// 桌宠编排器：把聊天流里的情绪事件翻译成桌宠指令并驱动控制器。
///
/// 规则（M3 定案）：
/// - expression 播放后 ~8s 自动复位到默认；
/// - motion 按 priority 掩蔽：高优先级动作播放期间（~3s）忽略低优先级；
/// - 映射解析直达数据库，改映射即时生效。
library;

import 'dart:async';

import '../../chat/application/emotion_tag_parser.dart';
import '../data/pet_controller_webview.dart';
import '../data/pet_model_repository.dart';
import '../domain/pet_command.dart';

class PetOrchestrator {
  final PetController controller;
  final PetModelRepository repo;
  final String petModelId;

  StreamSubscription<EmotionEvent>? _sub;
  Timer? _expressionResetTimer;
  Timer? _motionGuardTimer;
  int _motionPriorityFloor = 0;
  PetCommand? _lastCommand;

  /// 最近一次执行的指令（调试/试触发 UI 显示用）。
  PetCommand? get lastCommand => _lastCommand;

  PetOrchestrator({
    required this.controller,
    required this.repo,
    required this.petModelId,
  });

  /// 订阅聊天情绪事件流。
  void bindEmotionStream(Stream<EmotionEvent> stream) {
    _sub?.cancel();
    _sub = stream.listen(onEmotion);
  }

  /// 处理一个情绪事件（也可由「试触发」直接调用）。
  Future<void> onEmotion(EmotionEvent event) async {
    final command = await repo.resolve(event, petModelId);
    if (command != null) await execute(command);
  }

  /// 执行一条指令（含回落与掩蔽逻辑）。
  Future<void> execute(PetCommand command) async {
    switch (command.type) {
      case PetCommandType.setExpression:
        _expressionResetTimer?.cancel();
        await controller.setExpression(command.expressionId);
        _lastCommand = command;
        if (command.expressionId.isNotEmpty) {
          _expressionResetTimer = Timer(const Duration(seconds: 8), () async {
            await controller.setExpression('');
          });
        }
      case PetCommandType.startMotion:
        // 高优先级窗口期内忽略低优先级动作。
        if (command.priority < _motionPriorityFloor) return;
        _motionPriorityFloor = command.priority;
        _motionGuardTimer?.cancel();
        _motionGuardTimer = Timer(const Duration(seconds: 3), () {
          _motionPriorityFloor = 0;
        });
        await controller.startMotion(command.motionGroup,
            index: command.motionIndex, priority: command.priority);
        _lastCommand = command;
      case PetCommandType.setLipSync:
        await controller.setLipSync(command.lipSyncValue);
        _lastCommand = command;
    }
  }

  void dispose() {
    _sub?.cancel();
    _expressionResetTimer?.cancel();
    _motionGuardTimer?.cancel();
  }
}
