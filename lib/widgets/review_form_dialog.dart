import 'package:flutter/material.dart';

import '../models/review.dart';
import '../theme/app_colors.dart';
import 'rating_widget.dart';

class ReviewFormDialog extends StatefulWidget {
  final Review? existingReview;
  final String placeId;
  final double? initialRating;

  const ReviewFormDialog({
    super.key,
    this.existingReview,
    required this.placeId,
    this.initialRating,
  });

  @override
  State<ReviewFormDialog> createState() => _ReviewFormDialogState();
}

class _ReviewFormDialogState extends State<ReviewFormDialog> {
  late TextEditingController _textController;
  late double _rating;
  late bool _ratingLocked;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.existingReview?.text ?? '');
    _rating = widget.existingReview?.rating ?? widget.initialRating ?? 0;
    _ratingLocked = widget.initialRating != null && widget.initialRating! > 0;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingReview != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isEdit ? 'Edit Review' : 'Write a Review'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _ratingLocked ? 'Your rating:' : 'Select your rating:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Center(
              child: _ratingLocked
                  ? RatingWidget(rating: _rating, size: 36)
                  : RatingBar(
                      initialRating: _rating,
                      onRatingUpdate: (val) => _rating = val,
                      size: 36,
                    ),
            ),
            if (_ratingLocked)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Center(
                  child: Text(
                    'Change your rating using the stars above',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_rating == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a rating')),
              );
              return;
            }
            if (_textController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please write a review')),
              );
              return;
            }
            Navigator.pop(context, {
              'text': _textController.text.trim(),
              'rating': _rating,
            });
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text(
            isEdit ? 'Update' : 'Submit',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
