// lib/features/admin_notifications/presentation/widgets/notifications_stats_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class NotificationsStatsCard extends StatelessWidget {
  final Map<String, int> stats;
  final DateTime? startDate;
  final DateTime? endDate;

  const NotificationsStatsCard({
    super.key,
    required this.stats,
    this.startDate,
    this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildStatCard(
            title: 'إجمالي الإشعارات',
            value: stats['total']?.toString() ?? '0',
            icon: CupertinoIcons.bell_fill,
            gradient: AppTheme.primaryGradient,
            trend: stats['totalTrend']?.toDouble() ?? 0,
          ),
          _buildStatCard(
            title: 'مُرسلة',
            value: stats['sent']?.toString() ?? '0',
            icon: CupertinoIcons.checkmark_circle_fill,
            gradient: LinearGradient(
              colors: [
                AppTheme.success,
                AppTheme.success.withValues(alpha: 0.7),
              ],
            ),
            trend: stats['sentTrend']?.toDouble() ?? 0,
          ),
          _buildStatCard(
            title: 'قيد الانتظار',
            value: stats['pending']?.toString() ?? '0',
            icon: CupertinoIcons.clock_fill,
            gradient: LinearGradient(
              colors: [
                AppTheme.warning,
                AppTheme.warning.withValues(alpha: 0.7),
              ],
            ),
            trend: stats['pendingTrend']?.toDouble() ?? 0,
          ),
          _buildStatCard(
            title: 'فشلت',
            value: stats['failed']?.toString() ?? '0',
            icon: CupertinoIcons.xmark_circle_fill,
            gradient: LinearGradient(
              colors: [
                AppTheme.error,
                AppTheme.error.withValues(alpha: 0.7),
              ],
            ),
            trend: stats['failedTrend']?.toDouble() ?? 0,
          ),
          _buildStatCard(
            title: 'معدل القراءة',
            value: '${stats['readRate'] ?? 0}%',
            icon: CupertinoIcons.eye_fill,
            gradient: LinearGradient(
              colors: [
                AppTheme.info,
                AppTheme.info.withValues(alpha: 0.7),
              ],
            ),
            trend: stats['readRateTrend']?.toDouble() ?? 0,
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
    required double trend,
  }) {
    final isPositive = trend >= 0;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.2),
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
                  gradient.colors.first.withValues(alpha: 0.15),
                  gradient.colors.last.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: gradient.colors.first.withValues(alpha: 0.3),
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
                    color: gradient.colors.first.withValues(alpha: 0.1),
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
                            if (trend != 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: (isPositive
                                          ? AppTheme.success
                                          : AppTheme.error)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isPositive
                                          ? CupertinoIcons.arrow_up_right
                                          : CupertinoIcons.arrow_down_right,
                                    size: 8,
                                      color: isPositive
                                          ? AppTheme.success
                                          : AppTheme.error,
                                    ),
                                    const SizedBox(width: 1),
                                    Text(
                                      '${trend.abs().toStringAsFixed(1)}%',
                                      style: AppTextStyles.caption.copyWith(
                                        color: isPositive
                                            ? AppTheme.success
                                            : AppTheme.error,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
