import 'package:flutter/foundation.dart';
import '../core/errors/app_exception.dart';
import '../data/models/surah.dart';
import '../data/repositories/surah_repository.dart';

class SurahProvider with ChangeNotifier {
  final SurahRepository _repository;

  List<Surah> _surahs = [];
  bool _isLoading = false;
  AppException? _error;
  String? _currentLanguage;

  SurahProvider(this._repository);

  List<Surah> get surahs => _surahs;
  bool get isLoading => _isLoading;
  AppException? get error => _error;

  /// Whether an error is present.
  bool get hasError => _error != null;

  /// The classified error type, or null.
  AppErrorType? get errorType => _error?.type;

  Future<void> fetchSurahs({String language = 'ar'}) async {
    if (_currentLanguage == language && _surahs.isNotEmpty) {
      return;
    }

    _currentLanguage = language;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _surahs = await _repository.getSurahs(language: language);
    } catch (e) {
      _error = AppException.from(e);
      debugPrint('SurahProvider error: $_error');
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
