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

  static List<LocalGuide> forCity(String cityName) {
    return _all.where((g) => g.cityName == cityName).toList();
  }

  static const _all = [
    LocalGuide(
      id: 'emma',
      name: 'Emma',
      avatar: 'https://i.pravatar.cc/150?img=1',
      cityName: 'Paris',
      bio: 'Coffee shops & hidden courtyards in Le Marais',
    ),
    LocalGuide(
      id: 'lucas',
      name: 'Lucas',
      avatar: 'https://i.pravatar.cc/150?img=13',
      cityName: 'Paris',
      bio: 'Weekend markets and street food expert',
    ),
    LocalGuide(
      id: 'sophie',
      name: 'Sophie',
      avatar: 'https://i.pravatar.cc/150?img=5',
      cityName: 'Paris',
      bio: 'Family bistros and authentic French dining',
    ),
    LocalGuide(
      id: 'marco',
      name: 'Marco',
      avatar: 'https://i.pravatar.cc/150?img=12',
      cityName: 'Paris',
      bio: 'Bookstores, art walks, and quiet gems',
    ),
    LocalGuide(
      id: 'ava',
      name: 'Ava',
      avatar: 'https://i.pravatar.cc/150?img=9',
      cityName: 'Paris',
      bio: 'Nightlife and live music in the 11th',
    ),
  ];
}
