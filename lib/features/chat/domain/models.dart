/// 聊天领域模型：会话与消息。
library;

import 'dart:convert';

/// 单条消息附图上限（UI 与发送路径共同强制）。
const int kMaxImagesPerMessage = 9;

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

/// 消息种类（v8）：普通文本 vs 表情包（纯图，不进提示词/记忆/标题）。
enum MessageKind {
  text('text'),
  sticker('sticker');

  final String wire;

  const MessageKind(this.wire);

  static MessageKind fromWire(String value) => MessageKind.values.firstWhere(
        (k) => k.wire == value,
        orElse: () => MessageKind.text,
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

  /// 附图文件绝对路径（JSON 数组原文，v7）。
  final String imagePaths;

  /// 图片内容一句话概括（LLM 生成；失败留空走 [图片] 占位，v7）。
  final String imageSummary;

  final MessageStatus status;

  /// 消息种类（v8）：sticker 为角色自动发送的表情包（纯图）。
  final MessageKind kind;

  /// 当前选中的候选回复 id（v14）；null=正文即唯一候选。
  final String? activeVariantId;

  /// 群聊中这条消息的发言角色 id（v16）；null=单角色会话。
  final String? speakerCharacterId;

  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.rawContent,
    required this.emotionEvents,
    this.imagePaths = '[]',
    this.imageSummary = '',
    required this.status,
    this.kind = MessageKind.text,
    this.activeVariantId,
    this.speakerCharacterId,
    required this.createdAt,
  });

  /// 附图路径列表（JSON 解析失败视作无图）。
  List<String> get imageFilePaths {
    try {
      final decoded = jsonDecode(imagePaths);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {
      // 坏数据不致命，按无图处理。
    }
    return const [];
  }

  /// 历史消息入提示词/记忆用：正文 + 图片备注（摘要缺失走 [图片] 占位）。
  String get contentWithImageNote {
    if (imageFilePaths.isEmpty) return content;
    final s = imageSummary.trim();
    final note = s.isEmpty ? '[图片]' : '[图片：$s]';
    return content.trim().isEmpty ? note : '$content\n$note';
  }

  ChatMessage copyWith({
    String? content,
    String? rawContent,
    String? emotionEvents,
    String? imagePaths,
    String? imageSummary,
    MessageStatus? status,
    MessageKind? kind,
  }) =>
      ChatMessage(
        id: id,
        conversationId: conversationId,
        role: role,
        content: content ?? this.content,
        rawContent: rawContent ?? this.rawContent,
        emotionEvents: emotionEvents ?? this.emotionEvents,
        imagePaths: imagePaths ?? this.imagePaths,
        imageSummary: imageSummary ?? this.imageSummary,
        status: status ?? this.status,
        kind: kind ?? this.kind,
        activeVariantId: activeVariantId,
        speakerCharacterId: speakerCharacterId,
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

  /// 自定义聊天背景板文件绝对路径（v8）；null=默认主题背景。
  final String? backgroundPath;

  /// 分支来源会话 id（v16）；null=非分支会话。
  final String? parentConversationId;

  /// 分支点消息 id（v16）。
  final String? branchFromMessageId;

  /// 群聊：用户发言后是否让全部启用成员依次回复（v19）。
  final bool groupAutoReply;

  /// 群聊：角色之间自动拌嘴的额外轮数（v19，0–3）。
  final int groupBanterRounds;

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
    this.backgroundPath,
    this.parentConversationId,
    this.branchFromMessageId,
    this.groupAutoReply = true,
    this.groupBanterRounds = 2,
  });
}
/// 一条 assistant 消息的候选回复（v14）。
class MessageVariant {
  final String id;
  final String messageId;
  final String content;
  final String rawContent;
  final String emotionEvents;
  final DateTime createdAt;

  const MessageVariant({
    required this.id,
    required this.messageId,
    required this.content,
    required this.rawContent,
    required this.emotionEvents,
    required this.createdAt,
  });
}

/// 群聊会话的参与者（v16）。
class ConversationParticipant {
  final String id;
  final String conversationId;
  final String characterId;
  final int sortOrder;

  /// 是否参与自动轮转；静音成员仍可被强制发言。
  final bool enabled;

  final DateTime createdAt;

  const ConversationParticipant({
    required this.id,
    required this.conversationId,
    required this.characterId,
    required this.sortOrder,
    this.enabled = true,
    required this.createdAt,
  });
}
