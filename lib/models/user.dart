enum UserRole { tourist, local, admin, superUser }

class AppUser {
  String id;
  String name;
  String email;
  String avatar;
  UserRole role;
  String bio;
  int savedPlaces;
  int sharedPlaces;
  int points;
  List<String> badges;
  List<String> savedPlaceIds;
  bool isPro;
  bool isApproved;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatar = '',
    this.role = UserRole.tourist,
    this.bio = '',
    this.savedPlaces = 0,
    this.sharedPlaces = 0,
    this.points = 0,
    this.badges = const [],
    this.savedPlaceIds = const [],
    this.isPro = false,
    this.isApproved = true,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    return AppUser(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      avatar: map['avatar'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == (map['role'] ?? 'tourist'),
        orElse: () => UserRole.tourist,
      ),
      bio: map['bio'] ?? '',
      savedPlaces: map['savedPlaces'] ?? 0,
      sharedPlaces: map['sharedPlaces'] ?? 0,
      points: map['points'] ?? 0,
      badges: List<String>.from(map['badges'] ?? []),
      savedPlaceIds: List<String>.from(map['savedPlaceIds'] ?? []),
      isPro: map['isPro'] ?? false,
      isApproved: map['isApproved'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'avatar': avatar,
      'role': role.name,
      'bio': bio,
      'savedPlaces': savedPlaces,
      'sharedPlaces': sharedPlaces,
      'points': points,
      'badges': badges,
      'savedPlaceIds': savedPlaceIds,
      'isPro': isPro,
      'isApproved': isApproved,
    };
  }
}
