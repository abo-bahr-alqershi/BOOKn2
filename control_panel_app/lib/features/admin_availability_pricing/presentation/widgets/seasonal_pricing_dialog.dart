// lib/features/admin_availability_pricing/presentation/widgets/seasonal_pricing_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/pricing.dart';
import '../../domain/entities/seasonal_pricing.dart';
import '../bloc/pricing/pricing_bloc.dart';
import '../../domain/usecases/pricing/apply_seasonal_pricing_usecase.dart';

class SeasonalPricingDialog extends StatefulWidget {
  final String unitId;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const SeasonalPricingDialog({
    super.key,
    required this.unitId,
    this.initialStartDate,
    this.initialEndDate,
  });

  static Future<void> show(
    BuildContext context, {
    required String unitId,
    DateTime? initialStartDate,
    DateTime? initialEndDate,
  }) async {
    return showDialog(
      fullscreenDialog: true,
      context: context,
      barrierDismissible: false,
      barrierColor: AppTheme.overlayDark,
      builder: (context) => SeasonalPricingDialog(
        unitId: unitId,
        initialStartDate: initialStartDate,
        initialEndDate: initialEndDate,
      ),
    );
  }

  @override
  State<SeasonalPricingDialog> createState() => _SeasonalPricingDialogState();
}

class _SeasonalPricingDialogState extends State<SeasonalPricingDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<SeasonTemplate> _templates = [
    SeasonTemplate(
      id: '1',
      name: 'موسم الصيف',
      icon: Icons.wb_sunny_rounded,
      color: AppTheme.warning,
      priceChange: 30,
      tier: PricingTier.high,
    ),
    SeasonTemplate(
      id: '2',
      name: 'موسم الشتاء',
      icon: Icons.ac_unit_rounded,
      color: AppTheme.info,
      priceChange: -15,
      tier: PricingTier.discount,
    ),
    SeasonTemplate(
      id: '3',
      name: 'الأعياد والمناسبات',
      icon: Icons.celebration_rounded,
      color: AppTheme.error,
      priceChange: 50,
      tier: PricingTier.peak,
    ),
    SeasonTemplate(
      id: '4',
      name: 'نهاية الأسبوع',
      icon: Icons.weekend_rounded,
      color: AppTheme.primaryPurple,
      priceChange: 20,
      tier: PricingTier.high,
    ),
  ];

  SeasonTemplate? _selectedTemplate;
  DateTime? _startDate;
  DateTime? _endDate;
  double _customPriceChange = 0;
  bool _isRecurring = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();

    // Prefill dates if provided
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate ?? widget.initialStartDate;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withOpacity(0.95),
                AppTheme.darkCard.withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTemplateSelector(),
                          const SizedBox(height: 24),
                          _buildDateRangeSelector(),
                          const SizedBox(height: 24),
                          _buildPriceAdjustment(),
                          const SizedBox(height: 24),
                          _buildRecurringOption(),
                        ],
                      ),
                    ),
                  ),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryPurple.withOpacity(0.1),
            AppTheme.primaryBlue.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'التسعير الموسمي',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'قم بتطبيق قوالب تسعير موسمية جاهزة',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close_rounded,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر قالب موسمي',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _templates.length,
          itemBuilder: (context, index) {
            final template = _templates[index];
            final isSelected = _selectedTemplate?.id == template.id;

            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedTemplate = template;
                  _customPriceChange = template.priceChange;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            template.color.withOpacity(0.3),
                            template.color.withOpacity(0.1),
                          ],
                        )
                      : null,
                  color: !isSelected
                      ? AppTheme.darkSurface.withOpacity(0.5)
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? template.color
                        : AppTheme.darkBorder.withOpacity(0.3),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      template.icon,
                      color: isSelected ? template.color : AppTheme.textMuted,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      template.name,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected ? template.color : AppTheme.textWhite,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: template.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${template.priceChange > 0 ? '+' : ''}${template.priceChange}%',
                        style: AppTextStyles.caption.copyWith(
                          color: template.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الفترة الزمنية',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                label: 'من تاريخ',
                value: _startDate,
                onTap: () => _selectDate(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateField(
                label: 'إلى تاريخ',
                value: _endDate,
                onTap: () => _selectDate(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkSurface.withOpacity(0.6),
              AppTheme.darkSurface.withOpacity(0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(width: 8),
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
                    value != null
                        ? '${value.day}/${value.month}/${value.year}'
                        : 'اختر التاريخ',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: value != null
                          ? AppTheme.textWhite
                          : AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceAdjustment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تعديل السعر',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    _customPriceChange > 0
                        ? Icons.trending_up_rounded
                        : _customPriceChange < 0
                            ? Icons.trending_down_rounded
                            : Icons.remove_rounded,
                    color: _customPriceChange > 0
                        ? AppTheme.error
                        : _customPriceChange < 0
                            ? AppTheme.success
                            : AppTheme.textMuted,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Slider(
                      value: _customPriceChange,
                      min: -50,
                      max: 100,
                      divisions: 30,
                      activeColor: _customPriceChange > 0
                          ? AppTheme.error
                          : AppTheme.success,
                      inactiveColor: AppTheme.darkBorder.withOpacity(0.3),
                      onChanged: (value) {
                        setState(() {
                          _customPriceChange = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _customPriceChange > 0
                          ? AppTheme.error.withOpacity(0.2)
                          : _customPriceChange < 0
                              ? AppTheme.success.withOpacity(0.2)
                              : AppTheme.textMuted.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_customPriceChange > 0 ? '+' : ''}${_customPriceChange.toStringAsFixed(0)}%',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _customPriceChange > 0
                            ? AppTheme.error
                            : _customPriceChange < 0
                                ? AppTheme.success
                                : AppTheme.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecurringOption() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.info.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.repeat_rounded,
            color: AppTheme.info,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تكرار سنوياً',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'تطبيق هذا التسعير في نفس الفترة كل عام',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isRecurring,
            onChanged: (value) {
              setState(() {
                _isRecurring = value;
              });
            },
            activeThumbColor: AppTheme.info,
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final canApply = _selectedTemplate != null &&
        _startDate != null &&
        _endDate != null &&
        !_isSubmitting;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkSurface.withOpacity(0.6),
            AppTheme.darkSurface.withOpacity(0.4),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _isSubmitting ? null : () => Navigator.of(context).pop(),
              child: Opacity(
                opacity: _isSubmitting ? 0.6 : 1,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.darkBorder.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'إلغاء',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: canApply ? _handleApply : null,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: canApply ? 1 : 0.6,
                child: Container(
                  height: 48,
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
                  child: Center(
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'تطبيق التسعير',
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate ?? DateTime.now());
    final first = DateTime.now().subtract(const Duration(days: 365));
    final last = DateTime.now().add(const Duration(days: 365 * 3));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              surface: AppTheme.darkCard,
              onSurface: AppTheme.textWhite,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && picked.isAfter(_endDate!)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
          if (_startDate != null && picked.isBefore(_startDate!)) {
            _startDate = picked;
          }
        }
      });
    }
  }

  Future<void> _handleApply() async {
    if (_selectedTemplate == null || _startDate == null || _endDate == null)
      return;
    if (_endDate!.isBefore(_startDate!)) return;

    HapticFeedback.selectionClick();

    setState(() => _isSubmitting = true);

    try {
      final days = _endDate!.difference(_startDate!).inDays + 1;
      // Resolve currency from pricing state
      String currencyCode = 'YER';
      try {
        final ps = context.read<PricingBloc>().state;
        if (ps is PricingLoaded) {
          currencyCode = ps.unitPricing.currency;
        }
      } catch (_) {}

      final season = SeasonalPricing(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        name: _selectedTemplate!.name,
        type: _selectedTemplate!.name,
        startDate: _startDate!,
        endDate: _endDate!,
        price: 0,
        percentageChange: _customPriceChange,
        currency: currencyCode,
        pricingTier: _selectedTemplate!.tier,
        priority: 1,
        description: 'Seasonal pricing via dialog',
        isActive: true,
        isRecurring: _isRecurring,
        daysCount: days,
        totalRevenuePotential: 0,
      );

      context.read<PricingBloc>().add(
            ApplySeasonalPricing(
              params: ApplySeasonalPricingParams(
                unitId: widget.unitId,
                seasons: [season],
                currency: currencyCode,
              ),
            ),
          );

      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class SeasonTemplate {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final double priceChange;
  final PricingTier tier;

  SeasonTemplate({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.priceChange,
    required this.tier,
  });
}
