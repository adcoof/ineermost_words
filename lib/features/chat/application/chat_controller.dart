/// 聊天页 UI 状态与发送/流式/取消编排。
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../characters/application/prompt_assembler.dart';
import '../../characters/domain/character.dart';
import '../data/chat_api_client.dart';
import '../domain/models.dart';
import 'emotion_tag_parser.dart';
import 'keyword_emotion_detector.dart';

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
  }) =>
      ChatUiState(
        conversationId: conversationId ?? this.conversationId,
        isStreaming: isStreaming ?? this.isStreaming,
        streamingMessageId:
            clearStreaming ? null : (streamingMessageId ?? this.streamingMessageId),
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

  /// 发送用户消息并流式生成回复。
  ///
  /// 若尚未创建会话，先用默认 API 配置创建。
  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isStreaming) return;

    final seq = ++_sendSeq;
    final chatRepo = ref.read(chatRepositoryProvider);
    final profileRepo = ref.read(apiProfileRepositoryProvider);
    final api = ref.read(chatApiClientProvider);
    final speechSink = ref.read(speechSinkProvider);

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

    // 2. 入库用户消息。
    await chatRepo.insertMessage(
      conversationId: conversationId,
      role: ChatRole.user,
      content: trimmed,
      rawContent: trimmed,
    );

    // 首条消息作为会话标题（按字符截断，避免劈开 emoji 代理对）。
    final conv = await chatRepo.getConversation(conversationId);
    if (conv != null && conv.title == '新会话') {
      await chatRepo.renameConversation(conversationId, _titleFrom(trimmed));
    }

    // 3. 助手占位消息。
    final assistant = await chatRepo.insertMessage(
      conversationId: conversationId,
      role: ChatRole.assistant,
      content: '',
      rawContent: '',
      status: MessageStatus.streaming,
    );

    // 4. 组装请求消息：绑定角色走 PromptAssembler（人设 system + 40 条窗口），
    //    否则保持 M1 的裸历史。
    final history = await chatRepo.watchMessages(conversationId).first;
    final Character? character = conv?.characterId == null
        ? null
        : await ref.read(characterRepositoryProvider).getById(conv!.characterId!);
    final apiMessages = character == null
        ? [
            for (final m in history)
              if (m.id != assistant.id &&
                  m.status == MessageStatus.done &&
                  m.content.trim().isNotEmpty)
                ApiMessage(role: m.role.wire, content: m.content),
          ]
        : PromptAssembler().assemble(character: character, history: history);

    // 5. 解析 profile。
    final profile = await profileRepo.getById(conv?.apiProfileId ?? '') ??
        await profileRepo.getDefault();
    if (profile == null) {
      await chatRepo.updateMessage(assistant.id,
          content: '（未配置 API 供应商）', status: MessageStatus.error);
      if (_sendSeq == seq) {
        state = state.copyWith(
            errorText: '请先在设置中添加 API 供应商配置', clearStreaming: true);
      }
      return;
    }

    // 6. 流式消费。缓冲区是本次 send 的局部状态，旧发送的落库
    //    不会与新发送互相污染；绑定角色时增量剥离情绪/动作标签。
    final contentBuf = StringBuffer();
    final rawBuf = StringBuffer();
    final parser = character == null ? null : EmotionTagParser();
    final keywordDetector =
        character == null ? null : const KeywordEmotionDetector();
    final events = <EmotionEvent>[];

    // 关键词通道的跨 delta 状态：尾部重叠窗口（防触发词被 chunk 切开
    // 漏检）+ 同情绪短冷却（防密集情绪词反复触发、反复续期表情复位计时）。
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
        events.add(e);
        _emotionEvents.add(e);
      }
      // 保留尾部字符作为下一段的前缀窗口。
      final combined = keywordTail + flushedText;
      keywordTail = combined.length > keywordTailSize
          ? combined.substring(combined.length - keywordTailSize)
          : combined;
    }
    Timer? flushTimer;

    void scheduleFlush(String messageId) {
      if (flushTimer?.isActive ?? false) return;
      flushTimer = Timer(const Duration(milliseconds: 120), () async {
        final repo = ref.read(chatRepositoryProvider);
        await repo.updateMessage(messageId,
            content: contentBuf.toString(), rawContent: rawBuf.toString());
      });
    }

    Future<void> finalize(MessageStatus status) async {
      flushTimer?.cancel();
      // 把滞留的半个标签按普通文本吐出，保证内容不丢。
      final pending = parser?.flush() ?? '';
      if (pending.isNotEmpty) contentBuf.write(pending);
      final repo = ref.read(chatRepositoryProvider);
      await repo.updateMessage(
        assistant.id,
        content: contentBuf.toString(),
        rawContent: rawBuf.toString(),
        emotionEvents: parser == null
            ? null
            : EmotionTagParser.encodeEvents(events),
        status: status,
      );
    }

    final cancelToken = CancelToken();
    _cancelToken = cancelToken;
    if (_sendSeq == seq) {
      state =
          state.copyWith(isStreaming: true, streamingMessageId: assistant.id);
    }

    try {
      final stream = api.streamChat(
        profile: profile,
        messages: apiMessages,
        cancelToken: cancelToken,
      );
      await for (final delta in stream) {
        if (delta.content != null) {
          rawBuf.write(delta.content);
          String cleanDelta = delta.content!;
          if (parser == null) {
            contentBuf.write(delta.content);
          } else {
            final r = parser.feed(delta.content!);
            cleanDelta = r.flushed;
            contentBuf.write(r.flushed);
            // 标签是精确通道；本段没有标签时用关键词兜底探测情绪，
            // 让「文字里出现生气等字眼」也能驱动桌宠表情。
            events.addAll(r.events);
            for (final e in r.events) {
              _emotionEvents.add(e);
            }
            if (r.events.isEmpty) {
              fireKeywordEvents(r.flushed);
            }
          }
          // 语音出口：干净文本增量（内部句切分+朗读，按开关自判断）。
          if (cleanDelta.isNotEmpty) {
            await speechSink.onAssistantDelta(cleanDelta);
          }
          scheduleFlush(assistant.id);
        }
      }
      await finalize(MessageStatus.done);
      await speechSink.onAssistantDone();
    } on CancelledException {
      if (contentBuf.isEmpty && rawBuf.isEmpty) {
        // 首 token 前取消：不留空占位消息。
        flushTimer?.cancel();
        await chatRepo.deleteMessage(assistant.id);
      } else {
        // 用户主动停止：保留已生成部分。
        await finalize(MessageStatus.done);
      }
      await speechSink.onAssistantInterrupted();
    } on AppException catch (e) {
      await finalize(MessageStatus.error);
      await speechSink.onAssistantInterrupted();
      if (_sendSeq == seq) state = state.copyWith(errorText: e.message);
    } catch (e) {
      await finalize(MessageStatus.error);
      await speechSink.onAssistantInterrupted();
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

  /// 按 Unicode 字符截断标题（不劈开代理对），超出部分以 … 结尾。
  static String _titleFrom(String text, [int maxRunes = 20]) {
    final runes = text.runes;
    if (runes.length <= maxRunes) return text;
    final cut = runes.take(maxRunes);
    return '${String.fromCharCodes(cut)}…';
  }
}
