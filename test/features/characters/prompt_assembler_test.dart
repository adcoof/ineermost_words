import 'package:ai_roleplay_chat/features/chat/domain/models.dart';
import 'package:ai_roleplay_chat/features/characters/application/prompt_assembler.dart';
import 'package:ai_roleplay_chat/features/characters/domain/character.dart';
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

    test('超过 40 条只保留最近 40 条且顺序不变', () {
      final history = [
        for (var i = 0; i < 45; i++)
          msg(i.isEven ? ChatRole.user : ChatRole.assistant, '第$i条', minute: i),
      ];
      final messages = PromptAssembler().assemble(
        character: character,
        history: history,
      );
      final window = messages.where((m) => m.role != 'system').toList();
      expect(window.length, PromptAssembler.windowSize);
      expect(window.first.content, '第5条');
      expect(window.last.content, '第44条');
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
}
