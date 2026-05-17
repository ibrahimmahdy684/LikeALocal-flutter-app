import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../models/place.dart';
import '../models/review.dart';
import '../providers/auth_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/review_provider.dart';
import '../services/firestore_service.dart';
import '../services/maps_launcher_service.dart';
import '../theme/app_colors.dart';
import '../widgets/rating_widget.dart';
import '../widgets/reminder_dialog.dart';
import '../widgets/review_card.dart';
import '../widgets/review_form_dialog.dart';
import '../widgets/save_place_button.dart';
import '../widgets/upgrade_pro_dialog.dart';
import 'auth_screen.dart';

class PlaceDetailScreen extends StatefulWidget {
  final Place place;

  const PlaceDetailScreen({super.key, required this.place});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  final _firestore = FirestoreService();
  final _maps = MapsLauncherService();
  double? _userRating;
  bool _loadingRating = true;
  late double _displayRating;
  late int _displayRatingCount;

  @override
  void initState() {
    super.initState();
    _displayRating = widget.place.rating;
    _displayRatingCount = widget.place.ratingCount;
    _loadUserRating();
  }

  Future<void> _refreshPlaceRating() async {
    final doc = await _firestore.getPlaceById(widget.place.id);
    if (doc != null && mounted) {
      setState(() {
        _displayRating = doc.rating;
        _displayRatingCount = doc.ratingCount;
        widget.place.rating = doc.rating;
        widget.place.ratingCount = doc.ratingCount;
        widget.place.ratingTotal = doc.ratingTotal;
      });
    }
  }

  Future<void> _loadUserRating() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      setState(() => _loadingRating = false);
      return;
    }
    final reviewProvider = context.read<ReviewProvider>();
    _userRating = await reviewProvider.getUserRating(
      widget.place.id,
      auth.currentUser!.id,
    );
    if (mounted) setState(() => _loadingRating = false);
  }

  Future<void> _ratePlace(double rating) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => AuthScreen()));
      return;
    }
    final reviewProvider = context.read<ReviewProvider>();
    await reviewProvider.ratePlace(
      placeId: widget.place.id,
      userId: auth.currentUser!.id,
      rating: rating,
    );
    setState(() => _userRating = rating);
    await _refreshPlaceRating();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rating submitted!')),
      );
    }
  }

  Future<void> _writeReview() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => AuthScreen()));
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => ReviewFormDialog(placeId: widget.place.id),
    );
    if (result == null) return;

    final reviewProvider = context.read<ReviewProvider>();
    await reviewProvider.addReview(
      placeId: widget.place.id,
      userId: auth.currentUser!.id,
      userName: auth.currentUser!.name,
      text: result['text'],
      rating: result['rating'],
    );

    await reviewProvider.ratePlace(
      placeId: widget.place.id,
      userId: auth.currentUser!.id,
      rating: result['rating'],
    );
    setState(() => _userRating = result['rating']);
    await _refreshPlaceRating();
  }

  Future<void> _editReview(Review review) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => ReviewFormDialog(
        placeId: widget.place.id,
        existingReview: review,
      ),
    );
    if (result == null) return;

    review.text = result['text'];
    review.rating = result['rating'];
    review.updatedAt = DateTime.now();

    final reviewProvider = context.read<ReviewProvider>();
    await reviewProvider.updateReview(review);
    await reviewProvider.ratePlace(
      placeId: widget.place.id,
      userId: review.userId,
      rating: result['rating'],
    );
    setState(() => _userRating = result['rating']);
    await _refreshPlaceRating();
  }

  Future<void> _deleteReview(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final reviewProvider = context.read<ReviewProvider>();
    await reviewProvider.deleteReview(widget.place.id, review.id);
  }

  Future<void> _pinPlace() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => AuthScreen()));
      return;
    }
    try {
      await auth.togglePinPlace(
        widget.place.id,
        isPro: auth.currentUser!.isPro,
      );
      if (mounted) {
        final pinned = auth.isPlacePinned(widget.place.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pinned ? 'Place pinned!' : 'Pin removed')),
        );
      }
    } on FreemiumLimitException {
      if (mounted) showUpgradeProDialog(context);
    }
  }

  Future<void> _setReminder() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => AuthScreen()));
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => ReminderDialog(placeName: widget.place.title),
    );
    if (result == null) return;

    final reminderProvider = context.read<ReminderProvider>();
    await reminderProvider.addReminder(
      placeId: widget.place.id,
      placeName: widget.place.title,
      userId: auth.currentUser!.id,
      reminderTime: result['dateTime'],
      note: result['note'] ?? '',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder set for ${DateFormat.yMMMd().format(result['dateTime'])}')),
      );
    }
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
    final auth = context.watch<AuthProvider>();
    final isPinned = auth.isPlacePinned(place.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            actions: [
              IconButton(
                icon: Icon(
                  isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: isPinned ? AppColors.accent : Colors.white,
                ),
                onPressed: _pinPlace,
                tooltip: isPinned ? 'Unpin' : 'Pin location',
              ),
              IconButton(
                icon: const Icon(Icons.alarm_add, color: Colors.white),
                onPressed: _setReminder,
                tooltip: 'Set reminder',
              ),
            ],
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
                  Text(place.description, style: TextStyle(color: AppColors.muted)),
                  if (place.tips.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb_outline, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(place.tips, style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Overall rating display
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Column(
                          children: [
                            Text(
                              _displayRating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                            ),
                            RatingWidget(rating: _displayRating, size: 16),
                            Text(
                              '$_displayRatingCount ratings',
                              style: TextStyle(fontSize: 12, color: AppColors.muted),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Your rating:', style: TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            _loadingRating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : RatingBar(
                                    initialRating: _userRating ?? 0,
                                    onRatingUpdate: _ratePlace,
                                    size: 28,
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text(place.category)),
                      Chip(label: Text(place.cityName)),
                      Chip(label: Text('\$' * place.price)),
                      Chip(
                        label: Text('Gem ${place.hiddenGemScore.toStringAsFixed(1)}'),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _writeReview,
                          icon: const Icon(Icons.rate_review, color: Colors.white),
                          label: const Text('Write Review', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Reviews',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          // Reviews stream
          StreamBuilder<List<Review>>(
            stream: _firestore.watchReviews(widget.place.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              final reviews = snapshot.data ?? [];
              if (reviews.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No reviews yet. Be the first to review!',
                      style: TextStyle(color: AppColors.muted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final review = reviews[index];
                      final isOwner = auth.currentUser?.id == review.userId;
                      return ReviewCard(
                        review: review,
                        isOwner: isOwner,
                        onEdit: () => _editReview(review),
                        onDelete: () => _deleteReview(review),
                      );
                    },
                    childCount: reviews.length,
                  ),
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
