import 'package:ai_roleplay_chat/core/utils/token_estimate.dart';
import 'package:ai_roleplay_chat/features/chat/domain/models.dart';
import 'package:ai_roleplay_chat/features/characters/application/prompt_assembler.dart';
import 'package:ai_roleplay_chat/features/characters/domain/character.dart';
import 'package:ai_roleplay_chat/features/characters/domain/character_profile.dart';
import 'package:ai_roleplay_chat/features/characters/domain/lore_entry.dart';
import 'package:ai_roleplay_chat/features/characters/domain/memory_fact.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final character = Character(
    id: 'c1',
    name: '林小雨',
    description: '银发红瞳',
    personality: '冷淡毒舌',
    scenario: '天台',
    firstMessage: '*靠在栏杆上*……你来干什么？',
    exampleDialogue: '{{user}}：你好\n{{char}}：哼。',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  ChatMessage msg(ChatRole role, String content, {int minute = 0}) =>
      ChatMessage(
        id: 'm$role$content$minute',
        conversationId: 'conv',
        role: role,
        content: content,
        rawContent: content,
        emotionEvents: '[]',
        status: MessageStatus.done,
        createdAt: DateTime(2026, 1, 1, 0, minute),
      );

  group('PromptAssembler', () {
    test('system 顺序：人设 → 现在时间 → 场景 → 对话示例 → 标签规范（最后）', () {
      final messages = PromptAssembler().assemble(
        character: character,
        history: [msg(ChatRole.user, '嗨')],
        now: DateTime(2026, 1, 2, 15, 30),
      );

      expect(messages.first.role, 'system');
      expect(messages[0].content, contains('林小雨'));
      expect(messages[0].content, contains('银发红瞳'));
      expect(messages[0].content, contains('冷淡毒舌'));
      expect(messages[1].content, startsWith('现在时间：2026-01-02 15:30'));
      expect(messages[2].content, startsWith('场景：'));
      expect(messages[3].content, contains('对话示例'));
      expect(messages[3].content, contains('{{char}}'));
      // 风格规范必须是最后一条 system：离对话最近，短回复指令命中率最高。
      expect(messages[4].content, PromptAssembler.tagSpecInstruction);
      expect(
        messages.where((m) => m.role == 'system').last.content,
        PromptAssembler.tagSpecInstruction,
      );
    });

    test('场景为空时不产生场景 system 消息', () {
      final bare = character.copyWith(scenario: '');
      final messages = PromptAssembler().assemble(
        character: bare,
        history: const [],
      );
      final systems = messages
          .where((m) => m.role == 'system')
          .map((m) => m.content);
      expect(systems.any((s) => s.startsWith('场景：')), isFalse);
      expect(messages.length, 4); // 人设 + 现在时间 + 标签规范 + 示例
    });

    test('对话示例只进 system，不重复进历史', () {
      final messages = PromptAssembler().assemble(
        character: character,
        history: [msg(ChatRole.user, '嗨')],
      );
      final nonSystems = messages.where((m) => m.role != 'system').toList();
      expect(nonSystems.length, 1);
      expect(nonSystems.single.content, '嗨');
    });

    test('开场白（assistant 消息）保留在历史最前', () {
      final history = [
        msg(ChatRole.assistant, '*靠在栏杆上*……你来干什么？'),
        msg(ChatRole.user, '只是路过'),
      ];
      final messages = PromptAssembler().assemble(
        character: character,
        history: history,
      );
      final nonSystems = messages.where((m) => m.role != 'system').toList();
      expect(nonSystems.first.role, 'assistant');
      expect(nonSystems.first.content, contains('栏杆'));
      expect(nonSystems.last.content, '只是路过');
    });

    test('不再按 40 条硬截断：默认 4096 token 下 45 条短消息全部保留且顺序不变', () {
      final history = [
        for (var i = 0; i < 45; i++)
          msg(i.isEven ? ChatRole.user : ChatRole.assistant, '第$i条', minute: i),
      ];
      final messages = PromptAssembler().assemble(
        character: character,
        history: history,
      );
      final window = messages.where((m) => m.role != 'system').toList();
      expect(window.length, 45);
      expect(window.first.content, '第0条');
      expect(window.last.content, '第44条');
    });

    test('token 预算小：只保留最新的若干条，且至少保留最近 2 条', () {
      final history = [
        for (var i = 0; i < 30; i++)
          msg(
            i.isEven ? ChatRole.user : ChatRole.assistant,
            '这是一条很长的测试消息，用来占掉上下文预算，确保历史会被裁剪，编号 $i。',
            minute: i,
          ),
      ];
      final messages = PromptAssembler().assemble(
        character: character,
        history: history,
        tokenBudget: 1024,
      );
      final window = messages.where((m) => m.role != 'system').toList();
      expect(window.length, lessThan(30));
      expect(window.length, greaterThanOrEqualTo(2));
      expect(window.last.content, contains('编号 29'));
    });

    test('流式中/出错的消息不进历史', () {
      final history = [
        msg(ChatRole.user, '正常'),
        ChatMessage(
          id: 's1',
          conversationId: 'conv',
          role: ChatRole.assistant,
          content: '半截',
          rawContent: '半截',
          emotionEvents: '[]',
          status: MessageStatus.streaming,
          createdAt: DateTime(2026, 1, 1, 1),
        ),
        ChatMessage(
          id: 'e1',
          conversationId: 'conv',
          role: ChatRole.assistant,
          content: '（出错）',
          rawContent: '（出错）',
          emotionEvents: '[]',
          status: MessageStatus.error,
          createdAt: DateTime(2026, 1, 1, 2),
        ),
      ];
      final messages = PromptAssembler().assemble(
        character: character,
        history: history,
      );
      final window = messages.where((m) => m.role != 'system').toList();
      expect(window.map((m) => m.content), ['正常']);
    });

    test('表情包消息（kind=sticker）不进历史窗口', () {
      final sticker = ChatMessage(
        id: 'st1',
        conversationId: 'conv',
        role: ChatRole.assistant,
        content: '',
        rawContent: '',
        emotionEvents: '[]',
        imagePaths: '["/tmp/s.jpg"]',
        imageSummary: '表情包',
        status: MessageStatus.done,
        kind: MessageKind.sticker,
        createdAt: DateTime(2026, 1, 1, 0, 5),
      );
      final messages = PromptAssembler().assemble(
        character: character,
        history: [msg(ChatRole.user, '嗨'), sticker],
      );
      final window = messages.where((m) => m.role != 'system').toList();
      expect(window.length, 1);
      expect(window.single.content, '嗨');
    });
  });

  group('PromptAssembler 跨会话记忆', () {
    test('注入位置：场景后、对话示例与标签规范前；原文片段按角色名标注', () {
      final messages = PromptAssembler().assemble(
        character: character,
        history: [msg(ChatRole.user, '嗨')],
        memorySummary: '用户叫小明',
        pastTranscript: [
          msg(ChatRole.user, '上次聊了天气'),
          msg(ChatRole.assistant, '嗯，很热'),
        ],
      );

      expect(messages[3].content, contains('记忆摘要'));
      expect(messages[3].content, contains('用户叫小明'));
      expect(messages[4].content, contains('【其他对话】'));
      expect(messages[4].content, contains('【用户】上次聊了天气'));
      expect(messages[4].content, contains('【林小雨】嗯，很热'));
      expect(messages[5].content, contains('对话示例'));
      expect(messages[6].content, PromptAssembler.tagSpecInstruction);
      // 历史消息不受影响。
      final nonSystems = messages.where((m) => m.role != 'system').toList();
      expect(nonSystems.single.content, '嗨');
    });

    test('记忆参数缺省或空白：不产生额外 system', () {
      final bare = PromptAssembler().assemble(
        character: character,
        history: const [],
      );
      // 人设+现在时间+场景+标签+示例
      expect(bare.where((m) => m.role == 'system').length, 5);

      final blank = PromptAssembler().assemble(
        character: character,
        history: const [],
        memorySummary: '  ',
      );
      expect(blank.length, bare.length);
    });

    test('用户画像：注入在记忆之后、对话示例与标签规范之前', () {
      final messages = PromptAssembler().assemble(
        character: character,
        history: const [],
        memorySummary: '记忆正文',
        userSummary: '用户喜欢深夜聊天',
      );
      expect(messages[3].content, contains('记忆摘要'));
      expect(messages[4].content, contains('对这位用户的了解'));
      expect(messages[4].content, contains('深夜聊天'));
      expect(messages[5].content, contains('对话示例'));
      expect(messages[6].content, PromptAssembler.tagSpecInstruction);
    });
    test('跨会话原文预算为 0：只保留摘要与画像，不注入其他会话片段', () {
      final messages = PromptAssembler().assemble(
        character: character,
        history: [msg(ChatRole.user, '嗨')],
        memorySummary: '用户叫小明',
        userSummary: '用户喜欢猫',
        pastTranscript: [msg(ChatRole.user, '上次聊了天气')],
        otherTokenBudget: 0,
      );
      expect(
        messages.where((m) => m.content.contains('【其他对话】')),
        isEmpty,
      );
      expect(messages[3].content, contains('用户叫小明'));
      expect(messages[4].content, contains('用户喜欢猫'));
    });

    test('单条超长历史按预算截断而不是整条丢弃', () {
      final long = List.filled(200, '很长的历史内容。').join();
      final messages = PromptAssembler().assemble(
        character: character,
        history: [msg(ChatRole.user, long)],
        tokenBudget: 1024,
      );
      final nonSystem = messages.where((m) => m.role != 'system').single;
      expect(nonSystem.content.endsWith('…'), isTrue);
      expect(nonSystem.content.length, lessThan(long.length));
      expect(estimateTokens(nonSystem.content), lessThanOrEqualTo(307));
    });

    test('为当前输入预留预算后，历史只剩最近 2 条兜底', () {
      final messages = PromptAssembler().assemble(
        character: character,
        history: [
          for (var i = 0; i < 10; i++)
            msg(ChatRole.user, '第$i条比较长的历史消息，用于占预算。', minute: i),
        ],
        tokenBudget: 1024,
        reservedTokens: 900,
      );
      final nonSystem = messages.where((m) => m.role != 'system').toList();
      expect(nonSystem.length, 2);
      expect(nonSystem.last.content, contains('第9条'));
    });
  });

  group('PromptAssembler 事实记忆与会话分组（v9）', () {
    MemoryFact fact(String id, String text, DateTime at) => MemoryFact(
          id: id,
          characterId: character.id,
          fact: text,
          occurredAt: at,
          createdAt: DateTime(2026),
        );

    test('长期事实：场景后、近期摘要前，带日期与「不记得细节」约束', () {
      final assembled = PromptAssembler().assembleDetailed(
        character: character,
        history: [msg(ChatRole.user, '嗨')],
        facts: [
          fact('f1', '和用户去了关山', DateTime(2026, 1, 2)),
          fact('f2', '用户喜欢草莓', DateTime(2026, 1, 3)),
        ],
        memorySummary: '最近聊了旅行',
      );

      // 0 人设、1 时间、2 场景、3 事实、4 近期摘要、5 示例、6 标签规范。
      expect(assembled.messages[3].content, contains('长期事实'));
      expect(assembled.messages[3].content, contains('[2026-01-02] 和用户去了关山'));
      expect(assembled.messages[3].content, contains('[2026-01-03] 用户喜欢草莓'));
      expect(assembled.messages[3].content, contains('不要编造'));
      expect(assembled.messages[3].content, contains('记不太清'));
      expect(assembled.messages[4].content, contains('记忆摘要'));
      expect(assembled.usage.factTokens, greaterThan(0));
      expect(assembled.usage.usedTokens, greaterThan(assembled.usage.factTokens));
    });

    test('无事实：不产生事实 system，factTokens 为 0', () {
      final assembled = PromptAssembler().assembleDetailed(
        character: character,
        history: const [],
      );
      expect(
        assembled.messages.where((m) => m.content.contains('长期事实')),
        isEmpty,
      );
      expect(assembled.usage.factTokens, 0);
    });

    test('pastSessions：按会话分组、带会话标题、组内时序正序', () {
      final assembled = PromptAssembler().assembleDetailed(
        character: character,
        history: const [],
        pastSessions: [
          PastSession(title: '雨天的对话', messages: [
            msg(ChatRole.user, '带伞了吗', minute: 1),
            msg(ChatRole.assistant, '带了', minute: 2),
          ]),
          PastSession(title: '关山之行', messages: [
            msg(ChatRole.user, '山上下雪了', minute: 3),
          ]),
        ],
      );
      final block = assembled.messages
          .singleWhere((m) => m.content.contains('【其他对话】'));
      expect(block.content, contains('【会话：雨天的对话】'));
      expect(block.content, contains('【会话：关山之行】'));
      expect(block.content, contains('【用户】带伞了吗'));
      final rain = block.content.indexOf('带伞了吗');
      final mountain = block.content.indexOf('山上下雪了');
      expect(rain, lessThan(mountain)); // 分组顺序与会话输入顺序一致
      expect(assembled.usage.otherSessionTokens, greaterThan(0));
    });

    test('otherTokenBudget=0：pastSessions 也不注入', () {
      final assembled = PromptAssembler().assembleDetailed(
        character: character,
        history: const [],
        pastSessions: [
          PastSession(title: '旧会话', messages: [msg(ChatRole.user, '旧内容')]),
        ],
        otherTokenBudget: 0,
      );
      expect(
        assembled.messages.where((m) => m.content.contains('【其他对话】')),
        isEmpty,
      );
      expect(assembled.usage.otherSessionTokens, 0);
    });

    test('事实最多 60 条，超出部分不注入', () {
      final many = [
        for (var i = 0; i < 70; i++)
          fact('f$i', '事实编号$i', DateTime(2026, 1, 1).add(Duration(days: i))),
      ];
      final assembled = PromptAssembler().assembleDetailed(
        character: character,
        history: const [],
        facts: many,
      );
      final block = assembled.messages
          .singleWhere((m) => m.content.contains('长期事实'));
      final lines = block.content
          .split('\n')
          .where((l) => RegExp(r'^\[\d{4}-\d{2}-\d{2}\] ').hasMatch(l))
          .toList();
      expect(lines.length, 60);
      expect(block.content, isNot(contains('事实编号69')));
    });
  });

  group('PromptAssembler 时间锚点', () {
    final now = DateTime(2026, 1, 3, 12);

    test('跨自然日的消息带锚点前缀，同日短间隔不带', () {
      final history = [
        ChatMessage(
          id: 'a',
          conversationId: 'conv',
          role: ChatRole.user,
          content: '昨天说的事',
          rawContent: '昨天说的事',
          emotionEvents: '[]',
          status: MessageStatus.done,
          createdAt: DateTime(2026, 1, 2, 21, 35),
        ),
        ChatMessage(
          id: 'b',
          conversationId: 'conv',
          role: ChatRole.assistant,
          content: '嗯嗯我记得',
          rawContent: '嗯嗯我记得',
          emotionEvents: '[]',
          status: MessageStatus.done,
          createdAt: DateTime(2026, 1, 2, 21, 36),
        ),
        ChatMessage(
          id: 'c',
          conversationId: 'conv',
          role: ChatRole.user,
          content: '今天继续',
          rawContent: '今天继续',
          emotionEvents: '[]',
          status: MessageStatus.done,
          createdAt: DateTime(2026, 1, 3, 9, 0),
        ),
      ];
      final messages = PromptAssembler().assemble(
        character: character,
        history: history,
        now: now,
      );
      final window = messages.where((m) => m.role != 'system').toList();
      expect(window[0].content, '昨天说的事'); // 首条不加锚点
      expect(window[1].content, '嗯嗯我记得'); // 同日 1 分钟间隔：不加
      expect(window[2].content, startsWith('【今天 09:00】')); // 跨日：加
      expect(window[2].content, contains('今天继续'));
    });

    test('同一天内的长间隔（>6h）也带锚点', () {
      final history = [
        ChatMessage(
          id: 'a',
          conversationId: 'conv',
          role: ChatRole.user,
          content: '早上好',
          rawContent: '早上好',
          emotionEvents: '[]',
          status: MessageStatus.done,
          createdAt: DateTime(2026, 1, 3, 6, 0),
        ),
        ChatMessage(
          id: 'b',
          conversationId: 'conv',
          role: ChatRole.assistant,
          content: '早。',
          rawContent: '早。',
          emotionEvents: '[]',
          status: MessageStatus.done,
          createdAt: DateTime(2026, 1, 3, 13, 30),
        ),
      ];
      final messages = PromptAssembler().assemble(
        character: character,
        history: history,
        now: now,
      );
      final window = messages.where((m) => m.role != 'system').toList();
      expect(window[1].content, startsWith('【今天 13:30】'));
    });
  });

  group('世界书注入（v15）', () {
    LoreEntry entry(
      String id,
      String content, {
      String position = 'before',
      int depth = 0,
    }) => LoreEntry(
      id: id,
      characterId: 'c1',
      keys: const ['天台'],
      content: content,
      position: position,
      depth: depth,
      createdAt: DateTime(2026, 1, 1),
    );

    test('before 在历史前、after 在历史后，并计入 loreTokens', () {
      final history = [
        msg(ChatRole.user, '天台好冷', minute: 0),
        msg(ChatRole.assistant, '嗯。', minute: 1),
      ];
      final assembled = PromptAssembler().assembleDetailed(
        character: character,
        history: history,
        lore: [
          entry('a', '天台的风很大', position: 'before'),
          entry('b', '栏杆有些凉', position: 'after'),
        ],
      );
      final contents = assembled.messages.map((m) => m.content).toList();
      final beforeIndex = contents.indexWhere((c) => c.contains('天台的风很大'));
      final historyIndex = contents.indexWhere((c) => c.contains('天台好冷'));
      final afterIndex = contents.indexWhere((c) => c.contains('栏杆有些凉'));
      expect(beforeIndex, greaterThanOrEqualTo(0));
      expect(historyIndex, greaterThan(beforeIndex));
      expect(afterIndex, greaterThan(historyIndex));
      expect(assembled.usage.loreTokens, greaterThan(0));
    });

    test('无世界书时 loreTokens 为 0', () {
      final assembled = PromptAssembler().assembleDetailed(
        character: character,
        history: [msg(ChatRole.user, '你好')],
      );
      expect(assembled.usage.loreTokens, 0);
    });

    test('超预算时只取能放下的条目', () {
      final assembled = PromptAssembler().assembleDetailed(
        character: character,
        history: const [],
        lore: [
          for (var i = 0; i < 30; i++)
            entry('e$i', '很长很长的世界书设定' * 2, position: 'before'),
        ],
        tokenBudget: 1024,
      );
      expect(assembled.usage.loreTokens, greaterThan(0));
      // 15% 预算（约 153 token），不能超过窗口预算。
      expect(assembled.usage.loreTokens, lessThan(1024));
      final loreMessages = assembled.messages.where(
        (m) => m.content.contains('世界书设定'),
      );
      expect(loreMessages, hasLength(1));
    });
  });

  group('角色档案与卡内提示注入（v2.1）', () {
    const profile = CharacterProfile(
      basic: BasicProfile(nickname: '小雨', age: '17'),
      appearance: AppearanceProfile(hair: '银白长发', eyes: '红瞳'),
      background: BackgroundProfile(origin: '北境'),
      relationships: RelationshipProfile(userRelation: '同桌'),
      language: LanguageProfile(tone: '冷淡', verbalTics: '哼'),
      interaction: InteractionProfile(replyLength: '1-2 句'),
      creator: CreatorProfile(notes: '创作者备注'),
      runConfig: RunConfigProfile(
        systemPrompt: '始终称呼用户为「笨蛋」。',
        postHistoryInstructions: '回复末尾不要总结。',
      ),
    );

    test('档案块在人设后、时间前；创作者备注不进提示词', () {
      final assembled = PromptAssembler().assembleDetailed(
        character: character.copyWith(profile: profile),
        history: [msg(ChatRole.user, '嗨')],
      );

      expect(assembled.messages[0].content, contains('林小雨'));
      expect(assembled.messages[1].content, contains('【角色档案补充设定】'));
      expect(
        assembled.messages[1].content,
        contains('身份：昵称 小雨；年龄 17'),
      );
      expect(
        assembled.messages[1].content,
        contains('外貌：发型 银白长发；瞳色 红瞳'),
      );
      expect(assembled.messages[1].content, isNot(contains('创作者备注')));
      expect(assembled.messages[2].content, contains('【角色卡系统提示】'));
      expect(assembled.messages[3].content, startsWith('现在时间：'));
      expect(assembled.usage.profileTokens, greaterThan(0));
      expect(assembled.usage.cardPromptTokens, greaterThan(0));
      expect(
        assembled.usage.usedTokens,
        greaterThanOrEqualTo(
          assembled.usage.profileTokens + assembled.usage.cardPromptTokens,
        ),
      );
    });

    test('空档案不产生额外 system 消息与用量', () {
      final assembled = PromptAssembler().assembleDetailed(
        character: character,
        history: const [],
      );
      expect(
        assembled.messages.where(
          (m) => m.content.contains('【角色档案补充设定】'),
        ),
        isEmpty,
      );
      expect(assembled.usage.profileTokens, 0);
      expect(assembled.usage.cardPromptTokens, 0);
    });

    test('历史后置指令是世界书 after 之后的最后一条 system', () {
      final lore = LoreEntry(
        id: 'l1',
        characterId: 'c1',
        keys: const ['天台'],
        content: '世界书后置设定',
        position: 'after',
        createdAt: DateTime(2026),
      );
      final assembled = PromptAssembler().assembleDetailed(
        character: character.copyWith(profile: profile),
        history: [msg(ChatRole.user, '嗨')],
        lore: [lore],
      );
      final contents = assembled.messages.map((m) => m.content).toList();
      final loreIndex = contents.indexWhere((c) => c.contains('世界书后置设定'));
      final postIndex = contents.indexWhere((c) => c.contains('【历史后置指令】'));
      expect(loreIndex, greaterThanOrEqualTo(0));
      expect(postIndex, greaterThan(loreIndex));
      expect(assembled.messages.last.content, contains('不要总结'));
      expect(assembled.messages.last.role, 'system');
    });

    test('超长卡内提示保留尾部并限长', () {
      final longSystem = '${List.filled(2500, '甲').join()}尾部指令';
      final longPost = '${List.filled(1500, '乙').join()}尾部要求';
      final withLong = character.copyWith(
        profile: const CharacterProfile().copyWith(
          runConfig: RunConfigProfile(
            systemPrompt: longSystem,
            postHistoryInstructions: longPost,
          ),
        ),
      );
      final assembled = PromptAssembler().assembleDetailed(
        character: withLong,
        history: const [],
      );
      final systemMsg = assembled.messages.singleWhere(
        (m) => m.content.contains('【角色卡系统提示】'),
      );
      expect(systemMsg.content, contains('尾部指令'));
      expect(systemMsg.content.length, lessThan(2100));

      final postMsg = assembled.messages.last;
      expect(postMsg.content, contains('尾部要求'));
      expect(postMsg.content.length, lessThan(1030));
    });

    test('档案块超预算时截断，profileTokens 不超过 300', () {
      final huge = CharacterProfile(
        background: BackgroundProfile(
          origin: List.filled(20000, '很长').join(),
        ),
      );
      final assembled = PromptAssembler().assembleDetailed(
        character: character.copyWith(profile: huge),
        history: const [],
        tokenBudget: 1024,
      );
      expect(assembled.usage.profileTokens, greaterThan(0));
      expect(assembled.usage.profileTokens, lessThanOrEqualTo(300));
    });
  });
}
