class City {
  String id;
  String name;
  String country;
  int placeCount;
  String image;
  double latitude;
  double longitude;

  City({
    this.id = '',
    required this.name,
    required this.country,
    this.placeCount = 0,
    this.image = '',
    this.latitude = 0,
    this.longitude = 0,
  });

  factory City.fromMap(Map<String, dynamic> map, String id) {
    return City(
      id: id,
      name: map['name'] ?? '',
      country: map['country'] ?? '',
      placeCount: map['placeCount'] ?? 0,
      image: map['image'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'country': country,
      'placeCount': placeCount,
      'image': image,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
