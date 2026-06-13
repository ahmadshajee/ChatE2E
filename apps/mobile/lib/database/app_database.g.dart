// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalMessagesTable extends LocalMessages
    with TableInfo<$LocalMessagesTable, LocalMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMessagesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _senderIdMeta = const VerificationMeta(
    'senderId',
  );
  @override
  late final GeneratedColumn<String> senderId = GeneratedColumn<String>(
    'sender_id',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
    'sent_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _isMineMeta = const VerificationMeta('isMine');
  @override
  late final GeneratedColumn<bool> isMine = GeneratedColumn<bool>(
    'is_mine',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_mine" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _envelopeIdMeta = const VerificationMeta(
    'envelopeId',
  );
  @override
  late final GeneratedColumn<String> envelopeId = GeneratedColumn<String>(
    'envelope_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentMessageIdMeta = const VerificationMeta(
    'parentMessageId',
  );
  @override
  late final GeneratedColumn<String> parentMessageId = GeneratedColumn<String>(
    'parent_message_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reactionMeta = const VerificationMeta(
    'reaction',
  );
  @override
  late final GeneratedColumn<String> reaction = GeneratedColumn<String>(
    'reaction',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    conversationId,
    senderId,
    content,
    sentAt,
    status,
    isMine,
    envelopeId,
    parentMessageId,
    reaction,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMessage> instance, {
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
    if (data.containsKey('sender_id')) {
      context.handle(
        _senderIdMeta,
        senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    } else if (isInserting) {
      context.missing(_sentAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('is_mine')) {
      context.handle(
        _isMineMeta,
        isMine.isAcceptableOrUnknown(data['is_mine']!, _isMineMeta),
      );
    }
    if (data.containsKey('envelope_id')) {
      context.handle(
        _envelopeIdMeta,
        envelopeId.isAcceptableOrUnknown(data['envelope_id']!, _envelopeIdMeta),
      );
    }
    if (data.containsKey('parent_message_id')) {
      context.handle(
        _parentMessageIdMeta,
        parentMessageId.isAcceptableOrUnknown(
          data['parent_message_id']!,
          _parentMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('reaction')) {
      context.handle(
        _reactionMeta,
        reaction.isAcceptableOrUnknown(data['reaction']!, _reactionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMessage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      senderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sent_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      isMine: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_mine'],
      )!,
      envelopeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}envelope_id'],
      ),
      parentMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_message_id'],
      ),
      reaction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reaction'],
      ),
    );
  }

  @override
  $LocalMessagesTable createAlias(String alias) {
    return $LocalMessagesTable(attachedDatabase, alias);
  }
}

class LocalMessage extends DataClass implements Insertable<LocalMessage> {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime sentAt;
  final String status;
  final bool isMine;
  final String? envelopeId;
  final String? parentMessageId;
  final String? reaction;
  const LocalMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.sentAt,
    required this.status,
    required this.isMine,
    this.envelopeId,
    this.parentMessageId,
    this.reaction,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['conversation_id'] = Variable<String>(conversationId);
    map['sender_id'] = Variable<String>(senderId);
    map['content'] = Variable<String>(content);
    map['sent_at'] = Variable<DateTime>(sentAt);
    map['status'] = Variable<String>(status);
    map['is_mine'] = Variable<bool>(isMine);
    if (!nullToAbsent || envelopeId != null) {
      map['envelope_id'] = Variable<String>(envelopeId);
    }
    if (!nullToAbsent || parentMessageId != null) {
      map['parent_message_id'] = Variable<String>(parentMessageId);
    }
    if (!nullToAbsent || reaction != null) {
      map['reaction'] = Variable<String>(reaction);
    }
    return map;
  }

  LocalMessagesCompanion toCompanion(bool nullToAbsent) {
    return LocalMessagesCompanion(
      id: Value(id),
      conversationId: Value(conversationId),
      senderId: Value(senderId),
      content: Value(content),
      sentAt: Value(sentAt),
      status: Value(status),
      isMine: Value(isMine),
      envelopeId: envelopeId == null && nullToAbsent
          ? const Value.absent()
          : Value(envelopeId),
      parentMessageId: parentMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentMessageId),
      reaction: reaction == null && nullToAbsent
          ? const Value.absent()
          : Value(reaction),
    );
  }

  factory LocalMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMessage(
      id: serializer.fromJson<String>(json['id']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      senderId: serializer.fromJson<String>(json['senderId']),
      content: serializer.fromJson<String>(json['content']),
      sentAt: serializer.fromJson<DateTime>(json['sentAt']),
      status: serializer.fromJson<String>(json['status']),
      isMine: serializer.fromJson<bool>(json['isMine']),
      envelopeId: serializer.fromJson<String?>(json['envelopeId']),
      parentMessageId: serializer.fromJson<String?>(json['parentMessageId']),
      reaction: serializer.fromJson<String?>(json['reaction']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'conversationId': serializer.toJson<String>(conversationId),
      'senderId': serializer.toJson<String>(senderId),
      'content': serializer.toJson<String>(content),
      'sentAt': serializer.toJson<DateTime>(sentAt),
      'status': serializer.toJson<String>(status),
      'isMine': serializer.toJson<bool>(isMine),
      'envelopeId': serializer.toJson<String?>(envelopeId),
      'parentMessageId': serializer.toJson<String?>(parentMessageId),
      'reaction': serializer.toJson<String?>(reaction),
    };
  }

  LocalMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    DateTime? sentAt,
    String? status,
    bool? isMine,
    Value<String?> envelopeId = const Value.absent(),
    Value<String?> parentMessageId = const Value.absent(),
    Value<String?> reaction = const Value.absent(),
  }) => LocalMessage(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    senderId: senderId ?? this.senderId,
    content: content ?? this.content,
    sentAt: sentAt ?? this.sentAt,
    status: status ?? this.status,
    isMine: isMine ?? this.isMine,
    envelopeId: envelopeId.present ? envelopeId.value : this.envelopeId,
    parentMessageId: parentMessageId.present
        ? parentMessageId.value
        : this.parentMessageId,
    reaction: reaction.present ? reaction.value : this.reaction,
  );
  LocalMessage copyWithCompanion(LocalMessagesCompanion data) {
    return LocalMessage(
      id: data.id.present ? data.id.value : this.id,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      content: data.content.present ? data.content.value : this.content,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      status: data.status.present ? data.status.value : this.status,
      isMine: data.isMine.present ? data.isMine.value : this.isMine,
      envelopeId: data.envelopeId.present
          ? data.envelopeId.value
          : this.envelopeId,
      parentMessageId: data.parentMessageId.present
          ? data.parentMessageId.value
          : this.parentMessageId,
      reaction: data.reaction.present ? data.reaction.value : this.reaction,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMessage(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('senderId: $senderId, ')
          ..write('content: $content, ')
          ..write('sentAt: $sentAt, ')
          ..write('status: $status, ')
          ..write('isMine: $isMine, ')
          ..write('envelopeId: $envelopeId, ')
          ..write('parentMessageId: $parentMessageId, ')
          ..write('reaction: $reaction')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    conversationId,
    senderId,
    content,
    sentAt,
    status,
    isMine,
    envelopeId,
    parentMessageId,
    reaction,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMessage &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.senderId == this.senderId &&
          other.content == this.content &&
          other.sentAt == this.sentAt &&
          other.status == this.status &&
          other.isMine == this.isMine &&
          other.envelopeId == this.envelopeId &&
          other.parentMessageId == this.parentMessageId &&
          other.reaction == this.reaction);
}

class LocalMessagesCompanion extends UpdateCompanion<LocalMessage> {
  final Value<String> id;
  final Value<String> conversationId;
  final Value<String> senderId;
  final Value<String> content;
  final Value<DateTime> sentAt;
  final Value<String> status;
  final Value<bool> isMine;
  final Value<String?> envelopeId;
  final Value<String?> parentMessageId;
  final Value<String?> reaction;
  final Value<int> rowid;
  const LocalMessagesCompanion({
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.content = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.status = const Value.absent(),
    this.isMine = const Value.absent(),
    this.envelopeId = const Value.absent(),
    this.parentMessageId = const Value.absent(),
    this.reaction = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMessagesCompanion.insert({
    required String id,
    required String conversationId,
    required String senderId,
    required String content,
    required DateTime sentAt,
    this.status = const Value.absent(),
    this.isMine = const Value.absent(),
    this.envelopeId = const Value.absent(),
    this.parentMessageId = const Value.absent(),
    this.reaction = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       conversationId = Value(conversationId),
       senderId = Value(senderId),
       content = Value(content),
       sentAt = Value(sentAt);
  static Insertable<LocalMessage> custom({
    Expression<String>? id,
    Expression<String>? conversationId,
    Expression<String>? senderId,
    Expression<String>? content,
    Expression<DateTime>? sentAt,
    Expression<String>? status,
    Expression<bool>? isMine,
    Expression<String>? envelopeId,
    Expression<String>? parentMessageId,
    Expression<String>? reaction,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (senderId != null) 'sender_id': senderId,
      if (content != null) 'content': content,
      if (sentAt != null) 'sent_at': sentAt,
      if (status != null) 'status': status,
      if (isMine != null) 'is_mine': isMine,
      if (envelopeId != null) 'envelope_id': envelopeId,
      if (parentMessageId != null) 'parent_message_id': parentMessageId,
      if (reaction != null) 'reaction': reaction,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? conversationId,
    Value<String>? senderId,
    Value<String>? content,
    Value<DateTime>? sentAt,
    Value<String>? status,
    Value<bool>? isMine,
    Value<String?>? envelopeId,
    Value<String?>? parentMessageId,
    Value<String?>? reaction,
    Value<int>? rowid,
  }) {
    return LocalMessagesCompanion(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
      isMine: isMine ?? this.isMine,
      envelopeId: envelopeId ?? this.envelopeId,
      parentMessageId: parentMessageId ?? this.parentMessageId,
      reaction: reaction ?? this.reaction,
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
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (isMine.present) {
      map['is_mine'] = Variable<bool>(isMine.value);
    }
    if (envelopeId.present) {
      map['envelope_id'] = Variable<String>(envelopeId.value);
    }
    if (parentMessageId.present) {
      map['parent_message_id'] = Variable<String>(parentMessageId.value);
    }
    if (reaction.present) {
      map['reaction'] = Variable<String>(reaction.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMessagesCompanion(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('senderId: $senderId, ')
          ..write('content: $content, ')
          ..write('sentAt: $sentAt, ')
          ..write('status: $status, ')
          ..write('isMine: $isMine, ')
          ..write('envelopeId: $envelopeId, ')
          ..write('parentMessageId: $parentMessageId, ')
          ..write('reaction: $reaction, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalConversationsTable extends LocalConversations
    with TableInfo<$LocalConversationsTable, LocalConversation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peerUserIdMeta = const VerificationMeta(
    'peerUserId',
  );
  @override
  late final GeneratedColumn<String> peerUserId = GeneratedColumn<String>(
    'peer_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peerDisplayNameMeta = const VerificationMeta(
    'peerDisplayName',
  );
  @override
  late final GeneratedColumn<String> peerDisplayName = GeneratedColumn<String>(
    'peer_display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peerEmailMeta = const VerificationMeta(
    'peerEmail',
  );
  @override
  late final GeneratedColumn<String> peerEmail = GeneratedColumn<String>(
    'peer_email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _lastMessageMeta = const VerificationMeta(
    'lastMessage',
  );
  @override
  late final GeneratedColumn<String> lastMessage = GeneratedColumn<String>(
    'last_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessageAtMeta = const VerificationMeta(
    'lastMessageAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastMessageAt =
      GeneratedColumn<DateTime>(
        'last_message_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _unreadCountMeta = const VerificationMeta(
    'unreadCount',
  );
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
    'unread_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    peerUserId,
    peerDisplayName,
    peerEmail,
    lastMessage,
    lastMessageAt,
    unreadCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalConversation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('peer_user_id')) {
      context.handle(
        _peerUserIdMeta,
        peerUserId.isAcceptableOrUnknown(
          data['peer_user_id']!,
          _peerUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_peerUserIdMeta);
    }
    if (data.containsKey('peer_display_name')) {
      context.handle(
        _peerDisplayNameMeta,
        peerDisplayName.isAcceptableOrUnknown(
          data['peer_display_name']!,
          _peerDisplayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_peerDisplayNameMeta);
    }
    if (data.containsKey('peer_email')) {
      context.handle(
        _peerEmailMeta,
        peerEmail.isAcceptableOrUnknown(data['peer_email']!, _peerEmailMeta),
      );
    }
    if (data.containsKey('last_message')) {
      context.handle(
        _lastMessageMeta,
        lastMessage.isAcceptableOrUnknown(
          data['last_message']!,
          _lastMessageMeta,
        ),
      );
    }
    if (data.containsKey('last_message_at')) {
      context.handle(
        _lastMessageAtMeta,
        lastMessageAt.isAcceptableOrUnknown(
          data['last_message_at']!,
          _lastMessageAtMeta,
        ),
      );
    }
    if (data.containsKey('unread_count')) {
      context.handle(
        _unreadCountMeta,
        unreadCount.isAcceptableOrUnknown(
          data['unread_count']!,
          _unreadCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalConversation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalConversation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      peerUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_user_id'],
      )!,
      peerDisplayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_display_name'],
      )!,
      peerEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_email'],
      )!,
      lastMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message'],
      ),
      lastMessageAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_message_at'],
      ),
      unreadCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unread_count'],
      )!,
    );
  }

  @override
  $LocalConversationsTable createAlias(String alias) {
    return $LocalConversationsTable(attachedDatabase, alias);
  }
}

class LocalConversation extends DataClass
    implements Insertable<LocalConversation> {
  final String id;
  final String peerUserId;
  final String peerDisplayName;
  final String peerEmail;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  const LocalConversation({
    required this.id,
    required this.peerUserId,
    required this.peerDisplayName,
    required this.peerEmail,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['peer_user_id'] = Variable<String>(peerUserId);
    map['peer_display_name'] = Variable<String>(peerDisplayName);
    map['peer_email'] = Variable<String>(peerEmail);
    if (!nullToAbsent || lastMessage != null) {
      map['last_message'] = Variable<String>(lastMessage);
    }
    if (!nullToAbsent || lastMessageAt != null) {
      map['last_message_at'] = Variable<DateTime>(lastMessageAt);
    }
    map['unread_count'] = Variable<int>(unreadCount);
    return map;
  }

  LocalConversationsCompanion toCompanion(bool nullToAbsent) {
    return LocalConversationsCompanion(
      id: Value(id),
      peerUserId: Value(peerUserId),
      peerDisplayName: Value(peerDisplayName),
      peerEmail: Value(peerEmail),
      lastMessage: lastMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessage),
      lastMessageAt: lastMessageAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageAt),
      unreadCount: Value(unreadCount),
    );
  }

  factory LocalConversation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalConversation(
      id: serializer.fromJson<String>(json['id']),
      peerUserId: serializer.fromJson<String>(json['peerUserId']),
      peerDisplayName: serializer.fromJson<String>(json['peerDisplayName']),
      peerEmail: serializer.fromJson<String>(json['peerEmail']),
      lastMessage: serializer.fromJson<String?>(json['lastMessage']),
      lastMessageAt: serializer.fromJson<DateTime?>(json['lastMessageAt']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'peerUserId': serializer.toJson<String>(peerUserId),
      'peerDisplayName': serializer.toJson<String>(peerDisplayName),
      'peerEmail': serializer.toJson<String>(peerEmail),
      'lastMessage': serializer.toJson<String?>(lastMessage),
      'lastMessageAt': serializer.toJson<DateTime?>(lastMessageAt),
      'unreadCount': serializer.toJson<int>(unreadCount),
    };
  }

  LocalConversation copyWith({
    String? id,
    String? peerUserId,
    String? peerDisplayName,
    String? peerEmail,
    Value<String?> lastMessage = const Value.absent(),
    Value<DateTime?> lastMessageAt = const Value.absent(),
    int? unreadCount,
  }) => LocalConversation(
    id: id ?? this.id,
    peerUserId: peerUserId ?? this.peerUserId,
    peerDisplayName: peerDisplayName ?? this.peerDisplayName,
    peerEmail: peerEmail ?? this.peerEmail,
    lastMessage: lastMessage.present ? lastMessage.value : this.lastMessage,
    lastMessageAt: lastMessageAt.present
        ? lastMessageAt.value
        : this.lastMessageAt,
    unreadCount: unreadCount ?? this.unreadCount,
  );
  LocalConversation copyWithCompanion(LocalConversationsCompanion data) {
    return LocalConversation(
      id: data.id.present ? data.id.value : this.id,
      peerUserId: data.peerUserId.present
          ? data.peerUserId.value
          : this.peerUserId,
      peerDisplayName: data.peerDisplayName.present
          ? data.peerDisplayName.value
          : this.peerDisplayName,
      peerEmail: data.peerEmail.present ? data.peerEmail.value : this.peerEmail,
      lastMessage: data.lastMessage.present
          ? data.lastMessage.value
          : this.lastMessage,
      lastMessageAt: data.lastMessageAt.present
          ? data.lastMessageAt.value
          : this.lastMessageAt,
      unreadCount: data.unreadCount.present
          ? data.unreadCount.value
          : this.unreadCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalConversation(')
          ..write('id: $id, ')
          ..write('peerUserId: $peerUserId, ')
          ..write('peerDisplayName: $peerDisplayName, ')
          ..write('peerEmail: $peerEmail, ')
          ..write('lastMessage: $lastMessage, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('unreadCount: $unreadCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    peerUserId,
    peerDisplayName,
    peerEmail,
    lastMessage,
    lastMessageAt,
    unreadCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalConversation &&
          other.id == this.id &&
          other.peerUserId == this.peerUserId &&
          other.peerDisplayName == this.peerDisplayName &&
          other.peerEmail == this.peerEmail &&
          other.lastMessage == this.lastMessage &&
          other.lastMessageAt == this.lastMessageAt &&
          other.unreadCount == this.unreadCount);
}

class LocalConversationsCompanion extends UpdateCompanion<LocalConversation> {
  final Value<String> id;
  final Value<String> peerUserId;
  final Value<String> peerDisplayName;
  final Value<String> peerEmail;
  final Value<String?> lastMessage;
  final Value<DateTime?> lastMessageAt;
  final Value<int> unreadCount;
  final Value<int> rowid;
  const LocalConversationsCompanion({
    this.id = const Value.absent(),
    this.peerUserId = const Value.absent(),
    this.peerDisplayName = const Value.absent(),
    this.peerEmail = const Value.absent(),
    this.lastMessage = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalConversationsCompanion.insert({
    required String id,
    required String peerUserId,
    required String peerDisplayName,
    this.peerEmail = const Value.absent(),
    this.lastMessage = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       peerUserId = Value(peerUserId),
       peerDisplayName = Value(peerDisplayName);
  static Insertable<LocalConversation> custom({
    Expression<String>? id,
    Expression<String>? peerUserId,
    Expression<String>? peerDisplayName,
    Expression<String>? peerEmail,
    Expression<String>? lastMessage,
    Expression<DateTime>? lastMessageAt,
    Expression<int>? unreadCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (peerUserId != null) 'peer_user_id': peerUserId,
      if (peerDisplayName != null) 'peer_display_name': peerDisplayName,
      if (peerEmail != null) 'peer_email': peerEmail,
      if (lastMessage != null) 'last_message': lastMessage,
      if (lastMessageAt != null) 'last_message_at': lastMessageAt,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalConversationsCompanion copyWith({
    Value<String>? id,
    Value<String>? peerUserId,
    Value<String>? peerDisplayName,
    Value<String>? peerEmail,
    Value<String?>? lastMessage,
    Value<DateTime?>? lastMessageAt,
    Value<int>? unreadCount,
    Value<int>? rowid,
  }) {
    return LocalConversationsCompanion(
      id: id ?? this.id,
      peerUserId: peerUserId ?? this.peerUserId,
      peerDisplayName: peerDisplayName ?? this.peerDisplayName,
      peerEmail: peerEmail ?? this.peerEmail,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (peerUserId.present) {
      map['peer_user_id'] = Variable<String>(peerUserId.value);
    }
    if (peerDisplayName.present) {
      map['peer_display_name'] = Variable<String>(peerDisplayName.value);
    }
    if (peerEmail.present) {
      map['peer_email'] = Variable<String>(peerEmail.value);
    }
    if (lastMessage.present) {
      map['last_message'] = Variable<String>(lastMessage.value);
    }
    if (lastMessageAt.present) {
      map['last_message_at'] = Variable<DateTime>(lastMessageAt.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalConversationsCompanion(')
          ..write('id: $id, ')
          ..write('peerUserId: $peerUserId, ')
          ..write('peerDisplayName: $peerDisplayName, ')
          ..write('peerEmail: $peerEmail, ')
          ..write('lastMessage: $lastMessage, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboundQueueTable extends OutboundQueue
    with TableInfo<$OutboundQueueTable, OutboundQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboundQueueTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _targetDeviceIdMeta = const VerificationMeta(
    'targetDeviceId',
  );
  @override
  late final GeneratedColumn<String> targetDeviceId = GeneratedColumn<String>(
    'target_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ciphertextMeta = const VerificationMeta(
    'ciphertext',
  );
  @override
  late final GeneratedColumn<String> ciphertext = GeneratedColumn<String>(
    'ciphertext',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _envelopeTypeMeta = const VerificationMeta(
    'envelopeType',
  );
  @override
  late final GeneratedColumn<String> envelopeType = GeneratedColumn<String>(
    'envelope_type',
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
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    messageId,
    targetDeviceId,
    ciphertext,
    envelopeType,
    conversationId,
    createdAt,
    attempts,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbound_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboundQueueData> instance, {
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
    if (data.containsKey('target_device_id')) {
      context.handle(
        _targetDeviceIdMeta,
        targetDeviceId.isAcceptableOrUnknown(
          data['target_device_id']!,
          _targetDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetDeviceIdMeta);
    }
    if (data.containsKey('ciphertext')) {
      context.handle(
        _ciphertextMeta,
        ciphertext.isAcceptableOrUnknown(data['ciphertext']!, _ciphertextMeta),
      );
    } else if (isInserting) {
      context.missing(_ciphertextMeta);
    }
    if (data.containsKey('envelope_type')) {
      context.handle(
        _envelopeTypeMeta,
        envelopeType.isAcceptableOrUnknown(
          data['envelope_type']!,
          _envelopeTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_envelopeTypeMeta);
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
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboundQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboundQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      targetDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_device_id'],
      )!,
      ciphertext: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ciphertext'],
      )!,
      envelopeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}envelope_type'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
    );
  }

  @override
  $OutboundQueueTable createAlias(String alias) {
    return $OutboundQueueTable(attachedDatabase, alias);
  }
}

class OutboundQueueData extends DataClass
    implements Insertable<OutboundQueueData> {
  final String id;
  final String messageId;
  final String targetDeviceId;
  final String ciphertext;
  final String envelopeType;
  final String conversationId;
  final DateTime createdAt;
  final int attempts;
  const OutboundQueueData({
    required this.id,
    required this.messageId,
    required this.targetDeviceId,
    required this.ciphertext,
    required this.envelopeType,
    required this.conversationId,
    required this.createdAt,
    required this.attempts,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['message_id'] = Variable<String>(messageId);
    map['target_device_id'] = Variable<String>(targetDeviceId);
    map['ciphertext'] = Variable<String>(ciphertext);
    map['envelope_type'] = Variable<String>(envelopeType);
    map['conversation_id'] = Variable<String>(conversationId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['attempts'] = Variable<int>(attempts);
    return map;
  }

  OutboundQueueCompanion toCompanion(bool nullToAbsent) {
    return OutboundQueueCompanion(
      id: Value(id),
      messageId: Value(messageId),
      targetDeviceId: Value(targetDeviceId),
      ciphertext: Value(ciphertext),
      envelopeType: Value(envelopeType),
      conversationId: Value(conversationId),
      createdAt: Value(createdAt),
      attempts: Value(attempts),
    );
  }

  factory OutboundQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboundQueueData(
      id: serializer.fromJson<String>(json['id']),
      messageId: serializer.fromJson<String>(json['messageId']),
      targetDeviceId: serializer.fromJson<String>(json['targetDeviceId']),
      ciphertext: serializer.fromJson<String>(json['ciphertext']),
      envelopeType: serializer.fromJson<String>(json['envelopeType']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'messageId': serializer.toJson<String>(messageId),
      'targetDeviceId': serializer.toJson<String>(targetDeviceId),
      'ciphertext': serializer.toJson<String>(ciphertext),
      'envelopeType': serializer.toJson<String>(envelopeType),
      'conversationId': serializer.toJson<String>(conversationId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attempts': serializer.toJson<int>(attempts),
    };
  }

  OutboundQueueData copyWith({
    String? id,
    String? messageId,
    String? targetDeviceId,
    String? ciphertext,
    String? envelopeType,
    String? conversationId,
    DateTime? createdAt,
    int? attempts,
  }) => OutboundQueueData(
    id: id ?? this.id,
    messageId: messageId ?? this.messageId,
    targetDeviceId: targetDeviceId ?? this.targetDeviceId,
    ciphertext: ciphertext ?? this.ciphertext,
    envelopeType: envelopeType ?? this.envelopeType,
    conversationId: conversationId ?? this.conversationId,
    createdAt: createdAt ?? this.createdAt,
    attempts: attempts ?? this.attempts,
  );
  OutboundQueueData copyWithCompanion(OutboundQueueCompanion data) {
    return OutboundQueueData(
      id: data.id.present ? data.id.value : this.id,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      targetDeviceId: data.targetDeviceId.present
          ? data.targetDeviceId.value
          : this.targetDeviceId,
      ciphertext: data.ciphertext.present
          ? data.ciphertext.value
          : this.ciphertext,
      envelopeType: data.envelopeType.present
          ? data.envelopeType.value
          : this.envelopeType,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboundQueueData(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('targetDeviceId: $targetDeviceId, ')
          ..write('ciphertext: $ciphertext, ')
          ..write('envelopeType: $envelopeType, ')
          ..write('conversationId: $conversationId, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    messageId,
    targetDeviceId,
    ciphertext,
    envelopeType,
    conversationId,
    createdAt,
    attempts,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboundQueueData &&
          other.id == this.id &&
          other.messageId == this.messageId &&
          other.targetDeviceId == this.targetDeviceId &&
          other.ciphertext == this.ciphertext &&
          other.envelopeType == this.envelopeType &&
          other.conversationId == this.conversationId &&
          other.createdAt == this.createdAt &&
          other.attempts == this.attempts);
}

class OutboundQueueCompanion extends UpdateCompanion<OutboundQueueData> {
  final Value<String> id;
  final Value<String> messageId;
  final Value<String> targetDeviceId;
  final Value<String> ciphertext;
  final Value<String> envelopeType;
  final Value<String> conversationId;
  final Value<DateTime> createdAt;
  final Value<int> attempts;
  final Value<int> rowid;
  const OutboundQueueCompanion({
    this.id = const Value.absent(),
    this.messageId = const Value.absent(),
    this.targetDeviceId = const Value.absent(),
    this.ciphertext = const Value.absent(),
    this.envelopeType = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboundQueueCompanion.insert({
    required String id,
    required String messageId,
    required String targetDeviceId,
    required String ciphertext,
    required String envelopeType,
    required String conversationId,
    required DateTime createdAt,
    this.attempts = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       messageId = Value(messageId),
       targetDeviceId = Value(targetDeviceId),
       ciphertext = Value(ciphertext),
       envelopeType = Value(envelopeType),
       conversationId = Value(conversationId),
       createdAt = Value(createdAt);
  static Insertable<OutboundQueueData> custom({
    Expression<String>? id,
    Expression<String>? messageId,
    Expression<String>? targetDeviceId,
    Expression<String>? ciphertext,
    Expression<String>? envelopeType,
    Expression<String>? conversationId,
    Expression<DateTime>? createdAt,
    Expression<int>? attempts,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (messageId != null) 'message_id': messageId,
      if (targetDeviceId != null) 'target_device_id': targetDeviceId,
      if (ciphertext != null) 'ciphertext': ciphertext,
      if (envelopeType != null) 'envelope_type': envelopeType,
      if (conversationId != null) 'conversation_id': conversationId,
      if (createdAt != null) 'created_at': createdAt,
      if (attempts != null) 'attempts': attempts,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboundQueueCompanion copyWith({
    Value<String>? id,
    Value<String>? messageId,
    Value<String>? targetDeviceId,
    Value<String>? ciphertext,
    Value<String>? envelopeType,
    Value<String>? conversationId,
    Value<DateTime>? createdAt,
    Value<int>? attempts,
    Value<int>? rowid,
  }) {
    return OutboundQueueCompanion(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      targetDeviceId: targetDeviceId ?? this.targetDeviceId,
      ciphertext: ciphertext ?? this.ciphertext,
      envelopeType: envelopeType ?? this.envelopeType,
      conversationId: conversationId ?? this.conversationId,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
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
    if (targetDeviceId.present) {
      map['target_device_id'] = Variable<String>(targetDeviceId.value);
    }
    if (ciphertext.present) {
      map['ciphertext'] = Variable<String>(ciphertext.value);
    }
    if (envelopeType.present) {
      map['envelope_type'] = Variable<String>(envelopeType.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboundQueueCompanion(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('targetDeviceId: $targetDeviceId, ')
          ..write('ciphertext: $ciphertext, ')
          ..write('envelopeType: $envelopeType, ')
          ..write('conversationId: $conversationId, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionKeysTable extends SessionKeys
    with TableInfo<$SessionKeysTable, SessionKey> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionKeysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peerDeviceIdMeta = const VerificationMeta(
    'peerDeviceId',
  );
  @override
  late final GeneratedColumn<String> peerDeviceId = GeneratedColumn<String>(
    'peer_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sharedSecretMeta = const VerificationMeta(
    'sharedSecret',
  );
  @override
  late final GeneratedColumn<String> sharedSecret = GeneratedColumn<String>(
    'shared_secret',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _establishedAtMeta = const VerificationMeta(
    'establishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> establishedAt =
      GeneratedColumn<DateTime>(
        'established_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _peerIdentityKeyMeta = const VerificationMeta(
    'peerIdentityKey',
  );
  @override
  late final GeneratedColumn<String> peerIdentityKey = GeneratedColumn<String>(
    'peer_identity_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    peerDeviceId,
    sharedSecret,
    establishedAt,
    peerIdentityKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_keys';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionKey> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('peer_device_id')) {
      context.handle(
        _peerDeviceIdMeta,
        peerDeviceId.isAcceptableOrUnknown(
          data['peer_device_id']!,
          _peerDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_peerDeviceIdMeta);
    }
    if (data.containsKey('shared_secret')) {
      context.handle(
        _sharedSecretMeta,
        sharedSecret.isAcceptableOrUnknown(
          data['shared_secret']!,
          _sharedSecretMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sharedSecretMeta);
    }
    if (data.containsKey('established_at')) {
      context.handle(
        _establishedAtMeta,
        establishedAt.isAcceptableOrUnknown(
          data['established_at']!,
          _establishedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_establishedAtMeta);
    }
    if (data.containsKey('peer_identity_key')) {
      context.handle(
        _peerIdentityKeyMeta,
        peerIdentityKey.isAcceptableOrUnknown(
          data['peer_identity_key']!,
          _peerIdentityKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_peerIdentityKeyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionKey map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionKey(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      peerDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_device_id'],
      )!,
      sharedSecret: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shared_secret'],
      )!,
      establishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}established_at'],
      )!,
      peerIdentityKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_identity_key'],
      )!,
    );
  }

  @override
  $SessionKeysTable createAlias(String alias) {
    return $SessionKeysTable(attachedDatabase, alias);
  }
}

class SessionKey extends DataClass implements Insertable<SessionKey> {
  final String id;
  final String peerDeviceId;
  final String sharedSecret;
  final DateTime establishedAt;
  final String peerIdentityKey;
  const SessionKey({
    required this.id,
    required this.peerDeviceId,
    required this.sharedSecret,
    required this.establishedAt,
    required this.peerIdentityKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['peer_device_id'] = Variable<String>(peerDeviceId);
    map['shared_secret'] = Variable<String>(sharedSecret);
    map['established_at'] = Variable<DateTime>(establishedAt);
    map['peer_identity_key'] = Variable<String>(peerIdentityKey);
    return map;
  }

  SessionKeysCompanion toCompanion(bool nullToAbsent) {
    return SessionKeysCompanion(
      id: Value(id),
      peerDeviceId: Value(peerDeviceId),
      sharedSecret: Value(sharedSecret),
      establishedAt: Value(establishedAt),
      peerIdentityKey: Value(peerIdentityKey),
    );
  }

  factory SessionKey.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionKey(
      id: serializer.fromJson<String>(json['id']),
      peerDeviceId: serializer.fromJson<String>(json['peerDeviceId']),
      sharedSecret: serializer.fromJson<String>(json['sharedSecret']),
      establishedAt: serializer.fromJson<DateTime>(json['establishedAt']),
      peerIdentityKey: serializer.fromJson<String>(json['peerIdentityKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'peerDeviceId': serializer.toJson<String>(peerDeviceId),
      'sharedSecret': serializer.toJson<String>(sharedSecret),
      'establishedAt': serializer.toJson<DateTime>(establishedAt),
      'peerIdentityKey': serializer.toJson<String>(peerIdentityKey),
    };
  }

  SessionKey copyWith({
    String? id,
    String? peerDeviceId,
    String? sharedSecret,
    DateTime? establishedAt,
    String? peerIdentityKey,
  }) => SessionKey(
    id: id ?? this.id,
    peerDeviceId: peerDeviceId ?? this.peerDeviceId,
    sharedSecret: sharedSecret ?? this.sharedSecret,
    establishedAt: establishedAt ?? this.establishedAt,
    peerIdentityKey: peerIdentityKey ?? this.peerIdentityKey,
  );
  SessionKey copyWithCompanion(SessionKeysCompanion data) {
    return SessionKey(
      id: data.id.present ? data.id.value : this.id,
      peerDeviceId: data.peerDeviceId.present
          ? data.peerDeviceId.value
          : this.peerDeviceId,
      sharedSecret: data.sharedSecret.present
          ? data.sharedSecret.value
          : this.sharedSecret,
      establishedAt: data.establishedAt.present
          ? data.establishedAt.value
          : this.establishedAt,
      peerIdentityKey: data.peerIdentityKey.present
          ? data.peerIdentityKey.value
          : this.peerIdentityKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionKey(')
          ..write('id: $id, ')
          ..write('peerDeviceId: $peerDeviceId, ')
          ..write('sharedSecret: $sharedSecret, ')
          ..write('establishedAt: $establishedAt, ')
          ..write('peerIdentityKey: $peerIdentityKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    peerDeviceId,
    sharedSecret,
    establishedAt,
    peerIdentityKey,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionKey &&
          other.id == this.id &&
          other.peerDeviceId == this.peerDeviceId &&
          other.sharedSecret == this.sharedSecret &&
          other.establishedAt == this.establishedAt &&
          other.peerIdentityKey == this.peerIdentityKey);
}

class SessionKeysCompanion extends UpdateCompanion<SessionKey> {
  final Value<String> id;
  final Value<String> peerDeviceId;
  final Value<String> sharedSecret;
  final Value<DateTime> establishedAt;
  final Value<String> peerIdentityKey;
  final Value<int> rowid;
  const SessionKeysCompanion({
    this.id = const Value.absent(),
    this.peerDeviceId = const Value.absent(),
    this.sharedSecret = const Value.absent(),
    this.establishedAt = const Value.absent(),
    this.peerIdentityKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionKeysCompanion.insert({
    required String id,
    required String peerDeviceId,
    required String sharedSecret,
    required DateTime establishedAt,
    required String peerIdentityKey,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       peerDeviceId = Value(peerDeviceId),
       sharedSecret = Value(sharedSecret),
       establishedAt = Value(establishedAt),
       peerIdentityKey = Value(peerIdentityKey);
  static Insertable<SessionKey> custom({
    Expression<String>? id,
    Expression<String>? peerDeviceId,
    Expression<String>? sharedSecret,
    Expression<DateTime>? establishedAt,
    Expression<String>? peerIdentityKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (peerDeviceId != null) 'peer_device_id': peerDeviceId,
      if (sharedSecret != null) 'shared_secret': sharedSecret,
      if (establishedAt != null) 'established_at': establishedAt,
      if (peerIdentityKey != null) 'peer_identity_key': peerIdentityKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionKeysCompanion copyWith({
    Value<String>? id,
    Value<String>? peerDeviceId,
    Value<String>? sharedSecret,
    Value<DateTime>? establishedAt,
    Value<String>? peerIdentityKey,
    Value<int>? rowid,
  }) {
    return SessionKeysCompanion(
      id: id ?? this.id,
      peerDeviceId: peerDeviceId ?? this.peerDeviceId,
      sharedSecret: sharedSecret ?? this.sharedSecret,
      establishedAt: establishedAt ?? this.establishedAt,
      peerIdentityKey: peerIdentityKey ?? this.peerIdentityKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (peerDeviceId.present) {
      map['peer_device_id'] = Variable<String>(peerDeviceId.value);
    }
    if (sharedSecret.present) {
      map['shared_secret'] = Variable<String>(sharedSecret.value);
    }
    if (establishedAt.present) {
      map['established_at'] = Variable<DateTime>(establishedAt.value);
    }
    if (peerIdentityKey.present) {
      map['peer_identity_key'] = Variable<String>(peerIdentityKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionKeysCompanion(')
          ..write('id: $id, ')
          ..write('peerDeviceId: $peerDeviceId, ')
          ..write('sharedSecret: $sharedSecret, ')
          ..write('establishedAt: $establishedAt, ')
          ..write('peerIdentityKey: $peerIdentityKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeviceKeyStoreTable extends DeviceKeyStore
    with TableInfo<$DeviceKeyStoreTable, DeviceKeyStoreData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeviceKeyStoreTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyNameMeta = const VerificationMeta(
    'keyName',
  );
  @override
  late final GeneratedColumn<String> keyName = GeneratedColumn<String>(
    'key_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyValueMeta = const VerificationMeta(
    'keyValue',
  );
  @override
  late final GeneratedColumn<String> keyValue = GeneratedColumn<String>(
    'key_value',
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
  List<GeneratedColumn> get $columns => [keyName, keyValue, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'device_key_store';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeviceKeyStoreData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key_name')) {
      context.handle(
        _keyNameMeta,
        keyName.isAcceptableOrUnknown(data['key_name']!, _keyNameMeta),
      );
    } else if (isInserting) {
      context.missing(_keyNameMeta);
    }
    if (data.containsKey('key_value')) {
      context.handle(
        _keyValueMeta,
        keyValue.isAcceptableOrUnknown(data['key_value']!, _keyValueMeta),
      );
    } else if (isInserting) {
      context.missing(_keyValueMeta);
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
  Set<GeneratedColumn> get $primaryKey => {keyName};
  @override
  DeviceKeyStoreData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceKeyStoreData(
      keyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_name'],
      )!,
      keyValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_value'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DeviceKeyStoreTable createAlias(String alias) {
    return $DeviceKeyStoreTable(attachedDatabase, alias);
  }
}

class DeviceKeyStoreData extends DataClass
    implements Insertable<DeviceKeyStoreData> {
  final String keyName;
  final String keyValue;
  final DateTime createdAt;
  const DeviceKeyStoreData({
    required this.keyName,
    required this.keyValue,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key_name'] = Variable<String>(keyName);
    map['key_value'] = Variable<String>(keyValue);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DeviceKeyStoreCompanion toCompanion(bool nullToAbsent) {
    return DeviceKeyStoreCompanion(
      keyName: Value(keyName),
      keyValue: Value(keyValue),
      createdAt: Value(createdAt),
    );
  }

  factory DeviceKeyStoreData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceKeyStoreData(
      keyName: serializer.fromJson<String>(json['keyName']),
      keyValue: serializer.fromJson<String>(json['keyValue']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'keyName': serializer.toJson<String>(keyName),
      'keyValue': serializer.toJson<String>(keyValue),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DeviceKeyStoreData copyWith({
    String? keyName,
    String? keyValue,
    DateTime? createdAt,
  }) => DeviceKeyStoreData(
    keyName: keyName ?? this.keyName,
    keyValue: keyValue ?? this.keyValue,
    createdAt: createdAt ?? this.createdAt,
  );
  DeviceKeyStoreData copyWithCompanion(DeviceKeyStoreCompanion data) {
    return DeviceKeyStoreData(
      keyName: data.keyName.present ? data.keyName.value : this.keyName,
      keyValue: data.keyValue.present ? data.keyValue.value : this.keyValue,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceKeyStoreData(')
          ..write('keyName: $keyName, ')
          ..write('keyValue: $keyValue, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(keyName, keyValue, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceKeyStoreData &&
          other.keyName == this.keyName &&
          other.keyValue == this.keyValue &&
          other.createdAt == this.createdAt);
}

class DeviceKeyStoreCompanion extends UpdateCompanion<DeviceKeyStoreData> {
  final Value<String> keyName;
  final Value<String> keyValue;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DeviceKeyStoreCompanion({
    this.keyName = const Value.absent(),
    this.keyValue = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeviceKeyStoreCompanion.insert({
    required String keyName,
    required String keyValue,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : keyName = Value(keyName),
       keyValue = Value(keyValue),
       createdAt = Value(createdAt);
  static Insertable<DeviceKeyStoreData> custom({
    Expression<String>? keyName,
    Expression<String>? keyValue,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (keyName != null) 'key_name': keyName,
      if (keyValue != null) 'key_value': keyValue,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeviceKeyStoreCompanion copyWith({
    Value<String>? keyName,
    Value<String>? keyValue,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return DeviceKeyStoreCompanion(
      keyName: keyName ?? this.keyName,
      keyValue: keyValue ?? this.keyValue,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (keyName.present) {
      map['key_name'] = Variable<String>(keyName.value);
    }
    if (keyValue.present) {
      map['key_value'] = Variable<String>(keyValue.value);
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
    return (StringBuffer('DeviceKeyStoreCompanion(')
          ..write('keyName: $keyName, ')
          ..write('keyValue: $keyValue, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalMessagesTable localMessages = $LocalMessagesTable(this);
  late final $LocalConversationsTable localConversations =
      $LocalConversationsTable(this);
  late final $OutboundQueueTable outboundQueue = $OutboundQueueTable(this);
  late final $SessionKeysTable sessionKeys = $SessionKeysTable(this);
  late final $DeviceKeyStoreTable deviceKeyStore = $DeviceKeyStoreTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localMessages,
    localConversations,
    outboundQueue,
    sessionKeys,
    deviceKeyStore,
  ];
}

typedef $$LocalMessagesTableCreateCompanionBuilder =
    LocalMessagesCompanion Function({
      required String id,
      required String conversationId,
      required String senderId,
      required String content,
      required DateTime sentAt,
      Value<String> status,
      Value<bool> isMine,
      Value<String?> envelopeId,
      Value<String?> parentMessageId,
      Value<String?> reaction,
      Value<int> rowid,
    });
typedef $$LocalMessagesTableUpdateCompanionBuilder =
    LocalMessagesCompanion Function({
      Value<String> id,
      Value<String> conversationId,
      Value<String> senderId,
      Value<String> content,
      Value<DateTime> sentAt,
      Value<String> status,
      Value<bool> isMine,
      Value<String?> envelopeId,
      Value<String?> parentMessageId,
      Value<String?> reaction,
      Value<int> rowid,
    });

class $$LocalMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMessagesTable> {
  $$LocalMessagesTableFilterComposer({
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

  ColumnFilters<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMine => $composableBuilder(
    column: $table.isMine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get envelopeId => $composableBuilder(
    column: $table.envelopeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentMessageId => $composableBuilder(
    column: $table.parentMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reaction => $composableBuilder(
    column: $table.reaction,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMessagesTable> {
  $$LocalMessagesTableOrderingComposer({
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

  ColumnOrderings<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMine => $composableBuilder(
    column: $table.isMine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get envelopeId => $composableBuilder(
    column: $table.envelopeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentMessageId => $composableBuilder(
    column: $table.parentMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reaction => $composableBuilder(
    column: $table.reaction,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMessagesTable> {
  $$LocalMessagesTableAnnotationComposer({
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

  GeneratedColumn<String> get senderId =>
      $composableBuilder(column: $table.senderId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isMine =>
      $composableBuilder(column: $table.isMine, builder: (column) => column);

  GeneratedColumn<String> get envelopeId => $composableBuilder(
    column: $table.envelopeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parentMessageId => $composableBuilder(
    column: $table.parentMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reaction =>
      $composableBuilder(column: $table.reaction, builder: (column) => column);
}

class $$LocalMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMessagesTable,
          LocalMessage,
          $$LocalMessagesTableFilterComposer,
          $$LocalMessagesTableOrderingComposer,
          $$LocalMessagesTableAnnotationComposer,
          $$LocalMessagesTableCreateCompanionBuilder,
          $$LocalMessagesTableUpdateCompanionBuilder,
          (
            LocalMessage,
            BaseReferences<_$AppDatabase, $LocalMessagesTable, LocalMessage>,
          ),
          LocalMessage,
          PrefetchHooks Function()
        > {
  $$LocalMessagesTableTableManager(_$AppDatabase db, $LocalMessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String> senderId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime> sentAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> isMine = const Value.absent(),
                Value<String?> envelopeId = const Value.absent(),
                Value<String?> parentMessageId = const Value.absent(),
                Value<String?> reaction = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMessagesCompanion(
                id: id,
                conversationId: conversationId,
                senderId: senderId,
                content: content,
                sentAt: sentAt,
                status: status,
                isMine: isMine,
                envelopeId: envelopeId,
                parentMessageId: parentMessageId,
                reaction: reaction,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String conversationId,
                required String senderId,
                required String content,
                required DateTime sentAt,
                Value<String> status = const Value.absent(),
                Value<bool> isMine = const Value.absent(),
                Value<String?> envelopeId = const Value.absent(),
                Value<String?> parentMessageId = const Value.absent(),
                Value<String?> reaction = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMessagesCompanion.insert(
                id: id,
                conversationId: conversationId,
                senderId: senderId,
                content: content,
                sentAt: sentAt,
                status: status,
                isMine: isMine,
                envelopeId: envelopeId,
                parentMessageId: parentMessageId,
                reaction: reaction,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMessagesTable,
      LocalMessage,
      $$LocalMessagesTableFilterComposer,
      $$LocalMessagesTableOrderingComposer,
      $$LocalMessagesTableAnnotationComposer,
      $$LocalMessagesTableCreateCompanionBuilder,
      $$LocalMessagesTableUpdateCompanionBuilder,
      (
        LocalMessage,
        BaseReferences<_$AppDatabase, $LocalMessagesTable, LocalMessage>,
      ),
      LocalMessage,
      PrefetchHooks Function()
    >;
typedef $$LocalConversationsTableCreateCompanionBuilder =
    LocalConversationsCompanion Function({
      required String id,
      required String peerUserId,
      required String peerDisplayName,
      Value<String> peerEmail,
      Value<String?> lastMessage,
      Value<DateTime?> lastMessageAt,
      Value<int> unreadCount,
      Value<int> rowid,
    });
typedef $$LocalConversationsTableUpdateCompanionBuilder =
    LocalConversationsCompanion Function({
      Value<String> id,
      Value<String> peerUserId,
      Value<String> peerDisplayName,
      Value<String> peerEmail,
      Value<String?> lastMessage,
      Value<DateTime?> lastMessageAt,
      Value<int> unreadCount,
      Value<int> rowid,
    });

class $$LocalConversationsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalConversationsTable> {
  $$LocalConversationsTableFilterComposer({
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

  ColumnFilters<String> get peerUserId => $composableBuilder(
    column: $table.peerUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerDisplayName => $composableBuilder(
    column: $table.peerDisplayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerEmail => $composableBuilder(
    column: $table.peerEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessage => $composableBuilder(
    column: $table.lastMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalConversationsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalConversationsTable> {
  $$LocalConversationsTableOrderingComposer({
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

  ColumnOrderings<String> get peerUserId => $composableBuilder(
    column: $table.peerUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerDisplayName => $composableBuilder(
    column: $table.peerDisplayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerEmail => $composableBuilder(
    column: $table.peerEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessage => $composableBuilder(
    column: $table.lastMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalConversationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalConversationsTable> {
  $$LocalConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get peerUserId => $composableBuilder(
    column: $table.peerUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get peerDisplayName => $composableBuilder(
    column: $table.peerDisplayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get peerEmail =>
      $composableBuilder(column: $table.peerEmail, builder: (column) => column);

  GeneratedColumn<String> get lastMessage => $composableBuilder(
    column: $table.lastMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => column,
  );
}

class $$LocalConversationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalConversationsTable,
          LocalConversation,
          $$LocalConversationsTableFilterComposer,
          $$LocalConversationsTableOrderingComposer,
          $$LocalConversationsTableAnnotationComposer,
          $$LocalConversationsTableCreateCompanionBuilder,
          $$LocalConversationsTableUpdateCompanionBuilder,
          (
            LocalConversation,
            BaseReferences<
              _$AppDatabase,
              $LocalConversationsTable,
              LocalConversation
            >,
          ),
          LocalConversation,
          PrefetchHooks Function()
        > {
  $$LocalConversationsTableTableManager(
    _$AppDatabase db,
    $LocalConversationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalConversationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> peerUserId = const Value.absent(),
                Value<String> peerDisplayName = const Value.absent(),
                Value<String> peerEmail = const Value.absent(),
                Value<String?> lastMessage = const Value.absent(),
                Value<DateTime?> lastMessageAt = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalConversationsCompanion(
                id: id,
                peerUserId: peerUserId,
                peerDisplayName: peerDisplayName,
                peerEmail: peerEmail,
                lastMessage: lastMessage,
                lastMessageAt: lastMessageAt,
                unreadCount: unreadCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String peerUserId,
                required String peerDisplayName,
                Value<String> peerEmail = const Value.absent(),
                Value<String?> lastMessage = const Value.absent(),
                Value<DateTime?> lastMessageAt = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalConversationsCompanion.insert(
                id: id,
                peerUserId: peerUserId,
                peerDisplayName: peerDisplayName,
                peerEmail: peerEmail,
                lastMessage: lastMessage,
                lastMessageAt: lastMessageAt,
                unreadCount: unreadCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalConversationsTable,
      LocalConversation,
      $$LocalConversationsTableFilterComposer,
      $$LocalConversationsTableOrderingComposer,
      $$LocalConversationsTableAnnotationComposer,
      $$LocalConversationsTableCreateCompanionBuilder,
      $$LocalConversationsTableUpdateCompanionBuilder,
      (
        LocalConversation,
        BaseReferences<
          _$AppDatabase,
          $LocalConversationsTable,
          LocalConversation
        >,
      ),
      LocalConversation,
      PrefetchHooks Function()
    >;
typedef $$OutboundQueueTableCreateCompanionBuilder =
    OutboundQueueCompanion Function({
      required String id,
      required String messageId,
      required String targetDeviceId,
      required String ciphertext,
      required String envelopeType,
      required String conversationId,
      required DateTime createdAt,
      Value<int> attempts,
      Value<int> rowid,
    });
typedef $$OutboundQueueTableUpdateCompanionBuilder =
    OutboundQueueCompanion Function({
      Value<String> id,
      Value<String> messageId,
      Value<String> targetDeviceId,
      Value<String> ciphertext,
      Value<String> envelopeType,
      Value<String> conversationId,
      Value<DateTime> createdAt,
      Value<int> attempts,
      Value<int> rowid,
    });

class $$OutboundQueueTableFilterComposer
    extends Composer<_$AppDatabase, $OutboundQueueTable> {
  $$OutboundQueueTableFilterComposer({
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

  ColumnFilters<String> get targetDeviceId => $composableBuilder(
    column: $table.targetDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ciphertext => $composableBuilder(
    column: $table.ciphertext,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get envelopeType => $composableBuilder(
    column: $table.envelopeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboundQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboundQueueTable> {
  $$OutboundQueueTableOrderingComposer({
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

  ColumnOrderings<String> get targetDeviceId => $composableBuilder(
    column: $table.targetDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ciphertext => $composableBuilder(
    column: $table.ciphertext,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get envelopeType => $composableBuilder(
    column: $table.envelopeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboundQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboundQueueTable> {
  $$OutboundQueueTableAnnotationComposer({
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

  GeneratedColumn<String> get targetDeviceId => $composableBuilder(
    column: $table.targetDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ciphertext => $composableBuilder(
    column: $table.ciphertext,
    builder: (column) => column,
  );

  GeneratedColumn<String> get envelopeType => $composableBuilder(
    column: $table.envelopeType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);
}

class $$OutboundQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboundQueueTable,
          OutboundQueueData,
          $$OutboundQueueTableFilterComposer,
          $$OutboundQueueTableOrderingComposer,
          $$OutboundQueueTableAnnotationComposer,
          $$OutboundQueueTableCreateCompanionBuilder,
          $$OutboundQueueTableUpdateCompanionBuilder,
          (
            OutboundQueueData,
            BaseReferences<
              _$AppDatabase,
              $OutboundQueueTable,
              OutboundQueueData
            >,
          ),
          OutboundQueueData,
          PrefetchHooks Function()
        > {
  $$OutboundQueueTableTableManager(_$AppDatabase db, $OutboundQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboundQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboundQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboundQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> messageId = const Value.absent(),
                Value<String> targetDeviceId = const Value.absent(),
                Value<String> ciphertext = const Value.absent(),
                Value<String> envelopeType = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboundQueueCompanion(
                id: id,
                messageId: messageId,
                targetDeviceId: targetDeviceId,
                ciphertext: ciphertext,
                envelopeType: envelopeType,
                conversationId: conversationId,
                createdAt: createdAt,
                attempts: attempts,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String messageId,
                required String targetDeviceId,
                required String ciphertext,
                required String envelopeType,
                required String conversationId,
                required DateTime createdAt,
                Value<int> attempts = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboundQueueCompanion.insert(
                id: id,
                messageId: messageId,
                targetDeviceId: targetDeviceId,
                ciphertext: ciphertext,
                envelopeType: envelopeType,
                conversationId: conversationId,
                createdAt: createdAt,
                attempts: attempts,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboundQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboundQueueTable,
      OutboundQueueData,
      $$OutboundQueueTableFilterComposer,
      $$OutboundQueueTableOrderingComposer,
      $$OutboundQueueTableAnnotationComposer,
      $$OutboundQueueTableCreateCompanionBuilder,
      $$OutboundQueueTableUpdateCompanionBuilder,
      (
        OutboundQueueData,
        BaseReferences<_$AppDatabase, $OutboundQueueTable, OutboundQueueData>,
      ),
      OutboundQueueData,
      PrefetchHooks Function()
    >;
typedef $$SessionKeysTableCreateCompanionBuilder =
    SessionKeysCompanion Function({
      required String id,
      required String peerDeviceId,
      required String sharedSecret,
      required DateTime establishedAt,
      required String peerIdentityKey,
      Value<int> rowid,
    });
typedef $$SessionKeysTableUpdateCompanionBuilder =
    SessionKeysCompanion Function({
      Value<String> id,
      Value<String> peerDeviceId,
      Value<String> sharedSecret,
      Value<DateTime> establishedAt,
      Value<String> peerIdentityKey,
      Value<int> rowid,
    });

class $$SessionKeysTableFilterComposer
    extends Composer<_$AppDatabase, $SessionKeysTable> {
  $$SessionKeysTableFilterComposer({
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

  ColumnFilters<String> get peerDeviceId => $composableBuilder(
    column: $table.peerDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sharedSecret => $composableBuilder(
    column: $table.sharedSecret,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get establishedAt => $composableBuilder(
    column: $table.establishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerIdentityKey => $composableBuilder(
    column: $table.peerIdentityKey,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionKeysTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionKeysTable> {
  $$SessionKeysTableOrderingComposer({
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

  ColumnOrderings<String> get peerDeviceId => $composableBuilder(
    column: $table.peerDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sharedSecret => $composableBuilder(
    column: $table.sharedSecret,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get establishedAt => $composableBuilder(
    column: $table.establishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerIdentityKey => $composableBuilder(
    column: $table.peerIdentityKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionKeysTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionKeysTable> {
  $$SessionKeysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get peerDeviceId => $composableBuilder(
    column: $table.peerDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sharedSecret => $composableBuilder(
    column: $table.sharedSecret,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get establishedAt => $composableBuilder(
    column: $table.establishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get peerIdentityKey => $composableBuilder(
    column: $table.peerIdentityKey,
    builder: (column) => column,
  );
}

class $$SessionKeysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionKeysTable,
          SessionKey,
          $$SessionKeysTableFilterComposer,
          $$SessionKeysTableOrderingComposer,
          $$SessionKeysTableAnnotationComposer,
          $$SessionKeysTableCreateCompanionBuilder,
          $$SessionKeysTableUpdateCompanionBuilder,
          (
            SessionKey,
            BaseReferences<_$AppDatabase, $SessionKeysTable, SessionKey>,
          ),
          SessionKey,
          PrefetchHooks Function()
        > {
  $$SessionKeysTableTableManager(_$AppDatabase db, $SessionKeysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionKeysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionKeysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionKeysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> peerDeviceId = const Value.absent(),
                Value<String> sharedSecret = const Value.absent(),
                Value<DateTime> establishedAt = const Value.absent(),
                Value<String> peerIdentityKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionKeysCompanion(
                id: id,
                peerDeviceId: peerDeviceId,
                sharedSecret: sharedSecret,
                establishedAt: establishedAt,
                peerIdentityKey: peerIdentityKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String peerDeviceId,
                required String sharedSecret,
                required DateTime establishedAt,
                required String peerIdentityKey,
                Value<int> rowid = const Value.absent(),
              }) => SessionKeysCompanion.insert(
                id: id,
                peerDeviceId: peerDeviceId,
                sharedSecret: sharedSecret,
                establishedAt: establishedAt,
                peerIdentityKey: peerIdentityKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionKeysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionKeysTable,
      SessionKey,
      $$SessionKeysTableFilterComposer,
      $$SessionKeysTableOrderingComposer,
      $$SessionKeysTableAnnotationComposer,
      $$SessionKeysTableCreateCompanionBuilder,
      $$SessionKeysTableUpdateCompanionBuilder,
      (
        SessionKey,
        BaseReferences<_$AppDatabase, $SessionKeysTable, SessionKey>,
      ),
      SessionKey,
      PrefetchHooks Function()
    >;
typedef $$DeviceKeyStoreTableCreateCompanionBuilder =
    DeviceKeyStoreCompanion Function({
      required String keyName,
      required String keyValue,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$DeviceKeyStoreTableUpdateCompanionBuilder =
    DeviceKeyStoreCompanion Function({
      Value<String> keyName,
      Value<String> keyValue,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$DeviceKeyStoreTableFilterComposer
    extends Composer<_$AppDatabase, $DeviceKeyStoreTable> {
  $$DeviceKeyStoreTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get keyName => $composableBuilder(
    column: $table.keyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keyValue => $composableBuilder(
    column: $table.keyValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeviceKeyStoreTableOrderingComposer
    extends Composer<_$AppDatabase, $DeviceKeyStoreTable> {
  $$DeviceKeyStoreTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get keyName => $composableBuilder(
    column: $table.keyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keyValue => $composableBuilder(
    column: $table.keyValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeviceKeyStoreTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeviceKeyStoreTable> {
  $$DeviceKeyStoreTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get keyName =>
      $composableBuilder(column: $table.keyName, builder: (column) => column);

  GeneratedColumn<String> get keyValue =>
      $composableBuilder(column: $table.keyValue, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DeviceKeyStoreTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeviceKeyStoreTable,
          DeviceKeyStoreData,
          $$DeviceKeyStoreTableFilterComposer,
          $$DeviceKeyStoreTableOrderingComposer,
          $$DeviceKeyStoreTableAnnotationComposer,
          $$DeviceKeyStoreTableCreateCompanionBuilder,
          $$DeviceKeyStoreTableUpdateCompanionBuilder,
          (
            DeviceKeyStoreData,
            BaseReferences<
              _$AppDatabase,
              $DeviceKeyStoreTable,
              DeviceKeyStoreData
            >,
          ),
          DeviceKeyStoreData,
          PrefetchHooks Function()
        > {
  $$DeviceKeyStoreTableTableManager(
    _$AppDatabase db,
    $DeviceKeyStoreTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeviceKeyStoreTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeviceKeyStoreTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeviceKeyStoreTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> keyName = const Value.absent(),
                Value<String> keyValue = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeviceKeyStoreCompanion(
                keyName: keyName,
                keyValue: keyValue,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String keyName,
                required String keyValue,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => DeviceKeyStoreCompanion.insert(
                keyName: keyName,
                keyValue: keyValue,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeviceKeyStoreTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeviceKeyStoreTable,
      DeviceKeyStoreData,
      $$DeviceKeyStoreTableFilterComposer,
      $$DeviceKeyStoreTableOrderingComposer,
      $$DeviceKeyStoreTableAnnotationComposer,
      $$DeviceKeyStoreTableCreateCompanionBuilder,
      $$DeviceKeyStoreTableUpdateCompanionBuilder,
      (
        DeviceKeyStoreData,
        BaseReferences<_$AppDatabase, $DeviceKeyStoreTable, DeviceKeyStoreData>,
      ),
      DeviceKeyStoreData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalMessagesTableTableManager get localMessages =>
      $$LocalMessagesTableTableManager(_db, _db.localMessages);
  $$LocalConversationsTableTableManager get localConversations =>
      $$LocalConversationsTableTableManager(_db, _db.localConversations);
  $$OutboundQueueTableTableManager get outboundQueue =>
      $$OutboundQueueTableTableManager(_db, _db.outboundQueue);
  $$SessionKeysTableTableManager get sessionKeys =>
      $$SessionKeysTableTableManager(_db, _db.sessionKeys);
  $$DeviceKeyStoreTableTableManager get deviceKeyStore =>
      $$DeviceKeyStoreTableTableManager(_db, _db.deviceKeyStore);
}
