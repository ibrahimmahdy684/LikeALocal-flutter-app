import 'package:url_launcher/url_launcher.dart';

class MapsLauncherService {
  Future<void> openDirections({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final name = label != null ? Uri.encodeComponent(label) : '';
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&destination_place_id=&travelmode=walking${name.isNotEmpty ? '&destination=$name' : ''}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not open Google Maps');
    }
  }
}
