// lib/features/admin_users/presentation/pages/user_details_page.dart

import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:bookn_cp_app/core/widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';
import 'package:bookn_cp_app/injection_container.dart' as di;
import 'package:bookn_cp_app/features/admin_financial/domain/repositories/financial_repository.dart';
import 'package:bookn_cp_app/features/admin_bookings/domain/usecases/bookings/get_bookings_by_user_usecase.dart';
import 'package:bookn_cp_app/features/admin_bookings/domain/entities/booking.dart';
import 'package:bookn_cp_app/features/admin_bookings/presentation/widgets/futuristic_bookings_table.dart';
import 'package:bookn_cp_app/features/admin_bookings/presentation/widgets/booking_actions_dialog.dart';
import 'package:bookn_cp_app/features/admin_reviews/domain/usecases/get_all_reviews_usecase.dart';
import 'package:bookn_cp_app/features/admin_reviews/domain/entities/review.dart';
import 'package:bookn_cp_app/features/admin_reviews/presentation/widgets/futuristic_reviews_table.dart';
import 'package:bookn_cp_app/features/admin_audit_logs/domain/entities/audit_log.dart';
import 'package:bookn_cp_app/features/admin_audit_logs/domain/usecases/get_audit_logs_usecase.dart';
import 'package:bookn_cp_app/features/admin_audit_logs/presentation/widgets/futuristic_audit_log_card.dart';
import 'package:bookn_cp_app/features/admin_audit_logs/presentation/widgets/audit_log_details_dialog.dart';
import 'package:bookn_cp_app/features/admin_bookings/domain/usecases/bookings/confirm_booking_usecase.dart';
import 'package:bookn_cp_app/features/admin_bookings/domain/usecases/bookings/cancel_booking_usecase.dart';
import 'package:bookn_cp_app/features/admin_bookings/domain/usecases/bookings/check_in_usecase.dart';
import 'package:bookn_cp_app/features/admin_bookings/domain/usecases/bookings/check_out_usecase.dart';
import 'package:bookn_cp_app/core/widgets/glassmorphic_tooltip.dart';
import '../bloc/user_details/user_details_bloc.dart';
import '../widgets/user_role_selector.dart';
import '../widgets/last_seen_widget.dart';

class UserDetailsPage extends StatefulWidget {
  final String userId;

  const UserDetailsPage({
    super.key,
    required this.userId,
  });

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _backgroundAnimationController;
  late AnimationController _glowController;
  late AnimationController _contentAnimationController;
  late AnimationController _statsAnimationController;

  // Animations
  late Animation<double> _backgroundRotation;
  late Animation<double> _glowAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;
  late Animation<double> _statsScaleAnimation;

  // Tab Controller
  late TabController _tabController;

  // State
  String _selectedTab = 'overview';
  // Bookings state
  final int _bookingsPageSize = 10;
  List<Booking> _userBookings = [];
  bool _isLoadingBookings = false;
  String? _bookingsError;
  int _bookingsPage = 1;
  bool _bookingsHasMore = true;
  // Reviews state
  final int _reviewsPageSize = 10;
  List<Review> _userReviews = [];
  bool _isLoadingReviews = false;
  String? _reviewsError;
  int _reviewsPage = 1;
  bool _reviewsHasMore = true;
  // Activity state
  final int _activityPageSize = 10;
  List<AuditLog> _userActivityLogs = [];
  bool _isLoadingActivity = false;
  String? _activityError;
  int _activityPage = 1;
  bool _activityHasMore = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserDetails();
  }

  Future<void> _processOwnerPayout(String userId) async {
    try {
      // Optional: haptic feedback
      HapticFeedback.lightImpact();

      final repo = di.sl<FinancialRepository>();
      final resultEither = await repo.processOwnerPayouts(
        ownerIds: [userId],
        previewOnly: false,
      );

      resultEither.fold(
        (failure) => _showSnack(failure.message),
        (result) {
          final success = (result['success'] == true) || (result['isSuccess'] == true);
          final message = (result['message'] as String?) ?? (success ? 'تم تنفيذ تحويل المستحقات' : 'فشل تنفيذ تحويل المستحقات');
          _showSnack(message);
        },
      );
    } catch (e) {
      _showSnack('حدث خطأ: ${e.toString()}');
    }
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _initializeAnimations() {
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _statsAnimationController = AnimationController(
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
      begin: 0.3,
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
      curve: Curves.easeOut,
    ));

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOutQuart,
    ));

    _statsScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statsAnimationController,
      curve: Curves.elasticOut,
    ));

    _tabController = TabController(length: 4, vsync: this);

    // Start animations
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _contentAnimationController.forward();
        _statsAnimationController.forward();
      }
    });
  }

  void _loadUserDetails() {
    context.read<UserDetailsBloc>().add(
          LoadUserDetailsEvent(userId: widget.userId),
        );
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _glowController.dispose();
    _contentAnimationController.dispose();
    _statsAnimationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          BlocListener<UserDetailsBloc, UserDetailsState>(
            listener: (context, state) {
              // عند العودة من صفحة التحديث، نعيد تحميل البيانات
              if (state is UserDetailsLoaded) {
                // البيانات تم تحميلها بنجاح
              }
            },
            child: BlocBuilder<UserDetailsBloc, UserDetailsState>(
              builder: (context, state) {
                if (state is UserDetailsLoading) {
                  return const LoadingWidget(
                    type: LoadingType.futuristic,
                    message: 'جاري تحميل بيانات المستخدم...',
                  );
                }
                if (state is UserDetailsError) {
                  return _buildErrorState(state.message);
                }
                if (state is UserDetailsLoaded) {
                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      _buildSliverAppBar(state),
                      SliverToBoxAdapter(child: _buildUserInfoCard(state)),
                      SliverToBoxAdapter(child: _buildStatsSection(state)),
                      SliverToBoxAdapter(child: _buildTabNavigation(state)),
                      _buildTabContentSliver(state),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          _buildFloatingActionButton(),

          // Futuristic overlay during user actions (role/status/update)
          BlocBuilder<UserDetailsBloc, UserDetailsState>(
            builder: (context, state) {
              if (state is UserDetailsLoaded && state.isUpdating) {
                return Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: LoadingWidget(
                        type: LoadingType.futuristic,
                        message: 'جاري تنفيذ العملية...'),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([_backgroundRotation, _glowAnimation]),
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
            painter: _FuturisticBackgroundPainter(
              rotation: _backgroundRotation.value,
              glowIntensity: _glowAnimation.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  SliverAppBar _buildSliverAppBar(UserDetailsLoaded state) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: AppTheme.darkBackground,
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: AppTheme.darkCard.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Icon(Icons.arrow_back_rounded,
              color: Colors.white, size: 20),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Text(
          'تفاصيل المستخدم',
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
        _buildHeaderAction(
          icon: Icons.edit_rounded,
          onPressed: () => _navigateToEditPage(state),
        ),
        _buildHeaderAction(
          icon: Icons.security_rounded,
          onPressed: () => _showRoleSelector(state),
        ),
        _buildHeaderAction(
          icon: Icons.receipt_long_rounded,
          onPressed: () => context.push('/admin/financial/transactions', extra: {
            'userId': state.userDetails.id,
          }),
        ),
        if ((state.userDetails.role ?? '').toLowerCase() == 'owner')
          _buildHeaderAction(
            icon: Icons.payments_rounded,
            onPressed: () => _processOwnerPayout(state.userDetails.id),
          ),
        _buildHeaderAction(
          icon: state.userDetails.isActive
              ? Icons.block_rounded
              : Icons.check_circle_rounded,
          isActive: !state.userDetails.isActive,
          onPressed: () => _toggleUserStatus(state),
        ),
        _buildHeaderAction(
          icon: Icons.delete_rounded,
          isDanger: true,
          onPressed: _showDeleteConfirmation,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
    bool isDanger = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDanger
                  ? AppTheme.error
                  : isActive
                      ? AppTheme.primaryBlue
                      : AppTheme.darkBorder)
              .withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: isDanger
                  ? AppTheme.error
                  : (isActive ? AppTheme.primaryBlue : AppTheme.textWhite),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(UserDetailsLoaded state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.7),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: [
              // Back Button
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.darkSurface.withOpacity(0.5),
                        AppTheme.darkSurface.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.darkBorder.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: AppTheme.textWhite,
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Title with gradient
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppTheme.primaryGradient.createShader(bounds),
                      child: Text(
                        'تفاصيل المستخدم',
                        style: AppTextStyles.heading1.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.userDetails.userName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildActionButton(
                        icon: Icons.edit_rounded,
                        label: 'تعديل',
                        onTap: () => _navigateToEditPage(state),
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.security_rounded,
                        label: 'الصلاحيات',
                        onTap: () => _showRoleSelector(state),
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.receipt_long_rounded,
                        label: 'القيود',
                        onTap: () => context.push('/admin/financial/transactions', extra: {
                          'userId': state.userDetails.id,
                        }),
                      ),
                      if ((state.userDetails.role ?? '').toLowerCase() == 'owner') ...[
                        const SizedBox(width: 8),
                        _buildActionButton(
                          icon: Icons.payments_rounded,
                          label: 'تحويل مستحقات',
                          onTap: () => _processOwnerPayout(state.userDetails.id),
                        ),
                      ],
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: state.userDetails.isActive
                            ? Icons.block_rounded
                            : Icons.check_circle_rounded,
                        label: state.userDetails.isActive ? 'تعطيل' : 'تفعيل',
                        onTap: () => _toggleUserStatus(state),
                        isActive: !state.userDetails.isActive,
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.delete_rounded,
                        label: 'حذف',
                        onTap: () => _showDeleteConfirmation(),
                        isDanger: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    bool isDanger = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive
              ? AppTheme.primaryGradient
              : isDanger
                  ? LinearGradient(
                      colors: [
                        AppTheme.error.withOpacity(0.2),
                        AppTheme.error.withOpacity(0.1),
                      ],
                    )
                  : LinearGradient(
                      colors: [
                        AppTheme.darkCard.withOpacity(0.5),
                        AppTheme.darkCard.withOpacity(0.3),
                      ],
                    ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppTheme.primaryBlue.withOpacity(0.5)
                : isDanger
                    ? AppTheme.error.withOpacity(0.3)
                    : AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? Colors.white
                  : isDanger
                      ? AppTheme.error
                      : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isActive
                    ? Colors.white
                    : isDanger
                        ? AppTheme.error
                        : AppTheme.textMuted,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(UserDetailsLoaded state) {
    final user = state.userDetails;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.7),
            AppTheme.darkCard.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: [
              // Avatar
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: user.avatarUrl != null
                          ? null
                          : AppTheme.primaryGradient,
                      border: Border.all(
                        color: user.isActive
                            ? AppTheme.success.withOpacity(0.5)
                            : AppTheme.textMuted.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: user.isActive
                          ? [
                              BoxShadow(
                                color: AppTheme.success
                                    .withOpacity(0.3 * _glowAnimation.value),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: user.avatarUrl != null &&
                            user.avatarUrl!.trim().isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              user.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultAvatar(user.userName);
                              },
                            ),
                          )
                        : _buildDefaultAvatar(user.userName),
                  );
                },
              ),

              const SizedBox(width: 20),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and Status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.userName,
                            style: AppTextStyles.heading3.copyWith(
                              color: AppTheme.textWhite,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatusBadge(user.isActive),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Email
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 14,
                          color: AppTheme.textMuted.withOpacity(0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          user.email,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Phone
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: AppTheme.textMuted.withOpacity(0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          user.phoneNumber,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Last Seen Widget
                    LastSeenWidget(
                      lastSeen: user.lastSeen,
                      style: LastSeenStyle.detailed,
                      showIcon: true,
                      showAnimation: true,
                    ),

                    const SizedBox(height: 12),

                    // Role Badge
                    if (user.role != null) _buildRoleBadge(user.role!),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Center(
      child: Text(
        initial,
        style: AppTextStyles.heading2.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.success.withOpacity(0.1)
            : AppTheme.textMuted.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? AppTheme.success.withOpacity(0.3)
              : AppTheme.textMuted.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppTheme.success : AppTheme.textMuted,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'نشط' : 'غير نشط',
            style: AppTextStyles.caption.copyWith(
              color: isActive ? AppTheme.success : AppTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getRoleGradient(role),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _getRoleText(role),
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatsSection(UserDetailsLoaded state) {
    final user = state.userDetails;

    return AnimatedBuilder(
      animation: _statsScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _statsScaleAnimation.value,
          child: Container(
            constraints: const BoxConstraints(minHeight: 132),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'الحجوزات',
                    value: user.bookingsCount.toString(),
                    icon: Icons.book_online_rounded,
                    color: AppTheme.primaryBlue,
                    trend: '+5',
                    isPositive: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'المدفوعات',
                    value: '﷼${user.totalPayments.toStringAsFixed(0)}',
                    icon: Icons.payments_rounded,
                    color: AppTheme.success,
                    trend: '+12%',
                    isPositive: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'المراجعات',
                    value: user.reviewsCount.toString(),
                    icon: Icons.star_rounded,
                    color: AppTheme.warning,
                    trend: '3',
                    isPositive: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'النقاط',
                    value: user.loyaltyPoints?.toString() ?? '0',
                    icon: Icons.loyalty_rounded,
                    color: AppTheme.primaryPurple,
                    trend: '+20',
                    isPositive: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? trend,
    bool isPositive = true,
  }) {
    final GlobalKey _statCardKey = GlobalKey();
    return GestureDetector(
      onLongPress: () {
        String message = '📊 القيمة الحالية: ' + value + '\n\n';
        // تفاصيل إضافية
        if (trend != null) {
          message += 'الاتجاه: ' + trend + (isPositive ? ' ↑' : ' ↓');
        }
        GlasmorphicTooltip.show(
          context: context,
          targetKey: _statCardKey,
          title: title,
          message: message,
          accentColor: color,
          icon: icon,
          duration: const Duration(seconds: 5),
        );
      },
      child: Container(
        key: _statCardKey,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                OverflowBar(
                  alignment: MainAxisAlignment.spaceBetween,
                  overflowAlignment: OverflowBarAlignment.center,
                  spacing: 8,
                  overflowSpacing: 4,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.3),
                            color.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 14,
                      ),
                    ),
                    if (trend != null)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isPositive
                                ? AppTheme.success.withOpacity(0.1)
                                : AppTheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPositive
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                                size: 10,
                                color: isPositive
                                    ? AppTheme.success
                                    : AppTheme.error,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                trend,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isPositive
                                      ? AppTheme.success
                                      : AppTheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabNavigation(UserDetailsLoaded state) {
    final tabs = [
      {'id': 'overview', 'label': 'نظرة عامة', 'icon': Icons.dashboard_rounded},
      {
        'id': 'bookings',
        'label': 'الحجوزات',
        'icon': Icons.book_online_rounded
      },
      {'id': 'reviews', 'label': 'المراجعات', 'icon': Icons.star_rounded},
      {'id': 'activity', 'label': 'النشاط', 'icon': Icons.timeline_rounded},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: tabs.map((tab) {
          final isActive = _selectedTab == tab['id'];

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = tab['id'] as String;
                });
                HapticFeedback.lightImpact();
                _ensureTabDataLoaded(state);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isActive ? AppTheme.primaryGradient : null,
                  color: !isActive ? AppTheme.darkCard.withOpacity(0.3) : null,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? AppTheme.primaryBlue.withOpacity(0.5)
                        : AppTheme.darkBorder.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 16,
                      color: isActive ? Colors.white : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab['label'] as String,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isActive ? Colors.white : AppTheme.textMuted,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  SliverToBoxAdapter _buildTabContentSliver(UserDetailsLoaded state) {
    Widget child;
    switch (_selectedTab) {
      case 'bookings':
        child = _buildBookingsTab(state);
        break;
      case 'reviews':
        child = _buildReviewsTab(state);
        break;
      case 'activity':
        child = _buildActivityTab(state);
        break;
      case 'overview':
      default:
        child = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _buildOverviewTab(state),
        );
        break;
    }
    return SliverToBoxAdapter(child: child);
  }

  Widget _buildOverviewTab(UserDetailsLoaded state) {
    final user = state.userDetails;
    return Column(
      children: [
        _buildSectionCard(
          title: 'معلومات الحساب',
          icon: Icons.account_circle_rounded,
          children: [
            _buildDetailRow('معرف المستخدم', user.id),
            _buildDetailRow('الاسم', user.userName),
            _buildDetailRow('البريد الإلكتروني', user.email),
            _buildDetailRow('الهاتف', user.phoneNumber),
            _buildDetailRow('تاريخ الإنشاء', _formatDate(user.createdAt)),
            if (user.role != null)
              _buildDetailRow('الدور', _getRoleText(user.role!)),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'إحصائيات الحجوزات',
          icon: Icons.analytics_rounded,
          children: [
            _buildDetailRow('إجمالي الحجوزات', user.bookingsCount.toString()),
            _buildDetailRow(
                'الحجوزات الملغاة', user.canceledBookingsCount.toString()),
            _buildDetailRow(
                'الحجوزات المعلقة', user.pendingBookingsCount.toString()),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'المعاملات المالية',
          icon: Icons.account_balance_wallet_rounded,
          children: [
            _buildDetailRow('إجمالي المدفوعات',
                '﷼${user.totalPayments.toStringAsFixed(2)}'),
            _buildDetailRow(
                'إجمالي المردودات', '﷼${user.totalRefunds.toStringAsFixed(2)}'),
          ],
        ),
      ],
    );
  }

  Widget _buildBookingsTab(UserDetailsLoaded state) {
    if (_isLoadingBookings && _userBookings.isEmpty) {
      return const LoadingWidget(
        type: LoadingType.futuristic,
        message: 'جاري تحميل الحجوزات...',
      );
    }
    if (_bookingsError != null) {
      return _buildErrorState(_bookingsError!);
    }
    if (_userBookings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.book_online_rounded,
        title: 'لا توجد حجوزات',
        subtitle: 'لم يتم العثور على حجوزات لهذا المستخدم',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FuturisticBookingsTable(
          bookings: _userBookings,
          selectedBookings: const [],
          onBookingTap: (bookingId) =>
              context.push('/admin/bookings/$bookingId'),
          onSelectionChanged: (_) {},
          showActions: true,
          onConfirm: (bookingId) => _handleConfirmBooking(bookingId),
          onCancel: (bookingId) => _handleCancelBooking(bookingId),
          onCheckIn: (bookingId) => _handleCheckIn(bookingId),
          onCheckOut: (bookingId) => _handleCheckOut(bookingId),
        ),
        const SizedBox(height: 12),
        if (_bookingsHasMore)
          Center(
            child: GestureDetector(
              onTap: _isLoadingBookings
                  ? null
                  : () =>
                      _loadUserBookings(state.userDetails.id, loadMore: true),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _isLoadingBookings ? 'جاري التحميل...' : 'تحميل المزيد',
                  style:
                      AppTextStyles.buttonMedium.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReviewsTab(UserDetailsLoaded state) {
    if (_isLoadingReviews && _userReviews.isEmpty) {
      return const LoadingWidget(
        type: LoadingType.futuristic,
        message: 'جاري تحميل المراجعات...',
      );
    }
    if (_reviewsError != null) {
      return _buildErrorState(_reviewsError!);
    }
    if (_userReviews.isEmpty) {
      return _buildEmptyState(
        icon: Icons.star_rounded,
        title: 'لا توجد مراجعات',
        subtitle: 'لم يتم العثور على مراجعات لهذا المستخدم',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FuturisticReviewsTable(
          reviews: _userReviews,
          onReviewTap: (review) =>
              context.push('/admin/reviews/details', extra: review.id),
          onApproveTap: (_) {},
          onDeleteTap: (_) {},
          approvingReviewIds: const {},
          shrinkWrap: true,
        ),
        const SizedBox(height: 12),
        if (_reviewsHasMore)
          Center(
            child: GestureDetector(
              onTap: _isLoadingReviews
                  ? null
                  : () =>
                      _loadUserReviews(state.userDetails.id, loadMore: true),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _isLoadingReviews ? 'جاري التحميل...' : 'تحميل المزيد',
                  style:
                      AppTextStyles.buttonMedium.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActivityTab(UserDetailsLoaded state) {
    if (_isLoadingActivity && _userActivityLogs.isEmpty) {
      return const LoadingWidget(
        type: LoadingType.futuristic,
        message: 'جاري تحميل النشاط...',
      );
    }
    if (_activityError != null) {
      return _buildErrorState(_activityError!);
    }
    if (_userActivityLogs.isEmpty) {
      return _buildEmptyState(
        icon: Icons.timeline_rounded,
        title: 'لا يوجد نشاط',
        subtitle: 'لم يتم العثور على نشاط لهذا المستخدم',
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isGrid = constraints.maxWidth > 700;
              if (isGrid) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _userActivityLogs.length,
                  itemBuilder: (context, index) {
                    final log = _userActivityLogs[index];
                    return FuturisticAuditLogCard(
                      auditLog: log,
                      onTap: () => _showAuditLogDetails(log),
                      isGridView: true,
                    );
                  },
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _userActivityLogs.length,
                itemBuilder: (context, index) {
                  final log = _userActivityLogs[index];
                  return FuturisticAuditLogCard(
                    auditLog: log,
                    onTap: () => _showAuditLogDetails(log),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          if (_activityHasMore)
            Center(
              child: GestureDetector(
                onTap: _isLoadingActivity
                    ? null
                    : () => _loadUserActivityLogs(state.userDetails.id,
                        loadMore: true),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _isLoadingActivity ? 'جاري التحميل...' : 'تحميل المزيد',
                    style: AppTextStyles.buttonMedium
                        .copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Data loading helpers
  void _ensureTabDataLoaded(UserDetailsLoaded state) {
    if (_selectedTab == 'bookings' &&
        _userBookings.isEmpty &&
        !_isLoadingBookings) {
      _loadUserBookings(state.userDetails.id);
    } else if (_selectedTab == 'reviews' &&
        _userReviews.isEmpty &&
        !_isLoadingReviews) {
      _loadUserReviews(state.userDetails.id);
    } else if (_selectedTab == 'activity' &&
        _userActivityLogs.isEmpty &&
        !_isLoadingActivity) {
      _loadUserActivityLogs(state.userDetails.id);
    }
  }

  Future<void> _loadUserBookings(String userId, {bool loadMore = false}) async {
    setState(() {
      _isLoadingBookings = true;
      _bookingsError = null;
      if (!loadMore) {
        _bookingsPage = 1;
        _userBookings = [];
        _bookingsHasMore = true;
      }
    });
    try {
      final useCase = di.sl<GetBookingsByUserUseCase>();
      final result = await useCase(GetBookingsByUserParams(
        userId: userId,
        pageNumber: _bookingsPage,
        pageSize: _bookingsPageSize,
      ));
      result.fold((failure) {
        setState(() {
          _bookingsError = failure.message;
        });
      }, (paginated) {
        setState(() {
          final existingIds = _userBookings.map((b) => b.id).toSet();
          final newItems = paginated.items
              .where((b) => !existingIds.contains(b.id))
              .toList();
          _userBookings = [..._userBookings, ...newItems];
          final totalCount = paginated.totalCount;
          final loadedCount = _userBookings.length;
          _bookingsHasMore = loadedCount < totalCount;
          if (_bookingsHasMore) {
            _bookingsPage += 1;
          }
        });
      });
    } catch (e) {
      setState(() {
        _bookingsError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingBookings = false);
      }
    }
  }

  Future<void> _loadUserReviews(String userId, {bool loadMore = false}) async {
    setState(() {
      _isLoadingReviews = true;
      _reviewsError = null;
      if (!loadMore) {
        _reviewsPage = 1;
        _userReviews = [];
        _reviewsHasMore = true;
      }
    });
    try {
      final useCase = di.sl<GetAllReviewsUseCase>();
      final result = await useCase(GetAllReviewsParams(
        userId: userId,
        pageNumber: _reviewsPage,
        pageSize: _reviewsPageSize,
      ));
      result.fold((failure) {
        setState(() {
          _reviewsError = failure.message;
        });
      }, (paginated) {
        setState(() {
          final existingIds = _userReviews.map((r) => r.id).toSet();
          final newItems = paginated.items
              .where((r) => !existingIds.contains(r.id))
              .toList();
          _userReviews = [..._userReviews, ...newItems];
          final totalCount = paginated.totalCount;
          final loadedCount = _userReviews.length;
          _reviewsHasMore = loadedCount < totalCount;
          if (_reviewsHasMore) {
            _reviewsPage += 1;
          }
        });
      });
    } catch (e) {
      setState(() {
        _reviewsError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingReviews = false);
      }
    }
  }

  Future<void> _loadUserActivityLogs(String userId,
      {bool loadMore = false}) async {
    setState(() {
      _isLoadingActivity = true;
      _activityError = null;
      if (!loadMore) {
        _activityPage = 1;
        _userActivityLogs = [];
        _activityHasMore = true;
      }
    });
    try {
      final useCase = di.sl<GetAuditLogsUseCase>();
      final result = await useCase(AuditLogsQuery(
        userId: userId,
        pageNumber: _activityPage,
        pageSize: _activityPageSize,
      ));
      result.fold((failure) {
        setState(() {
          _activityError = failure.message;
        });
      }, (paginated) {
        setState(() {
          final existingIds = _userActivityLogs.map((a) => a.id).toSet();
          final newItems = paginated.items
              .where((a) => !existingIds.contains(a.id))
              .toList();
          _userActivityLogs = [..._userActivityLogs, ...newItems];
          final totalCount = paginated.totalCount;
          final loadedCount = _userActivityLogs.length;
          _activityHasMore = loadedCount < totalCount;
          if (_activityHasMore) {
            _activityPage += 1;
          }
        });
      });
    } catch (e) {
      setState(() {
        _activityError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingActivity = false);
      }
    }
  }

  void _showAuditLogDetails(AuditLog log) {
    showDialog(
      fullscreenDialog: true,
      context: context,
      builder: (context) => AuditLogDetailsDialog(auditLog: log),
    );
  }

  // Booking actions
  Future<void> _handleConfirmBooking(String bookingId) async {
    try {
      final result = await di.sl<ConfirmBookingUseCase>()(
          ConfirmBookingParams(bookingId: bookingId));
      result.fold((failure) {}, (_) {
        // Refresh bookings
        if (mounted) _loadUserBookings(widget.userId);
      });
    } catch (_) {}
  }

  Future<void> _handleCancelBooking(String bookingId) async {
    showDialog(
      fullscreenDialog: true,
      context: context,
      builder: (context) => BookingActionsDialog(
        bookingId: bookingId,
        action: BookingAction.cancel,
        onConfirm: (reason) async {
          if (reason == null || reason.trim().isEmpty) return;
          try {
            final result = await di.sl<CancelBookingUseCase>()(
              CancelBookingParams(
                  bookingId: bookingId, cancellationReason: reason.trim()),
            );
            result.fold((failure) {}, (_) {
              if (mounted) _loadUserBookings(widget.userId);
            });
          } catch (_) {}
        },
      ),
    );
  }

  Future<void> _handleCheckIn(String bookingId) async {
    try {
      final result =
          await di.sl<CheckInUseCase>()(CheckInParams(bookingId: bookingId));
      result.fold((failure) {}, (_) {
        if (mounted) _loadUserBookings(widget.userId);
      });
    } catch (_) {}
  }

  Future<void> _handleCheckOut(String bookingId) async {
    try {
      final result =
          await di.sl<CheckOutUseCase>()(CheckOutParams(bookingId: bookingId));
      result.fold((failure) {}, (_) {
        if (mounted) _loadUserBookings(widget.userId);
      });
    } catch (_) {}
  }

  // FuturisticReviewsTable used instead of manual rows

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.5),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Flexible(
            flex: 4,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل بيانات المستخدم...',
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
            size: 64,
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
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _loadUserDetails,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'إعادة المحاولة',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.1),
                  AppTheme.primaryPurple.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 40,
              color: AppTheme.primaryBlue.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Positioned(
      bottom: 24,
      right: 24,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFAB(
                icon: Icons.message_rounded,
                color: AppTheme.primaryBlue,
                onTap: _sendMessage,
              ),
              const SizedBox(height: 12),
              _buildFAB(
                icon: Icons.email_rounded,
                color: AppTheme.primaryPurple,
                onTap: _sendEmail,
              ),
              const SizedBox(height: 12),
              _buildFAB(
                icon: Icons.call_rounded,
                color: AppTheme.success,
                onTap: _makeCall,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFAB({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  // Helper Methods
  void _navigateToEditPage(UserDetailsLoaded state) async {
    // الانتقال إلى صفحة التحديث والانتظار حتى تغلق
    await context.push(
      '/admin/users/${widget.userId}/edit',
      extra: {
        'name': state.userDetails.userName,
        'email': state.userDetails.email,
        'phone': state.userDetails.phoneNumber,
        'roleId': state.userDetails.role,
      },
    );

    // بعد العودة من صفحة التحديث، نعيد تحميل البيانات
    if (mounted) {
      _loadUserDetails();
    }
  }

  void _showRoleSelector(UserDetailsLoaded state) {
    // حفظ الـ bloc قبل فتح الـ BottomSheet
    final bloc = context.read<UserDetailsBloc>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => UserRoleSelector(
        currentRole: state.userDetails.role,
        onRoleSelected: (roleId) {
          // استخدام الـ bloc المحفوظ بدلاً من context.read
          bloc.add(
            AssignUserRoleEvent(
              userId: widget.userId,
              roleId: roleId,
            ),
          );
        },
      ),
    );
  }

  void _toggleUserStatus(UserDetailsLoaded state) {
    context.read<UserDetailsBloc>().add(
          ToggleUserStatusEvent(
            userId: widget.userId,
            activate: !state.userDetails.isActive,
          ),
        );
  }

  void _showDeleteConfirmation() {
    HapticFeedback.mediumImpact();
    showDialog(
      fullscreenDialog: true,
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => BackdropFilter(
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
                  'حذف المستخدم؟',
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
                        onPressed: () => Navigator.pop(dialogContext),
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
                          Navigator.pop(dialogContext);
                          context.read<UserDetailsBloc>().add(
                                DeleteUserEvent(userId: widget.userId),
                              );
                          context.pop();
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

  void _sendMessage() {
    // TODO: Implement send message
  }

  void _sendEmail() {
    // TODO: Implement send email
  }

  void _makeCall() {
    // TODO: Implement make call
  }

  List<Color> _getRoleGradient(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return [AppTheme.error, AppTheme.primaryViolet];
      case 'owner':
        return [AppTheme.primaryBlue, AppTheme.primaryPurple];
      case 'staff':
        return [AppTheme.warning, AppTheme.neonBlue];
      default:
        return [AppTheme.primaryCyan, AppTheme.neonGreen];
    }
  }

  String _getRoleText(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'مدير';
      case 'owner':
        return 'مالك';
      case 'staff':
        return 'موظف';
      case 'customer':
        return 'عميل';
      default:
        return role;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Delete Confirmation Dialog
class _DeleteConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const _DeleteConfirmationDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(10),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withOpacity(0.95),
              AppTheme.darkCard.withOpacity(0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.error.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.error.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.error.withOpacity(0.2),
                    AppTheme.error.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_rounded,
                color: AppTheme.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'تأكيد الحذف',
              style: AppTextStyles.heading3.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'هل أنت متأكد من حذف هذا المستخدم؟\nلا يمكن التراجع عن هذا الإجراء.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onConfirm();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.error,
                            AppTheme.error.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.error.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'حذف',
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
          ],
        ),
      ),
    );
  }
}

// Background Painter
class _FuturisticBackgroundPainter extends CustomPainter {
  final double rotation;
  final double glowIntensity;

  _FuturisticBackgroundPainter({
    required this.rotation,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw grid
    paint.color = AppTheme.primaryBlue.withOpacity(0.05);
    const spacing = 50.0;

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

    // Draw rotating circles
    final center = Offset(size.width / 2, size.height / 2);
    paint.color = AppTheme.primaryBlue.withOpacity(0.03 * glowIntensity);

    for (int i = 0; i < 3; i++) {
      final radius = 200.0 + i * 100;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation + i * 0.5);
      canvas.translate(-center.dx, -center.dy);
      canvas.drawCircle(center, radius, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
