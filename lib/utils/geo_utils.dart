import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../models/place.dart';

class GeoUtils {
  static const _earthRadiusKm = 6371.0;

  static double distanceKm(LatLng a, LatLng b) {
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final lat1 = _deg2rad(a.latitude);
    final lat2 = _deg2rad(b.latitude);

    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * _earthRadiusKm * math.asin(math.sqrt(h));
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180);

  static List<Place> sortByDistance(
    List<Place> places,
    LatLng origin, {
    double maxKm = 25,
  }) {
    final withDistance = places
        .where((p) => p.latitude != null && p.longitude != null)
        .map((p) {
      final d = distanceKm(
        origin,
        LatLng(p.latitude!, p.longitude!),
      );
      return MapEntry(p, d);
    }).where((e) => e.value <= maxKm).toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return withDistance.map((e) => e.key).toList();
  }
}
