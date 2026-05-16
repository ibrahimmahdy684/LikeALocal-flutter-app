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

  // Sample cities data (offline fallback)
  static List<City> sampleCities = [
    City(
      name: 'Paris',
      country: 'France',
      placeCount: 127,
      image: 'https://images.unsplash.com/photo-1576085545437-4a3a6f7833cc?w=1080',
      latitude: 48.8566,
      longitude: 2.3522,
    ),
    City(
      name: 'Tokyo',
      country: 'Japan',
      placeCount: 98,
      image: 'https://images.unsplash.com/photo-1585085007341-a5aadf6e48e5?w=1080',
      latitude: 35.6762,
      longitude: 139.6503,
    ),
    City(
      name: 'Barcelona',
      country: 'Spain',
      placeCount: 85,
      image: 'https://images.unsplash.com/photo-1653677903266-1d814985b3cc?w=1080',
      latitude: 41.3874,
      longitude: 2.1686,
    ),
    City(
      name: 'New York',
      country: 'USA',
      placeCount: 142,
      image: 'https://images.unsplash.com/photo-1570304816841-906a17d7b067?w=1080',
      latitude: 40.7128,
      longitude: -74.0060,
    ),
    City(
      name: 'London',
      country: 'United Kingdom',
      placeCount: 103,
      image: 'https://images.unsplash.com/photo-1597178827242-f1e30914fc0e?w=1080',
      latitude: 51.5074,
      longitude: -0.1278,
    ),
    City(
      name: 'Amsterdam',
      country: 'Netherlands',
      placeCount: 67,
      image: 'https://images.unsplash.com/photo-1605905898247-bb1fe36b587e?w=1080',
      latitude: 52.3676,
      longitude: 4.9041,
    ),
  ];
}
