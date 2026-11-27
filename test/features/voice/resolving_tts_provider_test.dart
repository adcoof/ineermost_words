import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:ai_roleplay_chat/features/settings/data/api_profile_repository.dart';
import 'package:ai_roleplay_chat/features/settings/domain/api_profile.dart';
import 'package:ai_roleplay_chat/features/voice/data/custom_voice_repository.dart';
import 'package:ai_roleplay_chat/features/voice/data/resolving_tts_provider.dart';
import 'package:ai_roleplay_chat/features/voice/data/tts_profile_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ApiProfileRepository apiRepo;
  late TtsProfileRepository ttsRepo;
  late ResolvingTtsProvider resolver;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    apiRepo = ApiProfileRepository(db);
    ttsRepo = TtsProfileRepository(db);
    resolver = ResolvingTtsProvider(
      profiles: ttsRepo,
      chatProfiles: apiRepo,
      customVoices: CustomVoiceRepository(db),
    );
  });

  tearDown(() => db.close());

  test('语音供应商默认跟随聊天默认，选择后独立，删除后回退默认', () async {
    const mimo = ApiProfile(
      id: 'mimo',
      name: 'MiMo',
      baseUrl: 'https://mimo.example.com/v1',
      apiKey: 'sk-mimo',
      model: 'mimo-v2.6-flash',
      temperature: 1.0,
      extraHeaders: '{}',
      isDefault: false,
    );
    const deepseek = ApiProfile(
      id: 'ds',
      name: 'DeepSeek',
      baseUrl: 'https://api.deepseek.com/v1',
      apiKey: 'sk-ds',
      model: 'deepseek-chat',
      temperature: 1.0,
      extraHeaders: '{}',
      isDefault: true,
    );
    await apiRepo.save(mimo);
    await apiRepo.save(deepseek);

    // 未选择：跟随聊天默认（DeepSeek）。
    expect((await resolver.resolveVoiceProfile())!.id, 'ds');

    // 选择 MiMo：语音独立走 MiMo。
    await ttsRepo.setTtsApiProfileId('mimo');
    expect((await resolver.resolveVoiceProfile())!.id, 'mimo');

    // 选择的供应商被删除：回退默认，避免语音完全不可用。
    await ttsRepo.setTtsApiProfileId('missing');
    expect((await resolver.resolveVoiceProfile())!.id, 'ds');
  });
}
