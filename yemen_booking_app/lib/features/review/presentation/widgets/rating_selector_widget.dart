import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';

class RatingSelectorWidget extends StatelessWidget {
  final int rating;
  final Function(int) onRatingChanged;
  final double starSize;
  final MainAxisAlignment alignment;

  const RatingSelectorWidget({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.starSize = 28,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isSelected = rating >= starValue;
        
        return GestureDetector(
          onTap: () => onRatingChanged(starValue),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingXs / 2,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                size: starSize,
                color: isSelected ? AppTheme.warning : AppTheme.darkBorder,
              ),
            ),
          ),
        );
      }),
    );
  }
}