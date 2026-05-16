import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class CityChatMessage {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;

  CityChatMessage({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
  });
}

class CityChatProvider with ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  List<CityChatMessage> _messages = [];
  String _cityName = '';

  List<CityChatMessage> get messages => _messages;

  void listen(String cityName) {
    if (_cityName == cityName && _subscription != null) return;
    _cityName = cityName;
    _subscription?.cancel();
    _subscription = _firestore.watchCityChat(cityName).listen((data) {
      _messages = data.map((m) {
        return CityChatMessage(
          id: m['id'] as String,
          userId: m['userId'] ?? '',
          userName: m['userName'] ?? 'Traveler',
          text: m['text'] ?? '',
          createdAt: _parseTime(m['createdAt']),
        );
      }).toList();
      notifyListeners();
    });
  }

  Future<void> send({
    required String userId,
    required String userName,
    required String text,
  }) async {
    await _firestore.sendCityChatMessage(
      cityName: _cityName,
      userId: userId,
      userName: userName,
      text: text,
    );
  }

  static DateTime _parseTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
