import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static CacheService? _instance;
  SharedPreferences? _prefs;

  CacheService._();

  static CacheService get instance {
    _instance ??= CacheService._();
    return _instance!;
  }

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // User settings
  Future<void> savePremiumStatus(bool isPro) async {
    final p = await prefs;
    await p.setBool('isPro', isPro);
  }

  Future<bool> getPremiumStatus() async {
    final p = await prefs;
    return p.getBool('isPro') ?? false;
  }

  // Pinned locations
  Future<void> savePinnedPlaces(List<String> placeIds) async {
    final p = await prefs;
    await p.setStringList('pinnedPlaces', placeIds);
  }

  Future<List<String>> getPinnedPlaces() async {
    final p = await prefs;
    return p.getStringList('pinnedPlaces') ?? [];
  }

  // Chat privacy
  Future<void> saveChatPrivacy(String privacy) async {
    final p = await prefs;
    await p.setString('chatPrivacy', privacy);
  }

  Future<String> getChatPrivacy() async {
    final p = await prefs;
    return p.getString('chatPrivacy') ?? 'everyone';
  }

  // User preferences
  Future<void> savePreferredCategories(List<String> categories) async {
    final p = await prefs;
    await p.setStringList('preferredCategories', categories);
  }

  Future<List<String>> getPreferredCategories() async {
    final p = await prefs;
    return p.getStringList('preferredCategories') ?? [];
  }

  Future<void> saveBudgetLevel(int level) async {
    final p = await prefs;
    await p.setInt('budgetLevel', level);
  }

  Future<int> getBudgetLevel() async {
    final p = await prefs;
    return p.getInt('budgetLevel') ?? 2;
  }

  // Cached recommendations
  Future<void> cacheRecommendations(String key, List<Map<String, dynamic>> recs) async {
    final p = await prefs;
    await p.setString('recs_$key', jsonEncode(recs));
    await p.setInt('recs_ts_$key', DateTime.now().millisecondsSinceEpoch);
  }

  Future<List<Map<String, dynamic>>?> getCachedRecommendations(String key) async {
    final p = await prefs;
    final ts = p.getInt('recs_ts_$key');
    if (ts == null) return null;

    final age = DateTime.now().millisecondsSinceEpoch - ts;
    if (age > 3600000) return null; // 1 hour expiry

    final data = p.getString('recs_$key');
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  // Reminders
  Future<void> saveReminders(List<Map<String, dynamic>> reminders) async {
    final p = await prefs;
    await p.setString('reminders', jsonEncode(reminders));
  }

  Future<List<Map<String, dynamic>>> getReminders() async {
    final p = await prefs;
    final data = p.getString('reminders');
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  // Nearby notification settings
  Future<void> setNearbyNotificationsEnabled(bool enabled) async {
    final p = await prefs;
    await p.setBool('nearbyNotificationsEnabled', enabled);
  }

  Future<bool> getNearbyNotificationsEnabled() async {
    final p = await prefs;
    return p.getBool('nearbyNotificationsEnabled') ?? true;
  }

  Future<void> setNearbyRadius(double radiusKm) async {
    final p = await prefs;
    await p.setDouble('nearbyRadius', radiusKm);
  }

  Future<double> getNearbyRadius() async {
    final p = await prefs;
    return p.getDouble('nearbyRadius') ?? 1.0;
  }

  // Clear all cached data on logout
  Future<void> clearAll() async {
    final p = await prefs;
    await p.clear();
  }
}
