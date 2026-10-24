/// 全局 Riverpod providers。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';
import '../features/chat/application/chat_controller.dart';
import '../features/chat/application/memory_summarizer.dart';
import '../features/chat/application/speech_sink.dart';
import '../features/chat/data/chat_api_client.dart';
import '../features/chat/data/chat_repository.dart';
import '../features/chat/domain/models.dart';
import '../features/characters/data/character_repository.dart';
import '../features/characters/domain/character.dart';
import '../features/pet/data/pet_model_repository.dart';
import '../features/settings/data/api_profile_repository.dart';
import '../features/settings/data/app_settings_repository.dart';
import '../features/voice/application/tts_queue_service.dart';
import '../features/voice/application/voice_orchestrator.dart';
import '../features/voice/data/just_audio_player_backend.dart';
import '../features/voice/data/mimo_asr_provider.dart';
import '../features/voice/data/custom_voice_repository.dart';
import '../features/voice/data/resolving_asr_provider.dart';
import '../features/voice/data/resolving_tts_provider.dart';
import '../features/voice/data/speech_to_text_asr_provider.dart';
import '../features/voice/data/tts_profile_repository.dart';
import '../features/voice/domain/asr_provider.dart';
import 'theme.dart' show ThemePalette, themePaletteOf;

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final apiProfileRepositoryProvider = Provider<ApiProfileRepository>(
  (ref) => ApiProfileRepository(ref.watch(appDatabaseProvider)),
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(appDatabaseProvider)),
);

final characterRepositoryProvider = Provider<CharacterRepository>(
  (ref) => CharacterRepository(ref.watch(appDatabaseProvider)),
);

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>(
  (ref) => AppSettingsRepository(ref.watch(appDatabaseProvider)),
);

/// 未归档会话流（updatedAt 倒序），会话列表页消费。
///
/// autoDispose：页面卸载即退订 drift watch（否则 ProviderScope 常驻
/// 订阅，测试里 db.close() 会等不到完成而挂死）。
final conversationsStreamProvider = StreamProvider.autoDispose<
    List<Conversation>>(
  (ref) => ref.watch(chatRepositoryProvider).watchConversations(),
);

/// 角色流（updatedAt 倒序），会话列表页头像条消费。
final charactersStreamProvider = StreamProvider.autoDispose<List<Character>>(
  (ref) => ref.watch(characterRepositoryProvider).watchCharacters(),
);

final petModelRepositoryProvider = Provider<PetModelRepository>(
  (ref) => PetModelRepository(ref.watch(appDatabaseProvider)),
);

final ttsProfileRepositoryProvider = Provider<TtsProfileRepository>(
  (ref) => TtsProfileRepository(ref.watch(appDatabaseProvider)),
);

/// 自定义音色（音色设计）仓库。
final customVoiceRepositoryProvider = Provider<CustomVoiceRepository>(
  (ref) => CustomVoiceRepository(ref.watch(appDatabaseProvider)),
);

/// 语音编排：助手文本 → 句切分 → TTS 队列 → 播放/口型。
final voiceOrchestratorProvider = Provider<VoiceOrchestrator>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final ttsProfiles = TtsProfileRepository(db);
  final queue = TtsQueueService(
    provider: ResolvingTtsProvider(
      profiles: ttsProfiles,
      chatProfiles: ref.watch(apiProfileRepositoryProvider),
      customVoices: ref.watch(customVoiceRepositoryProvider),
    ),
    player: JustAudioPlayerBackend(),
  );
  final orchestrator = VoiceOrchestrator(
    queue: queue,
    enabledCheck: ttsProfiles.voiceEnabled,
    speedGet: ttsProfiles.voiceSpeed,
    // 兜底留空：各引擎自持默认音色；写死 Edge 音色会让 MiMo 报 Unknown voice 400。
    voiceGet: () async => (await ttsProfiles.getDefault())?.voiceId ?? '',
  );
  ref.onDispose(queue.dispose);
  return orchestrator;
});

/// 聊天控制器依赖的语音出口（内部按开关自判断）。
final speechSinkProvider = Provider<AssistantSpeechSink>(
  (ref) => ref.watch(voiceOrchestratorProvider),
);

/// ASR：按设置选引擎（'mimo' 复用聊天 / 'custom' 独立配置 / 'system' 本机），
/// 启动失败自动回退。custom 档注入独立配置（settings KV），未配时回落聊天配置。
final asrProviderProvider = Provider<AsrProvider>((ref) {
  final ttsProfiles = ref.read(ttsProfileRepositoryProvider);
  return ResolvingAsrProvider(
    engineGet: () => ttsProfiles.asrEngine(),
    mimo: MimoAsrProvider(
      baseUrl: '',
      apiKey: '',
      model: '',
      chatProfilesRepo: ref.read(apiProfileRepositoryProvider),
    ),
    custom: MimoAsrProvider(
      baseUrl: '',
      apiKey: '',
      model: '',
      chatProfilesRepo: ref.read(apiProfileRepositoryProvider),
      customConfigGet: () async {
        final c = await ttsProfiles.asrCustomConfig();
        return (baseUrl: c.baseUrl, apiKey: c.apiKey, model: c.model);
      },
    ),
    system: SpeechToTextAsrProvider(localeGet: () => ttsProfiles.asrLocale()),
  );
});

final chatApiClientProvider = Provider<ChatApiClient>(
  (ref) => OpenAiChatApiClient(),
);

/// 跨会话记忆摘要器（ChatController 成功回合后 fire-and-forget 触发）。
final memorySummarizerProvider = Provider<MemorySummarizer>((ref) =>
    MemorySummarizer(
      chatRepo: ref.watch(chatRepositoryProvider),
      characterRepo: ref.watch(characterRepositoryProvider),
      profileRepo: ref.watch(apiProfileRepositoryProvider),
      api: ref.watch(chatApiClientProvider),
    ));

/// 当前主题调色板（设置页切换后 invalidate 即全局生效）。
final themePaletteProvider = FutureProvider<ThemePalette>((ref) async {
  final repo = ref.watch(appSettingsRepositoryProvider);
  return themePaletteOf(await repo.themeKey());
});

final chatControllerProvider =
    NotifierProvider<ChatController, ChatUiState>(ChatController.new);