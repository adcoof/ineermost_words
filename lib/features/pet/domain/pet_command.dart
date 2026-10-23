/// 桌宠指令：EmotionMapper 的输出，PetController 的输入。
library;

/// 指令类型。
enum PetCommandType {
  /// 切换表情（空字符串 = 复位到默认）。
  setExpression,

  /// 播放动作。
  startMotion,

  /// 口型驱动（M4 使用，0..1）。
  setLipSync,
}

class PetCommand {
  final PetCommandType type;

  /// setExpression：表情 id（'' 复位）。
  final String expressionId;

  /// startMotion：动作组名（如 Idle / TapBody）。
  final String motionGroup;

  /// startMotion：组内序号。
  final int motionIndex;

  /// startMotion：优先级，高优先级掩蔽低优先级。
  final int priority;

  /// setLipSync：口型开合度 0..1。
  final double lipSyncValue;

  const PetCommand.expression(String id)
      : type = PetCommandType.setExpression,
        expressionId = id,
        motionGroup = '',
        motionIndex = 0,
        priority = 1,
        lipSyncValue = 0;

  const PetCommand.motion(String group,
      {int index = 0, this.priority = 1})
      : type = PetCommandType.startMotion,
        expressionId = '',
        motionGroup = group,
        motionIndex = index,
        lipSyncValue = 0;

  const PetCommand.lip(double value)
      : type = PetCommandType.setLipSync,
        expressionId = '',
        motionGroup = '',
        motionIndex = 0,
        priority = 1,
        lipSyncValue = value;

  @override
  String toString() => switch (type) {
        PetCommandType.setExpression => 'expression($expressionId)',
        PetCommandType.startMotion =>
          'motion($motionGroup[$motionIndex], p$priority)',
        PetCommandType.setLipSync => 'lip($lipSyncValue)',
      };
}
