import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../models/city.dart';
import '../providers/cities_provider.dart';
import 'city_detail_screen.dart';

class ExploreCitiesScreen extends StatefulWidget {
  @override
  _ExploreCitiesScreenState createState() => _ExploreCitiesScreenState();
}

class _ExploreCitiesScreenState extends State<ExploreCitiesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  List<City> _filterCities(String query, List<City> allCities) {
    if (query.isEmpty) return allCities;
    return allCities.where((city) {
      return city.name.toLowerCase().contains(query.toLowerCase()) ||
          city.country.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CitiesProvider>(
      builder: (context, citiesProvider, _) {
        final displayCities =
            _filterCities(_searchQuery, citiesProvider.cities);

        return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.surface,
            title: Text(
              'Explore Cities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
            ),
            centerTitle: true,
            automaticallyImplyLeading: false,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(64),
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (q) => setState(() => _searchQuery = q),
                    decoration: InputDecoration(
                      hintText: 'Search cities...',
                      hintStyle: TextStyle(
                        color: AppColors.muted,
                        fontSize: 16,
                      ),
                      prefixIcon:
                          Icon(Icons.search, color: AppColors.muted, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close,
                                  color: AppColors.muted, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // City Grid or Empty State
          if (displayCities.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search, size: 48, color: AppColors.muted),
                    SizedBox(height: 16),
                    Text(
                      'No cities found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Try different search terms',
                      style:
                          TextStyle(fontSize: 14, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildCityCard(displayCities[index]),
                  childCount: displayCities.length,
                ),
              ),
            ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildCityCard(City city) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => CityDetailScreen(cityName: city.name),
          ),
        );
      },
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // City image (60% of card)
            Expanded(
              flex: 6,
              child: CachedNetworkImage(
                imageUrl: city.image,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) =>
                    Container(color: AppColors.secondary),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.secondary,
                  child: Icon(Icons.image, color: AppColors.muted),
                ),
              ),
            ),
            // Card content (40% of card)
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      city.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      city.country,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          '${city.placeCount} places',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
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
    );
  }
}
