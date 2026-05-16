import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/places_provider.dart';
import '../screens/auth_screen.dart';
import '../theme/app_colors.dart';

class SavePlaceButton extends StatelessWidget {
  final String placeId;
  final double iconSize;

  const SavePlaceButton({
    super.key,
    required this.placeId,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, PlacesProvider>(
      builder: (context, auth, places, _) {
        final saved = places.isPlaceSaved(placeId);
        return IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(
            saved ? Icons.favorite : Icons.favorite_border,
            color: saved ? AppColors.destructive : AppColors.muted,
            size: iconSize,
          ),
          onPressed: () => _onTap(context, auth, places),
        );
      },
    );
  }

  Future<void> _onTap(
    BuildContext context,
    AuthProvider auth,
    PlacesProvider places,
  ) async {
    if (!auth.isAuthenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AuthScreen()),
      );
      return;
    }

    try {
      await places.toggleSavePlace(placeId, auth.currentUser!.id);
      await auth.updateSavedCount(places.savedPlaceIds.length);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update saved places')),
        );
      }
    }
  }
}
