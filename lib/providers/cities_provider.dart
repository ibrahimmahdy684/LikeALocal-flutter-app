import 'package:flutter/material.dart';

import '../models/city.dart';
import '../services/firestore_service.dart';

class CitiesProvider with ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<City> _cities = [];
  bool _isLoading = false;
  String? _error;

  List<City> get cities => _cities.isEmpty ? City.sampleCities : _cities;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get usingFallback => _cities.isEmpty;

  Future<void> fetchCities() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _firestore.fetchCities();
      _cities = result.isEmpty ? City.sampleCities : result;
    } catch (e) {
      debugPrint('CitiesProvider fetchCities: $e');
      _error = e.toString();
      _cities = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  City? cityByName(String name) {
    try {
      return cities.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }
}
