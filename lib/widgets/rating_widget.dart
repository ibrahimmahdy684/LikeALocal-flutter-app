import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class RatingWidget extends StatelessWidget {
  final double rating;
  final double size;
  final bool interactive;
  final ValueChanged<double>? onRatingChanged;

  const RatingWidget({
    super.key,
    required this.rating,
    this.size = 24,
    this.interactive = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        IconData icon;
        if (rating >= starValue) {
          icon = Icons.star;
        } else if (rating >= starValue - 0.5) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }

        return GestureDetector(
          onTap: interactive ? () => onRatingChanged?.call(starValue) : null,
          child: Icon(icon, color: AppColors.accent, size: size),
        );
      }),
    );
  }
}

class RatingBar extends StatefulWidget {
  final double initialRating;
  final ValueChanged<double> onRatingUpdate;
  final double size;

  const RatingBar({
    super.key,
    this.initialRating = 0,
    required this.onRatingUpdate,
    this.size = 32,
  });

  @override
  State<RatingBar> createState() => _RatingBarState();
}

class _RatingBarState extends State<RatingBar> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        return GestureDetector(
          onTap: () {
            setState(() => _rating = starValue);
            widget.onRatingUpdate(starValue);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              _rating >= starValue ? Icons.star : Icons.star_border,
              color: AppColors.accent,
              size: widget.size,
            ),
          ),
        );
      }),
    );
  }
}
