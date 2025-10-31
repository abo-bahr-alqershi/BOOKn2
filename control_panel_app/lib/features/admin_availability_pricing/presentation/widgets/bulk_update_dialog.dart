// lib/features/admin_availability_pricing/presentation/widgets/bulk_update_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/availability/availability_bloc.dart';
import '../bloc/pricing/pricing_bloc.dart';
import '../pages/availability_pricing_page.dart';
import '../../domain/entities/availability.dart';
import '../../domain/entities/pricing.dart';

class BulkUpdateDialog extends StatefulWidget {
  final ViewMode viewMode;
  final String unitId;
  // New: optional initial dates to prefill form
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  // Optional: pass currency from caller to avoid provider dependency
  final String? currencyCode;

  const BulkUpdateDialog({
    super.key,
    required this.viewMode,
    required this.unitId,
    this.initialStartDate,
    this.initialEndDate,
    this.currencyCode,
  });

  static Future<void> show(
    BuildContext context, {
    required ViewMode viewMode,
    required String unitId,
    DateTime? initialStartDate,
    DateTime? initialEndDate,
    String? currencyCode,
  }) async {
    AvailabilityBloc? availabilityBloc;
    PricingBloc? pricingBloc;
    try {
      availabilityBloc = context.read<AvailabilityBloc>();
    } catch (_) {}
    try {
      pricingBloc = context.read<PricingBloc>();
    } catch (_) {}

    return showDialog(
      fullscreenDialog: true,
      context: context,
      barrierDismissible: false,
      barrierColor: AppTheme.overlayDark,
      useRootNavigator: false, // ensure we stay under the same navigator/providers
      builder: (dialogContext) {
        Widget child = BulkUpdateDialog(
          viewMode: viewMode,
          unitId: unitId,
          initialStartDate: initialStartDate,
          initialEndDate: initialEndDate,
          currencyCode: currencyCode,
        );

        final providers = <BlocProvider>[];
        if (availabilityBloc != null) {
          providers.add(BlocProvider.value(value: availabilityBloc));
        }
        if (pricingBloc != null) {
          providers.add(BlocProvider.value(value: pricingBloc));
        }

        if (providers.isNotEmpty) {
          child = MultiBlocProvider(providers: providers, child: child);
        }

        return child;
      },
    );
  }

  @override
  State<BulkUpdateDialog> createState() => _BulkUpdateDialogState();
}

class _BulkUpdateDialogState extends State<BulkUpdateDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  DateTime? _startDate;
  DateTime? _endDate;
  final List<int> _selectedWeekdays = [];

  // Availability fields
  AvailabilityStatus _availabilityStatus = AvailabilityStatus.available;
  String? _reason;
  String? _notes;

  // Pricing fields
  double _price = 0;
  PricingTier _pricingTier = PricingTier.normal;
  PriceType _priceType = PriceType.base;
  double? _percentageChange;
  String? _currencyCode;

  bool _overwriteExisting = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Prefill from initial dates if provided
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate ?? widget.initialStartDate;
    // Resolve currency from prop or pricing state if available
    if (widget.currencyCode != null) {
      _currencyCode = widget.currencyCode;
    } else {
      try {
        final ps = context.read<PricingBloc>().state;
        if (ps is PricingLoaded) {
          _currencyCode = ps.unitPricing.currency;
        }
      } catch (_) {}
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.transparent,
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                // Wider dialog with responsive constraints
                width: MediaQuery.of(context).size.width.clamp(600.0, 1000.0),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                  maxWidth: MediaQuery.of(context).size.width * 0.95,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.darkCard.withOpacity(0.95),
                      AppTheme.darkCard.withOpacity(0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.primaryBlue
                        .withOpacity(0.2 + 0.1 * _glowAnimation.value),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue
                          .withOpacity(0.2 * _glowAnimation.value),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
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
                            child: Form(
                              key: _formKey,
                              child: _buildFormContent(),
                            ),
                          ),
                        ),
                        _buildActions(),
                      ],
                    ),
                  ),
                ),
              );
            },
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
            AppTheme.primaryBlue.withOpacity(0.1),
            AppTheme.primaryPurple.withOpacity(0.05),
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
            child: Icon(
              widget.viewMode == ViewMode.availability
                  ? Icons.event_available_rounded
                  : widget.viewMode == ViewMode.pricing
                      ? Icons.attach_money_rounded
                      : Icons.dashboard_rounded,
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
                  widget.viewMode == ViewMode.availability
                      ? 'تحديث الإتاحة المجمع'
                      : widget.viewMode == ViewMode.pricing
                          ? 'تحديث التسعير المجمع'
                          : 'تحديث الإتاحة والتسعير',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'قم بتحديث فترة كاملة بنقرة واحدة',
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

  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateRangeSelector(),
        const SizedBox(height: 24),
        _buildWeekdaySelector(),
        const SizedBox(height: 24),
        if (widget.viewMode == ViewMode.availability)
          _buildAvailabilityFields()
        else if (widget.viewMode == ViewMode.pricing)
          _buildPricingFields()
        else ...[
          _buildAvailabilityFields(),
          const SizedBox(height: 24),
          _buildPricingFields(),
        ],
        const SizedBox(height: 24),
        _buildOverwriteOption(),
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
                        ? DateFormat('dd/MM/yyyy').format(value)
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

  Widget _buildWeekdaySelector() {
    const weekdays = [
      {'name': 'أحد', 'value': 0},
      {'name': 'إثنين', 'value': 1},
      {'name': 'ثلاثاء', 'value': 2},
      {'name': 'أربعاء', 'value': 3},
      {'name': 'خميس', 'value': 4},
      {'name': 'جمعة', 'value': 5},
      {'name': 'سبت', 'value': 6},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'أيام محددة (اختياري)',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'اترك الكل فارغ لتطبيق على جميع الأيام',
              child: Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: weekdays.map((day) {
            final isSelected = _selectedWeekdays.contains(day['value']);

            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  if (isSelected) {
                    _selectedWeekdays.remove(day['value']);
                  } else {
                    _selectedWeekdays.add(day['value'] as int);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.primaryGradient : null,
                  color: !isSelected
                      ? AppTheme.darkSurface.withOpacity(0.5)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withOpacity(0.3)
                        : AppTheme.darkBorder.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  day['name'] as String,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? Colors.white : AppTheme.textMuted,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAvailabilityFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'حالة الإتاحة',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildStatusSelector(),
        if (_availabilityStatus == AvailabilityStatus.blocked ||
            _availabilityStatus == AvailabilityStatus.maintenance) ...[
          const SizedBox(height: 16),
          _buildReasonField(),
        ],
        const SizedBox(height: 16),
        _buildNotesField(),
      ],
    );
  }

  Widget _buildStatusSelector() {
    final statuses = [
      (
        AvailabilityStatus.available,
        'متاح',
        AppTheme.success,
        Icons.check_circle
      ),
      (AvailabilityStatus.booked, 'محجوز', AppTheme.warning, Icons.event_busy),
      (AvailabilityStatus.blocked, 'محظور', AppTheme.error, Icons.block),
      (AvailabilityStatus.maintenance, 'صيانة', AppTheme.info, Icons.build),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statuses.map((item) {
        final isSelected = _availabilityStatus == item.$1;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _availabilityStatus = item.$1;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        item.$3.withOpacity(0.3),
                        item.$3.withOpacity(0.1),
                      ],
                    )
                  : null,
              color: !isSelected ? AppTheme.darkSurface.withOpacity(0.5) : null,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    isSelected ? item.$3 : AppTheme.darkBorder.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.$4,
                  size: 16,
                  color: isSelected ? item.$3 : AppTheme.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  item.$2,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? item.$3 : AppTheme.textMuted,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPricingFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPriceInput(),
        const SizedBox(height: 16),
        _buildPricingTierSelector(),
        const SizedBox(height: 16),
        _buildPriceTypeSelector(),
        const SizedBox(height: 16),
        _buildPercentageChangeInput(),
      ],
    );
  }

  Widget _buildPriceInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'السعر',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
          decoration: InputDecoration(
            hintText: 'أدخل السعر',
            hintStyle: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textMuted.withOpacity(0.5),
            ),
            prefixIcon: Icon(
              Icons.attach_money_rounded,
              color: AppTheme.primaryBlue,
              size: 20,
            ),
            suffixText: _currencyCode ?? 'YER',
            suffixStyle: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
            ),
            filled: true,
            fillColor: AppTheme.darkSurface.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.darkBorder.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.darkBorder.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.primaryBlue.withOpacity(0.5),
              ),
            ),
          ),
          onChanged: (value) {
            _price = double.tryParse(value) ?? 0;
          },
          validator: widget.viewMode == ViewMode.pricing
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'السعر مطلوب';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildPricingTierSelector() {
    final tiers = [
      (PricingTier.discount, 'خصم', AppTheme.success),
      (PricingTier.normal, 'عادي', AppTheme.primaryBlue),
      (PricingTier.high, 'مرتفع', AppTheme.warning),
      (PricingTier.peak, 'ذروة', AppTheme.error),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مستوى التسعير',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tiers.map((item) {
            final isSelected = _pricingTier == item.$1;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _pricingTier = item.$1;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            item.$3.withOpacity(0.3),
                            item.$3.withOpacity(0.1),
                          ],
                        )
                      : null,
                  color: !isSelected
                      ? AppTheme.darkSurface.withOpacity(0.5)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? item.$3
                        : AppTheme.darkBorder.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  item.$2,
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected ? item.$3 : AppTheme.textMuted,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceTypeSelector() {
    final types = [
      (PriceType.base, 'أساسي'),
      (PriceType.weekend, 'نهاية الأسبوع'),
      (PriceType.seasonal, 'موسمي'),
      (PriceType.holiday, 'عطلة'),
      (PriceType.specialEvent, 'مناسبة خاصة'),
      (PriceType.custom, 'مخصص'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع السعر',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<PriceType>(
          initialValue: _priceType,
          dropdownColor: AppTheme.darkCard,
          style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.darkSurface.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.darkBorder.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.darkBorder.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.primaryBlue.withOpacity(0.5),
              ),
            ),
          ),
          items: types.map((item) {
            return DropdownMenuItem(
              value: item.$1,
              child: Text(item.$2),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _priceType = value ?? PriceType.base;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPercentageChangeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نسبة التغيير (اختياري)',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          keyboardType: const TextInputType.numberWithOptions(
              decimal: true, signed: true),
          style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
          decoration: InputDecoration(
            hintText: 'مثال: +20 أو -15',
            hintStyle: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textMuted.withOpacity(0.5),
            ),
            prefixIcon: Icon(
              Icons.percent_rounded,
              color: AppTheme.primaryPurple,
              size: 20,
            ),
            suffixText: '%',
            suffixStyle: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
            ),
            filled: true,
            fillColor: AppTheme.darkSurface.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.darkBorder.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.darkBorder.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.primaryPurple.withOpacity(0.5),
              ),
            ),
          ),
          onChanged: (value) {
            _percentageChange = double.tryParse(value);
          },
        ),
      ],
    );
  }

  Widget _buildReasonField() {
    return TextFormField(
      style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
      decoration: InputDecoration(
        labelText: 'السبب',
        labelStyle: AppTextStyles.bodySmall.copyWith(color: AppTheme.textMuted),
        hintText: 'أدخل سبب عدم الإتاحة',
        hintStyle: AppTextStyles.bodySmall.copyWith(
          color: AppTheme.textMuted.withOpacity(0.5),
        ),
        filled: true,
        fillColor: AppTheme.darkSurface.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.5),
          ),
        ),
      ),
      onChanged: (value) {
        _reason = value;
      },
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      maxLines: 3,
      style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
      decoration: InputDecoration(
        labelText: 'ملاحظات',
        labelStyle: AppTextStyles.bodySmall.copyWith(color: AppTheme.textMuted),
        hintText: 'أضف أي ملاحظات إضافية',
        hintStyle: AppTextStyles.bodySmall.copyWith(
          color: AppTheme.textMuted.withOpacity(0.5),
        ),
        filled: true,
        fillColor: AppTheme.darkSurface.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.5),
          ),
        ),
      ),
      onChanged: (value) {
        _notes = value;
      },
    );
  }

  Widget _buildOverwriteOption() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.warning,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'استبدال البيانات الموجودة',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'سيتم استبدال أي بيانات موجودة في هذه الفترة',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _overwriteExisting,
            onChanged: (value) {
              setState(() {
                _overwriteExisting = value;
              });
            },
            activeThumbColor: AppTheme.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
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
              onTap: _isLoading ? null : () => Navigator.of(context).pop(),
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
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _isLoading ? null : _handleSubmit,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: _isLoading
                      ? LinearGradient(
                          colors: [
                            AppTheme.textMuted.withOpacity(0.3),
                            AppTheme.textMuted.withOpacity(0.2),
                          ],
                        )
                      : AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !_isLoading
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'تطبيق التحديثات',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
    final now = DateTime.now();
    final initial = isStart
        ? _startDate ?? widget.initialStartDate ?? now
        : _endDate ?? widget.initialEndDate ?? _startDate ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
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
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_startDate != null && _endDate!.isBefore(_startDate!)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('يرجى تحديد الفترة الزمنية'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Submit based on view mode
      if (widget.viewMode == ViewMode.availability ||
          widget.viewMode == ViewMode.both) {
        context.read<AvailabilityBloc>().add(
              BulkUpdateAvailability(
                unitId: widget.unitId,
                startDate: _startDate!,
                endDate: _endDate!,
                status: _availabilityStatus,
                weekdays: _selectedWeekdays.isEmpty ? null : _selectedWeekdays,
                reason: _reason,
                notes: _notes,
                overwriteExisting: _overwriteExisting,
              ),
            );
      }

      if (widget.viewMode == ViewMode.pricing ||
          widget.viewMode == ViewMode.both) {
        if (_price > 0) {
          context.read<PricingBloc>().add(
                BulkUpdatePricing(
                  unitId: widget.unitId,
                  startDate: _startDate!,
                  endDate: _endDate!,
                  price: _price,
                  priceType: _priceType,
                  pricingTier: _pricingTier,
                  percentageChange: _percentageChange,
                  weekdays:
                      _selectedWeekdays.isEmpty ? null : _selectedWeekdays,
                  overwriteExisting: _overwriteExisting,
                ),
              );
        }
      }

      // Listen for success/error states
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تم تطبيق التحديثات بنجاح'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      });
    }
  }
}
