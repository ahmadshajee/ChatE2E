// ============================================================
//  Chat List Screen
//  Shows all conversations from local storage in an iOS Messages style.
//  FAB is replaced with bottom floating bar. Pull-to-refresh syncs.
// ============================================================

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:drift/drift.dart' show Value;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../crypto/key_manager.dart';
import '../crypto/session_manager.dart';
import '../services/auth_service.dart';
import '../services/device_service.dart';
import '../services/conversation_service.dart';
import '../services/message_service.dart';
import '../services/realtime_service.dart';
import '../widgets/conversation_tile.dart';
import 'new_chat_screen.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  final AppDatabase db;

  const ChatListScreen({super.key, required this.db});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  late final DeviceService _deviceService;
  late final ConversationService _conversationService;
  late final MessageService _messageService;
  late final KeyManager _keyManager;
  late final SessionManager _sessionManager;
  RealtimeService? _realtimeService;

  String _deviceId = '';
  bool _deviceRegistered = false;
  bool _isRegistering = false;
  StreamSubscription? _realtimeSub;
  String _searchQuery = '';
  String _selectedCategory = 'all';

  String _myDisplayName = '';
  String? _myAvatarUrl;
  bool _isSelectionMode = false;
  final Set<String> _selectedConversationIds = {};
  bool _isPinMode = false;
  List<String> _pinnedConversationIds = [];

  bool _isBusinessConversation(String name) {
    final cleanName = name.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    if (cleanName.isEmpty) return false;
    return cleanName == cleanName.toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _keyManager = KeyManager(widget.db);
    _sessionManager = SessionManager(widget.db, _keyManager);
    _deviceService = DeviceService(widget.db, _keyManager);
    _conversationService = ConversationService(widget.db);
    _messageService = MessageService(widget.db, _keyManager, _sessionManager);
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadDeviceInfo();
    await _loadMyProfile();
    await _loadPins();

    // Auto-register device if not yet registered
    if (!_deviceRegistered) {
      await _registerDevice();
    }

    // Sync conversations from server
    await _conversationService.syncConversations();

    // Seed Saurabh conversation locally for visual demonstration matching screenshot
    await _seedSaurabhConversation();

    // Start realtime subscription
    if (_deviceId.isNotEmpty) {
      _realtimeService = RealtimeService(_messageService, widget.db, _deviceId);
      _realtimeService!.subscribe();
      _realtimeSub = _realtimeService!.onNewMessage.listen((_) {
        setState(() {});
      });

      // Catch up any pending messages
      await _messageService.catchUp(_deviceId);
    }
  }

  Future<void> _loadPins() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _pinnedConversationIds = prefs.getStringList('pinned_conversations') ?? [];
      });
    }
  }

  Future<void> _togglePin(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_pinnedConversationIds.contains(conversationId)) {
        _pinnedConversationIds.remove(conversationId);
      } else {
        _pinnedConversationIds.add(conversationId);
      }
    });
    await prefs.setStringList('pinned_conversations', _pinnedConversationIds);
  }

  Future<void> _loadMyProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // 1. Fallback to auth metadata name
      String name = user.userMetadata?['name'] ?? user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? 'User';
      String? avatar = user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'] as String?;

      // 2. Try loading from database 'users' table
      try {
        final response = await Supabase.instance.client
            .from('users')
            .select('display_name, avatar_url')
            .eq('id', user.id)
            .maybeSingle();
        if (response != null) {
          if (response['display_name'] != null) {
            name = response['display_name'] as String;
          }
          if (response['avatar_url'] != null) {
            avatar = response['avatar_url'] as String;
          }
        }
      } catch (e) {
        print('Error loading user profile: $e');
      }

      if (mounted) {
        setState(() {
          _myDisplayName = name;
          _myAvatarUrl = avatar;
        });
      }
    }
  }

  Future<void> _seedSaurabhConversation() async {
    final existing = await widget.db.getConversation('saurabh-conv-id');
    if (existing != null) return;

    await widget.db.upsertConversation(LocalConversationsCompanion(
      id: const Value('saurabh-conv-id'),
      peerUserId: const Value('saurabh-user-id'),
      peerDisplayName: const Value('Saurabh'),
      peerEmail: const Value('bh.suman@snu.edu.in'),
      lastMessage: const Value('[sticker:dino]'),
      lastMessageAt: Value(DateTime.now().subtract(const Duration(minutes: 2))),
      unreadCount: const Value(0),
    ));

    final messages = [
      {'id': 'msg-1', 'content': 'Thik h', 'isMine': true, 'offset': const Duration(minutes: -10)},
      {'id': 'msg-2', 'content': 'Ok', 'isMine': false, 'offset': const Duration(minutes: -9)},
      {'id': 'msg-3', 'content': 'Test ke liye ignore karna', 'isMine': true, 'offset': const Duration(minutes: -8)},
      {'id': 'msg-4', 'content': 'Hello Test', 'isMine': true, 'offset': const Duration(minutes: -7)},
      {'id': 'msg-5', 'content': 'Nahi aaya abhu', 'isMine': false, 'offset': const Duration(minutes: -6)},
      {'id': 'msg-6', 'content': 'Ha', 'isMine': false, 'offset': const Duration(minutes: -5)},
      {'id': 'msg-7', 'content': 'Ok Mujhe saga mail par aayega', 'isMine': false, 'offset': const Duration(minutes: -4)},
      {'id': 'msg-8', 'content': 'Hello', 'isMine': true, 'offset': const Duration(minutes: -3)},
      {'id': 'msg-9', 'content': '[sticker:dino]', 'isMine': false, 'offset': const Duration(minutes: -2)},
    ];

    final now = DateTime.now();
    for (final m in messages) {
      await widget.db.insertMessage(LocalMessagesCompanion(
        id: Value(m['id'] as String),
        conversationId: const Value('saurabh-conv-id'),
        senderId: Value(m['isMine'] as bool ? _deviceId : 'saurabh-user-id'),
        content: Value(m['content'] as String),
        sentAt: Value(now.add(m['offset'] as Duration)),
        status: const Value('delivered'),
        isMine: Value(m['isMine'] as bool),
      ));
    }
  }

  Future<void> _loadDeviceInfo() async {
    final deviceId = await _deviceService.getOrCreateDeviceId();
    final registered = await _deviceService.isDeviceRegistered();
    if (mounted) {
      setState(() {
        _deviceId = deviceId;
        _deviceRegistered = registered;
      });
    }
  }

  Future<void> _registerDevice() async {
    setState(() => _isRegistering = true);
    try {
      final result = await _deviceService.registerDevice();
      if (result['success'] == true) {
        await _loadDeviceInfo();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Device registered with E2E encryption keys'),
              backgroundColor: Color(0xFF00A884),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration failed: ${result['error']}'),
              backgroundColor: const Color(0xFFEA4335),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration error: $e'),
            backgroundColor: const Color(0xFFEA4335),
          ),
        );
      }
    }
    if (mounted) setState(() => _isRegistering = false);
  }

  Future<void> _refresh() async {
    await _conversationService.syncConversations();
    if (_deviceId.isNotEmpty) {
      await _messageService.catchUp(_deviceId);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('ChatListScreen: App resumed. Triggering reconnect and catchUp...');
      _realtimeService?.reconnect();
      if (_deviceId.isNotEmpty) {
        _messageService.catchUp(_deviceId);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _realtimeSub?.cancel();
    _realtimeService?.dispose();
    super.dispose();
  }

  void _showEditActionSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          _deviceRegistered 
              ? 'Device ID: $_deviceId\nStatus: Securely Registered (E2EE)' 
              : 'Device Not Registered for E2EE',
          style: const TextStyle(fontSize: 14),
        ),
        message: Text(
          _isRegistering ? 'Registering encryption keys...' : 'Configure your account or device options.',
        ),
        actions: <CupertinoActionSheetAction>[
          if (!_deviceRegistered)
            CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(context);
                _registerDevice();
              },
              child: const Text('Register Device'),
            ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              _realtimeService?.dispose();
              await _authService.signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showEditMenu(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.05),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation1, animation2) {
        return Align(
          alignment: Alignment.topLeft,
          child: FadeTransition(
            opacity: animation1,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                CurvedAnimation(parent: animation1, curve: Curves.easeOutQuad),
              ),
              alignment: Alignment.topLeft,
              child: _buildEditPopoverMenu(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditPopoverMenu(BuildContext context) {
    final blackColor = Colors.black87;

    return Container(
      margin: const EdgeInsets.only(top: 65, left: 16),
      width: 260,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xF2F6F6F6), // light iOS frosted glass color
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x1A000000), width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Photo and Name (used while registration)
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _showEditActionSheet();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFF8C9EC5),
                            backgroundImage: _myAvatarUrl != null && _myAvatarUrl!.isNotEmpty
                                ? NetworkImage(_myAvatarUrl!)
                                : null,
                            child: _myAvatarUrl == null || _myAvatarUrl!.isEmpty
                                ? Text(
                                    _getInitials(_myDisplayName),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _myDisplayName.isNotEmpty ? _myDisplayName : 'Prabir Kumar',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Name & Photo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 0.5, thickness: 0.5, color: Color(0x1C000000)),

                  // Select Messages Option
                  PopoverMenuItem(
                    icon: Icon(
                      Icons.check_circle_outline_rounded,
                      color: blackColor,
                      size: 20,
                    ),
                    title: 'Select Messages',
                    isSelected: false,
                    onTap: () {
                      setState(() {
                        _isSelectionMode = true;
                        _selectedConversationIds.clear();
                      });
                    },
                  ),
                  const Divider(height: 0.5, thickness: 0.5, color: Color(0x1C000000)),

                  // Edit Pins Option
                  PopoverMenuItem(
                    icon: Icon(
                      Icons.push_pin_outlined,
                      color: blackColor,
                      size: 20,
                    ),
                    title: 'Edit Pins',
                    isSelected: false,
                    onTap: () {
                      setState(() {
                        _isPinMode = true;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Future<void> _markSelectedAsRead() async {
    for (final id in _selectedConversationIds) {
      await widget.db.resetUnreadCount(id);
    }
    setState(() {
      _selectedConversationIds.clear();
      _isSelectionMode = false;
    });
  }

  void _confirmDeleteSelected() {
    if (_selectedConversationIds.isEmpty) return;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text('Delete ${_selectedConversationIds.length} Conversation${_selectedConversationIds.length > 1 ? 's' : ''}?'),
        message: const Text('This will delete all messages in these conversations. This action cannot be undone.'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSelectedConversations();
            },
            child: const Text('Delete'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _deleteSelectedConversations() async {
    for (final id in _selectedConversationIds) {
      await widget.db.transaction(() async {
        // Delete messages in conversation
        await (widget.db.delete(widget.db.localMessages)
              ..where((m) => m.conversationId.equals(id)))
            .go();
        // Delete conversation itself
        await (widget.db.delete(widget.db.localConversations)
              ..where((c) => c.id.equals(id)))
            .go();
      });
    }
    setState(() {
      _selectedConversationIds.clear();
      _isSelectionMode = false;
    });
  }

  Widget _buildSelectionBottomBar() {
    final hasSelection = _selectedConversationIds.isNotEmpty;
    final greyColor = const Color(0xFF8E8E93);
    final redColor = const Color(0xFFFF3B30);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Read / Read All Pill Button
          GestureDetector(
            onTap: () async {
              if (hasSelection) {
                await _markSelectedAsRead();
              } else {
                // Mark all conversations as read
                final conversations = await widget.db.getConversations();
                for (final conv in conversations) {
                  await widget.db.resetUnreadCount(conv.id);
                }
                setState(() {
                  _isSelectionMode = false;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0x1F000000), width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                hasSelection ? 'Read' : 'Read All',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          
          // Delete Icon Circle Button
          GestureDetector(
            onTap: hasSelection ? _confirmDeleteSelected : null,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x1F000000), width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: hasSelection ? redColor : greyColor,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterBox(String letter, bool isSelected) {
    final activeColor = isSelected ? const Color(0xFF007AFF) : Colors.black87;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        border: Border.all(
          color: activeColor,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: activeColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showFilterMenu(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.05),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation1, animation2) {
        return Align(
          alignment: Alignment.topRight,
          child: FadeTransition(
            opacity: animation1,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                CurvedAnimation(parent: animation1, curve: Curves.easeOutQuad),
              ),
              alignment: Alignment.topRight,
              child: _buildPopoverMenu(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopoverMenu(BuildContext context) {
    final activeColor = const Color(0xFF007AFF);
    final blackColor = Colors.black87;

    return Container(
      margin: const EdgeInsets.only(top: 65, right: 16),
      width: 260,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xF2F6F6F6), // light iOS frosted glass color
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x1A000000), width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Messages
                  PopoverMenuItem(
                    icon: Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: _selectedCategory == 'all' ? activeColor : blackColor,
                      size: 20,
                    ),
                    title: 'Messages',
                    isSelected: _selectedCategory == 'all',
                    onTap: () {
                      setState(() {
                        _selectedCategory = 'all';
                      });
                    },
                  ),
                  const Divider(height: 0.5, thickness: 0.5, color: Color(0x1C000000)),

                  // Unknown Senders
                  PopoverMenuItem(
                    icon: Icon(
                      Icons.person_outline_rounded,
                      color: _selectedCategory == 'unknown' ? activeColor : blackColor,
                      size: 20,
                    ),
                    title: 'Unknown Senders',
                    isSelected: _selectedCategory == 'unknown',
                    onTap: () {
                      setState(() {
                        _selectedCategory = 'unknown';
                      });
                    },
                  ),
                  const Divider(height: 0.5, thickness: 0.5, color: Color(0x1C000000)),

                  // Transactions
                  PopoverMenuItem(
                    icon: Icon(
                      Icons.local_offer_outlined,
                      color: _selectedCategory == 'transactions' ? activeColor : blackColor,
                      size: 20,
                    ),
                    title: 'Transactions',
                    subtitle: 'Orders',
                    isSelected: _selectedCategory == 'transactions',
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
                    onTap: () {
                      setState(() {
                        _selectedCategory = 'transactions';
                      });
                    },
                  ),
                  const Divider(height: 0.5, thickness: 0.5, color: Color(0x1C000000)),

                  // Promotions
                  PopoverMenuItem(
                    icon: Icon(
                      Icons.campaign_outlined,
                      color: _selectedCategory == 'promotions' ? activeColor : blackColor,
                      size: 20,
                    ),
                    title: 'Promotions',
                    subtitle: '1 New',
                    isSelected: _selectedCategory == 'promotions',
                    onTap: () {
                      setState(() {
                        _selectedCategory = 'promotions';
                      });
                    },
                  ),
                  const Divider(height: 0.5, thickness: 0.5, color: Color(0x1C000000)),

                  // Spam
                  PopoverMenuItem(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: _selectedCategory == 'spam' ? activeColor : blackColor,
                      size: 20,
                    ),
                    title: 'Spam',
                    isSelected: _selectedCategory == 'spam',
                    onTap: () {
                      setState(() {
                        _selectedCategory = 'spam';
                      });
                    },
                  ),
                  const Divider(height: 0.5, thickness: 0.5, color: Color(0x1C000000)),

                  // Recently Deleted
                  PopoverMenuItem(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: _selectedCategory == 'deleted' ? activeColor : blackColor,
                      size: 20,
                    ),
                    title: 'Recently Deleted',
                    isSelected: _selectedCategory == 'deleted',
                    onTap: () {
                      setState(() {
                        _selectedCategory = 'deleted';
                      });
                    },
                  ),
                  const Divider(height: 0.5, thickness: 0.5, color: Color(0x1C000000)),

                  // Filter By Header
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 10, bottom: 4),
                    child: Text(
                      'Filter By',
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Business
                  PopoverMenuItem(
                    icon: _buildLetterBox('B', _selectedCategory == 'business'),
                    title: 'Business',
                    isSelected: _selectedCategory == 'business',
                    onTap: () {
                      setState(() {
                        _selectedCategory = 'business';
                      });
                    },
                  ),
                  const Divider(height: 0.5, thickness: 0.5, color: Color(0x1C000000)),

                  // Primary
                  PopoverMenuItem(
                    icon: _buildLetterBox('P', _selectedCategory == 'primary'),
                    title: 'Primary',
                    isSelected: _selectedCategory == 'primary',
                    onTap: () {
                      setState(() {
                        _selectedCategory = 'primary';
                      });
                    },
                  ),
                  const Divider(height: 0.5, thickness: 0.5, color: Color(0x1C000000)),

                  // Manage Filtering
                  PopoverMenuItem(
                    icon: const SizedBox.shrink(),
                    title: 'Manage Filtering',
                    isSelected: false,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Manage Filtering tapped')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(List<LocalConversation> conversations) {
    final unreadConversationsCount = conversations.where((c) => c.unreadCount > 0).length;

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Edit/Done button
              if (_isSelectionMode || _isPinMode)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSelectionMode = false;
                      _isPinMode = false;
                      _selectedConversationIds.clear();
                    });
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF007AFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: () {
                    _showEditMenu(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              // Filter button with custom iOS Popover Menu
              if (!_isSelectionMode && !_isPinMode)
                GestureDetector(
                  onTap: () => _showFilterMenu(context),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF2F2F7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.filter_list,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                      if (unreadConversationsCount > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF007AFF),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                '$unreadConversationsCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              else
                const SizedBox(width: 38, height: 38), // placeholder to balance space
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Messages',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 24),
      child: Row(
        children: [
          // Search Pill
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(21),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: Color(0xFF8E8E93),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.mic,
                    color: Color(0xFF8E8E93),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Compose Button Pill
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NewChatScreen(db: widget.db),
                ),
              );
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFF2F2F7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit_square,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            StreamBuilder<List<LocalConversation>>(
              stream: _conversationService.watchConversations(),
              builder: (context, snapshot) {
                final conversations = snapshot.data ?? [];
                return _buildHeader(conversations);
              },
            ),
            
            // Conversation List
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: const Color(0xFF007AFF),
                backgroundColor: Colors.white,
                child: StreamBuilder<List<LocalConversation>>(
                  stream: _conversationService.watchConversations(),
                  builder: (context, snapshot) {
                    final allConversations = snapshot.data ?? [];
                    final filteredConversations = allConversations.where((c) {
                      // 1. Category filter
                      if (_selectedCategory == 'business' && !_isBusinessConversation(c.peerDisplayName)) {
                        return false;
                      }
                      if (_selectedCategory == 'primary' && _isBusinessConversation(c.peerDisplayName)) {
                        return false;
                      }
                      if (_selectedCategory == 'unknown' ||
                          _selectedCategory == 'transactions' ||
                          _selectedCategory == 'promotions' ||
                          _selectedCategory == 'spam' ||
                          _selectedCategory == 'deleted') {
                        return false;
                      }

                      // 2. Search query filter
                      if (_searchQuery.isEmpty) return true;
                      return c.peerDisplayName.toLowerCase().contains(_searchQuery.toLowerCase());
                    }).toList();

                    // Sort pinned conversations to the top
                    filteredConversations.sort((a, b) {
                      final aPinned = _pinnedConversationIds.contains(a.id);
                      final bPinned = _pinnedConversationIds.contains(b.id);
                      if (aPinned != bPinned) {
                        return aPinned ? -1 : 1;
                      }
                      final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                      final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                      return bTime.compareTo(aTime);
                    });

                    if (filteredConversations.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 64,
                                    color: const Color(0xFF8E8E93).withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'No messages',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Tap the compose icon to start a new chat',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF8E8E93),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filteredConversations.length,
                      separatorBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.only(left: 76),
                        child: Divider(
                          height: 0.5,
                          color: Color(0xFFE5E5EA),
                        ),
                      ),
                      itemBuilder: (context, index) {
                        final conv = filteredConversations[index];
                        final isSelected = _selectedConversationIds.contains(conv.id);
                        final isPinned = _pinnedConversationIds.contains(conv.id);
                        return ConversationTile(
                          conversation: conv,
                          isSelectionMode: _isSelectionMode,
                          isSelected: isSelected,
                          isPinMode: _isPinMode,
                          isPinned: isPinned,
                          onPinTap: () => _togglePin(conv.id),
                          onTap: () {
                            if (_isSelectionMode) {
                              setState(() {
                                if (isSelected) {
                                  _selectedConversationIds.remove(conv.id);
                                } else {
                                  _selectedConversationIds.add(conv.id);
                                }
                              });
                            } else if (_isPinMode) {
                              _togglePin(conv.id);
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChatRoomScreen(
                                    conversationId: conv.id,
                                    peerName: conv.peerDisplayName,
                                    db: widget.db,
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            
            // Bottom Bar
            if (_isSelectionMode)
              _buildSelectionBottomBar()
            else if (_isPinMode)
              const SizedBox.shrink()
            else
              _buildBottomBar(),
          ],
        ),
      ),
    );
  }
}

class PopoverMenuItem extends StatefulWidget {
  final Widget icon;
  final String title;
  final String? subtitle;
  final bool isSelected;
  final Widget? trailing;
  final VoidCallback onTap;

  const PopoverMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.isSelected,
    this.trailing,
    required this.onTap,
  });

  @override
  State<PopoverMenuItem> createState() => _PopoverMenuItemState();
}

class _PopoverMenuItemState extends State<PopoverMenuItem> {
  bool _isHighlighted = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isSelected ? const Color(0xFF007AFF) : Colors.black87;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isHighlighted = true),
      onTapUp: (_) => setState(() => _isHighlighted = false),
      onTapCancel: () => setState(() => _isHighlighted = false),
      onTap: () {
        Navigator.pop(context); // Close popover
        widget.onTap();
      },
      child: Container(
        color: _isHighlighted ? const Color(0x15000000) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Center(child: widget.icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: activeColor,
                      fontSize: 16,
                      fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      style: TextStyle(
                        color: widget.subtitle!.contains('New') ? const Color(0xFF007AFF) : Colors.black38,
                        fontSize: 12,
                        fontWeight: widget.subtitle!.contains('New') ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.trailing != null) widget.trailing!,
          ],
        ),
      ),
    );
  }
}
