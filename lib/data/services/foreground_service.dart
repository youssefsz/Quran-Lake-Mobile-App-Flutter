import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'adhan_service.dart';
import 'background_service.dart';

/// Foreground service to keep adhan and countdown running even after app is killed
/// This service auto-starts on boot and continues running in the background
class ForegroundService {
  static const String notificationChannelId = 'quran_lake_foreground_service';
  static const String notificationChannelName = 'Quran Lake Service';
  static const int notificationId = 888;

  /// Initialize and start the foreground service
  static Future<void> start() async {
    final service = FlutterBackgroundService();

    // Configure Android-specific settings
    // Note: Using background mode instead of foreground mode to avoid Android 14+ type requirement
    // WorkManager and AlarmManager will handle the actual scheduling
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true, // Auto-start on boot
        isForegroundMode:
            false, // Use background mode to avoid Android 14+ foreground service type issue
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'Quran Lake',
        initialNotificationContent: 'Adhan and countdown service is running',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        // iOS restrictions: No foreground services like Android
        // Background App Refresh is limited to ~15 minutes
        // Local notifications are handled by the system automatically
        // The service will use Background App Refresh when available
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    // Start the service
    await service.startService();
    debugPrint('Foreground service started');
  }

  /// Stop the foreground service
  static Future<void> stop() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
    debugPrint('Foreground service stopped');
  }

  /// Check if service is running
  static Future<bool> isRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }
}

/// Background service entry point (runs in isolate)
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Handle stop service event
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Platform-specific handling
  if (service is AndroidServiceInstance) {
    // Android: Not using foreground service mode to avoid Android 14+ type requirement
    // WorkManager and AlarmManager will handle the actual scheduling
    // The service runs in background mode which is sufficient for our use case
  }

  // Initialize services (works for both Android and iOS)
  try {
    final prefs = await SharedPreferences.getInstance();
    final adhanEnabled = prefs.getBool('adhan_enabled') ?? false;

    if (adhanEnabled) {
      // Ensure background tasks are registered (Android only - WorkManager)
      if (service is AndroidServiceInstance) {
        await BackgroundService.initialize();
        await BackgroundService.registerDailyTask();

        // Register countdown update task if countdown is enabled
        final countdownEnabled =
            prefs.getBool('adhan_countdown_enabled') ?? true;
        if (countdownEnabled) {
          await BackgroundService.registerCountdownUpdateTask();
        }
      }

      // Initialize adhan service (works on both platforms)
      // iOS uses local notifications scheduled by AdhanService
      final adhanService = AdhanService(prefs);
      await adhanService.initialize();

      // Check if we need to show countdown on service start
      // This handles the case when service starts after app was killed
      final prayerName = prefs.getString('countdown_prayer_name');
      final prayerTimeStr = prefs.getString('countdown_prayer_time');

      if (prayerName != null && prayerTimeStr != null) {
        final prayerDateTime = DateTime.parse(prayerTimeStr);
        final now = DateTime.now();
        final remaining = prayerDateTime.difference(now);

        if (remaining.inSeconds > 0 && remaining.inMinutes <= 120) {
          // Update countdown notification
          await adhanService.updateCountdownNotification();
          debugPrint('Background service: Updated countdown for $prayerName');
        }
      }

      debugPrint('Background service: Services initialized and running');
    }
  } catch (e) {
    debugPrint('Background service error: $e');
  }
}

/// iOS background handler
/// iOS restrictions:
/// - No foreground services (unlike Android)
/// - Background App Refresh limited to ~15 minutes
/// - Local notifications are handled by iOS system automatically
/// - AdhanService uses flutter_local_notifications which schedules notifications
///   that iOS delivers even when app is backgrounded or killed
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final adhanEnabled = prefs.getBool('adhan_enabled') ?? false;

    if (adhanEnabled) {
      // Initialize adhan service - it will schedule local notifications
      // iOS will deliver these notifications even when app is killed
      final adhanService = AdhanService(prefs);
      await adhanService.initialize();
      debugPrint('iOS background: Adhan service initialized');
    }

    return true;
  } catch (e) {
    debugPrint('iOS background error: $e');
    return false;
  }
}
