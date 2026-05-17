class PlaceReminder {
  String id;
  String placeId;
  String placeName;
  String userId;
  DateTime reminderTime;
  String note;
  bool isCompleted;

  PlaceReminder({
    required this.id,
    required this.placeId,
    required this.placeName,
    required this.userId,
    required this.reminderTime,
    this.note = '',
    this.isCompleted = false,
  });

  factory PlaceReminder.fromMap(Map<String, dynamic> map, String id) {
    return PlaceReminder(
      id: id,
      placeId: map['placeId'] ?? '',
      placeName: map['placeName'] ?? '',
      userId: map['userId'] ?? '',
      reminderTime: DateTime.tryParse(map['reminderTime'] ?? '') ?? DateTime.now(),
      note: map['note'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'placeId': placeId,
      'placeName': placeName,
      'userId': userId,
      'reminderTime': reminderTime.toIso8601String(),
      'note': note,
      'isCompleted': isCompleted,
    };
  }
}
