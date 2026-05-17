enum UserRole { tourist, local, admin, superUser }

enum ChatPrivacy { everyone, guidesOnly, nobody }

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
  List<String> pinnedPlaceIds;
  bool isPro;
  bool isApproved;
  ChatPrivacy chatPrivacy;
  List<String> blockedUserIds;
  List<String> preferredCategories;
  int budgetLevel;
  DateTime? promotedToSuperAt;

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
    this.pinnedPlaceIds = const [],
    this.isPro = false,
    this.isApproved = true,
    this.chatPrivacy = ChatPrivacy.everyone,
    this.blockedUserIds = const [],
    this.preferredCategories = const [],
    this.budgetLevel = 2,
    this.promotedToSuperAt,
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
      pinnedPlaceIds: List<String>.from(map['pinnedPlaceIds'] ?? []),
      isPro: map['isPro'] ?? false,
      isApproved: map['isApproved'] ?? true,
      chatPrivacy: ChatPrivacy.values.firstWhere(
        (e) => e.name == (map['chatPrivacy'] ?? 'everyone'),
        orElse: () => ChatPrivacy.everyone,
      ),
      blockedUserIds: List<String>.from(map['blockedUserIds'] ?? []),
      preferredCategories: List<String>.from(map['preferredCategories'] ?? []),
      budgetLevel: map['budgetLevel'] ?? 2,
      promotedToSuperAt: map['promotedToSuperAt'] != null
          ? DateTime.tryParse(map['promotedToSuperAt'].toString())
          : null,
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
      'pinnedPlaceIds': pinnedPlaceIds,
      'isPro': isPro,
      'isApproved': isApproved,
      'chatPrivacy': chatPrivacy.name,
      'blockedUserIds': blockedUserIds,
      'preferredCategories': preferredCategories,
      'budgetLevel': budgetLevel,
      if (promotedToSuperAt != null)
        'promotedToSuperAt': promotedToSuperAt!.toIso8601String(),
    };
  }
}
