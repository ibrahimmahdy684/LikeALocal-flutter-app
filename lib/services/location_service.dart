import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  /// Returns the best available position quickly.
  /// First tries last known (instant), then falls back to a fresh fix
  /// with a short timeout so the map doesn't block for too long.
  Future<LatLng?> getBestEffortPosition() async {
    // Try cached/last-known first — this is nearly instant
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return LatLng(lastKnown.latitude, lastKnown.longitude);
      }
    } catch (e) {
      debugPrint('LocationService: could not read last known position — $e');
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low, // faster fix
          timeLimit: Duration(seconds: 8),
        ),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Location timeout'),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      // Gracefully handle platforms where geolocation is unavailable
      debugPrint('LocationService: could not get position — $e');
      return null;
    }
  }
}
