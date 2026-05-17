import 'package:cloud_firestore/cloud_firestore.dart';

class Place {
  String id;
  String title;
  String description;
  String category;
  int price; // 1-3
  double rating;
  int ratingCount;
  double ratingTotal;
  double hiddenGemScore;
  String image;
  double? latitude;
  double? longitude;
  String cityName;
  String contributorId;
  String contributorName;
  bool isApproved;
  String tips;
  DateTime createdAt;

  Place({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.price = 1,
    this.rating = 0,
    this.ratingCount = 0,
    this.ratingTotal = 0,
    this.hiddenGemScore = 0,
    this.image = '',
    this.latitude,
    this.longitude,
    this.cityName = '',
    this.contributorId = '',
    this.contributorName = '',
    this.isApproved = false,
    this.tips = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Place.fromMap(Map<String, dynamic> map, String id) {
    return Place(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      price: map['price'] ?? 1,
      rating: (map['rating'] ?? 0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
      ratingTotal: (map['ratingTotal'] ?? 0).toDouble(),
      hiddenGemScore: (map['hiddenGemScore'] ?? 0).toDouble(),
      image: map['image'] ?? '',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      cityName: map['cityName'] ?? '',
      contributorId: map['contributorId'] ?? '',
      contributorName: map['contributorName'] ?? '',
      isApproved: map['isApproved'] ?? false,
      tips: map['tips'] ?? '',
      createdAt: _parseDate(map['createdAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'rating': rating,
      'ratingCount': ratingCount,
      'ratingTotal': ratingTotal,
      'hiddenGemScore': hiddenGemScore,
      'image': image,
      'latitude': latitude,
      'longitude': longitude,
      'cityName': cityName,
      'contributorId': contributorId,
      'contributorName': contributorName,
      'isApproved': isApproved,
      'tips': tips,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
