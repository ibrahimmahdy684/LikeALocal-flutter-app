import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/firestore_collections.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';
import 'notifications_provider.dart';
import 'places_provider.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  AppUser? _currentUser;
  bool _isLoading = false;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isLocal =>
      _currentUser?.role == UserRole.local ||
      _currentUser?.role == UserRole.admin ||
      _currentUser?.role == UserRole.superUser;
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  Future<void> tryAutoLogin() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      await _fetchUserData(firebaseUser.uid);
    }
  }

  Future<void> syncUserSession({
    required PlacesProvider placesProvider,
    required NotificationsProvider notificationsProvider,
  }) async {
    if (_currentUser == null) return;
    await placesProvider.loadUserData(_currentUser!.id);
    await notificationsProvider.loadForUser(_currentUser!.id);
    await _fetchUserData(_currentUser!.id);
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final newUser = AppUser(
        id: credential.user!.uid,
        name: name,
        email: email,
        role: role,
        points: 20,
        badges: [],
        savedPlaceIds: [],
      );

      await _firestore
          .collection(FirestoreCollections.users)
          .doc(credential.user!.uid)
          .set(newUser.toMap());

      await _firestoreService.createWelcomeNotification(
        userId: credential.user!.uid,
        userName: name,
      );

      _currentUser = newUser;

      final prefs = await SharedPreferences.getInstance();
      prefs.setBool('isLoggedIn', true);
    } catch (error) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _fetchUserData(credential.user!.uid);

      final prefs = await SharedPreferences.getInstance();
      prefs.setBool('isLoggedIn', true);
    } catch (error) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut({
    PlacesProvider? placesProvider,
    NotificationsProvider? notificationsProvider,
  }) async {
    await _auth.signOut();
    _currentUser = null;
    placesProvider?.clearUserData();
    notificationsProvider?.clear();

    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', false);
    notifyListeners();
  }

  Future<void> _fetchUserData(String uid) async {
    try {
      final doc =
          await _firestore.collection(FirestoreCollections.users).doc(uid).get();
      if (doc.exists) {
        _currentUser =
            AppUser.fromMap(doc.data() as Map<String, dynamic>, uid);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  Future<void> addPoints(int points) async {
    if (_currentUser == null) return;
    _currentUser!.points += points;
    await _firestore.collection(FirestoreCollections.users).doc(_currentUser!.id).update({
      'points': _currentUser!.points,
    });
    notifyListeners();
  }

  Future<void> incrementSharedPlaces() async {
    if (_currentUser == null) return;
    await _firestoreService.incrementSharedPlaces(_currentUser!.id);
    _currentUser!.sharedPlaces += 1;
    notifyListeners();
  }

  Future<void> addBadge(String badge) async {
    if (_currentUser == null) return;
    if (!_currentUser!.badges.contains(badge)) {
      _currentUser!.badges.add(badge);
      await _firestore.collection(FirestoreCollections.users).doc(_currentUser!.id).update({
        'badges': _currentUser!.badges,
      });
      notifyListeners();
    }
  }

  Future<void> updateSavedCount(int count) async {
    if (_currentUser == null) return;
    _currentUser!.savedPlaces = count;
    await _firestore.collection(FirestoreCollections.users).doc(_currentUser!.id).update({
      'savedPlaces': count,
    });
    notifyListeners();
  }
}
