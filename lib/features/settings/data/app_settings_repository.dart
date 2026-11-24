/// 通用应用设置（settings KV）：主题、记忆开关等。
library;

import 'package:drift/drift.dart';

import '../../../data/local/app_database.dart';
import '../../agent/domain/agent_approval.dart';

/// 跨会话记忆全局开关的 KV 键。
const kMemoryEnabledSetting = 'memory_enabled';

/// 空回复自动重试一次（默认开）的 KV 键。
const kAutoRetryEnabledSetting = 'auto_retry_enabled';

/// 上下文窗口（token）与跨会话原文预算（token）的 KV 键。
const kContextWindowTokensSetting = 'context_window_tokens';
const kContextWindowOtherTokensSetting = 'context_window_other_tokens';

const int kContextWindowDefault = 4096;
const int kContextWindowMin = 1024;
const int kContextWindowMax = 32768;
const int kContextWindowStep = 512;
const int kContextWindowOtherDefault = 1024;
const int kContextWindowOtherMax = 8192;

/// Agent 模块设置：写文件是否免确认、单轮工具步数上限、是否启用 tab。
const kAgentAutoWriteSetting = 'agent_auto_write';
const kAgentMaxStepsSetting = 'agent_max_steps';
const kAgentEnabledSetting = 'agent_enabled';
const kAgentContextWindowSetting = 'agent_context_window_tokens';
const int kAgentMaxStepsDefault = 6;
const int kAgentMaxStepsHardLimit = 12;

/// Agent 扩权：审批模式与 SAF 授权文件夹。
const kAgentApprovalModeSetting = 'agent_approval_mode';
const kAgentGrantedFoldersSetting = 'agent_granted_folders';
const kAgentHttpDomainsSetting = 'agent_http_domains';

class AppSettingsRepository {
  final AppDatabase db;

  AppSettingsRepository(this.db);

  /// 当前主题 key（缺省 kThemePalettes 首个；旧版强调色 key 由
  /// themePaletteOf 兼容映射）。
  Future<String> themeKey() async {
    final q = db.select(db.settings)
      ..where((t) => t.key.equals('theme_accent'));
    final row = await q.getSingleOrNull();
    return row?.value ?? 'deep-space';
  }

  Future<void> setThemeKey(String key) async {
    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
      key: const Value('theme_accent'),
      value: Value(key),
    ));
  }

  /// 跨会话记忆开关（缺省开；与 voice_enabled 缺省关相反）。
  Future<bool> memoryEnabled() async {
    final q = db.select(db.settings)
      ..where((t) => t.key.equals(kMemoryEnabledSetting));
    final row = await q.getSingleOrNull();
    return row == null || row.value == '1';
  }

  Future<void> setMemoryEnabled(bool enabled) async {
    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
      key: const Value(kMemoryEnabledSetting),
      value: Value(enabled ? '1' : '0'),
    ));
  }

  /// 零正文时是否允许自动重试一次（缺省开）。
  Future<bool> autoRetryEnabled() async {
    final q = db.select(db.settings)
      ..where((t) => t.key.equals(kAutoRetryEnabledSetting));
    final row = await q.getSingleOrNull();
    return row == null || row.value == '1';
  }

  Future<void> setAutoRetryEnabled(bool enabled) async {
    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
      key: const Value(kAutoRetryEnabledSetting),
      value: Value(enabled ? '1' : '0'),
    ));
  }

  /// 上下文窗口 token 数；缺省 4096，越界自动 clamp 到 1024..32768。
  Future<int> contextWindowTokens() async {
    final q = db.select(db.settings)
      ..where((t) => t.key.equals(kContextWindowTokensSetting));
    final row = await q.getSingleOrNull();
    final parsed = int.tryParse(row?.value ?? '');
    return (parsed ?? kContextWindowDefault).clamp(
      kContextWindowMin,
      kContextWindowMax,
    );
  }

  Future<void> setContextWindowTokens(int n) async {
    final value = n.clamp(kContextWindowMin, kContextWindowMax);
    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
      key: const Value(kContextWindowTokensSetting),
      value: Value('$value'),
    ));
  }

  /// 跨会话原文预算 token 数；缺省 1024，0 表示不注入其他会话原文。
  Future<int> contextWindowOtherTokens() async {
    final q = db.select(db.settings)
      ..where((t) => t.key.equals(kContextWindowOtherTokensSetting));
    final row = await q.getSingleOrNull();
    final parsed = int.tryParse(row?.value ?? '');
    return (parsed ?? kContextWindowOtherDefault).clamp(0, kContextWindowOtherMax);
  }

  Future<void> setContextWindowOtherTokens(int n) async {
    final value = n.clamp(0, kContextWindowOtherMax);
    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
      key: const Value(kContextWindowOtherTokensSetting),
      value: Value('$value'),
    ));
  }

  /// 写文件是否免确认（缺省 false：每次写入都弹确认）。
  Future<bool> agentAutoWrite() async {
    final q = db.select(db.settings)
      ..where((t) => t.key.equals(kAgentAutoWriteSetting));
    final row = await q.getSingleOrNull();
    return row?.value == '1';
  }

  Future<void> setAgentAutoWrite(bool enabled) async {
    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
      key: const Value(kAgentAutoWriteSetting),
      value: Value(enabled ? '1' : '0'),
    ));
  }

  /// 单轮工具循环步数；缺省 6，clamp 1..12。
  Future<int> agentMaxSteps() async {
    final q = db.select(db.settings)
      ..where((t) => t.key.equals(kAgentMaxStepsSetting));
    final row = await q.getSingleOrNull();
    final parsed = int.tryParse(row?.value ?? '');
    return (parsed ?? kAgentMaxStepsDefault).clamp(1, kAgentMaxStepsHardLimit);
  }

  Future<void> setAgentMaxSteps(int n) async {
    final value = n.clamp(1, kAgentMaxStepsHardLimit);
    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
      key: const Value(kAgentMaxStepsSetting),
      value: Value('$value'),
    ));
  }

  /// Agent 会话自己的上下文窗口；缺省 4096，clamp 1024..32768。
  Future<int> agentContextWindowTokens() async {
    final q = db.select(db.settings)
      ..where((t) => t.key.equals(kAgentContextWindowSetting));
    final row = await q.getSingleOrNull();
    final parsed = int.tryParse(row?.value ?? '');
    return (parsed ?? kContextWindowDefault).clamp(
      kContextWindowMin,
      kContextWindowMax,
    );
  }

  Future<void> setAgentContextWindowTokens(int n) async {
    final value = n.clamp(kContextWindowMin, kContextWindowMax);
    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
      key: const Value(kAgentContextWindowSetting),
      value: Value('$value'),
    ));
  }

  /// Agent tab 是否显示（缺省开；关闭后仅隐藏入口，不动数据）。
  Future<bool> agentEnabled() async {
    final q = db.select(db.settings)
      ..where((t) => t.key.equals(kAgentEnabledSetting));
    final row = await q.getSingleOrNull();
    return row == null || row.value == '1';
  }

  Future<void> setAgentEnabled(bool enabled) async {
    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
      key: const Value(kAgentEnabledSetting),
      value: Value(enabled ? '1' : '0'),
    ));
  }

  /// Agent 审批模式；缺省每步确认。
  Future<AgentApprovalMode> agentApprovalMode() async {
    final q = db.select(db.settings)
      ..where((t) => t.key.equals(kAgentApprovalModeSetting));
    final row = await q.getSingleOrNull();
    return AgentApprovalMode.parse(row?.value);
  }

  Future<void> setAgentApprovalMode(AgentApprovalMode mode) async {
    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
      key: const Value(kAgentApprovalModeSetting),
      value: Value(mode.storageValue),
    ));
  }

  /// 已授权的 SAF 文件夹列表。
  Future<List<AgentGrantedFolder>> agentGrantedFolders() async {
    final q = db.select(db.settings)
      ..where((t) => t.key.equals(kAgentGrantedFoldersSetting));
    final row = await q.getSingleOrNull();
    return AgentGrantedFolder.decodeList(row?.value);
  }

  Future<void> setAgentGrantedFolders(List<AgentGrantedFolder> folders) async {
    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
      key: const Value(kAgentGrantedFoldersSetting),
      value: Value(AgentGrantedFolder.encodeList(folders)),
    ));
  }

  Future<void> addAgentGrantedFolder(AgentGrantedFolder folder) async {
    final current = await agentGrantedFolders();
    final next = current.where((f) => f.uri != folder.uri).toList()
      ..add(folder);
    await setAgentGrantedFolders(next);
  }

  Future<void> removeAgentGrantedFolder(String uri) async {
    final current = await agentGrantedFolders();
    await setAgentGrantedFolders(
      current.where((f) => f.uri != uri).toList(),
    );
  }

  /// HTTP 工具允许的域名（逗号分隔；空表示允许所有公网域名）。
  Future<List<String>> agentHttpDomains() async {
    final q = db.select(db.settings)
      ..where((t) => t.key.equals(kAgentHttpDomainsSetting));
    final row = await q.getSingleOrNull();
    return (row?.value ?? '')
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> setAgentHttpDomains(List<String> domains) async {
    final cleaned = domains
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toSet()
        .join(',');
    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
      key: const Value(kAgentHttpDomainsSetting),
      value: Value(cleaned),
    ));
  }
}
