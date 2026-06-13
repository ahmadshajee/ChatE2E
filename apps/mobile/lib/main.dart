// ============================================================
//  Main Entry Point
//  Initializes Supabase, local database, and crypto services.
// ============================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:background_fetch/background_fetch.dart';

import 'config/supabase_config.dart';
import 'database/app_database.dart';
import 'app.dart';
import 'services/notification_service.dart';
import 'services/sound_service.dart';
import 'services/device_service.dart';
import 'services/message_service.dart';
import 'crypto/key_manager.dart';
import 'crypto/session_manager.dart';

/// Global database instance
late final AppDatabase appDatabase;

@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessEvent task) async {
  final taskId = task.taskId;
  final isTimeout = task.timeout;
  if (isTimeout) {
    print('[BackgroundFetch] Headless task timed out: $taskId');
    BackgroundFetch.finish(taskId);
    return;
  }
  print('[BackgroundFetch] Headless task run: $taskId');

  try {
    WidgetsFlutterBinding.ensureInitialized();

    final db = AppDatabase();
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );

    await NotificationService().init();

    final keyManager = KeyManager(db);
    final deviceService = DeviceService(db, keyManager);
    final isRegistered = await deviceService.isDeviceRegistered();
    final deviceId = await deviceService.getOrCreateDeviceId();

    if (isRegistered && deviceId.isNotEmpty) {
      final sessionManager = SessionManager(db, keyManager);
      final messageService = MessageService(db, keyManager, sessionManager);
      await messageService.catchUp(deviceId);
      print('[BackgroundFetch] Headless message catchup completed successfully.');
    }
  } catch (e) {
    print('[BackgroundFetch] Headless error: $e');
  }

  BackgroundFetch.finish(taskId);
}

Future<void> _configureBackgroundFetch() async {
  // 1. Configure background fetch parameters
  final status = await BackgroundFetch.configure(
    BackgroundFetchConfig(
      minimumFetchInterval: 15,
      stopOnTerminate: false,
      startOnBoot: true,
      enableHeadless: true,
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresDeviceIdle: false,
      requiresStorageNotLow: false,
      requiredNetworkType: NetworkType.ANY,
    ),
    (String taskId) async {
      // Background fetch callback (active app/background state)
      print('[BackgroundFetch] Event received: $taskId');
      try {
        final keyManager = KeyManager(appDatabase);
        final deviceService = DeviceService(appDatabase, keyManager);
        final isRegistered = await deviceService.isDeviceRegistered();
        final deviceId = await deviceService.getOrCreateDeviceId();

        if (isRegistered && deviceId.isNotEmpty) {
          final sessionManager = SessionManager(appDatabase, keyManager);
          final messageService = MessageService(appDatabase, keyManager, sessionManager);
          await messageService.catchUp(deviceId);
        }
      } catch (e) {
        print('[BackgroundFetch] Callback error: $e');
      }
      BackgroundFetch.finish(taskId);
    },
    (String taskId) async {
      // Timeout callback
      print('[BackgroundFetch] Timeout event: $taskId');
      BackgroundFetch.finish(taskId);
    },
  );

  print('[BackgroundFetch] Configuration status: $status');

  // 2. Register headless task callback
  await BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Drift database (chatizy_local)
  appDatabase = AppDatabase();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(ChatizyApp(db: appDatabase));

  // Initialize local notifications and configure BackgroundFetch asynchronously
  Future.microtask(() async {
    try {
      await SoundService().init();
      await NotificationService().init();
      await _configureBackgroundFetch();
    } catch (e) {
      print('Failed to configure background fetch, sounds, or notifications: $e');
    }
  });
}
