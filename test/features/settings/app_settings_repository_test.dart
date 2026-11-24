import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:ai_roleplay_chat/features/agent/domain/agent_approval.dart';
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

  test('autoRetryEnabled 缺省开，setAutoRetryEnabled 往返', () async {
    expect(await repo.autoRetryEnabled(), isTrue);
    await repo.setAutoRetryEnabled(false);
    expect(await repo.autoRetryEnabled(), isFalse);
    await repo.setAutoRetryEnabled(true);
    expect(await repo.autoRetryEnabled(), isTrue);
  });

  test('contextWindowTokens 缺省 4096，越界写入被 clamp 且可持久化', () async {
    expect(await repo.contextWindowTokens(), kContextWindowDefault);
    await repo.setContextWindowTokens(8192);
    expect(await repo.contextWindowTokens(), 8192);
    await repo.setContextWindowTokens(1);
    expect(await repo.contextWindowTokens(), kContextWindowMin);
    await repo.setContextWindowTokens(999999);
    expect(await repo.contextWindowTokens(), kContextWindowMax);
    // 重新建 repo 模拟重启后从同一 DB 读取。
    final again = AppSettingsRepository(db);
    expect(await again.contextWindowTokens(), kContextWindowMax);
  });

  test('contextWindowOtherTokens 缺省 1024，0 合法，上限 8192', () async {
    expect(await repo.contextWindowOtherTokens(), kContextWindowOtherDefault);
    await repo.setContextWindowOtherTokens(0);
    expect(await repo.contextWindowOtherTokens(), 0);
    await repo.setContextWindowOtherTokens(-5);
    expect(await repo.contextWindowOtherTokens(), 0);
    await repo.setContextWindowOtherTokens(999999);
    expect(await repo.contextWindowOtherTokens(), kContextWindowOtherMax);
  });

  test('agentApprovalMode 缺省 ask，可持久化', () async {
    expect(await repo.agentApprovalMode(), AgentApprovalMode.ask);
    await repo.setAgentApprovalMode(AgentApprovalMode.full);
    expect(await repo.agentApprovalMode(), AgentApprovalMode.full);
    final again = AppSettingsRepository(db);
    expect(await again.agentApprovalMode(), AgentApprovalMode.full);
  });

  test('授权文件夹增删与去重', () async {
    expect(await repo.agentGrantedFolders(), isEmpty);
    await repo.addAgentGrantedFolder(
      const AgentGrantedFolder(uri: 'tree://a', name: 'A'),
    );
    await repo.addAgentGrantedFolder(
      const AgentGrantedFolder(uri: 'tree://b', name: 'B'),
    );
    await repo.addAgentGrantedFolder(
      const AgentGrantedFolder(uri: 'tree://a', name: 'A2'),
    );
    final folders = await repo.agentGrantedFolders();
    expect(folders.map((f) => f.uri), ['tree://b', 'tree://a']);
    expect(folders.last.name, 'A2');

    await repo.removeAgentGrantedFolder('tree://a');
    expect((await repo.agentGrantedFolders()).map((f) => f.uri), ['tree://b']);
  });

  test('HTTP 域名列表：小写、去重、空串过滤', () async {
    expect(await repo.agentHttpDomains(), isEmpty);
    await repo.setAgentHttpDomains([' Example.com ', 'b.com', 'example.com', '']);
    expect(await repo.agentHttpDomains(), ['example.com', 'b.com']);
    await repo.setAgentHttpDomains([]);
    expect(await repo.agentHttpDomains(), isEmpty);
  });
}
