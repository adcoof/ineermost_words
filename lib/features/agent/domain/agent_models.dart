/// Agent 模块的领域模型（会话 / 消息）。
library;

import '../../chat/data/chat_api_client.dart';
import 'agent_approval.dart';

/// 一次独立的 Agent 会话（不参与角色聊天与记忆）。
class AgentSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 会话级审批模式；null 表示跟随设置页默认。
  final AgentApprovalMode? approvalMode;

  /// 会话级授权文件夹；null 表示跟随设置页默认。
  final List<AgentGrantedFolder>? grantedFolders;

  const AgentSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.approvalMode,
    this.grantedFolders,
  });
}

/// Agent 消息：user / assistant / tool。
class AgentMessage {
  final String id;
  final String sessionId;
  final String role;
  final String content;
  final List<ApiToolCall> toolCalls;
  final String? toolCallId;
  final String? toolName;
  final String status;
  final DateTime createdAt;

  const AgentMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.toolCalls = const [],
    this.toolCallId,
    this.toolName,
    required this.status,
    required this.createdAt,
  });

  bool get isTool => role == 'tool';
}
