import 'package:flutter/material.dart';

import 'package:latlong2/latlong.dart';

import '../models/place.dart';
import '../services/firestore_service.dart';
import '../utils/geo_utils.dart';

class PlacesProvider with ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<Place> _places = [];
  List<Place> _nearbyPlaces = [];
  LatLng? _userLocation;
  List<Place> _savedPlacesList = [];
  List<Place> _contributedPlaces = [];
  List<String> _savedPlaceIds = [];
  bool _isLoading = false;
  String _selectedCategory = 'All';

  List<Place> get places => _places;
  List<Place> get nearbyPlaces => _nearbyPlaces;
  LatLng? get userLocation => _userLocation;
  List<Place> get savedPlaces => _savedPlacesList;
  List<Place> get contributedPlaces => _contributedPlaces;
  List<String> get savedPlaceIds => _savedPlaceIds;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;

  List<Place> get filteredPlaces {
    if (_selectedCategory == 'All') return _places;
    return _places.where((p) => p.category == _selectedCategory).toList();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> fetchNearbyPlaces(LatLng location, {String? cityName}) async {
    _userLocation = location;
    _isLoading = true;
    notifyListeners();

    try {
      List<Place> pool;
      if (cityName != null && cityName.isNotEmpty) {
        pool = await _firestore.fetchApprovedPlaces(cityName);
      } else {
        pool = await _firestore.fetchAllApprovedPlaces();
      }
      _nearbyPlaces = GeoUtils.sortByDistance(pool, location);
      _places = _nearbyPlaces;
    } catch (e) {
      debugPrint('PlacesProvider fetchNearbyPlaces: $e');
      _nearbyPlaces = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPlaces(String cityName) async {
    _isLoading = true;
    notifyListeners();

    try {
      _places = await _firestore.fetchApprovedPlaces(cityName);
    } catch (e) {
      debugPrint('PlacesProvider fetchPlaces: $e');
      _places = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllApprovedPlaces() async {
    _isLoading = true;
    notifyListeners();

    try {
      _places = await _firestore.fetchAllApprovedPlaces();
      _nearbyPlaces = [];
    } catch (e) {
      debugPrint('PlacesProvider fetchAllApprovedPlaces: $e');
      _places = [];
      _nearbyPlaces = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> addPlace(Place place) async {
    final id = await _firestore.addPlace(place);
    place.id = id;
    _contributedPlaces = [place, ..._contributedPlaces];
    notifyListeners();
    return id;
  }

  Future<void> toggleSavePlace(String placeId, String userId) async {
    Place? place;
    for (final p in [..._places, ..._savedPlacesList, ..._contributedPlaces]) {
      if (p.id == placeId) {
        place = p;
        break;
      }
    }

    if (_savedPlaceIds.contains(placeId)) {
      _savedPlaceIds.remove(placeId);
      _savedPlacesList.removeWhere((p) => p.id == placeId);
    } else {
      if (place == null) return;
      _savedPlaceIds.add(placeId);
      _savedPlacesList.add(place);
    }

    try {
      await _firestore.updateSavedPlaces(
        userId: userId,
        savedPlaceIds: _savedPlaceIds,
      );
    } catch (e) {
      debugPrint('PlacesProvider toggleSavePlace: $e');
      rethrow;
    }

    notifyListeners();
  }

  bool isPlaceSaved(String placeId) => _savedPlaceIds.contains(placeId);

  Future<void> loadUserData(String userId) async {
    try {
      _savedPlaceIds = await _firestore.getSavedPlaceIds(userId);
      _savedPlacesList = await _firestore.fetchPlacesByIds(_savedPlaceIds);
      _contributedPlaces = await _firestore.fetchPlacesByContributor(userId);
    } catch (e) {
      debugPrint('PlacesProvider loadUserData: $e');
    }
    notifyListeners();
  }

  Future<void> refreshContributedPlaces(String userId) async {
    try {
      _contributedPlaces = await _firestore.fetchPlacesByContributor(userId);
    } catch (e) {
      debugPrint('PlacesProvider refreshContributedPlaces: $e');
    }
    notifyListeners();
  }

  void clearUserData() {
    _savedPlaceIds = [];
    _savedPlacesList = [];
    _contributedPlaces = [];
    notifyListeners();
  }

  List<Place> getAllPlaces() =>
      _nearbyPlaces.isNotEmpty ? _nearbyPlaces : _places;

  List<Place> mapPlaces({required bool isPro}) {
    final all = getAllPlaces()
        .where((p) => p.latitude != null && p.longitude != null)
        .toList();
    if (isPro || all.length <= 10) return all;
    return all.take(10).toList();
  }
}
