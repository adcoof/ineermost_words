/// 聊天领域模型：会话与消息。
library;

/// 消息角色。
enum ChatRole {
  user('user'),
  assistant('assistant'),
  system('system');

  final String wire;

  const ChatRole(this.wire);

  static ChatRole fromWire(String value) => ChatRole.values.firstWhere(
        (r) => r.wire == value,
        orElse: () => ChatRole.user,
      );
}

/// 消息状态。
enum MessageStatus {
  streaming('streaming'),
  done('done'),
  error('error');

  final String wire;

  const MessageStatus(this.wire);

  static MessageStatus fromWire(String value) => MessageStatus.values.firstWhere(
        (s) => s.wire == value,
        orElse: () => MessageStatus.done,
      );
}

/// 一条聊天消息。
class ChatMessage {
  final String id;
  final String conversationId;
  final ChatRole role;

  /// 展示/朗读用干净文本。
  final String content;

  /// 原始输出（含情绪标签）。
  final String rawContent;

  /// 情绪/动作事件（JSON 数组原文，M2 起填充）。
  final String emotionEvents;

  final MessageStatus status;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.rawContent,
    required this.emotionEvents,
    required this.status,
    required this.createdAt,
  });

  ChatMessage copyWith({
    String? content,
    String? rawContent,
    String? emotionEvents,
    MessageStatus? status,
  }) =>
      ChatMessage(
        id: id,
        conversationId: conversationId,
        role: role,
        content: content ?? this.content,
        rawContent: rawContent ?? this.rawContent,
        emotionEvents: emotionEvents ?? this.emotionEvents,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}

/// 一个会话。
class Conversation {
  final String id;
  final String title;
  final String? characterId;
  final String? petModelId;
  final String apiProfileId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool archived;

  /// 本会话是否自动朗读（与全局 voice_enabled 相与生效）。
  final bool voiceEnabled;

  const Conversation({
    required this.id,
    required this.title,
    this.characterId,
    this.petModelId,
    required this.apiProfileId,
    required this.createdAt,
    required this.updatedAt,
    required this.archived,
    this.voiceEnabled = true,
  });
}