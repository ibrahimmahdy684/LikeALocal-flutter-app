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
}
