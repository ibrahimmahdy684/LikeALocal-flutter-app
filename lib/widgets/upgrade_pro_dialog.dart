import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../config/app_config.dart';

Future<void> showUpgradeProDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Upgrade to Pro'),
      content: Text(
        'Free accounts show up to ${AppConfig.freeMapPinLimit} map pins. '
        'Upgrade to Pro for unlimited pins and priority listings.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Not now'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pro plan coming soon — contact support to upgrade.'),
              ),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Learn more', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
