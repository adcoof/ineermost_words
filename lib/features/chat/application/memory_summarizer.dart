/// 跨会话记忆 v2（v1.4 M3）：多会话增量 → 「近期记忆 + 长期事实 + 用户画像」。
///
/// 与旧实现的差异：
/// - 水位线按「角色 + 会话」独立（`memory_cursors`），切换会话不丢消息；
/// - 一次整理可聚合最近 4 个会话（每会话最多 80 条），不再只读当前会话；
/// - 输出容忍 `#`/`**`/`【】` 包裹的标记，缺某段只保留该段旧值；
/// - 超长按节/句截断，不劈开半句；
/// - 同一请求顺便抽取「事实 + 发生日期」，细节过期后事实仍在。
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show debugPrint;

import '../../characters/data/character_repository.dart';
import '../../characters/domain/memory_fact.dart';
import '../../settings/data/api_profile_repository.dart';
import '../data/chat_api_client.dart';
import '../data/chat_repository.dart';
import '../domain/models.dart';

/// 新增完成消息总数达到该值才触发摘要。
const int kMemoryUpdateThreshold = 6;

/// 单次摘要输入的增量消息条数上限。
const int kMemoryInputMaxMessages = 80;

/// 近期记忆（`memory_summary`）字数上限。
const int kMemorySummaryMaxChars = 800;

/// 「角色眼中的用户」画像字数上限。
const int kUserSummaryMaxChars = 500;

/// 近期细节只保留最近 N 天，更早的只留事实。
const int kRecentMemoryDays = 3;

/// 双文档输出中分隔两部分的独行标记（旧格式兼容）。
const String kUserSectionMarker = '【对用户的了解】';

/// 记忆整理失败/并发时最多补跑一次。
const int _kMaxRetry = 1;

class MemorySummarizer {
  final ChatRepository chatRepo;
  final CharacterRepository characterRepo;
  final ApiProfileRepository profileRepo;
  final ChatApiClient api;

  /// 进行中的 characterId。
  final Set<String> _inFlight = {};

  /// 并发/失败后的补跑请求。
  final Set<String> _pending = {};

  /// 每个角色已补跑次数（防死循环）。
  final Map<String, int> _retryCounts = {};

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
    if (!_inFlight.add(characterId)) {
      _pending.add(characterId);
      return;
    }
    var failed = false;
    try {
      await _run(conversationId: conversationId, characterId: characterId);
    } catch (e) {
      failed = true;
      // 失败零副作用：旧记忆、旧游标原样保留，补跑一次。
      debugPrint('memory summarizer: $e');
    } finally {
      _inFlight.remove(characterId);
      final wantsRetry = _pending.remove(characterId) || failed;
      final retries = _retryCounts[characterId] ?? 0;
      if (wantsRetry && retries < _kMaxRetry) {
        _retryCounts[characterId] = retries + 1;
        // 等待补跑结束，避免调用方（尤其是测试/DB 生命周期）提前收尾。
        await maybeUpdateMemory(
          conversationId: conversationId,
          characterId: characterId,
        );
      } else {
        _retryCounts.remove(characterId);
      }
    }
  }

  Future<void> _run({
    required String conversationId,
    required String characterId,
  }) async {
    final character = await characterRepo.getById(characterId);
    if (character == null) return; // 角色已删。

    final conv = await chatRepo.getConversation(conversationId);
    if (conv == null) return;

    final memory = await characterRepo.getMemory(characterId);
    final cursors = await characterRepo.getMemoryCursors(characterId);
    final conversations = await chatRepo.getConversationsForCharacter(
      characterId,
      limit: 8,
    );
    if (conversations.isEmpty) return;

    final pending = <({Conversation conversation, List<ChatMessage> messages})>[];
    var total = 0;
    for (final c in conversations) {
      final msgs = await chatRepo.getDoneMessagesAfter(
        c.id,
        cursors[c.id],
        limit: kMemoryInputMaxMessages,
      );
      if (msgs.isEmpty) continue;
      pending.add((conversation: c, messages: msgs));
      total += msgs.length;
    }
    if (total < kMemoryUpdateThreshold) return;

    // 最近活跃的 4 个会话；每组均分 80 条配额，组内取最新。
    pending.sort(
      (a, b) => b.conversation.updatedAt.compareTo(a.conversation.updatedAt),
    );
    final groups = pending.take(4).toList();
    final quota = math.max(4, kMemoryInputMaxMessages ~/ groups.length);
    final merged = <ChatMessage>[];
    for (final g in groups) {
      final start = math.max(0, g.messages.length - quota);
      merged.addAll(g.messages.sublist(start));
    }
    merged.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final raw = merged.length > kMemoryInputMaxMessages
        ? merged.sublist(merged.length - kMemoryInputMaxMessages)
        : merged;
    if (raw.isEmpty) return;

    final profile =
        await profileRepo.getById(conv.apiProfileId) ??
        await profileRepo.getDefault();
    if (profile == null) return;

    final facts = await characterRepo.getMemoryFacts(characterId);
    final watermark = DateTime.now(); // 调 LLM 前捕获，成功才推进。
    final transcript = _buildTranscript(groups, raw, character.name);

    final output = StringBuffer();
    await for (final delta in api.streamChat(
      profile: profile,
      // 推理 token 计入预算（见 title_generator 注释）：三段文档 + 推理，
      // 800 会被吃光，2048 留足正文。
      maxTokens: 2048,
      messages: [
        const ApiMessage(
          role: 'system',
          content:
              '你是角色的记忆整理器。根据「现有近期记忆」「现有长期事实」'
              '「现有对用户的了解」和「新增对话」，输出更新后的三段内容。\n'
              '输出格式：三个标记各占一行，顺序固定，标记行本身不要加粗、'
              '不要加代码块，不要解释：\n'
              '## 近期\n'
              '最近 3 天内的细节，逐行以【MM-DD】开头（如【11-23】用户去关山游玩）；'
              '超过 3 天的条目删除，只保留最近 3 天。\n'
              '## 新事实\n'
              '每行 [YYYY-MM-DD] 一句事实，一事一条，不超过 40 字；'
              '只写发生了什么，不写过程细节。日期用对话中的绝对日期，'
              '不要用整理当天日期。新增对话里的每个事件，都必须同时出现在'
              '「近期」和「新事实」中，这样 3 天后删细节也不会丢事实。\n'
              '## 对用户的了解\n'
              '站在角色视角描述对这位用户的认识（称呼、喜好、性格印象、'
              '习惯、情绪态度），沿用现有小标题。\n'
              '总长不超过 1200 字；不要寒暄、不要解释、只输出三段正文。',
        ),
        ApiMessage(
          role: 'user',
          content:
              '现有近期记忆：'
              '${memory.summary.trim().isEmpty ? '（暂无）' : memory.summary}\n\n'
              '现有长期事实：\n'
              '${facts.isEmpty ? '（暂无）' : facts.take(60).map((f) => '[${_ymd(f.occurredAt)}] ${f.fact}').join('\n')}\n\n'
              '现有对用户的了解：'
              '${memory.userSummary.trim().isEmpty ? '（暂无）' : memory.userSummary}\n\n'
              '新增对话：\n$transcript',
        ),
      ],
    )) {
      if (delta.content != null) output.write(delta.content);
    }

    final rawOutput = output.toString().trim();
    if (rawOutput.isEmpty) {
      debugPrint('memory summarizer: empty output, keep old docs');
      _pending.add(characterId);
      return;
    }

    // 安全兜底：模型/网关偶发返回英文拒绝或非中文错误串（例如
    // "The request was rejected because it was considered high risk"）。
    // 这类文本没有分节标记，若按「缺标记整段当记忆」处理会直接覆盖旧记忆。
    if (!_hasSectionMarker(rawOutput) &&
        (_looksLikeRejection(rawOutput) || !_containsCjk(rawOutput))) {
      debugPrint(
        'memory summarizer: non-summary output, keep old docs: '
        '${rawOutput.length > 120 ? '${rawOutput.substring(0, 120)}…' : rawOutput}',
      );
      return;
    }

    final parsed = _parseSections(rawOutput);
    final recent = _truncateDoc(
      parsed.recent?.trim().isNotEmpty == true
          ? parsed.recent!.trim()
          : memory.summary,
      kMemorySummaryMaxChars,
    );
    final userSummary = _truncateDoc(
      parsed.user?.trim().isNotEmpty == true
          ? parsed.user!.trim()
          : memory.userSummary,
      kUserSummaryMaxChars,
    );
    if (recent.isEmpty && userSummary.isEmpty) {
      debugPrint('memory summarizer: no usable section, keep old docs');
      _pending.add(characterId);
      return;
    }

    // 事实：解析 → 归一化 → 完全匹配/二元组相似度去重 → 入库；失败不影响
    // 摘要落库，但游标仍只在整轮成功后推进。
    final fallbackDate = raw.last.createdAt;
    final factLines = (parsed.facts ?? '').split('\n');
    final existing = [...facts];
    for (final line in factLines) {
      final item = _parseFactLine(line, fallbackDate);
      if (item == null) continue;
      if (_isDuplicate(item.fact, existing)) continue;
      final saved = await characterRepo.addMemoryFact(
        characterId: characterId,
        fact: item.fact,
        occurredAt: item.occurredAt,
        sourceConversationId: raw.last.conversationId,
      );
      existing.insert(0, saved);
    }

    await characterRepo.setMemory(
      characterId,
      summary: recent,
      userSummary: userSummary,
      updatedAt: watermark,
    );

    // 只推进真正纳入本次输入的会话；被配额挤掉的更早消息不补
    //（方案 C2 明示：不做全量归档）。
    final included = raw.map((m) => m.conversationId).toSet();
    for (final g in groups) {
      if (!included.contains(g.conversation.id)) continue;
      await characterRepo.setMemoryCursor(
        characterId,
        g.conversation.id,
        watermark,
      );
    }
  }

  String _buildTranscript(
    List<({Conversation conversation, List<ChatMessage> messages})> groups,
    List<ChatMessage> raw,
    String characterName,
  ) {
    final byConv = <String, List<ChatMessage>>{};
    for (final m in raw) {
      byConv.putIfAbsent(m.conversationId, () => []).add(m);
    }
    final sb = StringBuffer();
    for (final g in groups) {
      final msgs = byConv[g.conversation.id];
      if (msgs == null || msgs.isEmpty) continue;
      final title = g.conversation.title.trim().isEmpty
          ? '未命名会话'
          : g.conversation.title.trim();
      sb.writeln('【会话：$title】');
      for (final m in msgs) {
        final text = m.contentWithImageNote;
        // 纯图消息若附图文件已不可用，仍保留图片摘要文本。
        final rendered =
            text.trim().isEmpty && m.imageSummary.trim().isNotEmpty
            ? '[图片：${m.imageSummary.trim()}]'
            : text;
        sb.writeln(
          '【${_md(m.createdAt)}】【${m.role == ChatRole.user ? '用户' : characterName}】'
          '$rendered',
        );
      }
      sb.writeln();
    }
    return sb.toString().trimRight();
  }

  /// 容忍 `## 近期`、`**【对用户的了解】**`、`【对用户的了解】` 等写法。
  bool _hasSectionMarker(String raw) {
    return raw.split('\n').any((line) => _sectionKey(line) != null);
  }

  bool _containsCjk(String text) =>
      RegExp(r'[\u4e00-\u9fff]').hasMatch(text);

  bool _looksLikeRejection(String text) {
    final lower = text.toLowerCase();
    const needles = [
      'rejected',
      'high risk',
      'cannot assist',
      "can't assist",
      'unable to comply',
      'i cannot',
      "i can't",
    ];
    if (needles.any(lower.contains)) return true;
    return RegExp(r'^\s*(抱歉|对不起|我无法|无法协助|不能协助)').hasMatch(text);
  }

  ({String? recent, String? facts, String? user}) _parseSections(String raw) {
    final lines = raw
        .replaceAll(RegExp(r'```[a-zA-Z]*'), '')
        .replaceAll('```', '')
        .split('\n');
    final buffers = <String, StringBuffer>{
      'recent': StringBuffer(),
      'facts': StringBuffer(),
      'user': StringBuffer(),
    };
    final preamble = StringBuffer();
    String? current;
    var sawMarker = false;
    for (final line in lines) {
      final key = _sectionKey(line);
      if (key != null) {
        sawMarker = true;
        current = key;
        continue;
      }
      if (!sawMarker) {
        preamble.writeln(line);
      } else if (current != null) {
        buffers[current]!.writeln(line);
      }
    }
    var recent = buffers['recent']!.toString().trim();
    if (recent.isEmpty) recent = preamble.toString().trim();
    return (
      recent: recent,
      facts: buffers['facts']!.toString().trim(),
      user: buffers['user']!.toString().trim(),
    );
  }

  String? _sectionKey(String line) {
    final text = line.trim();
    if (text.isEmpty) return null;
    final norm = text.replaceAll(RegExp(r'[#*_`~\[\]【】\s]'), '');
    if (norm.isEmpty || norm.length > 16) return null;
    if (norm.contains('对用户的了解') || norm.contains('TA眼中的你')) {
      return 'user';
    }
    if (norm.contains('新事实') || norm == '事实') return 'facts';
    if (norm.contains('近期')) return 'recent';
    return null;
  }

  ({String fact, DateTime occurredAt})? _parseFactLine(
    String line,
    DateTime fallbackDate,
  ) {
    var text = line.trim();
    if (text.isEmpty || text.startsWith('```')) return null;
    text = text.replaceFirst(RegExp(r'^[-*•]\s*'), '');
    final match = RegExp(
      r'^[\[\【]\s*(\d{2,4})-(\d{1,2})-(\d{1,2})\s*[\]\】]\s*(.+)$',
    ).firstMatch(text);
    DateTime occurredAt;
    String fact;
    if (match != null) {
      var year = int.parse(match.group(1)!);
      if (year < 100) year += 2000;
      final month = int.parse(match.group(2)!).clamp(1, 12);
      final day = int.parse(match.group(3)!).clamp(1, 31);
      occurredAt = DateTime(year, month, day);
      fact = match.group(4)!.trim();
    } else {
      final d = fallbackDate.toLocal();
      occurredAt = DateTime(d.year, d.month, d.day);
      fact = text;
    }
    if (fact.isEmpty) return null;
    if (fact.runes.length > 40) {
      fact = String.fromCharCodes(fact.runes.take(40));
    }
    return (fact: fact, occurredAt: occurredAt);
  }

  bool _isDuplicate(String candidate, List<MemoryFact> existing) {
    final c = _normalizeFact(candidate);
    if (c.isEmpty) return true;
    for (final f in existing) {
      final e = _normalizeFact(f.fact);
      if (c == e) return true;
      if (_bigramSimilarity(c, e) >= 0.8) return true;
    }
    return false;
  }

  String _normalizeFact(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[\s，。！？、,.!?;；:：""「」『』()（）\[\]【】]'), '');

  double _bigramSimilarity(String a, String b) {
    final ra = a.runes.toList();
    final rb = b.runes.toList();
    if (ra.length < 2 || rb.length < 2) return a == b ? 1 : 0;
    final sa = <String>{
      for (var i = 0; i < ra.length - 1; i++) String.fromCharCodes([ra[i], ra[i + 1]]),
    };
    final sb = <String>{
      for (var i = 0; i < rb.length - 1; i++) String.fromCharCodes([rb[i], rb[i + 1]]),
    };
    final inter = sa.intersection(sb).length;
    final union = sa.union(sb).length;
    return union == 0 ? 0 : inter / union;
  }

  /// 按节丢弃、再按句号截断；绝不从半个字/半句中间劈开。
  String _truncateDoc(String doc, int maxChars) {
    final text = doc.trim();
    if (text.isEmpty || text.length <= maxChars) return text;
    final lines = text.split('\n');
    final sections = <List<String>>[];
    var current = <String>[];
    for (final line in lines) {
      final isHeading = line.trim().startsWith('#');
      if (isHeading && current.isNotEmpty) {
        sections.add(current);
        current = <String>[];
      }
      current.add(line);
    }
    if (current.isNotEmpty) sections.add(current);

    final kept = <String>[];
    var used = 0;
    for (final section in sections) {
      final block = section.join('\n').trim();
      if (block.isEmpty) continue;
      final cost = block.length + 1;
      if (kept.isNotEmpty && used + cost > maxChars) break;
      kept.add(block);
      used += cost;
    }
    var out = kept.join('\n').trim();
    if (out.length > maxChars) {
      final cut = out.lastIndexOf(RegExp(r'[。！？\n]'), maxChars);
      out = cut > maxChars ~/ 3
          ? out.substring(0, cut + 1).trim()
          : String.fromCharCodes(out.runes.take(maxChars)).trim();
    }
    return out;
  }

  static String _md(DateTime value) {
    final d = value.toLocal();
    return '${_pad(d.month)}-${_pad(d.day)}';
  }

  static String _ymd(DateTime value) {
    final d = value.toLocal();
    return '${d.year.toString().padLeft(4, '0')}-${_pad(d.month)}-${_pad(d.day)}';
  }

  static String _pad(int v) => v.toString().padLeft(2, '0');
}
