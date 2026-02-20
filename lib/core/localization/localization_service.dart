import 'dart:convert';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();

  factory LocalizationService() {
    return _instance;
  }

  LocalizationService._internal();

  // Cache: Map<ScreenName, Map<Key, Value>>
  final Map<String, Map<String, dynamic>> _localizedStrings = {};

  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;

  Map<String, dynamic> getCachedTranslations(String screenName) {
    return _localizedStrings[screenName] ?? {};
  }

  void loadLocale(Locale locale) {
    _currentLocale = locale;
    // Clear cache when language changes so we reload the correct strings
    _localizedStrings.clear();
  }

  /// Helper to detect system locale
  static Locale getSystemLocale() {
    final systemLocale = PlatformDispatcher.instance.locale;
    final supportedLocales = ['en', 'ar'];

    if (supportedLocales.contains(systemLocale.languageCode)) {
      return Locale(systemLocale.languageCode);
    }
    return const Locale('en');
  }

  /// Fetches translations for a specific screen.
  ///
  /// 1. Checks cache.
  /// 2. If missing, loads from assets (lib/l10n/{lang}/{screen}.json).
  /// 3. Caches and returns.
  /// 4. Falls back to 'en' if file missing.
  Future<Map<String, dynamic>> getScreenTranslations(String screenName) async {
    // 1. Check cache
    if (_localizedStrings.containsKey(screenName)) {
      return _localizedStrings[screenName]!;
    }

    try {
      final String languageCode = _currentLocale.languageCode;
      // 2. Load from assets
      // Note: We use the key as 'lib/l10n/...' because that's how it's defined in pubspec.
      // However, rootBundle.loadString might require just the path.
      final String jsonString = await rootBundle.loadString(
        'lib/l10n/$languageCode/$screenName.json',
      );

      // 3. Decode and cache
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings[screenName] = jsonMap;

      return jsonMap;
    } catch (e) {
      // 4. Fallback to 'en' if current language fails and it's not already 'en'
      if (_currentLocale.languageCode != 'en') {
        try {
          final String fallbackString = await rootBundle.loadString(
            'lib/l10n/en/$screenName.json',
          );
          final Map<String, dynamic> fallbackMap = json.decode(fallbackString);
          _localizedStrings[screenName] = fallbackMap;
          return fallbackMap;
        } catch (fallbackError) {
          debugPrint(
            'Localization Error: Could not load $screenName.json for $_currentLocale or fallback.',
          );
          return {};
        }
      }
      debugPrint(
        'Localization Error: Could not load $screenName.json for $_currentLocale',
      );
      return {};
    }
  }
}
