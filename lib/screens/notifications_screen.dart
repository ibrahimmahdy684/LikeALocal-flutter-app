import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/notifications_provider.dart';
import '../providers/auth_provider.dart';
import '../models/notification_item.dart';

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Notifications'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final auth =
                  Provider.of<AuthProvider>(context, listen: false);
              if (auth.currentUser == null) return;
              Provider.of<NotificationsProvider>(context, listen: false)
                  .markAllAsRead(auth.currentUser!.id);
            },
            child: Text(
              'Mark all read',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: Consumer<NotificationsProvider>(
        builder: (context, notifProvider, child) {
          if (notifProvider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 48, color: AppColors.muted),
                  SizedBox(height: 16),
                  Text(
                    'All caught up!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No new notifications',
                    style: TextStyle(fontSize: 14, color: AppColors.muted),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: notifProvider.notifications.length,
            itemBuilder: (context, index) {
              return _buildNotificationCard(
                context,
                notifProvider.notifications[index],
                notifProvider,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationItem notification,
    NotificationsProvider provider,
  ) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24),
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.destructive,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        provider.deleteNotification(notification.id);
      },
      child: GestureDetector(
        onTap: () => provider.markAsRead(notification.id),
        child: Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: !notification.isRead
                ? Border.all(color: AppColors.accent, width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getIconBackground(notification.type),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIcon(notification.type),
                  color: _getIconColor(notification.type),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.foreground,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 12,
                        color: notification.isRead
                            ? AppColors.muted.withOpacity(0.7)
                            : AppColors.muted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Just now',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.muted.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.nearby:
        return Icons.location_on;
      case NotificationType.saved:
        return Icons.favorite;
      case NotificationType.badge:
        return Icons.emoji_events;
      case NotificationType.follower:
        return Icons.person_add;
      case NotificationType.message:
        return Icons.message;
      case NotificationType.approval:
        return Icons.check_circle;
      case NotificationType.reminder:
        return Icons.access_time;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.saved:
        return AppColors.destructive;
      case NotificationType.badge:
      case NotificationType.approval:
        return AppColors.accent;
      default:
        return AppColors.primary;
    }
  }

  Color _getIconBackground(NotificationType type) {
    return _getIconColor(type).withOpacity(0.1);
  }
}
