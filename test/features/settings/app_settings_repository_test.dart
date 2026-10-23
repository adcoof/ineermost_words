import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:ai_roleplay_chat/features/settings/data/app_settings_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AppSettingsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = AppSettingsRepository(db);
  });

  tearDown(() => db.close());

  test('themeAccent 缺省为首个选项 violet', () async {
    expect(await repo.themeAccent(), 'violet');
    expect(AppSettingsRepository.accentOf('violet').label, '霓虹紫');
  });

  test('setThemeAccent 往返与覆盖', () async {
    await repo.setThemeAccent('rose');
    expect(await repo.themeAccent(), 'rose');
    await repo.setThemeAccent('mint');
    expect(await repo.themeAccent(), 'mint');
  });

  test('未知 key 回落默认选项', () {
    final a = AppSettingsRepository.accentOf('nope');
    expect(a.key, 'violet');
  });
}
