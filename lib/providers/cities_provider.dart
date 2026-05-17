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
      return _cities.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCity(City city) async {
    // Normalize city name: capitalize first letter of each word
    city.name = _normalizeCityName(city.name);
    await _firestore.setCity(city);
    final index = _cities.indexWhere(
      (c) => c.name.toLowerCase() == city.name.toLowerCase(),
    );
    if (index == -1) {
      _cities = [..._cities, city];
    } else {
      _cities[index] = city;
    }
    notifyListeners();
  }

  Future<void> incrementCityPlaceCount(String cityName) async {
    final normalized = _normalizeCityName(cityName);
    await _firestore.incrementCityPlaceCount(normalized);
    final index = _cities.indexWhere(
      (c) => c.name.toLowerCase() == normalized.toLowerCase(),
    );
    if (index != -1) {
      _cities[index].placeCount += 1;
      notifyListeners();
    }
  }

  /// Normalize city name: "cairo" -> "Cairo", "new york" -> "New York"
  String _normalizeCityName(String name) {
    return name.trim().split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
