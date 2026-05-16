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
  NotificationType type;
  String title;
  String message;
  DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    DateTime? timestamp,
    this.isRead = false,
  }) : timestamp = timestamp ?? DateTime.now();

  // Sample notifications
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
