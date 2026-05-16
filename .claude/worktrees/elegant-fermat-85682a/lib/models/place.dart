class Place {
  String id;
  String title;
  String description;
  String category;
  int price; // 1-3
  double rating;
  double hiddenGemScore;
  String image;
  double? latitude;
  double? longitude;
  String cityName;
  String contributorId;
  String contributorName;
  bool isApproved;
  DateTime createdAt;

  Place({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.price = 1,
    this.rating = 0,
    this.hiddenGemScore = 0,
    this.image = '',
    this.latitude,
    this.longitude,
    this.cityName = '',
    this.contributorId = '',
    this.contributorName = '',
    this.isApproved = false,
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
      hiddenGemScore: (map['hiddenGemScore'] ?? 0).toDouble(),
      image: map['image'] ?? '',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      cityName: map['cityName'] ?? '',
      contributorId: map['contributorId'] ?? '',
      contributorName: map['contributorName'] ?? '',
      isApproved: map['isApproved'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'rating': rating,
      'hiddenGemScore': hiddenGemScore,
      'image': image,
      'latitude': latitude,
      'longitude': longitude,
      'cityName': cityName,
      'contributorId': contributorId,
      'contributorName': contributorName,
      'isApproved': isApproved,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
