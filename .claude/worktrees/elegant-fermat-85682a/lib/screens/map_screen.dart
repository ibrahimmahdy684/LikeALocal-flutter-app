import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../models/place.dart';
import '../providers/places_provider.dart';

class MapScreen extends StatefulWidget {
  final String? cityName;
  final double? lat;
  final double? lng;
  const MapScreen({Key? key, this.cityName, this.lat, this.lng}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  Place? _selectedPlace;
  String _filterCategory = 'All';

  final List<String> _categories = [
    'All', 'Cafe', 'Restaurant', 'Market', 'Museum', 'Bar', 'Park'
  ];

  @override
  void initState() {
    super.initState();
    // Load places if not already loaded
    Future.microtask(() {
      final provider = Provider.of<PlacesProvider>(context, listen: false);
      if (provider.places.isEmpty) {
        provider.fetchPlaces('Paris');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PlacesProvider>(
        builder: (context, placesProvider, child) {
          final allPlaces = placesProvider.getAllPlaces();
          final places = _filterCategory == 'All'
              ? allPlaces
              : allPlaces.where((p) => p.category == _filterCategory).toList();

          return Stack(
            children: [
              // Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(widget.lat ?? 48.8566, widget.lng ?? 2.3522),
                  initialZoom: 13,
                  onTap: (tapPosition, latlng) {
                    setState(() => _selectedPlace = null);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.likealocal.app',
                  ),
                  MarkerLayer(
                    markers: places
                        .where((p) =>
                            p.latitude != null && p.longitude != null)
                        .map((place) {
                      bool isSelected = _selectedPlace?.id == place.id;
                      return Marker(
                        point:
                            LatLng(place.latitude!, place.longitude!),
                        width: isSelected ? 48 : 40,
                        height: isSelected ? 48 : 40,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedPlace = place);
                            _mapController.move(
                              LatLng(place.latitude!, place.longitude!),
                              14,
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: isSelected ? 28 : 24,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // Top Controls
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Back button (only when pushed from city detail)
                      if (widget.cityName != null) ...[
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(Icons.arrow_back, color: AppColors.primary, size: 20),
                          ),
                        ),
                        SizedBox(width: 12),
                      ],
                      // Filters button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showFilterSheet(context),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.tune,
                                    color: AppColors.primary, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  _filterCategory == 'All' ? 'Filters' : _filterCategory,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.foreground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      // Navigation button
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(Icons.navigation,
                            color: AppColors.primary, size: 20),
                      ),
                    ],
                  ),
                ),
              ),

              // Draggable Bottom Sheet
              DraggableScrollableSheet(
                initialChildSize: 0.35,
                minChildSize: 0.15,
                maxChildSize: 0.75,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 24,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Drag Handle
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 12),
                          width: 48,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        // Header
                        Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Nearby Places',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.foreground,
                              ),
                            ),
                          ),
                        ),
                        // Places list
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            padding: EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: places.length,
                            itemBuilder: (context, index) {
                              return _buildMapPlaceCard(places[index]);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter by Category',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  bool isSelected = _filterCategory == cat;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _filterCategory = cat);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.foreground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapPlaceCard(Place place) {
    bool isSelected = _selectedPlace?.id == place.id;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPlace = place);
        if (place.latitude != null && place.longitude != null) {
          _mapController.move(
            LatLng(place.latitude!, place.longitude!),
            14,
          );
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.05)
              : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: place.image,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (ctx, url) =>
                    Container(width: 80, height: 80, color: AppColors.secondary),
                errorWidget: (ctx, url, err) => Container(
                  width: 80,
                  height: 80,
                  color: AppColors.secondary,
                  child: Icon(Icons.image),
                ),
              ),
            ),
            SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      place.category,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star,
                          size: 12, color: AppColors.accent),
                      SizedBox(width: 4),
                      Text(
                        place.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 12),
                      Row(
                        children: List.generate(3, (i) {
                          return Icon(
                            Icons.attach_money,
                            size: 12,
                            color: i < place.price
                                ? AppColors.primary
                                : AppColors.muted.withOpacity(0.3),
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
