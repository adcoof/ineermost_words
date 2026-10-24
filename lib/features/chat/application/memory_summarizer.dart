/// 跨会话记忆·长期摘要：把同角色会话的增量对话浓缩进角色记忆。
///
/// 由 ChatController 在每回合成功结束后 fire-and-forget 触发；
/// 达到阈值（水位线后新增 done 消息数）才真正调 LLM。失败保留旧
/// 记忆、不推进水位线，绝不向 UI 抛错、绝不阻塞聊天。
library;

import 'package:flutter/foundation.dart' show debugPrint;

import '../../characters/data/character_repository.dart';
import '../../settings/data/api_profile_repository.dart';
import '../data/chat_api_client.dart';
import '../data/chat_repository.dart';
import '../domain/models.dart';

/// 水位线后新增完成消息数达到该值才触发摘要。
const int kMemoryUpdateThreshold = 6;

/// 摘要输入的增量消息条数上限（防超长会话撑爆上下文）。
const int kMemoryInputMaxMessages = 80;

/// 摘要输出字数上限。
const int kMemorySummaryMaxChars = 300;

class MemorySummarizer {
  final ChatRepository chatRepo;
  final CharacterRepository characterRepo;
  final ApiProfileRepository profileRepo;
  final ChatApiClient api;

  /// 进行中的 characterId：同角色并发触发时直接跳过后者
  ///（下回合阈值仍满足会补做，比排队合并简单且无乱序风险）。
  final Set<String> _inFlight = {};

  MemorySummarizer({
    required this.chatRepo,
    required this.characterRepo,
    required this.profileRepo,
    required this.api,
  });

  /// 满足阈值时后台更新该角色记忆；永不抛出、不阻塞调用方。
  Future<void> maybeUpdateMemory({
    required String conversationId,
    required String characterId,
  }) async {
    if (!_inFlight.add(characterId)) return;
    try {
      await _run(conversationId: conversationId, characterId: characterId);
    } catch (e) {
      // 失败零副作用：旧记忆与水位线原样保留。
      debugPrint('memory summarizer: $e');
    } finally {
      _inFlight.remove(characterId);
    }
  }

  Future<void> _run({
    required String conversationId,
    required String characterId,
  }) async {
    final character = await characterRepo.getById(characterId);
    if (character == null) return; // 角色已删。

    final memory = await characterRepo.getMemory(characterId);
    final newCount = await chatRepo.countDoneMessagesSince(
        conversationId, memory.updatedAt);
    if (newCount < kMemoryUpdateThreshold) return;

    final conv = await chatRepo.getConversation(conversationId);
    if (conv == null) return;
    final profile = await profileRepo.getById(conv.apiProfileId) ??
        await profileRepo.getDefault();
    if (profile == null) return;

    final raw = await _incrementalSince(conversationId, memory.updatedAt);
    if (raw.isEmpty) return;

    // 水位线在调 LLM 之前捕获，成功才写入：期间产生的新消息
    // 留给下一轮摘要，宁可重复不可遗漏。
    final watermark = DateTime.now();
    final transcript = StringBuffer();
    for (final m in raw) {
      transcript.writeln(
          '${m.role == ChatRole.user ? '用户' : character.name}：${m.content}');
    }

    final output = StringBuffer();
    await for (final delta in api.streamChat(
      profile: profile,
      maxTokens: 400,
      messages: [
        const ApiMessage(
          role: 'system',
          content: '你是角色记忆整理器。根据「现有记忆」与「新增对话」，'
              '输出更新后的角色记忆。要求：第一人称视角；只保留对后续对话'
              '有用的事实、情感进展与关系变化；不超过300字；要点式短句，'
              '不要寒暄、不要解释、只输出记忆正文。',
        ),
        ApiMessage(
          role: 'user',
          content: '现有记忆：'
              '${memory.summary.trim().isEmpty ? '（暂无）' : memory.summary}\n\n'
              '新增对话：\n${transcript.toString().trimRight()}',
        ),
      ],
    )) {
      if (delta.content != null) output.write(delta.content);
    }

    var summary = output.toString().trim();
    if (summary.isEmpty) return;
    if (summary.length > kMemorySummaryMaxChars) {
      summary = summary.substring(0, kMemorySummaryMaxChars);
    }
    await characterRepo.setMemory(characterId,
        summary: summary, updatedAt: watermark);
  }

  /// 水位线之后的完成消息，取最近 [kMemoryInputMaxMessages] 条（时序）。
  Future<List<ChatMessage>> _incrementalSince(
      String conversationId, DateTime? since) async {
    final history = await chatRepo.watchMessages(conversationId).first;
    final done = [
      for (final m in history)
        if (m.status == MessageStatus.done &&
            m.content.trim().isNotEmpty &&
            (since == null || m.createdAt.isAfter(since))) m,
    ];
    return done.length > kMemoryInputMaxMessages
        ? done.sublist(done.length - kMemoryInputMaxMessages)
        : done;
  }
}
