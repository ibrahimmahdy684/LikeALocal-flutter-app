import 'package:flutter/material.dart';

import '../models/city.dart';
import '../services/firestore_service.dart';

class CitiesProvider with ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<City> _cities = [];
  bool _isLoading = false;
  String? _error;

  List<City> get cities => _cities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCities() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cities = await _firestore.fetchCities();
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
      return _cities.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCity(City city) async {
    await _firestore.setCity(city);
    final index = _cities.indexWhere((c) => c.name == city.name);
    if (index == -1) {
      _cities = [..._cities, city];
    } else {
      _cities[index] = city;
    }
    notifyListeners();
  }

  Future<void> incrementCityPlaceCount(String cityName) async {
    await _firestore.incrementCityPlaceCount(cityName);
    final index = _cities.indexWhere((c) => c.name == cityName);
    if (index != -1) {
      _cities[index].placeCount += 1;
      notifyListeners();
    }
  }
}
