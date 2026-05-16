import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/firestore_collections.dart';
import '../models/city.dart';
import '../models/notification_item.dart';
import '../models/place.dart';
import '../models/place_comment.dart';

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

  Future<void> setCity(City city) async {
    final docId = _cityDocId(city.name);
    await _cities.doc(docId).set(city.toMap(), SetOptions(merge: true));
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

  String _cityDocId(String name) =>
      name.toLowerCase().replaceAll(' ', '_');

  Future<void> seedInitialData() async {
    if (await isDatabaseSeeded()) return;

    debugPrint('FirestoreService: seeding initial cities and places...');

    for (final city in City.sampleCities) {
      await setCity(city);
    }

    for (final place in _samplePlacesForSeed()) {
      await _places.add(place.toMap());
    }

    await markDatabaseSeeded();
    debugPrint('FirestoreService: seed complete.');
  }

  List<Place> _samplePlacesForSeed() {
    const cityName = 'Paris';
    return [
      Place(
        id: '',
        title: 'Le Petit Cafe',
        description:
            'Hidden gem coffee shop with amazing pastries and local vibe',
        category: 'Cafe',
        price: 2,
        rating: 4.8,
        hiddenGemScore: 9.2,
        image:
            'https://images.unsplash.com/photo-1739723745132-97df9db49db2?w=1080',
        latitude: 48.8566,
        longitude: 2.3522,
        cityName: cityName,
        isApproved: true,
        contributorName: 'Emma',
      ),
      Place(
        id: '',
        title: 'Secret Market',
        description: 'Authentic local market, open only on weekends',
        category: 'Market',
        price: 1,
        rating: 4.9,
        hiddenGemScore: 9.8,
        image:
            'https://images.unsplash.com/photo-1766650186677-947f1740a94d?w=1080',
        latitude: 48.8606,
        longitude: 2.3376,
        cityName: cityName,
        isApproved: true,
        contributorName: 'Lucas',
      ),
      Place(
        id: '',
        title: 'Bistro Authentique',
        description: 'Family-run restaurant with traditional cuisine',
        category: 'Restaurant',
        price: 3,
        rating: 4.7,
        hiddenGemScore: 8.5,
        image:
            'https://images.unsplash.com/photo-1564758564211-cc16d061f020?w=1080',
        latitude: 48.8529,
        longitude: 2.3499,
        cityName: cityName,
        isApproved: true,
        contributorName: 'Sophie',
      ),
    ];
  }
}
