import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/enums/booking_status.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/booking_bloc.dart';
import '../bloc/booking_event.dart';
import '../bloc/booking_state.dart';
import '../widgets/booking_card_widget.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _backgroundAnimationController;
  late AnimationController _floatingAnimationController;
  late AnimationController _fadeController;
  late AnimationController _headerMorphController;
  late TabController _tabController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _headerMorphAnimation;
  
  // State
  final ScrollController _scrollController = ScrollController();
  BookingStatus? _selectedStatus;
  double _scrollOffset = 0;
  double _scrollProgress = 0; // نسبة التمرير من 0 إلى 1
  
  // Constants for smooth transitions
  static const double _expandedHeight = 160.0;
  static const double _collapsedHeight = 56.0;
  static const double _tabBarHeight = 44.0;
  static const double _statsHeight = 100.0;
  static const double _minStatsHeight = 128.0;
  static const double _totalScrollRange = _expandedHeight + _statsHeight;
  
  // Statistics
  Map<BookingStatus, int> _statusCounts = {
    BookingStatus.confirmed: 0,
    BookingStatus.pending: 0,
    BookingStatus.completed: 0,
    BookingStatus.cancelled: 0,
  };
  
  // Subtle Particles
  final List<_SubtleParticle> _particles = [];
  // Cache last loaded bookings to avoid empty list when bloc state changes externally
  List<dynamic> _cachedBookings = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateSubtleParticles();
    _startAnimations();
    
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    
    _loadBookings();
  }

  void _initializeAnimations() {
    // Slow background animation for subtlety
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    )..repeat();
    
    // Floating animation
    _floatingAnimationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);
    
    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Header morph animation
    _headerMorphController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _headerMorphAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerMorphController,
      curve: Curves.easeInOutCubic,
    ));
  }
  
  void _generateSubtleParticles() {
    for (int i = 0; i < 6; i++) {
      _particles.add(_SubtleParticle());
    }
  }
  
  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _floatingAnimationController.dispose();
    _fadeController.dispose();
    _headerMorphController.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      HapticFeedback.selectionClick();
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedStatus = null;
            break;
          case 1:
            _selectedStatus = BookingStatus.confirmed;
            break;
          case 2:
            _selectedStatus = BookingStatus.pending;
            break;
          case 3:
            _selectedStatus = BookingStatus.completed;
            break;
        }
      });
      _loadBookings();
    }
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
      // حساب نسبة التمرير بشكل سلس
      _scrollProgress = (_scrollOffset / _totalScrollRange).clamp(0.0, 1.0);
      
      // تحديث حالة Header Morph بشكل تدريجي
      if (_scrollProgress > 0.3) {
        _headerMorphController.forward();
      } else {
        _headerMorphController.reverse();
      }
    });
    
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _loadMoreBookings();
    }
  }

  void _loadBookings() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<BookingBloc>().add(
        GetUserBookingsEvent(
          userId: authState.user.userId,
          status: _selectedStatus?.toString().split('.').last,
          pageNumber: 1,
          pageSize: 10,
        ),
      );
    }
  }

  void _loadMoreBookings() {
    final state = context.read<BookingBloc>().state;
    if (state is UserBookingsLoaded && !state.isLoadingMore && state.hasMore) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        context.read<BookingBloc>().add(
          GetUserBookingsEvent(
            userId: authState.user.userId,
            status: _selectedStatus?.toString().split('.').last,
            pageNumber: state.currentPage + 1,
            pageSize: 10,
            loadMore: true,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          // Subtle animated background
          _buildSubtleBackground(),
          
          // Subtle floating particles
          _buildSubtleParticles(),
          
          // Main Content with Custom Scroll
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAdvancedSliverAppBar(),
              _buildCompactStatistics(),
              _buildBodySliver(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubtleBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkBackground,
                AppTheme.darkBackground2,
                AppTheme.darkBackground3,
              ],
            ),
          ),
          child: CustomPaint(
            painter: _SubtleGridPainter(
              animationValue: _backgroundAnimationController.value,
              scrollOffset: _scrollOffset,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildSubtleParticles() {
    return AnimatedBuilder(
      animation: _floatingAnimationController,
      builder: (context, child) {
        return CustomPaint(
          painter: _SubtleParticlePainter(
            particles: _particles,
            animationValue: _floatingAnimationController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildAdvancedSliverAppBar() {
    return SliverAppBar(
      expandedHeight: _expandedHeight,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: const SizedBox.shrink(),
      
      // Actions with fade effect
      actions: [
        AnimatedOpacity(
          opacity: 1.0 - (_scrollProgress * 0.3),
          duration: const Duration(milliseconds: 150),
          child: _buildMinimalActionButton(
            icon: Icons.filter_list_rounded,
            onPressed: _showFilterDialog,
          ),
        ),
      ],
      
      // Flexible space with smooth transitions
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final double currentHeight = constraints.maxHeight;
          final double progress = ((currentHeight - _collapsedHeight) / 
                                   (_expandedHeight - _collapsedHeight))
                                   .clamp(0.0, 1.0);
          
          return Stack(
            fit: StackFit.expand,
            children: [
              // Background with progressive blur
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.darkCard.withOpacity(0.3 + (0.6 * (1 - progress))),
                        AppTheme.darkCard.withOpacity(0.1 * progress),
                      ],
                    ),
                  ),
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 10 + (10 * (1 - progress)),
                        sigmaY: 10 + (10 * (1 - progress)),
                      ),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Header content with parallax and morph
              Positioned(
                left: 0,
                right: 0,
                bottom: _tabBarHeight,
                child: Container(
                  height: _expandedHeight - _tabBarHeight,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top,
                  ),
                  child: _buildMorphingHeader(progress),
                ),
              ),
              
              // Tab bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedOpacity(
                  opacity: 0.5 + (0.5 * progress),
                  duration: const Duration(milliseconds: 200),
                  child: _buildSmoothTabBar(progress),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildMorphingHeader(double progress) {
    // حساب القيم التدريجية
    final double iconSize = 24 + (24 * progress);
    final double iconContainerSize = 32 + (16 * progress);
    final double spacing = 4 + (8 * progress);
    final double textSize = 14 + (6 * progress);
    final double horizontalPadding = 56 + (40 * (1 - progress)); // للمحاذاة مع الأزرار
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          // Icon with smooth scaling
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: iconContainerSize,
            height: iconContainerSize,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.6 + (0.2 * progress)),
                  AppTheme.primaryPurple.withOpacity(0.4 + (0.2 * progress)),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.1 * progress),
                  blurRadius: 8 * progress,
                  spreadRadius: 1 * progress,
                ),
              ],
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: Colors.white.withOpacity(0.9 + (0.1 * progress)),
              size: iconSize,
            ),
          ),
          
          SizedBox(width: spacing),
          
          // Title with smooth transition
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: textSize,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite.withOpacity(0.9 + (0.05 * progress)),
                  ),
                  child: const Text('حجوزاتي'),
                ),
                
                // Subtitle that fades in/out
                AnimatedOpacity(
                  opacity: progress * 0.7,
                  duration: const Duration(milliseconds: 200),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: progress * 14,
                    child: Text(
                      'إدارة جميع حجوزاتك',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted.withOpacity(0.6),
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Count badge with smooth transition
          AnimatedOpacity(
            opacity: 0.5 + (0.5 * (1 - progress)),
            duration: const Duration(milliseconds: 200),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: 6 + (2 * progress),
                vertical: 3 + (1 * progress),
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.08 + (0.02 * progress)),
                borderRadius: BorderRadius.circular(6 + (2 * progress)),
              ),
              child: Text(
                '${_statusCounts.values.fold(0, (a, b) => a + b)}',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.primaryBlue.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                  fontSize: 10 + (1 * progress),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSmoothTabBar(double progress) {
    return Container(
      height: _tabBarHeight,
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.2 + (0.1 * (1 - progress))),
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.1 * progress),
            width: 0.5,
          ),
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.1 + (0.1 * (1 - progress))),
            width: 0.5,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5 + (5 * (1 - progress)),
            sigmaY: 5 + (5 * (1 - progress)),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: false,
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: AppTheme.textMuted.withOpacity(0.4 + (0.2 * progress)),
            indicatorColor: Colors.transparent,
            indicator: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.15 + (0.05 * progress)),
                  AppTheme.primaryPurple.withOpacity(0.08 + (0.02 * progress)),
                ],
              ),
              borderRadius: BorderRadius.circular(6 + (2 * progress)),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 10 + (1 * progress),
            ),
            tabs: [
              _buildCompactTab('الكل', _statusCounts.values.fold(0, (a, b) => a + b), progress),
              _buildCompactTab('مؤكدة', _statusCounts[BookingStatus.confirmed] ?? 0, progress),
              _buildCompactTab('معلقة', _statusCounts[BookingStatus.pending] ?? 0, progress),
              _buildCompactTab('مكتملة', _statusCounts[BookingStatus.completed] ?? 0, progress),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalBackButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.darkCard.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.darkBorder.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 16),
              color: AppTheme.textWhite.withOpacity(0.9),
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.darkCard.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.darkBorder.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: IconButton(
              icon: Icon(icon, size: 16),
              color: AppTheme.textWhite.withOpacity(0.9),
              onPressed: onPressed,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTab(String label, int count, double progress) {
    return Tab(
      height: 36,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (count > 0) ...[
              SizedBox(width: 3 + (1 * progress)),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: 3 + (1 * progress),
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.12 + (0.03 * progress)),
                  borderRadius: BorderRadius.circular(4 + (2 * progress)),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 8 + (1 * progress),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStatistics() {
    return SliverToBoxAdapter(
      child: AnimatedOpacity(
        opacity: 1.0 - (_scrollProgress * 2).clamp(0.0, 1.0),
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: math.max(
            _minStatsHeight,
            _statsHeight * (1.0 - (_scrollProgress * 1.5).clamp(0.0, 1.0)),
          ),
          child: BlocBuilder<BookingBloc, BookingState>(
            builder: (context, state) {
              if (state is UserBookingsLoaded) {
                _updateStatistics(state.bookings);
              }
              
              return AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12 * (1.0 - _scrollProgress),
                      ),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildMinimalStatCard(
                            icon: Icons.check_circle_rounded,
                            title: 'مؤكدة',
                            count: _statusCounts[BookingStatus.confirmed] ?? 0,
                            color: AppTheme.success.withOpacity(0.8),
                          ),
                          const SizedBox(width: 10),
                          _buildMinimalStatCard(
                            icon: Icons.hourglass_empty_rounded,
                            title: 'معلقة',
                            count: _statusCounts[BookingStatus.pending] ?? 0,
                            color: AppTheme.warning.withOpacity(0.8),
                          ),
                          const SizedBox(width: 10),
                          _buildMinimalStatCard(
                            icon: Icons.done_all_rounded,
                            title: 'مكتملة',
                            count: _statusCounts[BookingStatus.completed] ?? 0,
                            color: AppTheme.info.withOpacity(0.8),
                          ),
                          const SizedBox(width: 10),
                          _buildMinimalStatCard(
                            icon: Icons.cancel_rounded,
                            title: 'ملغاة',
                            count: _statusCounts[BookingStatus.cancelled] ?? 0,
                            color: AppTheme.error.withOpacity(0.8),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalStatCard({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    final double scale = 1.0 - (_scrollProgress * 0.2).clamp(0.0, 0.2);
    
    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count.toString(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    title,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted.withOpacity(0.7),
                      fontSize: 9,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBodySliver() {
    return SliverPadding(
      padding: const EdgeInsets.all(12),
      sliver: BlocBuilder<BookingBloc, BookingState>(
        builder: (context, state) {
          // Determine current bookings (use cached when not in UserBookingsLoaded)
          if (state is UserBookingsLoaded) {
            _cachedBookings = state.bookings;
          }
          final bookings = (state is UserBookingsLoaded)
              ? state.bookings
              : _cachedBookings;

          // Only show full loader on first load; keep list if cached exists
          if (state is BookingLoading && bookings.isEmpty) {
            return SliverFillRemaining(
              child: Center(
                child: _buildMinimalLoader(),
              ),
            );
          }

          if (state is BookingError) {
            if (bookings.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: _buildMinimalError(state),
                ),
              );
            }
            // If we have cached data, fall through to render cached list
          }

          if (bookings.isNotEmpty) {
            final isLoadingMore = state is UserBookingsLoaded ? state.isLoadingMore : false;
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == bookings.length && isLoadingMore) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: const LoadingWidget(
                        type: LoadingType.futuristic,
                        message: 'جاري تحميل المزيد...',
                      ),
                    );
                  }

                  if (index >= bookings.length) return const SizedBox.shrink();
                  final booking = bookings[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 200 + (index * 50)),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, (1 - value) * 20),
                          child: Opacity(
                            opacity: value,
                            child: BookingCardWidget(
                              booking: booking,
                              onTap: () => _navigateToDetails(booking.id),
                              onCancel: booking.canCancel
                                  ? () => _showCancelDialog(booking)
                                  : null,
                              onReview: booking.canReview
                                  ? () => _navigateToReview(booking)
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                childCount: bookings.length + (isLoadingMore ? 1 : 0),
              ),
            );
          }

          return const SliverFillRemaining(
            child: SizedBox.shrink(),
          );
        },
      ),
    );
  }

  Widget _buildMinimalLoader() {
    return const LoadingWidget(
      type: LoadingType.futuristic,
      message: 'جاري تحميل الحجوزات...',
    );
  }

  Widget _buildMinimalError(BookingError state) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.error.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 24,
                color: AppTheme.error.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildMinimalRetryButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalRetryButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.error.withOpacity(0.7),
            AppTheme.error.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loadBookings,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  'إعادة المحاولة',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalEmpty() {
    String message;
    IconData icon;
    Color color;
    
    switch (_selectedStatus) {
      case BookingStatus.confirmed:
        message = 'لا توجد حجوزات مؤكدة';
        icon = Icons.check_circle_outline_rounded;
        color = AppTheme.success.withOpacity(0.8);
        break;
      case BookingStatus.pending:
        message = 'لا توجد حجوزات معلقة';
        icon = Icons.hourglass_empty_rounded;
        color = AppTheme.warning.withOpacity(0.8);
        break;
      case BookingStatus.completed:
        message = 'لا توجد حجوزات مكتملة';
        icon = Icons.done_all_rounded;
        color = AppTheme.info.withOpacity(0.8);
        break;
      default:
        message = 'لا توجد حجوزات';
        icon = Icons.calendar_today_rounded;
        color = AppTheme.primaryBlue.withOpacity(0.8);
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: color.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.8),
                    AppTheme.primaryPurple.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/search'),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'ابحث عن عقارات',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateStatistics(dynamic bookings) {
    _statusCounts = {
      BookingStatus.confirmed: 0,
      BookingStatus.pending: 0,
      BookingStatus.completed: 0,
      BookingStatus.cancelled: 0,
    };
    
    for (var booking in bookings) {
      if (_statusCounts.containsKey(booking.status)) {
        _statusCounts[booking.status] = (_statusCounts[booking.status] ?? 0) + 1;
      }
    }
  }

  Future<void> _navigateToDetails(String bookingId) async {
    HapticFeedback.selectionClick();
    await context.push('/booking/$bookingId');
    // Refresh bookings after returning from details
    _loadBookings();
  }

  void _navigateToReview(dynamic booking) {
    HapticFeedback.selectionClick();
    context.push('/review/write', extra: {
      'bookingId': booking.id,
      'propertyId': booking.propertyId,
      'propertyName': booking.propertyName,
    });
  }

  void _showCancelDialog(dynamic booking) {
    HapticFeedback.mediumImpact();
    // Implementation for cancel dialog
  }

  void _showFilterDialog() {
    HapticFeedback.selectionClick();
    // Implementation for filter dialog
  }
}

// [نفس الـ Painters السابقة بدون تغيير]
class _SubtleGridPainter extends CustomPainter {
  final double animationValue;
  final double scrollOffset;
  
  _SubtleGridPainter({
    required this.animationValue,
    required this.scrollOffset,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.2;
    
    const spacing = 30.0;
    final offset = scrollOffset * 0.05 % spacing;
    
    for (double x = -spacing + offset; x < size.width + spacing; x += spacing) {
      paint.color = AppTheme.primaryBlue.withOpacity(0.02);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    for (double y = -spacing + offset; y < size.height + spacing; y += spacing) {
      paint.color = AppTheme.primaryPurple.withOpacity(0.02);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SubtleParticle {
  late double x;
  late double y;
  late double size;
  late double opacity;
  late Color color;
  late double speed;
  
  _SubtleParticle() {
    reset();
  }
  
  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    size = math.Random().nextDouble() * 3 + 1;
    opacity = math.Random().nextDouble() * 0.1 + 0.02;
    speed = math.Random().nextDouble() * 0.005 + 0.002;
    
    final colors = [
      AppTheme.primaryBlue,
      AppTheme.primaryPurple,
      AppTheme.primaryCyan,
    ];
    color = colors[math.Random().nextInt(colors.length)];
  }
  
  void update(double animationValue) {
    y -= speed;
    if (y < -0.1) {
      y = 1.1;
      x = math.Random().nextDouble();
    }
  }
}

class _SubtleParticlePainter extends CustomPainter {
  final List<_SubtleParticle> particles;
  final double animationValue;
  
  _SubtleParticlePainter({
    required this.particles,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update(animationValue);
      
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}