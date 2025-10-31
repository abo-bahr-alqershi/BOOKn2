// lib/features/admin_currencies/presentation/widgets/currency_stats_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/currency.dart';

class CurrencyStatsCard extends StatelessWidget {
  final List<Currency> currencies;
  final Map<String, dynamic>?
      stats; // backend-provided stats, similar to reviews
  final DateTime? startDate;
  final DateTime? endDate;

  const CurrencyStatsCard({
    super.key,
    required this.currencies,
    this.stats,
    this.startDate,
    this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final computed = _calculateStats();
    final total = _asInt(stats?['totalCurrencies']) ?? computed['total'] as int;
    final defCode = (stats?['defaultCurrencyCode'] as String?) ??
        (computed['default'] as String);
    final withRate = _asInt(stats?['currenciesWithExchangeRate']) ??
        (computed['withRate'] as int);
    final avgRate = _asDouble(stats?['averageExchangeRate']) ??
        double.parse(computed['avgRate'] as String);
    final lastUpdateStr =
        computed['lastUpdate'] as String; // keep nice formatting
    final updatesCount = _asInt(stats?['updatesCount']);
    final updatesTrend = _asDouble(stats?['updatesTrendPct']);

    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildStatCard(
            icon: CupertinoIcons.money_dollar_circle_fill,
            label: 'إجمالي العملات',
            value: total.toString(),
            gradient: [AppTheme.primaryCyan, AppTheme.primaryBlue],
          ),
          _buildStatCard(
            icon: CupertinoIcons.star_fill,
            label: 'العملة الافتراضية',
            value: defCode,
            gradient: [AppTheme.success, AppTheme.neonGreen],
          ),
          _buildStatCard(
            icon: CupertinoIcons.arrow_2_circlepath,
            label: 'متوسط سعر الصرف',
            value: avgRate.toStringAsFixed(4),
            gradient: [AppTheme.primaryPurple, AppTheme.primaryViolet],
          ),
          _buildStatCard(
            icon: CupertinoIcons.clock_fill,
            label: 'آخر تحديث',
            value: lastUpdateStr,
            gradient: [AppTheme.warning, AppTheme.neonPurple],
          ),
          // Only show trends if backend provided and window present
          if (updatesCount != null || updatesTrend != null)
            _buildTrendCard(
              icon: CupertinoIcons.chart_bar_fill,
              label: 'تحديثات آخر 30 يوم',
              value: (updatesCount ?? 0).toString(),
              trendPct: updatesTrend,
              gradient: [AppTheme.info, AppTheme.neonBlue],
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required List<Color> gradient,
  }) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.2),
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
                  gradient.first.withValues(alpha: 0.15),
                  gradient.last.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: gradient.first.withValues(alpha: 0.3),
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
                    icon,
                    size: 100,
                    color: gradient.first.withValues(alpha: 0.05),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradient),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          icon,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value,
                            style: AppTextStyles.heading2.copyWith(
                              color: gradient.first,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            label,
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

  Widget _buildTrendCard({
    required IconData icon,
    required String label,
    required String value,
    required List<Color> gradient,
    double? trendPct,
  }) {
    final trendColor = trendPct == null
        ? AppTheme.textWhite.withValues(alpha: 0.8)
        : (trendPct >= 0 ? AppTheme.success : AppTheme.error);
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.2),
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
                  gradient.first.withValues(alpha: 0.15),
                  gradient.last.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: gradient.first.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Padding(
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
                          gradient: LinearGradient(colors: gradient),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, size: 18, color: Colors.white),
                      ),
                      if (trendPct != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: trendColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                trendPct >= 0
                                    ? CupertinoIcons.arrow_up_right
                                    : CupertinoIcons.arrow_down_right,
                                color: trendColor,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${trendPct.abs().toStringAsFixed(1)}%',
                                style: AppTextStyles.caption.copyWith(
                                  color: trendColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: AppTextStyles.heading2.copyWith(
                          color: gradient.first,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
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
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateStats() {
    Currency? defaultCurrency;
    if (currencies.isNotEmpty) {
      final maybeDefault = currencies.where((c) => c.isDefault);
      defaultCurrency =
          maybeDefault.isNotEmpty ? maybeDefault.first : currencies.first;
    } else {
      defaultCurrency = null;
    }

    final ratesCount = currencies.where((c) => c.exchangeRate != null).length;
    final avgRate = ratesCount > 0
        ? currencies
                .where((c) => c.exchangeRate != null)
                .map((c) => c.exchangeRate!)
                .reduce((a, b) => a + b) /
            ratesCount
        : 0.0;

    final lastUpdated = currencies
        .where((c) => c.lastUpdated != null)
        .map((c) => c.lastUpdated!)
        .fold<DateTime?>(null, (prev, date) {
      if (prev == null) return date;
      return date.isAfter(prev) ? date : prev;
    });

    return {
      'total': currencies.length,
      'default': defaultCurrency?.arabicCode ?? 'غير محدد',
      'withRate': ratesCount,
      'avgRate': avgRate.toStringAsFixed(2),
      'lastUpdate': lastUpdated != null
          ? '${lastUpdated.day}/${lastUpdated.month}'
          : 'غير محدد',
    };
  }

  int? _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  double? _asDouble(Object? v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
