import 'package:flutter/material.dart';

import '../models/notification_item.dart';
import '../services/firestore_service.dart';

class NotificationsProvider with ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<NotificationItem> _notifications = [];
  bool _isLoading = false;

  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadForUser(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _firestore.fetchNotifications(userId);
    } catch (e) {
      debugPrint('NotificationsProvider loadForUser: $e');
      _notifications = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;

    _notifications[index].isRead = true;
    notifyListeners();

    try {
      await _firestore.markNotificationRead(id);
    } catch (e) {
      debugPrint('NotificationsProvider markAsRead: $e');
    }
  }

  Future<void> markAllAsRead(String userId) async {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();

    try {
      await _firestore.markAllNotificationsRead(userId);
    } catch (e) {
      debugPrint('NotificationsProvider markAllAsRead: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();

    try {
      await _firestore.deleteNotification(id);
    } catch (e) {
      debugPrint('NotificationsProvider deleteNotification: $e');
    }
  }

  void clear() {
    _notifications = [];
    notifyListeners();
  }
}
