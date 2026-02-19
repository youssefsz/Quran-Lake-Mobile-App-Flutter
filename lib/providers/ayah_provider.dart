import 'package:flutter/foundation.dart';
import '../data/models/ayah.dart';
import '../data/repositories/ayah_repository.dart';

class AyahProvider with ChangeNotifier {
  final AyahRepository _repository;
  
  Ayah? _ayah;
  bool _isLoading = false;
  String? _errorMessage;

  AyahProvider(this._repository) {
    fetchRandomAyah();
  }

  Ayah? get ayah => _ayah;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchRandomAyah() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _ayah = await _repository.getRandomAyah();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
