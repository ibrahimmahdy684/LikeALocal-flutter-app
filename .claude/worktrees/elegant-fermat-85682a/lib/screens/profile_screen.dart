import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/places_provider.dart';
import '../models/user.dart';
import 'auth_screen.dart';
import 'add_place_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          return _buildGuestState(context);
        }
        return _buildAuthenticatedState(context, authProvider);
      },
    );
  }

  Widget _buildGuestState(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_outline,
                      color: AppColors.primary, size: 40),
                ),
                SizedBox(height: 24),
                Text(
                  'Sign in to LikeALocal',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Save places, earn badges, and contribute to the community',
                  style: TextStyle(fontSize: 14, color: AppColors.muted),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (ctx) => AuthScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthenticatedState(
      BuildContext context, AuthProvider authProvider) {
    final user = authProvider.currentUser!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: Text('Profile'),
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (ctx) => NotificationsScreen()),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Profile header
            Container(
              color: AppColors.surface,
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: user.avatar.isNotEmpty
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: user.avatar,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(Icons.person,
                            color: AppColors.primary, size: 40),
                  ),
                  SizedBox(height: 12),
                  // Name
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                  ),
                  SizedBox(height: 4),
                  // Role badge
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getRoleName(user.role),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat('Saved', user.savedPlaces.toString()),
                      Container(
                        width: 1,
                        height: 32,
                        color: AppColors.border,
                      ),
                      _buildStat('Shared', user.sharedPlaces.toString()),
                      Container(
                        width: 1,
                        height: 32,
                        color: AppColors.border,
                      ),
                      _buildStat('Points', user.points.toString()),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Add Place button (for locals)
                  if (authProvider.isLocal ||
                      user.role == UserRole.tourist)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (ctx) => AddPlaceScreen()),
                          );
                        },
                        icon: Icon(Icons.add, size: 20),
                        label: Text('Add Place'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Tab bar
            Container(
              color: AppColors.surface,
              child: TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.muted,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: 'Saved'),
                  Tab(text: 'Shared'),
                  Tab(text: 'Badges'),
                ],
              ),
            ),
            // Tab views
            Expanded(
              child: TabBarView(
                children: [
                  _buildSavedTab(),
                  _buildSharedTab(),
                  _buildBadgesTab(user),
                ],
              ),
            ),
            // Sign out button
            Container(
              color: AppColors.surface,
              padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => authProvider.signOut(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.destructive,
                    side: BorderSide(color: AppColors.destructive),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Sign Out',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.foreground,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildSavedTab() {
    return Consumer<PlacesProvider>(
      builder: (context, placesProvider, child) {
        if (placesProvider.savedPlaces.isEmpty) {
          return _buildEmptyState(
            icon: Icons.favorite_outline,
            title: 'No saved places yet',
            subtitle: 'Save your first place',
          );
        }
        return GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: placesProvider.savedPlaces.length,
          itemBuilder: (context, index) {
            final place = placesProvider.savedPlaces[index];
            return Container(
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
                  Expanded(
                    flex: 3,
                    child: CachedNetworkImage(
                      imageUrl: place.image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (ctx, url) =>
                          Container(color: AppColors.secondary),
                      errorWidget: (ctx, url, err) =>
                          Container(color: AppColors.secondary),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              place.category,
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSharedTab() {
    return _buildEmptyState(
      icon: Icons.location_on_outlined,
      title: 'No shared places yet',
      subtitle: 'Share your first place',
    );
  }

  Widget _buildBadgesTab(AppUser user) {
    final allBadges = [
      {
        'name': 'Explorer',
        'desc': 'Visit 10+ places',
        'icon': Icons.explore,
      },
      {
        'name': 'Curator',
        'desc': 'Save 20+ places',
        'icon': Icons.bookmark,
      },
      {
        'name': 'Contributor',
        'desc': 'Share 5+ places',
        'icon': Icons.share,
      },
      {
        'name': 'Super User',
        'desc': 'Top contributor',
        'icon': Icons.star,
      },
      {
        'name': 'Local Guide',
        'desc': 'Verified local',
        'icon': Icons.verified,
      },
    ];

    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: allBadges.length,
      itemBuilder: (context, index) {
        final badge = allBadges[index];
        bool isEarned = user.badges.contains(badge['name']);
        return Container(
          padding: EdgeInsets.all(16),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                badge['icon'] as IconData,
                size: 32,
                color: isEarned ? AppColors.accent : AppColors.muted,
              ),
              SizedBox(height: 8),
              Text(
                badge['name'] as String,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isEarned ? AppColors.foreground : AppColors.muted,
                ),
              ),
              SizedBox(height: 4),
              Text(
                badge['desc'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.muted),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.tourist:
        return 'Tourist';
      case UserRole.local:
        return 'Local Contributor';
      case UserRole.admin:
        return 'Admin';
      case UserRole.superUser:
        return 'Super User';
    }
  }
}
