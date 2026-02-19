import 'package:flutter/foundation.dart';
import '../data/models/surah.dart';
import '../data/repositories/surah_repository.dart';

class SurahProvider with ChangeNotifier {
  final SurahRepository _repository;
  
  List<Surah> _surahs = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentLanguage;

  SurahProvider(this._repository);

  List<Surah> get surahs => _surahs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSurahs({String language = 'ar'}) async {
    if (_currentLanguage == language && _surahs.isNotEmpty) {
      return;
    }

    _currentLanguage = language;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _surahs = await _repository.getSurahs(language: language);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Surah? getSurahById(int id) {
    try {
      return _surahs.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }
}
