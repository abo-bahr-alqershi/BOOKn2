// lib/features/admin_reviews/presentation/pages/reviews_list_page.dart

import 'package:bookn_cp_app/core/widgets/loading_widget.dart';
import 'package:bookn_cp_app/features/admin_reviews/presentation/bloc/review_details/review_details_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/reviews_list/reviews_list_bloc.dart';
import '../widgets/review_stats_card.dart';
import '../widgets/review_filters_widget.dart';
import '../widgets/futuristic_review_card.dart';
import '../widgets/futuristic_reviews_table.dart';
import 'review_details_page.dart';
import 'package:bookn_cp_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bookn_cp_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:bookn_cp_app/features/auth/domain/entities/user.dart' as domain;

class ReviewsListPage extends StatefulWidget {
  const ReviewsListPage({super.key});

  @override
  State<ReviewsListPage> createState() => _ReviewsListPageState();
}

class _ReviewsListPageState extends State<ReviewsListPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isGridView = false;
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();

    _scrollController.addListener(() {
      final position = _scrollController.position;
      final nearBottom = position.pixels >= position.maxScrollExtent - 200;
      if (nearBottom) {
        // Attempt to load more only if current state suggests server-side pages exist
        final bloc = context.read<ReviewsListBloc>();
        final state = bloc.state;
        if (state is ReviewsListLoaded) {
          // If backend pagination is supported via metadata, we expect keys
          final meta = state.stats;
          final hasNext = _extractHasNextFromStats(meta) ?? false;
          final nextPage = _extractNextPageFromStats(meta);
          if (hasNext && nextPage != null) {
            final authState = context.read<AuthBloc>().state;
            domain.User? user;
            if (authState is AuthAuthenticated) user = authState.user;
            if (authState is AuthLoginSuccess) user = authState.user;
            if (authState is AuthProfileUpdateSuccess) user = authState.user;
            if (user != null &&
                user.isOwner &&
                (user.propertyId != null && user.propertyId!.isNotEmpty)) {
              bloc.add(LoadReviewsEvent(
                  propertyId: user.propertyId,
                  pageNumber: nextPage,
                  pageSize: 20));
            } else {
              bloc.add(LoadReviewsEvent(pageNumber: nextPage, pageSize: 20));
            }
          }
        }
      }
      setState(() {
        _showBackToTop = _scrollController.offset > 200;
      });
    });

    _loadReviews(pageNumber: 1, pageSize: 20);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadReviews({int pageNumber = 1, int pageSize = 20}) {
    final authState = context.read<AuthBloc>().state;
    domain.User? user;
    if (authState is AuthAuthenticated) user = authState.user;
    if (authState is AuthLoginSuccess) user = authState.user;
    if (authState is AuthProfileUpdateSuccess) user = authState.user;

    if (user != null &&
        user.isOwner &&
        (user.propertyId != null && user.propertyId!.isNotEmpty)) {
      context.read<ReviewsListBloc>().add(
            LoadReviewsEvent(
              propertyId: user.propertyId,
              pageNumber: pageNumber,
              pageSize: pageSize,
            ),
          );
    } else {
      context.read<ReviewsListBloc>().add(
            LoadReviewsEvent(
              pageNumber: pageNumber,
              pageSize: pageSize,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isDesktop = size.width > 1200;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          // خلفية متحركة بتدرج لوني
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(seconds: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.darkBackground,
                    AppTheme.darkBackground2.withOpacity(0.8),
                    AppTheme.primaryPurple.withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ),

          // كرات متوهجة متحركة
          ..._buildFloatingOrbs(),

          // المحتوى الرئيسي
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // شريط التطبيق الفاخر
              _buildPremiumAppBar(context, isDesktop),

              // قسم الإحصائيات
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildStatsSection(isDesktop, isTablet),
                  ),
                ),
              ),

              // قسم الفلاتر
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 32 : 20,
                      vertical: 16,
                    ),
                    child: ReviewFiltersWidget(
                      onFilterChanged: (filters) {
                        // enforce owner scoping in filters
                        final authState = context.read<AuthBloc>().state;
                        domain.User? user;
                        if (authState is AuthAuthenticated)
                          user = authState.user;
                        if (authState is AuthLoginSuccess)
                          user = authState.user;
                        if (authState is AuthProfileUpdateSuccess)
                          user = authState.user;
                        context.read<ReviewsListBloc>().add(
                              FilterReviewsEvent(
                                searchQuery: filters['search'] ?? '',
                                minRating: filters['minRating'],
                                isPending: filters['isPending'],
                                hasResponse: filters['hasResponse'],
                                propertyId: (user != null && user.isOwner)
                                    ? user.propertyId
                                    : null,
                              ),
                            );
                      },
                    ),
                  ),
                ),
              ),

              // تبديل العرض
              if (!isDesktop)
                SliverToBoxAdapter(
                  child: _buildViewToggle(),
                ),

              // محتوى التقييمات
              BlocBuilder<ReviewsListBloc, ReviewsListState>(
                builder: (context, state) {
                  if (state is ReviewsListLoading) {
                    return const SliverFillRemaining(
                      child: LoadingWidget(
                        type: LoadingType.futuristic,
                        message: 'جاري تحميل المراجعات...',
                      ),
                    );
                  }

                  if (state is ReviewsListError) {
                    return SliverFillRemaining(
                      child: _buildErrorState(state.message),
                    );
                  }

                  // 🎯 حالة LoadingMore: عرض المحتوى مع Progress Bar
                  if (state is ReviewsListLoadingMore) {
                    if (state.filteredReviews.isEmpty) {
                      return const SliverFillRemaining(
                        child: LoadingWidget(
                          type: LoadingType.futuristic,
                          message: 'جاري تحميل المراجعات...',
                        ),
                      );
                    }

                    if (isDesktop || (!_isGridView && isTablet)) {
                      return SliverList(
                        delegate: SliverChildListDelegate([
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 32 : 20,
                            ),
                            child: FuturisticReviewsTable(
                              reviews: state.filteredReviews,
                              approvingReviewIds: state.approvingReviewIds,
                              onReviewTap: (review) =>
                                  _navigateToDetails(context, review.id),
                              onApproveTap: (review) {
                                _showApproveConfirmation(context, review.id);
                              },
                              onDeleteTap: (review) {
                                _showDeleteConfirmation(context, review.id);
                              },
                            ),
                          ),
                          // Progress Bar في الأسفل
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: LoadingWidget(
                                type: LoadingType.futuristic,
                                message: 'جاري تحميل المزيد...',
                              ),
                            ),
                          ),
                        ]),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildListDelegate([
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 32 : 20,
                          ),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isTablet ? 2 : 1,
                              childAspectRatio: isTablet ? 1.5 : 1.8,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: state.filteredReviews.length,
                            itemBuilder: (context, index) {
                              return FuturisticReviewCard(
                                review: state.filteredReviews[index],
                                onTap: () => _navigateToDetails(
                                    context, state.filteredReviews[index].id),
                                onApprove: () {
                                  _showApproveConfirmation(
                                      context, state.filteredReviews[index].id);
                                },
                                onDelete: () {
                                  _showDeleteConfirmation(
                                      context, state.filteredReviews[index].id);
                                },
                                isApproving: state.approvingReviewIds
                                    .contains(state.filteredReviews[index].id),
                              );
                            },
                          ),
                        ),
                        // Progress Bar في الأسفل
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: LoadingWidget(
                              type: LoadingType.futuristic,
                              message: 'جاري تحميل المزيد...',
                            ),
                          ),
                        ),
                      ]),
                    );
                  }

                  if (state is ReviewsListLoaded) {
                    if (state.filteredReviews.isEmpty) {
                      return SliverFillRemaining(
                        child: _buildEmptyState(),
                      );
                    }

                    if (isDesktop || (!_isGridView && isTablet)) {
                      return SliverFillRemaining(
                        hasScrollBody: true,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 32 : 20,
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                  maxHeight: constraints.maxHeight,
                                ),
                                child: FuturisticReviewsTable(
                                  reviews: state.filteredReviews,
                                  approvingReviewIds: state.approvingReviewIds,
                                  onReviewTap: (review) =>
                                      _navigateToDetails(context, review.id),
                                  onApproveTap: (review) {
                                    _showApproveConfirmation(
                                        context, review.id);
                                  },
                                  onDeleteTap: (review) {
                                    _showDeleteConfirmation(context, review.id);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 32 : 20,
                      ),
                      sliver: _buildReviewsGrid(
                        state.filteredReviews,
                        isTablet: isTablet,
                      ),
                    );
                  }

                  return const SliverToBoxAdapter(child: SizedBox());
                },
              ),

              // حشوة سفلية
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),

          // زر عائم
          if (_showBackToTop)
            Positioned(
              bottom: 32,
              right: isDesktop ? 32 : 20,
              child: _buildFloatingActionButton(),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingOrbs() {
    return [
      Positioned(
        top: -100,
        right: -100,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(seconds: 2),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryBlue.withOpacity(0.1 * value),
                      AppTheme.primaryBlue.withOpacity(0.01),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      Positioned(
        bottom: -150,
        left: -150,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(seconds: 2, milliseconds: 500),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryPurple.withOpacity(0.08 * value),
                      AppTheme.primaryPurple.withOpacity(0.01),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }

  Widget _buildPremiumAppBar(BuildContext context, bool isDesktop) {
    // محاذاة التصميم مع شريط تطبيق صفحة الحجوزات
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: AppTheme.darkBackground,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Text(
          'التقييمات',
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
        // تحديث
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            _loadReviews(pageNumber: 1, pageSize: 20);
          },
          icon: Icon(
            Icons.refresh_rounded,
            color: AppTheme.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(bool isDesktop, bool isTablet) {
    return BlocBuilder<ReviewsListBloc, ReviewsListState>(
      builder: (context, state) {
        if (state is ReviewsListLoaded) {
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 20,
              vertical: 20,
            ),
            child: ReviewStatsCard(
              totalReviews: _parseInt(state.stats?['totalReviews']) ??
                  state.reviews.length,
              pendingReviews: _parseInt(state.stats?['pendingReviews']) ??
                  state.pendingCount,
              averageRating: _parseDouble(state.stats?['averageRating']) ??
                  state.averageRating,
              reviews: state.reviews,
              isDesktop: isDesktop,
              isTablet: isTablet,
              withResponsesCount:
                  _parseInt(state.stats?['reviewsWithResponses']),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  bool? _extractHasNextFromStats(Map<String, dynamic>? stats) {
    if (stats == null) return null;
    final v = stats['hasNextPage'] ?? stats['hasMore'] ?? stats['HasNextPage'];
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    if (v is num) return v > 0;
    return null;
  }

  int? _extractNextPageFromStats(Map<String, dynamic>? stats) {
    if (stats == null) return null;
    final v = stats['nextPage'] ?? stats['nextPageNumber'] ?? stats['NextPage'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    if (v is num) return v.toInt();
    return null;
  }

  int? _parseInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  double? _parseDouble(Object? v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  Widget _buildViewToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.darkCard.withOpacity(0.5),
              border: Border.all(
                color: AppTheme.glowBlue.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                _buildToggleButton(
                  icon: Icons.view_list_rounded,
                  isSelected: !_isGridView,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isGridView = false);
                  },
                ),
                const SizedBox(width: 4),
                _buildToggleButton(
                  icon: Icons.grid_view_rounded,
                  isSelected: _isGridView,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isGridView = true);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? AppTheme.primaryBlue.withOpacity(0.2)
              : Colors.transparent,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected
              ? AppTheme.glowBlue
              : AppTheme.textLight.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildReviewsGrid(
    List<dynamic> reviews, {
    required bool isTablet,
  }) {
    final crossAxisCount = isTablet ? 2 : 1;

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: isTablet ? 1.5 : 1.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 600),
            columnCount: crossAxisCount,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: FuturisticReviewCard(
                  review: reviews[index],
                  onTap: () => _navigateToDetails(context, reviews[index].id),
                  onApprove: () {
                    _showApproveConfirmation(context, reviews[index].id);
                  },
                  onDelete: () {
                    _showDeleteConfirmation(context, reviews[index].id);
                  },
                  isApproving: (context.read<ReviewsListBloc>().state
                          is ReviewsListLoaded)
                      ? (context.read<ReviewsListBloc>().state
                              as ReviewsListLoaded)
                          .approvingReviewIds
                          .contains(reviews[index].id)
                      : false,
                ),
              ),
            ),
          );
        },
        childCount: reviews.length,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.glowBlue.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'جاري تحميل التقييمات...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textLight,
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppTheme.error.withOpacity(0.1),
              border: Border.all(
                color: AppTheme.error.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'خطأ في تحميل التقييمات',
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              context.read<ReviewsListBloc>().add(const LoadReviewsEvent());
            },
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text(
              'حاول مرة أخرى',
              style: AppTextStyles.buttonMedium,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.1),
                  AppTheme.primaryPurple.withOpacity(0.1),
                ],
              ),
            ),
            child: Icon(
              Icons.reviews_outlined,
              size: 64,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد تقييمات',
            style: AppTextStyles.heading2.copyWith(
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لا توجد تقييمات تطابق معايير البحث',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.glowBlue.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                  );
                },
                borderRadius: BorderRadius.circular(28),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToDetails(BuildContext context, String reviewId) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            BlocProvider<ReviewDetailsBloc>(
          create: (_) => di.sl<ReviewDetailsBloc>(),
          child: ReviewDetailsPage(reviewId: reviewId),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.95,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String reviewId) {
    HapticFeedback.mediumImpact();
    showDialog(
      fullscreenDialog: true,
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.error.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.error.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.error.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: AppTheme.error,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'حذف التقييم؟',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'لا يمكن التراجع عن هذا الإجراء',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'إلغاء',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppTheme.textLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.read<ReviewsListBloc>().add(
                                DeleteReviewEvent(reviewId),
                              );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'حذف',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showApproveConfirmation(BuildContext context, String reviewId) {
    HapticFeedback.mediumImpact();
    final reviewsListBloc = context.read<ReviewsListBloc>();
    showDialog(
      fullscreenDialog: true,
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.success.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.success.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.success.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.success,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'الموافقة على التقييم؟',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'سيتم اعتماد هذا التقييم. هل تريد المتابعة؟',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'إلغاء',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppTheme.textLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          reviewsListBloc.add(ApproveReviewEvent(reviewId));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'موافقة',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
