import 'package:flutter/foundation.dart';
import '../data/services/adhan_service.dart';
import '../data/services/background_service.dart';
import '../data/services/foreground_service.dart';
import '../data/models/prayer_time.dart';

/// Provider for managing adhan (call to prayer) settings and scheduling
class AdhanProvider extends ChangeNotifier {
  final AdhanService _adhanService;

  AdhanProvider(this._adhanService);

  // ===========================================================================
  // Getters
  // ===========================================================================

  bool get isEnabled => _adhanService.isEnabled;
  bool get isFajrEnabled => _adhanService.isFajrEnabled;
  bool get isSunriseEnabled => _adhanService.isSunriseEnabled;
  bool get isDhuhrEnabled => _adhanService.isDhuhrEnabled;
  bool get isAsrEnabled => _adhanService.isAsrEnabled;
  bool get isMaghribEnabled => _adhanService.isMaghribEnabled;
  bool get isIshaEnabled => _adhanService.isIshaEnabled;
  bool get isCountdownEnabled => _adhanService.isCountdownEnabled;
  double get volume => _adhanService.volume;
  String get sound => _adhanService.sound;
  Future<List<Map<String, String>>> get availableAdhans =>
      _adhanService.getAvailableAdhans();

  // ===========================================================================
  // Settings Methods
  // ===========================================================================

  Future<void> setEnabled(bool enabled) async {
    await _adhanService.setEnabled(enabled);

    // Register or cancel background task based on adhan state
    if (enabled) {
      await BackgroundService.registerDailyTask();
      // Start foreground service to keep running even after app is killed
      await ForegroundService.start();
    } else {
      await BackgroundService.cancelTask();
      // Stop foreground service when adhan is disabled
      await ForegroundService.stop();
    }

    notifyListeners();
  }

  Future<void> setFajrEnabled(bool enabled) async {
    await _adhanService.setFajrEnabled(enabled);
    notifyListeners();
  }

  Future<void> setSunriseEnabled(bool enabled) async {
    await _adhanService.setSunriseEnabled(enabled);
    notifyListeners();
  }

  Future<void> setDhuhrEnabled(bool enabled) async {
    await _adhanService.setDhuhrEnabled(enabled);
    notifyListeners();
  }

  Future<void> setAsrEnabled(bool enabled) async {
    await _adhanService.setAsrEnabled(enabled);
    notifyListeners();
  }

  Future<void> setMaghribEnabled(bool enabled) async {
    await _adhanService.setMaghribEnabled(enabled);
    notifyListeners();
  }

  Future<void> setIshaEnabled(bool enabled) async {
    await _adhanService.setIshaEnabled(enabled);
    notifyListeners();
  }

  Future<void> setVolume(double volume) async {
    await _adhanService.setVolume(volume);
    notifyListeners();
  }

  Future<void> setSound(String sound) async {
    await _adhanService.setSound(sound);
    notifyListeners();
  }

  Future<void> setCountdownEnabled(bool enabled) async {
    await _adhanService.setCountdownEnabled(enabled);
    notifyListeners();
    // Reschedule alarms if countdown setting changed
    if (isEnabled) {
      // This will be handled by the caller when they reschedule
    }
  }

  // ===========================================================================
  // Alarm Scheduling
  // ===========================================================================

  /// Schedule adhan alarms based on prayer times
  Future<void> scheduleAdhanAlarms(PrayerTime prayerTime) async {
    await _adhanService.scheduleAdhanAlarms(prayerTime);

    // Ensure background task is registered when scheduling alarms
    if (isEnabled) {
      await BackgroundService.registerDailyTask();
      // Ensure foreground service is running
      await ForegroundService.start();
    }

    notifyListeners();
  }

  /// Check and show countdown notification on app open if prayer is within 0-120 minutes
  Future<void> checkAndShowCountdownOnAppOpen(PrayerTime prayerTime) async {
    await _adhanService.checkAndShowCountdownOnAppOpen(prayerTime);
  }

  /// Cancel all adhan alarms
  Future<void> cancelAllAlarms() async {
    await _adhanService.cancelAllAlarms();
    // Stop foreground service when all alarms are cancelled
    await ForegroundService.stop();
    notifyListeners();
  }

  // ===========================================================================
  // Manual Playback (for testing)
  // ===========================================================================

  Future<void> playAdhan() async {
    await _adhanService.playAdhan();
  }

  Future<void> stopAdhan() async {
    await _adhanService.stopAdhan();
  }

  /// Preview a specific adhan voice by ID
  Future<void> previewAdhan(String adhanId) async {
    await _adhanService.previewAdhan(adhanId);
  }
}
