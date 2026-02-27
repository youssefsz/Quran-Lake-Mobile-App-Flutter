import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:quran_lake/core/errors/app_exception.dart';
import 'package:quran_lake/data/models/prayer_time.dart';
import 'package:quran_lake/data/repositories/prayer_time_repository.dart';

class PrayerProvider extends ChangeNotifier {
  final PrayerTimeRepository _repository;

  PrayerTime? _prayerTime;
  PrayerTime? get prayerTime => _prayerTime;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AppException? _error;
  AppException? get error => _error;

  /// Whether an error is present.
  bool get hasError => _error != null;

  /// The classified error type, or null.
  AppErrorType? get errorType => _error?.type;

  Duration _timeUntilNextPrayer = Duration.zero;
  Duration get timeUntilNextPrayer => _timeUntilNextPrayer;

  String _nextPrayerName = '';
  String get nextPrayerName => _nextPrayerName;

  Timer? _timer;

  // Cache for parsed prayer times to avoid re-parsing every second
  Map<String, DateTime>? _todayPrayerTimes;
  DateTime? _lastParsedDate;

  PrayerProvider(this._repository) {
    fetchPrayerTimes();
    _startTimer();
  }

  Future<void> fetchPrayerTimes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _prayerTime = await _repository.getPrayerTimes();
      _parsePrayerTimes();
      _calculateNextPrayer();
      // Note: Adhan scheduling will be handled by AdhanProvider
      // when it listens to prayer time changes
    } catch (e) {
      _error = AppException.from(e);
      debugPrint('PrayerProvider error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateNextPrayer();
    });
  }

  void _parsePrayerTimes() {
    if (_prayerTime == null) return;

    final now = DateTime.now();
    _lastParsedDate = DateTime(now.year, now.month, now.day);

    // Helper to parse time string "05:30 (BST)" -> DateTime
    DateTime parseTime(String timeStr) {
      // Remove timezone info like (BST), (EST) etc.
      final cleanTime = timeStr.replaceAll(RegExp(r'\s*\(.*\)'), '').trim();
      final timeParts = cleanTime.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      return DateTime(now.year, now.month, now.day, hour, minute);
    }

    try {
      _todayPrayerTimes = {
        'Fajr': parseTime(_prayerTime!.fajr),
        'Dhuhr': parseTime(_prayerTime!.dhuhr),
        'Asr': parseTime(_prayerTime!.asr),
        'Maghrib': parseTime(_prayerTime!.maghrib),
        'Isha': parseTime(_prayerTime!.isha),
      };
    } catch (e) {
      debugPrint('Error parsing prayer times: $e');
    }
  }

  void _calculateNextPrayer() {
    if (_prayerTime == null) return;

    final now = DateTime.now();

    // If date has changed, we need to re-parse (update the date part of the DateTimes)
    if (_lastParsedDate != null &&
        (_lastParsedDate!.year != now.year ||
            _lastParsedDate!.month != now.month ||
            _lastParsedDate!.day != now.day)) {
      _parsePrayerTimes();
    }

    if (_todayPrayerTimes == null) {
      _parsePrayerTimes();
      if (_todayPrayerTimes == null) return;
    }

    final fajr = _todayPrayerTimes!['Fajr']!;
    final dhuhr = _todayPrayerTimes!['Dhuhr']!;
    final asr = _todayPrayerTimes!['Asr']!;
    final maghrib = _todayPrayerTimes!['Maghrib']!;
    final isha = _todayPrayerTimes!['Isha']!;

    if (now.isBefore(fajr)) {
      _nextPrayerName = 'Fajr';
      _timeUntilNextPrayer = fajr.difference(now);
    } else if (now.isBefore(dhuhr)) {
      _nextPrayerName = 'Dhuhr';
      _timeUntilNextPrayer = dhuhr.difference(now);
    } else if (now.isBefore(asr)) {
      _nextPrayerName = 'Asr';
      _timeUntilNextPrayer = asr.difference(now);
    } else if (now.isBefore(maghrib)) {
      _nextPrayerName = 'Maghrib';
      _timeUntilNextPrayer = maghrib.difference(now);
    } else if (now.isBefore(isha)) {
      _nextPrayerName = 'Isha';
      _timeUntilNextPrayer = isha.difference(now);
    } else {
      // Next is Fajr tomorrow
      _nextPrayerName = 'Fajr';
      // Approximate tomorrow's Fajr as today's Fajr + 24h
      final tomorrowFajr = fajr.add(const Duration(days: 1));
      _timeUntilNextPrayer = tomorrowFajr.difference(now);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
