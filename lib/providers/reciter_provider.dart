import 'package:flutter/foundation.dart';
import '../data/models/reciter.dart';
import '../data/repositories/reciters_repository.dart';

class ReciterProvider with ChangeNotifier {
  final RecitersRepository _repository;
  
  List<Reciter> _reciters = [];
  List<Reciter> _filteredReciters = [];
  bool _isLoading = false;
  String? _errorMessage;

  ReciterProvider(this._repository);

  List<Reciter> get reciters => _filteredReciters.isNotEmpty || _searchQuery.isNotEmpty 
      ? _filteredReciters 
      : _reciters;
      
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  String _searchQuery = '';
  String? _currentLanguage;

  Future<void> fetchReciters({String language = 'ar'}) async {
    if (_currentLanguage == language && _reciters.isNotEmpty) {
      _filterReciters();
      return;
    }

    _currentLanguage = language;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reciters = await _repository.getReciters(language: language);
      _filterReciters();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _searchQuery = query;
    _filterReciters();
    notifyListeners();
  }

  Reciter? getReciterById(int id) {
    try {
      return _reciters.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  void _filterReciters() {
    if (_searchQuery.isEmpty) {
      _filteredReciters = [];
    } else {
      _filteredReciters = _reciters.where((reciter) {
        return reciter.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               reciter.letter.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }
}
