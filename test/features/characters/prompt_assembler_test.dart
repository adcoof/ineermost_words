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
    test('system 顺序：人设 → 场景 → 标签规范 → 对话示例', () {
      final messages = PromptAssembler()
          .assemble(character: character, history: [msg(ChatRole.user, '嗨')]);

      expect(messages.first.role, 'system');
      expect(messages[0].content, contains('林小雨'));
      expect(messages[0].content, contains('银发红瞳'));
      expect(messages[0].content, contains('冷淡毒舌'));
      expect(messages[1].content, startsWith('场景：'));
      expect(messages[2].content, PromptAssembler.tagSpecInstruction);
      expect(messages[3].content, contains('对话示例'));
      expect(messages[3].content, contains('{{char}}'));
    });

    test('场景为空时不产生场景 system 消息', () {
      final bare = character.copyWith(scenario: '');
      final messages = PromptAssembler()
          .assemble(character: bare, history: const []);
      final systems =
          messages.where((m) => m.role == 'system').map((m) => m.content);
      expect(systems.any((s) => s.startsWith('场景：')), isFalse);
      expect(messages.length, 3); // 人设 + 标签规范 + 示例
    });

    test('对话示例只进 system，不重复进历史', () {
      final messages = PromptAssembler()
          .assemble(character: character, history: [msg(ChatRole.user, '嗨')]);
      final nonSystems =
          messages.where((m) => m.role != 'system').toList();
      expect(nonSystems.length, 1);
      expect(nonSystems.single.content, '嗨');
    });

    test('开场白（assistant 消息）保留在历史最前', () {
      final history = [
        msg(ChatRole.assistant, '*靠在栏杆上*……你来干什么？'),
        msg(ChatRole.user, '只是路过'),
      ];
      final messages =
          PromptAssembler().assemble(character: character, history: history);
      final nonSystems =
          messages.where((m) => m.role != 'system').toList();
      expect(nonSystems.first.role, 'assistant');
      expect(nonSystems.first.content, contains('栏杆'));
      expect(nonSystems.last.content, '只是路过');
    });

    test('超过 40 条只保留最近 40 条且顺序不变', () {
      final history = [
        for (var i = 0; i < 45; i++)
          msg(i.isEven ? ChatRole.user : ChatRole.assistant, '第$i条',
              minute: i),
      ];
      final messages =
          PromptAssembler().assemble(character: character, history: history);
      final window =
          messages.where((m) => m.role != 'system').toList();
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
      final messages =
          PromptAssembler().assemble(character: character, history: history);
      final window =
          messages.where((m) => m.role != 'system').toList();
      expect(window.map((m) => m.content), ['正常']);
    });
  });
}
