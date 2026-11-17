import 'package:flutter/material.dart';
import 'package:toktok/core/theme/app_theme.dart';

class StarRating extends StatelessWidget {
  final int rating;
  final bool interactive;
  final ValueChanged<int>? onRatingChanged;
  final double size;

  const StarRating({
    super.key,
    this.rating = 0,
    this.interactive = false,
    this.onRatingChanged,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        return GestureDetector(
          onTap: interactive ? () => onRatingChanged?.call(starNumber) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              starNumber <= rating ? Icons.star_rounded : Icons.star_border_rounded,
              color: starNumber <= rating ? AppColors.accent : AppColors.textTertiary,
              size: size,
            ),
          ),
        );
      }),
    );
  }
}
