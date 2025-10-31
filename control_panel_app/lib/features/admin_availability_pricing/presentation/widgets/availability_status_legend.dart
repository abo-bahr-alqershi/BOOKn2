// lib/features/admin_availability_pricing/presentation/widgets/availability_status_legend.dart

import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/availability.dart';

class AvailabilityStatusLegend extends StatelessWidget {
  const AvailabilityStatusLegend({super.key});

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
                status: AvailabilityStatus.available,
                label: 'متاح',
                color: AppTheme.success,
              ),
              _buildLegendItem(
                status: AvailabilityStatus.booked,
                label: 'محجوز',
                color: AppTheme.warning,
              ),
              _buildLegendItem(
                status: AvailabilityStatus.blocked,
                label: 'محظور',
                color: AppTheme.error,
              ),
              _buildLegendItem(
                status: AvailabilityStatus.maintenance,
                label: 'صيانة',
                color: AppTheme.info,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required AvailabilityStatus status,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
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