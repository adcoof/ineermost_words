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

  test('语音供应商默认自动选 MiMo，与聊天默认解耦', () async {
    await apiRepo.save(mimo);
    await apiRepo.save(deepseek);

    // 未选择：自动选 MiMo，而不是默认聊天（DeepSeek）。
    expect((await resolver.resolveVoiceProfile())!.id, 'mimo');

    // 显式选择仍优先（用户可以指定其他语音供应商）。
    await ttsRepo.setTtsApiProfileId('ds');
    expect((await resolver.resolveVoiceProfile())!.id, 'ds');

    // 选择的供应商被删除：回退自动 MiMo，避免语音完全不可用。
    await ttsRepo.setTtsApiProfileId('missing');
    expect((await resolver.resolveVoiceProfile())!.id, 'mimo');

    // 显式选择 Key 为空：同样回退自动 MiMo。
    await apiRepo.save(deepseek.copyWith(apiKey: ''));
    await ttsRepo.setTtsApiProfileId('ds');
    expect((await resolver.resolveVoiceProfile())!.id, 'mimo');
  });

  test('没有 MiMo 时不拿文本聊天供应商顶替，返回 null', () async {
    await apiRepo.save(deepseek);
    expect(await resolver.resolveVoiceProfile(), isNull);

    // 显式选择文本供应商则尊重用户选择（可能失败，但不是静默改配置）。
    await ttsRepo.setTtsApiProfileId('ds');
    expect((await resolver.resolveVoiceProfile())!.id, 'ds');
  });
}
