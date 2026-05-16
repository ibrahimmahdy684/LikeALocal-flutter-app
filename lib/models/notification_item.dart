import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  nearby,
  saved,
  badge,
  follower,
  message,
  approval,
  reminder,
}

class NotificationItem {
  String id;
  String userId;
  NotificationType type;
  String title;
  String message;
  DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.id,
    this.userId = '',
    required this.type,
    required this.title,
    required this.message,
    DateTime? timestamp,
    this.isRead = false,
  }) : timestamp = timestamp ?? DateTime.now();

  factory NotificationItem.fromMap(Map<String, dynamic> map, String id) {
    return NotificationItem(
      id: id,
      userId: map['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'reminder'),
        orElse: () => NotificationType.reminder,
      ),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      timestamp: _parseDate(map['timestamp']),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  // Sample notifications (offline fallback)
  static List<NotificationItem> sampleNotifications = [
    NotificationItem(
      id: '1',
      type: NotificationType.nearby,
      title: 'New Place Nearby',
      message: 'Le Petit Cafe is just 200m away from you!',
      isRead: false,
    ),
    NotificationItem(
      id: '2',
      type: NotificationType.saved,
      title: 'Someone saved your place',
      message: 'A tourist saved Secret Market to their list',
      isRead: false,
    ),
    NotificationItem(
      id: '3',
      type: NotificationType.badge,
      title: 'New Badge Unlocked!',
      message: 'You earned the Explorer badge for visiting 10+ places',
      isRead: true,
    ),
    NotificationItem(
      id: '4',
      type: NotificationType.approval,
      title: 'Place Approved',
      message: 'Your submission "Old Town Books" has been approved!',
      isRead: true,
    ),
    NotificationItem(
      id: '5',
      type: NotificationType.reminder,
      title: 'Visit Reminder',
      message: 'Don\'t forget to visit Bistro Authentique today!',
      isRead: false,
    ),
    NotificationItem(
      id: '6',
      type: NotificationType.follower,
      title: 'New Follower',
      message: 'Emma started following you',
      isRead: true,
    ),
    NotificationItem(
      id: '7',
      type: NotificationType.message,
      title: 'New Message',
      message: 'Lucas sent you a recommendation',
      isRead: false,
    ),
  ];
}
