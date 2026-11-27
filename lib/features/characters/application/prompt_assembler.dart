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
/// 8. 滑动窗口：按 token 预算从最新消息往前取完成状态的文本消息
///    （含角色开场白，它以 assistant 消息入库）；跨日/长间隔处带时间锚点前缀。
library;

import 'dart:math' as math;

import '../../../core/utils/time_anchor.dart';
import '../../../core/utils/token_estimate.dart';
import '../../chat/application/emotion_tag_parser.dart' show stripTagMarkup;
import '../../chat/data/chat_api_client.dart';
import '../../chat/domain/models.dart';
import '../domain/character.dart';
import '../domain/lore_entry.dart';
import '../domain/memory_fact.dart';

/// 跨会话原文片段（按会话分组），供提示词渲染「【会话：标题】」。
class PastSession {
  final String title;
  final List<ChatMessage> messages;

  const PastSession({required this.title, required this.messages});
}

/// 一次组装后各分类的估算 token（用于聊天页用量 chip / sheet）。
class PromptUsage {
  /// 系统提示词：人设、时间、场景、示例对话、标签规范。
  final int systemTokens;

  /// 记忆：长期摘要 + 对用户的了解（事实记忆在 M3 计入 [factTokens]）。
  final int memoryTokens;

  /// 事实记忆（按需召回）。
  final int factTokens;

  /// 世界书命中条目。
  final int loreTokens;

  /// 跨会话原文片段。
  final int otherSessionTokens;

  /// 角色扩展档案块（v2.1：外貌/背景/关系/语言风格/互动方式）。
  final int profileTokens;

  /// 角色卡自带的系统提示 + 历史后置指令（v2.1）。
  final int cardPromptTokens;

  /// 本会话历史（含时间锚点）。
  final int historyTokens;

  /// 当前用户输入（预留，含图片摘要）。
  final int currentInputTokens;

  /// 用户设置的窗口大小（token）。
  final int windowTokens;

  const PromptUsage({
    this.systemTokens = 0,
    this.memoryTokens = 0,
    this.factTokens = 0,
    this.loreTokens = 0,
    this.otherSessionTokens = 0,
    this.profileTokens = 0,
    this.cardPromptTokens = 0,
    this.historyTokens = 0,
    this.currentInputTokens = 0,
    this.windowTokens = 4096,
  });

  static const empty = PromptUsage();

  int get usedTokens =>
      systemTokens +
      memoryTokens +
      factTokens +
      loreTokens +
      otherSessionTokens +
      profileTokens +
      cardPromptTokens +
      historyTokens +
      currentInputTokens;

  /// 实际可用于历史的预算（窗口的 90%，预留当前输入后）。
  int get budgetTokens => (windowTokens * 0.9).floor();

  int get remainingTokens => math.max(0, budgetTokens - usedTokens);

  /// 已用 / 窗口；用于 chip 百分比（系统部分也展示，可能超过 100%）。
  double get ratio => windowTokens <= 0 ? 0 : usedTokens / windowTokens;
}

class AssembledPrompt {
  final List<ApiMessage> messages;
  final PromptUsage usage;

  const AssembledPrompt({required this.messages, required this.usage});
}

class PromptAssembler {
  /// 兼容旧调用方的滑动窗口常量；实际窗口由 token 预算决定。
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

  /// 兼容旧签名；默认预算下等价于 [assembleDetailed] 的 messages。
  List<ApiMessage> assemble({
    required Character character,
    required List<ChatMessage> history,
    String memorySummary = '',
    List<ChatMessage> pastTranscript = const [],
    List<PastSession> pastSessions = const [],
    List<MemoryFact> facts = const [],
    List<LoreEntry> lore = const [],
    String userSummary = '',
    DateTime? now,
    int tokenBudget = 4096,
    int otherTokenBudget = 1024,
    int reservedTokens = 0,
  }) => assembleDetailed(
    character: character,
    history: history,
    memorySummary: memorySummary,
    pastTranscript: pastTranscript,
    pastSessions: pastSessions,
    facts: facts,
    lore: lore,
    userSummary: userSummary,
    now: now,
    tokenBudget: tokenBudget,
    otherTokenBudget: otherTokenBudget,
    reservedTokens: reservedTokens,
  ).messages;

  /// 组装并返回分类用量，供聊天页展示。
  AssembledPrompt assembleDetailed({
    required Character character,
    required List<ChatMessage> history,
    String memorySummary = '',
    List<ChatMessage> pastTranscript = const [],
    List<PastSession> pastSessions = const [],
    List<MemoryFact> facts = const [],
    List<LoreEntry> lore = const [],
    String userSummary = '',
    DateTime? now,
    int tokenBudget = 4096,
    int otherTokenBudget = 1024,
    int reservedTokens = 0,
  }) {
    final currentTime = now ?? DateTime.now();
    final system = <ApiMessage>[];
    var systemTokens = 0;
    var memoryTokens = 0;
    var factTokens = 0;
    var loreTokens = 0;
    var profileTokens = 0;
    var cardPromptTokens = 0;

    final persona = StringBuffer('你将扮演以下角色，全程保持角色设定，绝不出戏。\n')
      ..write('名字：${character.name}\n');
    if (character.description.trim().isNotEmpty) {
      persona.write('描述：${character.description.trim()}\n');
    }
    if (character.personality.trim().isNotEmpty) {
      persona.write('性格：${character.personality.trim()}');
    }
    final personaMsg = ApiMessage(
      role: 'system',
      content: persona.toString().trimRight(),
    );
    system.add(personaMsg);
    systemTokens += _cost(personaMsg.content);

    // 角色扩展档案（v2.1）：只注入运行分区，整体上限窗口 12%，
    // 至少 300 token、最多 1200 token；超长按 token 截断。
    final profileText = character.profile.promptText.trim();
    if (profileText.isNotEmpty) {
      const header = '【角色档案补充设定】（按设定扮演，不要逐条复述）\n';
      final cap = math.min(
        1200,
        math.max(300, (tokenBudget * 0.12).floor()),
      );
      var body = profileText;
      if (_cost('$header$body') > cap) {
        final available = math.max(8, cap - _cost(header));
        body = truncateToTokens(body, available);
      }
      final msg = ApiMessage(role: 'system', content: '$header$body');
      system.add(msg);
      profileTokens += _cost(msg.content);
    }

    // 角色卡自带的系统提示（v2.1）：单独成条，限 2000 字符并保留尾部；
    // 输出格式规范仍是历史前的最后一条 system，不被卡内提示覆盖。
    final systemPrompt = character.profile.runConfig.systemPrompt.trim();
    if (systemPrompt.isNotEmpty) {
      final msg = ApiMessage(
        role: 'system',
        content:
            '【角色卡系统提示】（在不违反输出格式规范的前提下遵循）\n'
            '${_tailClip(systemPrompt, 2000)}',
      );
      system.add(msg);
      cardPromptTokens += _cost(msg.content);
    }

    // 当前时间（时间感知，v8）：配合历史消息的时间锚点，
    // 角色能推断「那是昨天/3天前的事」而不是顺着"刚刚"。
    final timeMsg = ApiMessage(
      role: 'system',
      content: '现在时间：${formatCurrentTime(currentTime)}',
    );
    system.add(timeMsg);
    systemTokens += _cost(timeMsg.content);

    if (character.scenario.trim().isNotEmpty) {
      final sceneMsg = ApiMessage(
        role: 'system',
        content: '场景：${character.scenario.trim()}',
      );
      system.add(sceneMsg);
      systemTokens += _cost(sceneMsg.content);
    }

    // 长期事实（记忆压缩）：只给「日期 + 事实」，明确要求被问细节时
    // 承认记不清而不是编造；放在近期摘要之前，先给骨架再给近期细节。
    if (facts.isNotEmpty) {
      final lines = <String>[];
      var chars = 0;
      for (final f in facts) {
        if (lines.length >= 60) break;
        final line = '[${_formatDate(f.occurredAt)}] ${f.fact.trim()}';
        if (chars + line.length > 1200) break;
        lines.add(line);
        chars += line.length + 1;
      }
      if (lines.isNotEmpty) {
        final msg = ApiMessage(
          role: 'system',
          content:
              '以下是你记得的长期事实（按时间倒序，方括号内是发生日期）。\n'
              '你只记得这些事实和发生时间，不记得具体过程；被问到细节时不要编造，'
              '可以自然地说「记不太清了」。不要生硬罗列这些事实：\n'
              '${lines.join('\n')}',
        );
        system.add(msg);
        factTokens += _cost(msg.content);
      }
    }

    if (memorySummary.trim().isNotEmpty) {
      final msg = ApiMessage(
        role: 'system',
        content:
            '以下是该角色对过往对话的记忆摘要（第一人称，由历次对话自动整理，'
            '可能不完整），请自然延续这些记忆与关系进展，不要生硬复述：\n'
            '${memorySummary.trim()}',
      );
      system.add(msg);
      memoryTokens += _cost(msg.content);
    }

    // 跨会话原文：按会话分组，每组独立配额，组内从最新往前取后正序渲染。
    final groups = pastSessions.isNotEmpty
        ? pastSessions
        : (pastTranscript.isEmpty
              ? const <PastSession>[]
              : [PastSession(title: '', messages: pastTranscript)]);
    if (groups.isNotEmpty && otherTokenBudget > 0) {
      final otherBudget = (otherTokenBudget * 0.9).floor();
      final blocks = <String>[];
      var used = 0;
      for (final group in groups) {
        if (group.messages.isEmpty) continue;
        final perGroup = groups.length <= 1
            ? otherBudget
            : math.max(1, otherBudget ~/ groups.length);
        final chosen = <ChatMessage>[];
        var groupUsed = 0;
        for (final m in group.messages.reversed) {
          final text = stripTagMarkup(m.contentWithImageNote);
          final cost = _cost(text);
          if (chosen.isNotEmpty && groupUsed + cost > perGroup) break;
          if (used + cost > otherBudget) break;
          chosen.add(m);
          groupUsed += cost;
          used += cost;
        }
        if (chosen.isEmpty) continue;
        final lines = _renderLines(
          chosen.reversed.toList(),
          character: character,
          currentTime: currentTime,
        );
        final title = group.title.trim();
        blocks.add(
          title.isEmpty ? lines.join('\n') : '【会话：$title】\n${lines.join('\n')}',
        );
      }
      if (blocks.isNotEmpty) {
        final msg = ApiMessage(
          role: 'system',
          content:
              '以下是该角色与用户在【其他对话】中的近期片段（按会话分组），'
              '仅作背景参考，不是当前对话正在发生的内容，不要逐条复述：\n'
              '${blocks.join('\n\n')}',
        );
        system.add(msg);
      }
    }

    if (userSummary.trim().isNotEmpty) {
      final msg = ApiMessage(
        role: 'system',
        content:
            '以下是该角色对这位用户的了解（角色视角，由历次对话自动整理），'
            '请据此自然地对待用户、体现你对TA的熟悉，不要生硬复述：\n'
            '${userSummary.trim()}',
      );
      system.add(msg);
      memoryTokens += _cost(msg.content);
    }

    if (character.exampleDialogue.trim().isNotEmpty) {
      final msg = ApiMessage(
        role: 'system',
        content:
            '以下是该角色的对话示例，仅用于示范说话风格，不要当作真实对话内容：\n'
            '${character.exampleDialogue.trim()}',
      );
      system.add(msg);
      systemTokens += _cost(msg.content);
    }

    // 回复风格规范放在最后一条 system（v8.1）：离当前对话最近，
    // 最不容易被前面的长文本淹没——短回复/分段指令的命中率最高。
    const tagMsg = ApiMessage(role: 'system', content: tagSpecInstruction);
    system.add(tagMsg);
    systemTokens += _cost(tagMsg.content);

    // 世界书（v1.9）：只在关键词命中时注入，预算 ≤ 窗口 15%。
    final loreBefore = <LoreEntry>[];
    final loreAfter = <LoreEntry>[];
    if (lore.isNotEmpty) {
      final loreBudget = (tokenBudget * 0.15).floor();
      var used = 0;
      for (final entry in lore) {
        final content = entry.content.trim();
        if (content.isEmpty) continue;
        final cost = estimateTokens(content);
        if (used + cost > loreBudget) break;
        (entry.isBefore ? loreBefore : loreAfter).add(entry);
        used += cost;
      }
    }
    loreBefore.sort((a, b) => b.depth.compareTo(a.depth));
    loreAfter.sort((a, b) => a.depth.compareTo(b.depth));

    ApiMessage? loreMessage(List<LoreEntry> entries, String intro) {
      if (entries.isEmpty) return null;
      final body = entries.map((e) => e.content.trim()).join('\n');
      final msg = ApiMessage(role: 'system', content: '$intro\n$body');
      loreTokens += _cost(msg.content);
      return msg;
    }

    final loreBeforeMsg = loreMessage(
      loreBefore,
      '以下是本场景的世界书设定（仅作背景事实，不要逐条复述）：',
    );
    final loreAfterMsg = loreMessage(
      loreAfter,
      '以下是紧邻当前场景的世界书补充设定（不要逐条复述）：',
    );

    final budget = (tokenBudget * 0.9).floor();
    final chosen = _selectHistory(
      history: history,
      budget: budget,
      reservedTokens: reservedTokens,
    );
    final wire = _wire(chosen, currentTime);
    var historyTokens = 0;
    for (final m in wire) {
      historyTokens += _cost(m.content);
    }

    final otherTokens = system
        .where((m) => m.content.contains('【其他对话】'))
        .fold<int>(0, (sum, m) => sum + _cost(m.content));

    // 历史后置指令（v2.1）：放在历史与世界书 after 之后、当前输入之前，
    // 限 1000 字符并保留尾部。
    final postHistory =
        character.profile.runConfig.postHistoryInstructions.trim();
    ApiMessage? postHistoryMsg;
    if (postHistory.isNotEmpty) {
      postHistoryMsg = ApiMessage(
        role: 'system',
        content: '【历史后置指令】\n${_tailClip(postHistory, 1000)}',
      );
      cardPromptTokens += _cost(postHistoryMsg.content);
    }

    return AssembledPrompt(
      messages: [
        ...system,
        ?loreBeforeMsg,
        ...wire,
        ?loreAfterMsg,
        ?postHistoryMsg,
      ],
      usage: PromptUsage(
        systemTokens: systemTokens,
        memoryTokens: memoryTokens,
        factTokens: factTokens,
        loreTokens: loreTokens,
        otherSessionTokens: otherTokens,
        profileTokens: profileTokens,
        cardPromptTokens: cardPromptTokens,
        historyTokens: historyTokens,
        currentInputTokens: reservedTokens,
        windowTokens: tokenBudget,
      ),
    );
  }

  /// 无角色会话：只有当前时间 + 按预算裁剪的裸历史。
  AssembledPrompt assembleBare({
    required List<ChatMessage> history,
    DateTime? now,
    int tokenBudget = 4096,
    int reservedTokens = 0,
  }) {
    final currentTime = now ?? DateTime.now();
    final timeMsg = ApiMessage(
      role: 'system',
      content: '现在时间：${formatCurrentTime(currentTime)}',
    );
    final budget = (tokenBudget * 0.9).floor();
    final chosen = _selectHistory(
      history: history,
      budget: budget,
      reservedTokens: reservedTokens,
    );
    final wire = _wire(chosen, currentTime, anchors: true);
    var historyTokens = 0;
    for (final m in wire) {
      historyTokens += _cost(m.content);
    }
    return AssembledPrompt(
      messages: [timeMsg, ...wire],
      usage: PromptUsage(
        systemTokens: _cost(timeMsg.content),
        historyTokens: historyTokens,
        currentInputTokens: reservedTokens,
        windowTokens: tokenBudget,
      ),
    );
  }

  List<({ChatMessage message, String text})> _selectHistory({
    required List<ChatMessage> history,
    required int budget,
    required int reservedTokens,
  }) {
    final done = [
      for (final m in history)
        if (m.status == MessageStatus.done &&
            m.kind == MessageKind.text &&
            m.role != ChatRole.system &&
            m.contentWithImageNote.trim().isNotEmpty)
          m,
    ];
    if (done.isEmpty) return const [];
    final available = math.max(0, budget - reservedTokens);
    final singleCap = math.max(8, (budget * 0.3).floor());
    final chosen = <({ChatMessage message, String text})>[];
    var used = 0;
    for (var i = done.length - 1; i >= 0; i--) {
      final m = done[i];
      final text = stripTagMarkup(m.contentWithImageNote);
      var cost = _cost(text);
      final mustKeep = chosen.length < 2;
      if (!mustKeep && used + cost > available) break;
      if (cost > singleCap) {
        // 单条超预算 30%：截断后仍保留在窗口里，避免一条长文挤掉全部上下文。
        // 只改提示词里的副本，不改库里的消息。
        final clipped = truncateToTokens(text, singleCap - 4);
        chosen.add((message: m, text: clipped));
        cost = _cost(clipped);
      } else {
        chosen.add((message: m, text: text));
      }
      used += cost;
      if (used >= available && chosen.length >= 2) break;
    }
    return chosen.reversed.toList();
  }

  List<ApiMessage> _wire(
    List<({ChatMessage message, String text})> chosen,
    DateTime currentTime, {
    bool anchors = true,
  }) {
    DateTime? prevTs;
    final wire = <ApiMessage>[];
    for (final item in chosen) {
      var content = item.text;
      if (anchors &&
          prevTs != null &&
          item.message.createdAt.difference(prevTs) >= kTimeAnchorGap) {
        content = '【${timeAnchorLabel(currentTime, item.message.createdAt)}】$content';
      }
      prevTs = item.message.createdAt;
      wire.add(ApiMessage(role: item.message.role.wire, content: content));
    }
    return wire;
  }

  List<String> _renderLines(
    List<ChatMessage> messages, {
    required Character character,
    required DateTime currentTime,
  }) {
    DateTime? prevTs;
    final lines = <String>[];
    for (final m in messages) {
      var text = stripTagMarkup(m.contentWithImageNote);
      if (prevTs != null && m.createdAt.difference(prevTs) >= kTimeAnchorGap) {
        text = '【${timeAnchorLabel(currentTime, m.createdAt)}】$text';
      }
      prevTs = m.createdAt;
      lines.add('【${m.role == ChatRole.user ? '用户' : character.name}】$text');
    }
    return lines;
  }

  String _formatDate(DateTime value) {
    final d = value.toLocal();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  int _cost(String text) => 4 + estimateTokens(text);

  /// 保留字符串尾部（指令通常在末尾），避免截掉关键约束。
  String _tailClip(String text, int maxChars) {
    if (text.length <= maxChars) return text;
    return text.substring(text.length - maxChars);
  }
}
