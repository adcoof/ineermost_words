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

  test('themeKey 缺省为 deep-space', () async {
    expect(await repo.themeKey(), 'deep-space');
  });

  test('setThemeKey 往返与覆盖', () async {
    await repo.setThemeKey('sakura');
    expect(await repo.themeKey(), 'sakura');
    await repo.setThemeKey('daylight');
    expect(await repo.themeKey(), 'daylight');
  });

  test('memoryEnabled 缺省开，setMemoryEnabled 往返', () async {
    expect(await repo.memoryEnabled(), isTrue);
    await repo.setMemoryEnabled(false);
    expect(await repo.memoryEnabled(), isFalse);
    await repo.setMemoryEnabled(true);
    expect(await repo.memoryEnabled(), isTrue);
  });
}
