/// 全局 Riverpod providers。
library;

import 'package:flutter/material.dart' show Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';
import '../features/chat/application/chat_controller.dart';
import '../features/chat/application/speech_sink.dart';
import '../features/chat/data/chat_api_client.dart';
import '../features/chat/data/chat_repository.dart';
import '../features/characters/data/character_repository.dart';
import '../features/pet/data/pet_model_repository.dart';
import '../features/settings/data/api_profile_repository.dart';
import '../features/settings/data/app_settings_repository.dart';
import '../features/voice/application/tts_queue_service.dart';
import '../features/voice/application/voice_orchestrator.dart';
import '../features/voice/data/just_audio_player_backend.dart';
import '../features/voice/data/mimo_asr_provider.dart';
import '../features/voice/data/resolving_asr_provider.dart';
import '../features/voice/data/resolving_tts_provider.dart';
import '../features/voice/data/speech_to_text_asr_provider.dart';
import '../features/voice/data/tts_profile_repository.dart';
import '../features/voice/domain/asr_provider.dart';
import 'theme.dart' show accentColorOf;

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

final petModelRepositoryProvider = Provider<PetModelRepository>(
  (ref) => PetModelRepository(ref.watch(appDatabaseProvider)),
);

final ttsProfileRepositoryProvider = Provider<TtsProfileRepository>(
  (ref) => TtsProfileRepository(ref.watch(appDatabaseProvider)),
);

/// 语音编排：助手文本 → 句切分 → TTS 队列 → 播放/口型。
final voiceOrchestratorProvider = Provider<VoiceOrchestrator>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final ttsProfiles = TtsProfileRepository(db);
  final queue = TtsQueueService(
    provider: ResolvingTtsProvider(
      profiles: ttsProfiles,
      chatProfiles: ref.watch(apiProfileRepositoryProvider),
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

/// ASR：按设置选引擎（'mimo' 云端 / 'system' 本机），启动失败自动回退。
final asrProviderProvider = Provider<AsrProvider>(
  (ref) => ResolvingAsrProvider(
    engineGet: () => ref.read(ttsProfileRepositoryProvider).asrEngine(),
    mimo: MimoAsrProvider(
      baseUrl: '',
      apiKey: '',
      model: '',
      chatProfilesRepo: ref.read(apiProfileRepositoryProvider),
    ),
    system: SpeechToTextAsrProvider(
        localeGet: () => ref.read(ttsProfileRepositoryProvider).asrLocale()),
  ),
);

final chatApiClientProvider = Provider<ChatApiClient>(
  (ref) => OpenAiChatApiClient(),
);

/// 当前主题强调色（设置页切换后 invalidate 即全局生效）。
final themeAccentProvider = FutureProvider<Color>((ref) async {
  final repo = AppSettingsRepository(ref.watch(appDatabaseProvider));
  return accentColorOf(await repo.themeAccent());
});

final chatControllerProvider =
    NotifierProvider<ChatController, ChatUiState>(ChatController.new);