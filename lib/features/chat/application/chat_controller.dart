/// 聊天页 UI 状态与发送/流式/取消编排。
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/id.dart';
import '../../../core/utils/text.dart';
import '../../../core/utils/time_anchor.dart';
import '../../characters/application/prompt_assembler.dart';
import '../../characters/domain/character.dart';
import '../data/chat_api_client.dart';
import '../domain/models.dart';
import 'emotion_tag_parser.dart';
import 'keyword_emotion_detector.dart';
import 'segment_splitter.dart';
import 'speech_sink.dart' show NoopSpeechSink;

/// 聊天页 UI 状态。
class ChatUiState {
  /// 当前会话；null 表示尚未创建。
  final String? conversationId;

  /// 是否正在流式生成。
  final bool isStreaming;

  /// 流式中消息的 id（用于停止按钮与气泡角标）。
  final String? streamingMessageId;

  /// 最近一次错误（面向用户）。
  final String? errorText;

  const ChatUiState({
    this.conversationId,
    this.isStreaming = false,
    this.streamingMessageId,
    this.errorText,
  });

  ChatUiState copyWith({
    String? conversationId,
    bool? isStreaming,
    String? streamingMessageId,
    String? errorText,
    bool clearError = false,
    bool clearStreaming = false,
  }) => ChatUiState(
    conversationId: conversationId ?? this.conversationId,
    isStreaming: isStreaming ?? this.isStreaming,
    streamingMessageId: clearStreaming
        ? null
        : (streamingMessageId ?? this.streamingMessageId),
    errorText: clearError ? null : (errorText ?? this.errorText),
  );
}

class ChatController extends Notifier<ChatUiState> {
  CancelToken? _cancelToken;

  /// 发送代次：每次 send / 切换会话递增。旧发送只允许写库，
  /// 不允许再改 UI 状态（避免后台流与新会话互相污染）。
  int _sendSeq = 0;

  /// 流式解析出的情绪/动作事件（桌宠编排器订阅）。
  final _emotionEvents = StreamController<EmotionEvent>.broadcast();

  Stream<EmotionEvent> get emotionEvents => _emotionEvents.stream;

  @override
  ChatUiState build() {
    ref.onDispose(_emotionEvents.close);
    return const ChatUiState();
  }

  /// 绑定/切换当前会话；传 null 表示新会话（清空绑定）。
  ///
  /// 切换时若仍在流式生成，先取消旧流（旧流的本地缓冲会照常
  /// 落库为半截消息，只是不再更新 UI 状态）。
  void bindConversation(String? conversationId) {
    if (state.isStreaming) _cancelToken?.cancel('切换会话');
    _sendSeq++;
    state = ChatUiState(conversationId: conversationId);
  }

  /// 发送用户消息（可附图）并流式生成回复。
  ///
  /// 若尚未创建会话，先用默认 API 配置创建。
  Future<void> send(String text, {List<Uint8List> images = const []}) async {
    final trimmed = text.trim();
    if ((trimmed.isEmpty && images.isEmpty) || state.isStreaming) return;

    final seq = ++_sendSeq;
    final chatRepo = ref.read(chatRepositoryProvider);
    final profileRepo = ref.read(apiProfileRepositoryProvider);
    final api = ref.read(chatApiClientProvider);
    final realSink = ref.read(speechSinkProvider);

    if (_sendSeq == seq) state = state.copyWith(clearError: true);

    // 1. 确保会话存在。
    var conversationId = state.conversationId;
    if (conversationId == null) {
      final profile = await profileRepo.getDefault();
      if (profile == null) {
        if (_sendSeq == seq) {
          state = state.copyWith(errorText: '请先在设置中添加 API 供应商配置');
        }
        return;
      }
      final conv = await chatRepo.createConversation(apiProfileId: profile.id);
      conversationId = conv.id;
      if (_sendSeq == seq) {
        state = state.copyWith(conversationId: conversationId);
      }
    }
    // 只读副本：供下方各闭包稳定引用会话 id。
    final String activeConvId = conversationId;

    // 2. 入库用户消息（附图先落盘，路径随消息行保存）。
    final userMsgId = newId();
    final attached = images.take(kMaxImagesPerMessage).toList();
    final imagePaths = attached.isEmpty
        ? const <String>[]
        : await chatRepo.saveMessageImages(userMsgId, attached);
    final userMsg = await chatRepo.insertMessage(
      id: userMsgId,
      conversationId: activeConvId,
      role: ChatRole.user,
      content: trimmed,
      rawContent: trimmed,
      imagePaths: imagePaths,
    );

    // 首条用户消息即时截取标题（所有会话生效，含角色会话）；
    // 首条回复完成后由 TitleGenerator 精炼（fire-and-forget）。
    if (await chatRepo.countUserMessages(activeConvId) == 1) {
      await chatRepo.renameConversation(
        activeConvId,
        titleFrom(trimmed.isEmpty ? '[图片]' : trimmed),
      );
    }

    // 图片概括与回复生成并行（fire-and-forget）：下一次发送时历史
    // 只带概括文本不带原图。
    if (imagePaths.isNotEmpty) {
      unawaited(
        ref
            .read(imageCaptionServiceProvider)
            .maybeCaption(messageId: userMsg.id)
            .catchError((_) {}),
      );
    }

    // 会话级语音开关在本回合开始时取快照（流式中途改开关下一回合生效）；
    // 会话不存在（并发删除）按开处理，与旧版行为一致。
    final conv = await chatRepo.getConversation(activeConvId);
    final sink = (conv?.voiceEnabled ?? true)
        ? realSink
        : const NoopSpeechSink();

    // 3. 助手占位消息。
    final assistant = await chatRepo.insertMessage(
      conversationId: activeConvId,
      role: ChatRole.assistant,
      content: '',
      rawContent: '',
      status: MessageStatus.streaming,
    );

    // 4. 组装请求消息：绑定角色走 PromptAssembler（人设 system + 40 条窗口），
    //    否则保持 M1 的裸历史。角色会话注入跨会话记忆（近期原文+长期摘要，
    //    设置可关）；无角色会话不注入。历史消息只带图片概括文本备注，
    //    当前用户消息在最后显式追加（带图走多模态 parts）。
    final history = await chatRepo.watchMessages(activeConvId).first;
    final Character? character = conv?.characterId == null
        ? null
        : await ref
              .read(characterRepositoryProvider)
              .getById(conv!.characterId!);
    final historyExceptCurrent = history
        .where((m) => m.id != userMsg.id)
        .toList();
    final List<ApiMessage> apiMessages;
    if (character == null) {
      // 裸历史也带时间感知（v8）：当前时间 system + 跨日锚点前缀。
      final msgs = <ApiMessage>[
        ApiMessage(
          role: 'system',
          content: '现在时间：${formatCurrentTime(DateTime.now())}',
        ),
      ];
      DateTime? prevTs;
      for (final m in historyExceptCurrent) {
        if (m.id == assistant.id ||
            m.status != MessageStatus.done ||
            m.kind != MessageKind.text) {
          continue;
        }
        var content = stripTagMarkup(m.contentWithImageNote);
        if (content.trim().isEmpty) continue;
        if (prevTs != null &&
            m.createdAt.difference(prevTs) >= kTimeAnchorGap) {
          content = '【${timeAnchorLabel(DateTime.now(), m.createdAt)}】$content';
        }
        prevTs = m.createdAt;
        msgs.add(ApiMessage(role: m.role.wire, content: content));
      }
      apiMessages = msgs;
    } else {
      var memorySummary = '';
      var userSummary = '';
      var pastTranscript = const <ChatMessage>[];
      if (await ref.read(appSettingsRepositoryProvider).memoryEnabled()) {
        final memory = await ref
            .read(characterRepositoryProvider)
            .getMemory(character.id);
        memorySummary = memory.summary;
        userSummary = memory.userSummary;
        pastTranscript = await chatRepo.getRecentOtherMessages(
          characterId: character.id,
          excludeConversationId: activeConvId,
        );
      }
      apiMessages = PromptAssembler().assemble(
        character: character,
        history: historyExceptCurrent,
        memorySummary: memorySummary,
        pastTranscript: pastTranscript,
        userSummary: userSummary,
      );
    }
    apiMessages.add(
      ApiMessage(
        role: 'user',
        content: trimmed,
        images: [for (final b in attached) ApiImage(bytes: b)],
      ),
    );

    // 5. 解析 profile。
    final profile =
        await profileRepo.getById(conv?.apiProfileId ?? '') ??
        await profileRepo.getDefault();
    if (profile == null) {
      await chatRepo.updateMessage(
        assistant.id,
        content: '（未配置 API 供应商）',
        status: MessageStatus.error,
      );
      if (_sendSeq == seq) {
        state = state.copyWith(
          errorText: '请先在设置中添加 API 供应商配置',
          clearStreaming: true,
        );
      }
      return;
    }

    // 6. 流式消费（多段，v8）：`[P]` 独行分隔符把一轮回复切成最多
    //    SegmentSplitter.maxSegments 段，每段独立落一行消息。缓冲区
    //    随段整体换新；过期落盘定时器用 identical 快照检查丢弃。
    //    绑定角色时增量剥离情绪/动作标签。
    final splitter = SegmentSplitter();
    var contentBuf = StringBuffer();
    var rawBuf = StringBuffer();
    // 标签剥离对所有会话生效（v8.1）：无角色会话同样可能吐出
    // <action:x> 之类的标记，漏到气泡里就是可见脏文本。
    final parser = EmotionTagParser();
    final keywordDetector = character == null
        ? null
        : const KeywordEmotionDetector();
    // 段级事件写入本段消息行；轮级累计供表情包选型（取最后情绪）。
    var segEvents = <EmotionEvent>[];
    final turnEvents = <EmotionEvent>[];
    var segId = assistant.id;

    /// 本轮产生的文本消息条数（含占位）。只有 1 条时才做兜底补切。
    var segmentCount = 1;

    // 关键词通道的跨 delta 状态：尾部重叠窗口（防触发词被 chunk 切开
    // 漏检）+ 同情绪短冷却（防密集情绪词反复触发、反复续期表情复位计时）。
    // 轮级状态，跨段持续。
    const keywordTailSize = 8;
    const keywordCooldown = Duration(seconds: 4);
    var keywordTail = '';
    final lastKeywordFired = <String, DateTime>{};

    void fireKeywordEvents(String flushedText) {
      final detector = keywordDetector;
      if (detector == null || flushedText.isEmpty) return;
      final hits = detector.detect(keywordTail + flushedText);
      final now = DateTime.now();
      for (final e in hits) {
        final last = lastKeywordFired[e.value];
        if (last != null && now.difference(last) < keywordCooldown) {
          continue; // 冷却中。
        }
        lastKeywordFired[e.value] = now;
        turnEvents.add(e);
        _emotionEvents.add(e);
      }
      // 保留尾部字符作为下一段的前缀窗口。
      final combined = keywordTail + flushedText;
      keywordTail = combined.length > keywordTailSize
          ? combined.substring(combined.length - keywordTailSize)
          : combined;
    }

    Timer? flushTimer;

    void scheduleFlush() {
      if (flushTimer?.isActive ?? false) return;
      final msgId = segId;
      final cBuf = contentBuf;
      final rBuf = rawBuf;
      flushTimer = Timer(const Duration(milliseconds: 120), () async {
        if (!identical(cBuf, contentBuf)) return; // 段已切换，丢弃过期落盘。
        final repo = ref.read(chatRepositoryProvider);
        await repo.updateMessage(
          msgId,
          content: cBuf.toString(),
          rawContent: rBuf.toString(),
        );
      });
    }

    Future<void> finalizeSegment(MessageStatus status) async {
      flushTimer?.cancel();
      // 把滞留的半个标签按普通文本吐出，保证内容不丢。
      final pending = parser.flush();
      if (pending.isNotEmpty) contentBuf.write(pending);
      final repo = ref.read(chatRepositoryProvider);
      await repo.updateMessage(
        segId,
        content: contentBuf.toString(),
        rawContent: rawBuf.toString(),
        emotionEvents: EmotionTagParser.encodeEvents(segEvents),
        status: status,
      );
    }

    /// 消费一段已被分段器确认安全的原始文本（标签剥离 + 关键词兜底 +
    /// 语音出口 + 落盘调度）。
    Future<void> ingest(String raw) async {
      rawBuf.write(raw);
      final r = parser.feed(raw);
      final cleanDelta = r.flushed;
      contentBuf.write(r.flushed);
      // 标签是精确通道；本段没有标签时用关键词兜底探测情绪，
      // 让「文字里出现生气等字眼」也能驱动桌宠表情。
      segEvents.addAll(r.events);
      turnEvents.addAll(r.events);
      for (final e in r.events) {
        _emotionEvents.add(e);
      }
      if (r.events.isEmpty) {
        fireKeywordEvents(r.flushed);
      }
      // 语音出口：干净文本增量（内部句切分+朗读，按开关自判断）。
      if (cleanDelta.isNotEmpty) {
        await sink.onAssistantDelta(cleanDelta);
      }
      scheduleFlush();
    }

    /// `[P]` 边界：非空段落 done + 重置 TTS 分句 + 开新占位行；
    /// 空段（纯标签/纯空白）直接重置缓冲，复用当前占位，不留空泡。
    Future<void> endSegmentAtBoundary() async {
      if (contentBuf.toString().trim().isEmpty) {
        flushTimer?.cancel();
        parser.flush(); // 丢弃滞留（属上一空段）。
        contentBuf = StringBuffer();
        rawBuf = StringBuffer();
        segEvents = <EmotionEvent>[];
        return;
      }
      await finalizeSegment(MessageStatus.done);
      await sink.onAssistantDone();
      final next = await chatRepo.insertMessage(
        conversationId: activeConvId,
        role: ChatRole.assistant,
        content: '',
        rawContent: '',
        status: MessageStatus.streaming,
      );
      segId = next.id;
      segmentCount++;
      contentBuf = StringBuffer();
      rawBuf = StringBuffer();
      segEvents = <EmotionEvent>[];
      if (_sendSeq == seq) {
        state = state.copyWith(streamingMessageId: next.id);
      }
    }

    final cancelToken = CancelToken();
    _cancelToken = cancelToken;
    if (_sendSeq == seq) {
      state = state.copyWith(isStreaming: true, streamingMessageId: segId);
    }

    try {
      final stream = api.streamChat(
        profile: profile,
        messages: apiMessages,
        cancelToken: cancelToken,
      );
      await for (final delta in stream) {
        if (delta.content == null) {
          continue;
        }
        // 分段检测先行（行制），文本片段再进情绪标签解析。
        for (final ev in splitter.feed(delta.content!)) {
          if (ev.isBoundary) {
            await endSegmentAtBoundary();
          } else {
            await ingest(ev.text!);
          }
        }
      }
      // 尾行：孤悬 [P] 已被丢弃，其余按普通文本进当前段。
      final tail = splitter.flush();
      if (tail.isNotEmpty) await ingest(tail);
      await finalizeSegment(MessageStatus.done);
      await sink.onAssistantDone();

      // 兜底分段（v8.3 真机）：提示词已要求 `[P]` 分段，但模型经常无视，
      // 整轮仍是一大段。本轮只落了一条文本消息时，按空行/句子补切成
      // 多条短消息——不依赖模型自觉，用户侧一定看到"像真人打字"的节奏。
      if (segmentCount == 1) {
        final parts = splitLongReply(contentBuf.toString());
        if (parts.length > 1) {
          await chatRepo.updateMessage(segId, content: parts.first);
          final base = DateTime.now();
          for (var i = 1; i < parts.length; i++) {
            await chatRepo.insertMessage(
              conversationId: activeConvId,
              role: ChatRole.assistant,
              content: parts[i],
              rawContent: parts[i],
              createdAt: base.add(Duration(milliseconds: i)),
            );
          }
        }
      }
      // 成功回合后尝试更新跨会话记忆（fire-and-forget，内部自兜底；
      // 只在 done 路径触发——error/中断的半截消息不值得摘要）。
      if (character != null) {
        unawaited(
          ref
              .read(memorySummarizerProvider)
              .maybeUpdateMemory(
                conversationId: activeConvId,
                characterId: character.id,
              )
              .catchError((_) {}),
        );
      }
      // 首条回复完成后精炼会话标题（同样只在 done 路径触发）。
      unawaited(
        ref
            .read(titleGeneratorProvider)
            .maybeRefine(conversationId: activeConvId)
            .catchError((_) {}),
      );
      // 表情包（v8）：取本轮最后一个情绪事件（动作事件不触发），
      // 稍候作为独立 assistant 纯图消息跟在回复文本之后发送。
      EmotionEvent? lastEmotion;
      for (final e in turnEvents) {
        if (e.kind == 'emotion') lastEmotion = e;
      }
      final emotion = lastEmotion;
      final charId = character?.id;
      if (emotion != null && charId != null) {
        unawaited(
          (() async {
            await Future<void>.delayed(const Duration(milliseconds: 500));
            if (cancelToken.isCancelled) return;
            final path = await ref
                .read(stickerRepositoryProvider)
                .pickForMood(charId, emotion.value);
            if (path == null) return;
            await chatRepo.insertMessage(
              conversationId: activeConvId,
              role: ChatRole.assistant,
              imagePaths: [path],
              imageSummary: '表情包',
              kind: MessageKind.sticker,
            );
          })().catchError((_) {}),
        );
      }
    } on CancelledException {
      if (contentBuf.toString().trim().isEmpty &&
          rawBuf.toString().trim().isEmpty) {
        // 当前段无任何内容：删占位（首轮即整轮空 = 不留消息行）。
        flushTimer?.cancel();
        await chatRepo.deleteMessage(segId);
      } else {
        // 用户主动停止：保留已生成部分（已完成的历史段不动）。
        await finalizeSegment(MessageStatus.done);
      }
      await sink.onAssistantInterrupted();
    } on AppException catch (e) {
      await finalizeSegment(MessageStatus.error);
      await sink.onAssistantInterrupted();
      if (_sendSeq == seq) state = state.copyWith(errorText: e.message);
    } catch (e) {
      await finalizeSegment(MessageStatus.error);
      await sink.onAssistantInterrupted();
      if (_sendSeq == seq) state = state.copyWith(errorText: '生成失败：$e');
    } finally {
      if (_cancelToken == cancelToken) _cancelToken = null;
      if (_sendSeq == seq) {
        state = state.copyWith(isStreaming: false, clearStreaming: true);
      }
    }
  }

  /// 停止生成（保留已生成部分）。
  void stop() {
    _cancelToken?.cancel('用户停止');
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
