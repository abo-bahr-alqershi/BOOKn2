// lib/features/admin_availability_pricing/presentation/pages/availability_pricing_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import 'package:intl/intl.dart';
import '../bloc/availability/availability_bloc.dart';
import '../bloc/pricing/pricing_bloc.dart';
import '../widgets/futuristic_calendar_view.dart';
import '../widgets/unit_selector_card.dart';
import '../widgets/property_selector_card.dart';
import '../widgets/stats_dashboard_card.dart';
import '../widgets/quick_actions_panel.dart';
// Removed legends as per request
import '../widgets/bulk_update_dialog.dart';
import '../widgets/copy_pricing_dialog.dart';
import '../../../../core/widgets/glassmorphic_tooltip.dart';

class AvailabilityPricingPage extends StatefulWidget {
  const AvailabilityPricingPage({super.key});

  @override
  State<AvailabilityPricingPage> createState() =>
      _AvailabilityPricingPageState();
}

class _AvailabilityPricingPageState extends State<AvailabilityPricingPage>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _backgroundAnimationController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late AnimationController _contentAnimationController;

  // Animations
  late Animation<double> _backgroundRotation;
  late Animation<double> _glowAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;

  // State
  ViewMode _viewMode = ViewMode.availability;
  bool _showStats = false;
  String? _selectedUnitId;
  String? _selectedUnitName;
  String? _selectedPropertyId;
  String? _selectedPropertyName;
  DateTime _currentDate = DateTime.now();
  final GlobalKey _legendIconKey = GlobalKey();

  // New: persist selection range across dialogs until context changes
  DateTime? _selectionStart;
  DateTime? _selectionEnd;

  // Particles for background
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateParticles();
    _startAnimations();

    // Load initial data
    _loadInitialData();
  }

  void _initializeAnimations() {
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _backgroundRotation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _backgroundAnimationController,
      curve: Curves.linear,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _contentFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutQuart),
    ));
  }

  void _generateParticles() {
    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle());
    }
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _contentAnimationController.forward();
      }
    });
  }

  void _loadInitialData() {
    // Do not preselect any unit or fetch data by default
    _selectedUnitId = null;
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _contentAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > AppDimensions.desktopBreakpoint;
    final isTablet = size.width > AppDimensions.tabletBreakpoint;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          // Animated background
          _buildAnimatedBackground(),

          // Particles
          _buildParticles(),

          // Main content
          _buildMainContent(isDesktop, isTablet),
        ],
      ),
    );
  }

  Widget _buildAvailabilityQuickStats() {
    return BlocBuilder<AvailabilityBloc, AvailabilityState>(
      builder: (context, state) {
        if (state is AvailabilityLoaded) {
          final stats = state.unitAvailability.stats;
          return Row(
            children: [
              _buildStatChip(
                icon: Icons.check_circle,
                value: '${stats.availableDays}',
                label: 'متاح',
                color: AppTheme.success,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                icon: Icons.event_busy,
                value: '${stats.bookedDays}',
                label: 'محجوز',
                color: AppTheme.warning,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                icon: Icons.block,
                value: '${stats.blockedDays}',
                label: 'محظور',
                color: AppTheme.error,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                icon: Icons.build_rounded,
                value: '${stats.maintenanceDays}',
                label: 'صيانة',
                color: AppTheme.info,
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPricingQuickStats() {
    return BlocBuilder<PricingBloc, PricingState>(
      builder: (context, state) {
        if (state is PricingLoaded) {
          final stats = state.unitPricing.stats;
          final base = state.unitPricing.basePrice;
          final currency = state.unitPricing.currency;

          final avgColor = _priceDeltaColor(stats.averagePrice, base);
          final minColor = _priceDeltaColor(stats.minPrice, base);
          final maxColor = _priceDeltaColor(stats.maxPrice, base);

          return Row(
            children: [
              _buildStatChip(
                icon: Icons.show_chart_rounded,
                value: _formatMoney(stats.averagePrice, currency),
                label: 'متوسط',
                color: avgColor,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                icon: Icons.trending_down_rounded,
                value: _formatMoney(stats.minPrice, currency),
                label: 'أقل',
                color: minColor,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                icon: Icons.trending_up_rounded,
                value: _formatMoney(stats.maxPrice, currency),
                label: 'أعلى',
                color: maxColor,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                icon: Icons.auto_awesome_rounded,
                value: '${stats.daysWithSpecialPricing}',
                label: 'أيام مميزة',
                color: AppTheme.primaryPurple,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                icon: Icons.payments_rounded,
                value: _formatMoney(stats.potentialRevenue, currency),
                label: 'العائد',
                color: AppTheme.primaryBlue,
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  String _formatMoney(double value, String currency) {
    try {
      final f = NumberFormat('#,##0');
      return '${f.format(value)} $currency';
    } catch (_) {
      return '$value $currency';
    }
  }

  Color _priceDeltaColor(double price, double basePrice) {
    if (basePrice <= 0) return AppTheme.textMuted;
    final pct = ((price - basePrice) / basePrice) * 100.0;
    if (pct > 20) return const Color(0xFF7C3AED); // Purple (high)
    if (pct > 10) return const Color(0xFFF59E0B); // Orange
    if (pct > 0) return const Color(0xFFFBBF24);  // Yellow
    if (pct == 0) return const Color(0xFF10B981); // Green
    if (pct > -10) return const Color(0xFF60A5FA); // Light Blue
    return const Color(0xFF3B82F6);               // Blue
  }

  Widget _buildLegendHelpIcon() {
    return GestureDetector(
      onTap: _showLegendTooltip,
      child: Container(
        key: _legendIconKey,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkSurface.withOpacity(0.6),
              AppTheme.darkSurface.withOpacity(0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppTheme.primaryBlue.withOpacity(0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.info_outline_rounded,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showLegendTooltip() {
    final accent = _viewMode == ViewMode.availability
        ? AppTheme.success
        : _viewMode == ViewMode.pricing
            ? const Color(0xFF7C3AED)
            : AppTheme.primaryBlue;

    final title = _viewMode == ViewMode.availability
        ? 'دليل ألوان الإتاحة'
        : _viewMode == ViewMode.pricing
            ? 'دليل ألوان التسعير'
            : 'دليل الألوان';

    final message = _buildLegendMessage(_viewMode);

    GlasmorphicTooltip.show(
      context: context,
      targetKey: _legendIconKey,
      title: title,
      message: message,
      accentColor: accent,
      icon: Icons.palette_rounded,
      duration: const Duration(seconds: 8),
      dismissOnTap: true,
    );
  }

  String _buildLegendMessage(ViewMode mode) {
    if (mode == ViewMode.availability) {
      return (
        '• متاح: أخضر يوحي بإمكانية الحجز\n'
        '• محجوز: برتقالي يدل على عدم التوفر\n'
        '• محظور: أحمر لحجب اليوم\n'
        '• صيانة: أزرق لأيام الصيانة'
      );
    }

    if (mode == ViewMode.pricing) {
      return (
        'الألوان تعبّر عن الفرق مقارنة بالسعر الأساسي:\n\n'
        '• أرجواني (#7C3AED): أعلى من الأساسي بأكثر من 20%\n'
        '• برتقالي (#F59E0B): أعلى من الأساسي بين 10% و20%\n'
        '• أصفر (#FBBF24): أعلى من الأساسي حتى 10%\n'
        '• أخضر (#10B981): مساوي للسعر الأساسي\n'
        '• أزرق فاتح (#60A5FA): أقل من الأساسي حتى 10%\n'
        '• أزرق (#3B82F6): أقل من الأساسي بأكثر من 10%'
      );
    }

    // ViewMode.both
    return (
      'الإتاحة:\n'
      '• متاح: أخضر — قابل للحجز\n'
      '• محجوز: برتقالي — مشغول\n'
      '• محظور: أحمر — غير متاح\n'
      '• صيانة: أزرق — خارج الخدمة\n\n'
      'التسعير (مقارنة بالسعر الأساسي):\n'
      '• أرجواني (#7C3AED): +20% فأكثر\n'
      '• برتقالي (#F59E0B): +10% إلى +20%\n'
      '• أصفر (#FBBF24): 0% إلى +10%\n'
      '• أخضر (#10B981): 0%\n'
      '• أزرق فاتح (#60A5FA): 0% إلى −10%\n'
      '• أزرق (#3B82F6): أقل من −10%'
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _backgroundRotation,
        _glowAnimation,
      ]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkBackground,
                AppTheme.darkBackground2.withOpacity(0.8),
                AppTheme.darkBackground3.withOpacity(0.6),
              ],
            ),
          ),
          child: CustomPaint(
            painter: _BackgroundPainter(
              rotation: _backgroundRotation.value,
              glowIntensity: _glowAnimation.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            animationValue: _particleController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildMainContent(bool isDesktop, bool isTablet) {
    return SafeArea(
      child: FadeTransition(
        opacity: _contentFadeAnimation,
        child: SlideTransition(
          position: _contentSlideAnimation,
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: Column(
              children: [
                // Header
                _buildHeader(),

                const SizedBox(height: 20),

                // Main content area
                Expanded(
                  child: isDesktop
                      ? _buildDesktopLayout()
                      : _buildMobileLayout(isTablet),
                ),
              ],
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
            AppTheme.darkCard.withOpacity(0.7),
            AppTheme.darkCard.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title with gradient
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.primaryGradient.createShader(bounds),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'إدارة الإتاحة والتسعير',
                      style: AppTextStyles.heading2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Options then stats below
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildViewModeToggle(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: _buildQuickStats(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildLegendHelpIcon(),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsToggle() {
    final isOn = _showStats;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _showStats = !_showStats);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isOn
              ? AppTheme.success.withOpacity(0.15)
              : AppTheme.darkSurface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isOn
                ? AppTheme.success.withOpacity(0.4)
                : AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(isOn ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                size: 18, color: isOn ? AppTheme.success : AppTheme.textMuted),
            const SizedBox(width: 6),
            Text(
              isOn ? 'إخفاء الإحصائيات' : 'إظهار الإحصائيات',
              style: AppTextStyles.caption.copyWith(
                color: isOn ? AppTheme.success : AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkSurface.withOpacity(0.6),
            AppTheme.darkSurface.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          _buildModeButton(
            icon: Icons.event_available_rounded,
            label: 'الإتاحة',
            isSelected: _viewMode == ViewMode.availability,
            onTap: () => setState(() => _viewMode = ViewMode.availability),
          ),
          const SizedBox(width: 4),
          _buildModeButton(
            icon: Icons.attach_money_rounded,
            label: 'التسعير',
            isSelected: _viewMode == ViewMode.pricing,
            onTap: () => setState(() => _viewMode = ViewMode.pricing),
          ),
          const SizedBox(width: 4),
          _buildModeButton(
            icon: Icons.dashboard_rounded,
            label: 'كلاهما',
            isSelected: _viewMode == ViewMode.both,
            onTap: () => setState(() => _viewMode = ViewMode.both),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: !isSelected ? Colors.transparent : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppTheme.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? Colors.white : AppTheme.textMuted,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    if (_viewMode == ViewMode.availability) {
      return _buildAvailabilityQuickStats();
    }
    if (_viewMode == ViewMode.pricing) {
      return _buildPricingQuickStats();
    }
    // ViewMode.both: show both sets
    return Row(
      children: [
        _buildAvailabilityQuickStats(),
        const SizedBox(width: 12),
        _buildPricingQuickStats(),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left sidebar
        SizedBox(
          width: 320,
          child: Column(
            children: [
              // Unit selector
              // Property then Unit selectors
              PropertySelectorCard(
                selectedPropertyId: _selectedPropertyId,
                selectedPropertyName: _selectedPropertyName,
                onPropertySelected: (id, name) {
                  setState(() {
                    _selectedPropertyId = id;
                    _selectedPropertyName = name;
                    // Reset selected unit when property changes
                    _selectedUnitId = null;
                    _selectedUnitName = null;
                    // Clear selection when property changes
                    _selectionStart = null;
                    _selectionEnd = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              UnitSelectorCard(
                selectedUnitId: _selectedUnitId,
                selectedUnitName: _selectedUnitName,
                selectedPropertyId: _selectedPropertyId,
                onUnitSelected: (id, name) {
                  _onUnitSelectedWithName(id, name);
                  // Clear selection when unit changes
                  setState(() {
                    _selectionStart = null;
                    _selectionEnd = null;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Stats dashboard
              Expanded(
                child: StatsDashboardCard(
                  viewMode: _viewMode,
                ),
              ),

              const SizedBox(height: 16),

              // Quick actions
              QuickActionsPanel(
                viewMode: _viewMode,
                onActionTap: _handleQuickAction,
              ),
            ],
          ),
        ),

        const SizedBox(width: 20),

        // Main calendar area
        Expanded(
          child: Column(
            children: [
              // Calendar view
              Expanded(
                child: FuturisticCalendarView(
                  viewMode: _viewMode,
                  currentDate: _currentDate,
                  onDateChanged: _onDateChanged,
                  selectionStart: _selectionStart,
                  selectionEnd: _selectionEnd,
                  onSelectionChanged: (start, end, fromLongPress) {
                    setState(() {
                      _selectionStart = start;
                      _selectionEnd = end;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isTablet) {
    return Column(
      children: [
        // Unit selector (compact)
        // Property then Unit selectors (compact)
        PropertySelectorCard(
          selectedPropertyId: _selectedPropertyId,
          selectedPropertyName: _selectedPropertyName,
          onPropertySelected: (id, name) {
            setState(() {
              _selectedPropertyId = id;
              _selectedPropertyName = name;
              _selectedUnitId = null;
              _selectedUnitName = null;
              _selectionStart = null;
              _selectionEnd = null;
            });
          },
          isCompact: true,
        ),
        const SizedBox(height: 8),
        UnitSelectorCard(
          selectedUnitId: _selectedUnitId,
          selectedUnitName: _selectedUnitName,
          selectedPropertyId: _selectedPropertyId,
          onUnitSelected: (id, name) {
            _onUnitSelectedWithName(id, name);
            setState(() {
              _selectionStart = null;
              _selectionEnd = null;
            });
          },
          isCompact: true,
        ),

        const SizedBox(height: 12),

        // Calendar view
        Expanded(
          child: FuturisticCalendarView(
            viewMode: _viewMode,
            currentDate: _currentDate,
            onDateChanged: _onDateChanged,
            isCompact: !isTablet,
            selectionStart: _selectionStart,
            selectionEnd: _selectionEnd,
            onSelectionChanged: (start, end, fromLongPress) {
              setState(() {
                _selectionStart = start;
                _selectionEnd = end;
              });
            },
          ),
        ),

        const SizedBox(height: 12),

        // Quick actions (horizontal scroll)
        SizedBox(
          height: 60,
          child: QuickActionsPanel(
            viewMode: _viewMode,
            onActionTap: _handleQuickAction,
            isHorizontal: true,
          ),
        ),
      ],
    );
  }

  void _onUnitSelectedWithName(String unitId, String unitName) {
    setState(() {
      _selectedUnitId = unitId;
      _selectedUnitName = unitName;
    });
    context.read<AvailabilityBloc>().add(
          LoadMonthlyAvailability(
            unitId: unitId,
            year: _currentDate.year,
            month: _currentDate.month,
          ),
        );
    context.read<PricingBloc>().add(
          LoadMonthlyPricing(
            unitId: unitId,
            year: _currentDate.year,
            month: _currentDate.month,
          ),
        );
  }

  void _onDateChanged(DateTime date) {
    setState(() {
      _currentDate = date;
      // Clear selection when month changes
      _selectionStart = null;
      _selectionEnd = null;
    });

    if (_selectedUnitId != null) {
      context.read<AvailabilityBloc>().add(
            ChangeMonth(year: date.year, month: date.month),
          );

      context.read<PricingBloc>().add(
            ChangePricingMonth(year: date.year, month: date.month),
          );
    }
  }

  void _handleQuickAction(QuickAction action) {
    HapticFeedback.mediumImpact();

    switch (action) {
      case QuickAction.bulkUpdate:
        _showBulkUpdateDialog();
        break;
      case QuickAction.seasonalPricing:
        _showSeasonalPricingDialog();
        break;
      case QuickAction.cloneSettings:
        _showCloneSettingsDialog();
        break;
      case QuickAction.exportData:
        _exportData();
        break;
      case QuickAction.importData:
        _importData();
        break;
    }
  }

  void _showBulkUpdateDialog() {
    if (_selectedUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يرجى اختيار وحدة أولاً'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Pass current currency to dialog to avoid provider lookup inside dialog
    String? currencyCode;
    final ps = context.read<PricingBloc>().state;
    if (ps is PricingLoaded) currencyCode = ps.unitPricing.currency;

    BulkUpdateDialog.show(
      context,
      viewMode: _viewMode,
      unitId: _selectedUnitId!,
      initialStartDate: _selectionStart,
      initialEndDate: _selectionEnd,
      currencyCode: currencyCode,
    );
  }

  void _showSeasonalPricingDialog() {
    // Show seasonal pricing dialog
  }

  void _showCloneSettingsDialog() {
    if (_selectedUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يرجى اختيار وحدة أولاً'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    CopyPricingDialog.show(
      context,
      unitId: _selectedUnitId!,
      initialSourceStart: _selectionStart,
      initialSourceEnd: _selectionEnd,
      initialTargetStart: _selectionEnd ?? _selectionStart,
    );
  }

  void _exportData() {
    // Export data functionality
  }

  void _importData() {
    // Import data functionality
  }
}

// Enums
enum ViewMode {
  availability,
  pricing,
  both,
}

enum QuickAction {
  bulkUpdate,
  seasonalPricing,
  cloneSettings,
  exportData,
  importData,
}

// Background Painter
class _BackgroundPainter extends CustomPainter {
  final double rotation;
  final double glowIntensity;

  _BackgroundPainter({
    required this.rotation,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = AppTheme.primaryBlue.withOpacity(0.05);

    // Draw grid
    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw rotating glow
    final center = Offset(size.width / 2, size.height / 2);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.primaryBlue.withOpacity(0.1 * glowIntensity),
          AppTheme.primaryPurple.withOpacity(0.05 * glowIntensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 2));

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawCircle(center, size.width / 3, glowPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Particle class
class _Particle {
  late double x, y, vx, vy;
  late double radius;
  late Color color;

  _Particle() {
    reset();
  }

  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    vx = (math.Random().nextDouble() - 0.5) * 0.001;
    vy = (math.Random().nextDouble() - 0.5) * 0.001;
    radius = math.Random().nextDouble() * 2 + 1;

    final colors = [
      AppTheme.primaryBlue,
      AppTheme.primaryPurple,
      AppTheme.primaryCyan,
    ];
    color = colors[math.Random().nextInt(colors.length)];
  }

  void update() {
    x += vx;
    y += vy;

    if (x < 0 || x > 1) vx = -vx;
    if (y < 0 || y > 1) vy = -vy;
  }
}

// Particle painter
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;

  _ParticlePainter({
    required this.particles,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update();

      final paint = Paint()
        ..color = particle.color.withOpacity(0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
