// lib/features/admin_availability_pricing/presentation/widgets/date_options_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../pages/availability_pricing_page.dart';
import '../../domain/entities/availability.dart';
import '../../domain/entities/pricing.dart';
import '../bloc/pricing/pricing_bloc.dart';

class DateOptionsSheet extends StatefulWidget {
  final DateTime date;
  final ViewMode viewMode;
  final Function(AvailabilityStatus) onUpdateAvailability;
  final void Function(double price, PriceType priceType, PricingTier pricingTier, bool overwriteExisting) onUpdatePricing;

  const DateOptionsSheet({
    super.key,
    required this.date,
    required this.viewMode,
    required this.onUpdateAvailability,
    required this.onUpdatePricing,
  });

  @override
  State<DateOptionsSheet> createState() => _DateOptionsSheetState();
}

class _DateOptionsSheetState extends State<DateOptionsSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  AvailabilityStatus? _selectedStatus;
  double? _price;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  PriceType _priceType = PriceType.custom;
  PricingTier _pricingTier = PricingTier.normal;
  bool _overwriteExisting = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
              0, MediaQuery.of(context).size.height * _slideAnimation.value),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.darkCard,
                  AppTheme.darkCard.withOpacity(0.95),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHandle(),
                    _buildHeader(),
                    _buildContent(),
                    _buildActions(),
                    SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppTheme.darkBorder.withOpacity(0.5),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.viewMode == ViewMode.availability
                  ? Icons.event_available_rounded
                  : Icons.attach_money_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.date.day}/${widget.date.month}/${widget.date.year}',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.viewMode == ViewMode.availability
                      ? 'تحديث حالة الإتاحة'
                      : 'تحديث السعر',
                  style: AppTextStyles.bodySmall.copyWith(
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

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: widget.viewMode == ViewMode.availability
          ? _buildAvailabilityContent()
          : _buildPricingContent(),
    );
  }

  Widget _buildAvailabilityContent() {
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
        ...statuses.map((item) {
          final isSelected = _selectedStatus == item.$1;
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedStatus = item.$1;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          item.$3.withOpacity(0.2),
                          item.$3.withOpacity(0.1),
                        ],
                      )
                    : null,
                color:
                    !isSelected ? AppTheme.darkSurface.withOpacity(0.5) : null,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? item.$3
                      : AppTheme.darkBorder.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(item.$4, color: item.$3, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    item.$2,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected ? item.$3 : AppTheme.textWhite,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: item.$3.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: item.$3,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
          decoration: InputDecoration(
            labelText: 'ملاحظات (اختياري)',
            labelStyle:
                AppTextStyles.bodySmall.copyWith(color: AppTheme.textMuted),
            hintText: 'أضف أي ملاحظات',
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
        ),
      ],
    );
  }

  Widget _buildPricingContent() {
    final currencyCode = _resolveCurrencyCode();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'السعر لليوم',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTextStyles.heading2.copyWith(color: AppTheme.primaryBlue),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: AppTextStyles.heading2.copyWith(
              color: AppTheme.textMuted.withOpacity(0.3),
            ),
            prefixIcon: Icon(
              Icons.attach_money_rounded,
              color: AppTheme.primaryBlue,
              size: 28,
            ),
            suffixText: currencyCode,
            suffixStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
            filled: true,
            fillColor: AppTheme.primaryBlue.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.primaryBlue.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.primaryBlue.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.primaryBlue.withOpacity(0.5),
                width: 2,
              ),
            ),
          ),
          onChanged: (value) {
            _price = double.tryParse(value);
          },
        ),
        const SizedBox(height: 16),
        Text(
          'نوع السعر',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<PriceType>(
          value: _priceType,
          dropdownColor: AppTheme.darkCard,
          style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
          items: const [
            DropdownMenuItem(value: PriceType.base, child: Text('أساسي')),
            DropdownMenuItem(value: PriceType.weekend, child: Text('نهاية الأسبوع')),
            DropdownMenuItem(value: PriceType.seasonal, child: Text('موسمي')),
            DropdownMenuItem(value: PriceType.holiday, child: Text('عطلة')),
            DropdownMenuItem(value: PriceType.specialEvent, child: Text('مناسبة خاصة')),
            DropdownMenuItem(value: PriceType.custom, child: Text('مخصص')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _priceType = v);
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.darkSurface.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.darkBorder.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.darkBorder.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.5)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'مستوى التسعير',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<PricingTier>(
          value: _pricingTier,
          dropdownColor: AppTheme.darkCard,
          style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
          items: const [
            DropdownMenuItem(value: PricingTier.discount, child: Text('خصم')),
            DropdownMenuItem(value: PricingTier.normal, child: Text('عادي')),
            DropdownMenuItem(value: PricingTier.high, child: Text('مرتفع')),
            DropdownMenuItem(value: PricingTier.peak, child: Text('ذروة')),
            DropdownMenuItem(value: PricingTier.custom, child: Text('مخصص')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _pricingTier = v);
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.darkSurface.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.darkBorder.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.darkBorder.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.5)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
                Icons.info_outline_rounded,
                color: AppTheme.info,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'سيتم تطبيق هذا السعر على التاريخ المحدد فقط',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textWhite.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
                child: Text(
                  'استبدال أي قاعدة تسعير موجودة لهذا اليوم',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
              Switch(
                value: _overwriteExisting,
                onChanged: (v) => setState(() => _overwriteExisting = v),
                activeThumbColor: AppTheme.warning,
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
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
              onTap: _handleApply,
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
                  child: Text(
                    'تطبيق',
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

  void _handleApply() {
    if (widget.viewMode == ViewMode.availability) {
      if (_selectedStatus != null) {
        widget.onUpdateAvailability(_selectedStatus!);
        Navigator.of(context).pop();
      }
    } else {
      if (_price != null && _price! > 0) {
        widget.onUpdatePricing(_price!, _priceType, _pricingTier, _overwriteExisting);
        Navigator.of(context).pop();
      }
    }
  }

  String _resolveCurrencyCode() {
    try {
      final pricingState = context.read<PricingBloc>().state;
      if (pricingState is PricingLoaded) {
        return pricingState.unitPricing.currency;
      }
    } catch (_) {}
    return 'YER';
  }
}
