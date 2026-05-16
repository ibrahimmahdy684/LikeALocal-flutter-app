import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/place.dart';

class PlacesProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Place> _places = [];
  List<Place> _savedPlacesList = [];
  List<String> _savedPlaceIds = [];
  bool _isLoading = false;
  String _selectedCategory = 'All';

  List<Place> get places => _places;
  List<Place> get savedPlaces => _savedPlacesList;
  List<String> get savedPlaceIds => _savedPlaceIds;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;

  // Get places filtered by category
  List<Place> get filteredPlaces {
    if (_selectedCategory == 'All') return _places;
    return _places.where((p) => p.category == _selectedCategory).toList();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Fetch places for a city from Firestore
  Future<void> fetchPlaces(String cityName) async {
    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('places')
          .where('cityName', isEqualTo: cityName)
          .where('isApproved', isEqualTo: true)
          .get();

      _places = snapshot.docs
          .map((doc) =>
              Place.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // If no places in Firestore yet, load sample data
      if (_places.isEmpty) {
        _places = _getSamplePlaces(cityName);
      }
    } catch (e) {
      debugPrint('Error fetching places: $e');
      // Fallback to sample data
      _places = _getSamplePlaces(cityName);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new place (contribution)
  Future<void> addPlace(Place place) async {
    try {
      DocumentReference ref =
          await _firestore.collection('places').add(place.toMap());
      place.id = ref.id;
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding place: $e');
      rethrow;
    }
  }

  // Save / unsave a place
  Future<void> toggleSavePlace(String placeId, String userId) async {
    if (_savedPlaceIds.contains(placeId)) {
      _savedPlaceIds.remove(placeId);
      _savedPlacesList.removeWhere((p) => p.id == placeId);
    } else {
      _savedPlaceIds.add(placeId);
      Place? place = _places.firstWhere(
        (p) => p.id == placeId,
        orElse: () => _getSamplePlaces('Paris').first,
      );
      _savedPlacesList.add(place);
    }

    // Persist to Firestore
    try {
      await _firestore.collection('users').doc(userId).update({
        'savedPlaceIds': _savedPlaceIds,
      });
    } catch (e) {
      debugPrint('Error saving place: $e');
    }

    notifyListeners();
  }

  bool isPlaceSaved(String placeId) {
    return _savedPlaceIds.contains(placeId);
  }

  // Load saved places for user
  Future<void> loadSavedPlaces(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        _savedPlaceIds = List<String>.from(data['savedPlaceIds'] ?? []);
      }
    } catch (e) {
      debugPrint('Error loading saved places: $e');
    }
    notifyListeners();
  }

  // Sample places data for offline/demo mode
  List<Place> _getSamplePlaces(String cityName) {
    return [
      Place(
        id: 'p1',
        title: 'Le Petit Cafe',
        description:
            'Hidden gem coffee shop with amazing pastries and local vibe',
        category: 'Cafe',
        price: 2,
        rating: 4.8,
        hiddenGemScore: 9.2,
        image:
            'https://images.unsplash.com/photo-1739723745132-97df9db49db2?w=1080',
        latitude: 48.8566,
        longitude: 2.3522,
        cityName: cityName,
        isApproved: true,
        contributorName: 'Emma',
      ),
      Place(
        id: 'p2',
        title: 'Secret Market',
        description: 'Authentic local market, open only on weekends',
        category: 'Market',
        price: 1,
        rating: 4.9,
        hiddenGemScore: 9.8,
        image:
            'https://images.unsplash.com/photo-1766650186677-947f1740a94d?w=1080',
        latitude: 48.8606,
        longitude: 2.3376,
        cityName: cityName,
        isApproved: true,
        contributorName: 'Lucas',
      ),
      Place(
        id: 'p3',
        title: 'Bistro Authentique',
        description: 'Family-run restaurant with traditional cuisine',
        category: 'Restaurant',
        price: 3,
        rating: 4.7,
        hiddenGemScore: 8.5,
        image:
            'https://images.unsplash.com/photo-1564758564211-cc16d061f020?w=1080',
        latitude: 48.8529,
        longitude: 2.3499,
        cityName: cityName,
        isApproved: true,
        contributorName: 'Sophie',
      ),
      Place(
        id: 'p4',
        title: 'Old Town Books',
        description:
            'Vintage bookstore with rare finds and cozy reading nooks',
        category: 'Shop',
        price: 2,
        rating: 4.6,
        hiddenGemScore: 9.0,
        image:
            'https://images.unsplash.com/photo-1771030669116-d25df9817eda?w=1080',
        latitude: 48.8600,
        longitude: 2.3450,
        cityName: cityName,
        isApproved: true,
        contributorName: 'Marco',
      ),
      Place(
        id: 'p5',
        title: 'Jazz Underground',
        description: 'Live jazz every night in a cozy basement venue',
        category: 'Nightlife',
        price: 2,
        rating: 4.5,
        hiddenGemScore: 8.8,
        image:
            'https://images.unsplash.com/photo-1564758564211-cc16d061f020?w=1080',
        latitude: 48.8550,
        longitude: 2.3480,
        cityName: cityName,
        isApproved: true,
        contributorName: 'Ava',
      ),
      Place(
        id: 'p6',
        title: 'Artisan Gallery',
        description: 'Local contemporary art from emerging artists',
        category: 'Art & Culture',
        price: 1,
        rating: 4.4,
        hiddenGemScore: 8.2,
        image:
            'https://images.unsplash.com/photo-1564758564211-cc16d061f020?w=1080',
        latitude: 48.8580,
        longitude: 2.3510,
        cityName: cityName,
        isApproved: true,
        contributorName: 'Emma',
      ),
    ];
  }

  // Get all places (for map)
  List<Place> getAllPlaces() {
    if (_places.isEmpty) {
      return _getSamplePlaces('Paris');
    }
    return _places;
  }
}
