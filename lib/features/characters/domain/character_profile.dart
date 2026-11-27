/// 角色扩展档案：在 6 个 SillyTavern 核心字段之外，保存更完整的人设资料。
///
/// 存储策略（v2.1）：核心字段仍是 `characters` 表的列；本对象整体编码成
/// `characters.profile_json`。解码时未知的顶层键保留在 [extra]，重新编码时
/// 写回，避免未来版本新增分区后旧版本保存时丢字段。
library;

import 'dart:convert';

/// 基础身份（名字仍在 characters.name，不在这里）。
class BasicProfile {
  final String nickname;
  final String age;
  final String gender;
  final String race;
  final String identity;

  const BasicProfile({
    this.nickname = '',
    this.age = '',
    this.gender = '',
    this.race = '',
    this.identity = '',
  });

  factory BasicProfile.fromJson(Map<String, dynamic> json) => BasicProfile(
    nickname: _readStr(json, 'nickname'),
    age: _readStr(json, 'age'),
    gender: _readStr(json, 'gender'),
    race: _readStr(json, 'race'),
    identity: _readStr(json, 'identity'),
  );

  Map<String, dynamic> toJson() => _compact({
    'nickname': nickname,
    'age': age,
    'gender': gender,
    'race': race,
    'identity': identity,
  });

  bool get isEmpty =>
      nickname.trim().isEmpty &&
      age.trim().isEmpty &&
      gender.trim().isEmpty &&
      race.trim().isEmpty &&
      identity.trim().isEmpty;

  BasicProfile copyWith({
    String? nickname,
    String? age,
    String? gender,
    String? race,
    String? identity,
  }) => BasicProfile(
    nickname: nickname ?? this.nickname,
    age: age ?? this.age,
    gender: gender ?? this.gender,
    race: race ?? this.race,
    identity: identity ?? this.identity,
  );
}

/// 外貌设定。
class AppearanceProfile {
  final String summary;
  final String hair;
  final String eyes;
  final String outfit;
  final String height;
  final String body;
  final String features;

  const AppearanceProfile({
    this.summary = '',
    this.hair = '',
    this.eyes = '',
    this.outfit = '',
    this.height = '',
    this.body = '',
    this.features = '',
  });

  factory AppearanceProfile.fromJson(Map<String, dynamic> json) =>
      AppearanceProfile(
        summary: _readStr(json, 'summary'),
        hair: _readStr(json, 'hair'),
        eyes: _readStr(json, 'eyes'),
        outfit: _readStr(json, 'outfit'),
        height: _readStr(json, 'height'),
        body: _readStr(json, 'body'),
        features: _readStr(json, 'features'),
      );

  Map<String, dynamic> toJson() => _compact({
    'summary': summary,
    'hair': hair,
    'eyes': eyes,
    'outfit': outfit,
    'height': height,
    'body': body,
    'features': features,
  });

  bool get isEmpty =>
      summary.trim().isEmpty &&
      hair.trim().isEmpty &&
      eyes.trim().isEmpty &&
      outfit.trim().isEmpty &&
      height.trim().isEmpty &&
      body.trim().isEmpty &&
      features.trim().isEmpty;

  AppearanceProfile copyWith({
    String? summary,
    String? hair,
    String? eyes,
    String? outfit,
    String? height,
    String? body,
    String? features,
  }) => AppearanceProfile(
    summary: summary ?? this.summary,
    hair: hair ?? this.hair,
    eyes: eyes ?? this.eyes,
    outfit: outfit ?? this.outfit,
    height: height ?? this.height,
    body: body ?? this.body,
    features: features ?? this.features,
  );
}

/// 背景设定。
class BackgroundProfile {
  final String origin;
  final String experiences;
  final String keyEvents;
  final String secrets;
  final String goals;

  const BackgroundProfile({
    this.origin = '',
    this.experiences = '',
    this.keyEvents = '',
    this.secrets = '',
    this.goals = '',
  });

  factory BackgroundProfile.fromJson(Map<String, dynamic> json) =>
      BackgroundProfile(
        origin: _readStr(json, 'origin'),
        experiences: _readStr(json, 'experiences'),
        keyEvents: _readStr(json, 'keyEvents'),
        secrets: _readStr(json, 'secrets'),
        goals: _readStr(json, 'goals'),
      );

  Map<String, dynamic> toJson() => _compact({
    'origin': origin,
    'experiences': experiences,
    'keyEvents': keyEvents,
    'secrets': secrets,
    'goals': goals,
  });

  bool get isEmpty =>
      origin.trim().isEmpty &&
      experiences.trim().isEmpty &&
      keyEvents.trim().isEmpty &&
      secrets.trim().isEmpty &&
      goals.trim().isEmpty;

  BackgroundProfile copyWith({
    String? origin,
    String? experiences,
    String? keyEvents,
    String? secrets,
    String? goals,
  }) => BackgroundProfile(
    origin: origin ?? this.origin,
    experiences: experiences ?? this.experiences,
    keyEvents: keyEvents ?? this.keyEvents,
    secrets: secrets ?? this.secrets,
    goals: goals ?? this.goals,
  );
}

/// 关系设定。
class RelationshipProfile {
  final String userRelation;
  final String initialCloseness;
  final String direction;
  final String others;

  const RelationshipProfile({
    this.userRelation = '',
    this.initialCloseness = '',
    this.direction = '',
    this.others = '',
  });

  factory RelationshipProfile.fromJson(Map<String, dynamic> json) =>
      RelationshipProfile(
        userRelation: _readStr(json, 'userRelation'),
        initialCloseness: _readStr(json, 'initialCloseness'),
        direction: _readStr(json, 'direction'),
        others: _readStr(json, 'others'),
      );

  Map<String, dynamic> toJson() => _compact({
    'userRelation': userRelation,
    'initialCloseness': initialCloseness,
    'direction': direction,
    'others': others,
  });

  bool get isEmpty =>
      userRelation.trim().isEmpty &&
      initialCloseness.trim().isEmpty &&
      direction.trim().isEmpty &&
      others.trim().isEmpty;

  RelationshipProfile copyWith({
    String? userRelation,
    String? initialCloseness,
    String? direction,
    String? others,
  }) => RelationshipProfile(
    userRelation: userRelation ?? this.userRelation,
    initialCloseness: initialCloseness ?? this.initialCloseness,
    direction: direction ?? this.direction,
    others: others ?? this.others,
  );
}

/// 语言风格。
class LanguageProfile {
  final String tone;
  final String habits;
  final String verbalTics;
  final String commonPhrases;
  final String taboos;

  const LanguageProfile({
    this.tone = '',
    this.habits = '',
    this.verbalTics = '',
    this.commonPhrases = '',
    this.taboos = '',
  });

  factory LanguageProfile.fromJson(Map<String, dynamic> json) => LanguageProfile(
    tone: _readStr(json, 'tone'),
    habits: _readStr(json, 'habits'),
    verbalTics: _readStr(json, 'verbalTics'),
    commonPhrases: _readStr(json, 'commonPhrases'),
    taboos: _readStr(json, 'taboos'),
  );

  Map<String, dynamic> toJson() => _compact({
    'tone': tone,
    'habits': habits,
    'verbalTics': verbalTics,
    'commonPhrases': commonPhrases,
    'taboos': taboos,
  });

  bool get isEmpty =>
      tone.trim().isEmpty &&
      habits.trim().isEmpty &&
      verbalTics.trim().isEmpty &&
      commonPhrases.trim().isEmpty &&
      taboos.trim().isEmpty;

  LanguageProfile copyWith({
    String? tone,
    String? habits,
    String? verbalTics,
    String? commonPhrases,
    String? taboos,
  }) => LanguageProfile(
    tone: tone ?? this.tone,
    habits: habits ?? this.habits,
    verbalTics: verbalTics ?? this.verbalTics,
    commonPhrases: commonPhrases ?? this.commonPhrases,
    taboos: taboos ?? this.taboos,
  );
}

/// 互动设定。
class InteractionProfile {
  final String replyLength;
  final String initiative;
  final String emotionExpression;
  final String behaviorTendency;

  const InteractionProfile({
    this.replyLength = '',
    this.initiative = '',
    this.emotionExpression = '',
    this.behaviorTendency = '',
  });

  factory InteractionProfile.fromJson(Map<String, dynamic> json) =>
      InteractionProfile(
        replyLength: _readStr(json, 'replyLength'),
        initiative: _readStr(json, 'initiative'),
        emotionExpression: _readStr(json, 'emotionExpression'),
        behaviorTendency: _readStr(json, 'behaviorTendency'),
      );

  Map<String, dynamic> toJson() => _compact({
    'replyLength': replyLength,
    'initiative': initiative,
    'emotionExpression': emotionExpression,
    'behaviorTendency': behaviorTendency,
  });

  bool get isEmpty =>
      replyLength.trim().isEmpty &&
      initiative.trim().isEmpty &&
      emotionExpression.trim().isEmpty &&
      behaviorTendency.trim().isEmpty;

  InteractionProfile copyWith({
    String? replyLength,
    String? initiative,
    String? emotionExpression,
    String? behaviorTendency,
  }) => InteractionProfile(
    replyLength: replyLength ?? this.replyLength,
    initiative: initiative ?? this.initiative,
    emotionExpression: emotionExpression ?? this.emotionExpression,
    behaviorTendency: behaviorTendency ?? this.behaviorTendency,
  );
}

/// 创作者信息（展示 / 导出用，不进提示词）。
class CreatorProfile {
  final String author;
  final String version;
  final List<String> tags;
  final String notes;
  final String copyright;

  const CreatorProfile({
    this.author = '',
    this.version = '',
    this.tags = const [],
    this.notes = '',
    this.copyright = '',
  });

  factory CreatorProfile.fromJson(Map<String, dynamic> json) => CreatorProfile(
    author: _readStr(json, 'author'),
    version: _readStr(json, 'version'),
    tags: _readStringList(json['tags']),
    notes: _readStr(json, 'notes'),
    copyright: _readStr(json, 'copyright'),
  );

  Map<String, dynamic> toJson() {
    final map = _compact({
      'author': author,
      'version': version,
      'notes': notes,
      'copyright': copyright,
    });
    final cleanTags = [
      for (final tag in tags)
        if (tag.trim().isNotEmpty) tag.trim(),
    ];
    if (cleanTags.isNotEmpty) map['tags'] = cleanTags;
    return map;
  }

  bool get isEmpty =>
      author.trim().isEmpty &&
      version.trim().isEmpty &&
      tags.isEmpty &&
      notes.trim().isEmpty &&
      copyright.trim().isEmpty;

  CreatorProfile copyWith({
    String? author,
    String? version,
    List<String>? tags,
    String? notes,
    String? copyright,
  }) => CreatorProfile(
    author: author ?? this.author,
    version: version ?? this.version,
    tags: tags ?? this.tags,
    notes: notes ?? this.notes,
    copyright: copyright ?? this.copyright,
  );
}

/// 运行配置：直接参与提示词，但单独成条注入。
class RunConfigProfile {
  final String systemPrompt;
  final String postHistoryInstructions;

  const RunConfigProfile({
    this.systemPrompt = '',
    this.postHistoryInstructions = '',
  });

  factory RunConfigProfile.fromJson(Map<String, dynamic> json) =>
      RunConfigProfile(
        systemPrompt: _readStr(json, 'systemPrompt'),
        postHistoryInstructions: _readStr(json, 'postHistoryInstructions'),
      );

  Map<String, dynamic> toJson() => _compact({
    'systemPrompt': systemPrompt,
    'postHistoryInstructions': postHistoryInstructions,
  });

  bool get isEmpty =>
      systemPrompt.trim().isEmpty && postHistoryInstructions.trim().isEmpty;

  RunConfigProfile copyWith({
    String? systemPrompt,
    String? postHistoryInstructions,
  }) => RunConfigProfile(
    systemPrompt: systemPrompt ?? this.systemPrompt,
    postHistoryInstructions:
        postHistoryInstructions ?? this.postHistoryInstructions,
  );
}

/// 完整扩展档案。
class CharacterProfile {
  static const empty = CharacterProfile();

  static const _sectionKeys = {
    'v',
    'basic',
    'appearance',
    'background',
    'relationships',
    'language',
    'interaction',
    'creator',
    'runConfig',
  };

  final BasicProfile basic;
  final AppearanceProfile appearance;
  final BackgroundProfile background;
  final RelationshipProfile relationships;
  final LanguageProfile language;
  final InteractionProfile interaction;
  final CreatorProfile creator;
  final RunConfigProfile runConfig;

  /// 未知顶层键（未来版本新增的分区），原样保留。
  final Map<String, dynamic> extra;

  const CharacterProfile({
    this.basic = const BasicProfile(),
    this.appearance = const AppearanceProfile(),
    this.background = const BackgroundProfile(),
    this.relationships = const RelationshipProfile(),
    this.language = const LanguageProfile(),
    this.interaction = const InteractionProfile(),
    this.creator = const CreatorProfile(),
    this.runConfig = const RunConfigProfile(),
    this.extra = const {},
  });

  factory CharacterProfile.fromJson(Map<String, dynamic> json) {
    final extra = <String, dynamic>{
      for (final entry in json.entries)
        if (!_sectionKeys.contains(entry.key)) entry.key: entry.value,
    };
    return CharacterProfile(
      basic: BasicProfile.fromJson(_readMap(json['basic'])),
      appearance: AppearanceProfile.fromJson(_readMap(json['appearance'])),
      background: BackgroundProfile.fromJson(_readMap(json['background'])),
      relationships: RelationshipProfile.fromJson(
        _readMap(json['relationships']),
      ),
      language: LanguageProfile.fromJson(_readMap(json['language'])),
      interaction: InteractionProfile.fromJson(_readMap(json['interaction'])),
      creator: CreatorProfile.fromJson(_readMap(json['creator'])),
      runConfig: RunConfigProfile.fromJson(_readMap(json['runConfig'])),
      extra: Map<String, dynamic>.unmodifiable(extra),
    );
  }

  /// 容错解码：空串 / 坏 JSON / 非对象一律返回空档案。
  static CharacterProfile decode(String raw) {
    if (raw.trim().isEmpty) return empty;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return CharacterProfile.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      // 坏数据按空档案处理，不阻塞角色读取。
    }
    return empty;
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'v': 1};
    // 先写未知键，再写已知分区；同键时已知值优先。
    map.addAll(extra);
    final sections = <String, Map<String, dynamic>>{
      'basic': basic.toJson(),
      'appearance': appearance.toJson(),
      'background': background.toJson(),
      'relationships': relationships.toJson(),
      'language': language.toJson(),
      'interaction': interaction.toJson(),
      'creator': creator.toJson(),
      'runConfig': runConfig.toJson(),
    };
    for (final entry in sections.entries) {
      if (entry.value.isNotEmpty) map[entry.key] = entry.value;
    }
    return map;
  }

  String encode() => isEmpty ? '{}' : jsonEncode(toJson());

  bool get isEmpty =>
      basic.isEmpty &&
      appearance.isEmpty &&
      background.isEmpty &&
      relationships.isEmpty &&
      language.isEmpty &&
      interaction.isEmpty &&
      creator.isEmpty &&
      runConfig.isEmpty &&
      extra.isEmpty;

  /// 需要注入提示词的分区（不含创作者信息与运行配置）。
  ///
  /// 只输出非空字段；由 PromptAssembler 负责整体预算与截断。
  String get promptText {
    final lines = <String>[];
    void add(String label, String content) {
      if (content.trim().isNotEmpty) lines.add('$label：$content');
    }

    add(
      '身份',
      _labeled([
        ('昵称', basic.nickname),
        ('年龄', basic.age),
        ('性别', basic.gender),
        ('种族', basic.race),
        ('身份', basic.identity),
      ]),
    );
    add(
      '外貌',
      _labeled([
        ('概述', appearance.summary),
        ('发型', appearance.hair),
        ('瞳色', appearance.eyes),
        ('服饰', appearance.outfit),
        ('身高', appearance.height),
        ('体型', appearance.body),
        ('特征', appearance.features),
      ]),
    );
    add(
      '背景',
      _labeled([
        ('出身', background.origin),
        ('经历', background.experiences),
        ('重要事件', background.keyEvents),
        ('秘密', background.secrets),
        ('目标', background.goals),
      ]),
    );
    add(
      '与用户的关系',
      _labeled([
        ('关系', relationships.userRelation),
        ('初始亲密度', relationships.initialCloseness),
        ('关系走向', relationships.direction),
        ('其他关系', relationships.others),
      ]),
    );
    add(
      '语言风格',
      _labeled([
        ('语气', language.tone),
        ('说话习惯', language.habits),
        ('口癖', language.verbalTics),
        ('常用表达', language.commonPhrases),
        ('表达禁忌', language.taboos),
      ]),
    );
    add(
      '互动方式',
      _labeled([
        ('回复长度', interaction.replyLength),
        ('主动性', interaction.initiative),
        ('情绪表达', interaction.emotionExpression),
        ('行为倾向', interaction.behaviorTendency),
      ]),
    );
    return lines.join('\n');
  }

  CharacterProfile copyWith({
    BasicProfile? basic,
    AppearanceProfile? appearance,
    BackgroundProfile? background,
    RelationshipProfile? relationships,
    LanguageProfile? language,
    InteractionProfile? interaction,
    CreatorProfile? creator,
    RunConfigProfile? runConfig,
    Map<String, dynamic>? extra,
  }) => CharacterProfile(
    basic: basic ?? this.basic,
    appearance: appearance ?? this.appearance,
    background: background ?? this.background,
    relationships: relationships ?? this.relationships,
    language: language ?? this.language,
    interaction: interaction ?? this.interaction,
    creator: creator ?? this.creator,
    runConfig: runConfig ?? this.runConfig,
    extra: extra ?? this.extra,
  );
}

String _labeled(List<(String, String)> pairs) {
  final parts = <String>[];
  for (final (label, value) in pairs) {
    final v = value.trim();
    if (v.isNotEmpty) parts.add('$label $v');
  }
  return parts.join('；');
}

Map<String, dynamic> _compact(Map<String, String> source) {
  final out = <String, dynamic>{};
  for (final entry in source.entries) {
    if (entry.value.trim().isNotEmpty) out[entry.key] = entry.value;
  }
  return out;
}

Map<String, dynamic> _readMap(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

String _readStr(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return '';
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return '';
}

List<String> _readStringList(Object? value) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is String && item.trim().isNotEmpty) item.trim(),
  ];
}
