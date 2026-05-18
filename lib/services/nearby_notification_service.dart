import 'dart:async';
import 'package:latlong2/latlong.dart';

import '../models/place.dart';
import '../services/cache_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../utils/geo_utils.dart';

class NearbyNotificationService {
  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();
  final CacheService _cache = CacheService.instance;
  Timer? _timer;
  final Set<String> _notifiedPlaceIds = {};

  static const double _hiddenGemRadiusKm = 10.0;
  static const double _hiddenGemMinScore = 3.0;

  void startMonitoring({
    required String userId,
    required List<Place> places,
    required void Function(String title, String message) onNearbyPlace,
    List<String> preferredCategories = const [],
    int budgetLevel = 2,
  }) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) async {
      await _checkNearby(
        userId: userId,
        places: places,
        onNearbyPlace: onNearbyPlace,
        preferredCategories: preferredCategories,
        budgetLevel: budgetLevel,
      );
    });
    _checkNearby(
      userId: userId,
      places: places,
      onNearbyPlace: onNearbyPlace,
      preferredCategories: preferredCategories,
      budgetLevel: budgetLevel,
    );
  }

  Future<void> _checkNearby({
    required String userId,
    required List<Place> places,
    required void Function(String title, String message) onNearbyPlace,
    required List<String> preferredCategories,
    required int budgetLevel,
  }) async {
    final enabled = await _cache.getNearbyNotificationsEnabled();
    if (!enabled) return;

    final position = await _locationService.getCurrentPosition();
    if (position == null) return;

    final radiusKm = await _cache.getNearbyRadius();

    for (final place in places) {
      if (place.latitude == null || place.longitude == null) continue;
      if (_notifiedPlaceIds.contains(place.id)) continue;

      final distance = GeoUtils.distanceKm(
        position,
        LatLng(place.latitude!, place.longitude!),
      );

      // Standard nearby notification
      if (distance <= radiusKm) {
        _notifiedPlaceIds.add(place.id);
        onNearbyPlace(
          'You\'re near ${place.title}!',
          '${place.title} in ${place.cityName} is just ${(distance * 1000).round()}m away. Check it out!',
        );

        await _firestoreService.createNearbyNotification(
          userId: userId,
          placeName: place.title,
          distance: distance,
        );
        continue;
      }

      // Hidden gem notification within 10km that matches preferences
      if (distance <= _hiddenGemRadiusKm &&
          place.hiddenGemScore >= _hiddenGemMinScore &&
          _matchesPreferences(place, preferredCategories, budgetLevel)) {
        _notifiedPlaceIds.add(place.id);

        final distanceStr = distance >= 1
            ? '${distance.toStringAsFixed(1)}km'
            : '${(distance * 1000).round()}m';

        onNearbyPlace(
          'Hidden gem nearby: ${place.title}!',
          '${place.title} (${place.category}) is a hidden gem $distanceStr away — matches your preferences!',
        );

        await _firestoreService.createHiddenGemNotification(
          userId: userId,
          placeName: place.title,
          category: place.category,
          distance: distance,
          gemScore: place.hiddenGemScore,
        );
      }
    }
  }

  bool _matchesPreferences(
    Place place,
    List<String> preferredCategories,
    int budgetLevel,
  ) {
    if (place.price > budgetLevel) return false;
    if (preferredCategories.isEmpty) return true;
    return preferredCategories.contains(place.category);
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  void clearNotified() {
    _notifiedPlaceIds.clear();
  }
}
