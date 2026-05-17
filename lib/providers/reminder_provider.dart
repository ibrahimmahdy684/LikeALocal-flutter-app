import 'package:flutter/material.dart';

import '../models/place_reminder.dart';
import '../services/cache_service.dart';
import '../services/firestore_service.dart';

class ReminderProvider with ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  final CacheService _cache = CacheService.instance;

  List<PlaceReminder> _reminders = [];
  bool _isLoading = false;

  List<PlaceReminder> get reminders => _reminders;
  List<PlaceReminder> get upcoming =>
      _reminders.where((r) => !r.isCompleted && r.reminderTime.isAfter(DateTime.now())).toList();
  List<PlaceReminder> get overdue =>
      _reminders.where((r) => !r.isCompleted && r.reminderTime.isBefore(DateTime.now())).toList();
  bool get isLoading => _isLoading;

  Future<void> loadReminders(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _reminders = await _firestore.fetchReminders(userId);
      await _cacheReminders();
    } catch (e) {
      debugPrint('ReminderProvider loadReminders: $e');
      final cached = await _cache.getReminders();
      _reminders = cached
          .map((m) => PlaceReminder.fromMap(m, m['id'] ?? ''))
          .toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addReminder({
    required String placeId,
    required String placeName,
    required String userId,
    required DateTime reminderTime,
    String note = '',
  }) async {
    final reminder = PlaceReminder(
      id: '',
      placeId: placeId,
      placeName: placeName,
      userId: userId,
      reminderTime: reminderTime,
      note: note,
    );

    final id = await _firestore.addReminder(reminder);
    reminder.id = id;
    _reminders.add(reminder);
    _reminders.sort((a, b) => a.reminderTime.compareTo(b.reminderTime));
    await _cacheReminders();
    notifyListeners();
  }

  Future<void> completeReminder(String reminderId) async {
    final idx = _reminders.indexWhere((r) => r.id == reminderId);
    if (idx == -1) return;

    _reminders[idx].isCompleted = true;
    notifyListeners();

    await _firestore.completeReminder(reminderId);
    await _cacheReminders();
  }

  Future<void> deleteReminder(String reminderId) async {
    _reminders.removeWhere((r) => r.id == reminderId);
    notifyListeners();

    await _firestore.deleteReminder(reminderId);
    await _cacheReminders();
  }

  Future<void> _cacheReminders() async {
    final data = _reminders.map((r) => {...r.toMap(), 'id': r.id}).toList();
    await _cache.saveReminders(data);
  }

  void clear() {
    _reminders = [];
    notifyListeners();
  }
}
