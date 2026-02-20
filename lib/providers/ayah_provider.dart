import 'package:flutter/foundation.dart';
import '../core/errors/app_exception.dart';
import '../data/models/ayah.dart';
import '../data/repositories/ayah_repository.dart';

class AyahProvider with ChangeNotifier {
  final AyahRepository _repository;

  Ayah? _ayah;
  bool _isLoading = false;
  AppException? _error;

  AyahProvider(this._repository) {
    fetchRandomAyah();
  }

  Ayah? get ayah => _ayah;
  bool get isLoading => _isLoading;
  AppException? get error => _error;

  /// Whether an error is present.
  bool get hasError => _error != null;

  /// The classified error type, or null.
  AppErrorType? get errorType => _error?.type;

  Future<void> fetchRandomAyah() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _ayah = await _repository.getRandomAyah();
    } catch (e) {
      _error = AppException.from(e);
      debugPrint('AyahProvider error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
