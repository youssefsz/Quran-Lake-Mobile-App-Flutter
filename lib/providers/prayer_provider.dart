import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:quran_lake/data/models/prayer_time.dart';
import 'package:quran_lake/data/repositories/prayer_time_repository.dart';

class PrayerProvider extends ChangeNotifier {
  final PrayerTimeRepository _repository;

  PrayerTime? _prayerTime;
  PrayerTime? get prayerTime => _prayerTime;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Duration _timeUntilNextPrayer = Duration.zero;
  Duration get timeUntilNextPrayer => _timeUntilNextPrayer;

  String _nextPrayerName = '';
  String get nextPrayerName => _nextPrayerName;

  Timer? _timer;

  PrayerProvider(this._repository) {
    fetchPrayerTimes();
    _startTimer();
  }

  Future<void> fetchPrayerTimes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _prayerTime = await _repository.getPrayerTimes();
      _calculateNextPrayer();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _calculateNextPrayer();
    });
  }

  void _calculateNextPrayer() {
    if (_prayerTime == null) return;

    final now = DateTime.now();
    
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
      final fajr = parseTime(_prayerTime!.fajr);
      final dhuhr = parseTime(_prayerTime!.dhuhr);
      final asr = parseTime(_prayerTime!.asr);
      final maghrib = parseTime(_prayerTime!.maghrib);
      final isha = parseTime(_prayerTime!.isha);

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
        // Ideally we should fetch tomorrow's data but this is acceptable for now
        final tomorrowFajr = fajr.add(const Duration(days: 1));
        _timeUntilNextPrayer = tomorrowFajr.difference(now);
      }
      notifyListeners();
    } catch (e) {
      // Handle parsing errors gracefully
      print('Error parsing prayer times: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
