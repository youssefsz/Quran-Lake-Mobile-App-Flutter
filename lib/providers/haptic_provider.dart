import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HapticProvider extends ChangeNotifier {
  static const String _prefsKey = 'haptic_enabled';
  bool _isEnabled = true;

  bool get isEnabled => _isEnabled;

  HapticProvider() {
    _loadSavedPreference();
  }

  Future<void> _loadSavedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_prefsKey) ?? true;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (_isEnabled == value) return;
    _isEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }

  Future<void> lightImpact() async {
    if (!_isEnabled) return;
    await HapticFeedback.lightImpact();
  }
}
