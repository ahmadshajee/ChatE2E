// ============================================================
//  Drift Local Database
//  Plaintext messages live ONLY here — never on the server.
//  Server stores ciphertext envelopes only.
// ============================================================

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// ── Tables ────────────────────────────────────────────────────

/// Local plaintext messages — the only place readable content exists.
class LocalMessages extends Table {
  TextColumn get id => text()();              // client_message_id (UUID)
  TextColumn get conversationId => text()();  // server conversation UUID
  TextColumn get senderId => text()();        // sender user UUID
  TextColumn get content => text()();         // PLAINTEXT message body
  DateTimeColumn get sentAt => dateTime()();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, sent, delivered, read, failed
  BoolColumn get isMine => boolean().withDefault(const Constant(true))();
  TextColumn get envelopeId => text().nullable()(); // server envelope UUID after send

  @override
  Set<Column> get primaryKey => {id};
}

/// Local conversation metadata — cached from server + local state.
class LocalConversations extends Table {
  TextColumn get id => text()();              // server conversation UUID
  TextColumn get peerUserId => text()();      // the other user
  TextColumn get peerDisplayName => text()();
  TextColumn get peerEmail => text().withDefault(const Constant(''))();
  TextColumn get lastMessage => text().nullable()();
  DateTimeColumn get lastMessageAt => dateTime().nullable()();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Outbound message queue — encrypted envelopes waiting to be sent.
class OutboundQueue extends Table {
  TextColumn get id => text()();              // UUID
  TextColumn get messageId => text()();       // FK to local_messages.id
  TextColumn get targetDeviceId => text()();  // recipient device UUID
  TextColumn get ciphertext => text()();      // Base64 encrypted payload
  TextColumn get envelopeType => text()();    // message, prekey_message, key_exchange
  TextColumn get conversationId => text()();  // server conversation UUID
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Per-device-pair session keys — derived from X3DH.
class SessionKeys extends Table {
  TextColumn get id => text()();              // {myDeviceId}:{peerDeviceId}
  TextColumn get peerDeviceId => text()();
  TextColumn get sharedSecret => text()();    // Base64 AES-256 key
  DateTimeColumn get establishedAt => dateTime()();
  TextColumn get peerIdentityKey => text()(); // Base64 peer identity public key

  @override
  Set<Column> get primaryKey => {id};
}

/// Device key store — private keys for this device.
class DeviceKeyStore extends Table {
  TextColumn get keyName => text()();         // e.g. 'identity_private', 'signed_prekey_private'
  TextColumn get keyValue => text()();        // Base64 encoded key material
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {keyName};
}

// ── Database ──────────────────────────────────────────────────

@DriftDatabase(tables: [
  LocalMessages,
  LocalConversations,
  OutboundQueue,
  SessionKeys,
  DeviceKeyStore,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'chatizy_local');
  }

  // ── Message DAOs ──────────────────────────────────────────

  /// Insert a new local message.
  Future<void> insertMessage(LocalMessagesCompanion message) {
    return into(localMessages).insertOnConflictUpdate(message);
  }

  /// Watch all messages for a conversation, ordered by time.
  Stream<List<LocalMessage>> watchMessages(String conversationId) {
    return (select(localMessages)
          ..where((m) => m.conversationId.equals(conversationId))
          ..orderBy([(m) => OrderingTerm.asc(m.sentAt)]))
        .watch();
  }

  /// Get all messages for a conversation.
  Future<List<LocalMessage>> getMessages(String conversationId) {
    return (select(localMessages)
          ..where((m) => m.conversationId.equals(conversationId))
          ..orderBy([(m) => OrderingTerm.asc(m.sentAt)]))
        .get();
  }

  /// Update message status.
  Future<void> updateMessageStatus(String messageId, String status) {
    return (update(localMessages)..where((m) => m.id.equals(messageId)))
        .write(LocalMessagesCompanion(status: Value(status)));
  }

  /// Update message envelope ID (after server confirms).
  Future<void> updateMessageEnvelopeId(String messageId, String envelopeId) {
    return (update(localMessages)..where((m) => m.id.equals(messageId)))
        .write(LocalMessagesCompanion(envelopeId: Value(envelopeId)));
  }

  // ── Conversation DAOs ─────────────────────────────────────

  /// Upsert a conversation.
  Future<void> upsertConversation(LocalConversationsCompanion conv) {
    return into(localConversations).insertOnConflictUpdate(conv);
  }

  /// Watch all conversations, sorted by last message time.
  Stream<List<LocalConversation>> watchConversations() {
    return (select(localConversations)
          ..orderBy([(c) => OrderingTerm.desc(c.lastMessageAt)]))
        .watch();
  }

  /// Get all conversations.
  Future<List<LocalConversation>> getConversations() {
    return (select(localConversations)
          ..orderBy([(c) => OrderingTerm.desc(c.lastMessageAt)]))
        .get();
  }

  /// Get a single conversation by ID.
  Future<LocalConversation?> getConversation(String id) {
    return (select(localConversations)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// Find conversation by peer user ID.
  Future<LocalConversation?> findConversationByPeer(String peerUserId) {
    return (select(localConversations)
          ..where((c) => c.peerUserId.equals(peerUserId)))
        .getSingleOrNull();
  }

  /// Update last message and unread count.
  Future<void> updateConversationLastMessage(
    String conversationId,
    String lastMessage,
    DateTime lastMessageAt, {
    bool incrementUnread = false,
  }) async {
    final existing = await getConversation(conversationId);
    if (existing != null) {
      await (update(localConversations)
            ..where((c) => c.id.equals(conversationId)))
          .write(LocalConversationsCompanion(
        lastMessage: Value(lastMessage),
        lastMessageAt: Value(lastMessageAt),
        unreadCount: Value(
            incrementUnread ? existing.unreadCount + 1 : existing.unreadCount),
      ));
    }
  }

  /// Reset unread count for a conversation.
  Future<void> resetUnreadCount(String conversationId) {
    return (update(localConversations)
          ..where((c) => c.id.equals(conversationId)))
        .write(const LocalConversationsCompanion(unreadCount: Value(0)));
  }

  // ── Outbound Queue DAOs ───────────────────────────────────

  /// Enqueue an outbound envelope.
  Future<void> enqueueOutbound(OutboundQueueCompanion item) {
    return into(outboundQueue).insert(item);
  }

  /// Get all pending outbound items.
  Future<List<OutboundQueueData>> getPendingOutbound() {
    return (select(outboundQueue)
          ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
        .get();
  }

  /// Delete an outbound item (after successful send).
  Future<void> deleteOutbound(String id) {
    return (delete(outboundQueue)..where((q) => q.id.equals(id))).go();
  }

  /// Increment attempt count.
  Future<void> incrementOutboundAttempt(String id) async {
    final item = await (select(outboundQueue)..where((q) => q.id.equals(id)))
        .getSingleOrNull();
    if (item != null) {
      await (update(outboundQueue)..where((q) => q.id.equals(id)))
          .write(OutboundQueueCompanion(attempts: Value(item.attempts + 1)));
    }
  }

  // ── Session Key DAOs ──────────────────────────────────────

  /// Store a session key.
  Future<void> storeSessionKey(SessionKeysCompanion key) {
    return into(sessionKeys).insertOnConflictUpdate(key);
  }

  /// Get session key for a peer device.
  Future<SessionKey?> getSessionKey(String myDeviceId, String peerDeviceId) {
    final id = '$myDeviceId:$peerDeviceId';
    return (select(sessionKeys)..where((s) => s.id.equals(id)))
        .getSingleOrNull();
  }

  // ── Device Key Store DAOs ─────────────────────────────────

  /// Store a device key.
  Future<void> storeDeviceKey(String name, String value) {
    return into(deviceKeyStore).insertOnConflictUpdate(DeviceKeyStoreCompanion(
      keyName: Value(name),
      keyValue: Value(value),
      createdAt: Value(DateTime.now()),
    ));
  }

  /// Get a device key by name.
  Future<String?> getDeviceKey(String name) async {
    final row = await (select(deviceKeyStore)
          ..where((k) => k.keyName.equals(name)))
        .getSingleOrNull();
    return row?.keyValue;
  }

  /// Check if a key exists.
  Future<bool> hasDeviceKey(String name) async {
    final key = await getDeviceKey(name);
    return key != null;
  }
}
