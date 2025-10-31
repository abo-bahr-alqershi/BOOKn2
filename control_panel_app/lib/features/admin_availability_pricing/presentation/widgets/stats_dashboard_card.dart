// lib/features/admin_availability_pricing/presentation/widgets/stats_dashboard_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../bloc/availability/availability_bloc.dart';
import '../bloc/pricing/pricing_bloc.dart';
import '../pages/availability_pricing_page.dart';

class StatsDashboardCard extends StatefulWidget {
  final ViewMode viewMode;

  const StatsDashboardCard({
    super.key,
    required this.viewMode,
  });

  @override
  State<StatsDashboardCard> createState() => _StatsDashboardCardState();
}

class _StatsDashboardCardState extends State<StatsDashboardCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _countController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _countController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withOpacity(0.7),
                AppTheme.darkCard.withOpacity(0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    Expanded(
                      child: widget.viewMode == ViewMode.availability
                          ? _buildAvailabilityStats()
                          : widget.viewMode == ViewMode.pricing
                              ? _buildPricingStats()
                              : _buildCombinedStats(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value * 0.1,
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'الإحصائيات',
          style: AppTextStyles.heading3.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.success.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'مباشر',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityStats() {
    return BlocBuilder<AvailabilityBloc, AvailabilityState>(
      builder: (context, state) {
        if (state is AvailabilityLoaded) {
          final stats = state.unitAvailability.stats;
          return Column(
            children: [
              _buildStatRow(
                icon: Icons.check_circle_rounded,
                label: 'أيام متاحة',
                value: stats.availableDays.toString(),
                total: stats.totalDays,
                color: AppTheme.success,
              ),
              const SizedBox(height: 16),
              _buildStatRow(
                icon: Icons.event_busy_rounded,
                label: 'أيام محجوزة',
                value: stats.bookedDays.toString(),
                total: stats.totalDays,
                color: AppTheme.warning,
              ),
              const SizedBox(height: 16),
              _buildStatRow(
                icon: Icons.block_rounded,
                label: 'أيام محظورة',
                value: stats.blockedDays.toString(),
                total: stats.totalDays,
                color: AppTheme.error,
              ),
              const SizedBox(height: 20),
              _buildOccupancyRate(stats.occupancyRate),
            ],
          );
        }
        return _buildLoadingState();
      },
    );
  }

  Widget _buildPricingStats() {
    return BlocBuilder<PricingBloc, PricingState>(
      builder: (context, state) {
        if (state is PricingLoaded) {
          final stats = state.unitPricing.stats;
          return Column(
            children: [
              _buildPriceCard(
                label: 'متوسط السعر',
                value: stats.averagePrice,
                icon: Icons.analytics_rounded,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(height: 12),
              _buildPriceCard(
                label: 'أعلى سعر',
                value: stats.maxPrice,
                icon: Icons.trending_up_rounded,
                color: AppTheme.error,
              ),
              const SizedBox(height: 12),
              _buildPriceCard(
                label: 'أقل سعر',
                value: stats.minPrice,
                icon: Icons.trending_down_rounded,
                color: AppTheme.success,
              ),
              const SizedBox(height: 16),
              _buildRevenueCard(stats.potentialRevenue),
            ],
          );
        }
        return _buildLoadingState();
      },
    );
  }

  Widget _buildCombinedStats() {
    return SingleChildScrollView(
      child: Column(
        children: [
          BlocBuilder<AvailabilityBloc, AvailabilityState>(
            builder: (context, state) {
              if (state is AvailabilityLoaded) {
                return _buildMiniStatCard(
                  title: 'الإتاحة',
                  icon: Icons.event_available,
                  value: '${state.unitAvailability.stats.availableDays}',
                  subtitle: 'يوم متاح',
                  color: AppTheme.success,
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 12),
          BlocBuilder<PricingBloc, PricingState>(
            builder: (context, state) {
              if (state is PricingLoaded) {
                return _buildMiniStatCard(
                  title: 'التسعير',
                  icon: Icons.attach_money,
                  value: '${state.unitPricing.stats.averagePrice.toStringAsFixed(0)}',
                  subtitle: 'متوسط السعر',
                  color: AppTheme.primaryPurple,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required int total,
    required Color color,
  }) {
    final percentage = (int.parse(value) / total * 100);
    
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _countController,
                    builder: (context, child) {
                      final animatedValue = (_countController.value * int.parse(value)).round();
                      return Text(
                        '$animatedValue',
                        style: AppTextStyles.heading3.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  Text(
                    ' / $total',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 4,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${percentage.toStringAsFixed(0)}%',
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOccupancyRate(double rate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.1),
            AppTheme.primaryPurple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${(rate * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.heading3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'معدل الإشغال',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'للشهر الحالي',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard({
    required String label,
    required double value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                Text(
                  '${value.toStringAsFixed(0)} ريال',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(double revenue) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.monetization_on_rounded,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الإيرادات المحتملة',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                Text(
                  '${revenue.toStringAsFixed(0)} ريال',
                  style: AppTextStyles.heading3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard({
    required String title,
    required IconData icon,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      value,
                      style: AppTextStyles.heading3.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        color: AppTheme.primaryBlue,
        strokeWidth: 2,
      ),
    );
  }
}