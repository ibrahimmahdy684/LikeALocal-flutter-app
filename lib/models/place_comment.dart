import 'package:cloud_firestore/cloud_firestore.dart';

class PlaceComment {
  final String id;
  final String placeId;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;

  PlaceComment({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
  });

  factory PlaceComment.fromMap(Map<String, dynamic> map, String id) {
    return PlaceComment(
      id: id,
      placeId: map['placeId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Anonymous',
      text: map['text'] ?? '',
      createdAt: _parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'placeId': placeId,
      'userId': userId,
      'userName': userName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}
