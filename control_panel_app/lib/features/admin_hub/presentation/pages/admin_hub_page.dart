// lib/features/admin_hub/presentation/pages/admin_hub_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../notifications/presentation/bloc/notification_bloc.dart';
import '../../../notifications/presentation/bloc/notification_event.dart';
import '../../../notifications/presentation/bloc/notification_state.dart';
import '../../../../injection_container.dart' as di;
import '../../data/services/screen_search_service.dart';
import '../widgets/screen_search_dialog.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class AdminHubPage extends StatefulWidget {
  const AdminHubPage({super.key});

  @override
  State<AdminHubPage> createState() => _AdminHubPageState();
}

class _AdminHubPageState extends State<AdminHubPage>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _mainAnimationController;
  late AnimationController _floatingAnimationController;
  late AnimationController _pulseAnimationController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // UI State
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingHeader = false;
  int? _hoveredCardIndex;

  // Stats Data (Should be fetched from backend)
  final Map<String, dynamic> _stats = {
    'properties': 156,
    'users': 2341,
    'bookings': 89,
    'revenue': 45.2,
    'growth': 12.5,
    'occupancy': 78,
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
  }

  void _initializeAnimations() {
    // Main entrance animation
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Floating animation for background elements
    _floatingAnimationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    // Pulse animation for interactive elements
    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Setup animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutBack),
    ));

    // Start animations
    _mainAnimationController.forward();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final shouldShow = _scrollController.offset > 200;
      if (shouldShow != _showFloatingHeader) {
        setState(() {
          _showFloatingHeader = shouldShow;
        });
      }
    });
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _floatingAnimationController.dispose();
    _pulseAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
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
          // Animated Background
          _buildAnimatedBackground(),

          // Main Content
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Premium App Bar
              _buildPremiumAppBar(context, isDesktop),

              // Hero Section
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildHeroSection(isDesktop, isTablet),
                  ),
                ),
              ),

              // // Quick Stats
              // SliverToBoxAdapter(
              //   child: FadeTransition(
              //     opacity: _fadeAnimation,
              //     child: ScaleTransition(
              //       scale: _scaleAnimation,
              //       child: _buildQuickStats(isDesktop, isTablet),
              //     ),
              //   ),
              // ),

              // Admin Features Grid
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 20,
                  vertical: 32,
                ),
                sliver: SliverToBoxAdapter(
                  child: _buildAdminFeaturesSection(isDesktop, isTablet),
                ),
              ),

              // Bottom Padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),

          // Floating Header
          if (_showFloatingHeader) _buildFloatingHeader(context),

          // Floating Action Button
          if (_showFloatingHeader) _buildFloatingActionButton(),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        // Gradient Background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkBackground,
                AppTheme.darkBackground2,
                AppTheme.darkBackground3.withOpacity(0.5),
              ],
            ),
          ),
        ),

        // Animated Orbs
        AnimatedBuilder(
          animation: _floatingAnimationController,
          builder: (context, child) {
            return Stack(
              children: [
                // Top Right Orb
                Positioned(
                  top: -100 + (30 * _floatingAnimationController.value),
                  right: -100,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.primaryBlue.withOpacity(0.15),
                          AppTheme.primaryBlue.withOpacity(0.05),
                          AppTheme.primaryBlue.withOpacity(0.01),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom Left Orb
                Positioned(
                  bottom: -200 + (20 * _floatingAnimationController.value),
                  left: -150,
                  child: Container(
                    width: 500,
                    height: 500,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.primaryPurple.withOpacity(0.12),
                          AppTheme.primaryPurple.withOpacity(0.04),
                          AppTheme.primaryPurple.withOpacity(0.01),
                        ],
                      ),
                    ),
                  ),
                ),

                // Center Orb
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.5,
                  right: MediaQuery.of(context).size.width * 0.3,
                  child: Transform.scale(
                    scale: 0.8 + (0.2 * _floatingAnimationController.value),
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.primaryViolet.withOpacity(0.08),
                            AppTheme.primaryViolet.withOpacity(0.02),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // Subtle Grid Pattern
        CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _GridPatternPainter(
            color: AppTheme.darkBorder.withOpacity(0.03),
            spacing: 60,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumAppBar(BuildContext context, bool isDesktop) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.darkCard.withOpacity(0.8),
                  AppTheme.darkCard.withOpacity(0.4),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.glowBlue.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          // Logo with Glow
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.glowBlue.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.dashboard_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Title
          Expanded(
            // Fix overflow issue
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'لوحة التحكم',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppTheme.textWhite,
                    fontSize: isDesktop ? 20 : 18,
                  ),
                ),
                Text(
                  'نظام الإدارة',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Search Button
        _buildAppBarAction(
          icon: Icons.search_rounded,
          onTap: () => _showSearchDialog(context),
        ),

        // Notifications
        BlocProvider<NotificationBloc>(
          create: (_) =>
              di.sl<NotificationBloc>()..add(const LoadUnreadCountEvent()),
          child: BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              String? badge;
              if (state is NotificationLoaded) {
                if (state.unreadCount > 0)
                  badge = state.unreadCount > 99
                      ? '99+'
                      : state.unreadCount.toString();
              } else if (state is NotificationUnreadCountLoaded) {
                if (state.unreadCount > 0)
                  badge = state.unreadCount > 99
                      ? '99+'
                      : state.unreadCount.toString();
              }
              return _buildAppBarAction(
                icon: Icons.notifications_none_rounded,
                onTap: () => context.push('/notifications'),
                badge: badge,
              );
            },
          ),
        ),

        // Profile
        Padding(
          padding: const EdgeInsets.only(right: 8, left: 8),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/profile');
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryPurple,
                    AppTheme.primaryViolet,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryPurple.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBarAction({
    required IconData icon,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppTheme.inputBackground.withOpacity(0.3),
            ),
            child: Icon(
              icon,
              color: AppTheme.textLight,
              size: 20,
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.error, AppTheme.primaryViolet],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.error.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Center(
                child: Text(
                  badge,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeroSection(bool isDesktop, bool isTablet) {
    final isAdmin = context.select((AuthBloc bloc) {
      final s = bloc.state;
      if (s is AuthAuthenticated) return s.user.isAdmin;
      if (s is AuthLoginSuccess) return s.user.isAdmin;
      if (s is AuthProfileUpdateSuccess) return s.user.isAdmin;
      if (s is AuthProfileImageUploadSuccess) return s.user.isAdmin;
      return false;
    });
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;

    if (hour < 12) {
      greeting = 'صباح الخير';
      greetingIcon = Icons.wb_sunny_outlined;
    } else if (hour < 18) {
      greeting = 'مساء الخير';
      greetingIcon = Icons.wb_twilight_outlined;
    } else {
      greeting = 'مساء الخير';
      greetingIcon = Icons.nights_stay_outlined;
    }

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 20,
        vertical: 24,
      ),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkCard.withOpacity(0.6),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        border: Border.all(
          color: AppTheme.glowBlue.withOpacity(0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    Row(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseAnimationController,
                          builder: (context, child) {
                            return Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.warning.withOpacity(0.2),
                                    AppTheme.warning.withOpacity(0.1),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.warning.withOpacity(
                                      0.2 * _pulseAnimationController.value,
                                    ),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                greetingIcon,
                                color: AppTheme.warning,
                                size: 24,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Text(
                          greeting,
                          style: AppTextStyles.displaySmall.copyWith(
                            color: AppTheme.textWhite,
                            fontSize: isDesktop ? 28 : 24,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Welcome Message
                    Text(
                      'مرحباً بك في لوحة التحكم الخاصة بك',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppTheme.textLight,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Last Login
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppTheme.textMuted.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'آخر تسجيل دخول: ${_formatLastLogin()}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textMuted.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Quick Actions
                    Row(
                      children: [
                        if (isAdmin)
                          _buildQuickActionButton(
                            label: 'إضافة عقار',
                            icon: Icons.add_business,
                            onTap: () => context.push('/admin/properties/add'),
                          ),
                        if (isAdmin) const SizedBox(width: 12),
                        _buildQuickActionButton(
                          label: 'التقارير',
                          icon: Icons.assessment_outlined,
                          onTap: () => context.push('/admin/reports'),
                          isPrimary: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isTablet)
                const SizedBox.shrink()
              else ...[
                const SizedBox(width: 32),
                // Decorative Element
                AnimatedBuilder(
                  animation: _floatingAnimationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset:
                          Offset(0, 10 * _floatingAnimationController.value),
                      child: Container(
                        width: isDesktop ? 120 : 100,
                        height: isDesktop ? 120 : 100,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.white,
                          size: isDesktop ? 56 : 48,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = true,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isPrimary ? AppTheme.primaryGradient : null,
          color: isPrimary ? null : AppTheme.inputBackground.withOpacity(0.3),
          border: isPrimary
              ? null
              : Border.all(
                  color: AppTheme.darkBorder.withOpacity(0.3),
                  width: 0.5,
                ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.white : AppTheme.textLight,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.buttonMedium.copyWith(
                color: isPrimary ? Colors.white : AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(bool isDesktop, bool isTablet) {
    final stats = [
      _StatItem(
        label: 'العقارات',
        value: _stats['properties'].toString(),
        icon: Icons.apartment_rounded,
        gradient: [AppTheme.primaryBlue, AppTheme.primaryCyan],
        trend: '+12%',
        isPositive: true,
      ),
      _StatItem(
        label: 'المستخدمون',
        value: '${(_stats['users'] / 1000).toStringAsFixed(1)}ك',
        icon: Icons.people_rounded,
        gradient: [AppTheme.primaryPurple, AppTheme.primaryViolet],
        trend: '+8%',
        isPositive: true,
      ),
      _StatItem(
        label: 'الحجوزات',
        value: _stats['bookings'].toString(),
        icon: Icons.calendar_month_rounded,
        gradient: [AppTheme.neonGreen, AppTheme.primaryCyan],
        trend: '-3%',
        isPositive: false,
      ),
      _StatItem(
        label: 'الإيرادات',
        value: '\$${_stats['revenue']}ك',
        icon: Icons.attach_money_rounded,
        gradient: [AppTheme.warning, AppTheme.neonPurple],
        trend: '+24%',
        isPositive: true,
      ),
      _StatItem(
        label: 'النمو',
        value: '${_stats['growth']}%',
        icon: Icons.trending_up_rounded,
        gradient: [AppTheme.success, AppTheme.neonGreen],
        trend: '+5%',
        isPositive: true,
      ),
      _StatItem(
        label: 'الإشغال',
        value: '${_stats['occupancy']}%',
        icon: Icons.hotel_rounded,
        gradient: [AppTheme.info, AppTheme.neonBlue],
        trend: '+10%',
        isPositive: true,
      ),
    ];

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 20,
      ),
      child: AnimationLimiter(
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 6 : (isTablet ? 3 : 2),
            childAspectRatio: isDesktop ? 1.4 : 1.3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 600),
              columnCount: isDesktop ? 6 : (isTablet ? 3 : 2),
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: _buildStatCard(stats[index]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(_StatItem stat) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact =
            constraints.maxHeight < 100 || constraints.maxWidth < 120;
        final isVeryCompact = constraints.maxHeight < 80;

        return Container(
          padding: EdgeInsets.all(isVeryCompact ? 12 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkCard.withOpacity(0.7),
                AppTheme.darkCard.withOpacity(0.5),
              ],
            ),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.2),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: stat.gradient[0].withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon and Trend - جعله flexible
                  Flexible(
                    flex: isVeryCompact ? 2 : 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: isVeryCompact ? 28 : (isCompact ? 32 : 36),
                          height: isVeryCompact ? 28 : (isCompact ? 32 : 36),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: stat.gradient),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: stat.gradient[0].withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            stat.icon,
                            color: Colors.white,
                            size: isVeryCompact ? 14 : (isCompact ? 16 : 18),
                          ),
                        ),
                        if (!isVeryCompact) // إخفاء الترند في المساحات الصغيرة جداً
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 4 : 6,
                                vertical: isCompact ? 2 : 3,
                              ),
                              decoration: BoxDecoration(
                                color: stat.isPositive
                                    ? AppTheme.success.withOpacity(0.1)
                                    : AppTheme.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: stat.isPositive
                                      ? AppTheme.success.withOpacity(0.3)
                                      : AppTheme.error.withOpacity(0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    stat.isPositive
                                        ? Icons.trending_up_rounded
                                        : Icons.trending_down_rounded,
                                    color: stat.isPositive
                                        ? AppTheme.success
                                        : AppTheme.error,
                                    size: isCompact ? 8 : 10,
                                  ),
                                  const SizedBox(width: 1),
                                  Flexible(
                                    child: Text(
                                      stat.trend,
                                      style: AppTextStyles.caption.copyWith(
                                        color: stat.isPositive
                                            ? AppTheme.success
                                            : AppTheme.error,
                                        fontWeight: FontWeight.w600,
                                        fontSize: isCompact ? 8 : 9,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Value and Label - استخدام Expanded
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Text(
                                  stat.value,
                                  style: AppTextStyles.heading2.copyWith(
                                    color: AppTheme.textWhite,
                                    fontSize: isVeryCompact
                                        ? 14
                                        : (isCompact ? 16 : 18),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stat.label,
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textMuted,
                            fontSize: isVeryCompact ? 9 : (isCompact ? 10 : 11),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

  Widget _buildAdminFeaturesSection(bool isDesktop, bool isTablet) {
    final isAdmin = context.select((AuthBloc bloc) {
      final s = bloc.state;
      if (s is AuthAuthenticated) return s.user.isAdmin;
      if (s is AuthLoginSuccess) return s.user.isAdmin;
      if (s is AuthProfileUpdateSuccess) return s.user.isAdmin;
      if (s is AuthProfileImageUploadSuccess) return s.user.isAdmin;
      return false;
    });
    final isOwner = context.select((AuthBloc bloc) {
      final s = bloc.state;
      if (s is AuthAuthenticated) return s.user.isOwner;
      if (s is AuthLoginSuccess) return s.user.isOwner;
      if (s is AuthProfileUpdateSuccess) return s.user.isOwner;
      if (s is AuthProfileImageUploadSuccess) return s.user.isOwner;
      return false;
    });

    bool canSeeFeature(_AdminFeature f) =>
        isAdmin || !f.adminOnly || (isOwner && f.visibleForOwner);

    final features = _adminFeatures.where(canSeeFeature).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              width: 4,
              height: 28,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أدوات الإدارة',
                  style: AppTextStyles.heading1.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'وصول سريع لجميع مميزات الإدارة',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Features Grid
        AnimationLimiter(
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 4 : (isTablet ? 3 : 2),
              childAspectRatio: isDesktop
                  ? 1.2
                  : (isTablet
                      ? 1.1
                      : 1.0), // Slightly taller on smaller screens
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              return AnimationConfiguration.staggeredGrid(
                position: index,
                duration: const Duration(milliseconds: 600),
                columnCount: isDesktop ? 4 : (isTablet ? 3 : 2),
                child: ScaleAnimation(
                  child: FadeInAnimation(
                    child: _buildFeatureCard(
                      features[index],
                      index,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(_AdminFeature feature, int index) {
    final isHovered = _hoveredCardIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredCardIndex = index),
      onExit: (_) => setState(() => _hoveredCardIndex = null),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          feature.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..translate(0.0, isHovered ? -8.0 : 0.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isHovered
                  ? [
                      AppTheme.darkCard.withOpacity(0.9),
                      AppTheme.darkCard.withOpacity(0.7),
                    ]
                  : [
                      AppTheme.darkCard.withOpacity(0.6),
                      AppTheme.darkCard.withOpacity(0.4),
                    ],
            ),
            border: Border.all(
              color: isHovered
                  ? feature.gradient[0].withOpacity(0.5)
                  : AppTheme.darkBorder.withOpacity(0.2),
              width: isHovered ? 1.5 : 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered
                    ? feature.gradient[0].withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                blurRadius: isHovered ? 30 : 20,
                spreadRadius: isHovered ? 5 : 0,
                offset: Offset(0, isHovered ? 12 : 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: isHovered ? 20 : 10,
                sigmaY: isHovered ? 20 : 10,
              ),
              child: Stack(
                children: [
                  // Background Glow
                  if (isHovered)
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              feature.gradient[0].withOpacity(0.3),
                              feature.gradient[0].withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Content - محسّن لمنع overflow
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxHeight < 180;
                      return Padding(
                        padding: EdgeInsets.all(isCompact ? 12 : 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon - جزء ثابت
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isHovered ? 48 : 44,
                              height: isHovered ? 48 : 44,
                              decoration: BoxDecoration(
                                gradient:
                                    LinearGradient(colors: feature.gradient),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: feature.gradient[0].withOpacity(0.4),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                feature.icon,
                                color: Colors.white,
                                size: isHovered ? 24 : 22,
                              ),
                            ),

                            // Spacer مرن
                            const SizedBox(height: 8),

                            // Text Content - مرن ومحمي من overflow
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Title
                                  Flexible(
                                    child: Text(
                                      feature.title,
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        color: AppTheme.textWhite,
                                        fontWeight: FontWeight.w600,
                                        fontSize: isCompact ? 14 : 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  const SizedBox(height: 2),

                                  // Description
                                  Flexible(
                                    child: Text(
                                      feature.description,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppTheme.textMuted,
                                        height: 1.2,
                                        fontSize: isCompact ? 10 : 11,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  // Count Badge - مخفي في المساحات الصغيرة
                                  if (!isCompact) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: feature.gradient[0]
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: feature.gradient[0]
                                              .withOpacity(0.3),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        feature.count == null
                                            ? '...'
                                            : '${feature.count} عنصر',
                                        style: AppTextStyles.caption.copyWith(
                                          color: feature.gradient[0],
                                          fontWeight: FontWeight.w600,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Arrow Indicator
                  if (!isHovered)
                    const SizedBox.shrink()
                  else
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isHovered ? 1.0 : 0.0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.glassLight.withOpacity(0.2),
                            border: Border.all(
                              color: AppTheme.glowWhite.withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingHeader(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      top: _showFloatingHeader ? 0 : -100,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              bottom: 12,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: AppTheme.darkCard.withOpacity(0.8),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.glowBlue.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.dashboard_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'لوحة التحكم',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Quick Stats
                Row(
                  children: [
                    BlocProvider<NotificationBloc>(
                      create: (_) => di.sl<NotificationBloc>()
                        ..add(const LoadUnreadCountEvent()),
                      child: BlocBuilder<NotificationBloc, NotificationState>(
                        builder: (context, state) {
                          String value = '0';
                          if (state is NotificationLoaded) {
                            value = state.unreadCount.toString();
                          } else if (state is NotificationUnreadCountLoaded) {
                            value = state.unreadCount.toString();
                          }
                          return _buildMiniStat(
                            icon: Icons.notifications_active,
                            value: value,
                            color: AppTheme.warning,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildMiniStat(
                      icon: Icons.people,
                      value: '127',
                      color: AppTheme.success,
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

  Widget _buildMiniStat({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _pulseAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (0.05 * _pulseAnimationController.value),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.glowBlue.withOpacity(0.4),
                    blurRadius: 14 + (6 * _pulseAnimationController.value),
                    spreadRadius: 1,
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
                  borderRadius: BorderRadius.circular(22),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    HapticFeedback.lightImpact();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Search',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScreenSearchDialog(
          searchService: di.sl<ScreenSearchService>(),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: child,
          ),
        );
      },
    );
  }

  String _formatLastLogin() {
    final now = DateTime.now();
    final lastLogin = now.subtract(const Duration(hours: 2));
    final difference = now.difference(lastLogin);

    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }

  // Admin Features List
  List<_AdminFeature> get _adminFeatures => [
        _AdminFeature(
          title: 'الحجوزات',
          description: 'إدارة الحجوزات والتقويم والتحليلات',
          icon: Icons.event_available_rounded,
          gradient: [AppTheme.primaryBlue, AppTheme.neonBlue],
          onTap: () => context.push('/admin/bookings'),
          count: _stats['bookings'],
        ),
        _AdminFeature(
          title: 'العقارات',
          description: 'إدارة جميع العقارات',
          icon: Icons.apartment_rounded,
          gradient: [AppTheme.primaryBlue, AppTheme.primaryCyan],
          onTap: () => context.push('/admin/properties'),
          count: _stats['properties'],
          adminOnly: true,
        ),
        _AdminFeature(
          title: 'أنواع العقارات',
          description: 'الفئات والأنواع',
          icon: Icons.category_rounded,
          gradient: [AppTheme.primaryViolet, AppTheme.neonPurple],
          onTap: () => context.push('/admin/property-types'),
          adminOnly: true,
        ),
        _AdminFeature(
          title: 'الوحدات',
          description: 'الوحدات السكنية',
          icon: Icons.home_work_rounded,
          gradient: [AppTheme.neonPurple, AppTheme.neonBlue],
          onTap: () => context.push('/admin/units'),
          adminOnly: true,
          visibleForOwner: true,
        ),
        _AdminFeature(
          title: 'الخدمات',
          description: 'الخدمات الإضافية',
          icon: Icons.room_service_rounded,
          gradient: [AppTheme.primaryCyan, AppTheme.primaryBlue],
          onTap: () => context.push('/admin/services'),
        ),
        _AdminFeature(
          title: 'المرافق',
          description: 'مرافق العقارات',
          icon: Icons.pool_rounded,
          gradient: [AppTheme.primaryBlue, AppTheme.primaryPurple],
          onTap: () => context.push('/admin/amenities'),
          adminOnly: true,
        ),
        _AdminFeature(
          title: 'السياسات',
          description: 'سياسات العقارات والحجوزات',
          icon: Icons.policy_rounded,
          gradient: [AppTheme.error, AppTheme.primaryViolet],
          onTap: () => context.push('/admin/policies'),
        ),
        _AdminFeature(
          title: 'المراجعات',
          description: 'آراء العملاء',
          icon: Icons.reviews_rounded,
          gradient: [AppTheme.primaryPurple, AppTheme.primaryViolet],
          onTap: () => context.push('/admin/reviews'),
        ),
        _AdminFeature(
          title: 'المدن',
          description: 'المواقع المتاحة',
          icon: Icons.location_city_rounded,
          gradient: [AppTheme.primaryViolet, AppTheme.neonGreen],
          onTap: () => context.push('/admin/cities'),
          adminOnly: true,
        ),
        _AdminFeature(
          title: 'المستخدمون',
          description: 'إدارة المستخدمين',
          icon: Icons.people_alt_rounded,
          gradient: [AppTheme.neonGreen, AppTheme.neonBlue],
          onTap: () => context.push('/admin/users'),
          count: _stats['users'].toInt(),
          adminOnly: true,
        ),
        _AdminFeature(
          title: 'سجلات التدقيق',
          description: 'أنشطة النظام',
          icon: Icons.receipt_long_rounded,
          gradient: [AppTheme.neonBlue, AppTheme.primaryBlue],
          onTap: () => context.push('/admin/audit-logs'),
        ),
        _AdminFeature(
          title: 'الأسعار',
          description: 'التوفر والأسعار',
          icon: Icons.calendar_month_rounded,
          gradient: [AppTheme.primaryBlue, AppTheme.neonPurple],
          onTap: () => context.push('/admin/availability-pricing'),
          adminOnly: true,
        ),
        _AdminFeature(
          title: 'العملات',
          description: 'إعدادات العملة',
          icon: Icons.payments_rounded,
          gradient: [AppTheme.warning, AppTheme.neonPurple],
          onTap: () => context.push('/admin/currencies'),
          adminOnly: true,
        ),
        _AdminFeature(
          title: 'الأقسام',
          description: 'إدارة أقسام الواجهة والمحتوى',
          icon: Icons.view_quilt_rounded,
          gradient: [AppTheme.primaryCyan, AppTheme.primaryPurple],
          onTap: () => context.push('/admin/sections'),
          adminOnly: true,
        ),
        _AdminFeature(
          title: 'الإشعارات',
          description: 'إدارة إشعارات النظام والمستخدمين',
          icon: Icons.notifications_active_rounded,
          gradient: [AppTheme.warning, AppTheme.primaryViolet],
          onTap: () => context.push('/admin/notifications'),
          adminOnly: true,
        ),
        _AdminFeature(
          title: 'النظام المحاسبي',
          description: 'لوحة التحكم المالية الشاملة والتقارير',
          icon: Icons.account_balance_rounded,
          gradient: [AppTheme.primaryCyan, AppTheme.primaryBlue],
          onTap: () => context.push('/admin/financial/dashboard'),
          adminOnly: true,
        ),
        _AdminFeature(
          title: 'المدفوعات',
          description: 'إدارة المعاملات المالية والاستردادات',
          icon: Icons.account_balance_wallet_rounded,
          gradient: [AppTheme.neonGreen, AppTheme.primaryCyan],
          onTap: () => context.push('/admin/payments'),
          adminOnly: true,
          visibleForOwner: true,
        ),
        _AdminFeature(
          title: 'الإعدادات',
          description: 'إعدادات النظام',
          icon: Icons.settings_rounded,
          gradient: [AppTheme.primaryPurple, AppTheme.primaryCyan],
          onTap: () => context.push('/admin/settings'),
        ),
      ];
}

// Data Models
class _AdminFeature {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
  final int? count;
  final bool adminOnly;
  final bool visibleForOwner;

  _AdminFeature({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.count,
    this.adminOnly = false,
    this.visibleForOwner = false,
  });
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final String trend;
  final bool isPositive;

  _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.trend,
    required this.isPositive,
  });
}

// Grid Pattern Painter
class _GridPatternPainter extends CustomPainter {
  final Color color;
  final double spacing;

  _GridPatternPainter({
    required this.color,
    this.spacing = 60,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
