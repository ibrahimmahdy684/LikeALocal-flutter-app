import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/cache_service.dart';
import '../theme/app_colors.dart';

class ChatPrivacyScreen extends StatefulWidget {
  const ChatPrivacyScreen({super.key});

  @override
  State<ChatPrivacyScreen> createState() => _ChatPrivacyScreenState();
}

class _ChatPrivacyScreenState extends State<ChatPrivacyScreen> {
  bool _nearbyNotifications = true;
  double _nearbyRadius = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final cache = CacheService.instance;
    _nearbyNotifications = await cache.getNearbyNotificationsEnabled();
    _nearbyRadius = await cache.getNearbyRadius();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Privacy & Notifications')),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isAuthenticated) {
            return const Center(child: Text('Please sign in'));
          }

          final user = auth.currentUser!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionHeader('Chat Privacy'),
              const SizedBox(height: 8),
              _buildPrivacyOption(
                auth,
                'Everyone',
                'Anyone can send you messages',
                ChatPrivacy.everyone,
                user.chatPrivacy,
              ),
              _buildPrivacyOption(
                auth,
                'Guides Only',
                'Only local guides can message you',
                ChatPrivacy.guidesOnly,
                user.chatPrivacy,
              ),
              _buildPrivacyOption(
                auth,
                'Nobody',
                'Disable incoming messages',
                ChatPrivacy.nobody,
                user.chatPrivacy,
              ),
              const SizedBox(height: 24),
              _sectionHeader('Nearby Notifications'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Enable nearby alerts'),
                      subtitle: const Text(
                          'Get notified when you\'re near interesting places'),
                      value: _nearbyNotifications,
                      activeColor: AppColors.primary,
                      onChanged: (val) async {
                        setState(() => _nearbyNotifications = val);
                        await CacheService.instance
                            .setNearbyNotificationsEnabled(val);
                      },
                    ),
                    if (_nearbyNotifications) ...[
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Text('Radius: '),
                            Expanded(
                              child: Slider(
                                value: _nearbyRadius,
                                min: 0.5,
                                max: 5.0,
                                divisions: 9,
                                activeColor: AppColors.primary,
                                label: '${_nearbyRadius.toStringAsFixed(1)} km',
                                onChanged: (val) async {
                                  setState(() => _nearbyRadius = val);
                                  await CacheService.instance
                                      .setNearbyRadius(val);
                                },
                              ),
                            ),
                            Text('${_nearbyRadius.toStringAsFixed(1)} km'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.foreground,
      ),
    );
  }

  Widget _buildPrivacyOption(
    AuthProvider auth,
    String title,
    String subtitle,
    ChatPrivacy value,
    ChatPrivacy current,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: current == value
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
      ),
      child: RadioListTile<ChatPrivacy>(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(color: AppColors.muted, fontSize: 12)),
        value: value,
        groupValue: current,
        activeColor: AppColors.primary,
        onChanged: (val) {
          if (val != null) auth.updateChatPrivacy(val);
        },
      ),
    );
  }
}
