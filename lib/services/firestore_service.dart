import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firestore_collections.dart';
import '../models/city.dart';
import '../models/local_guide.dart';
import '../models/notification_item.dart';
import '../models/place.dart';
import '../models/place_comment.dart';
import '../models/place_reminder.dart';
import '../models/review.dart';
import '../models/user.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(FirestoreCollections.users);

  CollectionReference<Map<String, dynamic>> get _places =>
      _db.collection(FirestoreCollections.places);

  CollectionReference<Map<String, dynamic>> get _cities =>
      _db.collection(FirestoreCollections.cities);

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection(FirestoreCollections.notifications);

  Future<bool> isDatabaseSeeded() async {
    final doc = await _db
        .collection(FirestoreCollections.meta)
        .doc(FirestoreCollections.seedDoc)
        .get();
    return doc.exists && doc.data()?['initialized'] == true;
  }

  Future<void> markDatabaseSeeded() async {
    await _db
        .collection(FirestoreCollections.meta)
        .doc(FirestoreCollections.seedDoc)
        .set({
      'initialized': true,
      'seededAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<City>> fetchCities() async {
    final snapshot = await _cities.orderBy('name').get();
    final cities = snapshot.docs
        .map((doc) => City.fromMap(doc.data(), doc.id))
        .toList();

    // Update place counts dynamically from actual approved places
    for (final city in cities) {
      final placesSnap = await _places
          .where('cityName', isEqualTo: city.name)
          .where('isApproved', isEqualTo: true)
          .count()
          .get();
      final actualCount = placesSnap.count ?? 0;
      if (actualCount != city.placeCount) {
        city.placeCount = actualCount;
        // Update in background, don't await
        _cities.doc(_cityDocId(city.name)).update({'placeCount': actualCount});
      }
    }

    return cities;
  }

  Future<City?> fetchCityByName(String cityName) async {
    final doc = await _cities.doc(_cityDocId(cityName)).get();
    if (!doc.exists) return null;
    return City.fromMap(doc.data() ?? const <String, dynamic>{}, doc.id);
  }

  Future<void> setCity(City city) async {
    final docId = _cityDocId(city.name);
    await _cities.doc(docId).set(city.toMap(), SetOptions(merge: true));
  }

  Future<void> incrementCityPlaceCount(String cityName) async {
    final docRef = _cities.doc(_cityDocId(cityName));
    final doc = await docRef.get();
    if (!doc.exists) return;

    await docRef.update({
      'placeCount': FieldValue.increment(1),
    });
  }

  Future<List<LocalGuide>> fetchLocalGuidesForCity(String cityName) async {
    final snapshot = await _places
        .where('cityName', isEqualTo: cityName)
        .where('isApproved', isEqualTo: true)
        .get();

    final contributorIds = snapshot.docs
        .map((doc) => doc.data()['contributorId'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (contributorIds.isEmpty) return [];

    final userDocs = await Future.wait(
      contributorIds.map((id) => _users.doc(id).get()),
    );

    final guides = <LocalGuide>[];
    for (final doc in userDocs) {
      if (!doc.exists || doc.data() == null) continue;

      final user = AppUser.fromMap(doc.data()!, doc.id);
      if (user.role != UserRole.local || !user.isApproved) {
        continue;
      }

      guides.add(
        LocalGuide(
          id: user.id,
          name: user.name,
          avatar: user.avatar,
          cityName: cityName,
          bio: user.bio,
        ),
      );
    }

    return guides;
  }

  Future<List<Place>> fetchApprovedPlaces(String cityName) async {
    final snapshot = await _places
        .where('cityName', isEqualTo: cityName)
        .where('isApproved', isEqualTo: true)
        .get();
    return snapshot.docs
        .map((doc) => Place.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<Place>> fetchPlacesByContributor(String userId) async {
    final snapshot =
        await _places.where('contributorId', isEqualTo: userId).get();
    return snapshot.docs
        .map((doc) => Place.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<Place>> fetchPlacesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final places = <Place>[];
    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
      final snapshot = await _places
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      places.addAll(
        snapshot.docs.map((doc) => Place.fromMap(doc.data(), doc.id)),
      );
    }
    return places;
  }

  Future<String> addPlace(Place place) async {
    final ref = await _places.add(place.toMap());
    return ref.id;
  }

  Future<Place?> getPlaceById(String placeId) async {
    final doc = await _places.doc(placeId).get();
    if (!doc.exists) return null;
    return Place.fromMap(doc.data()!, doc.id);
  }

  Future<List<String>> getSavedPlaceIds(String userId) async {
    final doc = await _users.doc(userId).get();
    if (!doc.exists) return [];
    final data = doc.data();
    return List<String>.from(data?['savedPlaceIds'] ?? []);
  }

  Future<void> updateSavedPlaces({
    required String userId,
    required List<String> savedPlaceIds,
  }) async {
    await _users.doc(userId).update({
      'savedPlaceIds': savedPlaceIds,
      'savedPlaces': savedPlaceIds.length,
    });
  }

  Future<void> incrementSharedPlaces(String userId) async {
    await _users.doc(userId).update({
      'sharedPlaces': FieldValue.increment(1),
    });
  }

  Future<List<NotificationItem>> fetchNotifications(String userId) async {
    final snapshot = await _notifications
        .where('userId', isEqualTo: userId)
        .get();
    final items = snapshot.docs
        .map((doc) => NotificationItem.fromMap(doc.data(), doc.id))
        .toList();
    // Sort client-side to avoid needing a composite Firestore index
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllNotificationsRead(String userId) async {
    final snapshot = await _notifications
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _notifications.doc(notificationId).delete();
  }

  Future<List<Place>> fetchAllApprovedPlaces() async {
    final snapshot =
        await _places.where('isApproved', isEqualTo: true).get();
    return snapshot.docs
        .map((doc) => Place.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<List<PlaceComment>> watchPlaceComments(String placeId) {
    return _places
        .doc(placeId)
        .collection(FirestoreCollections.comments)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PlaceComment.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> addPlaceComment({
    required String placeId,
    required String userId,
    required String userName,
    required String text,
  }) async {
    await _places.doc(placeId).collection(FirestoreCollections.comments).add({
      'placeId': placeId,
      'userId': userId,
      'userName': userName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchCityChat(String cityName) {
    final cityId = _cityDocId(cityName);
    return _db
        .collection(FirestoreCollections.cityChats)
        .doc(cityId)
        .collection(FirestoreCollections.messages)
        .orderBy('createdAt', descending: false)
        .limitToLast(100)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  Future<void> sendCityChatMessage({
    required String cityName,
    required String userId,
    required String userName,
    required String text,
  }) async {
    final cityId = _cityDocId(cityName);
    await _db
        .collection(FirestoreCollections.cityChats)
        .doc(cityId)
        .collection(FirestoreCollections.messages)
        .add({
      'userId': userId,
      'userName': userName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createNearbyNotification({
    required String userId,
    required String placeName,
    required double distance,
  }) async {
    await _notifications.add({
      'userId': userId,
      'type': NotificationType.nearby.name,
      'title': 'You\'re near $placeName!',
      'message': '$placeName is just ${(distance * 1000).round()}m away.',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  Future<void> createMessageNotification({
    required String recipientId,
    required String senderName,
    required String messagePreview,
  }) async {
    await _notifications.add({
      'userId': recipientId,
      'type': NotificationType.message.name,
      'title': 'New message from $senderName',
      'message': messagePreview,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  Future<void> createReminderNotification({
    required String userId,
    required String placeName,
  }) async {
    await _notifications.add({
      'userId': userId,
      'type': NotificationType.reminder.name,
      'title': 'Reminder: Visit $placeName',
      'message': 'You set a reminder to visit $placeName. Time to explore!',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  Future<void> createWelcomeNotification({
    required String userId,
    required String userName,
  }) async {
    await _notifications.add({
      'userId': userId,
      'type': NotificationType.badge.name,
      'title': 'Welcome to LikeALocal!',
      'message': 'Hi $userName — start exploring cities and saving hidden gems.',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  // ── Guide chat (real-time 1:1) ──

  /// Build a deterministic chat room ID from two user IDs.
  String _guideChatId(String userId, String guideId) {
    final ids = [userId, guideId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Stream messages between a user and a guide.
  Stream<List<Map<String, dynamic>>> watchGuideChat(
      String userId, String guideId) {
    final chatId = _guideChatId(userId, guideId);
    return _db
        .collection(FirestoreCollections.guideChats)
        .doc(chatId)
        .collection(FirestoreCollections.messages)
        .orderBy('createdAt', descending: false)
        .limitToLast(100)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  /// Send a message in a guide chat.
  Future<void> sendGuideChatMessage({
    required String userId,
    required String guideId,
    required String senderName,
    required String text,
  }) async {
    final chatId = _guideChatId(userId, guideId);
    await _db
        .collection(FirestoreCollections.guideChats)
        .doc(chatId)
        .collection(FirestoreCollections.messages)
        .add({
      'senderId': userId,
      'senderName': senderName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Admin methods ──

  /// Fetch all local guide users pending approval.
  Future<List<AppUser>> fetchPendingLocalGuides() async {
    final snapshot = await _users
        .where('role', isEqualTo: 'local')
        .where('isApproved', isEqualTo: false)
        .get();
    return snapshot.docs
        .map((doc) => AppUser.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Approve a local guide account.
  Future<void> approveLocalGuide(String userId) async {
    await _users.doc(userId).update({'isApproved': true});
  }

  /// Fetch all places (approved and unapproved) for admin.
  Future<List<Place>> fetchAllPlaces() async {
    final snapshot = await _places.get();
    return snapshot.docs
        .map((doc) => Place.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Fetch unapproved places for admin review.
  Future<List<Place>> fetchPendingPlaces() async {
    final snapshot =
        await _places.where('isApproved', isEqualTo: false).get();
    return snapshot.docs
        .map((doc) => Place.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Approve a place.
  Future<void> approvePlace(String placeId) async {
    await _places.doc(placeId).update({'isApproved': true});
  }

  /// Delete a place.
  Future<void> deletePlace(String placeId) async {
    await _places.doc(placeId).delete();
  }

  // ── Reviews ──

  Future<String> addReview(Review review) async {
    final ref = await _places
        .doc(review.placeId)
        .collection(FirestoreCollections.reviews)
        .add(review.toMap());
    await _updatePlaceRating(review.placeId);
    return ref.id;
  }

  Future<void> updateReview(Review review) async {
    await _places
        .doc(review.placeId)
        .collection(FirestoreCollections.reviews)
        .doc(review.id)
        .update({
      'text': review.text,
      'rating': review.rating,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _updatePlaceRating(review.placeId);
  }

  Future<void> deleteReview(String placeId, String reviewId) async {
    await _places
        .doc(placeId)
        .collection(FirestoreCollections.reviews)
        .doc(reviewId)
        .delete();
    await _updatePlaceRating(placeId);
  }

  Stream<List<Review>> watchReviews(String placeId) {
    return _places
        .doc(placeId)
        .collection(FirestoreCollections.reviews)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Review.fromMap(d.data(), d.id)).toList());
  }

  Future<Review?> getUserReview(String placeId, String userId) async {
    final snap = await _places
        .doc(placeId)
        .collection(FirestoreCollections.reviews)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Review.fromMap(snap.docs.first.data(), snap.docs.first.id);
  }

  // ── Ratings ──

  Future<void> ratePlace({
    required String placeId,
    required String userId,
    required double rating,
  }) async {
    final ratingDoc = _places
        .doc(placeId)
        .collection(FirestoreCollections.ratings)
        .doc(userId);

    await ratingDoc.set({
      'userId': userId,
      'rating': rating,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _updatePlaceRating(placeId);
  }

  Future<double?> getUserRating(String placeId, String userId) async {
    final doc = await _places
        .doc(placeId)
        .collection(FirestoreCollections.ratings)
        .doc(userId)
        .get();
    if (!doc.exists) return null;
    return (doc.data()?['rating'] ?? 0).toDouble();
  }

  Future<void> _updatePlaceRating(String placeId) async {
    final ratingsSnap = await _places
        .doc(placeId)
        .collection(FirestoreCollections.ratings)
        .get();

    if (ratingsSnap.docs.isEmpty) {
      await _places.doc(placeId).update({
        'rating': 0,
        'ratingCount': 0,
        'ratingTotal': 0,
      });
      return;
    }

    double total = 0;
    for (final doc in ratingsSnap.docs) {
      total += (doc.data()['rating'] ?? 0).toDouble();
    }
    final count = ratingsSnap.docs.length;
    final average = total / count;

    await _places.doc(placeId).update({
      'rating': average,
      'ratingCount': count,
      'ratingTotal': total,
    });
  }

  // ── Privacy ──

  Future<void> updateChatPrivacy(String userId, ChatPrivacy privacy) async {
    await _users.doc(userId).update({'chatPrivacy': privacy.name});
  }

  Future<void> blockUser(String userId, String blockedId) async {
    await _users.doc(userId).update({
      'blockedUserIds': FieldValue.arrayUnion([blockedId]),
    });
  }

  Future<void> unblockUser(String userId, String blockedId) async {
    await _users.doc(userId).update({
      'blockedUserIds': FieldValue.arrayRemove([blockedId]),
    });
  }

  Future<ChatPrivacy> getChatPrivacy(String userId) async {
    final doc = await _users.doc(userId).get();
    final val = doc.data()?['chatPrivacy'] ?? 'everyone';
    return ChatPrivacy.values.firstWhere(
      (e) => e.name == val,
      orElse: () => ChatPrivacy.everyone,
    );
  }

  // ── Reminders ──

  Future<String> addReminder(PlaceReminder reminder) async {
    final ref = await _db
        .collection(FirestoreCollections.reminders)
        .add(reminder.toMap());
    return ref.id;
  }

  Future<void> updateReminder(PlaceReminder reminder) async {
    await _db
        .collection(FirestoreCollections.reminders)
        .doc(reminder.id)
        .update(reminder.toMap());
  }

  Future<void> deleteReminder(String reminderId) async {
    await _db
        .collection(FirestoreCollections.reminders)
        .doc(reminderId)
        .delete();
  }

  Future<List<PlaceReminder>> fetchReminders(String userId) async {
    final snap = await _db
        .collection(FirestoreCollections.reminders)
        .where('userId', isEqualTo: userId)
        .get();
    final items = snap.docs
        .map((d) => PlaceReminder.fromMap(d.data(), d.id))
        .toList();
    // Sort client-side to avoid needing a composite Firestore index
    items.sort((a, b) => a.reminderTime.compareTo(b.reminderTime));
    return items;
  }

  Future<void> completeReminder(String reminderId) async {
    await _db
        .collection(FirestoreCollections.reminders)
        .doc(reminderId)
        .update({'isCompleted': true});
  }

  // ── Pinned Places ──

  Future<void> updatePinnedPlaces({
    required String userId,
    required List<String> pinnedPlaceIds,
  }) async {
    await _users.doc(userId).update({'pinnedPlaceIds': pinnedPlaceIds});
  }

  // ── User Preferences ──

  Future<void> updatePreferences({
    required String userId,
    required List<String> categories,
    required int budgetLevel,
  }) async {
    await _users.doc(userId).update({
      'preferredCategories': categories,
      'budgetLevel': budgetLevel,
    });
  }

  // ── Super User Promotion ──

  Future<void> promoteToSuperUser(String userId) async {
    await _users.doc(userId).update({
      'role': UserRole.superUser.name,
      'promotedToSuperAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<AppUser>> fetchSuperUserCandidates() async {
    final snap = await _users
        .where('role', isEqualTo: 'tourist')
        .where('points', isGreaterThanOrEqualTo: 500)
        .get();
    return snap.docs
        .map((d) => AppUser.fromMap(d.data(), d.id))
        .toList();
  }

  // ── Premium ──

  Future<void> upgradeToPro(String userId) async {
    await _users.doc(userId).update({'isPro': true});
  }

  String _cityDocId(String name) =>
      name.toLowerCase().replaceAll(' ', '_');
}
