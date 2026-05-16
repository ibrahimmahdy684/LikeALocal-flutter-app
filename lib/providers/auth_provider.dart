import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // Initialize: check if user is already logged in
  Future<void> tryAutoLogin() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      await _fetchUserData(firebaseUser.uid);
    }
  }

  // Sign Up with email and password
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Create user in Firebase Auth
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      AppUser newUser = AppUser(
        id: credential.user!.uid,
        name: name,
        email: email,
        role: role,
        points: 20, // points for completing profile
        badges: [],
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(newUser.toMap());

      _currentUser = newUser;

      // Save login state
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool('isLoggedIn', true);
    } catch (error) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign In with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
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

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', false);
    notifyListeners();
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser =
            AppUser.fromMap(doc.data() as Map<String, dynamic>, uid);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  // Update user points
  Future<void> addPoints(int points) async {
    if (_currentUser == null) return;
    _currentUser!.points += points;
    await _firestore.collection('users').doc(_currentUser!.id).update({
      'points': _currentUser!.points,
    });
    notifyListeners();
  }

  // Add badge
  Future<void> addBadge(String badge) async {
    if (_currentUser == null) return;
    if (!_currentUser!.badges.contains(badge)) {
      _currentUser!.badges.add(badge);
      await _firestore.collection('users').doc(_currentUser!.id).update({
        'badges': _currentUser!.badges,
      });
      notifyListeners();
    }
  }

  // Update saved places count
  Future<void> updateSavedCount(int count) async {
    if (_currentUser == null) return;
    _currentUser!.savedPlaces = count;
    await _firestore.collection('users').doc(_currentUser!.id).update({
      'savedPlaces': count,
    });
    notifyListeners();
  }
}
