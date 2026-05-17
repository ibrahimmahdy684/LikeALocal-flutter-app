import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firestore_collections.dart';
import '../models/city.dart';
import '../models/local_guide.dart';
import '../models/notification_item.dart';
import '../models/place.dart';
import '../models/place_comment.dart';
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
    return snapshot.docs
        .map((doc) => City.fromMap(doc.data(), doc.id))
        .toList();
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
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => NotificationItem.fromMap(doc.data(), doc.id))
        .toList();
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

  String _cityDocId(String name) =>
      name.toLowerCase().replaceAll(' ', '_');
}
