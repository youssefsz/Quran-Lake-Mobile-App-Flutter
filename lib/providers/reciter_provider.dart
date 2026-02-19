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

  Future<void> fetchReciters({String language = 'ar'}) async {
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
