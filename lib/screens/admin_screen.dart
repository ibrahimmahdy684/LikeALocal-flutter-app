import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/place.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestore = FirestoreService();

  List<AppUser> _pendingGuides = [];
  List<Place> _pendingPlaces = [];
  List<Place> _allPlaces = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _firestore.fetchPendingLocalGuides(),
        _firestore.fetchPendingPlaces(),
        _firestore.fetchAllPlaces(),
      ]);
      _pendingGuides = results[0] as List<AppUser>;
      _pendingPlaces = results[1] as List<Place>;
      _allPlaces = results[2] as List<Place>;
    } catch (e) {
      debugPrint('Admin load error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _approveGuide(AppUser guide) async {
    try {
      await _firestore.approveLocalGuide(guide.id);
      setState(() => _pendingGuides.removeWhere((g) => g.id == guide.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${guide.name} approved as local guide'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.destructive),
        );
      }
    }
  }

  Future<void> _approvePlace(Place place) async {
    try {
      await _firestore.approvePlace(place.id);
      await _firestore.createApprovalNotification(
        userId: place.contributorId,
        placeName: place.title,
      );
      setState(() {
        _pendingPlaces.removeWhere((p) => p.id == place.id);
        final idx = _allPlaces.indexWhere((p) => p.id == place.id);
        if (idx >= 0) _allPlaces[idx].isApproved = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\"${place.title}\" approved'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.destructive),
        );
      }
    }
  }

  Future<void> _deletePlace(Place place) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Place'),
        content: Text('Are you sure you want to delete \"${place.title}\"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _firestore.deletePlace(place.id);
      setState(() {
        _allPlaces.removeWhere((p) => p.id == place.id);
        _pendingPlaces.removeWhere((p) => p.id == place.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\"${place.title}\" deleted'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.destructive),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Guides (${_pendingGuides.length})'),
            Tab(text: 'Places (${_pendingPlaces.length})'),
            const Tab(text: 'Map'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPendingGuidesTab(),
                _buildPendingPlacesTab(),
                _buildAllPlacesMapTab(),
              ],
            ),
    );
  }

  // ── Tab 1: Pending Guides ──

  Widget _buildPendingGuidesTab() {
    if (_pendingGuides.isEmpty) {
      return _emptyState(Icons.verified_user, 'No pending guides',
          'All local guide accounts have been reviewed.');
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingGuides.length,
        itemBuilder: (context, index) {
          final guide = _pendingGuides[index];
          final initials = guide.name
              .trim()
              .split(' ')
              .map((w) => w.isNotEmpty ? w[0] : '')
              .take(2)
              .join()
              .toUpperCase();
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Text(initials,
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
              ),
              title: Text(guide.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(guide.email),
              trailing: ElevatedButton(
                onPressed: () => _approveGuide(guide),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Approve'),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Tab 2: Pending Places ──

  Widget _buildPendingPlacesTab() {
    if (_pendingPlaces.isEmpty) {
      return _emptyState(Icons.place, 'No pending places',
          'All submitted places have been reviewed.');
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingPlaces.length,
        itemBuilder: (context, index) {
          final place = _pendingPlaces[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(place.description,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: AppColors.muted)),
                  const SizedBox(height: 4),
                  Text('By: ${place.contributorName} · ${place.cityName}',
                      style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _deletePlace(place),
                        child: const Text('Delete',
                            style: TextStyle(color: AppColors.destructive)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _approvePlace(place),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Approve'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Tab 3: All Places Map ──

  Widget _buildAllPlacesMapTab() {
    final placesWithCoords = _allPlaces
        .where((p) => p.latitude != null && p.longitude != null)
        .toList();

    final center = placesWithCoords.isNotEmpty
        ? LatLng(placesWithCoords.first.latitude!,
            placesWithCoords.first.longitude!)
        : const LatLng(30.0444, 31.2357);

    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 5),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.likealocal.app',
          errorTileCallback: (_, __, ___) {},
        ),
        MarkerLayer(
          markers: placesWithCoords.map((place) {
            return Marker(
              point: LatLng(place.latitude!, place.longitude!),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => _showPlaceAdminPopup(place),
                child: Container(
                  decoration: BoxDecoration(
                    color: place.isApproved ? AppColors.primary : AppColors.destructive,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.location_on,
                      color: Colors.white, size: 22),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showPlaceAdminPopup(Place place) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(place.title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(place.description,
                maxLines: 3, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: place.isApproved
                        ? AppColors.accent.withOpacity(0.2)
                        : AppColors.destructive.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    place.isApproved ? 'Approved' : 'Pending',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: place.isApproved
                          ? AppColors.accent
                          : AppColors.destructive,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('By: ${place.contributorName}',
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _deletePlace(place);
                  },
                  child: const Text('Delete',
                      style: TextStyle(color: AppColors.destructive)),
                ),
                if (!place.isApproved) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _approvePlace(place);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Approve'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.muted),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: TextStyle(fontSize: 14, color: AppColors.muted)),
        ],
      ),
    );
  }
}
