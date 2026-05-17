import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/place.dart';
import '../models/notification_item.dart';
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

  void startMonitoring({
    required String userId,
    required List<Place> places,
    required void Function(String title, String message) onNearbyPlace,
  }) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) async {
      await _checkNearby(
        userId: userId,
        places: places,
        onNearbyPlace: onNearbyPlace,
      );
    });
    _checkNearby(userId: userId, places: places, onNearbyPlace: onNearbyPlace);
  }

  Future<void> _checkNearby({
    required String userId,
    required List<Place> places,
    required void Function(String title, String message) onNearbyPlace,
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
      }
    }
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  void clearNotified() {
    _notifiedPlaceIds.clear();
  }
}
