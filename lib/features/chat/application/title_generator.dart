/// 会话标题优化器：首条回复完成后用小请求把即时截取标题精炼成短标题。
///
/// 由 ChatController 在每回合成功结束后 fire-and-forget 触发；
/// 仅在「首条用户消息之后的第一条完成回复」时真正调 LLM（一次性）。
/// 失败保留旧标题，绝不向 UI 抛错、绝不阻塞聊天。
library;

import 'package:flutter/foundation.dart' show debugPrint;

import '../../../core/utils/text.dart';
import '../../settings/data/api_profile_repository.dart';
import '../data/chat_api_client.dart';
import '../data/chat_repository.dart';
import '../domain/models.dart';

/// 生成标题字数上限。
const int kTitleMaxRunes = 10;

/// 喂给标题生成器的单段输入截断长度。
const int kTitleInputClip = 200;

class TitleGenerator {
  final ChatRepository chatRepo;
  final ApiProfileRepository profileRepo;
  final ChatApiClient api;

  /// 进行中的会话：并发触发直接跳过后者。
  final Set<String> _inFlight = {};

  /// 流式输出兜底超时：SSE 挂起时不让 _inFlight 永久卡死。
  final Duration streamTimeout;

  TitleGenerator({
    required this.chatRepo,
    required this.profileRepo,
    required this.api,
    this.streamTimeout = const Duration(seconds: 90),
  });

  /// 首条回复完成后后台生成精炼标题；永不抛出、不阻塞调用方。
  Future<void> maybeRefine({required String conversationId}) async {
    if (!_inFlight.add(conversationId)) return;
    try {
      await _run(conversationId);
    } catch (e) {
      // 失败零副作用：保留即时截取的旧标题。
      debugPrint('title generator: $e');
    } finally {
      _inFlight.remove(conversationId);
    }
  }

  Future<void> _run(String conversationId) async {
    final history = await chatRepo.watchMessages(conversationId).first;
    // 一次性触发：会话仍只有首条用户消息、且其后已有 done 非空回复
    //（角色开场白在首条用户消息之前，天然不计数；v8 多段回复 = 多行，
    // 一并取来合并生成）。controller 每轮结束各触发一次，userCount>1
    // 之后本门槛永久关闭。用列表位置而非 createdAt 判定——drift
    // dateTime 秒级精度，时间戳会撞。
    final userMsgs = [
      for (final m in history)
        if (m.role == ChatRole.user) m,
    ];
    if (userMsgs.length != 1) return;
    final firstUserIdx = history.indexOf(userMsgs.single);
    final replies = [
      for (final m in history.skip(firstUserIdx + 1))
        if (m.role == ChatRole.assistant &&
            m.status == MessageStatus.done &&
            m.content.trim().isNotEmpty)
          m,
    ];
    if (replies.isEmpty) return;

    final conv = await chatRepo.getConversation(conversationId);
    if (conv == null) return;
    final profile =
        await profileRepo.getById(conv.apiProfileId) ??
        await profileRepo.getDefault();
    if (profile == null) return;

    final userText = history[firstUserIdx].content.trim();
    final replyText =
        replies.map((m) => m.content.trim()).join('\n').trim();
    if (userText.isEmpty && replyText.isEmpty) return;

    final stream = api
        .streamChat(
          profile: profile,
          // 推理模型（mimo-v2.6-flash）的 reasoning_tokens 计入 max_tokens 预算，
          // 且推理长度随机：同一提示词实测 28~130+ token，enable_thinking:false
          // 并不生效。预算不足会在正文开始前 length 截断 → content 恒空 →
          // 静默保留旧标题。512 = 实测推理上限的约 4 倍余量 + 标题正文。
          maxTokens: 512,
          messages: [
            const ApiMessage(
              role: 'system',
              content:
                  '你是会话标题生成器。根据「用户的第一条消息」与「助手的第一条回复」'
                  '生成一个概括对话主题的短标题。要求：不超过10个字；只输出标题本身，'
                  '不含引号、不要标点结尾或任何解释。',
            ),
            ApiMessage(
              role: 'user',
              content:
                  '用户的第一条消息：${_clip(userText)}\n'
                  '助手的第一条回复：${_clip(replyText)}',
            ),
          ],
        )
        .timeout(streamTimeout);
    final output = StringBuffer();
    await for (final delta in stream) {
      if (delta.content != null) output.write(delta.content);
    }

    final title = cleanLlmLine(output.toString());
    if (title.isEmpty) {
      // 空输出（推理吃光预算等）保留旧标题，但留下可诊断痕迹。
      debugPrint('title generator: empty output, keep current title');
      return;
    }
    await chatRepo.renameConversation(
      conversationId,
      titleFrom(title, kTitleMaxRunes),
    );
  }

  String _clip(String s) =>
      s.length <= kTitleInputClip ? s : s.substring(0, kTitleInputClip);
}
