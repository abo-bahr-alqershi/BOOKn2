// lib/features/admin_reviews/presentation/widgets/review_stats_card.dart

import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/review.dart';

class ReviewStatsCard extends StatelessWidget {
  final int totalReviews;
  final int pendingReviews;
  final double averageRating;
  final List<Review> reviews;
  final bool isDesktop;
  final bool isTablet;
  final int? withResponsesCount;

  const ReviewStatsCard({
    super.key,
    required this.totalReviews,
    required this.pendingReviews,
    required this.averageRating,
    required this.reviews,
    required this.isDesktop,
    required this.isTablet,
    this.withResponsesCount,
  });

  @override
  Widget build(BuildContext context) {
    final withResponse = withResponsesCount ?? reviews.where((r) => r.hasResponse).length;
    final responseRate = totalReviews > 0 ? (withResponse / totalReviews) * 100 : 0.0;

    return SizedBox(
      height: 130,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 4),
        children: [
          _buildStatCard(
            title: 'إجمالي التقييمات',
            value: totalReviews.toString(),
            icon: Icons.reviews_outlined,
            gradient: LinearGradient(
              colors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
            ),
          ),
          _buildStatCard(
            title: 'قيد المراجعة',
            value: pendingReviews.toString(),
            icon: Icons.pending_outlined,
            gradient: LinearGradient(
              colors: [AppTheme.warning, Colors.orange],
            ),
          ),
          _buildStatCard(
            title: 'متوسط التقييم',
            value: averageRating.toStringAsFixed(1),
            icon: Icons.star_rounded,
            gradient: LinearGradient(
              colors: [AppTheme.success, AppTheme.neonGreen],
            ),
          ),
          _buildStatCard(
            title: 'معدل الرد',
            value: '${responseRate.toStringAsFixed(0)}%',
            icon: Icons.reply_all_rounded,
            gradient: LinearGradient(
              colors: [AppTheme.info, AppTheme.neonBlue],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gradient.colors.first.withOpacity(0.15),
                  gradient.colors.last.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: gradient.colors.first.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -15,
                  top: -15,
                  child: Icon(
                    icon,
                    size: 80,
                    color: gradient.colors.first.withOpacity(0.1),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 32,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: gradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                icon,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        title,
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            value,
                            style: AppTextStyles.heading2.copyWith(
                              color: gradient.colors.first,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}