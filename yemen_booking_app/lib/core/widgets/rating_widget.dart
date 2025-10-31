import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_dimensions.dart';

class RatingWidget extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final double starSize;
  final bool showLabel;
  final bool interactive;
  final Function(double)? onRatingChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final MainAxisAlignment alignment;
  final bool showReviewCount;

  const RatingWidget({
    super.key,
    required this.rating,
    this.reviewCount,
    this.starSize = 20,
    this.showLabel = true,
    this.interactive = false,
    this.onRatingChanged,
    this.activeColor,
    this.inactiveColor,
    this.alignment = MainAxisAlignment.start,
    this.showReviewCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (interactive)
          _buildInteractiveStars()
        else
          _buildStaticStars(),
        if (showLabel) ...[
          const SizedBox(width: AppDimensions.spacingXs),
          _buildRatingLabel(),
        ],
        if (showReviewCount && reviewCount != null) ...[
          const SizedBox(width: AppDimensions.spacingXs),
          _buildReviewCount(),
        ],
      ],
    );
  }

  Widget _buildStaticStars() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return _buildStar(index);
      }),
    );
  }

  Widget _buildInteractiveStars() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            if (onRatingChanged != null) {
              onRatingChanged!(index + 1.0);
            }
          },
          child: _buildStar(index),
        );
      }),
    );
  }

  Widget _buildStar(int index) {
    final double starValue = index + 1.0;
    final bool isFilled = rating >= starValue;
    final bool isHalfFilled = rating > index && rating < starValue;

    IconData iconData;
    Color color;

    if (isFilled) {
      iconData = Icons.star_rounded;
      color = activeColor ?? AppTheme.warning;
    } else if (isHalfFilled) {
      iconData = Icons.star_half_rounded;
      color = activeColor ?? AppTheme.warning;
    } else {
      iconData = Icons.star_outline_rounded;
      color = inactiveColor ?? AppTheme.darkBorder;
    }

    return Icon(
      iconData,
      size: starSize,
      color: color,
    );
  }

  Widget _buildRatingLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSmall,
        vertical: AppDimensions.paddingXSmall,
      ),
      decoration: BoxDecoration(
        color: _getRatingColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusXs),
      ),
      child: Text(
        rating.toStringAsFixed(1),
        style: AppTextStyles.rating.copyWith(
          color: _getRatingColor(),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildReviewCount() {
    return Text(
      '($reviewCount)',
      style: AppTextStyles.caption.copyWith(
        color: AppTheme.textMuted,
      ),
    );
  }

  Color _getRatingColor() {
    if (rating >= 4.5) {
      return AppTheme.success;
    } else if (rating >= 3.5) {
      return AppTheme.warning;
    } else if (rating >= 2.5) {
      return AppTheme.warning;
    } else {
      return AppTheme.error;
    }
  }
}

class RatingStarsInput extends StatefulWidget {
  final double initialRating;
  final Function(double) onRatingChanged;
  final double starSize;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool allowHalfRating;

  const RatingStarsInput({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.starSize = 32,
    this.activeColor,
    this.inactiveColor,
    this.allowHalfRating = false,
  });

  @override
  State<RatingStarsInput> createState() => _RatingStarsInputState();
}

class _RatingStarsInputState extends State<RatingStarsInput> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTapDown: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localPosition = box.globalToLocal(details.globalPosition);
            final starWidth = widget.starSize;
            final starIndex = localPosition.dx / starWidth;
            
            setState(() {
              if (widget.allowHalfRating) {
                _currentRating = (starIndex * 2).round() / 2;
              } else {
                _currentRating = starIndex.ceil().toDouble();
              }
              _currentRating = _currentRating.clamp(0.5, 5.0);
            });
            
            widget.onRatingChanged(_currentRating);
          },
          child: Icon(
            _getIconForIndex(index),
            size: widget.starSize,
            color: _getColorForIndex(index),
          ),
        );
      }),
    );
  }

  IconData _getIconForIndex(int index) {
    final double starValue = index + 1.0;
    
    if (_currentRating >= starValue) {
      return Icons.star_rounded;
    } else if (_currentRating > index && _currentRating < starValue) {
      return Icons.star_half_rounded;
    } else {
      return Icons.star_outline_rounded;
    }
  }

  Color _getColorForIndex(int index) {
    final double starValue = index + 1.0;
    
    if (_currentRating >= starValue) {
      return widget.activeColor ?? AppTheme.warning;
    } else {
      return widget.inactiveColor ?? AppTheme.darkBorder;
    }
  }
}