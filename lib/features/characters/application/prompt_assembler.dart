/// 提示词组装：把角色卡 + 会话历史拼成 /chat/completions 的 messages。
///
/// 顺序（M2 定案 + v6 记忆注入 + v8 用户画像/时间锚点/多段规范）：
/// 1. system 人设（名字/描述/性格）
/// 2. system 当前时间（时间感知）
/// 3. system 场景（可选）
/// 4. system 跨会话记忆：长期摘要 + 近期原文片段（可选，v6）
/// 5. system 角色对用户的了解（可选，v8）
/// 6. system 对话示例（few-shot，只进 system 不进历史）
/// 7. system 回复风格/分段/情绪标签规范（放最后，离对话最近）
/// 8. 滑动窗口：最近 40 条完成状态的文本消息（含角色开场白，它以
///    assistant 消息入库）；跨日/长间隔处带时间锚点前缀。
library;

import '../../../core/utils/time_anchor.dart';
import '../../chat/application/emotion_tag_parser.dart' show stripTagMarkup;
import '../../chat/data/chat_api_client.dart';
import '../../chat/domain/models.dart';
import '../domain/character.dart';

class PromptAssembler {
  /// 滑动窗口大小。
  static const int windowSize = 40;

  /// 回复风格 + 多段分隔符 + 情绪/动作标签输出规范。
  /// 标签解析与剥离由 [EmotionTagParser] 负责，分段由 [SegmentSplitter]
  /// 负责（行制检测 `[P]`），M3 起桌宠消费情绪事件，v8 起情绪驱动表情包。
  ///
  /// v8.1：真机反馈"回复依然很长一大段"，把长度约束提到最前、加上
  /// 正例示范，并把本段作为**最后一条 system**（离对话最近，最不易被淹没）。
  static const String tagSpecInstruction =
      '【输出格式：你在手机上聊天，像真人打字，不是在写小说】\n'
      '1. 一条消息只发 1~3 句短话，通常不超过 80 字；口语化、带语气词。'
      '不要写环境描写、心理独白、旁白总结或剧情回顾——这些又长又像 AI。\n'
      '2. 想连着说几件事时，像真人一样拆成几条消息：段与段之间单独一行写 [P]，'
      '一轮最多 4 段，每段都要短。宁可分成几条短消息，也不要堆成一大段。'
      '[P] 只能独占一行，绝不能出现在代码块、引用或句子中间。\n'
      '3. 情绪标签穿插在台词中，界面会隐藏它、由桌宠演绎：'
      '<emotion:happy>喜、<emotion:angry>怒、<emotion:sad>哀、<emotion:amused>乐、'
      '<emotion:confused>疑惑、<emotion:shy>害羞、<emotion:surprised>惊讶、'
      '<emotion:smug>得意、<emotion:speechless>无语、<emotion:scared>害怕、'
      '<emotion:crying>哭泣、<emotion:loving>心动、<emotion:thinking>思考、'
      '<emotion:sleepy>困倦；'
      '动作标签：<action:wave>、<action:nod>、<action:shake_head>'
      '（英文小写，下划线分词）。\n'
      '4. 每条回复的情绪标签不超过 2 个，放在情绪最明显的位置；'
      '标签自包含，不需要闭合、不需要结束标记。'
      '除上述标签外不要输出任何其他标记或解释。\n'
      '示例（这就是你该有的说话节奏）：\n'
      '<emotion:amused>诶？你居然还记得呀，我还以为你早忘了\n'
      '[P]\n'
      '<emotion:shy>……哼，才、才没有很开心呢';

  /// 组装完整请求消息列表。
  ///
  /// [memorySummary] 长期记忆摘要、[pastTranscript] 同角色其他会话的
  /// 近期完成消息（时序）、[userSummary] 角色对用户的了解（v8）；
  /// 各段任一为空则跳过。[now] 注入当前时间便于测试。
  List<ApiMessage> assemble({
    required Character character,
    required List<ChatMessage> history,
    String memorySummary = '',
    List<ChatMessage> pastTranscript = const [],
    String userSummary = '',
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final system = <ApiMessage>[];

    final persona = StringBuffer('你将扮演以下角色，全程保持角色设定，绝不出戏。\n')
      ..write('名字：${character.name}\n');
    if (character.description.trim().isNotEmpty) {
      persona.write('描述：${character.description.trim()}\n');
    }
    if (character.personality.trim().isNotEmpty) {
      persona.write('性格：${character.personality.trim()}');
    }
    system.add(
      ApiMessage(role: 'system', content: persona.toString().trimRight()),
    );

    // 当前时间（时间感知，v8）：配合历史消息的时间锚点，
    // 角色能推断「那是昨天/3天前的事」而不是顺着"刚刚"。
    system.add(
      ApiMessage(
        role: 'system',
        content: '现在时间：${formatCurrentTime(currentTime)}',
      ),
    );

    if (character.scenario.trim().isNotEmpty) {
      system.add(
        ApiMessage(role: 'system', content: '场景：${character.scenario.trim()}'),
      );
    }

    if (memorySummary.trim().isNotEmpty) {
      system.add(
        ApiMessage(
          role: 'system',
          content:
              '以下是该角色对过往对话的记忆摘要（第一人称，由历次对话自动整理，'
              '可能不完整），请自然延续这些记忆与关系进展，不要生硬复述：\n'
              '${memorySummary.trim()}',
        ),
      );
    }

    if (pastTranscript.isNotEmpty) {
      DateTime? prevTs;
      final lines = <String>[];
      for (final m in pastTranscript) {
        // 旧版本落库的脏文本可能残留标签，喂给模型前先清掉。
        var text = stripTagMarkup(m.contentWithImageNote);
        if (prevTs != null &&
            m.createdAt.difference(prevTs) >= kTimeAnchorGap) {
          text = '【${timeAnchorLabel(currentTime, m.createdAt)}】$text';
        }
        prevTs = m.createdAt;
        lines.add('【${m.role == ChatRole.user ? '用户' : character.name}】$text');
      }
      system.add(
        ApiMessage(
          role: 'system',
          content:
              '以下是该角色与用户在【其他对话】中的近期片段，仅作背景参考，'
              '不是当前对话正在发生的内容，不要逐条复述：\n'
              '${lines.join('\n')}',
        ),
      );
    }

    if (userSummary.trim().isNotEmpty) {
      system.add(
        ApiMessage(
          role: 'system',
          content:
              '以下是该角色对这位用户的了解（角色视角，由历次对话自动整理），'
              '请据此自然地对待用户、体现你对TA的熟悉，不要生硬复述：\n'
              '${userSummary.trim()}',
        ),
      );
    }

    if (character.exampleDialogue.trim().isNotEmpty) {
      system.add(
        ApiMessage(
          role: 'system',
          content:
              '以下是该角色的对话示例，仅用于示范说话风格，不要当作真实对话内容：\n'
              '${character.exampleDialogue.trim()}',
        ),
      );
    }

    // 回复风格规范放在最后一条 system（v8.1）：离当前对话最近，
    // 最不容易被前面的长文本淹没——短回复/分段指令的命中率最高。
    system.add(const ApiMessage(role: 'system', content: tagSpecInstruction));

    // 滑动窗口：仅取完成、文本类（排除贴纸）、非空（含纯图消息的
    // [图片] 备注）的 user/assistant 消息，保留原始顺序（空消息可能是
    // 历史版本取消时留下的占位，部分端点会拒绝空 assistant）。
    // 历史只带图片概括文本。
    final done = [
      for (final m in history)
        if (m.status == MessageStatus.done &&
            m.kind == MessageKind.text &&
            m.role != ChatRole.system &&
            m.contentWithImageNote.trim().isNotEmpty)
          m,
    ];
    final window = done.length > windowSize
        ? done.sublist(done.length - windowSize)
        : done;

    // 时间锚点（v8）：跨自然日或长间隔（>6h）处给下一条消息加前缀，
    // 同一天连续对话零开销。
    DateTime? prevTs;
    final wire = <ApiMessage>[];
    for (final m in window) {
      var content = stripTagMarkup(m.contentWithImageNote);
      if (prevTs != null && m.createdAt.difference(prevTs) >= kTimeAnchorGap) {
        content = '【${timeAnchorLabel(currentTime, m.createdAt)}】$content';
      }
      prevTs = m.createdAt;
      wire.add(ApiMessage(role: m.role.wire, content: content));
    }

    return [...system, ...wire];
  }
}
