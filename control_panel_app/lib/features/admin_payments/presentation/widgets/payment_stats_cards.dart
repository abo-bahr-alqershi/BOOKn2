import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'; // 🎯 للـ haptic feedback
import 'dart:ui';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/theme/app_dimensions.dart';
import '../../../../../../core/widgets/glassmorphic_tooltip.dart'; // 🎯 tooltip

class PaymentStatsCards extends StatefulWidget {
  final Map<String, dynamic> statistics;
  final String currency;

  const PaymentStatsCards({
    super.key,
    required this.statistics,
    this.currency = 'YER',
  });

  @override
  State<PaymentStatsCards> createState() => _PaymentStatsCardsState();
}

class _PaymentStatsCardsState extends State<PaymentStatsCards>
    with TickerProviderStateMixin {
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _fadeAnimations;
  late AnimationController _countController;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _cardControllers = List.generate(
      4,
      (index) => AnimationController(
        duration: Duration(milliseconds: 500 + (index * 100)),
        vsync: this,
      ),
    );

    _scaleAnimations = _cardControllers.map((controller) {
      return Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      ));
    }).toList();

    _fadeAnimations = _cardControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeIn,
      ));
    }).toList();

    _countController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Start animations
    for (var controller in _cardControllers) {
      controller.forward();
    }
    _countController.forward();
  }

  @override
  void dispose() {
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double? _pct(Object? v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    final totalTrend = _pct(widget.statistics['totalPaymentsTrendPct']);
    final amountTrend = _pct(widget.statistics['totalAmountTrendPct']);
    final successTrend = _pct(widget.statistics['successfulPaymentsTrendPct']);
    final refundedTrend = _pct(widget.statistics['refundedPaymentsTrendPct']);

    return SizedBox(
      height: 130, // 🎯 مطابق للحجوزات
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 4),
        children: [
          _buildStatCard(
            index: 0,
            title: 'إجمالي المدفوعات',
            value: widget.statistics['totalPayments'] ?? 0,
            icon: CupertinoIcons.creditcard_fill,
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue,
                AppTheme.primaryBlue.withValues(alpha: 0.7),
              ],
            ),
            suffix: 'معاملة',
            trend: totalTrend,
          ),
          _buildStatCard(
            index: 1,
            title: 'إجمالي المبلغ',
            value: widget.statistics['totalAmount'] ?? 0,
            icon: CupertinoIcons.money_dollar_circle_fill,
            gradient: LinearGradient(
              colors: [
                AppTheme.success,
                AppTheme.success.withValues(alpha: 0.7),
              ],
            ),
            isCurrency: true,
            trend: amountTrend,
          ),
          _buildStatCard(
            index: 2,
            title: 'المدفوعات الناجحة',
            value: widget.statistics['successfulPayments'] ?? 0,
            icon: CupertinoIcons.checkmark_seal_fill,
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryPurple,
                AppTheme.primaryPurple.withValues(alpha: 0.7),
              ],
            ),
            suffix: 'معاملة',
            trend: successTrend,
          ),
          _buildStatCard(
            index: 3,
            title: 'المستردات',
            value: widget.statistics['refundedPayments'] ?? 0,
            icon: CupertinoIcons.arrow_counterclockwise_circle_fill,
            gradient: LinearGradient(
              colors: [
                AppTheme.warning,
                AppTheme.warning.withValues(alpha: 0.7),
              ],
            ),
            suffix: 'معاملة',
            trend: refundedTrend,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required int index,
    required String title,
    required dynamic value,
    required IconData icon,
    required Gradient gradient,
    String? suffix,
    bool isCurrency = false,
    double? trend,
  }) {
    final isPositive = trend != null && trend >= 0;
    final GlobalKey cardKey = GlobalKey(); // 🎯 GlobalKey للـ tooltip
    
    return GestureDetector(
      onLongPress: () { // 🎯 عرض tooltip عند النقر المطول
        HapticFeedback.mediumImpact();
        _showStatsTooltip(
          context: context,
          cardKey: cardKey,
          title: title,
          value: isCurrency
              ? '${_formatCurrency(value.toDouble())}'
              : '${_formatNumber(value.toDouble())}${suffix != null && !isCurrency ? " $suffix" : ""}',
          icon: icon,
          gradient: gradient,
          trend: trend,
          isPositive: isPositive,
        );
      },
      child: Container(
        key: cardKey, // 🎯 إضافة key
        width: 160, // 🎯 مطابق للحجوزات
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
                // Background Icon - 🎯 مثل الحجوزات
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
                      // Header Row - 🎯 مثل الحجوزات
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
                            if (trend != null && trend != 0)
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
                      const SizedBox(height: 4),
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
                      const SizedBox(height: 6),
                      // Value - 🎯 animated counter
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: value.toDouble()),
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeOut,
                        builder: (context, animatedValue, child) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Flexible(
                                child: Text(
                                  isCurrency
                                      ? _formatCurrency(animatedValue)
                                      : _formatNumber(animatedValue),
                                  style: AppTextStyles.heading2.copyWith(
                                    color: AppTheme.textWhite,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (suffix != null && !isCurrency) ...[
                                const SizedBox(width: 4),
                                Text(
                                  suffix,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ), // 🎯 closing GestureDetector
    );
  }

  // 🎯 دالة لعرض tooltip للـ stats
  void _showStatsTooltip({
    required BuildContext context,
    required GlobalKey cardKey,
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
    double? trend,
    bool? isPositive,
  }) {
    final descriptions = {
      'إجمالي المدفوعات': 'العدد الكلي للمعاملات المالية التي تمت معالجتها في النظام',
      'إجمالي المبلغ': 'مجموع جميع المبالغ المالية من المعاملات الناجحة',
      'المدفوعات الناجحة': 'عدد المعاملات التي تمت بنجاح واكتملت',
      'المستردات': 'عدد المعاملات التي تم استرداد مبالغها للعملاء',
    };

    String message = '📊 القيمة الحالية: $value\n\n';
    message += descriptions[title] ?? 'معلومات إحصائية عن $title';
    
    if (trend != null) {
      message += '\n\n📈 تفاصيل إضافية:';
      message += '\n• الفترة: آخر 30 يوماً';
      message += '\n• الحالة: ${isPositive == true ? "في تحسن ✅" : "في انخفاض ⚠️"}';
      message += '\n• نسبة التغيير: ${trend.abs().toStringAsFixed(1)}%';
    }

    GlasmorphicTooltip.show(
      context: context,
      targetKey: cardKey,
      title: title,
      message: message,
      accentColor: gradient.colors.first,
      icon: icon,
      duration: const Duration(seconds: 5),
    );
  }

  String _formatNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  String _formatCurrency(double value) {
    final currencySymbol = widget.currency;
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M $currencySymbol';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K $currencySymbol';
    }
    return '${value.toStringAsFixed(0)} $currencySymbol';
  }
}
