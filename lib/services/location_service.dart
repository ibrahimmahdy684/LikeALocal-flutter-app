import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  LatLng? _cachedPosition;

  /// Returns the best available position quickly.
  /// Uses in-memory cache first, then platform-appropriate methods.
  Future<LatLng?> getBestEffortPosition() async {
    // Return cached position immediately if available
    if (_cachedPosition != null) return _cachedPosition;

    // On web, getLastKnownPosition is not supported — skip it
    if (!kIsWeb) {
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          _cachedPosition = LatLng(lastKnown.latitude, lastKnown.longitude);
          return _cachedPosition;
        }
      } catch (e) {
        debugPrint('LocationService: last known position unavailable — $e');
      }
    }

    return getCurrentPosition();
  }

  Future<LatLng?> getCurrentPosition() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: kIsWeb ? LocationAccuracy.medium : LocationAccuracy.low,
          timeLimit: const Duration(seconds: 10),
        ),
      ).timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw Exception('Location timeout'),
      );

      _cachedPosition = LatLng(position.latitude, position.longitude);
      return _cachedPosition;
    } catch (e) {
      debugPrint('LocationService: could not get position — $e');
      return null;
    }
  }

  /// Returns cached position without making any async calls.
  LatLng? get lastKnown => _cachedPosition;
}
