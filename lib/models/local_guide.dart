class LocalGuide {
  final String id;
  final String name;
  final String avatar;
  final String cityName;
  final String bio;

  const LocalGuide({
    required this.id,
    required this.name,
    required this.avatar,
    required this.cityName,
    this.bio = '',
  });
}
