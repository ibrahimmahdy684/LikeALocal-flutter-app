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

  static const double _recommendRadiusKm = 10.0;

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

    for (final place in places) {
      if (place.latitude == null || place.longitude == null) continue;
      if (_notifiedPlaceIds.contains(place.id)) continue;

      final distance = GeoUtils.distanceKm(
        position,
        LatLng(place.latitude!, place.longitude!),
      );

      // Recommend places within 10km that match user preferences
      if (distance <= _recommendRadiusKm &&
          _matchesPreferences(place, preferredCategories, budgetLevel)) {
        _notifiedPlaceIds.add(place.id);

        final distanceStr = distance >= 1
            ? '${distance.toStringAsFixed(1)}km'
            : '${(distance * 1000).round()}m';

        onNearbyPlace(
          'Recommended: ${place.title}',
          '${place.title} (${place.category}) is $distanceStr away and matches your preferences!',
        );

        await _firestoreService.createNearbyNotification(
          userId: userId,
          placeName: place.title,
          distance: distance,
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
