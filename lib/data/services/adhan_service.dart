import 'dart:convert';
import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../data/models/prayer_time.dart';
import 'background_service.dart';

/// Service to handle adhan (call to prayer) scheduling and playback
class AdhanService {
  static const String _prefKeyEnabled = 'adhan_enabled';
  static const String _prefKeyFajrEnabled = 'adhan_fajr_enabled';
  static const String _prefKeySunriseEnabled = 'adhan_sunrise_enabled';
  static const String _prefKeyDhuhrEnabled = 'adhan_dhuhr_enabled';
  static const String _prefKeyAsrEnabled = 'adhan_asr_enabled';
  static const String _prefKeyMaghribEnabled = 'adhan_maghrib_enabled';
  static const String _prefKeyIshaEnabled = 'adhan_isha_enabled';
  static const String _prefKeyVolume = 'adhan_volume';
  static const String _prefKeySound = 'adhan_sound';
  static const String _prefKeyCountdownEnabled = 'adhan_countdown_enabled';
  static const String _prefKeyCountdownPrayerName = 'countdown_prayer_name';
  static const String _prefKeyCountdownPrayerTime = 'countdown_prayer_time';
  static const String countdownTaskName = 'adhanCountdownUpdateTask';

  final AudioPlayer _audioPlayer = AudioPlayer();
  final SharedPreferences _prefs;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  AdhanService(this._prefs);

  /// Initialize notifications - must be called before scheduling
  Future<void> initialize() async {
    if (_initialized) return;
    await _initializeNotifications();
    _initialized = true;
  }

  /// Initialize local notifications for silent countdown notifications
  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@drawable/notification_icon', // Use drawable for notification icon (status bar)
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: false, // Silent notifications
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);

    // Create notification channel for Android (required for scheduled notifications)
    // High importance to ensure notifications appear even when app is closed
    const androidChannel = AndroidNotificationChannel(
      'adhan_countdown_channel',
      'Adhan Countdown',
      description: 'Silent countdown notifications before prayer time',
      importance:
          Importance.high, // High importance = visible in notification bar
      playSound: false, // Silent - no sound
      enableVibration: false, // Silent - no vibration
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  // ===========================================================================
  // Settings Getters
  // ===========================================================================

  bool get isEnabled => _prefs.getBool(_prefKeyEnabled) ?? false;
  bool get isFajrEnabled => _prefs.getBool(_prefKeyFajrEnabled) ?? true;
  bool get isSunriseEnabled =>
      _prefs.getBool(_prefKeySunriseEnabled) ?? false; // Default OFF
  bool get isDhuhrEnabled => _prefs.getBool(_prefKeyDhuhrEnabled) ?? true;
  bool get isAsrEnabled => _prefs.getBool(_prefKeyAsrEnabled) ?? true;
  bool get isMaghribEnabled => _prefs.getBool(_prefKeyMaghribEnabled) ?? true;
  bool get isIshaEnabled => _prefs.getBool(_prefKeyIshaEnabled) ?? true;
  double get volume => _prefs.getDouble(_prefKeyVolume) ?? 0.8;
  String get sound => _prefs.getString(_prefKeySound) ?? 'default';
  bool get isCountdownEnabled =>
      _prefs.getBool(_prefKeyCountdownEnabled) ?? true;

  // ===========================================================================
  // Settings Setters
  // ===========================================================================

  Future<void> setEnabled(bool enabled) async {
    await _prefs.setBool(_prefKeyEnabled, enabled);
    if (!enabled) {
      await cancelAllAlarms();
    }
  }

  Future<void> setFajrEnabled(bool enabled) async {
    await _prefs.setBool(_prefKeyFajrEnabled, enabled);
  }

  Future<void> setSunriseEnabled(bool enabled) async {
    await _prefs.setBool(_prefKeySunriseEnabled, enabled);
  }

  Future<void> setDhuhrEnabled(bool enabled) async {
    await _prefs.setBool(_prefKeyDhuhrEnabled, enabled);
  }

  Future<void> setAsrEnabled(bool enabled) async {
    await _prefs.setBool(_prefKeyAsrEnabled, enabled);
  }

  Future<void> setMaghribEnabled(bool enabled) async {
    await _prefs.setBool(_prefKeyMaghribEnabled, enabled);
  }

  Future<void> setIshaEnabled(bool enabled) async {
    await _prefs.setBool(_prefKeyIshaEnabled, enabled);
  }

  Future<void> setVolume(double volume) async {
    await _prefs.setDouble(_prefKeyVolume, volume.clamp(0.0, 1.0));
  }

  Future<void> setSound(String sound) async {
    await _prefs.setString(_prefKeySound, sound);
  }

  Future<void> setCountdownEnabled(bool enabled) async {
    await _prefs.setBool(_prefKeyCountdownEnabled, enabled);
    if (!enabled) {
      await cancelAllCountdownAlarms();
      await BackgroundService.cancelCountdownUpdateTask();
    } else if (isEnabled) {
      // If adhan is enabled and countdown is now enabled, register the task
      await BackgroundService.registerCountdownUpdateTask();
    }
  }

  // ===========================================================================
  // Prayer-specific enabled check
  // ===========================================================================

  bool isPrayerEnabled(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        return isFajrEnabled;
      case 'sunrise':
        return isSunriseEnabled;
      case 'dhuhr':
        return isDhuhrEnabled;
      case 'asr':
        return isAsrEnabled;
      case 'maghrib':
        return isMaghribEnabled;
      case 'isha':
        return isIshaEnabled;
      default:
        return false;
    }
  }

  // ===========================================================================
  // Alarm Scheduling
  // ===========================================================================

  /// Check and show countdown notification on app open if prayer is within 0-120 minutes
  Future<void> checkAndShowCountdownOnAppOpen(PrayerTime prayerTime) async {
    if (!isEnabled) {
      return;
    }

    // Ensure notifications are initialized
    if (!_initialized) {
      await initialize();
    }

    // Ensure background countdown update task is registered
    if (isCountdownEnabled) {
      await BackgroundService.registerCountdownUpdateTask();
    }

    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day);

    // Helper to parse time string and create DateTime
    DateTime parseTime(String timeStr) {
      final cleanTime = timeStr.replaceAll(RegExp(r'\s*\(.*\)'), '').trim();
      final parts = cleanTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(date.year, date.month, date.day, hour, minute);
    }

    // Check all prayers
    final prayers = [
      ('Fajr', parseTime(prayerTime.fajr)),
      ('Sunrise', parseTime(prayerTime.sunrise)),
      ('Dhuhr', parseTime(prayerTime.dhuhr)),
      ('Asr', parseTime(prayerTime.asr)),
      ('Maghrib', parseTime(prayerTime.maghrib)),
      ('Isha', parseTime(prayerTime.isha)),
    ];

    // Find the next prayer within 0-120 minutes
    for (final (prayerName, prayerDateTime) in prayers) {
      if (!isPrayerEnabled(prayerName)) {
        continue;
      }

      // If the prayer time has already passed today, check tomorrow
      DateTime nextPrayerDateTime = prayerDateTime;
      if (nextPrayerDateTime.isBefore(now)) {
        nextPrayerDateTime = nextPrayerDateTime.add(const Duration(days: 1));
      }

      // Calculate minutes until prayer
      final totalSeconds = nextPrayerDateTime.difference(now).inSeconds;
      final minutesUntilPrayer = totalSeconds ~/ 60;

      // If prayer is within 0-120 minutes, show notification immediately
      if (totalSeconds >= 1 && minutesUntilPrayer <= 120) {
        await _showCountdownNotification(prayerName, nextPrayerDateTime);

        // Store prayer info for reminder scheduling
        await _prefs.setString(_prefKeyCountdownPrayerName, prayerName);
        await _prefs.setString(
          _prefKeyCountdownPrayerTime,
          nextPrayerDateTime.toIso8601String(),
        );

        // Schedule recurring reminder notifications every 2 minutes until prayer time
        // All reminders use the same notification ID, so:
        // - If notification is dismissed, the next reminder will reappear (needed)
        // - If notification is still showing, the next reminder will update it (redundant but harmless)
        //   Note: The chronometer already counts down automatically, so updates are only needed if dismissed
        //   Android handles duplicate updates efficiently (may not even trigger visual update)
        DateTime nextReminder = now.add(const Duration(minutes: 2));
        int reminderCount = 0;
        // Schedule reminders every 2 minutes, but limit to reasonable number
        // We can't detect if notification was dismissed when app is closed, so we schedule as safety net
        while (nextReminder.isBefore(nextPrayerDateTime) &&
            nextPrayerDateTime.difference(nextReminder).inMinutes > 2 &&
            reminderCount < 30) {
          // Limit to 30 reminders (1 hour max) - enough for most cases
          await _scheduleCountdownReminder(
            prayerName,
            nextPrayerDateTime,
            nextReminder,
          );
          nextReminder = nextReminder.add(const Duration(minutes: 2));
          reminderCount++;
        }

        // Schedule cancellation at prayer time
        await _scheduleCountdownCancellation(prayerName, nextPrayerDateTime);

        // Ensure background countdown update task is registered
        if (isCountdownEnabled) {
          await BackgroundService.registerCountdownUpdateTask();
        }

        debugPrint(
          'Showed countdown notification on app open for $prayerName (${minutesUntilPrayer} minutes until prayer)',
        );
        return; // Only show for the first/next prayer
      }
    }
  }

  /// Schedule adhan alarms for all prayers in the given PrayerTime
  Future<void> scheduleAdhanAlarms(PrayerTime prayerTime) async {
    if (!isEnabled) {
      debugPrint('Adhan is disabled, skipping alarm scheduling');
      return;
    }

    // Ensure notifications are initialized
    if (!_initialized) {
      await initialize();
    }

    // Cancel existing alarms first
    await cancelAllAlarms();

    // Register background countdown update task to keep countdown running
    if (isCountdownEnabled) {
      await BackgroundService.registerCountdownUpdateTask();
    }

    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day);

    // Helper to parse time string and create DateTime
    DateTime parseTime(String timeStr) {
      final cleanTime = timeStr.replaceAll(RegExp(r'\s*\(.*\)'), '').trim();
      final parts = cleanTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(date.year, date.month, date.day, hour, minute);
    }

    // Schedule alarms for each prayer
    final prayers = [
      ('Fajr', parseTime(prayerTime.fajr)),
      ('Sunrise', parseTime(prayerTime.sunrise)),
      ('Dhuhr', parseTime(prayerTime.dhuhr)),
      ('Asr', parseTime(prayerTime.asr)),
      ('Maghrib', parseTime(prayerTime.maghrib)),
      ('Isha', parseTime(prayerTime.isha)),
    ];

    for (final (prayerName, prayerDateTime) in prayers) {
      if (!isPrayerEnabled(prayerName)) {
        debugPrint('Adhan for $prayerName is disabled, skipping');
        continue;
      }

      // If the prayer time has already passed today, schedule for tomorrow
      DateTime alarmDateTime = prayerDateTime;
      if (alarmDateTime.isBefore(now)) {
        alarmDateTime = alarmDateTime.add(const Duration(days: 1));
      }

      try {
        // Create notification settings
        final notificationSettings = NotificationSettings(
          title: 'Adhan - $prayerName',
          body: 'Time for $prayerName prayer',
        );

        // VolumeSettings in alarm 5.2.1 uses named constructors
        // Use VolumeSettings.fixed() for a fixed volume level
        final volumeSettings = VolumeSettings.fixed(
          volume: volume,
          volumeEnforced: false,
        );

        // AlarmSettings uses Android AlarmManager under the hood
        // With SCHEDULE_EXACT_ALARM permission, it uses AlarmManager.setExactAndAllowWhileIdle()
        // This ensures alarms fire even when app is closed or device is in doze mode
        final audioPath = await _getAdhanAudioPath();
        final alarmSettings = AlarmSettings(
          id: _getAlarmId(prayerName),
          dateTime: alarmDateTime,
          assetAudioPath: audioPath,
          loopAudio: false,
          vibrate: true,
          volumeSettings: volumeSettings,
          notificationSettings: notificationSettings,
        );

        // Alarm.set() uses AlarmManager to schedule exact alarms
        // Works in background even when app is closed
        await Alarm.set(alarmSettings: alarmSettings);
        debugPrint(
          'Scheduled adhan for $prayerName at ${alarmDateTime.toString()}',
        );

        // Always schedule countdown notifications (30min, 15min, 5min before)
        await _scheduleCountdownNotifications(prayerName, alarmDateTime);
      } catch (e) {
        debugPrint('Error scheduling adhan for $prayerName: $e');
      }
    }
  }

  /// Schedule countdown notifications before prayer time
  /// Shows ONE notification that updates every second (live countdown with seconds)
  /// If dismissed, it reappears after 2 minutes
  Future<void> _scheduleCountdownNotifications(
    String prayerName,
    DateTime prayerDateTime,
  ) async {
    final now = DateTime.now();

    // Calculate total seconds until prayer
    final totalSeconds = prayerDateTime.difference(now).inSeconds;
    final minutesUntilPrayer = totalSeconds ~/ 60;

    // Store prayer info (needed for showing notification even when app is closed)
    await _prefs.setString(_prefKeyCountdownPrayerName, prayerName);
    await _prefs.setString(
      _prefKeyCountdownPrayerTime,
      prayerDateTime.toIso8601String(),
    );

    // Calculate when to show notification (120 minutes before prayer)
    final showAt120Minutes = prayerDateTime.subtract(
      const Duration(minutes: 120),
    );

    // If prayer is within 0-120 minutes, show notification immediately
    if (totalSeconds >= 1 && minutesUntilPrayer <= 120) {
      await _showCountdownNotification(prayerName, prayerDateTime);

      // Also schedule it to appear at 120 minutes before (in case app closes and reopens)
      // This ensures it persists even if app is closed
      if (showAt120Minutes.isAfter(now)) {
        await _scheduleCountdownNotification(
          prayerName,
          prayerDateTime,
          showAt120Minutes,
        );
      }
    }
    // If prayer is more than 120 minutes away, schedule notification to appear at 120 minutes before
    // This ensures it appears even if app is closed when prayer enters 0-120 minute window
    else if (showAt120Minutes.isAfter(now)) {
      await _scheduleCountdownNotification(
        prayerName,
        prayerDateTime,
        showAt120Minutes,
      );
    }

    // Schedule a task to cancel countdown notification when prayer time arrives
    // This ensures the notification is removed even if alarm callback doesn't fire
    await _scheduleCountdownCancellation(prayerName, prayerDateTime);

    // Register background countdown update task to keep countdown running
    if (isCountdownEnabled) {
      await BackgroundService.registerCountdownUpdateTask();
    }

    // Schedule recurring reminder notifications every 2 minutes until prayer time
    // All reminders use the same notification ID, so:
    // - If notification is dismissed, the next reminder will reappear (needed)
    // - If notification is still showing, the next reminder will update it (redundant but harmless)
    //   Note: The chronometer already counts down automatically, so updates are only needed if dismissed
    //   Android handles duplicate updates efficiently (may not even trigger visual update)
    // Works even when app is closed and screen is off
    DateTime nextReminder = now.add(const Duration(minutes: 2));
    int reminderCount = 0;
    // Schedule reminders every 2 minutes, but limit to reasonable number
    // We can't detect if notification was dismissed when app is closed, so we schedule as safety net
    while (nextReminder.isBefore(prayerDateTime) &&
        prayerDateTime.difference(nextReminder).inMinutes > 2 &&
        reminderCount < 30) {
      // Limit to 30 reminders (1 hour max) - enough for most cases
      await _scheduleCountdownReminder(
        prayerName,
        prayerDateTime,
        nextReminder,
      );
      nextReminder = nextReminder.add(const Duration(minutes: 2));
      reminderCount++;
    }
  }

  /// Show an immediate countdown notification with chronometer (counts down automatically)
  Future<void> _showCountdownNotification(
    String prayerName,
    DateTime prayerDateTime,
  ) async {
    try {
      final notificationId = _getCountdownNotificationId(prayerName);

      // Convert prayer time to milliseconds since epoch for chronometer
      final prayerTimeMs = prayerDateTime.millisecondsSinceEpoch;

      // Silent notification with chronometer - counts down automatically
      final androidDetails = AndroidNotificationDetails(
        'adhan_countdown_channel',
        'Adhan Countdown',
        channelDescription: 'Silent countdown notifications before prayer time',
        importance: Importance.high, // Visible in notification bar
        priority: Priority.high, // High priority to ensure it appears
        playSound: false, // Silent - no sound
        enableVibration: false, // Silent - no vibration
        showWhen: true,
        when: prayerTimeMs, // Set to prayer time for chronometer
        usesChronometer: true, // Enable chronometer (counts down to when)
        ongoing: true, // Ongoing so it stays visible
        autoCancel: false, // Don't auto-cancel
        onlyAlertOnce: false,
        icon:
            '@drawable/notification_icon', // Use drawable for notification icon (status bar)
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false, // Silent
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        notificationId,
        '$prayerName prayer',
        'Prepare for $prayerName prayer',
        notificationDetails,
      );

      debugPrint(
        'Showed countdown notification with chronometer: $prayerName (Notification ID: $notificationId - counts down automatically)',
      );
    } catch (e) {
      debugPrint('Error showing countdown notification for $prayerName: $e');
    }
  }

  /// Schedule countdown notification to appear at a specific time (works even when app is closed)
  Future<void> _scheduleCountdownNotification(
    String prayerName,
    DateTime prayerDateTime,
    DateTime showAt,
  ) async {
    try {
      final notificationId = _getCountdownNotificationId(prayerName);
      final prayerTimeMs = prayerDateTime.millisecondsSinceEpoch;

      // Convert to timezone-aware DateTime
      tz.Location location;
      try {
        location = tz.local;
      } catch (e) {
        location = tz.UTC;
      }
      final scheduledDate = tz.TZDateTime.from(showAt, location);

      // Silent notification with chronometer - counts down automatically
      final androidDetails = AndroidNotificationDetails(
        'adhan_countdown_channel',
        'Adhan Countdown',
        channelDescription: 'Silent countdown notifications before prayer time',
        importance: Importance.high,
        priority: Priority.high,
        playSound: false,
        enableVibration: false,
        showWhen: true,
        when: prayerTimeMs, // Set to prayer time for chronometer
        usesChronometer: true, // Enable chronometer (counts down automatically)
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: false,
        icon:
            '@drawable/notification_icon', // Use drawable for notification icon (status bar)
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        notificationId,
        '$prayerName prayer',
        'Prepare for $prayerName prayer',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint(
        'Scheduled countdown notification for $prayerName to appear at ${showAt.toString()} (works even when app is closed)',
      );
    } catch (e) {
      debugPrint('Error scheduling countdown notification for $prayerName: $e');
    }
  }

  /// Schedule a task to cancel countdown notification when prayer time arrives
  /// Note: Primary cancellation happens via Alarm.ringStream callback in main.dart
  /// This Workmanager task is a backup (may be delayed in doze mode, but alarm callback is reliable)
  Future<void> _scheduleCountdownCancellation(
    String prayerName,
    DateTime prayerDateTime,
  ) async {
    try {
      // Schedule a one-time task to cancel the countdown at prayer time (backup method)
      // Primary cancellation is handled by Alarm.ringStream callback in main.dart
      // which uses AlarmManager and works reliably even when app is closed
      final now = DateTime.now();
      final delay = prayerDateTime.difference(now);

      if (delay.inSeconds > 0) {
        await Workmanager().registerOneOffTask(
          '${countdownTaskName}_cancel_$prayerName',
          '${countdownTaskName}_cancel_$prayerName',
          initialDelay: delay,
        );

        debugPrint(
          'Scheduled countdown cancellation backup task for $prayerName at ${prayerDateTime.toString()} (primary: alarm callback)',
        );
      }
    } catch (e) {
      debugPrint('Error scheduling countdown cancellation for $prayerName: $e');
    }
  }

  /// Schedule a reminder notification (reappears after 2 minutes if dismissed)
  /// Uses scheduled notification to ensure it works even when screen is off and app is closed
  Future<void> _scheduleCountdownReminder(
    String prayerName,
    DateTime prayerDateTime,
    DateTime reminderDateTime,
  ) async {
    try {
      final notificationId = _getCountdownNotificationId(prayerName);
      final prayerTimeMs = prayerDateTime.millisecondsSinceEpoch;

      // Convert to timezone-aware DateTime
      tz.Location location;
      try {
        location = tz.local;
      } catch (e) {
        location = tz.UTC;
      }
      final scheduledDate = tz.TZDateTime.from(reminderDateTime, location);

      // Silent notification with chronometer - counts down automatically
      final androidDetails = AndroidNotificationDetails(
        'adhan_countdown_channel',
        'Adhan Countdown',
        channelDescription: 'Silent countdown notifications before prayer time',
        importance: Importance.high,
        priority: Priority.high,
        playSound: false,
        enableVibration: false,
        showWhen: true,
        when: prayerTimeMs, // Set to prayer time for chronometer
        usesChronometer: true, // Enable chronometer (counts down automatically)
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: false,
        icon:
            '@drawable/notification_icon', // Use drawable for notification icon (status bar)
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule notification to reappear after 2 minutes
      // Uses exactAllowWhileIdle to work even when screen is off and app is closed
      await _notifications.zonedSchedule(
        notificationId, // Same ID = replaces if still showing, or reappears if dismissed
        '$prayerName prayer',
        'Prepare for $prayerName prayer',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint(
        'Scheduled countdown reminder for $prayerName at ${reminderDateTime.toString()} (will reshow if dismissed, works even when screen is off)',
      );
    } catch (e) {
      debugPrint('Error scheduling countdown reminder for $prayerName: $e');
    }
  }

  /// Get notification ID for countdown notifications
  /// All countdown notifications for the same prayer use the same ID
  /// so they replace each other (30min -> 15min -> 5min)
  int _getCountdownNotificationId(String prayerName) {
    final baseId = _getAlarmId(prayerName);
    // Use same ID for all countdowns of the same prayer
    return baseId * 100 + 1;
  }

  /// Cancel all adhan alarms
  Future<void> cancelAllAlarms() async {
    final prayerNames = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    for (final prayerName in prayerNames) {
      try {
        await Alarm.stop(_getAlarmId(prayerName));
      } catch (e) {
        debugPrint('Error canceling alarm for $prayerName: $e');
      }
    }
    // Also cancel countdown alarms
    await cancelAllCountdownAlarms();
    // Cancel background countdown update task
    await BackgroundService.cancelCountdownUpdateTask();
  }

  /// Cancel countdown notification for a specific prayer
  Future<void> cancelCountdownForPrayer(String prayerName) async {
    try {
      final notificationId = _getCountdownNotificationId(prayerName);
      await _notifications.cancel(notificationId);

      // Clear stored countdown info if it matches this prayer
      final storedPrayerName = _prefs.getString(_prefKeyCountdownPrayerName);
      if (storedPrayerName == prayerName) {
        await _prefs.remove(_prefKeyCountdownPrayerName);
        await _prefs.remove(_prefKeyCountdownPrayerTime);
      }

      debugPrint('Cancelled countdown notification for $prayerName');
    } catch (e) {
      debugPrint('Error canceling countdown notification for $prayerName: $e');
    }
  }

  /// Cancel all countdown notification alarms
  Future<void> cancelAllCountdownAlarms() async {
    final prayerNames = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    for (final prayerName in prayerNames) {
      try {
        // All countdowns for the same prayer use the same notification ID
        final notificationId = _getCountdownNotificationId(prayerName);
        await _notifications.cancel(notificationId);
      } catch (e) {
        debugPrint(
          'Error canceling countdown notification for $prayerName: $e',
        );
      }
    }

    // Clear stored countdown info
    await _prefs.remove(_prefKeyCountdownPrayerName);
    await _prefs.remove(_prefKeyCountdownPrayerTime);
    
    // Cancel background countdown update task if no countdown is active
    await BackgroundService.cancelCountdownUpdateTask();
  }

  /// Update countdown notification (called periodically)
  /// This can be called from a background task to keep the countdown live
  Future<void> updateCountdownNotification() async {
    try {
      final prayerName = _prefs.getString(_prefKeyCountdownPrayerName);
      final prayerTimeStr = _prefs.getString(_prefKeyCountdownPrayerTime);

      if (prayerName == null || prayerTimeStr == null) {
        return; // No active countdown
      }

      final prayerDateTime = DateTime.parse(prayerTimeStr);
      final now = DateTime.now();
      final remaining = prayerDateTime.difference(now);
      final minutesUntilPrayer = remaining.inMinutes;

      // Only update if prayer is between 0 and 120 minutes away
      if (remaining.inSeconds < 0 || minutesUntilPrayer > 120) {
        // Countdown expired, cancel it
        await cancelAllCountdownAlarms();
        return;
      }

      // Update the notification with chronometer
      final notificationId = _getCountdownNotificationId(prayerName);
      final prayerTimeMs = prayerDateTime.millisecondsSinceEpoch;

      final androidDetails = AndroidNotificationDetails(
        'adhan_countdown_channel',
        'Adhan Countdown',
        channelDescription: 'Silent countdown notifications before prayer time',
        importance: Importance.high,
        priority: Priority.high,
        playSound: false,
        enableVibration: false,
        showWhen: true,
        when: prayerTimeMs, // Set to prayer time for chronometer
        usesChronometer: true, // Enable chronometer (counts down automatically)
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: false,
        icon:
            '@drawable/notification_icon', // Use drawable for notification icon (status bar)
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        notificationId,
        '$prayerName prayer',
        'Prepare for $prayerName prayer',
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Error updating countdown notification: $e');
    }
  }

  /// Get unique alarm ID for a prayer
  int _getAlarmId(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        return 1;
      case 'sunrise':
        return 2;
      case 'dhuhr':
        return 3;
      case 'asr':
        return 4;
      case 'maghrib':
        return 5;
      case 'isha':
        return 6;
      default:
        return 0;
    }
  }

  /// Get adhan audio file path
  // Cache for dynamically loaded adhans
  List<Map<String, String>>? _cachedAdhans;

  /// Get list of available adhan voices dynamically from JSON config
  /// This allows adding/removing adhans by just updating assets/audio/adhans.json
  Future<List<Map<String, String>>> getAvailableAdhans() async {
    // Return cached if available
    if (_cachedAdhans != null) {
      return _cachedAdhans!;
    }

    try {
      // Load adhans configuration from JSON file
      final String jsonString = await rootBundle.loadString(
        'assets/audio/adhans.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> adhansList = jsonData['adhans'] ?? [];

      // Convert to List<Map<String, String>>
      _cachedAdhans = adhansList
          .map((adhan) => Map<String, String>.from(adhan as Map))
          .toList();

      // Fallback to default if empty
      if (_cachedAdhans!.isEmpty) {
        _cachedAdhans = [
          {
            'id': 'adhan-v1',
            'name': 'Voice 1',
            'path': 'assets/audio/adhan-v1.mp3',
          },
        ];
      }

      return _cachedAdhans!;
    } catch (e) {
      debugPrint('Error loading adhans.json: $e');
      // Fallback to default adhan if config file is missing or invalid
      _cachedAdhans = [
        {
          'id': 'adhan-v1',
          'name': 'Voice 1',
          'path': 'assets/audio/adhan-v1.mp3',
        },
      ];
      return _cachedAdhans!;
    }
  }

  /// Clear cache to reload adhans (useful if config changes)
  void clearAdhansCache() {
    _cachedAdhans = null;
  }

  /// Returns the path to the adhan audio file in assets based on selected sound
  /// Uses cached adhans or loads them if needed
  Future<String> _getAdhanAudioPath() async {
    final selectedSound = _prefs.getString(_prefKeySound) ?? 'adhan-v1';
    final adhans = await getAvailableAdhans();
    final adhan = adhans.firstWhere(
      (a) => a['id'] == selectedSound,
      orElse: () =>
          adhans.isNotEmpty ? adhans[0] : {'path': 'assets/audio/adhan-v1.mp3'},
    );
    return adhan['path'] ?? 'assets/audio/adhan-v1.mp3';
  }

  // ===========================================================================
  // Manual Playback (for testing)
  // ===========================================================================

  /// Play adhan audio manually (for testing or immediate playback)
  Future<void> playAdhan() async {
    try {
      final audioPath = await _getAdhanAudioPath();
      // For manual playback, we can use URL or asset
      // For alarm scheduling, we must use asset path
      // When using just_audio_background, we must use AudioSource with MediaItem tag
      if (audioPath.startsWith('http') || audioPath.startsWith('https')) {
        final mediaItem = MediaItem(
          id: audioPath,
          title: 'Adhan',
          album: 'Quran Lake',
          artist: 'Adhan',
        );
        final audioSource = AudioSource.uri(
          Uri.parse(audioPath),
          tag: mediaItem,
        );
        await _audioPlayer.setAudioSource(audioSource);
      } else {
        // For assets, use asset:// URI format which works with just_audio_background
        // Format: asset:///assets/audio/adhan-v1.mp3
        final assetUri = audioPath.startsWith('assets/')
            ? 'asset:///$audioPath'
            : 'asset:///assets/$audioPath';
        final mediaItem = MediaItem(
          id: audioPath,
          title: 'Adhan',
          album: 'Quran Lake',
          artist: 'Adhan',
        );
        final audioSource = AudioSource.uri(
          Uri.parse(assetUri),
          tag: mediaItem,
        );
        await _audioPlayer.setAudioSource(audioSource);
      }
      await _audioPlayer.setVolume(volume);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing adhan: $e');
    }
  }

  /// Preview a specific adhan voice by ID
  Future<void> previewAdhan(String adhanId) async {
    try {
      // Stop any currently playing adhan
      await stopAdhan();

      // Find the adhan by ID
      final adhans = await getAvailableAdhans();
      final adhan = adhans.firstWhere(
        (a) => a['id'] == adhanId,
        orElse: () => adhans.isNotEmpty
            ? adhans[0]
            : {'path': 'assets/audio/adhan-v1.mp3'},
      );
      final audioPath = adhan['path'] ?? 'assets/audio/adhan-v1.mp3';

      debugPrint('Previewing adhan: $adhanId from path: $audioPath');

      // Use a preview volume (ensure it's not 0, use at least 0.5 for preview)
      final previewVolume = volume > 0 ? volume : 0.5;

      // Play the preview
      // When using just_audio_background, we must use AudioSource with MediaItem tag
      if (audioPath.startsWith('http') || audioPath.startsWith('https')) {
        final mediaItem = MediaItem(
          id: audioPath,
          title: adhan['name'] ?? 'Adhan Preview',
          album: 'Quran Lake',
          artist: 'Adhan',
        );
        final audioSource = AudioSource.uri(
          Uri.parse(audioPath),
          tag: mediaItem,
        );
        await _audioPlayer.setAudioSource(audioSource);
      } else {
        // For assets, use asset:// URI format which works with just_audio_background
        // Format: asset:///assets/audio/adhan-v1.mp3
        final assetUri = audioPath.startsWith('assets/')
            ? 'asset:///$audioPath'
            : 'asset:///assets/$audioPath';
        debugPrint('Loading asset: $assetUri');

        final mediaItem = MediaItem(
          id: audioPath,
          title: adhan['name'] ?? 'Adhan Preview',
          album: 'Quran Lake',
          artist: 'Adhan',
        );
        final audioSource = AudioSource.uri(
          Uri.parse(assetUri),
          tag: mediaItem,
        );
        await _audioPlayer.setAudioSource(audioSource);
      }

      // Set volume before playing
      await _audioPlayer.setVolume(previewVolume);

      // Wait for audio to load by listening to processing state
      int attempts = 0;
      while (attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        final state = _audioPlayer.processingState;
        if (state == ProcessingState.ready) {
          break;
        }
        attempts++;
      }

      // Check if audio is loaded
      final duration = _audioPlayer.duration;
      debugPrint(
        'Audio duration: $duration, volume: $previewVolume, state: ${_audioPlayer.processingState}',
      );

      // Play the audio
      await _audioPlayer.play();
      debugPrint('Preview started playing');
    } catch (e, stackTrace) {
      debugPrint('Error previewing adhan: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Stop adhan playback
  Future<void> stopAdhan() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping adhan: $e');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
