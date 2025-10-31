// lib/features/admin_cities/presentation/widgets/city_stats_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class CityStatsCard extends StatelessWidget {
  final Map<String, dynamic> statistics;
  final int citiesCount;

  const CityStatsCard({
    super.key,
    required this.statistics,
    required this.citiesCount,
  });

  @override
  Widget build(BuildContext context) {
    double numb(Object? v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    final stats = [
      _StatItem(
        icon: CupertinoIcons.building_2_fill,
        label: 'إجمالي المدن',
        value: citiesCount.toString(),
        gradient: [AppTheme.primaryBlue, AppTheme.primaryCyan],
        trend: numb(statistics['updatesTrendPct']),
      ),
      _StatItem(
        icon: CupertinoIcons.house_fill,
        label: 'العقارات',
        value: (statistics['totalProperties'] ?? 0).toString(),
        gradient: [AppTheme.primaryPurple, AppTheme.primaryViolet],
        trend: numb(statistics['propertiesTrend']),
      ),
      _StatItem(
        icon: CupertinoIcons.checkmark_circle_fill,
        label: 'مدن نشطة',
        value: (statistics['activeCities'] ?? statistics['active'] ?? 0)
            .toString(),
        gradient: [AppTheme.success, AppTheme.neonGreen],
        trend: numb(statistics['activeTrend']),
      ),
      _StatItem(
        icon: CupertinoIcons.photo_fill,
        label: 'الصور',
        value: _formatNumber((statistics['totalImages'] ?? 0) is int
            ? (statistics['totalImages'] as int)
            : int.tryParse('${statistics['totalImages']}') ?? 0),
        gradient: [AppTheme.warning, AppTheme.neonPurple],
        trend: numb(statistics['imagesTrend']),
      ),
    ];

    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          return _buildStatCard(stat);
        },
      ),
    );
  }

  Widget _buildStatCard(_StatItem stat) {
    final isPositive = stat.trend >= 0;

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: stat.gradient.first.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
                  stat.gradient.first.withValues(alpha: 0.15),
                  stat.gradient.last.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: stat.gradient.first.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // Background Icon
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    stat.icon,
                    size: 100,
                    color: stat.gradient.first.withValues(alpha: 0.05),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Icon and Trend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: stat.gradient,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: stat.gradient.first
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              stat.icon,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          if (stat.trend != 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
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
                                    size: 10,
                                    color: isPositive
                                        ? AppTheme.success
                                        : AppTheme.error,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${stat.trend.abs().toStringAsFixed(1)}%',
                                    style: AppTextStyles.caption.copyWith(
                                      color: isPositive
                                          ? AppTheme.success
                                          : AppTheme.error,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      // Value and Label
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stat.value,
                            style: AppTextStyles.heading2.copyWith(
                              color: stat.gradient.first,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stat.label,
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final List<Color> gradient;
  final double trend;

  _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
    required this.trend,
  });
}
