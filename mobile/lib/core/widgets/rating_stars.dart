import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Read-only star row with optional numeric label.
class RatingStars extends StatelessWidget {
  final double rating;
  final int count;
  final double size;
  final bool showCount;

  const RatingStars({
    super.key,
    required this.rating,
    this.count = 0,
    this.size = 16,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, color: AppColors.accent, size: size + 2),
        const SizedBox(width: 3),
        Text(
          rating > 0 ? rating.toStringAsFixed(1) : 'New',
          style: AppText.bodyStrong.copyWith(fontSize: size - 1),
        ),
        if (showCount && count > 0) ...[
          const SizedBox(width: 3),
          Text('($count)', style: AppText.caption.copyWith(fontSize: size - 3)),
        ],
      ],
    );
  }
}

/// Interactive star picker for submitting reviews.
class RatingPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  const RatingPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final filled = i < value;
        return IconButton(
          onPressed: () => onChanged(i + 1),
          icon: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            color: filled ? AppColors.accent : AppColors.textMuted,
            size: size,
          ),
        );
      }),
    );
  }
}
