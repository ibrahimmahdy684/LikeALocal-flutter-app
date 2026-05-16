import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Send a message to Firestore (Lecture 8 pattern)
  Future<void> sendMessage(String text) async {
    final user = _auth.currentUser;
    String username = 'Guest';
    String userId = 'anonymous';

    if (user != null) {
      userId = user.uid;
      // Fetch username from users collection (Lecture 8)
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          username = data['name'] ?? 'User';
        }
      } catch (e) {
        debugPrint('Error fetching username: $e');
      }
    }

    // Add chat message to Firestore (Lecture 8 pattern)
    await _firestore.collection('chats').doc().set({
      'text': text,
      'userId': userId,
      'username': username,
      'timeCreated': Timestamp.now(),
    });
  }

  // Get chat stream ordered by time (Lecture 8 - StreamBuilder pattern)
  Stream<QuerySnapshot> getChatStream() {
    return _firestore
        .collection('chats')
        .orderBy('timeCreated', descending: true)
        .snapshots();
  }

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
}
