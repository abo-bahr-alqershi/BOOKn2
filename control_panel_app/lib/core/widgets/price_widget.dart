import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_dimensions.dart';

class PriceWidget extends StatelessWidget {
  final double price;
  final double? originalPrice;
  final String currency;
  final PriceDisplayType displayType;
  final TextStyle? priceStyle;
  final TextStyle? originalPriceStyle;
  final TextStyle? currencyStyle;
  final String? period;
  final bool showCurrencySymbol;
  final MainAxisAlignment alignment;
  final bool animate;

  const PriceWidget({
    super.key,
    required this.price,
    this.originalPrice,
    this.currency = 'YER',
    this.displayType = PriceDisplayType.normal,
    this.priceStyle,
    this.originalPriceStyle,
    this.currencyStyle,
    this.period,
    this.showCurrencySymbol = true,
    this.alignment = MainAxisAlignment.start,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (displayType) {
      case PriceDisplayType.normal:
        return _buildNormalPrice(context);
      case PriceDisplayType.discount:
        return _buildDiscountPrice(context);
      case PriceDisplayType.compact:
        return _buildCompactPrice(context);
      case PriceDisplayType.detailed:
        return _buildDetailedPrice(context);
    }
  }

  Widget _buildNormalPrice(BuildContext context) {
    final Widget priceWidget = Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatPrice(price),
          style: priceStyle ?? AppTextStyles.heading1,
        ),
        if (showCurrencySymbol) ...[
          const SizedBox(width: AppDimensions.spaceXSmall),
          Text(
            currency,
            style: currencyStyle ?? AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
        if (period != null) ...[
          const SizedBox(width: AppDimensions.spaceXSmall),
          Text(
            '/ $period',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ],
    );

    if (animate) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: price),
        duration: const Duration(milliseconds: 500),
        builder: (context, value, child) {
          return Row(
            mainAxisAlignment: alignment,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatPrice(value),
                style: priceStyle ?? AppTextStyles.heading1,
              ),
              if (showCurrencySymbol) ...[
                const SizedBox(width: AppDimensions.spaceXSmall),
                Text(
                  currency,
                  style: currencyStyle ?? AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ],
          );
        },
      );
    }

    return priceWidget;
  }

  Widget _buildDiscountPrice(BuildContext context) {
    if (originalPrice == null || originalPrice == price) {
      return _buildNormalPrice(context);
    }

    final double discountPercentage = 
        ((originalPrice! - price) / originalPrice! * 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: alignment,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatPrice(price),
              style: priceStyle ?? AppTextStyles.heading1.copyWith(
                color: AppTheme.success,
              ),
            ),
            if (showCurrencySymbol) ...[
              const SizedBox(width: AppDimensions.spaceXSmall),
              Text(
                currency,
                style: currencyStyle ?? AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.normal,
                  color: AppTheme.success,
                ),
              ),
            ],
            const SizedBox(width: AppDimensions.spaceSmall),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingSmall,
                vertical: AppDimensions.paddingXSmall,
              ),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.borderRadiusXs),
              ),
              child: Text(
                '${discountPercentage.toStringAsFixed(0)}% خصم',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceXSmall),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatPrice(originalPrice!),
              style: originalPriceStyle ?? AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            if (showCurrencySymbol) ...[
              const SizedBox(width: AppDimensions.spaceXSmall),
              Text(
                currency,
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCompactPrice(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSmall,
        vertical: AppDimensions.paddingXSmall,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusXs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatPrice(price),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (showCurrencySymbol) ...[
            const SizedBox(width: 2),
            Text(
              currency,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedPrice(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(AppDimensions.borderMedium),
        border: Border.all(
          color: AppTheme.darkBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (originalPrice != null && originalPrice != price) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'السعر الأصلي:',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                Text(
                  '${_formatPrice(originalPrice!)} $currency',
                  style: AppTextStyles.bodyMedium.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceXSmall),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                period != null ? 'السعر / $period:' : 'السعر:',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_formatPrice(price)} $currency',
                style: AppTextStyles.heading1.copyWith(
                  color: originalPrice != null && originalPrice != price
                      ? AppTheme.success
                      : AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPrice(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}

enum PriceDisplayType {
  normal,
  discount,
  compact,
  detailed,
}