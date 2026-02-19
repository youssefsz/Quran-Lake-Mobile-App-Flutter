import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/localization/localization_service.dart';

class LocaleProvider extends ChangeNotifier {
  final LocalizationService _localizationService = LocalizationService();
  static const String _prefsKey = 'selected_locale';

  Locale get locale => _localizationService.currentLocale;

  LocaleProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString(_prefsKey);
    
    if (languageCode != null) {
      _localizationService.loadLocale(Locale(languageCode));
    } else {
      _localizationService.loadLocale(LocalizationService.getSystemLocale());
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode == _localizationService.currentLocale.languageCode) return;
    
    _localizationService.loadLocale(locale);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
    
    notifyListeners();
  }

  Future<Map<String, dynamic>> getScreenTranslations(String screenName) {
    return _localizationService.getScreenTranslations(screenName);
  }

  Map<String, dynamic> getCachedTranslations(String screenName) {
    return _localizationService.getCachedTranslations(screenName);
  }
}
