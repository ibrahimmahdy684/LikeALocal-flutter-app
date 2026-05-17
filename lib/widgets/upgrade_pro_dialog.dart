import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';

Future<void> showUpgradeProDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
          const SizedBox(width: 8),
          const Text('Upgrade to Pro'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Free accounts are limited to ${AppConfig.freePinLimit} pinned locations.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          _featureRow(Icons.push_pin, 'Unlimited pin locations'),
          _featureRow(Icons.map_outlined, 'All map pins visible'),
          _featureRow(Icons.route, 'Create custom itineraries'),
          _featureRow(Icons.smart_toy, 'Priority AI recommendations'),
          _featureRow(Icons.star, 'Priority content visibility'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Not now'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            final auth = Provider.of<AuthProvider>(ctx, listen: false);
            if (auth.isAuthenticated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pro plan coming soon — contact support to upgrade.'),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Upgrade', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

Widget _featureRow(IconData icon, String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 18, color: AppColors.accent),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    ),
  );
}
