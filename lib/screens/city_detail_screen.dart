import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../models/place.dart';
import '../providers/places_provider.dart';
import '../providers/cities_provider.dart';
import '../widgets/save_place_button.dart';
import '../models/local_guide.dart';
import '../services/firestore_service.dart';
import 'guide_chat_screen.dart';
import 'place_detail_screen.dart';
import 'city_chat_screen.dart';

class CityDetailScreen extends StatefulWidget {
  final String cityName;
  const CityDetailScreen({super.key, required this.cityName});

  @override
  State<CityDetailScreen> createState() => _CityDetailScreenState();
}

class _CityDetailScreenState extends State<CityDetailScreen> {
  final _searchController = TextEditingController();
  final _firestore = FirestoreService();
  String _searchQuery = '';
  late Future<List<LocalGuide>> _guidesFuture;

  String? _cityImage(BuildContext context) {
    final city = context.read<CitiesProvider>().cityByName(widget.cityName);
    if (city != null && city.image.isNotEmpty) return city.image;
    return null;
  }

  void _showCategoryFilter(BuildContext context, PlacesProvider provider) {
    const categories = [
      'All',
      'Cafe',
      'Restaurant',
      'Market',
      'Shop',
      'Art & Culture',
      'Nightlife',
    ];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: categories.map((cat) {
            return ListTile(
              title: Text(cat),
              trailing: provider.selectedCategory == cat
                  ? Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                provider.setCategory(cat);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _guidesFuture = _firestore.fetchLocalGuidesForCity(widget.cityName);
    // Fetch places for this city
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PlacesProvider>().fetchPlaces(widget.cityName);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CityChatScreen(cityName: widget.cityName),
            ),
          );
        },
        icon: const Icon(Icons.forum, color: Colors.white),
        label: const Text('City chat',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
      ),
      body: Consumer<PlacesProvider>(
        builder: (context, placesProvider, child) {
          // Filter places by search query
          List<Place> displayPlaces = placesProvider.filteredPlaces;
          if (_searchQuery.isNotEmpty) {
            displayPlaces = displayPlaces.where((p) {
              return p.title
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  p.description
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
            }).toList();
          }

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Hero Image
                  SliverAppBar(
                    expandedHeight: 180,
                    pinned: true,
                    leading: Padding(
                      padding: EdgeInsets.all(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back,
                              color: AppColors.primary, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          if ((_cityImage(context) ?? '').isNotEmpty)
                            CachedNetworkImage(
                              imageUrl: _cityImage(context)!,
                              fit: BoxFit.cover,
                              placeholder: (ctx, url) =>
                                  Container(color: AppColors.secondary),
                              errorWidget: (ctx, url, err) => Container(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            )
                          else
                            Container(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.3),
                                  Colors.black.withValues(alpha: 0.6),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 24,
                            left: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.cityName,
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, 2),
                                        blurRadius: 8,
                                        color: Colors.black.withValues(alpha: 0.8),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Discover hidden gems',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: AppColors.muted, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) =>
                                  setState(() => _searchQuery = val),
                              decoration: const InputDecoration(
                                hintText: 'Search places, food, experiences...',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                _showCategoryFilter(context, placesProvider),
                            icon: const Icon(Icons.tune, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Local Guides Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        'Local Guides',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: FutureBuilder<List<LocalGuide>>(
                      future: _guidesFuture,
                      builder: (context, snapshot) {
                        final guides = snapshot.data ?? [];

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            height: 100,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }

                        if (guides.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'No local guides yet for this city',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.muted,
                              ),
                            ),
                          );
                        }

                        return SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: guides.length,
                            itemBuilder: (context, index) {
                              final guide = guides[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          GuideChatScreen(guide: guide),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: AppColors.accent,
                                              width: 2),
                                        ),
                                        child: ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl: guide.avatar,
                                            fit: BoxFit.cover,
                                            errorWidget: (ctx, url, err) =>
                                                Container(
                                              color: AppColors.secondary,
                                              child: Icon(Icons.person,
                                                  color: AppColors.muted),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        guide.name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  // Recommended Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recommended',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.foreground,
                            ),
                          ),
                          Text(
                            '${displayPlaces.length} places',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Places List
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildPlaceCard(displayPlaces[index]),
                      childCount: displayPlaces.length,
                    ),
                  ),

                  // Bottom spacer for floating button
                  SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),

            ],
          );
        },
      ),
    );
  }

  Widget _buildPlaceCard(Place place) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaceDetailScreen(place: place),
          ),
        );
      },
      child: Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
        children: [
          // Place image
          SizedBox(
            width: 112,
            child: CachedNetworkImage(
              imageUrl: place.image,
              fit: BoxFit.cover,
              placeholder: (ctx, url) =>
                  Container(color: AppColors.secondary),
              errorWidget: (ctx, url, err) => Container(
                color: AppColors.secondary,
                child: Icon(Icons.image, color: AppColors.muted),
              ),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          place.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.foreground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SavePlaceButton(placeId: place.id),
                          SizedBox(width: 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome,
                                    size: 12, color: AppColors.accent),
                                SizedBox(width: 4),
                                Text(
                                  place.hiddenGemScore.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Description
                  Text(
                    place.description,
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Bottom row: Category + Price
                  Row(
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          place.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.foreground,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      // Price indicators
                      Row(
                        children: List.generate(3, (i) {
                          return Icon(
                            Icons.attach_money,
                            size: 12,
                            color: i < place.price
                                ? AppColors.primary
                                : AppColors.muted.withValues(alpha: 0.3),
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    ));
  }
}
