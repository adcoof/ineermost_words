/// 提示词组装：把角色卡 + 会话历史拼成 /chat/completions 的 messages。
///
/// 顺序（M2 定案 + v6 记忆注入）：
/// 1. system 人设（名字/描述/性格）
/// 2. system 场景（可选）
/// 3. system 跨会话记忆：长期摘要 + 近期原文片段（可选，v6）
/// 4. system 情绪/动作标签输出规范
/// 5. system 对话示例（few-shot，只进 system 不进历史）
/// 6. 滑动窗口：最近 40 条完成状态的消息（含角色开场白，它以 assistant 消息入库）
library;

import '../../chat/data/chat_api_client.dart';
import '../../chat/domain/models.dart';
import '../domain/character.dart';

class PromptAssembler {
  /// 滑动窗口大小。
  static const int windowSize = 40;

  /// 情绪/动作标签输出规范。解析与剥离由 [EmotionTagParser] 负责，
  /// M3 起桌宠消费这些事件。
  static const String tagSpecInstruction =
      '在需要表达情绪或动作时，可以在句子中插入标签，例如 '
      '<emotion:happy>、<emotion:sad>、<emotion:angry>、<emotion:shy>、'
      '<emotion:surprised> 表示情绪，<action:wave>、<action:nod>、'
      '<action:shake_head> 表示动作（英文小写，下划线分词）。'
      '标签会被界面隐藏、由桌宠演绎，直接穿插在台词中即可；'
      '标签是自包含的，无需闭合、无需配套输出结束标记，'
      '除此之外不要输出任何其他标记或解释。';

  /// 组装完整请求消息列表。
  ///
  /// [memorySummary] 长期记忆摘要、[pastTranscript] 同角色其他会话的
  /// 近期完成消息（时序）；两者任一为空则跳过对应段。
  List<ApiMessage> assemble({
    required Character character,
    required List<ChatMessage> history,
    String memorySummary = '',
    List<ChatMessage> pastTranscript = const [],
  }) {
    final system = <ApiMessage>[];

    final persona = StringBuffer('你将扮演以下角色，全程保持角色设定，绝不出戏。\n')
      ..write('名字：${character.name}\n');
    if (character.description.trim().isNotEmpty) {
      persona.write('描述：${character.description.trim()}\n');
    }
    if (character.personality.trim().isNotEmpty) {
      persona.write('性格：${character.personality.trim()}');
    }
    system.add(ApiMessage(role: 'system', content: persona.toString().trimRight()));

    if (character.scenario.trim().isNotEmpty) {
      system.add(
          ApiMessage(role: 'system', content: '场景：${character.scenario.trim()}'));
    }

    if (memorySummary.trim().isNotEmpty) {
      system.add(ApiMessage(
        role: 'system',
        content: '以下是该角色对过往对话的记忆摘要（第一人称，由历次对话自动整理，'
            '可能不完整），请自然延续这些记忆与关系进展，不要生硬复述：\n'
            '${memorySummary.trim()}',
      ));
    }

    if (pastTranscript.isNotEmpty) {
      final lines = [
        for (final m in pastTranscript)
          '【${m.role == ChatRole.user ? '用户' : character.name}】${m.content}',
      ];
      system.add(ApiMessage(
        role: 'system',
        content: '以下是该角色与用户在【其他对话】中的近期片段，仅作背景参考，'
            '不是当前对话正在发生的内容，不要逐条复述：\n'
            '${lines.join('\n')}',
      ));
    }

    system.add(const ApiMessage(role: 'system', content: tagSpecInstruction));

    if (character.exampleDialogue.trim().isNotEmpty) {
      system.add(ApiMessage(
        role: 'system',
        content:
            '以下是该角色的对话示例，仅用于示范说话风格，不要当作真实对话内容：\n'
            '${character.exampleDialogue.trim()}',
      ));
    }

    // 滑动窗口：仅取完成且非空的 user/assistant 消息，保留原始顺序
    // （空消息可能是历史版本取消时留下的占位，部分端点会拒绝空 assistant）。
    final done = [
      for (final m in history)
        if (m.status == MessageStatus.done &&
            m.role != ChatRole.system &&
            m.content.trim().isNotEmpty) m,
    ];
    final window = done.length > windowSize
        ? done.sublist(done.length - windowSize)
        : done;

    return [
      ...system,
      for (final m in window)
        ApiMessage(role: m.role.wire, content: m.content),
    ];
  }
}
