// lib/features/admin_availability_pricing/presentation/widgets/futuristic_calendar_view.dart

import 'package:bookn_cp_app/features/admin_availability_pricing/domain/entities/availability.dart';
import 'package:bookn_cp_app/features/admin_availability_pricing/domain/entities/pricing.dart';
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
import 'availability_calendar_grid.dart';
import 'pricing_calendar_grid.dart';
import 'date_options_sheet.dart';
import 'date_range_options_sheet.dart';

class FuturisticCalendarView extends StatefulWidget {
  final ViewMode viewMode;
  final DateTime currentDate;
  final Function(DateTime) onDateChanged;
  final bool isCompact;
  // New: external persistent selection (from parent/page)
  final DateTime? selectionStart;
  final DateTime? selectionEnd;
  // New: notify parent when selection committed (via drag or long-press)
  final void Function(DateTime start, DateTime end, bool fromLongPress)?
      onSelectionChanged;

  const FuturisticCalendarView({
    super.key,
    required this.viewMode,
    required this.currentDate,
    required this.onDateChanged,
    this.isCompact = false,
    this.selectionStart,
    this.selectionEnd,
    this.onSelectionChanged,
  });

  @override
  State<FuturisticCalendarView> createState() => _FuturisticCalendarViewState();
}

class _FuturisticCalendarViewState extends State<FuturisticCalendarView>
    with TickerProviderStateMixin {
  late AnimationController _calendarAnimationController;
  late AnimationController _glowController;
  late Animation<double> _calendarFadeAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _calendarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _calendarFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _calendarAnimationController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _calendarAnimationController.forward();
  }

  @override
  void dispose() {
    _calendarAnimationController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withOpacity(0.7),
                AppTheme.darkCard.withOpacity(0.5),
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
                    .withOpacity(0.1 * _glowAnimation.value),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                children: [
                  // Calendar header
                  _buildCalendarHeader(),

                  // Calendar body
                  Expanded(
                    child: FadeTransition(
                      opacity: _calendarFadeAnimation,
                      child: _buildCalendarBody(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendarHeader() {
    final dateFormat = DateFormat('MMMM yyyy', 'ar');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkSurface.withOpacity(0.6),
            AppTheme.darkSurface.withOpacity(0.4),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Previous month button
          _buildNavigationButton(
            icon: Icons.chevron_left_rounded,
            onTap: _previousMonth,
          ),

          const SizedBox(width: 16),

          // Current month/year
          Expanded(
            child: Center(
              child: ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.primaryGradient.createShader(bounds),
                child: Text(
                  dateFormat.format(widget.currentDate),
                  style: AppTextStyles.heading3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Next month button
          _buildNavigationButton(
            icon: Icons.chevron_right_rounded,
            onTap: _nextMonth,
          ),

          const SizedBox(width: 16),

          // Today button
          _buildTodayButton(),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryBlue.withOpacity(0.2),
              AppTheme.primaryPurple.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildTodayButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _goToToday();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          'اليوم',
          style: AppTextStyles.buttonSmall.copyWith(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarBody() {
    if (widget.viewMode == ViewMode.both) {
      return _buildSplitView();
    } else if (widget.viewMode == ViewMode.availability) {
      return _buildAvailabilityView();
    } else {
      return _buildPricingView();
    }
  }

  Widget _buildSplitView() {
    return Row(
      children: [
        // Availability calendar
        Expanded(
          child: Column(
            children: [
              _buildSubHeader('الإتاحة', AppTheme.success),
              Expanded(
                child: _buildAvailabilityView(),
              ),
            ],
          ),
        ),

        // Divider
        Container(
          width: 1,
          margin: const EdgeInsets.symmetric(vertical: 16),
          color: AppTheme.darkBorder.withOpacity(0.3),
        ),

        // Pricing calendar
        Expanded(
          child: Column(
            children: [
              _buildSubHeader('التسعير', AppTheme.warning),
              Expanded(
                child: _buildPricingView(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubHeader(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityView() {
    return BlocBuilder<AvailabilityBloc, AvailabilityState>(
      builder: (context, state) {
        if (state is AvailabilityLoading) {
          return _buildLoadingState();
        }

        if (state is AvailabilityLoaded) {
          return AvailabilityCalendarGrid(
            unitAvailability: state.unitAvailability,
            currentDate: widget.currentDate,
            isCompact: widget.isCompact,
            selectionStart: widget.selectionStart,
            selectionEnd: widget.selectionEnd,
            onSelectionCommitted: (start, end, fromLongPress) {
              // Bubble to parent; parent will choose whether to open dialogs
              widget.onSelectionChanged?.call(start, end, fromLongPress);
            },
            onDateSelected: (date) =>
                _onDateSelected(date, ViewMode.availability),
            onDateRangeSelected: (start, end) =>
                _onDateRangeSelected(start, end, ViewMode.availability),
          );
        }

        if (state is AvailabilityError) {
          return _buildErrorState(state.message);
        }

        return _buildEmptyState();
      },
    );
  }

  Widget _buildPricingView() {
    return BlocBuilder<PricingBloc, PricingState>(
      builder: (context, state) {
        if (state is PricingLoading) {
          return _buildLoadingState();
        }

        if (state is PricingLoaded) {
          return PricingCalendarGrid(
            unitPricing: state.unitPricing,
            currentDate: widget.currentDate,
            isCompact: widget.isCompact,
            selectionStart: widget.selectionStart,
            selectionEnd: widget.selectionEnd,
            onSelectionCommitted: (start, end, fromLongPress) {
              widget.onSelectionChanged?.call(start, end, fromLongPress);
            },
            onDateSelected: (date) => _onDateSelected(date, ViewMode.pricing),
            onDateRangeSelected: (start, end) =>
                _onDateRangeSelected(start, end, ViewMode.pricing),
          );
        }

        if (state is PricingError) {
          return _buildErrorState(state.message);
        }

        return _buildEmptyState();
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated loading indicator
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'جاري التحميل...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppTheme.error.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _retry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'إعادة المحاولة',
                style: AppTextStyles.buttonSmall.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 48,
            color: AppTheme.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد بيانات للعرض',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'يرجى اختيار وحدة للبدء',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textMuted.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _previousMonth() {
    final newDate = DateTime(
      widget.currentDate.year,
      widget.currentDate.month - 1,
    );
    widget.onDateChanged(newDate);

    _calendarAnimationController.reset();
    _calendarAnimationController.forward();
  }

  void _nextMonth() {
    final newDate = DateTime(
      widget.currentDate.year,
      widget.currentDate.month + 1,
    );
    widget.onDateChanged(newDate);

    _calendarAnimationController.reset();
    _calendarAnimationController.forward();
  }

  void _goToToday() {
    final today = DateTime.now();
    widget.onDateChanged(DateTime(today.year, today.month));

    _calendarAnimationController.reset();
    _calendarAnimationController.forward();
  }

  void _retry() {
    // Get current selected unit ID from bloc state
    String? unitId;

    final availabilityState = context.read<AvailabilityBloc>().state;
    if (availabilityState is AvailabilityLoaded) {
      unitId = availabilityState.selectedUnitId;
    } else {
      final pricingState = context.read<PricingBloc>().state;
      if (pricingState is PricingLoaded) {
        unitId = pricingState.selectedUnitId;
      }
    }

    if (unitId != null) {
      // Reload data for current month
      if (widget.viewMode == ViewMode.availability ||
          widget.viewMode == ViewMode.both) {
        context.read<AvailabilityBloc>().add(
              LoadMonthlyAvailability(
                unitId: unitId,
                year: widget.currentDate.year,
                month: widget.currentDate.month,
              ),
            );
      }

      if (widget.viewMode == ViewMode.pricing ||
          widget.viewMode == ViewMode.both) {
        context.read<PricingBloc>().add(
              LoadMonthlyPricing(
                unitId: unitId,
                year: widget.currentDate.year,
                month: widget.currentDate.month,
              ),
            );
      }
    }
  }

  void _onDateSelected(DateTime date, ViewMode mode) {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DateOptionsSheet(
        date: date,
        viewMode: mode,
        onUpdateAvailability: (status) {
          _updateSingleDayAvailability(date, status);
        },
        onUpdatePricing: (price, priceType, pricingTier, overwrite) {
          _updateSingleDayPricing(
              date, price, priceType, pricingTier, overwrite);
        },
      ),
    );
  }

  void _onDateRangeSelected(DateTime start, DateTime end, ViewMode mode) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DateRangeOptionsSheet(
        startDate: start,
        endDate: end,
        viewMode: mode,
        onUpdateAvailability: (status, overwrite) {
          _updateDateRangeAvailability(start, end, status, overwrite);
        },
        onUpdatePricing: (price, overwrite) {
          _updateDateRangePricing(start, end, price, overwrite);
        },
      ),
    );
  }

  void _updateSingleDayAvailability(DateTime date, AvailabilityStatus status) {
    final state = context.read<AvailabilityBloc>().state;
    if (state is AvailabilityLoaded) {
      context.read<AvailabilityBloc>().add(
            UpdateSingleDayAvailability(
              unitId: state.selectedUnitId,
              date: date,
              status: status,
            ),
          );
    }
  }

  void _updateSingleDayPricing(
    DateTime date,
    double price,
    PriceType priceType,
    PricingTier pricingTier,
    bool overwrite,
  ) {
    final state = context.read<PricingBloc>().state;
    if (state is PricingLoaded) {
      final currencyCode = state.unitPricing.currency;
      context.read<PricingBloc>().add(
            UpdateSingleDayPricing(
              unitId: state.selectedUnitId,
              date: date,
              price: price,
              priceType: priceType,
              pricingTier: pricingTier,
              currency: currencyCode,
              overwriteExisting: overwrite,
            ),
          );
    }
  }

  void _updateDateRangeAvailability(
      DateTime start, DateTime end, AvailabilityStatus status, bool overwrite) {
    final state = context.read<AvailabilityBloc>().state;
    if (state is AvailabilityLoaded) {
      context.read<AvailabilityBloc>().add(
            BulkUpdateAvailability(
              unitId: state.selectedUnitId,
              startDate: start,
              endDate: end,
              status: status,
              overwriteExisting: overwrite,
            ),
          );
    }
  }

  void _updateDateRangePricing(
      DateTime start, DateTime end, double price, bool overwrite) {
    final state = context.read<PricingBloc>().state;
    if (state is PricingLoaded) {
      final currencyCode = state.unitPricing.currency;
      context.read<PricingBloc>().add(
            UpdateDateRangePricing(
              unitId: state.selectedUnitId,
              startDate: start,
              endDate: end,
              price: price,
              currency: currencyCode,
              overwriteExisting: overwrite,
            ),
          );
    }
  }
}
