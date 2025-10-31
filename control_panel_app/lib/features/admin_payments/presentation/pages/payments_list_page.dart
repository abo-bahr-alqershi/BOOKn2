// lib/features/admin_payments/presentation/pages/payments_list_page.dart

import 'package:bookn_cp_app/features/admin_payments/presentation/bloc/payments_list/payments_list_bloc.dart';
import 'package:bookn_cp_app/features/admin_payments/presentation/bloc/payments_list/payments_list_event.dart';
import 'package:bookn_cp_app/features/admin_payments/presentation/bloc/payments_list/payments_list_state.dart';
import 'package:bookn_cp_app/features/admin_payments/domain/entities/payment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart'; // 🎯 للـ haptic feedback
import 'package:go_router/go_router.dart'; // 🎯 للـ navigation
import 'dart:ui'; // 🎯 للـ blur effect
import '../widgets/futuristic_payments_table.dart';
import '../widgets/payment_filters_widget.dart';
import '../widgets/payment_stats_cards.dart';
import '../widgets/refund_dialog.dart'; // 🎯 إضافة
import '../../../admin_bookings/presentation/widgets/booking_confirmation_dialog.dart';
import '../widgets/void_payment_dialog.dart'; // 🎯 إضافة
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/empty_widget.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class PaymentsListPage extends StatefulWidget {
  const PaymentsListPage({super.key});

  @override
  State<PaymentsListPage> createState() => _PaymentsListPageState();
}

class _PaymentsListPageState extends State<PaymentsListPage>
    with TickerProviderStateMixin {
  // 🎯 تغيير إلى TickerProviderStateMixin
  late AnimationController _animationController;
  late AnimationController _pulseAnimationController; // 🎯 للـ pulse animation
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _showFilters = false;
  bool _isGridView = false; // 🎯 إضافة grid view option
  DateTime? _defaultStart;
  DateTime? _defaultEnd;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // 🎯 إضافة pulse animation controller
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    // Load payments with default last 30 days window for trends
    final now = DateTime.now();
    final last30 = now.subtract(const Duration(days: 30));
    _defaultStart = last30;
    _defaultEnd = now;

    _loadPayments();
    _setupScrollListener(); // 🎯 إضافة scroll listener
  }

  void _loadPayments() {
    final start =
        _defaultStart ?? DateTime.now().subtract(const Duration(days: 30));
    final end = _defaultEnd ?? DateTime.now();
    final authState = context.read<AuthBloc>().state;
    bool isOwner = false;
    String? ownerPropertyId;
    if (authState is AuthAuthenticated) {
      isOwner = authState.user.isOwner;
      ownerPropertyId = authState.user.propertyId;
    } else if (authState is AuthLoginSuccess) {
      isOwner = authState.user.isOwner;
      ownerPropertyId = authState.user.propertyId;
    } else if (authState is AuthProfileUpdateSuccess) {
      isOwner = authState.user.isOwner;
      ownerPropertyId = authState.user.propertyId;
    } else if (authState is AuthProfileImageUploadSuccess) {
      isOwner = authState.user.isOwner;
      ownerPropertyId = authState.user.propertyId;
    }

    context.read<PaymentsListBloc>().add(LoadPaymentsEvent(
          startDate: start,
          endDate: end,
          propertyId: isOwner && (ownerPropertyId ?? '').isNotEmpty
              ? ownerPropertyId
              : null,
        ));
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        // Load more when near bottom
        final state = context.read<PaymentsListBloc>().state;
        if (state is PaymentsListLoaded && state.payments.hasNextPage) {
          context.read<PaymentsListBloc>().add(
                ChangePageEvent(pageNumber: state.payments.currentPage + 1),
              );
        }
      }
    });
  }

  Widget _buildTrendNote(PaymentsListLoaded state) {
    final start = _defaultStart;
    final end = _defaultEnd;
    if (start == null || end == null) return const SizedBox.shrink();
    final days = end.difference(start).inDays;
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          'الاتجاهات محسوبة لآخر $days يومًا',
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseAnimationController.dispose(); // 🎯 تنظيف
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              context
                  .read<PaymentsListBloc>()
                  .add(const RefreshPaymentsEvent());
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                _buildSliverAppBar(), // 🎯 SliverAppBar مثل الحجوزات
                _buildStatsSection(),
                _buildFilterSection(),
                // ✅ Payments List - spread multiple slivers
                ..._buildPaymentsListSlivers(),
              ],
            ),
          ),
          // Overlay progress while an operation (e.g., refund) is in progress
          BlocBuilder<PaymentsListBloc, PaymentsListState>(
            builder: (context, state) {
              if (state is PaymentOperationInProgress) {
                return Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: const Center(
                      child: LoadingWidget(
                        type: LoadingType.futuristic,
                        message: 'جاري تنفيذ عملية الاسترداد...',
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      floatingActionButton:
          _buildEnhancedFloatingActionButton(), // 🎯 تحسين الزر العائم
    );
  }

  // 🎯 SliverAppBar مثل الحجوزات تماماً
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: AppTheme.darkBackground,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Text(
          'المدفوعات',
          style: AppTextStyles.heading1.copyWith(
            color: AppTheme.textWhite,
            shadows: [
              Shadow(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryBlue.withOpacity(0.1),
                AppTheme.darkBackground,
              ],
            ),
          ),
        ),
      ),
      actions: [
        _buildActionButton(
          icon: _isGridView
              ? CupertinoIcons.list_bullet
              : CupertinoIcons.square_grid_2x2,
          onPressed: () => setState(() => _isGridView = !_isGridView),
        ),

        // 🎯 أزرار تحليلات المدفوعات ولوحة الإيرادات
        _buildAnalyticsButton(),
        _buildRevenueButton(),

        _buildActionButton(
          icon: _showFilters
              ? CupertinoIcons.xmark
              : CupertinoIcons.slider_horizontal_3,
          onPressed: () => setState(() => _showFilters = !_showFilters),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // 🎯 زر Analytics المميز (مثل Timeline في الحجوزات)
  Widget _buildAnalyticsButton() {
    return AnimatedBuilder(
      animation: _pulseAnimationController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Stack(
            children: [
              // Background with gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryPurple.withOpacity(0.2),
                      AppTheme.primaryViolet.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryPurple.withOpacity(
                      0.3 + (_pulseAnimationController.value * 0.2),
                    ),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withOpacity(
                        0.1 * _pulseAnimationController.value,
                      ),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push('/admin/payments/analytics');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        CupertinoIcons.chart_bar_alt_fill,
                        color: AppTheme.primaryPurple,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),

              // Pulse indicator
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.neonPurple,
                        AppTheme.primaryViolet,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.neonPurple.withOpacity(
                          0.6 * _pulseAnimationController.value,
                        ),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🎯 زر لوحة الإيرادات المميز
  Widget _buildRevenueButton() {
    return AnimatedBuilder(
      animation: _pulseAnimationController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.success.withOpacity(0.2),
                      AppTheme.neonGreen.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.success.withOpacity(
                      0.3 + (_pulseAnimationController.value * 0.2),
                    ),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.success.withOpacity(
                        0.1 * _pulseAnimationController.value,
                      ),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push('/admin/payments/revenue-dashboard');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        CupertinoIcons.chart_pie_fill,
                        color: AppTheme.success,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🎯 أزرار الأكشن
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.darkCard.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.darkBorder.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: AppTheme.textWhite,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  // 🎯 قسم الإحصائيات
  Widget _buildStatsSection() {
    return BlocBuilder<PaymentsListBloc, PaymentsListState>(
      builder: (context, state) {
        if (state is PaymentsListLoaded) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: PaymentStatsCards(
                statistics: {
                  ...state.statistics,
                  if (state.stats != null) ...state.stats!,
                },
              ),
            ),
          );
        }
        return const SliverToBoxAdapter(child: SizedBox());
      },
    );
  }

  // 🎯 قسم الفلاتر
  Widget _buildFilterSection() {
    return SliverToBoxAdapter(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _showFilters ? 120 : 0,
        child: _showFilters
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: PaymentFiltersWidget(),
              )
            : const SizedBox(),
      ),
    );
  }

  // 🎯 قائمة المدفوعات - إرجاع عدة Slivers بدلاً من واحد
  List<Widget> _buildPaymentsListSlivers() {
    return [
      BlocBuilder<PaymentsListBloc, PaymentsListState>(
        buildWhen: (previous, current) {
          // منع إعادة البناء عند الانتقال من Loaded إلى LoadingMore
          if (previous is PaymentsListLoaded &&
              current is PaymentsListLoadingMore) {
            return false;
          }
          // السماح بإعادة البناء عند الانتقال من LoadingMore إلى Loaded
          if (previous is PaymentsListLoadingMore &&
              current is PaymentsListLoaded) {
            return true;
          }
          return true;
        },
        builder: (context, state) {
          if (state is PaymentsListLoading) {
            return const SliverFillRemaining(
              child: LoadingWidget(
                type: LoadingType.futuristic,
                message: 'جاري تحميل المدفوعات...',
              ),
            );
          }

          if (state is PaymentsListError) {
            return SliverFillRemaining(
              child: CustomErrorWidget(
                message: state.message,
                type: ErrorType.general,
                onRetry: () {
                  context.read<PaymentsListBloc>().add(
                        const RefreshPaymentsEvent(),
                      );
                },
              ),
            );
          }

          // 🎯 عرض المحتوى للحالة Loaded أو LoadingMore
          final payments = _getCurrentPayments(state);
          if (payments == null) {
            return const SliverToBoxAdapter(child: SizedBox());
          }

          if (payments.isEmpty) {
            return const SliverFillRemaining(
              child: EmptyWidget(
                message: 'لا توجد مدفوعات',
                icon: CupertinoIcons.money_dollar_circle,
              ),
            );
          }

          // ✅ عرض الجدول بدون AnimatedSwitcher للحفاظ على ثبات الشجرة وتجنب الوميض
          return SliverToBoxAdapter(
            key: const ValueKey('payments_table'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FuturisticPaymentsTable(
                payments: payments,
                onPaymentTap: (payment) {
                  context.push('/admin/payments/${payment.id}');
                },
                onRefundTap: context.select((AuthBloc bloc) {
                  final s = bloc.state;
                  final isAdmin = s is AuthAuthenticated
                      ? s.user.isAdmin
                      : s is AuthLoginSuccess
                          ? s.user.isAdmin
                          : s is AuthProfileUpdateSuccess
                              ? s.user.isAdmin
                              : s is AuthProfileImageUploadSuccess
                                  ? s.user.isAdmin
                                  : false;
                  final isOwner = s is AuthAuthenticated
                      ? s.user.isOwner
                      : s is AuthLoginSuccess
                          ? s.user.isOwner
                          : s is AuthProfileUpdateSuccess
                              ? s.user.isOwner
                              : s is AuthProfileImageUploadSuccess
                                  ? s.user.isOwner
                                  : false;
                  return isAdmin
                      ? _showRefundDialog
                      : isOwner
                          ? null
                          : null;
                }),
                onVoidTap: context.select((AuthBloc bloc) {
                  final s = bloc.state;
                  final isAdmin = s is AuthAuthenticated
                      ? s.user.isAdmin
                      : s is AuthLoginSuccess
                          ? s.user.isAdmin
                          : s is AuthProfileUpdateSuccess
                              ? s.user.isAdmin
                              : s is AuthProfileImageUploadSuccess
                                  ? s.user.isAdmin
                                  : false;
                  final isOwner = s is AuthAuthenticated
                      ? s.user.isOwner
                      : s is AuthLoginSuccess
                          ? s.user.isOwner
                          : s is AuthProfileUpdateSuccess
                              ? s.user.isOwner
                              : s is AuthProfileImageUploadSuccess
                                  ? s.user.isOwner
                                  : false;
                  return isAdmin
                      ? _showVoidConfirmation
                      : isOwner
                          ? null
                          : null;
                }),
              ),
            ),
          );
        },
      ),

      // ✅ Progress Bar منفصل تماماً - يظهر فقط في حالة LoadingMore
      BlocBuilder<PaymentsListBloc, PaymentsListState>(
        builder: (context, state) {
          if (state is PaymentsListLoadingMore) {
            return const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: LoadingWidget(
                    type: LoadingType.futuristic,
                    message: 'جاري تحميل المزيد...',
                  ),
                ),
              ),
            );
          }
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        },
      ),
    ];
  }

  // Helper method to get current payments from state
  List<Payment>? _getCurrentPayments(PaymentsListState state) {
    if (state is PaymentsListLoaded) {
      return state.payments.items;
    } else if (state is PaymentsListLoadingMore) {
      return state.payments.items;
    } else if (state is PaymentOperationInProgress) {
      return state.payments.items;
    } else if (state is PaymentOperationSuccess) {
      return state.payments.items;
    } else if (state is PaymentOperationFailure) {
      return state.payments.items;
    }
    return null;
  }

  Widget _buildContentBody(
    PaymentsListLoaded state,
    bool isSmallScreen,
    bool isMediumScreen,
    double? tableHeight,
    BoxConstraints constraints,
  ) {
    // للشاشات الصغيرة، نستخدم SingleChildScrollView
    if (isSmallScreen) {
      return SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Stats Cards
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLarge,
              ),
              child: PaymentStatsCards(
                statistics: {
                  ...state.statistics,
                  if (state.stats != null) ...state.stats!,
                },
              ),
            ),
            if (_defaultStart != null && _defaultEnd != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLarge,
                ),
                child: _buildTrendNote(state),
              ),
            const SizedBox(height: AppDimensions.spaceMedium),

            // Payments Table - مع ارتفاع محدد للموبايل
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: SizedBox(
                height: constraints.maxHeight * 0.5, // نصف الشاشة
                child: FuturisticPaymentsTable(
                  payments: state.payments.items,
                  onPaymentTap: (payment) {
                    // 🎯 استخدام GoRouter push للإضافة إلى المكدس
                    context.push('/admin/payments/${payment.id}');
                  },
                  onRefundTap: context.select((AuthBloc bloc) {
                    final s = bloc.state;
                    final isAdmin = s is AuthAuthenticated
                        ? s.user.isAdmin
                        : s is AuthLoginSuccess
                            ? s.user.isAdmin
                            : s is AuthProfileUpdateSuccess
                                ? s.user.isAdmin
                                : s is AuthProfileImageUploadSuccess
                                    ? s.user.isAdmin
                                    : false;
                    final isOwner = s is AuthAuthenticated
                        ? s.user.isOwner
                        : s is AuthLoginSuccess
                            ? s.user.isOwner
                            : s is AuthProfileUpdateSuccess
                                ? s.user.isOwner
                                : s is AuthProfileImageUploadSuccess
                                    ? s.user.isOwner
                                    : false;
                    return isAdmin
                        ? _showRefundDialog
                        : isOwner
                            ? null
                            : null;
                  }),
                  onVoidTap: context.select((AuthBloc bloc) {
                    final s = bloc.state;
                    final isAdmin = s is AuthAuthenticated
                        ? s.user.isAdmin
                        : s is AuthLoginSuccess
                            ? s.user.isAdmin
                            : s is AuthProfileUpdateSuccess
                                ? s.user.isAdmin
                                : s is AuthProfileImageUploadSuccess
                                    ? s.user.isAdmin
                                    : false;
                    final isOwner = s is AuthAuthenticated
                        ? s.user.isOwner
                        : s is AuthLoginSuccess
                            ? s.user.isOwner
                            : s is AuthProfileUpdateSuccess
                                ? s.user.isOwner
                                : s is AuthProfileImageUploadSuccess
                                    ? s.user.isOwner
                                    : false;
                    return isAdmin
                        ? _showVoidConfirmation
                        : isOwner
                            ? null
                            : null;
                  }),
                ),
              ),
            ),

            // Pagination
            if (state.payments.hasNextPage)
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                child: _buildLoadMoreButton(),
              ),
          ],
        ),
      );
    }

    // للشاشات الأكبر، نستخدم CustomScrollView
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Stats Cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLarge,
            ),
            child: PaymentStatsCards(
              statistics: {
                ...state.statistics,
                if (state.stats != null) ...state.stats!,
              },
            ),
          ),
        ),
        if (_defaultStart != null && _defaultEnd != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLarge,
              ),
              child: _buildTrendNote(state),
            ),
          ),

        const SliverToBoxAdapter(
          child: SizedBox(height: AppDimensions.spaceMedium),
        ),

        // Payments Table - استخدام SliverFillRemaining
        SliverFillRemaining(
          hasScrollBody: false,
          fillOverscroll: false,
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: FuturisticPaymentsTable(
              payments: state.payments.items,
              height: tableHeight, // تحديد الارتفاع
              onPaymentTap: (payment) {
                // 🎯 استخدام GoRouter push للإضافة إلى المكدس
                context.push('/admin/payments/${payment.id}');
              },
              onRefundTap: context.select((AuthBloc bloc) {
                final s = bloc.state;
                final isAdmin = s is AuthAuthenticated
                    ? s.user.isAdmin
                    : s is AuthLoginSuccess
                        ? s.user.isAdmin
                        : s is AuthProfileUpdateSuccess
                            ? s.user.isAdmin
                            : s is AuthProfileImageUploadSuccess
                                ? s.user.isAdmin
                                : false;
                return isAdmin ? _showRefundDialog : null;
              }),
              onVoidTap: context.select((AuthBloc bloc) {
                final s = bloc.state;
                final isAdmin = s is AuthAuthenticated
                    ? s.user.isAdmin
                    : s is AuthLoginSuccess
                        ? s.user.isAdmin
                        : s is AuthProfileUpdateSuccess
                            ? s.user.isAdmin
                            : s is AuthProfileImageUploadSuccess
                                ? s.user.isAdmin
                                : false;
                return isAdmin ? _showVoidConfirmation : null;
              }),
            ),
          ),
        ),

        // Pagination
        if (state.payments.hasNextPage)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: Center(
                child: _buildLoadMoreButton(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadMoreButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 14,
        ),
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        onPressed: () {
          final state = context.read<PaymentsListBloc>().state;
          if (state is PaymentsListLoaded) {
            context.read<PaymentsListBloc>().add(
                  ChangePageEvent(
                    pageNumber: state.payments.currentPage + 1,
                  ),
                );
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.arrow_down_circle,
              color: AppTheme.primaryBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'تحميل المزيد',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🎯 إظهار نافذة الاسترداد المخصصة
  void _showRefundDialog(payment) {
    HapticFeedback.mediumImpact();
    showCupertinoModalPopup(
      context: context,
      builder: (_) => RefundDialog(
        payment: payment,
        onRefund: (amount, reason) {
          Navigator.pop(context);
          // تأكيد بنفس تصميم ديالوج تأكيد/إلغاء الحجز
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (ctx) => BookingConfirmationDialog(
              type: BookingConfirmationType.confirm,
              bookingId: payment.bookingId,
              bookingReference: '#${payment.transactionId}',
              customTitle: 'تأكيد الاسترداد؟',
              customSubtitle:
                  'سيتم استرداد ${amount.currency} ${amount.amount.toStringAsFixed(2)} للمعاملة #${payment.transactionId}',
              customConfirmText: 'تأكيد الاسترداد',
              onConfirm: () {
                context.read<PaymentsListBloc>().add(
                      RefundPaymentEvent(
                        paymentId: payment.id,
                        refundAmount: amount,
                        refundReason: reason,
                      ),
                    );
              },
            ),
          );
        },
      ),
    );
  }

  // 🎯 إظهار نافذة إلغاء المعاملة المخصصة
  void _showVoidConfirmation(payment) {
    HapticFeedback.heavyImpact();
    showCupertinoModalPopup(
      context: context,
      builder: (_) => VoidPaymentDialog(
        payment: payment,
        onVoid: () {
          Navigator.pop(context);
          context.read<PaymentsListBloc>().add(
                VoidPaymentEvent(paymentId: payment.id),
              );
        },
      ),
    );
  }

  // 🎯 Floating Action Button المحسّن (مثل الحجوزات)
  Widget _buildEnhancedFloatingActionButton() {
    return AnimatedBuilder(
      animation: _pulseAnimationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(
                  0.2 + (_pulseAnimationController.value * 0.1),
                ),
                blurRadius: 12 + (_pulseAnimationController.value * 4),
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.read<PaymentsListBloc>().add(
                    const ExportPaymentsEvent(format: ExportFormat.excel),
                  );
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: const Icon(CupertinoIcons.arrow_down_doc, size: 20),
            label: Text(
              'تصدير',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppTheme.textWhiteAlways,
              ),
            ),
          ),
        );
      },
    );
  }
}
