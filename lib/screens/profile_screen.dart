import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/places_provider.dart';
import '../providers/notifications_provider.dart';
import '../models/user.dart';
import 'admin_screen.dart';
import 'auth_screen.dart';
import 'add_place_screen.dart';
import 'chat_privacy_screen.dart';
import 'notifications_screen.dart';
import 'preferences_screen.dart';
import 'reminders_screen.dart';

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
            if (authProvider.isAdmin)
              IconButton(
                icon: Icon(Icons.admin_panel_settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => const AdminScreen()),
                  );
                },
              ),
            IconButton(
              icon: Icon(Icons.alarm),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const RemindersScreen()),
                );
              },
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.settings_outlined),
              onSelected: (val) {
                if (val == 'privacy') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatPrivacyScreen()));
                } else if (val == 'preferences') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PreferencesScreen()));
                } else if (val == 'reminders') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersScreen()));
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'privacy', child: Text('Privacy & Notifications')),
                const PopupMenuItem(value: 'preferences', child: Text('My Preferences')),
                const PopupMenuItem(value: 'reminders', child: Text('Reminders')),
              ],
            ),
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
        body: OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;
            return LayoutBuilder(
              builder: (context, constraints) {
                final headerHeight = isLandscape
                    ? (constraints.maxHeight * 0.25).clamp(80.0, 120.0)
                    : (constraints.maxHeight * 0.2).clamp(120.0, 180.0);
                return Column(
                  children: [
                    SizedBox(
                      height: headerHeight,
                      child: Container(
                        width: double.infinity,
                        color: AppColors.surface,
                        padding: EdgeInsets.symmetric(
                          horizontal: isLandscape ? 32 : 16,
                          vertical: isLandscape ? 4 : 8,
                        ),
                        child: Row(
                          children: [
                            _buildUserAvatar(
                              user.avatar,
                              user.name,
                              isLandscape ? 22 : 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: TextStyle(
                                      fontSize: isLandscape ? 15 : 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _getRoleName(user.role) +
                                        (user.role == UserRole.local &&
                                                !user.isApproved
                                            ? ' (Pending Approval)'
                                            : ''),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: user.role == UserRole.local &&
                                              !user.isApproved
                                          ? AppColors.destructive
                                          : AppColors.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _compactStat(
                                          'Saved', user.savedPlaces.toString()),
                                      _compactStat('Shared',
                                          user.sharedPlaces.toString()),
                                      _compactStat(
                                          'Pts', user.points.toString()),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (ctx) => AddPlaceScreen()),
                                );
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.add, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                Material(
                  color: AppColors.surface,
                  child: TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.muted,
                    indicatorColor: AppColors.primary,
                    tabs: const [
                      Tab(text: 'Saved'),
                      Tab(text: 'Shared'),
                      Tab(text: 'Badges'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildSavedTab(),
                      _buildSharedTab(),
                      _buildBadgesTab(user),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () {
                          authProvider.signOut(
                            placesProvider: Provider.of<PlacesProvider>(
                                context,
                                listen: false),
                            notificationsProvider:
                                Provider.of<NotificationsProvider>(context,
                                    listen: false),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.destructive,
                          side: const BorderSide(color: AppColors.destructive),
                        ),
                        child: const Text('Sign Out',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
              ],
            );
            },
          );
          },
        ),
      ),
    );
  }

  Widget _compactStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 11, color: AppColors.muted),
          children: [
            TextSpan(
              text: '$value ',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.foreground,
                fontSize: 12,
              ),
            ),
            TextSpan(text: label),
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
        return LayoutBuilder(
          builder: (ctx, gridConstraints) {
            final crossAxisCount = (gridConstraints.maxWidth / 180).floor().clamp(2, 4);
            return GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
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
      },
    );
  }

  Widget _buildSharedTab() {
    return Consumer<PlacesProvider>(
      builder: (context, placesProvider, _) {
        final places = placesProvider.contributedPlaces;
        if (places.isEmpty) {
          return _buildEmptyState(
            icon: Icons.location_on_outlined,
            title: 'No shared places yet',
            subtitle: 'Add a place — it appears here after submission',
          );
        }
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: places.length,
          itemBuilder: (context, index) {
            final place = places[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: place.image.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: place.image,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        color: AppColors.secondary,
                        child: Icon(Icons.place, color: AppColors.muted),
                      ),
              ),
              title: Text(place.title),
              subtitle: Text(
                place.isApproved ? 'Approved' : 'Pending approval',
              ),
              trailing: Icon(
                place.isApproved ? Icons.check_circle : Icons.schedule,
                color: place.isApproved ? AppColors.accent : AppColors.muted,
                size: 20,
              ),
            );
          },
        );
      },
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

  static Widget _buildUserAvatar(String avatar, String name, double radius) {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '?';
    // Check if avatar is a local file path
    if (avatar.isNotEmpty && !kIsWeb && !avatar.startsWith('http')) {
      final file = File(avatar);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: FileImage(file),
        );
      }
    }
    // Network image
    if (avatar.isNotEmpty && avatar.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primaryLight,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: avatar,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Text(
              initials,
              style: TextStyle(
                fontSize: radius * 0.7,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      );
    }
    // Initials fallback
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLight,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
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
