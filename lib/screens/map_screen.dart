import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config/app_config.dart';
import '../models/place.dart';
import '../providers/auth_provider.dart';
import '../providers/places_provider.dart';
import '../services/location_service.dart';
import '../services/maps_launcher_service.dart';
import '../theme/app_colors.dart';
import '../widgets/place_image.dart';
import '../widgets/save_place_button.dart';
import '../widgets/upgrade_pro_dialog.dart';
import 'place_detail_screen.dart';

class MapScreen extends StatefulWidget {
  final String? cityName;
  final double? lat;
  final double? lng;
  const MapScreen({super.key, this.cityName, this.lat, this.lng});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final MapsLauncherService _mapsLauncher = MapsLauncherService();
  Place? _selectedPlace;
  bool _locating = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final places = context.read<PlacesProvider>();

    // If opened from a city page with explicit coordinates, use those
    if (widget.lat != null && widget.lng != null) {
      final cityCenter = LatLng(widget.lat!, widget.lng!);
      await places.fetchNearbyPlaces(cityCenter, cityName: widget.cityName);
      if (mounted) {
        _mapController.move(cityCenter, 14);
        setState(() {
          _locating = false;
          _locationError = null;
        });
      }
      return;
    }

    await places.fetchAllApprovedPlaces();
    if (!mounted) return;

    setState(() {
      _locating = false;
      _locationError = null;
    });

    unawaited(_resolveDeviceLocation(places));
  }

  Future<void> _resolveDeviceLocation(PlacesProvider places) async {
    final position = await _locationService.getBestEffortPosition();

    if (!mounted) return;

    if (position != null) {
      await places.fetchNearbyPlaces(position);
      _mapController.move(position, 14);
      setState(() {
        _locationError = null;
      });
    } else {
      setState(() {
        _locationError = 'Location unavailable — showing all places';
      });
    }
  }

  void _onMarkerTap(Place place, bool isPro, int totalWithCoords) {
    setState(() => _selectedPlace = place);
    if (place.latitude != null && place.longitude != null) {
      _mapController.move(LatLng(place.latitude!, place.longitude!), 15);
    }
  }

  Future<void> _pinPlace(Place place) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    try {
      await auth.togglePinPlace(place.id, isPro: auth.currentUser!.isPro);
      setState(() {});
      if (mounted) {
        final pinned = auth.isPlacePinned(place.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pinned ? '${place.title} pinned!' : 'Pin removed')),
        );
      }
    } on FreemiumLimitException {
      if (mounted) showUpgradeProDialog(context);
    }
  }

  Future<void> _centerOnUser() async {
    final places = context.read<PlacesProvider>();
    final position = await _locationService.getBestEffortPosition();
    if (position != null) {
      await places.fetchNearbyPlaces(position);
      _mapController.move(position, 14);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<PlacesProvider, AuthProvider>(
        builder: (context, placesProvider, auth, _) {
          final isPro = auth.currentUser?.isPro ?? false;
          final allWithCoords = placesProvider
              .getAllPlaces()
              .where((p) => p.latitude != null && p.longitude != null)
              .toList();
          final baseMapPlaces = placesProvider.mapPlaces(isPro: isPro);

          // Always include pinned places on the map (even if not in nearby)
          final pinnedIds = auth.currentUser?.pinnedPlaceIds ?? [];
          final pinnedPlaces = placesProvider.savedPlaces
              .where((p) => pinnedIds.contains(p.id) && p.latitude != null && p.longitude != null)
              .toList();
          final mapPlaceIds = baseMapPlaces.map((p) => p.id).toSet();
          final mapPlaces = [
            ...baseMapPlaces,
            ...pinnedPlaces.where((p) => !mapPlaceIds.contains(p.id)),
          ];

          final center = placesProvider.userLocation ??
              const LatLng(30.0444, 31.2357);

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 13,
                  onTap: (_, __) => setState(() => _selectedPlace = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.likealocal.app',
                  ),
                  if (placesProvider.userLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: placesProvider.userLocation!,
                          width: 36,
                          height: 36,
                          child: const Icon(Icons.my_location,
                              color: Colors.blue, size: 32),
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: mapPlaces.map((place) {
                      final selected = _selectedPlace?.id == place.id;
                      final pinned = auth.isPlacePinned(place.id);
                      return Marker(
                        point: LatLng(place.latitude!, place.longitude!),
                        width: selected ? 48 : 40,
                        height: selected ? 48 : 40,
                        child: GestureDetector(
                          onTap: () => _onMarkerTap(
                              place, isPro, allWithCoords.length),
                          child: Container(
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.accent
                                  : pinned
                                      ? Colors.orange
                                      : AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              pinned ? Icons.push_pin : Icons.location_on,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            _locating
                                ? 'Finding nearby places...'
                                : _locationError ??
                                    '${mapPlaces.length} pins nearby'
                                        '${!isPro && allWithCoords.length > AppConfig.freeMapPinLimit ? ' (free max ${AppConfig.freeMapPinLimit})' : ''}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _iconButton(Icons.my_location, _centerOnUser),
                      if (!isPro)
                        _iconButton(
                          Icons.workspace_premium,
                          () => showUpgradeProDialog(context),
                        ),
                    ],
                  ),
                ),
              ),

              if (_selectedPlace != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _PlaceMapPopup(
                    place: _selectedPlace!,
                    isPinned: auth.isPlacePinned(_selectedPlace!.id),
                    onClose: () => setState(() => _selectedPlace = null),
                    onPin: () => _pinPlace(_selectedPlace!),
                    onDirections: () => _mapsLauncher.openDirections(
                      latitude: _selectedPlace!.latitude!,
                      longitude: _selectedPlace!.longitude!,
                      label: _selectedPlace!.title,
                    ),
                    onDetails: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PlaceDetailScreen(place: _selectedPlace!),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _PlaceMapPopup extends StatelessWidget {
  final Place place;
  final bool isPinned;
  final VoidCallback onClose;
  final VoidCallback onPin;
  final VoidCallback onDirections;
  final VoidCallback onDetails;

  const _PlaceMapPopup({
    required this.place,
    this.isPinned = false,
    required this.onClose,
    required this.onPin,
    required this.onDirections,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  place.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          if (place.image.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: PlaceImage(
                imageUrl: place.image,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 8),
          Text(place.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              SavePlaceButton(placeId: place.id),
              IconButton(
                onPressed: onPin,
                icon: Icon(
                  isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: isPinned ? AppColors.accent : AppColors.muted,
                ),
                tooltip: isPinned ? 'Unpin' : 'Pin location',
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onDirections,
                icon: const Icon(Icons.directions),
                label: const Text('Directions'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Details',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
