import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

class MapsLauncherService {
  Future<void> openDirections({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final name = label != null ? Uri.encodeComponent(label) : '';
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=walking${name.isNotEmpty ? '&destination=$name' : ''}',
    );
    // Use platformDefault on web (externalApplication doesn't work in browsers)
    final mode =
        kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication;
    if (!await launchUrl(uri, mode: mode)) {
      throw Exception('Could not open Google Maps');
    }
  }
}
