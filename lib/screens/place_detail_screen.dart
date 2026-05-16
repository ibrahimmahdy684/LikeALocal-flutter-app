import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../models/place.dart';
import '../models/place_comment.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../services/maps_launcher_service.dart';
import '../theme/app_colors.dart';
import '../widgets/save_place_button.dart';
import 'auth_screen.dart';

class PlaceDetailScreen extends StatefulWidget {
  final Place place;

  const PlaceDetailScreen({super.key, required this.place});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  final _commentController = TextEditingController();
  final _firestore = FirestoreService();
  final _maps = MapsLauncherService();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AuthScreen()),
      );
      return;
    }
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    await _firestore.addPlaceComment(
      placeId: widget.place.id,
      userId: auth.currentUser!.id,
      userName: auth.currentUser!.name,
      text: text,
    );
    _commentController.clear();
  }

  Future<void> _openDirections() async {
    if (widget.place.latitude == null || widget.place.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No location available for this place')),
      );
      return;
    }
    try {
      await _maps.openDirections(
        latitude: widget.place.latitude!,
        longitude: widget.place.longitude!,
        label: widget.place.title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open maps: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: place.image.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: place.image,
                      fit: BoxFit.cover,
                    )
                  : Container(color: AppColors.secondary),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          place.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SavePlaceButton(placeId: place.id),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(place.description,
                      style: TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text(place.category)),
                      Chip(label: Text(place.cityName)),
                      Chip(
                        label: Text(
                          'Gem ${place.hiddenGemScore.toStringAsFixed(1)}',
                        ),
                        backgroundColor: AppColors.accentLight,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openDirections,
                          icon: const Icon(Icons.directions),
                          label: const Text('Directions'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _postComment,
                        icon: const Icon(Icons.send, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          StreamBuilder<List<PlaceComment>>(
            stream: _firestore.watchPlaceComments(place.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              final comments = snapshot.data ?? [];
              if (comments.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No comments yet. Be the first!',
                      style: TextStyle(color: AppColors.muted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final c = comments[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(c.userName.isNotEmpty
                            ? c.userName[0].toUpperCase()
                            : '?'),
                      ),
                      title: Text(c.userName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(c.text),
                      trailing: Text(
                        DateFormat.MMMd().format(c.createdAt),
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    );
                  },
                  childCount: comments.length,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
