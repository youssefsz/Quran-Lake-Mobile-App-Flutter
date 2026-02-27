import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'adhan_service.dart';
import 'foreground_service.dart';
import '../models/prayer_time.dart';

// Task names for background work
const String _prayerTimesTaskName = 'prayerTimesBackgroundTask';
const String _countdownUpdateTaskName = 'adhanCountdownUpdateTask';

/// Background service to fetch prayer times and reschedule alarms daily
class BackgroundService {
  static const String taskName = _prayerTimesTaskName;
  static const String countdownUpdateTaskName = _countdownUpdateTaskName;

  /// Initialize background fetch
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
  }

  /// Register daily background task to fetch prayer times and reschedule alarms
  static Future<void> registerDailyTask() async {
    // Cancel existing task first
    await Workmanager().cancelByUniqueName(taskName);

    // Register periodic task that runs daily
    // Runs at least once per day, with minimum interval of 15 minutes
    await Workmanager().registerPeriodicTask(
      taskName,
      taskName,
      frequency: const Duration(hours: 24), // Run daily
      constraints: Constraints(
        networkType: NetworkType.connected, // Requires internet
      ),
      initialDelay: const Duration(minutes: 1), // Start after 1 minute
    );

    debugPrint('Background task registered: $taskName');
  }

  /// Register periodic countdown update task
  /// Updates countdown notification every minute to ensure accuracy
  static Future<void> registerCountdownUpdateTask() async {
    // Cancel existing task first
    await Workmanager().cancelByUniqueName(countdownUpdateTaskName);

    // Register periodic task that runs every minute
    // This ensures the countdown notification stays accurate even when app is closed
    await Workmanager().registerPeriodicTask(
      countdownUpdateTaskName,
      countdownUpdateTaskName,
      frequency: const Duration(minutes: 1), // Run every minute
      constraints: Constraints(
        // No network required - just updates notification
      ),
      initialDelay: const Duration(seconds: 30), // Start after 30 seconds
    );

    debugPrint('Countdown update task registered: $countdownUpdateTaskName');
  }

  /// Cancel countdown update task
  static Future<void> cancelCountdownUpdateTask() async {
    await Workmanager().cancelByUniqueName(countdownUpdateTaskName);
    debugPrint('Countdown update task cancelled: $countdownUpdateTaskName');
  }

  /// Cancel background task
  static Future<void> cancelTask() async {
    await Workmanager().cancelByUniqueName(taskName);
    await cancelCountdownUpdateTask(); // Also cancel countdown updates
    debugPrint('Background task cancelled: $taskName');
  }
}

/// Background task callback - runs in isolate
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('Background task started: $task');

    // Handle countdown cancellation task (cancel notification when prayer time arrives)
    if (task.startsWith('adhanCountdownUpdateTask_cancel_')) {
      try {
        final prefs = await SharedPreferences.getInstance();
        // Extract prayer name from task name
        final prayerName = task.replaceFirst('adhanCountdownUpdateTask_cancel_', '');
        final adhanService = AdhanService(prefs);
        await adhanService.initialize();
        await adhanService.cancelCountdownForPrayer(prayerName);
        debugPrint('Cancelled countdown notification for $prayerName (prayer time arrived)');
        return Future.value(true);
      } catch (e) {
        debugPrint('Error cancelling countdown notification in background: $e');
        return Future.value(false);
      }
    }

    // Handle periodic countdown update task (runs every minute)
    if (task == _countdownUpdateTaskName) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final prayerName = prefs.getString('countdown_prayer_name');
        final prayerTimeStr = prefs.getString('countdown_prayer_time');

        if (prayerName != null && prayerTimeStr != null) {
          final adhanService = AdhanService(prefs);
          await adhanService.initialize();
          // Update the countdown notification to ensure accuracy
          await adhanService.updateCountdownNotification();
          debugPrint('Updated countdown notification for $prayerName (background service)');
        } else {
          // No active countdown, cancel the task
          await Workmanager().cancelByUniqueName(_countdownUpdateTaskName);
          debugPrint('No active countdown, cancelled countdown update task');
        }
        return Future.value(true);
      } catch (e) {
        debugPrint('Error updating countdown notification in background: $e');
        return Future.value(false);
      }
    }

    // Handle countdown reminder task (reshow notification if dismissed)
    if (task.startsWith('adhanCountdownUpdateTask_') && 
        task != _countdownUpdateTaskName &&
        !task.startsWith('adhanCountdownUpdateTask_cancel_')) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final prayerName = prefs.getString('countdown_prayer_name');
        final prayerTimeStr = prefs.getString('countdown_prayer_time');

        if (prayerName != null && prayerTimeStr != null) {
          final adhanService = AdhanService(prefs);
          await adhanService.initialize();
          // Reshow the notification with chronometer
          await adhanService.updateCountdownNotification();
          debugPrint('Reshowed countdown notification for $prayerName');
        }
        return Future.value(true);
      } catch (e) {
        debugPrint('Error reshowing countdown notification in background: $e');
        return Future.value(false);
      }
    }

    // Handle daily prayer times update task
    try {
      // Get SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      // Check if adhan is enabled
      final adhanEnabled = prefs.getBool('adhan_enabled') ?? false;
      if (!adhanEnabled) {
        debugPrint('Adhan is disabled, skipping background fetch');
        return Future.value(true);
      }

      // Ensure foreground service is running (auto-start on boot/after app kill)
      try {
        final isRunning = await ForegroundService.isRunning();
        if (!isRunning) {
          await ForegroundService.start();
          debugPrint('Foreground service auto-started from background task');
        }
      } catch (e) {
        debugPrint('Error starting foreground service: $e');
      }

      // Get cached location
      final cachedLat = prefs.getDouble('last_latitude');
      final cachedLng = prefs.getDouble('last_longitude');

      if (cachedLat == null || cachedLng == null) {
        debugPrint('No cached location found, skipping background fetch');
        return Future.value(true);
      }

      // Fetch prayer times from API
      final prayerTime = await _fetchPrayerTimesInBackground(
        cachedLat,
        cachedLng,
      );

      if (prayerTime != null) {
        // Initialize adhan service and reschedule alarms
        final adhanService = AdhanService(prefs);
        await adhanService.initialize();
        await adhanService.scheduleAdhanAlarms(prayerTime);
        debugPrint('Background task: Alarms rescheduled successfully');
      } else {
        debugPrint('Background task: Failed to fetch prayer times');
      }

      return Future.value(true);
    } catch (e, stackTrace) {
      debugPrint('Background task error: $e');
      debugPrint('Stack trace: $stackTrace');
      return Future.value(false);
    }
  });
}

/// Fetch prayer times in background isolate using HTTP
Future<PrayerTime?> _fetchPrayerTimesInBackground(
  double latitude,
  double longitude,
) async {
  try {
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';

    // Fetch prayer times from Aladhan API
    final url = Uri.parse(
      'https://api.aladhan.com/v1/timings/$dateStr?latitude=$latitude&longitude=$longitude&method=2',
    );

    final response = await http.get(url).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception('Request timeout');
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final timings = jsonData['data']['timings'];

      // Fetch location name (optional, use cached if available)
      String city = 'Unknown';
      String country = 'Unknown';

      try {
        final locationUrl = Uri.parse(
          'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$latitude&longitude=$longitude&localityLanguage=en',
        );
        final locationResponse = await http.get(locationUrl).timeout(
          const Duration(seconds: 10),
        );

        if (locationResponse.statusCode == 200) {
          final locationData = json.decode(locationResponse.body);
          city = locationData['city'] ?? 'Unknown';
          country = locationData['countryName'] ?? 'Unknown';
        }
      } catch (e) {
        debugPrint('Error fetching location name: $e');
      }

      // Create PrayerTime object
      final prayerTime = PrayerTime(
        date: dateStr,
        fajr: timings['Fajr'],
        sunrise: timings['Sunrise'],
        dhuhr: timings['Dhuhr'],
        asr: timings['Asr'],
        maghrib: timings['Maghrib'],
        isha: timings['Isha'],
        city: city,
        country: country,
      );

      debugPrint('Background task: Prayer times fetched successfully');
      return prayerTime;
    } else {
      debugPrint('Background task: API returned status ${response.statusCode}');
      return null;
    }
  } catch (e) {
    debugPrint('Error fetching prayer times in background: $e');
    return null;
  }
}
