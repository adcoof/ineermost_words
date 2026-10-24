// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ConversationsTable extends Conversations
    with TableInfo<$ConversationsTable, ConversationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('新会话'),
  );
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<String> characterId = GeneratedColumn<String>(
    'character_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _petModelIdMeta = const VerificationMeta(
    'petModelId',
  );
  @override
  late final GeneratedColumn<String> petModelId = GeneratedColumn<String>(
    'pet_model_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _apiProfileIdMeta = const VerificationMeta(
    'apiProfileId',
  );
  @override
  late final GeneratedColumn<String> apiProfileId = GeneratedColumn<String>(
    'api_profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _voiceEnabledMeta = const VerificationMeta(
    'voiceEnabled',
  );
  @override
  late final GeneratedColumn<bool> voiceEnabled = GeneratedColumn<bool>(
    'voice_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("voice_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    characterId,
    petModelId,
    apiProfileId,
    createdAt,
    updatedAt,
    archived,
    voiceEnabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConversationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    }
    if (data.containsKey('pet_model_id')) {
      context.handle(
        _petModelIdMeta,
        petModelId.isAcceptableOrUnknown(
          data['pet_model_id']!,
          _petModelIdMeta,
        ),
      );
    }
    if (data.containsKey('api_profile_id')) {
      context.handle(
        _apiProfileIdMeta,
        apiProfileId.isAcceptableOrUnknown(
          data['api_profile_id']!,
          _apiProfileIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_apiProfileIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('voice_enabled')) {
      context.handle(
        _voiceEnabledMeta,
        voiceEnabled.isAcceptableOrUnknown(
          data['voice_enabled']!,
          _voiceEnabledMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConversationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConversationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character_id'],
      ),
      petModelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pet_model_id'],
      ),
      apiProfileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}api_profile_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      voiceEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}voice_enabled'],
      )!,
    );
  }

  @override
  $ConversationsTable createAlias(String alias) {
    return $ConversationsTable(attachedDatabase, alias);
  }
}

class ConversationRow extends DataClass implements Insertable<ConversationRow> {
  final String id;
  final String title;

  /// 绑定的角色卡 id（M2 起使用）。
  final String? characterId;

  /// 绑定的桌宠模型 id（M3 起使用）。
  final String? petModelId;

  /// 本会话使用的 API 供应商配置。
  final String apiProfileId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool archived;

  /// 本会话是否自动朗读（v6）：与全局 voice_enabled 相与决定实际发声。
  final bool voiceEnabled;
  const ConversationRow({
    required this.id,
    required this.title,
    this.characterId,
    this.petModelId,
    required this.apiProfileId,
    required this.createdAt,
    required this.updatedAt,
    required this.archived,
    required this.voiceEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || characterId != null) {
      map['character_id'] = Variable<String>(characterId);
    }
    if (!nullToAbsent || petModelId != null) {
      map['pet_model_id'] = Variable<String>(petModelId);
    }
    map['api_profile_id'] = Variable<String>(apiProfileId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['archived'] = Variable<bool>(archived);
    map['voice_enabled'] = Variable<bool>(voiceEnabled);
    return map;
  }

  ConversationsCompanion toCompanion(bool nullToAbsent) {
    return ConversationsCompanion(
      id: Value(id),
      title: Value(title),
      characterId: characterId == null && nullToAbsent
          ? const Value.absent()
          : Value(characterId),
      petModelId: petModelId == null && nullToAbsent
          ? const Value.absent()
          : Value(petModelId),
      apiProfileId: Value(apiProfileId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      archived: Value(archived),
      voiceEnabled: Value(voiceEnabled),
    );
  }

  factory ConversationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConversationRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      characterId: serializer.fromJson<String?>(json['characterId']),
      petModelId: serializer.fromJson<String?>(json['petModelId']),
      apiProfileId: serializer.fromJson<String>(json['apiProfileId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      archived: serializer.fromJson<bool>(json['archived']),
      voiceEnabled: serializer.fromJson<bool>(json['voiceEnabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'characterId': serializer.toJson<String?>(characterId),
      'petModelId': serializer.toJson<String?>(petModelId),
      'apiProfileId': serializer.toJson<String>(apiProfileId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'archived': serializer.toJson<bool>(archived),
      'voiceEnabled': serializer.toJson<bool>(voiceEnabled),
    };
  }

  ConversationRow copyWith({
    String? id,
    String? title,
    Value<String?> characterId = const Value.absent(),
    Value<String?> petModelId = const Value.absent(),
    String? apiProfileId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? archived,
    bool? voiceEnabled,
  }) => ConversationRow(
    id: id ?? this.id,
    title: title ?? this.title,
    characterId: characterId.present ? characterId.value : this.characterId,
    petModelId: petModelId.present ? petModelId.value : this.petModelId,
    apiProfileId: apiProfileId ?? this.apiProfileId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    archived: archived ?? this.archived,
    voiceEnabled: voiceEnabled ?? this.voiceEnabled,
  );
  ConversationRow copyWithCompanion(ConversationsCompanion data) {
    return ConversationRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      petModelId: data.petModelId.present
          ? data.petModelId.value
          : this.petModelId,
      apiProfileId: data.apiProfileId.present
          ? data.apiProfileId.value
          : this.apiProfileId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      archived: data.archived.present ? data.archived.value : this.archived,
      voiceEnabled: data.voiceEnabled.present
          ? data.voiceEnabled.value
          : this.voiceEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConversationRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('characterId: $characterId, ')
          ..write('petModelId: $petModelId, ')
          ..write('apiProfileId: $apiProfileId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archived: $archived, ')
          ..write('voiceEnabled: $voiceEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    characterId,
    petModelId,
    apiProfileId,
    createdAt,
    updatedAt,
    archived,
    voiceEnabled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConversationRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.characterId == this.characterId &&
          other.petModelId == this.petModelId &&
          other.apiProfileId == this.apiProfileId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.archived == this.archived &&
          other.voiceEnabled == this.voiceEnabled);
}

class ConversationsCompanion extends UpdateCompanion<ConversationRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> characterId;
  final Value<String?> petModelId;
  final Value<String> apiProfileId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> archived;
  final Value<bool> voiceEnabled;
  final Value<int> rowid;
  const ConversationsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.characterId = const Value.absent(),
    this.petModelId = const Value.absent(),
    this.apiProfileId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.archived = const Value.absent(),
    this.voiceEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationsCompanion.insert({
    required String id,
    this.title = const Value.absent(),
    this.characterId = const Value.absent(),
    this.petModelId = const Value.absent(),
    required String apiProfileId,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.archived = const Value.absent(),
    this.voiceEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       apiProfileId = Value(apiProfileId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ConversationRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? characterId,
    Expression<String>? petModelId,
    Expression<String>? apiProfileId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? archived,
    Expression<bool>? voiceEnabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (characterId != null) 'character_id': characterId,
      if (petModelId != null) 'pet_model_id': petModelId,
      if (apiProfileId != null) 'api_profile_id': apiProfileId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (archived != null) 'archived': archived,
      if (voiceEnabled != null) 'voice_enabled': voiceEnabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? characterId,
    Value<String?>? petModelId,
    Value<String>? apiProfileId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? archived,
    Value<bool>? voiceEnabled,
    Value<int>? rowid,
  }) {
    return ConversationsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      characterId: characterId ?? this.characterId,
      petModelId: petModelId ?? this.petModelId,
      apiProfileId: apiProfileId ?? this.apiProfileId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archived: archived ?? this.archived,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (characterId.present) {
      map['character_id'] = Variable<String>(characterId.value);
    }
    if (petModelId.present) {
      map['pet_model_id'] = Variable<String>(petModelId.value);
    }
    if (apiProfileId.present) {
      map['api_profile_id'] = Variable<String>(apiProfileId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (voiceEnabled.present) {
      map['voice_enabled'] = Variable<bool>(voiceEnabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('characterId: $characterId, ')
          ..write('petModelId: $petModelId, ')
          ..write('apiProfileId: $apiProfileId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archived: $archived, ')
          ..write('voiceEnabled: $voiceEnabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages
    with TableInfo<$MessagesTable, MessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _rawContentMeta = const VerificationMeta(
    'rawContent',
  );
  @override
  late final GeneratedColumn<String> rawContent = GeneratedColumn<String>(
    'raw_content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _emotionEventsMeta = const VerificationMeta(
    'emotionEvents',
  );
  @override
  late final GeneratedColumn<String> emotionEvents = GeneratedColumn<String>(
    'emotion_events',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('done'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    conversationId,
    role,
    content,
    rawContent,
    emotionEvents,
    status,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('raw_content')) {
      context.handle(
        _rawContentMeta,
        rawContent.isAcceptableOrUnknown(data['raw_content']!, _rawContentMeta),
      );
    }
    if (data.containsKey('emotion_events')) {
      context.handle(
        _emotionEventsMeta,
        emotionEvents.isAcceptableOrUnknown(
          data['emotion_events']!,
          _emotionEventsMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      rawContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_content'],
      )!,
      emotionEvents: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emotion_events'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class MessageRow extends DataClass implements Insertable<MessageRow> {
  final String id;
  final String conversationId;

  /// user | assistant | system
  final String role;
  final String content;
  final String rawContent;

  /// JSON 数组：情绪/动作事件（M2 起填充）。
  final String emotionEvents;

  /// streaming | done | error
  final String status;
  final DateTime createdAt;
  const MessageRow({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.rawContent,
    required this.emotionEvents,
    required this.status,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['conversation_id'] = Variable<String>(conversationId);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    map['raw_content'] = Variable<String>(rawContent);
    map['emotion_events'] = Variable<String>(emotionEvents);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      conversationId: Value(conversationId),
      role: Value(role),
      content: Value(content),
      rawContent: Value(rawContent),
      emotionEvents: Value(emotionEvents),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory MessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageRow(
      id: serializer.fromJson<String>(json['id']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      rawContent: serializer.fromJson<String>(json['rawContent']),
      emotionEvents: serializer.fromJson<String>(json['emotionEvents']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'conversationId': serializer.toJson<String>(conversationId),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'rawContent': serializer.toJson<String>(rawContent),
      'emotionEvents': serializer.toJson<String>(emotionEvents),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MessageRow copyWith({
    String? id,
    String? conversationId,
    String? role,
    String? content,
    String? rawContent,
    String? emotionEvents,
    String? status,
    DateTime? createdAt,
  }) => MessageRow(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    role: role ?? this.role,
    content: content ?? this.content,
    rawContent: rawContent ?? this.rawContent,
    emotionEvents: emotionEvents ?? this.emotionEvents,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
  MessageRow copyWithCompanion(MessagesCompanion data) {
    return MessageRow(
      id: data.id.present ? data.id.value : this.id,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      rawContent: data.rawContent.present
          ? data.rawContent.value
          : this.rawContent,
      emotionEvents: data.emotionEvents.present
          ? data.emotionEvents.value
          : this.emotionEvents,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageRow(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('rawContent: $rawContent, ')
          ..write('emotionEvents: $emotionEvents, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    conversationId,
    role,
    content,
    rawContent,
    emotionEvents,
    status,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageRow &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.role == this.role &&
          other.content == this.content &&
          other.rawContent == this.rawContent &&
          other.emotionEvents == this.emotionEvents &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class MessagesCompanion extends UpdateCompanion<MessageRow> {
  final Value<String> id;
  final Value<String> conversationId;
  final Value<String> role;
  final Value<String> content;
  final Value<String> rawContent;
  final Value<String> emotionEvents;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.rawContent = const Value.absent(),
    this.emotionEvents = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String id,
    required String conversationId,
    required String role,
    this.content = const Value.absent(),
    this.rawContent = const Value.absent(),
    this.emotionEvents = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       conversationId = Value(conversationId),
       role = Value(role),
       createdAt = Value(createdAt);
  static Insertable<MessageRow> custom({
    Expression<String>? id,
    Expression<String>? conversationId,
    Expression<String>? role,
    Expression<String>? content,
    Expression<String>? rawContent,
    Expression<String>? emotionEvents,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (rawContent != null) 'raw_content': rawContent,
      if (emotionEvents != null) 'emotion_events': emotionEvents,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? conversationId,
    Value<String>? role,
    Value<String>? content,
    Value<String>? rawContent,
    Value<String>? emotionEvents,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MessagesCompanion(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      rawContent: rawContent ?? this.rawContent,
      emotionEvents: emotionEvents ?? this.emotionEvents,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (rawContent.present) {
      map['raw_content'] = Variable<String>(rawContent.value);
    }
    if (emotionEvents.present) {
      map['emotion_events'] = Variable<String>(emotionEvents.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('rawContent: $rawContent, ')
          ..write('emotionEvents: $emotionEvents, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ApiProfilesTable extends ApiProfiles
    with TableInfo<$ApiProfilesTable, ApiProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ApiProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseUrlMeta = const VerificationMeta(
    'baseUrl',
  );
  @override
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
    'base_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _apiKeyMeta = const VerificationMeta('apiKey');
  @override
  late final GeneratedColumn<String> apiKey = GeneratedColumn<String>(
    'api_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _temperatureMeta = const VerificationMeta(
    'temperature',
  );
  @override
  late final GeneratedColumn<double> temperature = GeneratedColumn<double>(
    'temperature',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _maxTokensMeta = const VerificationMeta(
    'maxTokens',
  );
  @override
  late final GeneratedColumn<int> maxTokens = GeneratedColumn<int>(
    'max_tokens',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extraHeadersMeta = const VerificationMeta(
    'extraHeaders',
  );
  @override
  late final GeneratedColumn<String> extraHeaders = GeneratedColumn<String>(
    'extra_headers',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    baseUrl,
    apiKey,
    model,
    temperature,
    maxTokens,
    extraHeaders,
    isDefault,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'api_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ApiProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('base_url')) {
      context.handle(
        _baseUrlMeta,
        baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_baseUrlMeta);
    }
    if (data.containsKey('api_key')) {
      context.handle(
        _apiKeyMeta,
        apiKey.isAcceptableOrUnknown(data['api_key']!, _apiKeyMeta),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('temperature')) {
      context.handle(
        _temperatureMeta,
        temperature.isAcceptableOrUnknown(
          data['temperature']!,
          _temperatureMeta,
        ),
      );
    }
    if (data.containsKey('max_tokens')) {
      context.handle(
        _maxTokensMeta,
        maxTokens.isAcceptableOrUnknown(data['max_tokens']!, _maxTokensMeta),
      );
    }
    if (data.containsKey('extra_headers')) {
      context.handle(
        _extraHeadersMeta,
        extraHeaders.isAcceptableOrUnknown(
          data['extra_headers']!,
          _extraHeadersMeta,
        ),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ApiProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ApiProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      baseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_url'],
      )!,
      apiKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}api_key'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      temperature: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature'],
      )!,
      maxTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_tokens'],
      ),
      extraHeaders: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extra_headers'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
    );
  }

  @override
  $ApiProfilesTable createAlias(String alias) {
    return $ApiProfilesTable(attachedDatabase, alias);
  }
}

class ApiProfileRow extends DataClass implements Insertable<ApiProfileRow> {
  final String id;
  final String name;

  /// 形如 https://api.deepseek.com/v1 （不含 /chat/completions 后缀）。
  final String baseUrl;
  final String apiKey;
  final String model;
  final double temperature;
  final int? maxTokens;

  /// JSON 对象：额外请求头（覆盖中转站特殊鉴权）。
  final String extraHeaders;
  final bool isDefault;
  const ApiProfileRow({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.temperature,
    this.maxTokens,
    required this.extraHeaders,
    required this.isDefault,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['base_url'] = Variable<String>(baseUrl);
    map['api_key'] = Variable<String>(apiKey);
    map['model'] = Variable<String>(model);
    map['temperature'] = Variable<double>(temperature);
    if (!nullToAbsent || maxTokens != null) {
      map['max_tokens'] = Variable<int>(maxTokens);
    }
    map['extra_headers'] = Variable<String>(extraHeaders);
    map['is_default'] = Variable<bool>(isDefault);
    return map;
  }

  ApiProfilesCompanion toCompanion(bool nullToAbsent) {
    return ApiProfilesCompanion(
      id: Value(id),
      name: Value(name),
      baseUrl: Value(baseUrl),
      apiKey: Value(apiKey),
      model: Value(model),
      temperature: Value(temperature),
      maxTokens: maxTokens == null && nullToAbsent
          ? const Value.absent()
          : Value(maxTokens),
      extraHeaders: Value(extraHeaders),
      isDefault: Value(isDefault),
    );
  }

  factory ApiProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ApiProfileRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      baseUrl: serializer.fromJson<String>(json['baseUrl']),
      apiKey: serializer.fromJson<String>(json['apiKey']),
      model: serializer.fromJson<String>(json['model']),
      temperature: serializer.fromJson<double>(json['temperature']),
      maxTokens: serializer.fromJson<int?>(json['maxTokens']),
      extraHeaders: serializer.fromJson<String>(json['extraHeaders']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'baseUrl': serializer.toJson<String>(baseUrl),
      'apiKey': serializer.toJson<String>(apiKey),
      'model': serializer.toJson<String>(model),
      'temperature': serializer.toJson<double>(temperature),
      'maxTokens': serializer.toJson<int?>(maxTokens),
      'extraHeaders': serializer.toJson<String>(extraHeaders),
      'isDefault': serializer.toJson<bool>(isDefault),
    };
  }

  ApiProfileRow copyWith({
    String? id,
    String? name,
    String? baseUrl,
    String? apiKey,
    String? model,
    double? temperature,
    Value<int?> maxTokens = const Value.absent(),
    String? extraHeaders,
    bool? isDefault,
  }) => ApiProfileRow(
    id: id ?? this.id,
    name: name ?? this.name,
    baseUrl: baseUrl ?? this.baseUrl,
    apiKey: apiKey ?? this.apiKey,
    model: model ?? this.model,
    temperature: temperature ?? this.temperature,
    maxTokens: maxTokens.present ? maxTokens.value : this.maxTokens,
    extraHeaders: extraHeaders ?? this.extraHeaders,
    isDefault: isDefault ?? this.isDefault,
  );
  ApiProfileRow copyWithCompanion(ApiProfilesCompanion data) {
    return ApiProfileRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      apiKey: data.apiKey.present ? data.apiKey.value : this.apiKey,
      model: data.model.present ? data.model.value : this.model,
      temperature: data.temperature.present
          ? data.temperature.value
          : this.temperature,
      maxTokens: data.maxTokens.present ? data.maxTokens.value : this.maxTokens,
      extraHeaders: data.extraHeaders.present
          ? data.extraHeaders.value
          : this.extraHeaders,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ApiProfileRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('apiKey: $apiKey, ')
          ..write('model: $model, ')
          ..write('temperature: $temperature, ')
          ..write('maxTokens: $maxTokens, ')
          ..write('extraHeaders: $extraHeaders, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    baseUrl,
    apiKey,
    model,
    temperature,
    maxTokens,
    extraHeaders,
    isDefault,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApiProfileRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.baseUrl == this.baseUrl &&
          other.apiKey == this.apiKey &&
          other.model == this.model &&
          other.temperature == this.temperature &&
          other.maxTokens == this.maxTokens &&
          other.extraHeaders == this.extraHeaders &&
          other.isDefault == this.isDefault);
}

class ApiProfilesCompanion extends UpdateCompanion<ApiProfileRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> baseUrl;
  final Value<String> apiKey;
  final Value<String> model;
  final Value<double> temperature;
  final Value<int?> maxTokens;
  final Value<String> extraHeaders;
  final Value<bool> isDefault;
  final Value<int> rowid;
  const ApiProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.apiKey = const Value.absent(),
    this.model = const Value.absent(),
    this.temperature = const Value.absent(),
    this.maxTokens = const Value.absent(),
    this.extraHeaders = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ApiProfilesCompanion.insert({
    required String id,
    required String name,
    required String baseUrl,
    this.apiKey = const Value.absent(),
    required String model,
    this.temperature = const Value.absent(),
    this.maxTokens = const Value.absent(),
    this.extraHeaders = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       baseUrl = Value(baseUrl),
       model = Value(model);
  static Insertable<ApiProfileRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? baseUrl,
    Expression<String>? apiKey,
    Expression<String>? model,
    Expression<double>? temperature,
    Expression<int>? maxTokens,
    Expression<String>? extraHeaders,
    Expression<bool>? isDefault,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (baseUrl != null) 'base_url': baseUrl,
      if (apiKey != null) 'api_key': apiKey,
      if (model != null) 'model': model,
      if (temperature != null) 'temperature': temperature,
      if (maxTokens != null) 'max_tokens': maxTokens,
      if (extraHeaders != null) 'extra_headers': extraHeaders,
      if (isDefault != null) 'is_default': isDefault,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ApiProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? baseUrl,
    Value<String>? apiKey,
    Value<String>? model,
    Value<double>? temperature,
    Value<int?>? maxTokens,
    Value<String>? extraHeaders,
    Value<bool>? isDefault,
    Value<int>? rowid,
  }) {
    return ApiProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      extraHeaders: extraHeaders ?? this.extraHeaders,
      isDefault: isDefault ?? this.isDefault,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (apiKey.present) {
      map['api_key'] = Variable<String>(apiKey.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (temperature.present) {
      map['temperature'] = Variable<double>(temperature.value);
    }
    if (maxTokens.present) {
      map['max_tokens'] = Variable<int>(maxTokens.value);
    }
    if (extraHeaders.present) {
      map['extra_headers'] = Variable<String>(extraHeaders.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ApiProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('apiKey: $apiKey, ')
          ..write('model: $model, ')
          ..write('temperature: $temperature, ')
          ..write('maxTokens: $maxTokens, ')
          ..write('extraHeaders: $extraHeaders, ')
          ..write('isDefault: $isDefault, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CharactersTable extends Characters
    with TableInfo<$CharactersTable, CharacterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharactersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _personalityMeta = const VerificationMeta(
    'personality',
  );
  @override
  late final GeneratedColumn<String> personality = GeneratedColumn<String>(
    'personality',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _scenarioMeta = const VerificationMeta(
    'scenario',
  );
  @override
  late final GeneratedColumn<String> scenario = GeneratedColumn<String>(
    'scenario',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _firstMessageMeta = const VerificationMeta(
    'firstMessage',
  );
  @override
  late final GeneratedColumn<String> firstMessage = GeneratedColumn<String>(
    'first_message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _exampleDialogueMeta = const VerificationMeta(
    'exampleDialogue',
  );
  @override
  late final GeneratedColumn<String> exampleDialogue = GeneratedColumn<String>(
    'example_dialogue',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _avatarPathMeta = const VerificationMeta(
    'avatarPath',
  );
  @override
  late final GeneratedColumn<String> avatarPath = GeneratedColumn<String>(
    'avatar_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memorySummaryMeta = const VerificationMeta(
    'memorySummary',
  );
  @override
  late final GeneratedColumn<String> memorySummary = GeneratedColumn<String>(
    'memory_summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _memoryUpdatedAtMeta = const VerificationMeta(
    'memoryUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> memoryUpdatedAt =
      GeneratedColumn<DateTime>(
        'memory_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    personality,
    scenario,
    firstMessage,
    exampleDialogue,
    avatarPath,
    source,
    createdAt,
    updatedAt,
    memorySummary,
    memoryUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'characters';
  @override
  VerificationContext validateIntegrity(
    Insertable<CharacterRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('personality')) {
      context.handle(
        _personalityMeta,
        personality.isAcceptableOrUnknown(
          data['personality']!,
          _personalityMeta,
        ),
      );
    }
    if (data.containsKey('scenario')) {
      context.handle(
        _scenarioMeta,
        scenario.isAcceptableOrUnknown(data['scenario']!, _scenarioMeta),
      );
    }
    if (data.containsKey('first_message')) {
      context.handle(
        _firstMessageMeta,
        firstMessage.isAcceptableOrUnknown(
          data['first_message']!,
          _firstMessageMeta,
        ),
      );
    }
    if (data.containsKey('example_dialogue')) {
      context.handle(
        _exampleDialogueMeta,
        exampleDialogue.isAcceptableOrUnknown(
          data['example_dialogue']!,
          _exampleDialogueMeta,
        ),
      );
    }
    if (data.containsKey('avatar_path')) {
      context.handle(
        _avatarPathMeta,
        avatarPath.isAcceptableOrUnknown(data['avatar_path']!, _avatarPathMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('memory_summary')) {
      context.handle(
        _memorySummaryMeta,
        memorySummary.isAcceptableOrUnknown(
          data['memory_summary']!,
          _memorySummaryMeta,
        ),
      );
    }
    if (data.containsKey('memory_updated_at')) {
      context.handle(
        _memoryUpdatedAtMeta,
        memoryUpdatedAt.isAcceptableOrUnknown(
          data['memory_updated_at']!,
          _memoryUpdatedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CharacterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharacterRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      personality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}personality'],
      )!,
      scenario: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scenario'],
      )!,
      firstMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_message'],
      )!,
      exampleDialogue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example_dialogue'],
      )!,
      avatarPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_path'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      memorySummary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memory_summary'],
      )!,
      memoryUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}memory_updated_at'],
      ),
    );
  }

  @override
  $CharactersTable createAlias(String alias) {
    return $CharactersTable(attachedDatabase, alias);
  }
}

class CharacterRow extends DataClass implements Insertable<CharacterRow> {
  final String id;
  final String name;
  final String description;
  final String personality;
  final String scenario;

  /// 开场白（SillyTavern first_mes）；绑定角色建会话时作为 assistant 消息插入。
  final String firstMessage;
  final String exampleDialogue;

  /// 立绘文件绝对路径。
  final String? avatarPath;

  /// manual | st_v2
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 跨会话长期记忆（LLM 摘要，第一人称要点，v6）。
  /// 注意：CharacterRepository.save 是整行 upsert，本列不进 Character
  /// 领域模型，只经 getMemory/setMemory 读写，防止编辑角色卡时覆盖。
  final String memorySummary;

  /// 记忆水位线：该时点（含）之前的 done 消息已纳入摘要；null=从未摘要。
  final DateTime? memoryUpdatedAt;
  const CharacterRow({
    required this.id,
    required this.name,
    required this.description,
    required this.personality,
    required this.scenario,
    required this.firstMessage,
    required this.exampleDialogue,
    this.avatarPath,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    required this.memorySummary,
    this.memoryUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['personality'] = Variable<String>(personality);
    map['scenario'] = Variable<String>(scenario);
    map['first_message'] = Variable<String>(firstMessage);
    map['example_dialogue'] = Variable<String>(exampleDialogue);
    if (!nullToAbsent || avatarPath != null) {
      map['avatar_path'] = Variable<String>(avatarPath);
    }
    map['source'] = Variable<String>(source);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['memory_summary'] = Variable<String>(memorySummary);
    if (!nullToAbsent || memoryUpdatedAt != null) {
      map['memory_updated_at'] = Variable<DateTime>(memoryUpdatedAt);
    }
    return map;
  }

  CharactersCompanion toCompanion(bool nullToAbsent) {
    return CharactersCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      personality: Value(personality),
      scenario: Value(scenario),
      firstMessage: Value(firstMessage),
      exampleDialogue: Value(exampleDialogue),
      avatarPath: avatarPath == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarPath),
      source: Value(source),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      memorySummary: Value(memorySummary),
      memoryUpdatedAt: memoryUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(memoryUpdatedAt),
    );
  }

  factory CharacterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharacterRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      personality: serializer.fromJson<String>(json['personality']),
      scenario: serializer.fromJson<String>(json['scenario']),
      firstMessage: serializer.fromJson<String>(json['firstMessage']),
      exampleDialogue: serializer.fromJson<String>(json['exampleDialogue']),
      avatarPath: serializer.fromJson<String?>(json['avatarPath']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      memorySummary: serializer.fromJson<String>(json['memorySummary']),
      memoryUpdatedAt: serializer.fromJson<DateTime?>(json['memoryUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'personality': serializer.toJson<String>(personality),
      'scenario': serializer.toJson<String>(scenario),
      'firstMessage': serializer.toJson<String>(firstMessage),
      'exampleDialogue': serializer.toJson<String>(exampleDialogue),
      'avatarPath': serializer.toJson<String?>(avatarPath),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'memorySummary': serializer.toJson<String>(memorySummary),
      'memoryUpdatedAt': serializer.toJson<DateTime?>(memoryUpdatedAt),
    };
  }

  CharacterRow copyWith({
    String? id,
    String? name,
    String? description,
    String? personality,
    String? scenario,
    String? firstMessage,
    String? exampleDialogue,
    Value<String?> avatarPath = const Value.absent(),
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? memorySummary,
    Value<DateTime?> memoryUpdatedAt = const Value.absent(),
  }) => CharacterRow(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    personality: personality ?? this.personality,
    scenario: scenario ?? this.scenario,
    firstMessage: firstMessage ?? this.firstMessage,
    exampleDialogue: exampleDialogue ?? this.exampleDialogue,
    avatarPath: avatarPath.present ? avatarPath.value : this.avatarPath,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    memorySummary: memorySummary ?? this.memorySummary,
    memoryUpdatedAt: memoryUpdatedAt.present
        ? memoryUpdatedAt.value
        : this.memoryUpdatedAt,
  );
  CharacterRow copyWithCompanion(CharactersCompanion data) {
    return CharacterRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      personality: data.personality.present
          ? data.personality.value
          : this.personality,
      scenario: data.scenario.present ? data.scenario.value : this.scenario,
      firstMessage: data.firstMessage.present
          ? data.firstMessage.value
          : this.firstMessage,
      exampleDialogue: data.exampleDialogue.present
          ? data.exampleDialogue.value
          : this.exampleDialogue,
      avatarPath: data.avatarPath.present
          ? data.avatarPath.value
          : this.avatarPath,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      memorySummary: data.memorySummary.present
          ? data.memorySummary.value
          : this.memorySummary,
      memoryUpdatedAt: data.memoryUpdatedAt.present
          ? data.memoryUpdatedAt.value
          : this.memoryUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharacterRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('personality: $personality, ')
          ..write('scenario: $scenario, ')
          ..write('firstMessage: $firstMessage, ')
          ..write('exampleDialogue: $exampleDialogue, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('memorySummary: $memorySummary, ')
          ..write('memoryUpdatedAt: $memoryUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    personality,
    scenario,
    firstMessage,
    exampleDialogue,
    avatarPath,
    source,
    createdAt,
    updatedAt,
    memorySummary,
    memoryUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.personality == this.personality &&
          other.scenario == this.scenario &&
          other.firstMessage == this.firstMessage &&
          other.exampleDialogue == this.exampleDialogue &&
          other.avatarPath == this.avatarPath &&
          other.source == this.source &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.memorySummary == this.memorySummary &&
          other.memoryUpdatedAt == this.memoryUpdatedAt);
}

class CharactersCompanion extends UpdateCompanion<CharacterRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> description;
  final Value<String> personality;
  final Value<String> scenario;
  final Value<String> firstMessage;
  final Value<String> exampleDialogue;
  final Value<String?> avatarPath;
  final Value<String> source;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> memorySummary;
  final Value<DateTime?> memoryUpdatedAt;
  final Value<int> rowid;
  const CharactersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.personality = const Value.absent(),
    this.scenario = const Value.absent(),
    this.firstMessage = const Value.absent(),
    this.exampleDialogue = const Value.absent(),
    this.avatarPath = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.memorySummary = const Value.absent(),
    this.memoryUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CharactersCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.personality = const Value.absent(),
    this.scenario = const Value.absent(),
    this.firstMessage = const Value.absent(),
    this.exampleDialogue = const Value.absent(),
    this.avatarPath = const Value.absent(),
    this.source = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.memorySummary = const Value.absent(),
    this.memoryUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CharacterRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? personality,
    Expression<String>? scenario,
    Expression<String>? firstMessage,
    Expression<String>? exampleDialogue,
    Expression<String>? avatarPath,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? memorySummary,
    Expression<DateTime>? memoryUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (personality != null) 'personality': personality,
      if (scenario != null) 'scenario': scenario,
      if (firstMessage != null) 'first_message': firstMessage,
      if (exampleDialogue != null) 'example_dialogue': exampleDialogue,
      if (avatarPath != null) 'avatar_path': avatarPath,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (memorySummary != null) 'memory_summary': memorySummary,
      if (memoryUpdatedAt != null) 'memory_updated_at': memoryUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CharactersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? description,
    Value<String>? personality,
    Value<String>? scenario,
    Value<String>? firstMessage,
    Value<String>? exampleDialogue,
    Value<String?>? avatarPath,
    Value<String>? source,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? memorySummary,
    Value<DateTime?>? memoryUpdatedAt,
    Value<int>? rowid,
  }) {
    return CharactersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      personality: personality ?? this.personality,
      scenario: scenario ?? this.scenario,
      firstMessage: firstMessage ?? this.firstMessage,
      exampleDialogue: exampleDialogue ?? this.exampleDialogue,
      avatarPath: avatarPath ?? this.avatarPath,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      memorySummary: memorySummary ?? this.memorySummary,
      memoryUpdatedAt: memoryUpdatedAt ?? this.memoryUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (personality.present) {
      map['personality'] = Variable<String>(personality.value);
    }
    if (scenario.present) {
      map['scenario'] = Variable<String>(scenario.value);
    }
    if (firstMessage.present) {
      map['first_message'] = Variable<String>(firstMessage.value);
    }
    if (exampleDialogue.present) {
      map['example_dialogue'] = Variable<String>(exampleDialogue.value);
    }
    if (avatarPath.present) {
      map['avatar_path'] = Variable<String>(avatarPath.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (memorySummary.present) {
      map['memory_summary'] = Variable<String>(memorySummary.value);
    }
    if (memoryUpdatedAt.present) {
      map['memory_updated_at'] = Variable<DateTime>(memoryUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharactersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('personality: $personality, ')
          ..write('scenario: $scenario, ')
          ..write('firstMessage: $firstMessage, ')
          ..write('exampleDialogue: $exampleDialogue, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('memorySummary: $memorySummary, ')
          ..write('memoryUpdatedAt: $memoryUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PetModelsTable extends PetModels
    with TableInfo<$PetModelsTable, PetModelRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PetModelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dirPathMeta = const VerificationMeta(
    'dirPath',
  );
  @override
  late final GeneratedColumn<String> dirPath = GeneratedColumn<String>(
    'dir_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryJsonPathMeta = const VerificationMeta(
    'entryJsonPath',
  );
  @override
  late final GeneratedColumn<String> entryJsonPath = GeneratedColumn<String>(
    'entry_json_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbnailPathMeta = const VerificationMeta(
    'thumbnailPath',
  );
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
    'thumbnail_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expressionsMeta = const VerificationMeta(
    'expressions',
  );
  @override
  late final GeneratedColumn<String> expressions = GeneratedColumn<String>(
    'expressions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _motionGroupsMeta = const VerificationMeta(
    'motionGroups',
  );
  @override
  late final GeneratedColumn<String> motionGroups = GeneratedColumn<String>(
    'motion_groups',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    dirPath,
    entryJsonPath,
    thumbnailPath,
    expressions,
    motionGroups,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pet_models';
  @override
  VerificationContext validateIntegrity(
    Insertable<PetModelRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('dir_path')) {
      context.handle(
        _dirPathMeta,
        dirPath.isAcceptableOrUnknown(data['dir_path']!, _dirPathMeta),
      );
    } else if (isInserting) {
      context.missing(_dirPathMeta);
    }
    if (data.containsKey('entry_json_path')) {
      context.handle(
        _entryJsonPathMeta,
        entryJsonPath.isAcceptableOrUnknown(
          data['entry_json_path']!,
          _entryJsonPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_entryJsonPathMeta);
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
        _thumbnailPathMeta,
        thumbnailPath.isAcceptableOrUnknown(
          data['thumbnail_path']!,
          _thumbnailPathMeta,
        ),
      );
    }
    if (data.containsKey('expressions')) {
      context.handle(
        _expressionsMeta,
        expressions.isAcceptableOrUnknown(
          data['expressions']!,
          _expressionsMeta,
        ),
      );
    }
    if (data.containsKey('motion_groups')) {
      context.handle(
        _motionGroupsMeta,
        motionGroups.isAcceptableOrUnknown(
          data['motion_groups']!,
          _motionGroupsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PetModelRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PetModelRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      dirPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dir_path'],
      )!,
      entryJsonPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_json_path'],
      )!,
      thumbnailPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_path'],
      ),
      expressions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expressions'],
      )!,
      motionGroups: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}motion_groups'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PetModelsTable createAlias(String alias) {
    return $PetModelsTable(attachedDatabase, alias);
  }
}

class PetModelRow extends DataClass implements Insertable<PetModelRow> {
  final String id;
  final String name;

  /// 解压目录绝对路径。
  final String dirPath;

  /// model3.json 绝对路径。
  final String entryJsonPath;
  final String? thumbnailPath;

  /// JSON 数组：表情 id 列表。
  final String expressions;

  /// JSON 对象：动作组名 → 数量。
  final String motionGroups;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PetModelRow({
    required this.id,
    required this.name,
    required this.dirPath,
    required this.entryJsonPath,
    this.thumbnailPath,
    required this.expressions,
    required this.motionGroups,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['dir_path'] = Variable<String>(dirPath);
    map['entry_json_path'] = Variable<String>(entryJsonPath);
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    map['expressions'] = Variable<String>(expressions);
    map['motion_groups'] = Variable<String>(motionGroups);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PetModelsCompanion toCompanion(bool nullToAbsent) {
    return PetModelsCompanion(
      id: Value(id),
      name: Value(name),
      dirPath: Value(dirPath),
      entryJsonPath: Value(entryJsonPath),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      expressions: Value(expressions),
      motionGroups: Value(motionGroups),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PetModelRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PetModelRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      dirPath: serializer.fromJson<String>(json['dirPath']),
      entryJsonPath: serializer.fromJson<String>(json['entryJsonPath']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      expressions: serializer.fromJson<String>(json['expressions']),
      motionGroups: serializer.fromJson<String>(json['motionGroups']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'dirPath': serializer.toJson<String>(dirPath),
      'entryJsonPath': serializer.toJson<String>(entryJsonPath),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'expressions': serializer.toJson<String>(expressions),
      'motionGroups': serializer.toJson<String>(motionGroups),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PetModelRow copyWith({
    String? id,
    String? name,
    String? dirPath,
    String? entryJsonPath,
    Value<String?> thumbnailPath = const Value.absent(),
    String? expressions,
    String? motionGroups,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PetModelRow(
    id: id ?? this.id,
    name: name ?? this.name,
    dirPath: dirPath ?? this.dirPath,
    entryJsonPath: entryJsonPath ?? this.entryJsonPath,
    thumbnailPath: thumbnailPath.present
        ? thumbnailPath.value
        : this.thumbnailPath,
    expressions: expressions ?? this.expressions,
    motionGroups: motionGroups ?? this.motionGroups,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PetModelRow copyWithCompanion(PetModelsCompanion data) {
    return PetModelRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      dirPath: data.dirPath.present ? data.dirPath.value : this.dirPath,
      entryJsonPath: data.entryJsonPath.present
          ? data.entryJsonPath.value
          : this.entryJsonPath,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      expressions: data.expressions.present
          ? data.expressions.value
          : this.expressions,
      motionGroups: data.motionGroups.present
          ? data.motionGroups.value
          : this.motionGroups,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PetModelRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('dirPath: $dirPath, ')
          ..write('entryJsonPath: $entryJsonPath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('expressions: $expressions, ')
          ..write('motionGroups: $motionGroups, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    dirPath,
    entryJsonPath,
    thumbnailPath,
    expressions,
    motionGroups,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PetModelRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.dirPath == this.dirPath &&
          other.entryJsonPath == this.entryJsonPath &&
          other.thumbnailPath == this.thumbnailPath &&
          other.expressions == this.expressions &&
          other.motionGroups == this.motionGroups &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PetModelsCompanion extends UpdateCompanion<PetModelRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> dirPath;
  final Value<String> entryJsonPath;
  final Value<String?> thumbnailPath;
  final Value<String> expressions;
  final Value<String> motionGroups;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PetModelsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.dirPath = const Value.absent(),
    this.entryJsonPath = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.expressions = const Value.absent(),
    this.motionGroups = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PetModelsCompanion.insert({
    required String id,
    required String name,
    required String dirPath,
    required String entryJsonPath,
    this.thumbnailPath = const Value.absent(),
    this.expressions = const Value.absent(),
    this.motionGroups = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       dirPath = Value(dirPath),
       entryJsonPath = Value(entryJsonPath),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PetModelRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? dirPath,
    Expression<String>? entryJsonPath,
    Expression<String>? thumbnailPath,
    Expression<String>? expressions,
    Expression<String>? motionGroups,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (dirPath != null) 'dir_path': dirPath,
      if (entryJsonPath != null) 'entry_json_path': entryJsonPath,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (expressions != null) 'expressions': expressions,
      if (motionGroups != null) 'motion_groups': motionGroups,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PetModelsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? dirPath,
    Value<String>? entryJsonPath,
    Value<String?>? thumbnailPath,
    Value<String>? expressions,
    Value<String>? motionGroups,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PetModelsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      dirPath: dirPath ?? this.dirPath,
      entryJsonPath: entryJsonPath ?? this.entryJsonPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      expressions: expressions ?? this.expressions,
      motionGroups: motionGroups ?? this.motionGroups,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (dirPath.present) {
      map['dir_path'] = Variable<String>(dirPath.value);
    }
    if (entryJsonPath.present) {
      map['entry_json_path'] = Variable<String>(entryJsonPath.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (expressions.present) {
      map['expressions'] = Variable<String>(expressions.value);
    }
    if (motionGroups.present) {
      map['motion_groups'] = Variable<String>(motionGroups.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PetModelsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('dirPath: $dirPath, ')
          ..write('entryJsonPath: $entryJsonPath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('expressions: $expressions, ')
          ..write('motionGroups: $motionGroups, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EmotionMappingsTable extends EmotionMappings
    with TableInfo<$EmotionMappingsTable, EmotionMappingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmotionMappingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _petModelIdMeta = const VerificationMeta(
    'petModelId',
  );
  @override
  late final GeneratedColumn<String> petModelId = GeneratedColumn<String>(
    'pet_model_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionTypeMeta = const VerificationMeta(
    'actionType',
  );
  @override
  late final GeneratedColumn<String> actionType = GeneratedColumn<String>(
    'action_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    petModelId,
    tag,
    actionType,
    targetId,
    priority,
    enabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'emotion_mappings';
  @override
  VerificationContext validateIntegrity(
    Insertable<EmotionMappingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pet_model_id')) {
      context.handle(
        _petModelIdMeta,
        petModelId.isAcceptableOrUnknown(
          data['pet_model_id']!,
          _petModelIdMeta,
        ),
      );
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    } else if (isInserting) {
      context.missing(_tagMeta);
    }
    if (data.containsKey('action_type')) {
      context.handle(
        _actionTypeMeta,
        actionType.isAcceptableOrUnknown(data['action_type']!, _actionTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_actionTypeMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EmotionMappingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmotionMappingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      petModelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pet_model_id'],
      ),
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      )!,
      actionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_type'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
    );
  }

  @override
  $EmotionMappingsTable createAlias(String alias) {
    return $EmotionMappingsTable(attachedDatabase, alias);
  }
}

class EmotionMappingRow extends DataClass
    implements Insertable<EmotionMappingRow> {
  final String id;
  final String? petModelId;
  final String tag;

  /// expression | motion
  final String actionType;

  /// expression：表情 id；motion：动作组名或 组名:序号。
  final String targetId;
  final int priority;
  final bool enabled;
  const EmotionMappingRow({
    required this.id,
    this.petModelId,
    required this.tag,
    required this.actionType,
    required this.targetId,
    required this.priority,
    required this.enabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || petModelId != null) {
      map['pet_model_id'] = Variable<String>(petModelId);
    }
    map['tag'] = Variable<String>(tag);
    map['action_type'] = Variable<String>(actionType);
    map['target_id'] = Variable<String>(targetId);
    map['priority'] = Variable<int>(priority);
    map['enabled'] = Variable<bool>(enabled);
    return map;
  }

  EmotionMappingsCompanion toCompanion(bool nullToAbsent) {
    return EmotionMappingsCompanion(
      id: Value(id),
      petModelId: petModelId == null && nullToAbsent
          ? const Value.absent()
          : Value(petModelId),
      tag: Value(tag),
      actionType: Value(actionType),
      targetId: Value(targetId),
      priority: Value(priority),
      enabled: Value(enabled),
    );
  }

  factory EmotionMappingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmotionMappingRow(
      id: serializer.fromJson<String>(json['id']),
      petModelId: serializer.fromJson<String?>(json['petModelId']),
      tag: serializer.fromJson<String>(json['tag']),
      actionType: serializer.fromJson<String>(json['actionType']),
      targetId: serializer.fromJson<String>(json['targetId']),
      priority: serializer.fromJson<int>(json['priority']),
      enabled: serializer.fromJson<bool>(json['enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'petModelId': serializer.toJson<String?>(petModelId),
      'tag': serializer.toJson<String>(tag),
      'actionType': serializer.toJson<String>(actionType),
      'targetId': serializer.toJson<String>(targetId),
      'priority': serializer.toJson<int>(priority),
      'enabled': serializer.toJson<bool>(enabled),
    };
  }

  EmotionMappingRow copyWith({
    String? id,
    Value<String?> petModelId = const Value.absent(),
    String? tag,
    String? actionType,
    String? targetId,
    int? priority,
    bool? enabled,
  }) => EmotionMappingRow(
    id: id ?? this.id,
    petModelId: petModelId.present ? petModelId.value : this.petModelId,
    tag: tag ?? this.tag,
    actionType: actionType ?? this.actionType,
    targetId: targetId ?? this.targetId,
    priority: priority ?? this.priority,
    enabled: enabled ?? this.enabled,
  );
  EmotionMappingRow copyWithCompanion(EmotionMappingsCompanion data) {
    return EmotionMappingRow(
      id: data.id.present ? data.id.value : this.id,
      petModelId: data.petModelId.present
          ? data.petModelId.value
          : this.petModelId,
      tag: data.tag.present ? data.tag.value : this.tag,
      actionType: data.actionType.present
          ? data.actionType.value
          : this.actionType,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      priority: data.priority.present ? data.priority.value : this.priority,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmotionMappingRow(')
          ..write('id: $id, ')
          ..write('petModelId: $petModelId, ')
          ..write('tag: $tag, ')
          ..write('actionType: $actionType, ')
          ..write('targetId: $targetId, ')
          ..write('priority: $priority, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, petModelId, tag, actionType, targetId, priority, enabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmotionMappingRow &&
          other.id == this.id &&
          other.petModelId == this.petModelId &&
          other.tag == this.tag &&
          other.actionType == this.actionType &&
          other.targetId == this.targetId &&
          other.priority == this.priority &&
          other.enabled == this.enabled);
}

class EmotionMappingsCompanion extends UpdateCompanion<EmotionMappingRow> {
  final Value<String> id;
  final Value<String?> petModelId;
  final Value<String> tag;
  final Value<String> actionType;
  final Value<String> targetId;
  final Value<int> priority;
  final Value<bool> enabled;
  final Value<int> rowid;
  const EmotionMappingsCompanion({
    this.id = const Value.absent(),
    this.petModelId = const Value.absent(),
    this.tag = const Value.absent(),
    this.actionType = const Value.absent(),
    this.targetId = const Value.absent(),
    this.priority = const Value.absent(),
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EmotionMappingsCompanion.insert({
    required String id,
    this.petModelId = const Value.absent(),
    required String tag,
    required String actionType,
    required String targetId,
    this.priority = const Value.absent(),
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tag = Value(tag),
       actionType = Value(actionType),
       targetId = Value(targetId);
  static Insertable<EmotionMappingRow> custom({
    Expression<String>? id,
    Expression<String>? petModelId,
    Expression<String>? tag,
    Expression<String>? actionType,
    Expression<String>? targetId,
    Expression<int>? priority,
    Expression<bool>? enabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (petModelId != null) 'pet_model_id': petModelId,
      if (tag != null) 'tag': tag,
      if (actionType != null) 'action_type': actionType,
      if (targetId != null) 'target_id': targetId,
      if (priority != null) 'priority': priority,
      if (enabled != null) 'enabled': enabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EmotionMappingsCompanion copyWith({
    Value<String>? id,
    Value<String?>? petModelId,
    Value<String>? tag,
    Value<String>? actionType,
    Value<String>? targetId,
    Value<int>? priority,
    Value<bool>? enabled,
    Value<int>? rowid,
  }) {
    return EmotionMappingsCompanion(
      id: id ?? this.id,
      petModelId: petModelId ?? this.petModelId,
      tag: tag ?? this.tag,
      actionType: actionType ?? this.actionType,
      targetId: targetId ?? this.targetId,
      priority: priority ?? this.priority,
      enabled: enabled ?? this.enabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (petModelId.present) {
      map['pet_model_id'] = Variable<String>(petModelId.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (actionType.present) {
      map['action_type'] = Variable<String>(actionType.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmotionMappingsCompanion(')
          ..write('id: $id, ')
          ..write('petModelId: $petModelId, ')
          ..write('tag: $tag, ')
          ..write('actionType: $actionType, ')
          ..write('targetId: $targetId, ')
          ..write('priority: $priority, ')
          ..write('enabled: $enabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TtsProfilesTable extends TtsProfiles
    with TableInfo<$TtsProfilesTable, TtsProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TtsProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _voiceIdMeta = const VerificationMeta(
    'voiceId',
  );
  @override
  late final GeneratedColumn<String> voiceId = GeneratedColumn<String>(
    'voice_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  @override
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
    'speed',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _apiKeyMeta = const VerificationMeta('apiKey');
  @override
  late final GeneratedColumn<String> apiKey = GeneratedColumn<String>(
    'api_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _baseUrlMeta = const VerificationMeta(
    'baseUrl',
  );
  @override
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
    'base_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    provider,
    voiceId,
    speed,
    model,
    apiKey,
    baseUrl,
    isDefault,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tts_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<TtsProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('voice_id')) {
      context.handle(
        _voiceIdMeta,
        voiceId.isAcceptableOrUnknown(data['voice_id']!, _voiceIdMeta),
      );
    }
    if (data.containsKey('speed')) {
      context.handle(
        _speedMeta,
        speed.isAcceptableOrUnknown(data['speed']!, _speedMeta),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('api_key')) {
      context.handle(
        _apiKeyMeta,
        apiKey.isAcceptableOrUnknown(data['api_key']!, _apiKeyMeta),
      );
    }
    if (data.containsKey('base_url')) {
      context.handle(
        _baseUrlMeta,
        baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TtsProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TtsProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      voiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voice_id'],
      )!,
      speed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      apiKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}api_key'],
      )!,
      baseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_url'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
    );
  }

  @override
  $TtsProfilesTable createAlias(String alias) {
    return $TtsProfilesTable(attachedDatabase, alias);
  }
}

class TtsProfileRow extends DataClass implements Insertable<TtsProfileRow> {
  final String id;
  final String name;

  /// edge | openai | system
  final String provider;

  /// 发音人（edge: zh-CN-XiaoxiaoNeural 等；openai: alloy 等；system: 引擎语音 id）。
  final String voiceId;

  /// 语速倍率。
  final double speed;

  /// openai 提供商的模型名（如 tts-1）。
  final String model;

  /// openai 提供商专用 apiKey/baseUrl（为空时回落到默认聊天 API 配置）。
  final String apiKey;
  final String baseUrl;
  final bool isDefault;
  const TtsProfileRow({
    required this.id,
    required this.name,
    required this.provider,
    required this.voiceId,
    required this.speed,
    required this.model,
    required this.apiKey,
    required this.baseUrl,
    required this.isDefault,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['provider'] = Variable<String>(provider);
    map['voice_id'] = Variable<String>(voiceId);
    map['speed'] = Variable<double>(speed);
    map['model'] = Variable<String>(model);
    map['api_key'] = Variable<String>(apiKey);
    map['base_url'] = Variable<String>(baseUrl);
    map['is_default'] = Variable<bool>(isDefault);
    return map;
  }

  TtsProfilesCompanion toCompanion(bool nullToAbsent) {
    return TtsProfilesCompanion(
      id: Value(id),
      name: Value(name),
      provider: Value(provider),
      voiceId: Value(voiceId),
      speed: Value(speed),
      model: Value(model),
      apiKey: Value(apiKey),
      baseUrl: Value(baseUrl),
      isDefault: Value(isDefault),
    );
  }

  factory TtsProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TtsProfileRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      provider: serializer.fromJson<String>(json['provider']),
      voiceId: serializer.fromJson<String>(json['voiceId']),
      speed: serializer.fromJson<double>(json['speed']),
      model: serializer.fromJson<String>(json['model']),
      apiKey: serializer.fromJson<String>(json['apiKey']),
      baseUrl: serializer.fromJson<String>(json['baseUrl']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'provider': serializer.toJson<String>(provider),
      'voiceId': serializer.toJson<String>(voiceId),
      'speed': serializer.toJson<double>(speed),
      'model': serializer.toJson<String>(model),
      'apiKey': serializer.toJson<String>(apiKey),
      'baseUrl': serializer.toJson<String>(baseUrl),
      'isDefault': serializer.toJson<bool>(isDefault),
    };
  }

  TtsProfileRow copyWith({
    String? id,
    String? name,
    String? provider,
    String? voiceId,
    double? speed,
    String? model,
    String? apiKey,
    String? baseUrl,
    bool? isDefault,
  }) => TtsProfileRow(
    id: id ?? this.id,
    name: name ?? this.name,
    provider: provider ?? this.provider,
    voiceId: voiceId ?? this.voiceId,
    speed: speed ?? this.speed,
    model: model ?? this.model,
    apiKey: apiKey ?? this.apiKey,
    baseUrl: baseUrl ?? this.baseUrl,
    isDefault: isDefault ?? this.isDefault,
  );
  TtsProfileRow copyWithCompanion(TtsProfilesCompanion data) {
    return TtsProfileRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      provider: data.provider.present ? data.provider.value : this.provider,
      voiceId: data.voiceId.present ? data.voiceId.value : this.voiceId,
      speed: data.speed.present ? data.speed.value : this.speed,
      model: data.model.present ? data.model.value : this.model,
      apiKey: data.apiKey.present ? data.apiKey.value : this.apiKey,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TtsProfileRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('provider: $provider, ')
          ..write('voiceId: $voiceId, ')
          ..write('speed: $speed, ')
          ..write('model: $model, ')
          ..write('apiKey: $apiKey, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    provider,
    voiceId,
    speed,
    model,
    apiKey,
    baseUrl,
    isDefault,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TtsProfileRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.provider == this.provider &&
          other.voiceId == this.voiceId &&
          other.speed == this.speed &&
          other.model == this.model &&
          other.apiKey == this.apiKey &&
          other.baseUrl == this.baseUrl &&
          other.isDefault == this.isDefault);
}

class TtsProfilesCompanion extends UpdateCompanion<TtsProfileRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> provider;
  final Value<String> voiceId;
  final Value<double> speed;
  final Value<String> model;
  final Value<String> apiKey;
  final Value<String> baseUrl;
  final Value<bool> isDefault;
  final Value<int> rowid;
  const TtsProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.provider = const Value.absent(),
    this.voiceId = const Value.absent(),
    this.speed = const Value.absent(),
    this.model = const Value.absent(),
    this.apiKey = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TtsProfilesCompanion.insert({
    required String id,
    required String name,
    required String provider,
    this.voiceId = const Value.absent(),
    this.speed = const Value.absent(),
    this.model = const Value.absent(),
    this.apiKey = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       provider = Value(provider);
  static Insertable<TtsProfileRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? provider,
    Expression<String>? voiceId,
    Expression<double>? speed,
    Expression<String>? model,
    Expression<String>? apiKey,
    Expression<String>? baseUrl,
    Expression<bool>? isDefault,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (provider != null) 'provider': provider,
      if (voiceId != null) 'voice_id': voiceId,
      if (speed != null) 'speed': speed,
      if (model != null) 'model': model,
      if (apiKey != null) 'api_key': apiKey,
      if (baseUrl != null) 'base_url': baseUrl,
      if (isDefault != null) 'is_default': isDefault,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TtsProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? provider,
    Value<String>? voiceId,
    Value<double>? speed,
    Value<String>? model,
    Value<String>? apiKey,
    Value<String>? baseUrl,
    Value<bool>? isDefault,
    Value<int>? rowid,
  }) {
    return TtsProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      voiceId: voiceId ?? this.voiceId,
      speed: speed ?? this.speed,
      model: model ?? this.model,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      isDefault: isDefault ?? this.isDefault,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (voiceId.present) {
      map['voice_id'] = Variable<String>(voiceId.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (apiKey.present) {
      map['api_key'] = Variable<String>(apiKey.value);
    }
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TtsProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('provider: $provider, ')
          ..write('voiceId: $voiceId, ')
          ..write('speed: $speed, ')
          ..write('model: $model, ')
          ..write('apiKey: $apiKey, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('isDefault: $isDefault, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomVoicesTable extends CustomVoices
    with TableInfo<$CustomVoicesTable, CustomVoiceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomVoicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_voices';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomVoiceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomVoiceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomVoiceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CustomVoicesTable createAlias(String alias) {
    return $CustomVoicesTable(attachedDatabase, alias);
  }
}

class CustomVoiceRow extends DataClass implements Insertable<CustomVoiceRow> {
  final String id;

  /// 显示名（如「萝莉音」「磁性男声」）。
  final String name;

  /// 音色描述（如「温柔甜美的年轻女声，语速稍慢」）。
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CustomVoiceRow({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CustomVoicesCompanion toCompanion(bool nullToAbsent) {
    return CustomVoicesCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CustomVoiceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomVoiceRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CustomVoiceRow copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CustomVoiceRow(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CustomVoiceRow copyWithCompanion(CustomVoicesCompanion data) {
    return CustomVoiceRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomVoiceRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomVoiceRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CustomVoicesCompanion extends UpdateCompanion<CustomVoiceRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> description;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CustomVoicesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomVoicesCompanion.insert({
    required String id,
    required String name,
    required String description,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       description = Value(description),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CustomVoiceRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomVoicesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? description,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CustomVoicesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomVoicesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ConversationsTable conversations = $ConversationsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $ApiProfilesTable apiProfiles = $ApiProfilesTable(this);
  late final $CharactersTable characters = $CharactersTable(this);
  late final $PetModelsTable petModels = $PetModelsTable(this);
  late final $EmotionMappingsTable emotionMappings = $EmotionMappingsTable(
    this,
  );
  late final $TtsProfilesTable ttsProfiles = $TtsProfilesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $CustomVoicesTable customVoices = $CustomVoicesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    conversations,
    messages,
    apiProfiles,
    characters,
    petModels,
    emotionMappings,
    ttsProfiles,
    settings,
    customVoices,
  ];
}

typedef $$ConversationsTableCreateCompanionBuilder =
    ConversationsCompanion Function({
      required String id,
      Value<String> title,
      Value<String?> characterId,
      Value<String?> petModelId,
      required String apiProfileId,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<bool> archived,
      Value<bool> voiceEnabled,
      Value<int> rowid,
    });
typedef $$ConversationsTableUpdateCompanionBuilder =
    ConversationsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> characterId,
      Value<String?> petModelId,
      Value<String> apiProfileId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> archived,
      Value<bool> voiceEnabled,
      Value<int> rowid,
    });

class $$ConversationsTableFilterComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get petModelId => $composableBuilder(
    column: $table.petModelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get apiProfileId => $composableBuilder(
    column: $table.apiProfileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get voiceEnabled => $composableBuilder(
    column: $table.voiceEnabled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConversationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get petModelId => $composableBuilder(
    column: $table.petModelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get apiProfileId => $composableBuilder(
    column: $table.apiProfileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get voiceEnabled => $composableBuilder(
    column: $table.voiceEnabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConversationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get petModelId => $composableBuilder(
    column: $table.petModelId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get apiProfileId => $composableBuilder(
    column: $table.apiProfileId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<bool> get voiceEnabled => $composableBuilder(
    column: $table.voiceEnabled,
    builder: (column) => column,
  );
}

class $$ConversationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConversationsTable,
          ConversationRow,
          $$ConversationsTableFilterComposer,
          $$ConversationsTableOrderingComposer,
          $$ConversationsTableAnnotationComposer,
          $$ConversationsTableCreateCompanionBuilder,
          $$ConversationsTableUpdateCompanionBuilder,
          (
            ConversationRow,
            BaseReferences<_$AppDatabase, $ConversationsTable, ConversationRow>,
          ),
          ConversationRow,
          PrefetchHooks Function()
        > {
  $$ConversationsTableTableManager(_$AppDatabase db, $ConversationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> characterId = const Value.absent(),
                Value<String?> petModelId = const Value.absent(),
                Value<String> apiProfileId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<bool> voiceEnabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion(
                id: id,
                title: title,
                characterId: characterId,
                petModelId: petModelId,
                apiProfileId: apiProfileId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archived: archived,
                voiceEnabled: voiceEnabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> title = const Value.absent(),
                Value<String?> characterId = const Value.absent(),
                Value<String?> petModelId = const Value.absent(),
                required String apiProfileId,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> archived = const Value.absent(),
                Value<bool> voiceEnabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion.insert(
                id: id,
                title: title,
                characterId: characterId,
                petModelId: petModelId,
                apiProfileId: apiProfileId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archived: archived,
                voiceEnabled: voiceEnabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ConversationsTable, ConversationRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ConversationsTable,
                    ConversationRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConversationsTable,
      ConversationRow,
      $$ConversationsTableFilterComposer,
      $$ConversationsTableOrderingComposer,
      $$ConversationsTableAnnotationComposer,
      $$ConversationsTableCreateCompanionBuilder,
      $$ConversationsTableUpdateCompanionBuilder,
      (
        ConversationRow,
        BaseReferences<_$AppDatabase, $ConversationsTable, ConversationRow>,
      ),
      ConversationRow,
      PrefetchHooks Function()
    >;
typedef $$MessagesTableCreateCompanionBuilder = MessagesCompanion Function({
  required String id,
  required String conversationId,
  required String role,
  Value<String> content,
  Value<String> rawContent,
  Value<String> emotionEvents,
  Value<String> status,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$MessagesTableUpdateCompanionBuilder = MessagesCompanion Function({
  Value<String> id,
  Value<String> conversationId,
  Value<String> role,
  Value<String> content,
  Value<String> rawContent,
  Value<String> emotionEvents,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawContent => $composableBuilder(
    column: $table.rawContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emotionEvents => $composableBuilder(
    column: $table.emotionEvents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawContent => $composableBuilder(
    column: $table.rawContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emotionEvents => $composableBuilder(
    column: $table.emotionEvents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get rawContent => $composableBuilder(
    column: $table.rawContent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get emotionEvents => $composableBuilder(
    column: $table.emotionEvents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          MessageRow,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (
            MessageRow,
            BaseReferences<_$AppDatabase, $MessagesTable, MessageRow>,
          ),
          MessageRow,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> rawContent = const Value.absent(),
                Value<String> emotionEvents = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                conversationId: conversationId,
                role: role,
                content: content,
                rawContent: rawContent,
                emotionEvents: emotionEvents,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String conversationId,
                required String role,
                Value<String> content = const Value.absent(),
                Value<String> rawContent = const Value.absent(),
                Value<String> emotionEvents = const Value.absent(),
                Value<String> status = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion.insert(
                id: id,
                conversationId: conversationId,
                role: role,
                content: content,
                rawContent: rawContent,
                emotionEvents: emotionEvents,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MessagesTable, MessageRow>(table),
                  BaseReferences<_$AppDatabase, $MessagesTable, MessageRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      MessageRow,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (MessageRow, BaseReferences<_$AppDatabase, $MessagesTable, MessageRow>),
      MessageRow,
      PrefetchHooks Function()
    >;
typedef $$ApiProfilesTableCreateCompanionBuilder =
    ApiProfilesCompanion Function({
      required String id,
      required String name,
      required String baseUrl,
      Value<String> apiKey,
      required String model,
      Value<double> temperature,
      Value<int?> maxTokens,
      Value<String> extraHeaders,
      Value<bool> isDefault,
      Value<int> rowid,
    });
typedef $$ApiProfilesTableUpdateCompanionBuilder =
    ApiProfilesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> baseUrl,
      Value<String> apiKey,
      Value<String> model,
      Value<double> temperature,
      Value<int?> maxTokens,
      Value<String> extraHeaders,
      Value<bool> isDefault,
      Value<int> rowid,
    });

class $$ApiProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ApiProfilesTable> {
  $$ApiProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get apiKey => $composableBuilder(
    column: $table.apiKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxTokens => $composableBuilder(
    column: $table.maxTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extraHeaders => $composableBuilder(
    column: $table.extraHeaders,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ApiProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ApiProfilesTable> {
  $$ApiProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get apiKey => $composableBuilder(
    column: $table.apiKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxTokens => $composableBuilder(
    column: $table.maxTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extraHeaders => $composableBuilder(
    column: $table.extraHeaders,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ApiProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ApiProfilesTable> {
  $$ApiProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<String> get apiKey =>
      $composableBuilder(column: $table.apiKey, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxTokens =>
      $composableBuilder(column: $table.maxTokens, builder: (column) => column);

  GeneratedColumn<String> get extraHeaders => $composableBuilder(
    column: $table.extraHeaders,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);
}

class $$ApiProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ApiProfilesTable,
          ApiProfileRow,
          $$ApiProfilesTableFilterComposer,
          $$ApiProfilesTableOrderingComposer,
          $$ApiProfilesTableAnnotationComposer,
          $$ApiProfilesTableCreateCompanionBuilder,
          $$ApiProfilesTableUpdateCompanionBuilder,
          (
            ApiProfileRow,
            BaseReferences<_$AppDatabase, $ApiProfilesTable, ApiProfileRow>,
          ),
          ApiProfileRow,
          PrefetchHooks Function()
        > {
  $$ApiProfilesTableTableManager(_$AppDatabase db, $ApiProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ApiProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ApiProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ApiProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> baseUrl = const Value.absent(),
                Value<String> apiKey = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<double> temperature = const Value.absent(),
                Value<int?> maxTokens = const Value.absent(),
                Value<String> extraHeaders = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ApiProfilesCompanion(
                id: id,
                name: name,
                baseUrl: baseUrl,
                apiKey: apiKey,
                model: model,
                temperature: temperature,
                maxTokens: maxTokens,
                extraHeaders: extraHeaders,
                isDefault: isDefault,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String baseUrl,
                Value<String> apiKey = const Value.absent(),
                required String model,
                Value<double> temperature = const Value.absent(),
                Value<int?> maxTokens = const Value.absent(),
                Value<String> extraHeaders = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ApiProfilesCompanion.insert(
                id: id,
                name: name,
                baseUrl: baseUrl,
                apiKey: apiKey,
                model: model,
                temperature: temperature,
                maxTokens: maxTokens,
                extraHeaders: extraHeaders,
                isDefault: isDefault,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ApiProfilesTable, ApiProfileRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ApiProfilesTable,
                    ApiProfileRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ApiProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ApiProfilesTable,
      ApiProfileRow,
      $$ApiProfilesTableFilterComposer,
      $$ApiProfilesTableOrderingComposer,
      $$ApiProfilesTableAnnotationComposer,
      $$ApiProfilesTableCreateCompanionBuilder,
      $$ApiProfilesTableUpdateCompanionBuilder,
      (
        ApiProfileRow,
        BaseReferences<_$AppDatabase, $ApiProfilesTable, ApiProfileRow>,
      ),
      ApiProfileRow,
      PrefetchHooks Function()
    >;
typedef $$CharactersTableCreateCompanionBuilder = CharactersCompanion Function({
  required String id,
  required String name,
  Value<String> description,
  Value<String> personality,
  Value<String> scenario,
  Value<String> firstMessage,
  Value<String> exampleDialogue,
  Value<String?> avatarPath,
  Value<String> source,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String> memorySummary,
  Value<DateTime?> memoryUpdatedAt,
  Value<int> rowid,
});
typedef $$CharactersTableUpdateCompanionBuilder = CharactersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> description,
  Value<String> personality,
  Value<String> scenario,
  Value<String> firstMessage,
  Value<String> exampleDialogue,
  Value<String?> avatarPath,
  Value<String> source,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> memorySummary,
  Value<DateTime?> memoryUpdatedAt,
  Value<int> rowid,
});

class $$CharactersTableFilterComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personality => $composableBuilder(
    column: $table.personality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scenario => $composableBuilder(
    column: $table.scenario,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstMessage => $composableBuilder(
    column: $table.firstMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exampleDialogue => $composableBuilder(
    column: $table.exampleDialogue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memorySummary => $composableBuilder(
    column: $table.memorySummary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get memoryUpdatedAt => $composableBuilder(
    column: $table.memoryUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CharactersTableOrderingComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personality => $composableBuilder(
    column: $table.personality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scenario => $composableBuilder(
    column: $table.scenario,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstMessage => $composableBuilder(
    column: $table.firstMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exampleDialogue => $composableBuilder(
    column: $table.exampleDialogue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memorySummary => $composableBuilder(
    column: $table.memorySummary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get memoryUpdatedAt => $composableBuilder(
    column: $table.memoryUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CharactersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CharactersTable> {
  $$CharactersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get personality => $composableBuilder(
    column: $table.personality,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scenario =>
      $composableBuilder(column: $table.scenario, builder: (column) => column);

  GeneratedColumn<String> get firstMessage => $composableBuilder(
    column: $table.firstMessage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exampleDialogue => $composableBuilder(
    column: $table.exampleDialogue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get memorySummary => $composableBuilder(
    column: $table.memorySummary,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get memoryUpdatedAt => $composableBuilder(
    column: $table.memoryUpdatedAt,
    builder: (column) => column,
  );
}

class $$CharactersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CharactersTable,
          CharacterRow,
          $$CharactersTableFilterComposer,
          $$CharactersTableOrderingComposer,
          $$CharactersTableAnnotationComposer,
          $$CharactersTableCreateCompanionBuilder,
          $$CharactersTableUpdateCompanionBuilder,
          (
            CharacterRow,
            BaseReferences<_$AppDatabase, $CharactersTable, CharacterRow>,
          ),
          CharacterRow,
          PrefetchHooks Function()
        > {
  $$CharactersTableTableManager(_$AppDatabase db, $CharactersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharactersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharactersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharactersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> personality = const Value.absent(),
                Value<String> scenario = const Value.absent(),
                Value<String> firstMessage = const Value.absent(),
                Value<String> exampleDialogue = const Value.absent(),
                Value<String?> avatarPath = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> memorySummary = const Value.absent(),
                Value<DateTime?> memoryUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharactersCompanion(
                id: id,
                name: name,
                description: description,
                personality: personality,
                scenario: scenario,
                firstMessage: firstMessage,
                exampleDialogue: exampleDialogue,
                avatarPath: avatarPath,
                source: source,
                createdAt: createdAt,
                updatedAt: updatedAt,
                memorySummary: memorySummary,
                memoryUpdatedAt: memoryUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> description = const Value.absent(),
                Value<String> personality = const Value.absent(),
                Value<String> scenario = const Value.absent(),
                Value<String> firstMessage = const Value.absent(),
                Value<String> exampleDialogue = const Value.absent(),
                Value<String?> avatarPath = const Value.absent(),
                Value<String> source = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String> memorySummary = const Value.absent(),
                Value<DateTime?> memoryUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharactersCompanion.insert(
                id: id,
                name: name,
                description: description,
                personality: personality,
                scenario: scenario,
                firstMessage: firstMessage,
                exampleDialogue: exampleDialogue,
                avatarPath: avatarPath,
                source: source,
                createdAt: createdAt,
                updatedAt: updatedAt,
                memorySummary: memorySummary,
                memoryUpdatedAt: memoryUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CharactersTable, CharacterRow>(table),
                  BaseReferences<_$AppDatabase, $CharactersTable, CharacterRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CharactersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CharactersTable,
      CharacterRow,
      $$CharactersTableFilterComposer,
      $$CharactersTableOrderingComposer,
      $$CharactersTableAnnotationComposer,
      $$CharactersTableCreateCompanionBuilder,
      $$CharactersTableUpdateCompanionBuilder,
      (
        CharacterRow,
        BaseReferences<_$AppDatabase, $CharactersTable, CharacterRow>,
      ),
      CharacterRow,
      PrefetchHooks Function()
    >;
typedef $$PetModelsTableCreateCompanionBuilder = PetModelsCompanion Function({
  required String id,
  required String name,
  required String dirPath,
  required String entryJsonPath,
  Value<String?> thumbnailPath,
  Value<String> expressions,
  Value<String> motionGroups,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$PetModelsTableUpdateCompanionBuilder = PetModelsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> dirPath,
  Value<String> entryJsonPath,
  Value<String?> thumbnailPath,
  Value<String> expressions,
  Value<String> motionGroups,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$PetModelsTableFilterComposer
    extends Composer<_$AppDatabase, $PetModelsTable> {
  $$PetModelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dirPath => $composableBuilder(
    column: $table.dirPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryJsonPath => $composableBuilder(
    column: $table.entryJsonPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expressions => $composableBuilder(
    column: $table.expressions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get motionGroups => $composableBuilder(
    column: $table.motionGroups,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PetModelsTableOrderingComposer
    extends Composer<_$AppDatabase, $PetModelsTable> {
  $$PetModelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dirPath => $composableBuilder(
    column: $table.dirPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryJsonPath => $composableBuilder(
    column: $table.entryJsonPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expressions => $composableBuilder(
    column: $table.expressions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motionGroups => $composableBuilder(
    column: $table.motionGroups,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PetModelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PetModelsTable> {
  $$PetModelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get dirPath =>
      $composableBuilder(column: $table.dirPath, builder: (column) => column);

  GeneratedColumn<String> get entryJsonPath => $composableBuilder(
    column: $table.entryJsonPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get expressions => $composableBuilder(
    column: $table.expressions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get motionGroups => $composableBuilder(
    column: $table.motionGroups,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PetModelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PetModelsTable,
          PetModelRow,
          $$PetModelsTableFilterComposer,
          $$PetModelsTableOrderingComposer,
          $$PetModelsTableAnnotationComposer,
          $$PetModelsTableCreateCompanionBuilder,
          $$PetModelsTableUpdateCompanionBuilder,
          (
            PetModelRow,
            BaseReferences<_$AppDatabase, $PetModelsTable, PetModelRow>,
          ),
          PetModelRow,
          PrefetchHooks Function()
        > {
  $$PetModelsTableTableManager(_$AppDatabase db, $PetModelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PetModelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PetModelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PetModelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> dirPath = const Value.absent(),
                Value<String> entryJsonPath = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                Value<String> expressions = const Value.absent(),
                Value<String> motionGroups = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PetModelsCompanion(
                id: id,
                name: name,
                dirPath: dirPath,
                entryJsonPath: entryJsonPath,
                thumbnailPath: thumbnailPath,
                expressions: expressions,
                motionGroups: motionGroups,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String dirPath,
                required String entryJsonPath,
                Value<String?> thumbnailPath = const Value.absent(),
                Value<String> expressions = const Value.absent(),
                Value<String> motionGroups = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PetModelsCompanion.insert(
                id: id,
                name: name,
                dirPath: dirPath,
                entryJsonPath: entryJsonPath,
                thumbnailPath: thumbnailPath,
                expressions: expressions,
                motionGroups: motionGroups,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PetModelsTable, PetModelRow>(table),
                  BaseReferences<_$AppDatabase, $PetModelsTable, PetModelRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PetModelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PetModelsTable,
      PetModelRow,
      $$PetModelsTableFilterComposer,
      $$PetModelsTableOrderingComposer,
      $$PetModelsTableAnnotationComposer,
      $$PetModelsTableCreateCompanionBuilder,
      $$PetModelsTableUpdateCompanionBuilder,
      (
        PetModelRow,
        BaseReferences<_$AppDatabase, $PetModelsTable, PetModelRow>,
      ),
      PetModelRow,
      PrefetchHooks Function()
    >;
typedef $$EmotionMappingsTableCreateCompanionBuilder =
    EmotionMappingsCompanion Function({
      required String id,
      Value<String?> petModelId,
      required String tag,
      required String actionType,
      required String targetId,
      Value<int> priority,
      Value<bool> enabled,
      Value<int> rowid,
    });
typedef $$EmotionMappingsTableUpdateCompanionBuilder =
    EmotionMappingsCompanion Function({
      Value<String> id,
      Value<String?> petModelId,
      Value<String> tag,
      Value<String> actionType,
      Value<String> targetId,
      Value<int> priority,
      Value<bool> enabled,
      Value<int> rowid,
    });

class $$EmotionMappingsTableFilterComposer
    extends Composer<_$AppDatabase, $EmotionMappingsTable> {
  $$EmotionMappingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get petModelId => $composableBuilder(
    column: $table.petModelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EmotionMappingsTableOrderingComposer
    extends Composer<_$AppDatabase, $EmotionMappingsTable> {
  $$EmotionMappingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get petModelId => $composableBuilder(
    column: $table.petModelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EmotionMappingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmotionMappingsTable> {
  $$EmotionMappingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get petModelId => $composableBuilder(
    column: $table.petModelId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  GeneratedColumn<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);
}

class $$EmotionMappingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EmotionMappingsTable,
          EmotionMappingRow,
          $$EmotionMappingsTableFilterComposer,
          $$EmotionMappingsTableOrderingComposer,
          $$EmotionMappingsTableAnnotationComposer,
          $$EmotionMappingsTableCreateCompanionBuilder,
          $$EmotionMappingsTableUpdateCompanionBuilder,
          (
            EmotionMappingRow,
            BaseReferences<
              _$AppDatabase,
              $EmotionMappingsTable,
              EmotionMappingRow
            >,
          ),
          EmotionMappingRow,
          PrefetchHooks Function()
        > {
  $$EmotionMappingsTableTableManager(
    _$AppDatabase db,
    $EmotionMappingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmotionMappingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmotionMappingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmotionMappingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> petModelId = const Value.absent(),
                Value<String> tag = const Value.absent(),
                Value<String> actionType = const Value.absent(),
                Value<String> targetId = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EmotionMappingsCompanion(
                id: id,
                petModelId: petModelId,
                tag: tag,
                actionType: actionType,
                targetId: targetId,
                priority: priority,
                enabled: enabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> petModelId = const Value.absent(),
                required String tag,
                required String actionType,
                required String targetId,
                Value<int> priority = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EmotionMappingsCompanion.insert(
                id: id,
                petModelId: petModelId,
                tag: tag,
                actionType: actionType,
                targetId: targetId,
                priority: priority,
                enabled: enabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EmotionMappingsTable, EmotionMappingRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $EmotionMappingsTable,
                    EmotionMappingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EmotionMappingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EmotionMappingsTable,
      EmotionMappingRow,
      $$EmotionMappingsTableFilterComposer,
      $$EmotionMappingsTableOrderingComposer,
      $$EmotionMappingsTableAnnotationComposer,
      $$EmotionMappingsTableCreateCompanionBuilder,
      $$EmotionMappingsTableUpdateCompanionBuilder,
      (
        EmotionMappingRow,
        BaseReferences<_$AppDatabase, $EmotionMappingsTable, EmotionMappingRow>,
      ),
      EmotionMappingRow,
      PrefetchHooks Function()
    >;
typedef $$TtsProfilesTableCreateCompanionBuilder =
    TtsProfilesCompanion Function({
      required String id,
      required String name,
      required String provider,
      Value<String> voiceId,
      Value<double> speed,
      Value<String> model,
      Value<String> apiKey,
      Value<String> baseUrl,
      Value<bool> isDefault,
      Value<int> rowid,
    });
typedef $$TtsProfilesTableUpdateCompanionBuilder =
    TtsProfilesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> provider,
      Value<String> voiceId,
      Value<double> speed,
      Value<String> model,
      Value<String> apiKey,
      Value<String> baseUrl,
      Value<bool> isDefault,
      Value<int> rowid,
    });

class $$TtsProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $TtsProfilesTable> {
  $$TtsProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voiceId => $composableBuilder(
    column: $table.voiceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get apiKey => $composableBuilder(
    column: $table.apiKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TtsProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $TtsProfilesTable> {
  $$TtsProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voiceId => $composableBuilder(
    column: $table.voiceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get apiKey => $composableBuilder(
    column: $table.apiKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TtsProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TtsProfilesTable> {
  $$TtsProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get voiceId =>
      $composableBuilder(column: $table.voiceId, builder: (column) => column);

  GeneratedColumn<double> get speed =>
      $composableBuilder(column: $table.speed, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get apiKey =>
      $composableBuilder(column: $table.apiKey, builder: (column) => column);

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);
}

class $$TtsProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TtsProfilesTable,
          TtsProfileRow,
          $$TtsProfilesTableFilterComposer,
          $$TtsProfilesTableOrderingComposer,
          $$TtsProfilesTableAnnotationComposer,
          $$TtsProfilesTableCreateCompanionBuilder,
          $$TtsProfilesTableUpdateCompanionBuilder,
          (
            TtsProfileRow,
            BaseReferences<_$AppDatabase, $TtsProfilesTable, TtsProfileRow>,
          ),
          TtsProfileRow,
          PrefetchHooks Function()
        > {
  $$TtsProfilesTableTableManager(_$AppDatabase db, $TtsProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TtsProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TtsProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TtsProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> provider = const Value.absent(),
                Value<String> voiceId = const Value.absent(),
                Value<double> speed = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<String> apiKey = const Value.absent(),
                Value<String> baseUrl = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TtsProfilesCompanion(
                id: id,
                name: name,
                provider: provider,
                voiceId: voiceId,
                speed: speed,
                model: model,
                apiKey: apiKey,
                baseUrl: baseUrl,
                isDefault: isDefault,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String provider,
                Value<String> voiceId = const Value.absent(),
                Value<double> speed = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<String> apiKey = const Value.absent(),
                Value<String> baseUrl = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TtsProfilesCompanion.insert(
                id: id,
                name: name,
                provider: provider,
                voiceId: voiceId,
                speed: speed,
                model: model,
                apiKey: apiKey,
                baseUrl: baseUrl,
                isDefault: isDefault,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TtsProfilesTable, TtsProfileRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $TtsProfilesTable,
                    TtsProfileRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TtsProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TtsProfilesTable,
      TtsProfileRow,
      $$TtsProfilesTableFilterComposer,
      $$TtsProfilesTableOrderingComposer,
      $$TtsProfilesTableAnnotationComposer,
      $$TtsProfilesTableCreateCompanionBuilder,
      $$TtsProfilesTableUpdateCompanionBuilder,
      (
        TtsProfileRow,
        BaseReferences<_$AppDatabase, $TtsProfilesTable, TtsProfileRow>,
      ),
      TtsProfileRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          SettingRow,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, SettingRow>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      SettingRow,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
      SettingRow,
      PrefetchHooks Function()
    >;
typedef $$CustomVoicesTableCreateCompanionBuilder =
    CustomVoicesCompanion Function({
      required String id,
      required String name,
      required String description,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CustomVoicesTableUpdateCompanionBuilder =
    CustomVoicesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> description,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CustomVoicesTableFilterComposer
    extends Composer<_$AppDatabase, $CustomVoicesTable> {
  $$CustomVoicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomVoicesTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomVoicesTable> {
  $$CustomVoicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomVoicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomVoicesTable> {
  $$CustomVoicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CustomVoicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomVoicesTable,
          CustomVoiceRow,
          $$CustomVoicesTableFilterComposer,
          $$CustomVoicesTableOrderingComposer,
          $$CustomVoicesTableAnnotationComposer,
          $$CustomVoicesTableCreateCompanionBuilder,
          $$CustomVoicesTableUpdateCompanionBuilder,
          (
            CustomVoiceRow,
            BaseReferences<_$AppDatabase, $CustomVoicesTable, CustomVoiceRow>,
          ),
          CustomVoiceRow,
          PrefetchHooks Function()
        > {
  $$CustomVoicesTableTableManager(_$AppDatabase db, $CustomVoicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomVoicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomVoicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomVoicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomVoicesCompanion(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String description,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CustomVoicesCompanion.insert(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CustomVoicesTable, CustomVoiceRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CustomVoicesTable,
                    CustomVoiceRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomVoicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomVoicesTable,
      CustomVoiceRow,
      $$CustomVoicesTableFilterComposer,
      $$CustomVoicesTableOrderingComposer,
      $$CustomVoicesTableAnnotationComposer,
      $$CustomVoicesTableCreateCompanionBuilder,
      $$CustomVoicesTableUpdateCompanionBuilder,
      (
        CustomVoiceRow,
        BaseReferences<_$AppDatabase, $CustomVoicesTable, CustomVoiceRow>,
      ),
      CustomVoiceRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db, _db.conversations);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$ApiProfilesTableTableManager get apiProfiles =>
      $$ApiProfilesTableTableManager(_db, _db.apiProfiles);
  $$CharactersTableTableManager get characters =>
      $$CharactersTableTableManager(_db, _db.characters);
  $$PetModelsTableTableManager get petModels =>
      $$PetModelsTableTableManager(_db, _db.petModels);
  $$EmotionMappingsTableTableManager get emotionMappings =>
      $$EmotionMappingsTableTableManager(_db, _db.emotionMappings);
  $$TtsProfilesTableTableManager get ttsProfiles =>
      $$TtsProfilesTableTableManager(_db, _db.ttsProfiles);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$CustomVoicesTableTableManager get customVoices =>
      $$CustomVoicesTableTableManager(_db, _db.customVoices);
}
