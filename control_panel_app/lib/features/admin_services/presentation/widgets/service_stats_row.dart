// lib/features/admin_services/presentation/widgets/service_stats_row.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../utils/service_icons.dart';

class ServiceStatsRow extends StatelessWidget {
  final int totalServices;
  final int paidServices;

  const ServiceStatsRow({
    super.key,
    required this.totalServices,
    required this.paidServices,
  });

  @override
  Widget build(BuildContext context) {
    final int freeServices = (totalServices - paidServices).clamp(0, totalServices);
    final stats = [
      _StatItem(
        icon: Icons.room_service_rounded,
        label: 'إجمالي الخدمات',
        value: totalServices.toString(),
        gradient: [AppTheme.primaryBlue, AppTheme.primaryCyan],
        trend: 0,
      ),
      _StatItem(
        icon: Icons.attach_money_rounded,
        label: 'خدمات مدفوعة',
        value: paidServices.toString(),
        gradient: [AppTheme.success, AppTheme.neonGreen],
        trend: 0,
      ),
      _StatItem(
        icon: Icons.card_giftcard,
        label: 'خدمات مجانية',
        value: freeServices.toString(),
        gradient: [AppTheme.primaryPurple, AppTheme.primaryViolet],
        trend: 0,
      ),
      _StatItem(
        icon: Icons.palette_rounded,
        label: 'أيقونات متاحة',
        value: ServiceIcons.icons.length.toString(),
        gradient: [AppTheme.warning, AppTheme.neonPurple],
        trend: 0,
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
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    stat.icon,
                    size: 100,
                    color: stat.gradient.first.withValues(alpha: 0.05),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: stat.gradient),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: stat.gradient.first.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(stat.icon, size: 18, color: Colors.white),
                          ),
                        ],
                      ),
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

