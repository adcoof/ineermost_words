/// 聊天页 UI 状态与发送/流式/取消编排。
library;

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/id.dart';
import '../../../core/utils/text.dart';
import '../../../core/utils/token_estimate.dart';
import '../../characters/application/memory_recall.dart';
import '../../characters/application/lore_recall.dart';
import '../../characters/application/prompt_assembler.dart';
import '../../characters/domain/character.dart';
import '../../characters/domain/memory_fact.dart';
import '../../settings/data/api_profile_repository.dart';
import '../../settings/domain/api_profile.dart';
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

  /// 最近一次组装提示词的分类用量（聊天页 chip/sheet）。
  final PromptUsage? contextUsage;

  /// 群聊强制发言：下一条消息由该角色回复；null=按轮转。
  final String? forcedSpeakerId;

  const ChatUiState({
    this.conversationId,
    this.isStreaming = false,
    this.streamingMessageId,
    this.errorText,
    this.contextUsage,
    this.forcedSpeakerId,
  });

  ChatUiState copyWith({
    String? conversationId,
    bool? isStreaming,
    String? streamingMessageId,
    String? errorText,
    PromptUsage? contextUsage,
    String? forcedSpeakerId,
    bool clearError = false,
    bool clearStreaming = false,
    bool clearContextUsage = false,
    bool clearForcedSpeaker = false,
  }) => ChatUiState(
    conversationId: conversationId ?? this.conversationId,
    isStreaming: isStreaming ?? this.isStreaming,
    streamingMessageId: clearStreaming
        ? null
        : (streamingMessageId ?? this.streamingMessageId),
    errorText: clearError ? null : (errorText ?? this.errorText),
    contextUsage: clearContextUsage
        ? null
        : (contextUsage ?? this.contextUsage),
    forcedSpeakerId: clearForcedSpeaker
        ? null
        : (forcedSpeakerId ?? this.forcedSpeakerId),
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

  /// 群聊：让指定成员回复下一条消息；传 null 取消强制。
  void forceSpeaker(String? characterId) {
    state = characterId == null
        ? state.copyWith(clearForcedSpeaker: true)
        : state.copyWith(forcedSpeakerId: characterId);
  }

  /// 打开会话时预计算一次上下文用量（当前输入按 0 计）。
  ///
  /// 与 send 复用同一套组装逻辑；send / 切换会话会递增 [_sendSeq]，
  /// 旧结果直接丢弃，避免覆盖新会话或新回合的用量。
  Future<void> refreshContextUsage({String? conversationId, int? seq}) async {
    final convId = conversationId ?? state.conversationId;
    if (convId == null) return;
    final token = seq ?? _sendSeq;
    try {
      final chatRepo = ref.read(chatRepositoryProvider);
      final conv = await chatRepo.getConversation(convId);
      if (conv == null) return;
      final history = await chatRepo.watchMessages(convId).first;
      final participants = await chatRepo.listParticipants(convId);
      final participantCharacters = <String, Character>{};
      for (final participant in participants) {
        final character = await ref
            .read(characterRepositoryProvider)
            .getById(participant.characterId);
        if (character != null) participantCharacters[character.id] = character;
      }
      final character = await _resolveSpeaker(
        conv: conv,
        history: history,
        participants: participants,
        participantCharacters: participantCharacters,
        forcedSpeakerId: state.forcedSpeakerId,
      );
      final promptHistory = _transformGroupHistory(
        history,
        participants: participants,
        character: character,
        participantCharacters: participantCharacters,
      );
      final assembled = await _assemblePrompt(
        conversationId: convId,
        character: character,
        history: promptHistory,
        currentInput: '',
        reservedTokens: 0,
      );
      if (_sendSeq != token || state.conversationId != convId) return;
      state = state.copyWith(contextUsage: assembled.usage);
    } catch (_) {
      // 预计算失败不影响聊天；chip 保持 --。
    }
  }

  /// 群聊「角色之间对话」：不插入用户消息，按轮转连续生成 [rounds] 条回复。
  ///
  /// 最近一条消息来自其他角色时，[ _transformGroupHistory ] 会把它转成带
  /// 名字的 user 消息；再追加群聊指令，要求当前角色只回应对方。
  Future<void> continueGroup({int rounds = 2}) async {
    if (state.isStreaming) return;
    final conversationId = state.conversationId;
    if (conversationId == null) return;
    final total = rounds.clamp(1, 8).toInt();
    final seq = ++_sendSeq;
    final chatRepo = ref.read(chatRepositoryProvider);
    final api = ref.read(chatApiClientProvider);
    final profileRepo = ref.read(apiProfileRepositoryProvider);

    for (var round = 0; round < total; round++) {
      if (_sendSeq != seq) return;
      final conv = await chatRepo.getConversation(conversationId);
      if (conv == null) return;
      final history = await chatRepo.watchMessages(conversationId).first;
      final participants = await chatRepo.listParticipants(conversationId);
      if (participants.length <= 1) return;
      final participantCharacters = <String, Character>{};
      for (final participant in participants) {
        final character = await ref
            .read(characterRepositoryProvider)
            .getById(participant.characterId);
        if (character != null) participantCharacters[character.id] = character;
      }
      final forced = round == 0 ? state.forcedSpeakerId : null;
      if (forced != null) state = state.copyWith(clearForcedSpeaker: true);
      final character = await _resolveSpeaker(
        conv: conv,
        history: history,
        participants: participants,
        participantCharacters: participantCharacters,
        forcedSpeakerId: forced,
      );
      if (character == null) return;

      final promptHistory = _transformGroupHistory(
        history,
        participants: participants,
        character: character,
        participantCharacters: participantCharacters,
      );
      final assembled = await _assemblePrompt(
        conversationId: conversationId,
        character: character,
        history: promptHistory,
        currentInput: '',
        reservedTokens: 0,
      );
      final lastSpeakerMessages = history.reversed
          .where(
            (m) =>
                m.role == ChatRole.assistant &&
                m.speakerCharacterId != null &&
                participantCharacters.containsKey(m.speakerCharacterId),
          )
          .toList();
      final lastSpeaker = lastSpeakerMessages.isEmpty
          ? null
          : participantCharacters[lastSpeakerMessages.first.speakerCharacterId]
                ?.name;
      final roster = [
        for (final p in participants)
          participantCharacters[p.characterId]?.name ?? '角色',
      ].join('、');
      final instruction =
          '你正在一个多人聊天中。你是【${character.name}】，群成员：$roster。'
          '${lastSpeaker == null ? '' : '最近一条消息来自【$lastSpeaker】。'}'
          '请只以【${character.name}】的身份自然回应对方，推动对话；'
          '不要替其他角色说话，不要复述，不要写旁白总结。';

      String? participantProfileId;
      for (final participant in participants) {
        if (participant.characterId == character.id) {
          participantProfileId = participant.apiProfileId;
          break;
        }
      }
      final profile = await _resolveProfile(
        conversationProfileId: conv.apiProfileId,
        participantProfileId: participantProfileId,
        profileRepo: profileRepo,
      );
      if (profile == null || profile.apiKey.trim().isEmpty) {
        if (_sendSeq == seq) {
          state = state.copyWith(
            errorText: '请先在设置中添加 API 供应商配置',
            clearStreaming: true,
          );
        }
        return;
      }
      if (_sendSeq != seq) return;

      state = state.copyWith(
        isStreaming: true,
        clearError: true,
        contextUsage: assembled.usage,
      );
      final assistant = await chatRepo.insertMessage(
        conversationId: conversationId,
        role: ChatRole.assistant,
        content: '',
        rawContent: '',
        status: MessageStatus.streaming,
        speakerCharacterId: character.id,
      );
      state = state.copyWith(streamingMessageId: assistant.id);

      final cancelToken = CancelToken();
      _cancelToken = cancelToken;
      final raw = StringBuffer();
      var lastFlush = DateTime.fromMillisecondsSinceEpoch(0);
      try {
        final messages = [
          ...assembled.messages,
          ApiMessage(role: 'system', content: instruction),
        ];
        await for (final delta in api.streamChat(
          profile: profile,
          messages: messages,
          cancelToken: cancelToken,
        )) {
          final text = delta.content;
          if (text == null || text.isEmpty) continue;
          raw.write(text);
          final now = DateTime.now();
          if (now.difference(lastFlush) >= const Duration(milliseconds: 150)) {
            lastFlush = now;
            await chatRepo.updateMessage(
              assistant.id,
              content: stripTagMarkup(raw.toString()),
              rawContent: raw.toString(),
            );
          }
        }
        final rawText = raw.toString().trim();
        if (rawText.isEmpty) {
          await chatRepo.deleteMessage(assistant.id);
          if (_sendSeq == seq) {
            state = state.copyWith(
              errorText: '群聊自动回复为空，请重试',
              isStreaming: false,
              clearStreaming: true,
            );
          }
          return;
        }
        final parts = _splitGroupReply(rawText);
        await chatRepo.updateMessage(
          assistant.id,
          content: stripTagMarkup(parts.first),
          rawContent: parts.first,
          status: MessageStatus.done,
        );
        for (var i = 1; i < parts.length; i++) {
          await chatRepo.insertMessage(
            conversationId: conversationId,
            role: ChatRole.assistant,
            content: stripTagMarkup(parts[i]),
            rawContent: parts[i],
            status: MessageStatus.done,
            speakerCharacterId: character.id,
            createdAt: DateTime.now().add(Duration(milliseconds: i)),
          );
        }
        unawaited(
          ref
              .read(memorySummarizerProvider)
              .maybeUpdateMemory(
                conversationId: conversationId,
                characterId: character.id,
              )
              .catchError((_) {}),
        );
      } catch (e) {
        final rawText = raw.toString().trim();
        if (rawText.isEmpty) {
          await chatRepo.deleteMessage(assistant.id);
        } else {
          await chatRepo.updateMessage(
            assistant.id,
            content: stripTagMarkup(rawText),
            rawContent: rawText,
            status: MessageStatus.error,
          );
        }
        if (_sendSeq == seq) {
          state = state.copyWith(
            errorText: e is AppException ? e.message : '群聊自动回复失败：$e',
            isStreaming: false,
            clearStreaming: true,
          );
        }
        return;
      } finally {
        if (identical(_cancelToken, cancelToken)) _cancelToken = null;
        if (_sendSeq == seq) {
          state = state.copyWith(isStreaming: false, clearStreaming: true);
        }
      }
    }
  }

  /// 用户发送成功后：群聊开启「全员回复」时，补齐首轮其余成员并自动拌嘴。
  ///
  /// 首条回复已由 send 生成；这里只补 (启用人数-1) + 拌嘴轮数 条。
  Future<void> maybeAutoContinueGroup() async {
    if (state.isStreaming) return;
    final conversationId = state.conversationId;
    if (conversationId == null) return;
    final chatRepo = ref.read(chatRepositoryProvider);
    final conv = await chatRepo.getConversation(conversationId);
    if (conv == null || !conv.groupAutoReply) return;
    final participants = await chatRepo.listParticipants(conversationId);
    final enabled = participants.where((p) => p.enabled).length;
    if (participants.length <= 1 || enabled <= 0) return;
    final messages = await chatRepo.watchMessages(conversationId).first;
    if (messages.isEmpty) return;
    final last = messages.last;
    if (last.role != ChatRole.assistant || last.status != MessageStatus.done) {
      return;
    }
    final extra = (enabled - 1) + conv.groupBanterRounds.clamp(0, 3);
    if (extra <= 0) return;
    await continueGroup(rounds: extra);
  }

  List<String> _splitGroupReply(String raw) {
    final parts = raw
        .split(RegExp(r'\n\s*\[P\]\s*\n'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .take(4)
        .toList();
    return parts.isEmpty ? [raw] : parts;
  }

  Future<Character?> _resolveSpeaker({
    required Conversation conv,
    required List<ChatMessage> history,
    required List<ConversationParticipant> participants,
    required Map<String, Character> participantCharacters,
    String? forcedSpeakerId,
  }) async {
    // 强制发言优先，且不受静音影响。
    if (forcedSpeakerId != null &&
        participantCharacters.containsKey(forcedSpeakerId)) {
      return participantCharacters[forcedSpeakerId];
    }
    String? speakerId;
    if (participants.isNotEmpty) {
      // 静音成员不参与自动轮转；全部静音时退回全体，避免死锁。
      final enabled = participants.where((p) => p.enabled).toList();
      final pool = enabled.isEmpty ? participants : enabled;
      final reversedAssistants = history.reversed.where(
        (m) =>
            m.role == ChatRole.assistant &&
            m.speakerCharacterId != null &&
            pool.any((p) => p.characterId == m.speakerCharacterId),
      );
      final lastAssistant = reversedAssistants.isEmpty
          ? null
          : reversedAssistants.first;
      final prevIndex = lastAssistant == null
          ? -1
          : pool.indexWhere(
              (p) => p.characterId == lastAssistant.speakerCharacterId,
            );
      final nextIndex = prevIndex < 0 ? 0 : (prevIndex + 1) % pool.length;
      speakerId = pool[nextIndex].characterId;
    }
    if (speakerId != null) return participantCharacters[speakerId];
    final characterId = conv.characterId;
    if (characterId == null) return null;
    return ref.read(characterRepositoryProvider).getById(characterId);
  }

  List<ChatMessage> _transformGroupHistory(
    List<ChatMessage> history, {
    required List<ConversationParticipant> participants,
    required Character? character,
    required Map<String, Character> participantCharacters,
  }) {
    if (participants.length <= 1 || character == null) return history;
    return [
      for (final m in history)
        if (m.role == ChatRole.assistant &&
            m.speakerCharacterId != null &&
            m.speakerCharacterId != character.id)
          ChatMessage(
            id: m.id,
            conversationId: m.conversationId,
            role: ChatRole.user,
            content:
                '【${participantCharacters[m.speakerCharacterId]?.name ?? '角色'}】${m.content}',
            rawContent: m.rawContent,
            emotionEvents: m.emotionEvents,
            imagePaths: m.imagePaths,
            imageSummary: m.imageSummary,
            status: m.status,
            kind: m.kind,
            speakerCharacterId: m.speakerCharacterId,
            createdAt: m.createdAt,
          )
        else
          m,
    ];
  }

  /// 解析某次回复使用的 API 供应商：
  /// 群成员独立供应商 > 会话供应商 > 全局默认。
  Future<ApiProfile?> _resolveProfile({
    required String conversationProfileId,
    String? participantProfileId,
    required ApiProfileRepository profileRepo,
  }) async {
    if (participantProfileId != null && participantProfileId.isNotEmpty) {
      final selected = await profileRepo.getById(participantProfileId);
      if (selected != null && selected.apiKey.trim().isNotEmpty) {
        return selected;
      }
    }
    var profile = conversationProfileId.isEmpty
        ? null
        : await profileRepo.getById(conversationProfileId);
    if (profile == null || profile.apiKey.trim().isEmpty) {
      profile = await profileRepo.getDefault();
    }
    return profile;
  }

  /// 按当前会话/角色/历史组装提示词，返回消息与分类用量。
  ///
  /// [currentInput] 只在 send 时传入；打开会话预计算时传空串。
  Future<({List<ApiMessage> messages, PromptUsage usage})> _assemblePrompt({
    required String conversationId,
    required Character? character,
    required List<ChatMessage> history,
    required String currentInput,
    required int reservedTokens,
  }) async {
    final settings = ref.read(appSettingsRepositoryProvider);
    final windowTokens = await settings.contextWindowTokens();
    final otherTokens = await settings.contextWindowOtherTokens();
    if (character == null) {
      final assembled = PromptAssembler().assembleBare(
        history: history,
        tokenBudget: windowTokens,
        reservedTokens: reservedTokens,
      );
      return (messages: assembled.messages, usage: assembled.usage);
    }

    final chatRepo = ref.read(chatRepositoryProvider);
    var memorySummary = '';
    var userSummary = '';
    final pastSessions = <PastSession>[];
    var facts = const <MemoryFact>[];
    final recallQuery = [
      currentInput,
      ...history.reversed.take(4).map((m) => m.contentWithImageNote),
    ].where((s) => s.trim().isNotEmpty).join('\n');
    if (await settings.memoryEnabled()) {
      final characterRepo = ref.read(characterRepositoryProvider);
      final memory = await characterRepo.getMemory(character.id);
      memorySummary = memory.summary;
      userSummary = memory.userSummary;
      facts = recallMemoryFacts(
        facts: await characterRepo.getMemoryFacts(character.id),
        query: recallQuery,
      );
      // 跨会话片段按会话分组、每会话独立配额，纯图 + 图片摘要也纳入。
      final groups = await chatRepo.getCrossSessionDigest(
        characterId: character.id,
        excludeConversationId: conversationId,
      );
      for (final g in groups) {
        pastSessions.add(
          PastSession(title: g.conversation.title, messages: g.messages),
        );
      }
    }
    final lore = matchLoreEntries(
      entries: await ref
          .read(loreRepositoryProvider)
          .listForCharacter(character.id, enabledOnly: true),
      query: recallQuery,
    );
    final assembled = PromptAssembler().assembleDetailed(
      character: character,
      history: history,
      memorySummary: memorySummary,
      pastSessions: pastSessions,
      facts: facts,
      lore: lore,
      userSummary: userSummary,
      tokenBudget: windowTokens,
      otherTokenBudget: otherTokens,
      reservedTokens: reservedTokens,
    );
    return (messages: assembled.messages, usage: assembled.usage);
  }

  /// 重试上一条失败的用户消息：删除该轮用户消息与其后的错误/空回复，再重新发送。
  ///
  /// 仅在最后一条是未完成的 assistant 消息时执行，避免对已成功回复重复发送。
  Future<void> retryLastTurn() async {
    if (state.isStreaming) return;
    final conversationId = state.conversationId;
    if (conversationId == null) return;
    final chatRepo = ref.read(chatRepositoryProvider);
    final messages = await chatRepo.watchMessages(conversationId).first;
    final userIndex = messages.lastIndexWhere((m) => m.role == ChatRole.user);
    if (userIndex < 0) return;
    final tail = messages.sublist(userIndex);
    final lastAssistant = tail.lastWhere(
      (m) => m.role == ChatRole.assistant,
      orElse: () => tail.first,
    );
    if (lastAssistant.role == ChatRole.assistant &&
        lastAssistant.status == MessageStatus.done) {
      return;
    }
    final user = messages[userIndex];
    for (var i = messages.length - 1; i >= userIndex; i--) {
      await chatRepo.deleteMessage(messages[i].id);
    }
    final images = <Uint8List>[];
    for (final path in user.imageFilePaths) {
      final file = File(path);
      if (await file.exists()) images.add(await file.readAsBytes());
    }
    await send(user.content, images: images);
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

    // 3. 组装请求消息：预算来自设置里的上下文窗口（token 估算）；
    //    当前用户消息永远保留，历史从最新往前按预算取。角色会话注入
    //    跨会话记忆（近期原文+长期摘要，设置可关）；无角色会话只注入
    //    当前时间。历史消息只带图片概括文本备注，当前用户消息在最后
    //    显式追加（带图走多模态 parts）。
    final history = await chatRepo.watchMessages(activeConvId).first;
    final characterRepo = ref.read(characterRepositoryProvider);
    final participants = conv == null
        ? const <ConversationParticipant>[]
        : await chatRepo.listParticipants(activeConvId);
    final participantCharacters = <String, Character>{};
    for (final p in participants) {
      final c = await characterRepo.getById(p.characterId);
      if (c != null) participantCharacters[c.id] = c;
    }
    final forcedSpeakerId = state.forcedSpeakerId;
    if (forcedSpeakerId != null) {
      // 强制只作用于下一轮；先清掉 UI 标记，再解析本轮发言者。
      state = state.copyWith(clearForcedSpeaker: true);
    }
    final Character? character = conv == null
        ? null
        : await _resolveSpeaker(
            conv: conv,
            history: history,
            participants: participants,
            participantCharacters: participantCharacters,
            forcedSpeakerId: forcedSpeakerId,
          );
    final assistant = await chatRepo.insertMessage(
      conversationId: activeConvId,
      role: ChatRole.assistant,
      content: '',
      rawContent: '',
      status: MessageStatus.streaming,
      speakerCharacterId: character?.id,
    );
    final historyExceptCurrent = _transformGroupHistory(
      history.where((m) => m.id != userMsg.id).toList(),
      participants: participants,
      character: character,
      participantCharacters: participantCharacters,
    );
    final reservedTokens = 4 + estimateTokens(trimmed);
    final assembled = await _assemblePrompt(
      conversationId: activeConvId,
      character: character,
      history: historyExceptCurrent,
      currentInput: trimmed,
      reservedTokens: reservedTokens,
    );
    final apiMessages = assembled.messages;
    final usage = assembled.usage;
    if (_sendSeq == seq) {
      state = state.copyWith(contextUsage: usage);
    }
    apiMessages.add(
      ApiMessage(
        role: 'user',
        content: trimmed,
        images: [for (final b in attached) ApiImage(bytes: b)],
      ),
    );

    // 5. 解析 profile：群成员独立供应商 > 会话供应商 > 默认。
    //    旧会话可能 pin 了已删除/未填 Key 的供应商，回退默认。
    String? speakerProfileId;
    if (character != null) {
      for (final participant in participants) {
        if (participant.characterId == character.id) {
          speakerProfileId = participant.apiProfileId;
          break;
        }
      }
    }
    final profile = await _resolveProfile(
      conversationProfileId: conv?.apiProfileId ?? '',
      participantProfileId: speakerProfileId,
      profileRepo: profileRepo,
    );
    if (profile == null || profile.apiKey.trim().isEmpty) {
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
    final activeProfile = profile;

    // 6. 流式消费（多段，v8）：`[P]` 独行分隔符把一轮回复切成最多
    //    SegmentSplitter.maxSegments 段，每段独立落一行消息。缓冲区
    //    随段整体换新；过期落盘定时器用 identical 快照检查丢弃。
    //    绑定角色时增量剥离情绪/动作标签。
    var splitter = SegmentSplitter();
    var contentBuf = StringBuffer();
    var rawBuf = StringBuffer();
    // 标签剥离对所有会话生效（v8.1）：无角色会话同样可能吐出
    // <action:x> 之类的标记，漏到气泡里就是可见脏文本。
    var parser = EmotionTagParser();
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
        speakerCharacterId: character?.id,
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

    // 取消令牌先于 consumeOnce 声明，闭包才能捕获到它。
    final cancelToken = CancelToken();

    /// 每次尝试（首次或空回复重试）都从干净的解析状态开始。
    void resetAttempt() {
      flushTimer?.cancel();
      splitter = SegmentSplitter();
      contentBuf = StringBuffer();
      rawBuf = StringBuffer();
      parser = EmotionTagParser();
      segEvents = <EmotionEvent>[];
      segId = assistant.id;
      segmentCount = 1;
      keywordTail = '';
      lastKeywordFired.clear();
    }

    /// 错误/取消时把分段器未完成的尾行、标签解析器滞留的文本吐进缓冲，
    /// 避免「已生成半句但还在行缓冲里」被误判为空、连占位一起删掉。
    void flushPendingIntoBuffers() {
      final tail = splitter.flush();
      if (tail.isNotEmpty) {
        rawBuf.write(tail);
        contentBuf.write(parser.feed(tail).flushed);
      }
      final pending = parser.flush();
      if (pending.isNotEmpty) contentBuf.write(pending);
    }

    /// 消费一轮流，返回正文/原始标签/推理/结束原因，供空回复兜底判断。
    Future<
      ({bool gotContent, bool gotRaw, bool gotReasoning, String? finishReason})
    >
    consumeOnce({int? maxTokens}) async {
      resetAttempt();
      String? finishReason;
      var gotReasoning = false;
      final stream = api.streamChat(
        profile: activeProfile,
        messages: apiMessages,
        maxTokens: maxTokens,
        cancelToken: cancelToken,
      );
      await for (final delta in stream) {
        if (delta.finishReason != null) finishReason = delta.finishReason;
        if (delta.reasoning != null && delta.reasoning!.isNotEmpty) {
          gotReasoning = true;
        }
        final text = delta.content;
        if (text == null || text.isEmpty) continue;
        // 分段检测先行（行制），文本片段再进情绪标签解析。
        for (final ev in splitter.feed(text)) {
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
      // 把滞留的半个标签按普通文本吐出，保证内容不丢。
      final pending = parser.flush();
      if (pending.isNotEmpty) contentBuf.write(pending);
      final gotContent = contentBuf.toString().trim().isNotEmpty;
      final gotRaw = rawBuf.toString().trim().isNotEmpty;
      if (gotContent) {
        await finalizeSegment(MessageStatus.done);
        await sink.onAssistantDone();
      }
      return (
        gotContent: gotContent,
        gotRaw: gotRaw,
        gotReasoning: gotReasoning,
        finishReason: finishReason,
      );
    }

    _cancelToken = cancelToken;
    if (_sendSeq == seq) {
      state = state.copyWith(isStreaming: true, streamingMessageId: segId);
    }

    try {
      var attempt = 0;
      late ({
        bool gotContent,
        bool gotRaw,
        bool gotReasoning,
        String? finishReason,
      })
      outcome;

      while (true) {
        outcome = await consumeOnce(
          // 只有 length 截断时才需要加大预算；其余情况同参重试。
          maxTokens: attempt == 0
              ? null
              : (activeProfile.maxTokens == null
                    ? null
                    : (activeProfile.maxTokens! * 2 < 1024
                          ? 1024
                          : activeProfile.maxTokens! * 2)),
        );

        var canRetry =
            attempt == 0 &&
            !outcome.gotContent &&
            !outcome.gotRaw &&
            segmentCount == 1 &&
            _isRetryableFinish(outcome.finishReason) &&
            _sendSeq == seq &&
            !cancelToken.isCancelled;
        if (canRetry) {
          canRetry = await ref
              .read(appSettingsRepositoryProvider)
              .autoRetryEnabled();
        }
        if (!canRetry) break;

        attempt++;
        // 重试前把占位清空；不重复入库用户消息、不重复触发图片概括。
        await chatRepo.updateMessage(
          assistant.id,
          content: '',
          rawContent: '',
          status: MessageStatus.streaming,
        );
        if (_sendSeq == seq) {
          state = state.copyWith(streamingMessageId: assistant.id);
        }
      }

      final hadText = outcome.gotContent || segmentCount > 1;
      if (!hadText) {
        // 整轮空回复：不写库（历史里不留空泡）。
        flushTimer?.cancel();
        await chatRepo.deleteMessage(segId);
        if (cancelToken.isCancelled) {
          await sink.onAssistantInterrupted();
        } else {
          await sink.onAssistantDone();
          if (_sendSeq == seq) {
            state = state.copyWith(errorText: _emptyReplyText(outcome));
          }
        }
        return;
      }
      if (!outcome.gotContent) {
        // 最后停在 `[P]` 边界上：删掉空的尾段，前面完成的段保留。
        flushTimer?.cancel();
        await chatRepo.deleteMessage(segId);
      }

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
              speakerCharacterId: character?.id,
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
              speakerCharacterId: charId,
            );
          })().catchError((_) {}),
        );
      }
    } on CancelledException {
      flushPendingIntoBuffers();
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
      flushPendingIntoBuffers();
      if (contentBuf.toString().trim().isEmpty &&
          rawBuf.toString().trim().isEmpty) {
        // 没有任何正文/标签：删占位，不在历史里留错误空泡。
        flushTimer?.cancel();
        await chatRepo.deleteMessage(segId);
      } else {
        await finalizeSegment(MessageStatus.error);
      }
      await sink.onAssistantInterrupted();
      if (_sendSeq == seq) state = state.copyWith(errorText: e.message);
    } catch (e) {
      flushPendingIntoBuffers();
      if (contentBuf.toString().trim().isEmpty &&
          rawBuf.toString().trim().isEmpty) {
        flushTimer?.cancel();
        await chatRepo.deleteMessage(segId);
      } else {
        await finalizeSegment(MessageStatus.error);
      }
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

  /// 重新生成一条已完成的 assistant 消息。
  ///
  /// 只允许 done 的 assistant；旧正文先存为候选，失败/空回复会恢复旧正文。
  Future<bool> regenerateMessage(String messageId) async {
    if (state.isStreaming) return false;
    final repo = ref.read(chatRepositoryProvider);
    final message = await repo.getMessage(messageId);
    if (message == null ||
        message.role != ChatRole.assistant ||
        message.status != MessageStatus.done) {
      return false;
    }
    final conversation = await repo.getConversation(message.conversationId);
    if (conversation == null) return false;
    final history = await repo.watchMessages(conversation.id).first;
    final index = history.indexWhere((m) => m.id == messageId);
    if (index <= 0) return false;
    final before = history.sublist(0, index);
    if (before.isEmpty || before.last.role != ChatRole.user) return false;

    final profileRepo = ref.read(apiProfileRepositoryProvider);
    final api = ref.read(chatApiClientProvider);
    final settings = ref.read(appSettingsRepositoryProvider);
    final windowTokens = await settings.contextWindowTokens();
    final otherTokens = await settings.contextWindowOtherTokens();

    // 群聊重新生成要沿用这条消息的发言人，而不是会话主角色。
    final speakerId = message.speakerCharacterId ?? conversation.characterId;
    final Character? character = speakerId == null
        ? null
        : await ref.read(characterRepositoryProvider).getById(speakerId);
    final participants = await repo.listParticipants(conversation.id);
    final participantCharacters = <String, Character>{};
    for (final participant in participants) {
      final c = await ref
          .read(characterRepositoryProvider)
          .getById(participant.characterId);
      if (c != null) participantCharacters[c.id] = c;
    }
    final promptHistory = _transformGroupHistory(
      before,
      participants: participants,
      character: character,
      participantCharacters: participantCharacters,
    );
    final List<ApiMessage> apiMessages;
    if (character == null) {
      apiMessages = PromptAssembler()
          .assembleBare(history: promptHistory, tokenBudget: windowTokens)
          .messages;
    } else {
      var memorySummary = '';
      var userSummary = '';
      var facts = const <MemoryFact>[];
      final pastSessions = <PastSession>[];
      final recallQuery = before.reversed
          .take(4)
          .map((m) => m.contentWithImageNote)
          .join('\n');
      if (await settings.memoryEnabled()) {
        final characterRepo = ref.read(characterRepositoryProvider);
        final memory = await characterRepo.getMemory(character.id);
        memorySummary = memory.summary;
        userSummary = memory.userSummary;
        facts = recallMemoryFacts(
          facts: await characterRepo.getMemoryFacts(character.id),
          query: recallQuery,
        );
        for (final g in await repo.getCrossSessionDigest(
          characterId: character.id,
          excludeConversationId: conversation.id,
        )) {
          pastSessions.add(
            PastSession(title: g.conversation.title, messages: g.messages),
          );
        }
      }
      final lore = matchLoreEntries(
        entries: await ref
            .read(loreRepositoryProvider)
            .listForCharacter(character.id, enabledOnly: true),
        query: recallQuery,
      );
      apiMessages = PromptAssembler()
          .assembleDetailed(
            character: character,
            history: promptHistory,
            memorySummary: memorySummary,
            pastSessions: pastSessions,
            facts: facts,
            lore: lore,
            userSummary: userSummary,
            tokenBudget: windowTokens,
            otherTokenBudget: otherTokens,
          )
          .messages;
    }

    String? speakerProfileId;
    if (character != null) {
      for (final participant in participants) {
        if (participant.characterId == character.id) {
          speakerProfileId = participant.apiProfileId;
          break;
        }
      }
    }
    final profile = await _resolveProfile(
      conversationProfileId: conversation.apiProfileId,
      participantProfileId: speakerProfileId,
      profileRepo: profileRepo,
    );
    if (profile == null || profile.apiKey.trim().isEmpty) {
      if (state.conversationId == conversation.id) {
        state = state.copyWith(errorText: '请先在设置中添加 API 供应商配置');
      }
      return false;
    }
    final activeProfile = profile;

    // 旧正文先落候选（若还没有 active 候选）。
    await _ensureActiveVariant(message);
    final oldContent = message.content;
    final oldRaw = message.rawContent;
    final oldEvents = message.emotionEvents;

    final cancelToken = CancelToken();
    _cancelToken = cancelToken;
    await repo.updateMessage(
      messageId,
      content: '',
      rawContent: '',
      status: MessageStatus.streaming,
    );
    if (state.conversationId == conversation.id) {
      state = state.copyWith(streamingMessageId: messageId, clearError: true);
    }

    final buf = StringBuffer();
    final rawBuf = StringBuffer();
    final parser = EmotionTagParser();
    final events = <EmotionEvent>[];
    Timer? flushTimer;
    void scheduleFlush() {
      if (flushTimer?.isActive ?? false) return;
      flushTimer = Timer(const Duration(milliseconds: 150), () {
        repo.updateMessage(
          messageId,
          content: buf.toString(),
          rawContent: rawBuf.toString(),
        );
      });
    }

    var failed = false;
    try {
      await for (final delta in api.streamChat(
        profile: activeProfile,
        messages: apiMessages,
        cancelToken: cancelToken,
      )) {
        final text = delta.content;
        if (text == null || text.isEmpty) continue;
        rawBuf.write(text);
        final parsed = parser.feed(text);
        buf.write(parsed.flushed);
        events.addAll(parsed.events);
        scheduleFlush();
      }
      buf.write(parser.flush());
    } catch (e) {
      failed = true;
      debugPrint('重新生成失败：$e');
    } finally {
      flushTimer?.cancel();
      if (_cancelToken == cancelToken) _cancelToken = null;
    }

    final newContent = buf.toString().trim();
    if (!failed && newContent.isNotEmpty) {
      final variantId = newId();
      await repo.addVariant(
        MessageVariant(
          id: variantId,
          messageId: messageId,
          content: newContent,
          rawContent: rawBuf.toString(),
          emotionEvents: EmotionTagParser.encodeEvents(events),
          createdAt: DateTime.now(),
        ),
      );
      await repo.updateMessage(
        messageId,
        content: newContent,
        rawContent: rawBuf.toString(),
        emotionEvents: EmotionTagParser.encodeEvents(events),
        status: MessageStatus.done,
      );
      if (state.conversationId == conversation.id) {
        state = state.copyWith(clearStreaming: true);
      }
      return true;
    }

    // 失败/空回复：恢复旧正文，status 保持 done（不把旧回复标错）。
    await repo.updateMessage(
      messageId,
      content: oldContent,
      rawContent: oldRaw,
      emotionEvents: oldEvents,
      status: MessageStatus.done,
    );
    if (state.conversationId == conversation.id) {
      state = state.copyWith(
        clearStreaming: true,
        errorText: failed ? '重新生成失败，已保留原回复' : '模型没有返回内容，已保留原回复',
      );
    }
    return false;
  }

  /// 左右切换候选（direction=±1）；没有候选时先把当前正文存为候选。
  Future<bool> switchVariant(String messageId, int direction) async {
    if (state.isStreaming) return false;
    final repo = ref.read(chatRepositoryProvider);
    final message = await repo.getMessage(messageId);
    if (message == null || message.role != ChatRole.assistant) return false;
    await _ensureActiveVariant(message);
    final variants = await repo.getVariants(messageId);
    if (variants.length < 2) return false;
    final currentId = (await repo.getMessage(messageId))?.activeVariantId;
    var index = variants.indexWhere((v) => v.id == currentId);
    if (index < 0) index = 0;
    final next = (index + direction) % variants.length;
    final variant = variants[next < 0 ? next + variants.length : next];
    await repo.setActiveVariant(messageId, variant.id);
    await repo.updateMessage(
      messageId,
      content: variant.content,
      rawContent: variant.rawContent,
      emotionEvents: variant.emotionEvents,
      status: MessageStatus.done,
    );
    return true;
  }

  /// 编辑消息。assistant 的旧正文保存为候选；user 消息直接改。
  Future<bool> editMessage(String messageId, String text) async {
    if (state.isStreaming) return false;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    final repo = ref.read(chatRepositoryProvider);
    final message = await repo.getMessage(messageId);
    if (message == null) return false;
    if (message.role == ChatRole.user) {
      await repo.updateMessage(
        messageId,
        content: trimmed,
        rawContent: trimmed,
        status: MessageStatus.done,
      );
      return true;
    }
    await _ensureActiveVariant(message);
    final variantId = newId();
    await repo.addVariant(
      MessageVariant(
        id: variantId,
        messageId: messageId,
        content: trimmed,
        rawContent: trimmed,
        emotionEvents: '[]',
        createdAt: DateTime.now(),
      ),
    );
    await repo.updateMessage(
      messageId,
      content: trimmed,
      rawContent: trimmed,
      emotionEvents: '[]',
      status: MessageStatus.done,
    );
    return true;
  }

  /// 无用户消息时循环切换主开场白 + alternate_greetings。
  Future<bool> cycleAlternateGreeting() async {
    if (state.isStreaming) return false;
    final conversationId = state.conversationId;
    if (conversationId == null) return false;
    final repo = ref.read(chatRepositoryProvider);
    final conversation = await repo.getConversation(conversationId);
    if (conversation?.characterId == null) return false;
    final character = await ref
        .read(characterRepositoryProvider)
        .getById(conversation!.characterId!);
    if (character == null || character.alternateGreetings.isEmpty) return false;
    final messages = await repo.watchMessages(conversationId).first;
    if (messages.length != 1 ||
        messages.first.role != ChatRole.assistant ||
        messages.first.status != MessageStatus.done) {
      return false;
    }
    final options = [
      if (character.firstMessage.trim().isNotEmpty)
        character.firstMessage.trim(),
      ...character.alternateGreetings,
    ];
    if (options.length < 2) return false;
    final current = messages.first.content;
    var index = options.indexWhere((e) => e == current);
    if (index < 0) index = 0;
    final next = options[(index + 1) % options.length];
    await repo.updateMessage(
      messages.first.id,
      content: next,
      rawContent: next,
      status: MessageStatus.done,
    );
    return true;
  }

  /// 从某条消息分支：复制前缀到新会话并返回新会话 id。
  Future<String?> branchFromMessage(String messageId) async {
    final conversationId = state.conversationId;
    if (conversationId == null || state.isStreaming) return null;
    final repo = ref.read(chatRepositoryProvider);
    final message = await repo.getMessage(messageId);
    if (message == null ||
        message.conversationId != conversationId ||
        message.status == MessageStatus.streaming) {
      return null;
    }
    final branch = await repo.branchConversation(
      sourceConversationId: conversationId,
      messageId: messageId,
    );
    return branch.id;
  }

  Future<void> _ensureActiveVariant(ChatMessage message) async {
    if (message.activeVariantId != null) return;
    final repo = ref.read(chatRepositoryProvider);
    await repo.addVariant(
      MessageVariant(
        id: newId(),
        messageId: message.id,
        content: message.content,
        rawContent: message.rawContent,
        emotionEvents: message.emotionEvents,
        createdAt: message.createdAt,
      ),
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// 只有正常结束/长度截断/未知（null）才值得同参或加预算重试。
bool _isRetryableFinish(String? finish) =>
    finish == null || finish == 'stop' || finish == 'length';

/// 空回复的面向用户提示。
String _emptyReplyText(
  ({bool gotContent, bool gotRaw, bool gotReasoning, String? finishReason})
  outcome,
) {
  if (outcome.finishReason == 'content_filter') {
    return '内容被模型安全策略拦截，请调整后重试';
  }
  if (outcome.gotReasoning) {
    return '模型只返回了推理内容，没有正文；请调大最大输出 token 或关闭思考模式';
  }
  if (outcome.gotRaw) {
    return '模型只返回了格式标记，没有正文，请重试';
  }
  return '模型这次没有返回内容，请重试或检查最大输出设置';
}
