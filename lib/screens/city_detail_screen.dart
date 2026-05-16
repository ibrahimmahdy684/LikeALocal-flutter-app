import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../models/city.dart';
import '../models/place.dart';
import '../providers/places_provider.dart';

class CityDetailScreen extends StatefulWidget {
  final String cityName;
  const CityDetailScreen({Key? key, required this.cityName}) : super(key: key);

  @override
  _CityDetailScreenState createState() => _CityDetailScreenState();
}

class _CityDetailScreenState extends State<CityDetailScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // City image mapping
  String get _cityImage {
    final city = City.sampleCities.firstWhere(
      (c) => c.name == widget.cityName,
      orElse: () => City.sampleCities.first,
    );
    return city.image;
  }

  // Local guides data
  final List<Map<String, String>> _guides = [
    {'name': 'Emma', 'avatar': 'https://i.pravatar.cc/150?img=1'},
    {'name': 'Lucas', 'avatar': 'https://i.pravatar.cc/150?img=13'},
    {'name': 'Sophie', 'avatar': 'https://i.pravatar.cc/150?img=5'},
    {'name': 'Marco', 'avatar': 'https://i.pravatar.cc/150?img=12'},
    {'name': 'Ava', 'avatar': 'https://i.pravatar.cc/150?img=9'},
  ];

  @override
  void initState() {
    super.initState();
    // Fetch places for this city
    Future.microtask(() {
      Provider.of<PlacesProvider>(context, listen: false)
          .fetchPlaces(widget.cityName);
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
      body: Consumer<PlacesProvider>(
        builder: (context, placesProvider, child) {
          // Filter places by search query
          List<Place> displayPlaces = placesProvider.places;
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
                    expandedHeight: 256,
                    pinned: false,
                    leading: Padding(
                      padding: EdgeInsets.all(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
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
                          CachedNetworkImage(
                            imageUrl: _cityImage,
                            fit: BoxFit.cover,
                            placeholder: (ctx, url) =>
                                Container(color: AppColors.secondary),
                            errorWidget: (ctx, url, err) =>
                                Container(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.3),
                                  Colors.black.withOpacity(0.6),
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
                                        color: Colors.black.withOpacity(0.8),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Discover hidden gems',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Search & Filter Bar
                  SliverToBoxAdapter(
                    child: Transform.translate(
                      offset: Offset(0, -24),
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 24,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search,
                                color: AppColors.muted, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) =>
                                    setState(() => _searchQuery = val),
                                decoration: InputDecoration(
                                  hintText:
                                      'Search places, food, experiences...',
                                  hintStyle: TextStyle(
                                      fontSize: 14, color: AppColors.muted),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.tune,
                                  color: Colors.white, size: 20),
                            ),
                          ],
                        ),
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
                    child: Container(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _guides.length,
                        itemBuilder: (context, index) {
                          final guide = _guides[index];
                          return Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: Column(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppColors.accent, width: 2),
                                  ),
                                  child: ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: guide['avatar']!,
                                      fit: BoxFit.cover,
                                      placeholder: (ctx, url) => Container(
                                          color: AppColors.secondary),
                                      errorWidget: (ctx, url, err) =>
                                          Icon(Icons.person),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  guide['name']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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

              // Floating Map Button
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    // Navigate to map tab - handled by parent
                    Navigator.pop(context);
                  },
                  backgroundColor: AppColors.primary,
                  icon: Icon(Icons.map, color: Colors.white, size: 20),
                  label: Text(
                    'Map',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlaceCard(Place place) {
    return Container(
      height: 112,
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // Place image
          SizedBox(
            width: 112,
            height: 112,
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
                      // Hidden gem score badge
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                                : AppColors.muted.withOpacity(0.3),
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
    );
  }
}
