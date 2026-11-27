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
  static const VerificationMeta _backgroundPathMeta = const VerificationMeta(
    'backgroundPath',
  );
  @override
  late final GeneratedColumn<String> backgroundPath = GeneratedColumn<String>(
    'background_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentConversationIdMeta =
      const VerificationMeta('parentConversationId');
  @override
  late final GeneratedColumn<String> parentConversationId =
      GeneratedColumn<String>(
        'parent_conversation_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _branchFromMessageIdMeta =
      const VerificationMeta('branchFromMessageId');
  @override
  late final GeneratedColumn<String> branchFromMessageId =
      GeneratedColumn<String>(
        'branch_from_message_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
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
    backgroundPath,
    parentConversationId,
    branchFromMessageId,
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
    if (data.containsKey('background_path')) {
      context.handle(
        _backgroundPathMeta,
        backgroundPath.isAcceptableOrUnknown(
          data['background_path']!,
          _backgroundPathMeta,
        ),
      );
    }
    if (data.containsKey('parent_conversation_id')) {
      context.handle(
        _parentConversationIdMeta,
        parentConversationId.isAcceptableOrUnknown(
          data['parent_conversation_id']!,
          _parentConversationIdMeta,
        ),
      );
    }
    if (data.containsKey('branch_from_message_id')) {
      context.handle(
        _branchFromMessageIdMeta,
        branchFromMessageId.isAcceptableOrUnknown(
          data['branch_from_message_id']!,
          _branchFromMessageIdMeta,
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
      backgroundPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}background_path'],
      ),
      parentConversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_conversation_id'],
      ),
      branchFromMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_from_message_id'],
      ),
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

  /// 自定义聊天背景板文件绝对路径（v8）；null=默认主题背景。
  final String? backgroundPath;

  /// 分支来源会话（v16）：从某条消息 fork 出的新会话。
  final String? parentConversationId;

  /// 分支点消息 id（v16）。
  final String? branchFromMessageId;
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
    this.backgroundPath,
    this.parentConversationId,
    this.branchFromMessageId,
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
    if (!nullToAbsent || backgroundPath != null) {
      map['background_path'] = Variable<String>(backgroundPath);
    }
    if (!nullToAbsent || parentConversationId != null) {
      map['parent_conversation_id'] = Variable<String>(parentConversationId);
    }
    if (!nullToAbsent || branchFromMessageId != null) {
      map['branch_from_message_id'] = Variable<String>(branchFromMessageId);
    }
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
      backgroundPath: backgroundPath == null && nullToAbsent
          ? const Value.absent()
          : Value(backgroundPath),
      parentConversationId: parentConversationId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentConversationId),
      branchFromMessageId: branchFromMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(branchFromMessageId),
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
      backgroundPath: serializer.fromJson<String?>(json['backgroundPath']),
      parentConversationId: serializer.fromJson<String?>(
        json['parentConversationId'],
      ),
      branchFromMessageId: serializer.fromJson<String?>(
        json['branchFromMessageId'],
      ),
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
      'backgroundPath': serializer.toJson<String?>(backgroundPath),
      'parentConversationId': serializer.toJson<String?>(parentConversationId),
      'branchFromMessageId': serializer.toJson<String?>(branchFromMessageId),
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
    Value<String?> backgroundPath = const Value.absent(),
    Value<String?> parentConversationId = const Value.absent(),
    Value<String?> branchFromMessageId = const Value.absent(),
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
    backgroundPath: backgroundPath.present
        ? backgroundPath.value
        : this.backgroundPath,
    parentConversationId: parentConversationId.present
        ? parentConversationId.value
        : this.parentConversationId,
    branchFromMessageId: branchFromMessageId.present
        ? branchFromMessageId.value
        : this.branchFromMessageId,
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
      backgroundPath: data.backgroundPath.present
          ? data.backgroundPath.value
          : this.backgroundPath,
      parentConversationId: data.parentConversationId.present
          ? data.parentConversationId.value
          : this.parentConversationId,
      branchFromMessageId: data.branchFromMessageId.present
          ? data.branchFromMessageId.value
          : this.branchFromMessageId,
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
          ..write('voiceEnabled: $voiceEnabled, ')
          ..write('backgroundPath: $backgroundPath, ')
          ..write('parentConversationId: $parentConversationId, ')
          ..write('branchFromMessageId: $branchFromMessageId')
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
    backgroundPath,
    parentConversationId,
    branchFromMessageId,
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
          other.voiceEnabled == this.voiceEnabled &&
          other.backgroundPath == this.backgroundPath &&
          other.parentConversationId == this.parentConversationId &&
          other.branchFromMessageId == this.branchFromMessageId);
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
  final Value<String?> backgroundPath;
  final Value<String?> parentConversationId;
  final Value<String?> branchFromMessageId;
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
    this.backgroundPath = const Value.absent(),
    this.parentConversationId = const Value.absent(),
    this.branchFromMessageId = const Value.absent(),
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
    this.backgroundPath = const Value.absent(),
    this.parentConversationId = const Value.absent(),
    this.branchFromMessageId = const Value.absent(),
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
    Expression<String>? backgroundPath,
    Expression<String>? parentConversationId,
    Expression<String>? branchFromMessageId,
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
      if (backgroundPath != null) 'background_path': backgroundPath,
      if (parentConversationId != null)
        'parent_conversation_id': parentConversationId,
      if (branchFromMessageId != null)
        'branch_from_message_id': branchFromMessageId,
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
    Value<String?>? backgroundPath,
    Value<String?>? parentConversationId,
    Value<String?>? branchFromMessageId,
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
      backgroundPath: backgroundPath ?? this.backgroundPath,
      parentConversationId: parentConversationId ?? this.parentConversationId,
      branchFromMessageId: branchFromMessageId ?? this.branchFromMessageId,
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
    if (backgroundPath.present) {
      map['background_path'] = Variable<String>(backgroundPath.value);
    }
    if (parentConversationId.present) {
      map['parent_conversation_id'] = Variable<String>(
        parentConversationId.value,
      );
    }
    if (branchFromMessageId.present) {
      map['branch_from_message_id'] = Variable<String>(
        branchFromMessageId.value,
      );
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
          ..write('backgroundPath: $backgroundPath, ')
          ..write('parentConversationId: $parentConversationId, ')
          ..write('branchFromMessageId: $branchFromMessageId, ')
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
  static const VerificationMeta _imagePathsMeta = const VerificationMeta(
    'imagePaths',
  );
  @override
  late final GeneratedColumn<String> imagePaths = GeneratedColumn<String>(
    'image_paths',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _imageSummaryMeta = const VerificationMeta(
    'imageSummary',
  );
  @override
  late final GeneratedColumn<String> imageSummary = GeneratedColumn<String>(
    'image_summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('text'),
  );
  static const VerificationMeta _activeVariantIdMeta = const VerificationMeta(
    'activeVariantId',
  );
  @override
  late final GeneratedColumn<String> activeVariantId = GeneratedColumn<String>(
    'active_variant_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _speakerCharacterIdMeta =
      const VerificationMeta('speakerCharacterId');
  @override
  late final GeneratedColumn<String> speakerCharacterId =
      GeneratedColumn<String>(
        'speaker_character_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
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
    imagePaths,
    imageSummary,
    status,
    kind,
    activeVariantId,
    speakerCharacterId,
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
    if (data.containsKey('image_paths')) {
      context.handle(
        _imagePathsMeta,
        imagePaths.isAcceptableOrUnknown(data['image_paths']!, _imagePathsMeta),
      );
    }
    if (data.containsKey('image_summary')) {
      context.handle(
        _imageSummaryMeta,
        imageSummary.isAcceptableOrUnknown(
          data['image_summary']!,
          _imageSummaryMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('active_variant_id')) {
      context.handle(
        _activeVariantIdMeta,
        activeVariantId.isAcceptableOrUnknown(
          data['active_variant_id']!,
          _activeVariantIdMeta,
        ),
      );
    }
    if (data.containsKey('speaker_character_id')) {
      context.handle(
        _speakerCharacterIdMeta,
        speakerCharacterId.isAcceptableOrUnknown(
          data['speaker_character_id']!,
          _speakerCharacterIdMeta,
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
      imagePaths: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_paths'],
      )!,
      imageSummary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_summary'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      activeVariantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_variant_id'],
      ),
      speakerCharacterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}speaker_character_id'],
      ),
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

  /// JSON 数组：附图文件绝对路径（v7）。
  final String imagePaths;

  /// 图片内容一句话概括（LLM 生成；失败留空走 [图片] 占位，v7）。
  final String imageSummary;

  /// streaming | done | error
  final String status;

  /// text | sticker（v8）：sticker 为纯图表情包消息，不进提示词/记忆/标题。
  final String kind;

  /// 当前选中的候选回复 id（v14）；null=正文即唯一候选。
  final String? activeVariantId;

  /// 群聊中说这句话的角色 id（v16）；null=单角色会话。
  final String? speakerCharacterId;
  final DateTime createdAt;
  const MessageRow({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.rawContent,
    required this.emotionEvents,
    required this.imagePaths,
    required this.imageSummary,
    required this.status,
    required this.kind,
    this.activeVariantId,
    this.speakerCharacterId,
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
    map['image_paths'] = Variable<String>(imagePaths);
    map['image_summary'] = Variable<String>(imageSummary);
    map['status'] = Variable<String>(status);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || activeVariantId != null) {
      map['active_variant_id'] = Variable<String>(activeVariantId);
    }
    if (!nullToAbsent || speakerCharacterId != null) {
      map['speaker_character_id'] = Variable<String>(speakerCharacterId);
    }
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
      imagePaths: Value(imagePaths),
      imageSummary: Value(imageSummary),
      status: Value(status),
      kind: Value(kind),
      activeVariantId: activeVariantId == null && nullToAbsent
          ? const Value.absent()
          : Value(activeVariantId),
      speakerCharacterId: speakerCharacterId == null && nullToAbsent
          ? const Value.absent()
          : Value(speakerCharacterId),
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
      imagePaths: serializer.fromJson<String>(json['imagePaths']),
      imageSummary: serializer.fromJson<String>(json['imageSummary']),
      status: serializer.fromJson<String>(json['status']),
      kind: serializer.fromJson<String>(json['kind']),
      activeVariantId: serializer.fromJson<String?>(json['activeVariantId']),
      speakerCharacterId: serializer.fromJson<String?>(
        json['speakerCharacterId'],
      ),
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
      'imagePaths': serializer.toJson<String>(imagePaths),
      'imageSummary': serializer.toJson<String>(imageSummary),
      'status': serializer.toJson<String>(status),
      'kind': serializer.toJson<String>(kind),
      'activeVariantId': serializer.toJson<String?>(activeVariantId),
      'speakerCharacterId': serializer.toJson<String?>(speakerCharacterId),
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
    String? imagePaths,
    String? imageSummary,
    String? status,
    String? kind,
    Value<String?> activeVariantId = const Value.absent(),
    Value<String?> speakerCharacterId = const Value.absent(),
    DateTime? createdAt,
  }) => MessageRow(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    role: role ?? this.role,
    content: content ?? this.content,
    rawContent: rawContent ?? this.rawContent,
    emotionEvents: emotionEvents ?? this.emotionEvents,
    imagePaths: imagePaths ?? this.imagePaths,
    imageSummary: imageSummary ?? this.imageSummary,
    status: status ?? this.status,
    kind: kind ?? this.kind,
    activeVariantId: activeVariantId.present
        ? activeVariantId.value
        : this.activeVariantId,
    speakerCharacterId: speakerCharacterId.present
        ? speakerCharacterId.value
        : this.speakerCharacterId,
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
      imagePaths: data.imagePaths.present
          ? data.imagePaths.value
          : this.imagePaths,
      imageSummary: data.imageSummary.present
          ? data.imageSummary.value
          : this.imageSummary,
      status: data.status.present ? data.status.value : this.status,
      kind: data.kind.present ? data.kind.value : this.kind,
      activeVariantId: data.activeVariantId.present
          ? data.activeVariantId.value
          : this.activeVariantId,
      speakerCharacterId: data.speakerCharacterId.present
          ? data.speakerCharacterId.value
          : this.speakerCharacterId,
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
          ..write('imagePaths: $imagePaths, ')
          ..write('imageSummary: $imageSummary, ')
          ..write('status: $status, ')
          ..write('kind: $kind, ')
          ..write('activeVariantId: $activeVariantId, ')
          ..write('speakerCharacterId: $speakerCharacterId, ')
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
    imagePaths,
    imageSummary,
    status,
    kind,
    activeVariantId,
    speakerCharacterId,
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
          other.imagePaths == this.imagePaths &&
          other.imageSummary == this.imageSummary &&
          other.status == this.status &&
          other.kind == this.kind &&
          other.activeVariantId == this.activeVariantId &&
          other.speakerCharacterId == this.speakerCharacterId &&
          other.createdAt == this.createdAt);
}

class MessagesCompanion extends UpdateCompanion<MessageRow> {
  final Value<String> id;
  final Value<String> conversationId;
  final Value<String> role;
  final Value<String> content;
  final Value<String> rawContent;
  final Value<String> emotionEvents;
  final Value<String> imagePaths;
  final Value<String> imageSummary;
  final Value<String> status;
  final Value<String> kind;
  final Value<String?> activeVariantId;
  final Value<String?> speakerCharacterId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.rawContent = const Value.absent(),
    this.emotionEvents = const Value.absent(),
    this.imagePaths = const Value.absent(),
    this.imageSummary = const Value.absent(),
    this.status = const Value.absent(),
    this.kind = const Value.absent(),
    this.activeVariantId = const Value.absent(),
    this.speakerCharacterId = const Value.absent(),
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
    this.imagePaths = const Value.absent(),
    this.imageSummary = const Value.absent(),
    this.status = const Value.absent(),
    this.kind = const Value.absent(),
    this.activeVariantId = const Value.absent(),
    this.speakerCharacterId = const Value.absent(),
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
    Expression<String>? imagePaths,
    Expression<String>? imageSummary,
    Expression<String>? status,
    Expression<String>? kind,
    Expression<String>? activeVariantId,
    Expression<String>? speakerCharacterId,
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
      if (imagePaths != null) 'image_paths': imagePaths,
      if (imageSummary != null) 'image_summary': imageSummary,
      if (status != null) 'status': status,
      if (kind != null) 'kind': kind,
      if (activeVariantId != null) 'active_variant_id': activeVariantId,
      if (speakerCharacterId != null)
        'speaker_character_id': speakerCharacterId,
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
    Value<String>? imagePaths,
    Value<String>? imageSummary,
    Value<String>? status,
    Value<String>? kind,
    Value<String?>? activeVariantId,
    Value<String?>? speakerCharacterId,
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
      imagePaths: imagePaths ?? this.imagePaths,
      imageSummary: imageSummary ?? this.imageSummary,
      status: status ?? this.status,
      kind: kind ?? this.kind,
      activeVariantId: activeVariantId ?? this.activeVariantId,
      speakerCharacterId: speakerCharacterId ?? this.speakerCharacterId,
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
    if (imagePaths.present) {
      map['image_paths'] = Variable<String>(imagePaths.value);
    }
    if (imageSummary.present) {
      map['image_summary'] = Variable<String>(imageSummary.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (activeVariantId.present) {
      map['active_variant_id'] = Variable<String>(activeVariantId.value);
    }
    if (speakerCharacterId.present) {
      map['speaker_character_id'] = Variable<String>(speakerCharacterId.value);
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
          ..write('imagePaths: $imagePaths, ')
          ..write('imageSummary: $imageSummary, ')
          ..write('status: $status, ')
          ..write('kind: $kind, ')
          ..write('activeVariantId: $activeVariantId, ')
          ..write('speakerCharacterId: $speakerCharacterId, ')
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
  static const VerificationMeta _alternateGreetingsMeta =
      const VerificationMeta('alternateGreetings');
  @override
  late final GeneratedColumn<String> alternateGreetings =
      GeneratedColumn<String>(
        'alternate_greetings',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
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
  static const VerificationMeta _profileJsonMeta = const VerificationMeta(
    'profileJson',
  );
  @override
  late final GeneratedColumn<String> profileJson = GeneratedColumn<String>(
    'profile_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _extensionsJsonMeta = const VerificationMeta(
    'extensionsJson',
  );
  @override
  late final GeneratedColumn<String> extensionsJson = GeneratedColumn<String>(
    'extensions_json',
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
  static const VerificationMeta _userSummaryMeta = const VerificationMeta(
    'userSummary',
  );
  @override
  late final GeneratedColumn<String> userSummary = GeneratedColumn<String>(
    'user_summary',
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
    alternateGreetings,
    avatarPath,
    source,
    profileJson,
    extensionsJson,
    createdAt,
    updatedAt,
    memorySummary,
    userSummary,
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
    if (data.containsKey('alternate_greetings')) {
      context.handle(
        _alternateGreetingsMeta,
        alternateGreetings.isAcceptableOrUnknown(
          data['alternate_greetings']!,
          _alternateGreetingsMeta,
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
    if (data.containsKey('profile_json')) {
      context.handle(
        _profileJsonMeta,
        profileJson.isAcceptableOrUnknown(
          data['profile_json']!,
          _profileJsonMeta,
        ),
      );
    }
    if (data.containsKey('extensions_json')) {
      context.handle(
        _extensionsJsonMeta,
        extensionsJson.isAcceptableOrUnknown(
          data['extensions_json']!,
          _extensionsJsonMeta,
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
    if (data.containsKey('memory_summary')) {
      context.handle(
        _memorySummaryMeta,
        memorySummary.isAcceptableOrUnknown(
          data['memory_summary']!,
          _memorySummaryMeta,
        ),
      );
    }
    if (data.containsKey('user_summary')) {
      context.handle(
        _userSummaryMeta,
        userSummary.isAcceptableOrUnknown(
          data['user_summary']!,
          _userSummaryMeta,
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
      alternateGreetings: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alternate_greetings'],
      )!,
      avatarPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_path'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      profileJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_json'],
      )!,
      extensionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extensions_json'],
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
      userSummary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_summary'],
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

  /// 多开场白 JSON 数组（v14）；firstMessage 仍是主开场白。
  final String alternateGreetings;

  /// 立绘文件绝对路径。
  final String? avatarPath;

  /// manual | st_v1 | st_v2 | st_v3
  final String source;

  /// 扩展档案 JSON（v17）：外貌/背景/关系/语言风格/创作者/运行配置等。
  final String profileJson;

  /// 第三方扩展与未识别字段 JSON（v17）：只读保留，导出时合并。
  final String extensionsJson;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 跨会话长期记忆（LLM 摘要，第一人称要点，v6）。
  /// 注意：CharacterRepository.save 是整行 upsert，本列不进 Character
  /// 领域模型，只经 getMemory/setMemory 读写，防止编辑角色卡时覆盖。
  final String memorySummary;

  /// 角色眼中的用户画像（LLM 摘要，角色视角，v8）。同上不进域模型。
  final String userSummary;

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
    required this.alternateGreetings,
    this.avatarPath,
    required this.source,
    required this.profileJson,
    required this.extensionsJson,
    required this.createdAt,
    required this.updatedAt,
    required this.memorySummary,
    required this.userSummary,
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
    map['alternate_greetings'] = Variable<String>(alternateGreetings);
    if (!nullToAbsent || avatarPath != null) {
      map['avatar_path'] = Variable<String>(avatarPath);
    }
    map['source'] = Variable<String>(source);
    map['profile_json'] = Variable<String>(profileJson);
    map['extensions_json'] = Variable<String>(extensionsJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['memory_summary'] = Variable<String>(memorySummary);
    map['user_summary'] = Variable<String>(userSummary);
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
      alternateGreetings: Value(alternateGreetings),
      avatarPath: avatarPath == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarPath),
      source: Value(source),
      profileJson: Value(profileJson),
      extensionsJson: Value(extensionsJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      memorySummary: Value(memorySummary),
      userSummary: Value(userSummary),
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
      alternateGreetings: serializer.fromJson<String>(
        json['alternateGreetings'],
      ),
      avatarPath: serializer.fromJson<String?>(json['avatarPath']),
      source: serializer.fromJson<String>(json['source']),
      profileJson: serializer.fromJson<String>(json['profileJson']),
      extensionsJson: serializer.fromJson<String>(json['extensionsJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      memorySummary: serializer.fromJson<String>(json['memorySummary']),
      userSummary: serializer.fromJson<String>(json['userSummary']),
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
      'alternateGreetings': serializer.toJson<String>(alternateGreetings),
      'avatarPath': serializer.toJson<String?>(avatarPath),
      'source': serializer.toJson<String>(source),
      'profileJson': serializer.toJson<String>(profileJson),
      'extensionsJson': serializer.toJson<String>(extensionsJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'memorySummary': serializer.toJson<String>(memorySummary),
      'userSummary': serializer.toJson<String>(userSummary),
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
    String? alternateGreetings,
    Value<String?> avatarPath = const Value.absent(),
    String? source,
    String? profileJson,
    String? extensionsJson,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? memorySummary,
    String? userSummary,
    Value<DateTime?> memoryUpdatedAt = const Value.absent(),
  }) => CharacterRow(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    personality: personality ?? this.personality,
    scenario: scenario ?? this.scenario,
    firstMessage: firstMessage ?? this.firstMessage,
    exampleDialogue: exampleDialogue ?? this.exampleDialogue,
    alternateGreetings: alternateGreetings ?? this.alternateGreetings,
    avatarPath: avatarPath.present ? avatarPath.value : this.avatarPath,
    source: source ?? this.source,
    profileJson: profileJson ?? this.profileJson,
    extensionsJson: extensionsJson ?? this.extensionsJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    memorySummary: memorySummary ?? this.memorySummary,
    userSummary: userSummary ?? this.userSummary,
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
      alternateGreetings: data.alternateGreetings.present
          ? data.alternateGreetings.value
          : this.alternateGreetings,
      avatarPath: data.avatarPath.present
          ? data.avatarPath.value
          : this.avatarPath,
      source: data.source.present ? data.source.value : this.source,
      profileJson: data.profileJson.present
          ? data.profileJson.value
          : this.profileJson,
      extensionsJson: data.extensionsJson.present
          ? data.extensionsJson.value
          : this.extensionsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      memorySummary: data.memorySummary.present
          ? data.memorySummary.value
          : this.memorySummary,
      userSummary: data.userSummary.present
          ? data.userSummary.value
          : this.userSummary,
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
          ..write('alternateGreetings: $alternateGreetings, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('source: $source, ')
          ..write('profileJson: $profileJson, ')
          ..write('extensionsJson: $extensionsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('memorySummary: $memorySummary, ')
          ..write('userSummary: $userSummary, ')
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
    alternateGreetings,
    avatarPath,
    source,
    profileJson,
    extensionsJson,
    createdAt,
    updatedAt,
    memorySummary,
    userSummary,
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
          other.alternateGreetings == this.alternateGreetings &&
          other.avatarPath == this.avatarPath &&
          other.source == this.source &&
          other.profileJson == this.profileJson &&
          other.extensionsJson == this.extensionsJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.memorySummary == this.memorySummary &&
          other.userSummary == this.userSummary &&
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
  final Value<String> alternateGreetings;
  final Value<String?> avatarPath;
  final Value<String> source;
  final Value<String> profileJson;
  final Value<String> extensionsJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> memorySummary;
  final Value<String> userSummary;
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
    this.alternateGreetings = const Value.absent(),
    this.avatarPath = const Value.absent(),
    this.source = const Value.absent(),
    this.profileJson = const Value.absent(),
    this.extensionsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.memorySummary = const Value.absent(),
    this.userSummary = const Value.absent(),
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
    this.alternateGreetings = const Value.absent(),
    this.avatarPath = const Value.absent(),
    this.source = const Value.absent(),
    this.profileJson = const Value.absent(),
    this.extensionsJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.memorySummary = const Value.absent(),
    this.userSummary = const Value.absent(),
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
    Expression<String>? alternateGreetings,
    Expression<String>? avatarPath,
    Expression<String>? source,
    Expression<String>? profileJson,
    Expression<String>? extensionsJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? memorySummary,
    Expression<String>? userSummary,
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
      if (alternateGreetings != null) 'alternate_greetings': alternateGreetings,
      if (avatarPath != null) 'avatar_path': avatarPath,
      if (source != null) 'source': source,
      if (profileJson != null) 'profile_json': profileJson,
      if (extensionsJson != null) 'extensions_json': extensionsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (memorySummary != null) 'memory_summary': memorySummary,
      if (userSummary != null) 'user_summary': userSummary,
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
    Value<String>? alternateGreetings,
    Value<String?>? avatarPath,
    Value<String>? source,
    Value<String>? profileJson,
    Value<String>? extensionsJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? memorySummary,
    Value<String>? userSummary,
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
      alternateGreetings: alternateGreetings ?? this.alternateGreetings,
      avatarPath: avatarPath ?? this.avatarPath,
      source: source ?? this.source,
      profileJson: profileJson ?? this.profileJson,
      extensionsJson: extensionsJson ?? this.extensionsJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      memorySummary: memorySummary ?? this.memorySummary,
      userSummary: userSummary ?? this.userSummary,
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
    if (alternateGreetings.present) {
      map['alternate_greetings'] = Variable<String>(alternateGreetings.value);
    }
    if (avatarPath.present) {
      map['avatar_path'] = Variable<String>(avatarPath.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (profileJson.present) {
      map['profile_json'] = Variable<String>(profileJson.value);
    }
    if (extensionsJson.present) {
      map['extensions_json'] = Variable<String>(extensionsJson.value);
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
    if (userSummary.present) {
      map['user_summary'] = Variable<String>(userSummary.value);
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
          ..write('alternateGreetings: $alternateGreetings, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('source: $source, ')
          ..write('profileJson: $profileJson, ')
          ..write('extensionsJson: $extensionsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('memorySummary: $memorySummary, ')
          ..write('userSummary: $userSummary, ')
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

class $StickersTable extends Stickers
    with TableInfo<$StickersTable, StickerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StickersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<String> characterId = GeneratedColumn<String>(
    'character_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<String> mood = GeneratedColumn<String>(
    'mood',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    characterId,
    mood,
    filePath,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stickers';
  @override
  VerificationContext validateIntegrity(
    Insertable<StickerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('mood')) {
      context.handle(
        _moodMeta,
        mood.isAcceptableOrUnknown(data['mood']!, _moodMeta),
      );
    } else if (isInserting) {
      context.missing(_moodMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
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
  StickerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StickerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character_id'],
      )!,
      mood: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mood'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $StickersTable createAlias(String alias) {
    return $StickersTable(attachedDatabase, alias);
  }
}

class StickerRow extends DataClass implements Insertable<StickerRow> {
  final String id;
  final String characterId;

  /// 心情键：英文情绪标签值（happy/angry/sad/amused/confused/shy/…）。
  final String mood;

  /// 图片文件绝对路径。
  final String filePath;
  final DateTime createdAt;
  const StickerRow({
    required this.id,
    required this.characterId,
    required this.mood,
    required this.filePath,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['character_id'] = Variable<String>(characterId);
    map['mood'] = Variable<String>(mood);
    map['file_path'] = Variable<String>(filePath);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StickersCompanion toCompanion(bool nullToAbsent) {
    return StickersCompanion(
      id: Value(id),
      characterId: Value(characterId),
      mood: Value(mood),
      filePath: Value(filePath),
      createdAt: Value(createdAt),
    );
  }

  factory StickerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StickerRow(
      id: serializer.fromJson<String>(json['id']),
      characterId: serializer.fromJson<String>(json['characterId']),
      mood: serializer.fromJson<String>(json['mood']),
      filePath: serializer.fromJson<String>(json['filePath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'characterId': serializer.toJson<String>(characterId),
      'mood': serializer.toJson<String>(mood),
      'filePath': serializer.toJson<String>(filePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StickerRow copyWith({
    String? id,
    String? characterId,
    String? mood,
    String? filePath,
    DateTime? createdAt,
  }) => StickerRow(
    id: id ?? this.id,
    characterId: characterId ?? this.characterId,
    mood: mood ?? this.mood,
    filePath: filePath ?? this.filePath,
    createdAt: createdAt ?? this.createdAt,
  );
  StickerRow copyWithCompanion(StickersCompanion data) {
    return StickerRow(
      id: data.id.present ? data.id.value : this.id,
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      mood: data.mood.present ? data.mood.value : this.mood,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StickerRow(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('mood: $mood, ')
          ..write('filePath: $filePath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, characterId, mood, filePath, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StickerRow &&
          other.id == this.id &&
          other.characterId == this.characterId &&
          other.mood == this.mood &&
          other.filePath == this.filePath &&
          other.createdAt == this.createdAt);
}

class StickersCompanion extends UpdateCompanion<StickerRow> {
  final Value<String> id;
  final Value<String> characterId;
  final Value<String> mood;
  final Value<String> filePath;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const StickersCompanion({
    this.id = const Value.absent(),
    this.characterId = const Value.absent(),
    this.mood = const Value.absent(),
    this.filePath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StickersCompanion.insert({
    required String id,
    required String characterId,
    required String mood,
    required String filePath,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       characterId = Value(characterId),
       mood = Value(mood),
       filePath = Value(filePath),
       createdAt = Value(createdAt);
  static Insertable<StickerRow> custom({
    Expression<String>? id,
    Expression<String>? characterId,
    Expression<String>? mood,
    Expression<String>? filePath,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (characterId != null) 'character_id': characterId,
      if (mood != null) 'mood': mood,
      if (filePath != null) 'file_path': filePath,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StickersCompanion copyWith({
    Value<String>? id,
    Value<String>? characterId,
    Value<String>? mood,
    Value<String>? filePath,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return StickersCompanion(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      mood: mood ?? this.mood,
      filePath: filePath ?? this.filePath,
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
    if (characterId.present) {
      map['character_id'] = Variable<String>(characterId.value);
    }
    if (mood.present) {
      map['mood'] = Variable<String>(mood.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
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
    return (StringBuffer('StickersCompanion(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('mood: $mood, ')
          ..write('filePath: $filePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemoryCursorsTable extends MemoryCursors
    with TableInfo<$MemoryCursorsTable, MemoryCursorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemoryCursorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<String> characterId = GeneratedColumn<String>(
    'character_id',
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
  static const VerificationMeta _summarizedAtMeta = const VerificationMeta(
    'summarizedAt',
  );
  @override
  late final GeneratedColumn<DateTime> summarizedAt = GeneratedColumn<DateTime>(
    'summarized_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    characterId,
    conversationId,
    summarizedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memory_cursors';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemoryCursorRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterIdMeta);
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
    if (data.containsKey('summarized_at')) {
      context.handle(
        _summarizedAtMeta,
        summarizedAt.isAcceptableOrUnknown(
          data['summarized_at']!,
          _summarizedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_summarizedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {characterId, conversationId};
  @override
  MemoryCursorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemoryCursorRow(
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character_id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      summarizedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}summarized_at'],
      )!,
    );
  }

  @override
  $MemoryCursorsTable createAlias(String alias) {
    return $MemoryCursorsTable(attachedDatabase, alias);
  }
}

class MemoryCursorRow extends DataClass implements Insertable<MemoryCursorRow> {
  final String characterId;
  final String conversationId;
  final DateTime summarizedAt;
  const MemoryCursorRow({
    required this.characterId,
    required this.conversationId,
    required this.summarizedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['character_id'] = Variable<String>(characterId);
    map['conversation_id'] = Variable<String>(conversationId);
    map['summarized_at'] = Variable<DateTime>(summarizedAt);
    return map;
  }

  MemoryCursorsCompanion toCompanion(bool nullToAbsent) {
    return MemoryCursorsCompanion(
      characterId: Value(characterId),
      conversationId: Value(conversationId),
      summarizedAt: Value(summarizedAt),
    );
  }

  factory MemoryCursorRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemoryCursorRow(
      characterId: serializer.fromJson<String>(json['characterId']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      summarizedAt: serializer.fromJson<DateTime>(json['summarizedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'characterId': serializer.toJson<String>(characterId),
      'conversationId': serializer.toJson<String>(conversationId),
      'summarizedAt': serializer.toJson<DateTime>(summarizedAt),
    };
  }

  MemoryCursorRow copyWith({
    String? characterId,
    String? conversationId,
    DateTime? summarizedAt,
  }) => MemoryCursorRow(
    characterId: characterId ?? this.characterId,
    conversationId: conversationId ?? this.conversationId,
    summarizedAt: summarizedAt ?? this.summarizedAt,
  );
  MemoryCursorRow copyWithCompanion(MemoryCursorsCompanion data) {
    return MemoryCursorRow(
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      summarizedAt: data.summarizedAt.present
          ? data.summarizedAt.value
          : this.summarizedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemoryCursorRow(')
          ..write('characterId: $characterId, ')
          ..write('conversationId: $conversationId, ')
          ..write('summarizedAt: $summarizedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(characterId, conversationId, summarizedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemoryCursorRow &&
          other.characterId == this.characterId &&
          other.conversationId == this.conversationId &&
          other.summarizedAt == this.summarizedAt);
}

class MemoryCursorsCompanion extends UpdateCompanion<MemoryCursorRow> {
  final Value<String> characterId;
  final Value<String> conversationId;
  final Value<DateTime> summarizedAt;
  final Value<int> rowid;
  const MemoryCursorsCompanion({
    this.characterId = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.summarizedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemoryCursorsCompanion.insert({
    required String characterId,
    required String conversationId,
    required DateTime summarizedAt,
    this.rowid = const Value.absent(),
  }) : characterId = Value(characterId),
       conversationId = Value(conversationId),
       summarizedAt = Value(summarizedAt);
  static Insertable<MemoryCursorRow> custom({
    Expression<String>? characterId,
    Expression<String>? conversationId,
    Expression<DateTime>? summarizedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (characterId != null) 'character_id': characterId,
      if (conversationId != null) 'conversation_id': conversationId,
      if (summarizedAt != null) 'summarized_at': summarizedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemoryCursorsCompanion copyWith({
    Value<String>? characterId,
    Value<String>? conversationId,
    Value<DateTime>? summarizedAt,
    Value<int>? rowid,
  }) {
    return MemoryCursorsCompanion(
      characterId: characterId ?? this.characterId,
      conversationId: conversationId ?? this.conversationId,
      summarizedAt: summarizedAt ?? this.summarizedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (characterId.present) {
      map['character_id'] = Variable<String>(characterId.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (summarizedAt.present) {
      map['summarized_at'] = Variable<DateTime>(summarizedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemoryCursorsCompanion(')
          ..write('characterId: $characterId, ')
          ..write('conversationId: $conversationId, ')
          ..write('summarizedAt: $summarizedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemoryFactsTable extends MemoryFacts
    with TableInfo<$MemoryFactsTable, MemoryFactRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemoryFactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<String> characterId = GeneratedColumn<String>(
    'character_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _factMeta = const VerificationMeta('fact');
  @override
  late final GeneratedColumn<String> fact = GeneratedColumn<String>(
    'fact',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceConversationIdMeta =
      const VerificationMeta('sourceConversationId');
  @override
  late final GeneratedColumn<String> sourceConversationId =
      GeneratedColumn<String>(
        'source_conversation_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
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
    characterId,
    fact,
    occurredAt,
    sourceConversationId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memory_facts';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemoryFactRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('fact')) {
      context.handle(
        _factMeta,
        fact.isAcceptableOrUnknown(data['fact']!, _factMeta),
      );
    } else if (isInserting) {
      context.missing(_factMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('source_conversation_id')) {
      context.handle(
        _sourceConversationIdMeta,
        sourceConversationId.isAcceptableOrUnknown(
          data['source_conversation_id']!,
          _sourceConversationIdMeta,
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemoryFactRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemoryFactRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character_id'],
      )!,
      fact: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fact'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      sourceConversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_conversation_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MemoryFactsTable createAlias(String alias) {
    return $MemoryFactsTable(attachedDatabase, alias);
  }
}

class MemoryFactRow extends DataClass implements Insertable<MemoryFactRow> {
  final String id;
  final String characterId;

  /// 一事一条的短事实（如「用户去关山游玩」），不含过程细节。
  final String fact;

  /// 事件发生日（本地 00:00），不是整理时间。
  final DateTime occurredAt;
  final String? sourceConversationId;
  final DateTime createdAt;
  const MemoryFactRow({
    required this.id,
    required this.characterId,
    required this.fact,
    required this.occurredAt,
    this.sourceConversationId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['character_id'] = Variable<String>(characterId);
    map['fact'] = Variable<String>(fact);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    if (!nullToAbsent || sourceConversationId != null) {
      map['source_conversation_id'] = Variable<String>(sourceConversationId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MemoryFactsCompanion toCompanion(bool nullToAbsent) {
    return MemoryFactsCompanion(
      id: Value(id),
      characterId: Value(characterId),
      fact: Value(fact),
      occurredAt: Value(occurredAt),
      sourceConversationId: sourceConversationId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceConversationId),
      createdAt: Value(createdAt),
    );
  }

  factory MemoryFactRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemoryFactRow(
      id: serializer.fromJson<String>(json['id']),
      characterId: serializer.fromJson<String>(json['characterId']),
      fact: serializer.fromJson<String>(json['fact']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      sourceConversationId: serializer.fromJson<String?>(
        json['sourceConversationId'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'characterId': serializer.toJson<String>(characterId),
      'fact': serializer.toJson<String>(fact),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'sourceConversationId': serializer.toJson<String?>(sourceConversationId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MemoryFactRow copyWith({
    String? id,
    String? characterId,
    String? fact,
    DateTime? occurredAt,
    Value<String?> sourceConversationId = const Value.absent(),
    DateTime? createdAt,
  }) => MemoryFactRow(
    id: id ?? this.id,
    characterId: characterId ?? this.characterId,
    fact: fact ?? this.fact,
    occurredAt: occurredAt ?? this.occurredAt,
    sourceConversationId: sourceConversationId.present
        ? sourceConversationId.value
        : this.sourceConversationId,
    createdAt: createdAt ?? this.createdAt,
  );
  MemoryFactRow copyWithCompanion(MemoryFactsCompanion data) {
    return MemoryFactRow(
      id: data.id.present ? data.id.value : this.id,
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      fact: data.fact.present ? data.fact.value : this.fact,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      sourceConversationId: data.sourceConversationId.present
          ? data.sourceConversationId.value
          : this.sourceConversationId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemoryFactRow(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('fact: $fact, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('sourceConversationId: $sourceConversationId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    characterId,
    fact,
    occurredAt,
    sourceConversationId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemoryFactRow &&
          other.id == this.id &&
          other.characterId == this.characterId &&
          other.fact == this.fact &&
          other.occurredAt == this.occurredAt &&
          other.sourceConversationId == this.sourceConversationId &&
          other.createdAt == this.createdAt);
}

class MemoryFactsCompanion extends UpdateCompanion<MemoryFactRow> {
  final Value<String> id;
  final Value<String> characterId;
  final Value<String> fact;
  final Value<DateTime> occurredAt;
  final Value<String?> sourceConversationId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MemoryFactsCompanion({
    this.id = const Value.absent(),
    this.characterId = const Value.absent(),
    this.fact = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.sourceConversationId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemoryFactsCompanion.insert({
    required String id,
    required String characterId,
    required String fact,
    required DateTime occurredAt,
    this.sourceConversationId = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       characterId = Value(characterId),
       fact = Value(fact),
       occurredAt = Value(occurredAt),
       createdAt = Value(createdAt);
  static Insertable<MemoryFactRow> custom({
    Expression<String>? id,
    Expression<String>? characterId,
    Expression<String>? fact,
    Expression<DateTime>? occurredAt,
    Expression<String>? sourceConversationId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (characterId != null) 'character_id': characterId,
      if (fact != null) 'fact': fact,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (sourceConversationId != null)
        'source_conversation_id': sourceConversationId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemoryFactsCompanion copyWith({
    Value<String>? id,
    Value<String>? characterId,
    Value<String>? fact,
    Value<DateTime>? occurredAt,
    Value<String?>? sourceConversationId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MemoryFactsCompanion(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      fact: fact ?? this.fact,
      occurredAt: occurredAt ?? this.occurredAt,
      sourceConversationId: sourceConversationId ?? this.sourceConversationId,
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
    if (characterId.present) {
      map['character_id'] = Variable<String>(characterId.value);
    }
    if (fact.present) {
      map['fact'] = Variable<String>(fact.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (sourceConversationId.present) {
      map['source_conversation_id'] = Variable<String>(
        sourceConversationId.value,
      );
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
    return (StringBuffer('MemoryFactsCompanion(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('fact: $fact, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('sourceConversationId: $sourceConversationId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessageVariantsTable extends MessageVariants
    with TableInfo<$MessageVariantsTable, MessageVariantRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessageVariantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
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
    messageId,
    content,
    rawContent,
    emotionEvents,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message_variants';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageVariantRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
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
  MessageVariantRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageVariantRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
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
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MessageVariantsTable createAlias(String alias) {
    return $MessageVariantsTable(attachedDatabase, alias);
  }
}

class MessageVariantRow extends DataClass
    implements Insertable<MessageVariantRow> {
  final String id;
  final String messageId;
  final String content;
  final String rawContent;

  /// JSON 数组：情绪/动作事件。
  final String emotionEvents;
  final DateTime createdAt;
  const MessageVariantRow({
    required this.id,
    required this.messageId,
    required this.content,
    required this.rawContent,
    required this.emotionEvents,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['message_id'] = Variable<String>(messageId);
    map['content'] = Variable<String>(content);
    map['raw_content'] = Variable<String>(rawContent);
    map['emotion_events'] = Variable<String>(emotionEvents);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MessageVariantsCompanion toCompanion(bool nullToAbsent) {
    return MessageVariantsCompanion(
      id: Value(id),
      messageId: Value(messageId),
      content: Value(content),
      rawContent: Value(rawContent),
      emotionEvents: Value(emotionEvents),
      createdAt: Value(createdAt),
    );
  }

  factory MessageVariantRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageVariantRow(
      id: serializer.fromJson<String>(json['id']),
      messageId: serializer.fromJson<String>(json['messageId']),
      content: serializer.fromJson<String>(json['content']),
      rawContent: serializer.fromJson<String>(json['rawContent']),
      emotionEvents: serializer.fromJson<String>(json['emotionEvents']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'messageId': serializer.toJson<String>(messageId),
      'content': serializer.toJson<String>(content),
      'rawContent': serializer.toJson<String>(rawContent),
      'emotionEvents': serializer.toJson<String>(emotionEvents),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MessageVariantRow copyWith({
    String? id,
    String? messageId,
    String? content,
    String? rawContent,
    String? emotionEvents,
    DateTime? createdAt,
  }) => MessageVariantRow(
    id: id ?? this.id,
    messageId: messageId ?? this.messageId,
    content: content ?? this.content,
    rawContent: rawContent ?? this.rawContent,
    emotionEvents: emotionEvents ?? this.emotionEvents,
    createdAt: createdAt ?? this.createdAt,
  );
  MessageVariantRow copyWithCompanion(MessageVariantsCompanion data) {
    return MessageVariantRow(
      id: data.id.present ? data.id.value : this.id,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      content: data.content.present ? data.content.value : this.content,
      rawContent: data.rawContent.present
          ? data.rawContent.value
          : this.rawContent,
      emotionEvents: data.emotionEvents.present
          ? data.emotionEvents.value
          : this.emotionEvents,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageVariantRow(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('content: $content, ')
          ..write('rawContent: $rawContent, ')
          ..write('emotionEvents: $emotionEvents, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, messageId, content, rawContent, emotionEvents, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageVariantRow &&
          other.id == this.id &&
          other.messageId == this.messageId &&
          other.content == this.content &&
          other.rawContent == this.rawContent &&
          other.emotionEvents == this.emotionEvents &&
          other.createdAt == this.createdAt);
}

class MessageVariantsCompanion extends UpdateCompanion<MessageVariantRow> {
  final Value<String> id;
  final Value<String> messageId;
  final Value<String> content;
  final Value<String> rawContent;
  final Value<String> emotionEvents;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MessageVariantsCompanion({
    this.id = const Value.absent(),
    this.messageId = const Value.absent(),
    this.content = const Value.absent(),
    this.rawContent = const Value.absent(),
    this.emotionEvents = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessageVariantsCompanion.insert({
    required String id,
    required String messageId,
    this.content = const Value.absent(),
    this.rawContent = const Value.absent(),
    this.emotionEvents = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       messageId = Value(messageId),
       createdAt = Value(createdAt);
  static Insertable<MessageVariantRow> custom({
    Expression<String>? id,
    Expression<String>? messageId,
    Expression<String>? content,
    Expression<String>? rawContent,
    Expression<String>? emotionEvents,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (messageId != null) 'message_id': messageId,
      if (content != null) 'content': content,
      if (rawContent != null) 'raw_content': rawContent,
      if (emotionEvents != null) 'emotion_events': emotionEvents,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessageVariantsCompanion copyWith({
    Value<String>? id,
    Value<String>? messageId,
    Value<String>? content,
    Value<String>? rawContent,
    Value<String>? emotionEvents,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MessageVariantsCompanion(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      content: content ?? this.content,
      rawContent: rawContent ?? this.rawContent,
      emotionEvents: emotionEvents ?? this.emotionEvents,
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
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
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
    return (StringBuffer('MessageVariantsCompanion(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('content: $content, ')
          ..write('rawContent: $rawContent, ')
          ..write('emotionEvents: $emotionEvents, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LoreEntriesTable extends LoreEntries
    with TableInfo<$LoreEntriesTable, LoreEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoreEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<String> characterId = GeneratedColumn<String>(
    'character_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keysMeta = const VerificationMeta('keys');
  @override
  late final GeneratedColumn<String> keys = GeneratedColumn<String>(
    'keys',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
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
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<String> position = GeneratedColumn<String>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('before'),
  );
  static const VerificationMeta _depthMeta = const VerificationMeta('depth');
  @override
  late final GeneratedColumn<int> depth = GeneratedColumn<int>(
    'depth',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    defaultValue: const Constant(0),
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
  static const VerificationMeta _sourceJsonMeta = const VerificationMeta(
    'sourceJson',
  );
  @override
  late final GeneratedColumn<String> sourceJson = GeneratedColumn<String>(
    'source_json',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    characterId,
    keys,
    content,
    position,
    depth,
    priority,
    enabled,
    sourceJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lore_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LoreEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('keys')) {
      context.handle(
        _keysMeta,
        keys.isAcceptableOrUnknown(data['keys']!, _keysMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('depth')) {
      context.handle(
        _depthMeta,
        depth.isAcceptableOrUnknown(data['depth']!, _depthMeta),
      );
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
    if (data.containsKey('source_json')) {
      context.handle(
        _sourceJsonMeta,
        sourceJson.isAcceptableOrUnknown(data['source_json']!, _sourceJsonMeta),
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
  LoreEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LoreEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character_id'],
      )!,
      keys: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}keys'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}position'],
      )!,
      depth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}depth'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      sourceJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LoreEntriesTable createAlias(String alias) {
    return $LoreEntriesTable(attachedDatabase, alias);
  }
}

class LoreEntryRow extends DataClass implements Insertable<LoreEntryRow> {
  final String id;
  final String characterId;

  /// JSON 数组：触发关键词。
  final String keys;
  final String content;

  /// before|after：相对历史消息的位置。
  final String position;

  /// 0 表示贴近当前消息；数字越大越靠前。
  final int depth;
  final int priority;
  final bool enabled;

  /// 导入时的完整条目原文（v17）：导出时合并，保留未映射字段。
  final String sourceJson;
  final DateTime createdAt;
  const LoreEntryRow({
    required this.id,
    required this.characterId,
    required this.keys,
    required this.content,
    required this.position,
    required this.depth,
    required this.priority,
    required this.enabled,
    required this.sourceJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['character_id'] = Variable<String>(characterId);
    map['keys'] = Variable<String>(keys);
    map['content'] = Variable<String>(content);
    map['position'] = Variable<String>(position);
    map['depth'] = Variable<int>(depth);
    map['priority'] = Variable<int>(priority);
    map['enabled'] = Variable<bool>(enabled);
    map['source_json'] = Variable<String>(sourceJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LoreEntriesCompanion toCompanion(bool nullToAbsent) {
    return LoreEntriesCompanion(
      id: Value(id),
      characterId: Value(characterId),
      keys: Value(keys),
      content: Value(content),
      position: Value(position),
      depth: Value(depth),
      priority: Value(priority),
      enabled: Value(enabled),
      sourceJson: Value(sourceJson),
      createdAt: Value(createdAt),
    );
  }

  factory LoreEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LoreEntryRow(
      id: serializer.fromJson<String>(json['id']),
      characterId: serializer.fromJson<String>(json['characterId']),
      keys: serializer.fromJson<String>(json['keys']),
      content: serializer.fromJson<String>(json['content']),
      position: serializer.fromJson<String>(json['position']),
      depth: serializer.fromJson<int>(json['depth']),
      priority: serializer.fromJson<int>(json['priority']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      sourceJson: serializer.fromJson<String>(json['sourceJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'characterId': serializer.toJson<String>(characterId),
      'keys': serializer.toJson<String>(keys),
      'content': serializer.toJson<String>(content),
      'position': serializer.toJson<String>(position),
      'depth': serializer.toJson<int>(depth),
      'priority': serializer.toJson<int>(priority),
      'enabled': serializer.toJson<bool>(enabled),
      'sourceJson': serializer.toJson<String>(sourceJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LoreEntryRow copyWith({
    String? id,
    String? characterId,
    String? keys,
    String? content,
    String? position,
    int? depth,
    int? priority,
    bool? enabled,
    String? sourceJson,
    DateTime? createdAt,
  }) => LoreEntryRow(
    id: id ?? this.id,
    characterId: characterId ?? this.characterId,
    keys: keys ?? this.keys,
    content: content ?? this.content,
    position: position ?? this.position,
    depth: depth ?? this.depth,
    priority: priority ?? this.priority,
    enabled: enabled ?? this.enabled,
    sourceJson: sourceJson ?? this.sourceJson,
    createdAt: createdAt ?? this.createdAt,
  );
  LoreEntryRow copyWithCompanion(LoreEntriesCompanion data) {
    return LoreEntryRow(
      id: data.id.present ? data.id.value : this.id,
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      keys: data.keys.present ? data.keys.value : this.keys,
      content: data.content.present ? data.content.value : this.content,
      position: data.position.present ? data.position.value : this.position,
      depth: data.depth.present ? data.depth.value : this.depth,
      priority: data.priority.present ? data.priority.value : this.priority,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      sourceJson: data.sourceJson.present
          ? data.sourceJson.value
          : this.sourceJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LoreEntryRow(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('keys: $keys, ')
          ..write('content: $content, ')
          ..write('position: $position, ')
          ..write('depth: $depth, ')
          ..write('priority: $priority, ')
          ..write('enabled: $enabled, ')
          ..write('sourceJson: $sourceJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    characterId,
    keys,
    content,
    position,
    depth,
    priority,
    enabled,
    sourceJson,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoreEntryRow &&
          other.id == this.id &&
          other.characterId == this.characterId &&
          other.keys == this.keys &&
          other.content == this.content &&
          other.position == this.position &&
          other.depth == this.depth &&
          other.priority == this.priority &&
          other.enabled == this.enabled &&
          other.sourceJson == this.sourceJson &&
          other.createdAt == this.createdAt);
}

class LoreEntriesCompanion extends UpdateCompanion<LoreEntryRow> {
  final Value<String> id;
  final Value<String> characterId;
  final Value<String> keys;
  final Value<String> content;
  final Value<String> position;
  final Value<int> depth;
  final Value<int> priority;
  final Value<bool> enabled;
  final Value<String> sourceJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LoreEntriesCompanion({
    this.id = const Value.absent(),
    this.characterId = const Value.absent(),
    this.keys = const Value.absent(),
    this.content = const Value.absent(),
    this.position = const Value.absent(),
    this.depth = const Value.absent(),
    this.priority = const Value.absent(),
    this.enabled = const Value.absent(),
    this.sourceJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LoreEntriesCompanion.insert({
    required String id,
    required String characterId,
    this.keys = const Value.absent(),
    this.content = const Value.absent(),
    this.position = const Value.absent(),
    this.depth = const Value.absent(),
    this.priority = const Value.absent(),
    this.enabled = const Value.absent(),
    this.sourceJson = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       characterId = Value(characterId),
       createdAt = Value(createdAt);
  static Insertable<LoreEntryRow> custom({
    Expression<String>? id,
    Expression<String>? characterId,
    Expression<String>? keys,
    Expression<String>? content,
    Expression<String>? position,
    Expression<int>? depth,
    Expression<int>? priority,
    Expression<bool>? enabled,
    Expression<String>? sourceJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (characterId != null) 'character_id': characterId,
      if (keys != null) 'keys': keys,
      if (content != null) 'content': content,
      if (position != null) 'position': position,
      if (depth != null) 'depth': depth,
      if (priority != null) 'priority': priority,
      if (enabled != null) 'enabled': enabled,
      if (sourceJson != null) 'source_json': sourceJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LoreEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? characterId,
    Value<String>? keys,
    Value<String>? content,
    Value<String>? position,
    Value<int>? depth,
    Value<int>? priority,
    Value<bool>? enabled,
    Value<String>? sourceJson,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LoreEntriesCompanion(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      keys: keys ?? this.keys,
      content: content ?? this.content,
      position: position ?? this.position,
      depth: depth ?? this.depth,
      priority: priority ?? this.priority,
      enabled: enabled ?? this.enabled,
      sourceJson: sourceJson ?? this.sourceJson,
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
    if (characterId.present) {
      map['character_id'] = Variable<String>(characterId.value);
    }
    if (keys.present) {
      map['keys'] = Variable<String>(keys.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (position.present) {
      map['position'] = Variable<String>(position.value);
    }
    if (depth.present) {
      map['depth'] = Variable<int>(depth.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (sourceJson.present) {
      map['source_json'] = Variable<String>(sourceJson.value);
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
    return (StringBuffer('LoreEntriesCompanion(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('keys: $keys, ')
          ..write('content: $content, ')
          ..write('position: $position, ')
          ..write('depth: $depth, ')
          ..write('priority: $priority, ')
          ..write('enabled: $enabled, ')
          ..write('sourceJson: $sourceJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConversationParticipantsTable extends ConversationParticipants
    with TableInfo<$ConversationParticipantsTable, ConversationParticipantRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationParticipantsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<String> characterId = GeneratedColumn<String>(
    'character_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    characterId,
    sortOrder,
    enabled,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversation_participants';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConversationParticipantRow> instance, {
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
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
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
  ConversationParticipantRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConversationParticipantRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ConversationParticipantsTable createAlias(String alias) {
    return $ConversationParticipantsTable(attachedDatabase, alias);
  }
}

class ConversationParticipantRow extends DataClass
    implements Insertable<ConversationParticipantRow> {
  final String id;
  final String conversationId;
  final String characterId;
  final int sortOrder;

  /// 是否参与自动轮转（v18）。静音成员仍可被“让 TA 回复”强制发言。
  final bool enabled;
  final DateTime createdAt;
  const ConversationParticipantRow({
    required this.id,
    required this.conversationId,
    required this.characterId,
    required this.sortOrder,
    required this.enabled,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['conversation_id'] = Variable<String>(conversationId);
    map['character_id'] = Variable<String>(characterId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['enabled'] = Variable<bool>(enabled);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ConversationParticipantsCompanion toCompanion(bool nullToAbsent) {
    return ConversationParticipantsCompanion(
      id: Value(id),
      conversationId: Value(conversationId),
      characterId: Value(characterId),
      sortOrder: Value(sortOrder),
      enabled: Value(enabled),
      createdAt: Value(createdAt),
    );
  }

  factory ConversationParticipantRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConversationParticipantRow(
      id: serializer.fromJson<String>(json['id']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      characterId: serializer.fromJson<String>(json['characterId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'conversationId': serializer.toJson<String>(conversationId),
      'characterId': serializer.toJson<String>(characterId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'enabled': serializer.toJson<bool>(enabled),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ConversationParticipantRow copyWith({
    String? id,
    String? conversationId,
    String? characterId,
    int? sortOrder,
    bool? enabled,
    DateTime? createdAt,
  }) => ConversationParticipantRow(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    characterId: characterId ?? this.characterId,
    sortOrder: sortOrder ?? this.sortOrder,
    enabled: enabled ?? this.enabled,
    createdAt: createdAt ?? this.createdAt,
  );
  ConversationParticipantRow copyWithCompanion(
    ConversationParticipantsCompanion data,
  ) {
    return ConversationParticipantRow(
      id: data.id.present ? data.id.value : this.id,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConversationParticipantRow(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('characterId: $characterId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    conversationId,
    characterId,
    sortOrder,
    enabled,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConversationParticipantRow &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.characterId == this.characterId &&
          other.sortOrder == this.sortOrder &&
          other.enabled == this.enabled &&
          other.createdAt == this.createdAt);
}

class ConversationParticipantsCompanion
    extends UpdateCompanion<ConversationParticipantRow> {
  final Value<String> id;
  final Value<String> conversationId;
  final Value<String> characterId;
  final Value<int> sortOrder;
  final Value<bool> enabled;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ConversationParticipantsCompanion({
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.characterId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.enabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationParticipantsCompanion.insert({
    required String id,
    required String conversationId,
    required String characterId,
    this.sortOrder = const Value.absent(),
    this.enabled = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       conversationId = Value(conversationId),
       characterId = Value(characterId),
       createdAt = Value(createdAt);
  static Insertable<ConversationParticipantRow> custom({
    Expression<String>? id,
    Expression<String>? conversationId,
    Expression<String>? characterId,
    Expression<int>? sortOrder,
    Expression<bool>? enabled,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (characterId != null) 'character_id': characterId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (enabled != null) 'enabled': enabled,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationParticipantsCompanion copyWith({
    Value<String>? id,
    Value<String>? conversationId,
    Value<String>? characterId,
    Value<int>? sortOrder,
    Value<bool>? enabled,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ConversationParticipantsCompanion(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      characterId: characterId ?? this.characterId,
      sortOrder: sortOrder ?? this.sortOrder,
      enabled: enabled ?? this.enabled,
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
    if (characterId.present) {
      map['character_id'] = Variable<String>(characterId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
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
    return (StringBuffer('ConversationParticipantsCompanion(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('characterId: $characterId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CharacterVersionsTable extends CharacterVersions
    with TableInfo<$CharacterVersionsTable, CharacterVersionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharacterVersionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<String> characterId = GeneratedColumn<String>(
    'character_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _triggerMeta = const VerificationMeta(
    'trigger',
  );
  @override
  late final GeneratedColumn<String> trigger = GeneratedColumn<String>(
    'trigger',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('save'),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snapshotJsonMeta = const VerificationMeta(
    'snapshotJson',
  );
  @override
  late final GeneratedColumn<String> snapshotJson = GeneratedColumn<String>(
    'snapshot_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    characterId,
    trigger,
    label,
    createdAtMs,
    snapshotJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'character_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CharacterVersionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('trigger')) {
      context.handle(
        _triggerMeta,
        trigger.isAcceptableOrUnknown(data['trigger']!, _triggerMeta),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('snapshot_json')) {
      context.handle(
        _snapshotJsonMeta,
        snapshotJson.isAcceptableOrUnknown(
          data['snapshot_json']!,
          _snapshotJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CharacterVersionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharacterVersionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character_id'],
      )!,
      trigger: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trigger'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      snapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snapshot_json'],
      )!,
    );
  }

  @override
  $CharacterVersionsTable createAlias(String alias) {
    return $CharacterVersionsTable(attachedDatabase, alias);
  }
}

class CharacterVersionRow extends DataClass
    implements Insertable<CharacterVersionRow> {
  final String id;
  final String characterId;

  /// save | manual | restore | import
  final String trigger;
  final String label;

  /// 毫秒时间戳：dateTime() 按秒存，同秒保存无法稳定排序。
  final int createdAtMs;

  /// 快照 JSON：核心字段 + 扩展档案 + 第三方扩展 + source。
  final String snapshotJson;
  const CharacterVersionRow({
    required this.id,
    required this.characterId,
    required this.trigger,
    required this.label,
    required this.createdAtMs,
    required this.snapshotJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['character_id'] = Variable<String>(characterId);
    map['trigger'] = Variable<String>(trigger);
    map['label'] = Variable<String>(label);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['snapshot_json'] = Variable<String>(snapshotJson);
    return map;
  }

  CharacterVersionsCompanion toCompanion(bool nullToAbsent) {
    return CharacterVersionsCompanion(
      id: Value(id),
      characterId: Value(characterId),
      trigger: Value(trigger),
      label: Value(label),
      createdAtMs: Value(createdAtMs),
      snapshotJson: Value(snapshotJson),
    );
  }

  factory CharacterVersionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharacterVersionRow(
      id: serializer.fromJson<String>(json['id']),
      characterId: serializer.fromJson<String>(json['characterId']),
      trigger: serializer.fromJson<String>(json['trigger']),
      label: serializer.fromJson<String>(json['label']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      snapshotJson: serializer.fromJson<String>(json['snapshotJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'characterId': serializer.toJson<String>(characterId),
      'trigger': serializer.toJson<String>(trigger),
      'label': serializer.toJson<String>(label),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'snapshotJson': serializer.toJson<String>(snapshotJson),
    };
  }

  CharacterVersionRow copyWith({
    String? id,
    String? characterId,
    String? trigger,
    String? label,
    int? createdAtMs,
    String? snapshotJson,
  }) => CharacterVersionRow(
    id: id ?? this.id,
    characterId: characterId ?? this.characterId,
    trigger: trigger ?? this.trigger,
    label: label ?? this.label,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    snapshotJson: snapshotJson ?? this.snapshotJson,
  );
  CharacterVersionRow copyWithCompanion(CharacterVersionsCompanion data) {
    return CharacterVersionRow(
      id: data.id.present ? data.id.value : this.id,
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      trigger: data.trigger.present ? data.trigger.value : this.trigger,
      label: data.label.present ? data.label.value : this.label,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      snapshotJson: data.snapshotJson.present
          ? data.snapshotJson.value
          : this.snapshotJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharacterVersionRow(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('trigger: $trigger, ')
          ..write('label: $label, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('snapshotJson: $snapshotJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, characterId, trigger, label, createdAtMs, snapshotJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterVersionRow &&
          other.id == this.id &&
          other.characterId == this.characterId &&
          other.trigger == this.trigger &&
          other.label == this.label &&
          other.createdAtMs == this.createdAtMs &&
          other.snapshotJson == this.snapshotJson);
}

class CharacterVersionsCompanion extends UpdateCompanion<CharacterVersionRow> {
  final Value<String> id;
  final Value<String> characterId;
  final Value<String> trigger;
  final Value<String> label;
  final Value<int> createdAtMs;
  final Value<String> snapshotJson;
  final Value<int> rowid;
  const CharacterVersionsCompanion({
    this.id = const Value.absent(),
    this.characterId = const Value.absent(),
    this.trigger = const Value.absent(),
    this.label = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.snapshotJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CharacterVersionsCompanion.insert({
    required String id,
    required String characterId,
    this.trigger = const Value.absent(),
    this.label = const Value.absent(),
    required int createdAtMs,
    this.snapshotJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       characterId = Value(characterId),
       createdAtMs = Value(createdAtMs);
  static Insertable<CharacterVersionRow> custom({
    Expression<String>? id,
    Expression<String>? characterId,
    Expression<String>? trigger,
    Expression<String>? label,
    Expression<int>? createdAtMs,
    Expression<String>? snapshotJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (characterId != null) 'character_id': characterId,
      if (trigger != null) 'trigger': trigger,
      if (label != null) 'label': label,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (snapshotJson != null) 'snapshot_json': snapshotJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CharacterVersionsCompanion copyWith({
    Value<String>? id,
    Value<String>? characterId,
    Value<String>? trigger,
    Value<String>? label,
    Value<int>? createdAtMs,
    Value<String>? snapshotJson,
    Value<int>? rowid,
  }) {
    return CharacterVersionsCompanion(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      trigger: trigger ?? this.trigger,
      label: label ?? this.label,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      snapshotJson: snapshotJson ?? this.snapshotJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (characterId.present) {
      map['character_id'] = Variable<String>(characterId.value);
    }
    if (trigger.present) {
      map['trigger'] = Variable<String>(trigger.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (snapshotJson.present) {
      map['snapshot_json'] = Variable<String>(snapshotJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharacterVersionsCompanion(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('trigger: $trigger, ')
          ..write('label: $label, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('snapshotJson: $snapshotJson, ')
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
  late final $StickersTable stickers = $StickersTable(this);
  late final $MemoryCursorsTable memoryCursors = $MemoryCursorsTable(this);
  late final $MemoryFactsTable memoryFacts = $MemoryFactsTable(this);
  late final $MessageVariantsTable messageVariants = $MessageVariantsTable(
    this,
  );
  late final $LoreEntriesTable loreEntries = $LoreEntriesTable(this);
  late final $ConversationParticipantsTable conversationParticipants =
      $ConversationParticipantsTable(this);
  late final $CharacterVersionsTable characterVersions =
      $CharacterVersionsTable(this);
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
    stickers,
    memoryCursors,
    memoryFacts,
    messageVariants,
    loreEntries,
    conversationParticipants,
    characterVersions,
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
      Value<String?> backgroundPath,
      Value<String?> parentConversationId,
      Value<String?> branchFromMessageId,
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
      Value<String?> backgroundPath,
      Value<String?> parentConversationId,
      Value<String?> branchFromMessageId,
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

  ColumnFilters<String> get backgroundPath => $composableBuilder(
    column: $table.backgroundPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentConversationId => $composableBuilder(
    column: $table.parentConversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchFromMessageId => $composableBuilder(
    column: $table.branchFromMessageId,
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

  ColumnOrderings<String> get backgroundPath => $composableBuilder(
    column: $table.backgroundPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentConversationId => $composableBuilder(
    column: $table.parentConversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchFromMessageId => $composableBuilder(
    column: $table.branchFromMessageId,
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

  GeneratedColumn<String> get backgroundPath => $composableBuilder(
    column: $table.backgroundPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parentConversationId => $composableBuilder(
    column: $table.parentConversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get branchFromMessageId => $composableBuilder(
    column: $table.branchFromMessageId,
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
                Value<String?> backgroundPath = const Value.absent(),
                Value<String?> parentConversationId = const Value.absent(),
                Value<String?> branchFromMessageId = const Value.absent(),
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
                backgroundPath: backgroundPath,
                parentConversationId: parentConversationId,
                branchFromMessageId: branchFromMessageId,
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
                Value<String?> backgroundPath = const Value.absent(),
                Value<String?> parentConversationId = const Value.absent(),
                Value<String?> branchFromMessageId = const Value.absent(),
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
                backgroundPath: backgroundPath,
                parentConversationId: parentConversationId,
                branchFromMessageId: branchFromMessageId,
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
  Value<String> imagePaths,
  Value<String> imageSummary,
  Value<String> status,
  Value<String> kind,
  Value<String?> activeVariantId,
  Value<String?> speakerCharacterId,
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
  Value<String> imagePaths,
  Value<String> imageSummary,
  Value<String> status,
  Value<String> kind,
  Value<String?> activeVariantId,
  Value<String?> speakerCharacterId,
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

  ColumnFilters<String> get imagePaths => $composableBuilder(
    column: $table.imagePaths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageSummary => $composableBuilder(
    column: $table.imageSummary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activeVariantId => $composableBuilder(
    column: $table.activeVariantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get speakerCharacterId => $composableBuilder(
    column: $table.speakerCharacterId,
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

  ColumnOrderings<String> get imagePaths => $composableBuilder(
    column: $table.imagePaths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageSummary => $composableBuilder(
    column: $table.imageSummary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activeVariantId => $composableBuilder(
    column: $table.activeVariantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get speakerCharacterId => $composableBuilder(
    column: $table.speakerCharacterId,
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

  GeneratedColumn<String> get imagePaths => $composableBuilder(
    column: $table.imagePaths,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageSummary => $composableBuilder(
    column: $table.imageSummary,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get activeVariantId => $composableBuilder(
    column: $table.activeVariantId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get speakerCharacterId => $composableBuilder(
    column: $table.speakerCharacterId,
    builder: (column) => column,
  );

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
                Value<String> imagePaths = const Value.absent(),
                Value<String> imageSummary = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> activeVariantId = const Value.absent(),
                Value<String?> speakerCharacterId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                conversationId: conversationId,
                role: role,
                content: content,
                rawContent: rawContent,
                emotionEvents: emotionEvents,
                imagePaths: imagePaths,
                imageSummary: imageSummary,
                status: status,
                kind: kind,
                activeVariantId: activeVariantId,
                speakerCharacterId: speakerCharacterId,
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
                Value<String> imagePaths = const Value.absent(),
                Value<String> imageSummary = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> activeVariantId = const Value.absent(),
                Value<String?> speakerCharacterId = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion.insert(
                id: id,
                conversationId: conversationId,
                role: role,
                content: content,
                rawContent: rawContent,
                emotionEvents: emotionEvents,
                imagePaths: imagePaths,
                imageSummary: imageSummary,
                status: status,
                kind: kind,
                activeVariantId: activeVariantId,
                speakerCharacterId: speakerCharacterId,
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
  Value<String> alternateGreetings,
  Value<String?> avatarPath,
  Value<String> source,
  Value<String> profileJson,
  Value<String> extensionsJson,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String> memorySummary,
  Value<String> userSummary,
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
  Value<String> alternateGreetings,
  Value<String?> avatarPath,
  Value<String> source,
  Value<String> profileJson,
  Value<String> extensionsJson,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> memorySummary,
  Value<String> userSummary,
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

  ColumnFilters<String> get alternateGreetings => $composableBuilder(
    column: $table.alternateGreetings,
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

  ColumnFilters<String> get profileJson => $composableBuilder(
    column: $table.profileJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extensionsJson => $composableBuilder(
    column: $table.extensionsJson,
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

  ColumnFilters<String> get userSummary => $composableBuilder(
    column: $table.userSummary,
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

  ColumnOrderings<String> get alternateGreetings => $composableBuilder(
    column: $table.alternateGreetings,
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

  ColumnOrderings<String> get profileJson => $composableBuilder(
    column: $table.profileJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extensionsJson => $composableBuilder(
    column: $table.extensionsJson,
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

  ColumnOrderings<String> get userSummary => $composableBuilder(
    column: $table.userSummary,
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

  GeneratedColumn<String> get alternateGreetings => $composableBuilder(
    column: $table.alternateGreetings,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get profileJson => $composableBuilder(
    column: $table.profileJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get extensionsJson => $composableBuilder(
    column: $table.extensionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get memorySummary => $composableBuilder(
    column: $table.memorySummary,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userSummary => $composableBuilder(
    column: $table.userSummary,
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
                Value<String> alternateGreetings = const Value.absent(),
                Value<String?> avatarPath = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> profileJson = const Value.absent(),
                Value<String> extensionsJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> memorySummary = const Value.absent(),
                Value<String> userSummary = const Value.absent(),
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
                alternateGreetings: alternateGreetings,
                avatarPath: avatarPath,
                source: source,
                profileJson: profileJson,
                extensionsJson: extensionsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                memorySummary: memorySummary,
                userSummary: userSummary,
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
                Value<String> alternateGreetings = const Value.absent(),
                Value<String?> avatarPath = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> profileJson = const Value.absent(),
                Value<String> extensionsJson = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String> memorySummary = const Value.absent(),
                Value<String> userSummary = const Value.absent(),
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
                alternateGreetings: alternateGreetings,
                avatarPath: avatarPath,
                source: source,
                profileJson: profileJson,
                extensionsJson: extensionsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                memorySummary: memorySummary,
                userSummary: userSummary,
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
typedef $$StickersTableCreateCompanionBuilder = StickersCompanion Function({
  required String id,
  required String characterId,
  required String mood,
  required String filePath,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$StickersTableUpdateCompanionBuilder = StickersCompanion Function({
  Value<String> id,
  Value<String> characterId,
  Value<String> mood,
  Value<String> filePath,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$StickersTableFilterComposer
    extends Composer<_$AppDatabase, $StickersTable> {
  $$StickersTableFilterComposer({
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

  ColumnFilters<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StickersTableOrderingComposer
    extends Composer<_$AppDatabase, $StickersTable> {
  $$StickersTableOrderingComposer({
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

  ColumnOrderings<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StickersTableAnnotationComposer
    extends Composer<_$AppDatabase, $StickersTable> {
  $$StickersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$StickersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StickersTable,
          StickerRow,
          $$StickersTableFilterComposer,
          $$StickersTableOrderingComposer,
          $$StickersTableAnnotationComposer,
          $$StickersTableCreateCompanionBuilder,
          $$StickersTableUpdateCompanionBuilder,
          (
            StickerRow,
            BaseReferences<_$AppDatabase, $StickersTable, StickerRow>,
          ),
          StickerRow,
          PrefetchHooks Function()
        > {
  $$StickersTableTableManager(_$AppDatabase db, $StickersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StickersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StickersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StickersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> characterId = const Value.absent(),
                Value<String> mood = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StickersCompanion(
                id: id,
                characterId: characterId,
                mood: mood,
                filePath: filePath,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String characterId,
                required String mood,
                required String filePath,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => StickersCompanion.insert(
                id: id,
                characterId: characterId,
                mood: mood,
                filePath: filePath,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StickersTable, StickerRow>(table),
                  BaseReferences<_$AppDatabase, $StickersTable, StickerRow>(
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

typedef $$StickersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StickersTable,
      StickerRow,
      $$StickersTableFilterComposer,
      $$StickersTableOrderingComposer,
      $$StickersTableAnnotationComposer,
      $$StickersTableCreateCompanionBuilder,
      $$StickersTableUpdateCompanionBuilder,
      (StickerRow, BaseReferences<_$AppDatabase, $StickersTable, StickerRow>),
      StickerRow,
      PrefetchHooks Function()
    >;
typedef $$MemoryCursorsTableCreateCompanionBuilder =
    MemoryCursorsCompanion Function({
      required String characterId,
      required String conversationId,
      required DateTime summarizedAt,
      Value<int> rowid,
    });
typedef $$MemoryCursorsTableUpdateCompanionBuilder =
    MemoryCursorsCompanion Function({
      Value<String> characterId,
      Value<String> conversationId,
      Value<DateTime> summarizedAt,
      Value<int> rowid,
    });

class $$MemoryCursorsTableFilterComposer
    extends Composer<_$AppDatabase, $MemoryCursorsTable> {
  $$MemoryCursorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get summarizedAt => $composableBuilder(
    column: $table.summarizedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MemoryCursorsTableOrderingComposer
    extends Composer<_$AppDatabase, $MemoryCursorsTable> {
  $$MemoryCursorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get summarizedAt => $composableBuilder(
    column: $table.summarizedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MemoryCursorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemoryCursorsTable> {
  $$MemoryCursorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get summarizedAt => $composableBuilder(
    column: $table.summarizedAt,
    builder: (column) => column,
  );
}

class $$MemoryCursorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MemoryCursorsTable,
          MemoryCursorRow,
          $$MemoryCursorsTableFilterComposer,
          $$MemoryCursorsTableOrderingComposer,
          $$MemoryCursorsTableAnnotationComposer,
          $$MemoryCursorsTableCreateCompanionBuilder,
          $$MemoryCursorsTableUpdateCompanionBuilder,
          (
            MemoryCursorRow,
            BaseReferences<_$AppDatabase, $MemoryCursorsTable, MemoryCursorRow>,
          ),
          MemoryCursorRow,
          PrefetchHooks Function()
        > {
  $$MemoryCursorsTableTableManager(_$AppDatabase db, $MemoryCursorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemoryCursorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemoryCursorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemoryCursorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> characterId = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<DateTime> summarizedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemoryCursorsCompanion(
                characterId: characterId,
                conversationId: conversationId,
                summarizedAt: summarizedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String characterId,
                required String conversationId,
                required DateTime summarizedAt,
                Value<int> rowid = const Value.absent(),
              }) => MemoryCursorsCompanion.insert(
                characterId: characterId,
                conversationId: conversationId,
                summarizedAt: summarizedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MemoryCursorsTable, MemoryCursorRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MemoryCursorsTable,
                    MemoryCursorRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MemoryCursorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MemoryCursorsTable,
      MemoryCursorRow,
      $$MemoryCursorsTableFilterComposer,
      $$MemoryCursorsTableOrderingComposer,
      $$MemoryCursorsTableAnnotationComposer,
      $$MemoryCursorsTableCreateCompanionBuilder,
      $$MemoryCursorsTableUpdateCompanionBuilder,
      (
        MemoryCursorRow,
        BaseReferences<_$AppDatabase, $MemoryCursorsTable, MemoryCursorRow>,
      ),
      MemoryCursorRow,
      PrefetchHooks Function()
    >;
typedef $$MemoryFactsTableCreateCompanionBuilder =
    MemoryFactsCompanion Function({
      required String id,
      required String characterId,
      required String fact,
      required DateTime occurredAt,
      Value<String?> sourceConversationId,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$MemoryFactsTableUpdateCompanionBuilder =
    MemoryFactsCompanion Function({
      Value<String> id,
      Value<String> characterId,
      Value<String> fact,
      Value<DateTime> occurredAt,
      Value<String?> sourceConversationId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$MemoryFactsTableFilterComposer
    extends Composer<_$AppDatabase, $MemoryFactsTable> {
  $$MemoryFactsTableFilterComposer({
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

  ColumnFilters<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fact => $composableBuilder(
    column: $table.fact,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceConversationId => $composableBuilder(
    column: $table.sourceConversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MemoryFactsTableOrderingComposer
    extends Composer<_$AppDatabase, $MemoryFactsTable> {
  $$MemoryFactsTableOrderingComposer({
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

  ColumnOrderings<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fact => $composableBuilder(
    column: $table.fact,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceConversationId => $composableBuilder(
    column: $table.sourceConversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MemoryFactsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemoryFactsTable> {
  $$MemoryFactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fact =>
      $composableBuilder(column: $table.fact, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceConversationId => $composableBuilder(
    column: $table.sourceConversationId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MemoryFactsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MemoryFactsTable,
          MemoryFactRow,
          $$MemoryFactsTableFilterComposer,
          $$MemoryFactsTableOrderingComposer,
          $$MemoryFactsTableAnnotationComposer,
          $$MemoryFactsTableCreateCompanionBuilder,
          $$MemoryFactsTableUpdateCompanionBuilder,
          (
            MemoryFactRow,
            BaseReferences<_$AppDatabase, $MemoryFactsTable, MemoryFactRow>,
          ),
          MemoryFactRow,
          PrefetchHooks Function()
        > {
  $$MemoryFactsTableTableManager(_$AppDatabase db, $MemoryFactsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemoryFactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemoryFactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemoryFactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> characterId = const Value.absent(),
                Value<String> fact = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String?> sourceConversationId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemoryFactsCompanion(
                id: id,
                characterId: characterId,
                fact: fact,
                occurredAt: occurredAt,
                sourceConversationId: sourceConversationId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String characterId,
                required String fact,
                required DateTime occurredAt,
                Value<String?> sourceConversationId = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => MemoryFactsCompanion.insert(
                id: id,
                characterId: characterId,
                fact: fact,
                occurredAt: occurredAt,
                sourceConversationId: sourceConversationId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MemoryFactsTable, MemoryFactRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MemoryFactsTable,
                    MemoryFactRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MemoryFactsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MemoryFactsTable,
      MemoryFactRow,
      $$MemoryFactsTableFilterComposer,
      $$MemoryFactsTableOrderingComposer,
      $$MemoryFactsTableAnnotationComposer,
      $$MemoryFactsTableCreateCompanionBuilder,
      $$MemoryFactsTableUpdateCompanionBuilder,
      (
        MemoryFactRow,
        BaseReferences<_$AppDatabase, $MemoryFactsTable, MemoryFactRow>,
      ),
      MemoryFactRow,
      PrefetchHooks Function()
    >;
typedef $$MessageVariantsTableCreateCompanionBuilder =
    MessageVariantsCompanion Function({
      required String id,
      required String messageId,
      Value<String> content,
      Value<String> rawContent,
      Value<String> emotionEvents,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$MessageVariantsTableUpdateCompanionBuilder =
    MessageVariantsCompanion Function({
      Value<String> id,
      Value<String> messageId,
      Value<String> content,
      Value<String> rawContent,
      Value<String> emotionEvents,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$MessageVariantsTableFilterComposer
    extends Composer<_$AppDatabase, $MessageVariantsTable> {
  $$MessageVariantsTableFilterComposer({
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

  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessageVariantsTableOrderingComposer
    extends Composer<_$AppDatabase, $MessageVariantsTable> {
  $$MessageVariantsTableOrderingComposer({
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

  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessageVariantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessageVariantsTable> {
  $$MessageVariantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

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

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MessageVariantsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessageVariantsTable,
          MessageVariantRow,
          $$MessageVariantsTableFilterComposer,
          $$MessageVariantsTableOrderingComposer,
          $$MessageVariantsTableAnnotationComposer,
          $$MessageVariantsTableCreateCompanionBuilder,
          $$MessageVariantsTableUpdateCompanionBuilder,
          (
            MessageVariantRow,
            BaseReferences<
              _$AppDatabase,
              $MessageVariantsTable,
              MessageVariantRow
            >,
          ),
          MessageVariantRow,
          PrefetchHooks Function()
        > {
  $$MessageVariantsTableTableManager(
    _$AppDatabase db,
    $MessageVariantsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessageVariantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessageVariantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessageVariantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> messageId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> rawContent = const Value.absent(),
                Value<String> emotionEvents = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessageVariantsCompanion(
                id: id,
                messageId: messageId,
                content: content,
                rawContent: rawContent,
                emotionEvents: emotionEvents,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String messageId,
                Value<String> content = const Value.absent(),
                Value<String> rawContent = const Value.absent(),
                Value<String> emotionEvents = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => MessageVariantsCompanion.insert(
                id: id,
                messageId: messageId,
                content: content,
                rawContent: rawContent,
                emotionEvents: emotionEvents,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MessageVariantsTable, MessageVariantRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MessageVariantsTable,
                    MessageVariantRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessageVariantsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessageVariantsTable,
      MessageVariantRow,
      $$MessageVariantsTableFilterComposer,
      $$MessageVariantsTableOrderingComposer,
      $$MessageVariantsTableAnnotationComposer,
      $$MessageVariantsTableCreateCompanionBuilder,
      $$MessageVariantsTableUpdateCompanionBuilder,
      (
        MessageVariantRow,
        BaseReferences<_$AppDatabase, $MessageVariantsTable, MessageVariantRow>,
      ),
      MessageVariantRow,
      PrefetchHooks Function()
    >;
typedef $$LoreEntriesTableCreateCompanionBuilder =
    LoreEntriesCompanion Function({
      required String id,
      required String characterId,
      Value<String> keys,
      Value<String> content,
      Value<String> position,
      Value<int> depth,
      Value<int> priority,
      Value<bool> enabled,
      Value<String> sourceJson,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$LoreEntriesTableUpdateCompanionBuilder =
    LoreEntriesCompanion Function({
      Value<String> id,
      Value<String> characterId,
      Value<String> keys,
      Value<String> content,
      Value<String> position,
      Value<int> depth,
      Value<int> priority,
      Value<bool> enabled,
      Value<String> sourceJson,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$LoreEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LoreEntriesTable> {
  $$LoreEntriesTableFilterComposer({
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

  ColumnFilters<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keys => $composableBuilder(
    column: $table.keys,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get depth => $composableBuilder(
    column: $table.depth,
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

  ColumnFilters<String> get sourceJson => $composableBuilder(
    column: $table.sourceJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LoreEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LoreEntriesTable> {
  $$LoreEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keys => $composableBuilder(
    column: $table.keys,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get depth => $composableBuilder(
    column: $table.depth,
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

  ColumnOrderings<String> get sourceJson => $composableBuilder(
    column: $table.sourceJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LoreEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LoreEntriesTable> {
  $$LoreEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get keys =>
      $composableBuilder(column: $table.keys, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get depth =>
      $composableBuilder(column: $table.depth, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<String> get sourceJson => $composableBuilder(
    column: $table.sourceJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LoreEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LoreEntriesTable,
          LoreEntryRow,
          $$LoreEntriesTableFilterComposer,
          $$LoreEntriesTableOrderingComposer,
          $$LoreEntriesTableAnnotationComposer,
          $$LoreEntriesTableCreateCompanionBuilder,
          $$LoreEntriesTableUpdateCompanionBuilder,
          (
            LoreEntryRow,
            BaseReferences<_$AppDatabase, $LoreEntriesTable, LoreEntryRow>,
          ),
          LoreEntryRow,
          PrefetchHooks Function()
        > {
  $$LoreEntriesTableTableManager(_$AppDatabase db, $LoreEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoreEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoreEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoreEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> characterId = const Value.absent(),
                Value<String> keys = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> position = const Value.absent(),
                Value<int> depth = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String> sourceJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LoreEntriesCompanion(
                id: id,
                characterId: characterId,
                keys: keys,
                content: content,
                position: position,
                depth: depth,
                priority: priority,
                enabled: enabled,
                sourceJson: sourceJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String characterId,
                Value<String> keys = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> position = const Value.absent(),
                Value<int> depth = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String> sourceJson = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LoreEntriesCompanion.insert(
                id: id,
                characterId: characterId,
                keys: keys,
                content: content,
                position: position,
                depth: depth,
                priority: priority,
                enabled: enabled,
                sourceJson: sourceJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LoreEntriesTable, LoreEntryRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LoreEntriesTable,
                    LoreEntryRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LoreEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LoreEntriesTable,
      LoreEntryRow,
      $$LoreEntriesTableFilterComposer,
      $$LoreEntriesTableOrderingComposer,
      $$LoreEntriesTableAnnotationComposer,
      $$LoreEntriesTableCreateCompanionBuilder,
      $$LoreEntriesTableUpdateCompanionBuilder,
      (
        LoreEntryRow,
        BaseReferences<_$AppDatabase, $LoreEntriesTable, LoreEntryRow>,
      ),
      LoreEntryRow,
      PrefetchHooks Function()
    >;
typedef $$ConversationParticipantsTableCreateCompanionBuilder =
    ConversationParticipantsCompanion Function({
      required String id,
      required String conversationId,
      required String characterId,
      Value<int> sortOrder,
      Value<bool> enabled,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ConversationParticipantsTableUpdateCompanionBuilder =
    ConversationParticipantsCompanion Function({
      Value<String> id,
      Value<String> conversationId,
      Value<String> characterId,
      Value<int> sortOrder,
      Value<bool> enabled,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ConversationParticipantsTableFilterComposer
    extends Composer<_$AppDatabase, $ConversationParticipantsTable> {
  $$ConversationParticipantsTableFilterComposer({
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

  ColumnFilters<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConversationParticipantsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConversationParticipantsTable> {
  $$ConversationParticipantsTableOrderingComposer({
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

  ColumnOrderings<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConversationParticipantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConversationParticipantsTable> {
  $$ConversationParticipantsTableAnnotationComposer({
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

  GeneratedColumn<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ConversationParticipantsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConversationParticipantsTable,
          ConversationParticipantRow,
          $$ConversationParticipantsTableFilterComposer,
          $$ConversationParticipantsTableOrderingComposer,
          $$ConversationParticipantsTableAnnotationComposer,
          $$ConversationParticipantsTableCreateCompanionBuilder,
          $$ConversationParticipantsTableUpdateCompanionBuilder,
          (
            ConversationParticipantRow,
            BaseReferences<
              _$AppDatabase,
              $ConversationParticipantsTable,
              ConversationParticipantRow
            >,
          ),
          ConversationParticipantRow,
          PrefetchHooks Function()
        > {
  $$ConversationParticipantsTableTableManager(
    _$AppDatabase db,
    $ConversationParticipantsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationParticipantsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ConversationParticipantsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ConversationParticipantsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String> characterId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationParticipantsCompanion(
                id: id,
                conversationId: conversationId,
                characterId: characterId,
                sortOrder: sortOrder,
                enabled: enabled,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String conversationId,
                required String characterId,
                Value<int> sortOrder = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ConversationParticipantsCompanion.insert(
                id: id,
                conversationId: conversationId,
                characterId: characterId,
                sortOrder: sortOrder,
                enabled: enabled,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $ConversationParticipantsTable,
                    ConversationParticipantRow
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ConversationParticipantsTable,
                    ConversationParticipantRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConversationParticipantsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConversationParticipantsTable,
      ConversationParticipantRow,
      $$ConversationParticipantsTableFilterComposer,
      $$ConversationParticipantsTableOrderingComposer,
      $$ConversationParticipantsTableAnnotationComposer,
      $$ConversationParticipantsTableCreateCompanionBuilder,
      $$ConversationParticipantsTableUpdateCompanionBuilder,
      (
        ConversationParticipantRow,
        BaseReferences<
          _$AppDatabase,
          $ConversationParticipantsTable,
          ConversationParticipantRow
        >,
      ),
      ConversationParticipantRow,
      PrefetchHooks Function()
    >;
typedef $$CharacterVersionsTableCreateCompanionBuilder =
    CharacterVersionsCompanion Function({
      required String id,
      required String characterId,
      Value<String> trigger,
      Value<String> label,
      required int createdAtMs,
      Value<String> snapshotJson,
      Value<int> rowid,
    });
typedef $$CharacterVersionsTableUpdateCompanionBuilder =
    CharacterVersionsCompanion Function({
      Value<String> id,
      Value<String> characterId,
      Value<String> trigger,
      Value<String> label,
      Value<int> createdAtMs,
      Value<String> snapshotJson,
      Value<int> rowid,
    });

class $$CharacterVersionsTableFilterComposer
    extends Composer<_$AppDatabase, $CharacterVersionsTable> {
  $$CharacterVersionsTableFilterComposer({
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

  ColumnFilters<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trigger => $composableBuilder(
    column: $table.trigger,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snapshotJson => $composableBuilder(
    column: $table.snapshotJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CharacterVersionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CharacterVersionsTable> {
  $$CharacterVersionsTableOrderingComposer({
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

  ColumnOrderings<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trigger => $composableBuilder(
    column: $table.trigger,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snapshotJson => $composableBuilder(
    column: $table.snapshotJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CharacterVersionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CharacterVersionsTable> {
  $$CharacterVersionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trigger =>
      $composableBuilder(column: $table.trigger, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get snapshotJson => $composableBuilder(
    column: $table.snapshotJson,
    builder: (column) => column,
  );
}

class $$CharacterVersionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CharacterVersionsTable,
          CharacterVersionRow,
          $$CharacterVersionsTableFilterComposer,
          $$CharacterVersionsTableOrderingComposer,
          $$CharacterVersionsTableAnnotationComposer,
          $$CharacterVersionsTableCreateCompanionBuilder,
          $$CharacterVersionsTableUpdateCompanionBuilder,
          (
            CharacterVersionRow,
            BaseReferences<
              _$AppDatabase,
              $CharacterVersionsTable,
              CharacterVersionRow
            >,
          ),
          CharacterVersionRow,
          PrefetchHooks Function()
        > {
  $$CharacterVersionsTableTableManager(
    _$AppDatabase db,
    $CharacterVersionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharacterVersionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharacterVersionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharacterVersionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> characterId = const Value.absent(),
                Value<String> trigger = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<String> snapshotJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharacterVersionsCompanion(
                id: id,
                characterId: characterId,
                trigger: trigger,
                label: label,
                createdAtMs: createdAtMs,
                snapshotJson: snapshotJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String characterId,
                Value<String> trigger = const Value.absent(),
                Value<String> label = const Value.absent(),
                required int createdAtMs,
                Value<String> snapshotJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharacterVersionsCompanion.insert(
                id: id,
                characterId: characterId,
                trigger: trigger,
                label: label,
                createdAtMs: createdAtMs,
                snapshotJson: snapshotJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CharacterVersionsTable, CharacterVersionRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $CharacterVersionsTable,
                    CharacterVersionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CharacterVersionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CharacterVersionsTable,
      CharacterVersionRow,
      $$CharacterVersionsTableFilterComposer,
      $$CharacterVersionsTableOrderingComposer,
      $$CharacterVersionsTableAnnotationComposer,
      $$CharacterVersionsTableCreateCompanionBuilder,
      $$CharacterVersionsTableUpdateCompanionBuilder,
      (
        CharacterVersionRow,
        BaseReferences<
          _$AppDatabase,
          $CharacterVersionsTable,
          CharacterVersionRow
        >,
      ),
      CharacterVersionRow,
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
  $$StickersTableTableManager get stickers =>
      $$StickersTableTableManager(_db, _db.stickers);
  $$MemoryCursorsTableTableManager get memoryCursors =>
      $$MemoryCursorsTableTableManager(_db, _db.memoryCursors);
  $$MemoryFactsTableTableManager get memoryFacts =>
      $$MemoryFactsTableTableManager(_db, _db.memoryFacts);
  $$MessageVariantsTableTableManager get messageVariants =>
      $$MessageVariantsTableTableManager(_db, _db.messageVariants);
  $$LoreEntriesTableTableManager get loreEntries =>
      $$LoreEntriesTableTableManager(_db, _db.loreEntries);
  $$ConversationParticipantsTableTableManager get conversationParticipants =>
      $$ConversationParticipantsTableTableManager(
        _db,
        _db.conversationParticipants,
      );
  $$CharacterVersionsTableTableManager get characterVersions =>
      $$CharacterVersionsTableTableManager(_db, _db.characterVersions);
}
