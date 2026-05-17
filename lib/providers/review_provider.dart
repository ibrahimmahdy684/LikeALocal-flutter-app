import 'package:flutter/material.dart';

import '../models/review.dart';
import '../services/firestore_service.dart';

class ReviewProvider with ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<Review> _reviews = [];
  bool _isLoading = false;
  String? _currentPlaceId;

  List<Review> get reviews => _reviews;
  bool get isLoading => _isLoading;

  Stream<List<Review>> watchReviews(String placeId) {
    _currentPlaceId = placeId;
    return _firestore.watchReviews(placeId);
  }

  Future<Review?> getUserReview(String placeId, String userId) async {
    return _firestore.getUserReview(placeId, userId);
  }

  Future<void> addReview({
    required String placeId,
    required String userId,
    required String userName,
    required String text,
    required double rating,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final review = Review(
        id: '',
        placeId: placeId,
        userId: userId,
        userName: userName,
        text: text,
        rating: rating,
      );
      await _firestore.addReview(review);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateReview(Review review) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.updateReview(review);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteReview(String placeId, String reviewId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.deleteReview(placeId, reviewId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> ratePlace({
    required String placeId,
    required String userId,
    required double rating,
  }) async {
    await _firestore.ratePlace(
      placeId: placeId,
      userId: userId,
      rating: rating,
    );
    notifyListeners();
  }

  Future<double?> getUserRating(String placeId, String userId) async {
    return _firestore.getUserRating(placeId, userId);
  }
}
