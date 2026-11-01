/// 跨会话记忆·双文档摘要：把同角色会话的增量对话浓缩进
/// 「角色记忆」与「角色对用户的了解」两份文档。
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

/// 角色记忆文档字数上限。
const int kMemorySummaryMaxChars = 400;

/// 「角色眼中的用户」画像文档字数上限。
const int kUserSummaryMaxChars = 300;

/// 双文档输出中分隔两部分的独行标记。
const String kUserSectionMarker = '【对用户的了解】';

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
      conversationId,
      memory.updatedAt,
    );
    if (newCount < kMemoryUpdateThreshold) return;

    final conv = await chatRepo.getConversation(conversationId);
    if (conv == null) return;
    final profile =
        await profileRepo.getById(conv.apiProfileId) ??
        await profileRepo.getDefault();
    if (profile == null) return;

    final raw = await _incrementalSince(conversationId, memory.updatedAt);
    if (raw.isEmpty) return;

    // 水位线在调 LLM 之前捕获，成功才写入：期间产生的新消息
    // 留给下一轮摘要，宁可重复不可遗漏。
    final watermark = DateTime.now();
    // 增量 transcript：换日的行带日期前缀，让摘要里的绝对日期有据可依。
    final transcript = StringBuffer();
    int? lastDay;
    for (final m in raw) {
      final t = m.createdAt.toLocal();
      if (lastDay != t.day) {
        transcript.write('【${_pad(t.month)}-${_pad(t.day)}】');
        lastDay = t.day;
      }
      transcript.writeln(
        '${m.role == ChatRole.user ? '用户' : character.name}'
        '：${m.contentWithImageNote}',
      );
    }

    final output = StringBuffer();
    await for (final delta in api.streamChat(
      profile: profile,
      // 推理模型的 reasoning_tokens 计入预算（见 title_generator 注释）：
      // 双文档 + 分节正文 + 推理，400 会被吃光导致空输出，800 留足余量。
      maxTokens: 800,
      messages: [
        const ApiMessage(
          role: 'system',
          content:
              '你是角色的记忆整理器。根据「现有文档」与「新增对话」，'
              '输出更新后的两份文档。输出格式：先写「角色记忆」，然后单独一行'
              '【对用户的了解】，再写「对用户的了解」。'
              '角色记忆：第一人称视角，只保留对后续对话有用的事实、情感进展'
              '与关系变化；用「# 小标题」分成2~4节，每节要点式短句，不超过400字。'
              '对用户的了解：站在角色视角描述对这位用户的认识（对TA的称呼、'
              '喜好、性格印象、习惯、对TA的情绪态度）；同样用「# 小标题」分'
              '2~4节，不超过300字。'
              '对话中出现的事件要在要点里写绝对日期（如「10-29 用户提到考试」），'
              '不要用「刚才」「最近」这类相对时间词。'
              '不要寒暄、不要解释、只输出两份文档正文。',
        ),
        ApiMessage(
          role: 'user',
          content:
              '现有角色记忆：'
              '${memory.summary.trim().isEmpty ? '（暂无）' : memory.summary}\n\n'
              '现有对用户的了解：'
              '${memory.userSummary.trim().isEmpty ? '（暂无）' : memory.userSummary}\n\n'
              '新增对话：\n${transcript.toString().trimRight()}',
        ),
      ],
    )) {
      if (delta.content != null) output.write(delta.content);
    }

    final rawOutput = output.toString().trim();
    if (rawOutput.isEmpty) {
      debugPrint('memory summarizer: empty output, keep old docs');
      return;
    }
    // 解析双文档：以第一个「【对用户的了解】」独行分隔。
    final lines = rawOutput.split('\n');
    var splitIdx = -1;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].trim() == kUserSectionMarker) {
        splitIdx = i;
        break;
      }
    }
    if (splitIdx < 0) {
      debugPrint('memory summarizer: missing section marker, keep old docs');
      return;
    }
    var summary = lines.sublist(0, splitIdx).join('\n').trim();
    var userSummary = lines.sublist(splitIdx + 1).join('\n').trim();
    if (summary.isEmpty || userSummary.isEmpty) {
      debugPrint('memory summarizer: empty half, keep old docs');
      return;
    }
    if (summary.length > kMemorySummaryMaxChars) {
      summary = summary.substring(0, kMemorySummaryMaxChars);
    }
    if (userSummary.length > kUserSummaryMaxChars) {
      userSummary = userSummary.substring(0, kUserSummaryMaxChars);
    }
    await characterRepo.setMemory(
      characterId,
      summary: summary,
      userSummary: userSummary,
      updatedAt: watermark,
    );
  }

  /// 水位线之后的文本完成消息，取最近 [kMemoryInputMaxMessages] 条（时序）。
  Future<List<ChatMessage>> _incrementalSince(
    String conversationId,
    DateTime? since,
  ) async {
    final history = await chatRepo.watchMessages(conversationId).first;
    final done = [
      for (final m in history)
        if (m.status == MessageStatus.done &&
            m.kind == MessageKind.text &&
            m.contentWithImageNote.trim().isNotEmpty &&
            (since == null || m.createdAt.isAfter(since)))
          m,
    ];
    return done.length > kMemoryInputMaxMessages
        ? done.sublist(done.length - kMemoryInputMaxMessages)
        : done;
  }

  static String _pad(int v) => v.toString().padLeft(2, '0');
}
