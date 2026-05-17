import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  String id;
  String placeId;
  String userId;
  String userName;
  String text;
  double rating;
  DateTime createdAt;
  DateTime? updatedAt;

  Review({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.userName,
    required this.text,
    required this.rating,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Review.fromMap(Map<String, dynamic> map, String id) {
    return Review(
      id: id,
      placeId: map['placeId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      text: map['text'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      createdAt: _parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? _parseDate(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'placeId': placeId,
      'userId': userId,
      'userName': userName,
      'text': text,
      'rating': rating,
      'createdAt': FieldValue.serverTimestamp(),
      if (updatedAt != null) 'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}
