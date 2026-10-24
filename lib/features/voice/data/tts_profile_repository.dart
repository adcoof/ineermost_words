/// TTS 配置仓库 + 全局语音开关（settings KV）。
library;

import 'package:drift/drift.dart';

import '../../../core/utils/id.dart';
import '../../../data/local/app_database.dart';
import '../application/voice_orchestrator.dart';

class TtsProfile {
  final String id;
  final String name;

  /// edge | openai | system | mimo
  final String provider;
  final String voiceId;
  final double speed;
  final String model;
  final String apiKey;
  final String baseUrl;
  final bool isDefault;

  const TtsProfile({
    required this.id,
    required this.name,
    required this.provider,
    this.voiceId = '',
    this.speed = 1.0,
    this.model = '',
    this.apiKey = '',
    this.baseUrl = '',
    this.isDefault = false,
  });

  TtsProfile copyWith({
    String? name,
    String? provider,
    String? voiceId,
    double? speed,
    String? model,
    String? apiKey,
    String? baseUrl,
    bool? isDefault,
  }) =>
      TtsProfile(
        id: id,
        name: name ?? this.name,
        provider: provider ?? this.provider,
        voiceId: voiceId ?? this.voiceId,
        speed: speed ?? this.speed,
        model: model ?? this.model,
        apiKey: apiKey ?? this.apiKey,
        baseUrl: baseUrl ?? this.baseUrl,
        isDefault: isDefault ?? this.isDefault,
      );
}

class TtsProfileRepository {
  final AppDatabase db;

  TtsProfileRepository(this.db);

  Stream<List<TtsProfile>> watchProfiles() {
    final q = db.select(db.ttsProfiles)
      ..orderBy([(t) => OrderingTerm.desc(t.isDefault)]);
    return q.watch().map((rows) => rows.map(_fromRow).toList());
  }

  Future<TtsProfile?> getDefault() async {
    final q = db.select(db.ttsProfiles)
      ..where((t) => t.isDefault.equals(true))
      ..limit(1);
    final row = await q.getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// 无配置时返回 Edge 默认（开箱即用）。
  TtsProfile builtinEdge() => const TtsProfile(
        id: 'builtin-edge',
        name: 'Edge 免费语音',
        provider: 'edge',
        voiceId: 'zh-CN-XiaoxiaoNeural',
        isDefault: true,
      );

  /// 内置 MiMo 默认（云端，默认引擎）。
  TtsProfile builtinMimo() => const TtsProfile(
        id: 'builtin-mimo',
        name: 'MiMo 语音',
        provider: 'mimo',
        voiceId: 'mimo_default',
        model: 'mimo-v2.5-tts',
        isDefault: true,
      );

  /// 一次性迁移：把默认 TTS 覆盖为 MiMo（用户明确指示“使用 mimo-v2.5-tts”）。
  /// 用 settings KV 'tts_mimo_migrated' 做标记，只迁移这一次，
  /// 之后用户在设置里改什么就尊重什么。
  Future<void> ensureMimoDefault(Future<bool> Function() chatProfileExists) async {
    final q = db.select(db.settings)..where((t) => t.key.equals('tts_mimo_migrated'));
    if (await q.getSingleOrNull() != null) return;
    // 先写标记：迁移只跑一次，中途失败也不重复覆盖用户选择。
    await db.into(db.settings).insertOnConflictUpdate(const SettingsCompanion(
          key: Value('tts_mimo_migrated'),
          value: Value('1'),
        ));
    final existing = await getDefault();
    if (existing == null) {
      if (await chatProfileExists()) {
        await save(builtinMimo());
      }
      return;
    }
    if (existing.provider == 'mimo') return;
    // 之前因没声音被迫选的 system/edge：覆盖为 MiMo。
    await save(existing.copyWith(
      provider: 'mimo',
      voiceId: 'mimo_default',
      model: 'mimo-v2.5-tts',
      name: 'MiMo 语音',
      isDefault: true,
    ));
  }

  Future<void> save(TtsProfile profile) async {
    if (profile.isDefault) {
      await (db.update(db.ttsProfiles)..where((t) => t.id.equals(profile.id).not()))
          .write(const TtsProfilesCompanion(isDefault: Value(false)));
    }
    await db.into(db.ttsProfiles).insertOnConflictUpdate(_toRow(profile));
  }

  Future<void> delete(String id) async {
    await (db.delete(db.ttsProfiles)..where((t) => t.id.equals(id))).go();
  }

  // ---- 全局开关/参数（settings KV） ----

  Future<bool> voiceEnabled() async {
    final q = db.select(db.settings)
      ..where((t) => t.key.equals(kVoiceEnabledSetting));
    final row = await q.getSingleOrNull();
    return row?.value == '1';
  }

  Future<void> setVoiceEnabled(bool enabled) async {
    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
      key: Value(kVoiceEnabledSetting),
      value: Value(enabled ? '1' : '0'),
    ));
  }

  Future<double> voiceSpeed() async {
    final q = db.select(db.settings)..where((t) => t.key.equals('voice_speed'));
    final row = await q.getSingleOrNull();
    return double.tryParse(row?.value ?? '') ?? 1.0;
  }

  Future<void> setVoiceSpeed(double speed) async {
    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
      key: const Value('voice_speed'),
      value: Value(speed.toStringAsFixed(2)),
    ));
  }

  Future<String> asrLocale() async {
    final q = db.select(db.settings)..where((t) => t.key.equals('asr_locale'));
    final row = await q.getSingleOrNull();
    return row?.value ?? 'zh_CN';
  }

  Future<void> setAsrLocale(String locale) async {
    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
      key: const Value('asr_locale'),
      value: Value(locale),
    ));
  }

  /// ASR 引擎：'mimo'（复用聊天配置）| 'custom'（独立配置）| 'system'，
  /// 缺省 'mimo'。
  Future<String> asrEngine() async {
    final q = db.select(db.settings)..where((t) => t.key.equals('asr_engine'));
    final row = await q.getSingleOrNull();
    return row?.value ?? 'mimo';
  }

  Future<void> setAsrEngine(String engine) async {
    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
      key: const Value('asr_engine'),
      value: Value(engine),
    ));
  }

  /// ASR 独立配置（asr_engine='custom' 时生效；与 TTS 的 profile 字段分离）。
  Future<({String baseUrl, String apiKey, String model})> asrCustomConfig() async {
    final q = db.select(db.settings)
      ..where((t) =>
          t.key.isIn(const ['asr_base_url', 'asr_api_key', 'asr_model']));
    final rows = await q.get();
    final map = {for (final r in rows) r.key: r.value};
    return (
      baseUrl: map['asr_base_url'] ?? '',
      apiKey: map['asr_api_key'] ?? '',
      model: map['asr_model'] ?? '',
    );
  }

  Future<void> setAsrCustomConfig({
    required String baseUrl,
    required String apiKey,
    required String model,
  }) async {
    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
      key: const Value('asr_base_url'),
      value: Value(baseUrl.trim()),
    ));
    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
      key: const Value('asr_api_key'),
      value: Value(apiKey.trim()),
    ));
    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
      key: const Value('asr_model'),
      value: Value(model.trim()),
    ));
  }

  /// 新 id（编辑页新建用）。
  String newProfileId() => newId();

  TtsProfile _fromRow(TtsProfileRow row) => TtsProfile(
        id: row.id,
        name: row.name,
        provider: row.provider,
        voiceId: row.voiceId,
        speed: row.speed,
        model: row.model,
        apiKey: row.apiKey,
        baseUrl: row.baseUrl,
        isDefault: row.isDefault,
      );

  TtsProfilesCompanion _toRow(TtsProfile p) => TtsProfilesCompanion(
        id: Value(p.id),
        name: Value(p.name),
        provider: Value(p.provider),
        voiceId: Value(p.voiceId),
        speed: Value(p.speed),
        model: Value(p.model),
        apiKey: Value(p.apiKey),
        baseUrl: Value(p.baseUrl),
        isDefault: Value(p.isDefault),
      );
}
