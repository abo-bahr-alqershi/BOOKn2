// lib/features/auth/presentation/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/bloc/app_bloc.dart';
import '../../../../core/bloc/theme/theme_bloc.dart';
import '../../../../core/bloc/theme/theme_event.dart';
import '../../../../core/bloc/theme/theme_state.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/upload_user_image.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> 
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _subtleGlowController;
  late AnimationController _themeSwitchController;
  late Animation<double> _themeSwitchRotation;
  late Animation<double> _themeSwitchScale;
  
  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    
    _subtleGlowController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    
    _themeSwitchController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _themeSwitchRotation = Tween<double>(
      begin: 0,
      end: math.pi * 2,
    ).animate(CurvedAnimation(
      parent: _themeSwitchController,
      curve: Curves.easeInOut,
    ));
    
    _themeSwitchScale = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _themeSwitchController,
      curve: Curves.easeOutBack,
    ));
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _subtleGlowController.dispose();
    _themeSwitchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: BlocBuilder<AuthBloc, AuthState>(
        buildWhen: (previous, current) {
          // Avoid rebuilding on transient loading to prevent flicker to unauthenticated view
          return current is! AuthLoading;
        },
        builder: (context, state) {
          if (state is AuthUnauthenticated) {
            return _buildUnauthenticatedView(context);
          }

          // Extract user from states that carry it to keep UI stable during updates
          final dynamic user = state is AuthAuthenticated
              ? state.user
              : state is AuthProfileUpdateSuccess
                  ? state.user
                  : state is AuthProfileImageUploadSuccess
                      ? state.user
                      : state is AuthLoginSuccess
                          ? state.user
                          : null;

          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              _buildMinimalBackground(),
              
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildMinimalAppBar(context, user),
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeController,
                      child: Column(
                        children: [
                          _buildProfileHeader(context, user),
                          const SizedBox(height: 20),
                          _buildMinimalInfoCard(user),
                          const SizedBox(height: 16),
                          _buildMinimalMenuOptions(context),
                          const SizedBox(height: 16),
                          _buildLogoutButton(context),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // زر تبديل الثيم العائم
              _buildFloatingThemeToggle(),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildMinimalBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkBackground,
            AppTheme.darkSurface.withOpacity(0.8),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: _subtleGlowController,
        builder: (context, child) {
          return CustomPaint(
            painter: _MinimalBackgroundPainter(
              animationValue: _subtleGlowController.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  Widget _buildUnauthenticatedView(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.darkBackground,
            AppTheme.darkSurface.withOpacity(0.95),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.darkCard.withOpacity(0.3),
                      AppTheme.darkCard.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.15),
                    width: 0.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Center(
                      child: Icon(
                        Icons.person_outline_rounded,
                        size: 48,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'يرجى تسجيل الدخول',
                style: AppTextStyles.heading2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textWhite,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'قم بتسجيل الدخول للوصول إلى ملفك الشخصي',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              _buildMinimalButton(
                onPressed: () => context.push(RouteConstants.login),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.login_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'تسجيل الدخول',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalAppBar(BuildContext context, dynamic user) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryBlue.withOpacity(0.08),
                AppTheme.darkBackground.withOpacity(0.95),
              ],
            ),
          ),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: AppTheme.darkCard.withOpacity(0.1),
                child: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          'الملف الشخصي',
                          style: AppTextStyles.heading2.copyWith(
                            color: AppTheme.textWhite,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.darkCard.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: AppTheme.textWhite,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user) {
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _subtleGlowController,
                builder: (context, child) {
                  return Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.primaryBlue.withOpacity(
                            0.08 + (_subtleGlowController.value * 0.04),
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
              UploadUserImage(
                currentImageUrl: user.profileImage,
                onImageSelected: (imagePath) {
                  context.read<AuthBloc>().add(
                    UploadProfileImageEvent(imagePath: imagePath),
                  );
                },
                size: 90,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: user.isVerified
                  ? AppTheme.success.withOpacity(0.1)
                  : AppTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: user.isVerified
                    ? AppTheme.success.withOpacity(0.25)
                    : AppTheme.warning.withOpacity(0.25),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  user.isVerified
                      ? Icons.verified_rounded
                      : Icons.pending_rounded,
                  size: 14,
                  color: user.isVerified
                      ? AppTheme.success
                      : AppTheme.warning,
                ),
                const SizedBox(width: 6),
                Text(
                  user.isVerified ? 'حساب موثق' : 'في انتظار التحقق',
                  style: AppTextStyles.caption.copyWith(
                    color: user.isVerified
                        ? AppTheme.success
                        : AppTheme.warning,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalInfoCard(dynamic user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkCard.withOpacity(0.25),
              AppTheme.darkCard.withOpacity(0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.darkBorder.withOpacity(0.15),
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              children: [
                _buildMinimalInfoRow(
                  icon: Icons.email_outlined,
                  label: 'البريد الإلكتروني',
                  value: user.email,
                  verified: user.isEmailVerified,
                ),
                _buildDivider(),
                _buildMinimalInfoRow(
                  icon: Icons.phone_outlined,
                  label: 'رقم الهاتف',
                  value: user.phone,
                  verified: user.isPhoneVerified,
                ),
                _buildDivider(),
                _buildMinimalInfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'تاريخ الانضمام',
                  value: _formatDate(user.createdAt),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool? verified,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.15),
                width: 0.5,
              ),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryBlue,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (verified != null)
                      Icon(
                        verified
                            ? Icons.check_circle
                            : Icons.error_outline,
                        size: 14,
                        color: verified
                            ? AppTheme.success.withOpacity(0.8)
                            : AppTheme.warning.withOpacity(0.8),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppTheme.darkBorder.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  // زر تبديل الثيم العائم - يستخدم AppBloc.theme
  Widget _buildFloatingThemeToggle() {
    return BlocBuilder<ThemeBloc, ThemeState>(
      bloc: AppBloc.theme, // استخدام ThemeBloc من AppBloc
      builder: (context, themeState) {
        final isDark = themeState.themeMode == ThemeMode.dark;
        
        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 20,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _themeSwitchController.forward().then((_) {
                      _themeSwitchController.reverse();
                    });
                    AppBloc.theme.add(const ToggleThemeEvent()); // استخدام AppBloc.theme
                  },
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _themeSwitchRotation,
                      _themeSwitchScale,
                      _subtleGlowController,
                    ]),
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _themeSwitchRotation.value,
                        child: Transform.scale(
                          scale: _themeSwitchScale.value,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? [
                                        const Color(0xFFFDB813).withOpacity(0.15),
                                        const Color(0xFFFFE082).withOpacity(0.08),
                                      ]
                                    : [
                                        const Color(0xFF6366F1).withOpacity(0.15),
                                        const Color(0xFF8B5CF6).withOpacity(0.08),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFFFDB813).withOpacity(0.2 + _subtleGlowController.value * 0.1)
                                    : const Color(0xFF6366F1).withOpacity(0.2 + _subtleGlowController.value * 0.1),
                                width: 0.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? const Color(0xFFFDB813).withOpacity(0.1 + _subtleGlowController.value * 0.05)
                                      : const Color(0xFF6366F1).withOpacity(0.1 + _subtleGlowController.value * 0.05),
                                  blurRadius: 12 + _subtleGlowController.value * 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      decoration: BoxDecoration(
                                        gradient: RadialGradient(
                                          colors: isDark
                                              ? [
                                                  const Color(0xFFFDB813).withOpacity(0.05),
                                                  Colors.transparent,
                                                ]
                                              : [
                                                  const Color(0xFF6366F1).withOpacity(0.05),
                                                  Colors.transparent,
                                                ],
                                        ),
                                      ),
                                    ),
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 300),
                                      transitionBuilder: (child, animation) {
                                        return ScaleTransition(
                                          scale: animation,
                                          child: RotationTransition(
                                            turns: animation,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Icon(
                                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                        key: ValueKey(isDark),
                                        size: 20,
                                        color: isDark
                                            ? const Color(0xFFFDB813)
                                            : const Color(0xFF6366F1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // إضافة خيار تبديل الثيم في القائمة
  Widget _buildThemeToggleMenuItem() {
    return BlocBuilder<ThemeBloc, ThemeState>(
      bloc: AppBloc.theme, // استخدام AppBloc.theme
      builder: (context, themeState) {
        final isDark = themeState.themeMode == ThemeMode.dark;
        
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              _themeSwitchController.forward().then((_) {
                _themeSwitchController.reverse();
              });
              AppBloc.theme.add(const ToggleThemeEvent()); // استخدام AppBloc.theme
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _themeSwitchController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _themeSwitchRotation.value,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      const Color(0xFFFDB813).withOpacity(0.15),
                                      const Color(0xFFFFE082).withOpacity(0.08),
                                    ]
                                  : [
                                      const Color(0xFF6366F1).withOpacity(0.15),
                                      const Color(0xFF8B5CF6).withOpacity(0.08),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFFFDB813).withOpacity(0.2)
                                  : const Color(0xFF6366F1).withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                              key: ValueKey(isDark),
                              color: isDark
                                  ? const Color(0xFFFDB813)
                                  : const Color(0xFF6366F1),
                              size: 18,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مظهر التطبيق',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppTheme.textWhite,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isDark ? 'الوضع الداكن' : 'الوضع الفاتح',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textMuted.withOpacity(0.6),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildUltraSwitch(isDark),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUltraSwitch(bool value) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 46,
      height: 26,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: value
              ? [
                  const Color(0xFF6366F1).withOpacity(0.2),
                  const Color(0xFF8B5CF6).withOpacity(0.15),
                ]
              : [
                  AppTheme.darkBorder.withOpacity(0.15),
                  AppTheme.darkBorder.withOpacity(0.1),
                ],
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: value
              ? const Color(0xFF6366F1).withOpacity(0.3)
              : AppTheme.darkBorder.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            left: value ? 22 : 2,
            top: 2,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                gradient: value
                    ? const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      )
                    : LinearGradient(
                        colors: [
                          AppTheme.darkCard.withOpacity(0.5),
                          AppTheme.darkCard.withOpacity(0.3),
                        ],
                      ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: value
                        ? const Color(0xFF6366F1).withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    value ? Icons.dark_mode : Icons.light_mode,
                    key: ValueKey(value),
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalMenuOptions(BuildContext context) {
    final menuItems = [
      {
        'icon': Icons.edit_outlined,
        'title': 'تعديل الملف الشخصي',
        'route': RouteConstants.editProfile,
        'color': AppTheme.primaryBlue,
        'widget': null,
      },
      {
        'icon': Icons.lock_outline_rounded,
        'title': 'تغيير كلمة المرور',
        'route': RouteConstants.changePassword,
        'color': AppTheme.primaryPurple,
        'widget': null,
      },
      {
        'icon': Icons.payment_outlined,
        'title': 'طرق الدفع',
        'route': RouteConstants.paymentMethods,
        'color': AppTheme.success,
        'widget': null,
      },
      {
        'icon': Icons.palette_outlined,
        'title': 'مظهر التطبيق',
        'route': null,
        'color': const Color(0xFF6366F1),
        'widget': _buildThemeToggleMenuItem(),
      },
      {
        'icon': Icons.settings_outlined,
        'title': 'الإعدادات',
        'route': RouteConstants.notificationSettings,
        'color': AppTheme.error,
        'widget': null,
      },
      {
        'icon': Icons.notifications_none_rounded,
        'title': 'إعدادات الإشعارات',
        'route': RouteConstants.notificationSettings,
        'color': AppTheme.warning,
        'widget': null,
      },
      {
        'icon': Icons.language_rounded,
        'title': 'اللغة',
        'route': RouteConstants.languageSettings,
        'color': AppTheme.info,
        'widget': null,
      },
      {
        'icon': Icons.help_outline_rounded,
        'title': 'المساعدة والدعم',
        'route': null,
        'color': AppTheme.primaryCyan,
        'widget': null,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.darkBorder.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Column(
              children: menuItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                
                if (item['widget'] != null) {
                  return Column(
                    children: [
                      item['widget'] as Widget,
                      if (index < menuItems.length - 1)
                        Container(
                          height: 0.5,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          color: AppTheme.darkBorder.withOpacity(0.08),
                        ),
                    ],
                  );
                }
                
                return Column(
                  children: [
                    _buildMinimalMenuItem(
                      icon: item['icon'] as IconData,
                      title: item['title'] as String,
                      color: item['color'] as Color,
                      onTap: () {
                        final route = item['route'] as String?;
                        if (route != null) {
                          context.push(route);
                        }
                      },
                      delay: index * 50,
                    ),
                    if (index < menuItems.length - 1)
                      Container(
                        height: 0.5,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        color: AppTheme.darkBorder.withOpacity(0.08),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalMenuItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    int delay = 0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + delay),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: color.withOpacity(0.15),
                          width: 0.5,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppTheme.textMuted.withOpacity(0.5),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _buildMinimalButton(
        onPressed: () => _showLogoutDialog(context),
        isDestructive: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.logout_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'تسجيل الخروج',
              style: AppTextStyles.buttonMedium.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMinimalButton({
    required Widget child,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDestructive
              ? [
                  AppTheme.error.withOpacity(0.9),
                  AppTheme.error.withOpacity(0.7),
                ]
              : [
                  AppTheme.primaryBlue.withOpacity(0.9),
                  AppTheme.primaryPurple.withOpacity(0.7),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDestructive
                ? AppTheme.error.withOpacity(0.15)
                : AppTheme.primaryBlue.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(child: child),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: AppTheme.darkCard.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppTheme.darkBorder.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          title: Text(
            'تسجيل الخروج',
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'هل أنت متأكد من تسجيل الخروج؟',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.error.withOpacity(0.9),
                    AppTheme.error.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    context.read<AuthBloc>().add(const LogoutEvent());
                    context.go(RouteConstants.login);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'تسجيل الخروج',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
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

  String _formatDate(DateTime date) {
    final months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// Minimal Background Painter
class _MinimalBackgroundPainter extends CustomPainter {
  final double animationValue;
  
  _MinimalBackgroundPainter({required this.animationValue});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 2; i++) {
      paint.shader = RadialGradient(
        colors: [
          AppTheme.primaryBlue.withOpacity(0.02 + animationValue * 0.01),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(
          size.width * (0.3 + i * 0.4),
          size.height * (0.2 + i * 0.3),
        ),
        radius: 80 + animationValue * 10,
      ));
      
      canvas.drawCircle(
        Offset(
          size.width * (0.3 + i * 0.4),
          size.height * (0.2 + i * 0.3),
        ),
        80 + animationValue * 10,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}