// lib/features/admin_audit_logs/presentation/widgets/audit_log_stats_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/audit_log.dart';

class AuditLogStatsCard extends StatefulWidget {
  final List<AuditLog> auditLogs;
  final int totalCount;

  const AuditLogStatsCard({
    super.key,
    required this.auditLogs,
    required this.totalCount,
  });

  @override
  State<AuditLogStatsCard> createState() => _AuditLogStatsCardState();
}

class _AuditLogStatsCardState extends State<AuditLogStatsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _countAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _countAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return SizedBox(
      height: 130,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 4),
        children: [
          _buildStatCard(
            title: 'إجمالي السجلات',
            value: widget.totalCount,
            icon: CupertinoIcons.doc_text_fill,
            gradient: AppTheme.primaryGradient,
            trend: stats['totalTrend'] ?? 0,
          ),
          _buildStatCard(
            title: 'عمليات الإضافة',
            value: stats['createCount'] ?? 0,
            icon: CupertinoIcons.plus_circle_fill,
            gradient: LinearGradient(
              colors: [
                AppTheme.success,
                AppTheme.success.withValues(alpha: 0.7),
              ],
            ),
            trend: stats['createTrend'] ?? 0,
          ),
          _buildStatCard(
            title: 'عمليات التحديث',
            value: stats['updateCount'] ?? 0,
            icon: CupertinoIcons.pencil_circle_fill,
            gradient: LinearGradient(
              colors: [
                AppTheme.info,
                AppTheme.info.withValues(alpha: 0.7),
              ],
            ),
            trend: stats['updateTrend'] ?? 0,
          ),
          _buildStatCard(
            title: 'عمليات الحذف',
            value: stats['deleteCount'] ?? 0,
            icon: CupertinoIcons.trash_circle_fill,
            gradient: LinearGradient(
              colors: [
                AppTheme.error,
                AppTheme.error.withValues(alpha: 0.7),
              ],
            ),
            trend: stats['deleteTrend'] ?? 0,
          ),
          _buildStatCard(
            title: 'تسجيلات الدخول',
            value: stats['loginCount'] ?? 0,
            icon: CupertinoIcons.arrow_right_circle_fill,
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue,
                AppTheme.primaryCyan,
              ],
            ),
            trend: stats['loginTrend'] ?? 0,
          ),
          _buildStatCard(
            title: 'المستخدمون النشطون',
            value: stats['activeUsers'] ?? 0,
            icon: CupertinoIcons.person_2_fill,
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryPurple,
                AppTheme.primaryViolet,
              ],
            ),
            trend: stats['usersTrend'] ?? 0,
          ),
          _buildStatCard(
            title: 'العمليات البطيئة',
            value: stats['slowOperations'] ?? 0,
            icon: CupertinoIcons.exclamationmark_triangle_fill,
            gradient: LinearGradient(
              colors: [
                AppTheme.warning,
                AppTheme.warning.withValues(alpha: 0.7),
              ],
            ),
            trend: stats['slowTrend'] ?? 0,
            isWarning: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int value,
    required IconData icon,
    required Gradient gradient,
    required double trend,
    bool isWarning = false,
  }) {
    final isPositive = trend >= 0;

    return AnimatedBuilder(
      animation: _countAnimation,
      builder: (context, child) {
        return Container(
          width: 160,
          margin: const EdgeInsets.only(right: 12),
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
                    // Background Icon
                    Positioned(
                      right: -15,
                      top: -15,
                      child: Icon(
                        icon,
                        size: 80,
                        color: gradient.colors.first.withValues(alpha: 0.1),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header Row
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
                                      color: (isPositive && !isWarning
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
                                          color: isPositive && !isWarning
                                              ? AppTheme.success
                                              : AppTheme.error,
                                        ),
                                        const SizedBox(width: 1),
                                        Text(
                                          '${trend.abs().toStringAsFixed(1)}%',
                                          style: AppTextStyles.caption.copyWith(
                                            color: isPositive && !isWarning
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
                          // Title
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
                          // Animated Value
                          TweenAnimationBuilder<int>(
                            tween: IntTween(
                              begin: 0,
                              end: (value * _countAnimation.value).toInt(),
                            ),
                            duration: const Duration(milliseconds: 1500),
                            builder: (context, animatedValue, child) {
                              return Text(
                                _formatNumber(animatedValue),
                                style: AppTextStyles.heading2.copyWith(
                                  color: gradient.colors.first,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // Pulse Effect for Warning
                    if (isWarning && value > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.8, end: 1.2),
                          duration: const Duration(seconds: 1),
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppTheme.warning,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.warning
                                          .withValues(alpha: 0.6),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          onEnd: () {
                            if (mounted) setState(() {});
                          },
                        ),
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

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Map<String, dynamic> _calculateStats() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Today's stats
    final todayLogs =
        widget.auditLogs.where((log) => log.timestamp.isAfter(today)).toList();

    // Yesterday's stats
    final yesterdayLogs = widget.auditLogs
        .where((log) =>
            log.timestamp.isAfter(yesterday) && log.timestamp.isBefore(today))
        .toList();

    // Calculate counts
    final createCount = widget.auditLogs
        .where((log) => log.action.toLowerCase() == 'create')
        .length;
    final updateCount = widget.auditLogs
        .where((log) => log.action.toLowerCase() == 'update')
        .length;
    final deleteCount = widget.auditLogs
        .where((log) => log.action.toLowerCase() == 'delete')
        .length;
    final loginCount = widget.auditLogs
        .where((log) => log.action.toLowerCase() == 'login')
        .length;

    // Active users
    final activeUsers =
        widget.auditLogs.map((log) => log.userId).toSet().length;

    // Slow operations
    final slowOperations =
        widget.auditLogs.where((log) => log.isSlowOperation).length;

    // Calculate trends (simulated)
    final totalTrend = _calculateTrend(todayLogs.length, yesterdayLogs.length);

    return {
      'createCount': createCount,
      'updateCount': updateCount,
      'deleteCount': deleteCount,
      'loginCount': loginCount,
      'activeUsers': activeUsers,
      'slowOperations': slowOperations,
      'totalTrend': totalTrend,
      'createTrend': 12.5,
      'updateTrend': -5.3,
      'deleteTrend': 8.2,
      'loginTrend': 15.7,
      'usersTrend': 3.4,
      'slowTrend': slowOperations > 10 ? 25.0 : -10.0,
    };
  }

  double _calculateTrend(int current, int previous) {
    if (previous == 0) return current > 0 ? 100.0 : 0.0;
    return ((current - previous) / previous * 100);
  }
}
