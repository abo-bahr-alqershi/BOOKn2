// lib/features/admin_availability_pricing/presentation/widgets/pricing_tier_legend.dart

import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/pricing.dart';

class PricingTierLegend extends StatelessWidget {
  const PricingTierLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.7),
            AppTheme.darkCard.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(
                tier: PricingTier.discount,
                label: 'خصم',
                color: AppTheme.success,
                icon: Icons.trending_down_rounded,
              ),
              _buildLegendItem(
                tier: PricingTier.normal,
                label: 'عادي',
                color: AppTheme.primaryBlue,
                icon: Icons.remove_rounded,
              ),
              _buildLegendItem(
                tier: PricingTier.high,
                label: 'مرتفع',
                color: AppTheme.warning,
                icon: Icons.trending_up_rounded,
              ),
              _buildLegendItem(
                tier: PricingTier.peak,
                label: 'ذروة',
                color: AppTheme.error,
                icon: Icons.whatshot_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required PricingTier tier,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.3),
                color.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 12,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textWhite.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}