// lib/features/auth/presentation/pages/change_password_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  final _currentFocusNode = FocusNode();
  final _newFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Password strength
  double _passwordStrength = 0.0;
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = AppTheme.textMuted;

  // Animation Controllers
  late AnimationController _backgroundAnimationController;
  late AnimationController _formAnimationController;
  late AnimationController _particleAnimationController;
  late AnimationController _glowAnimationController;
  late AnimationController _fieldAnimationController;
  late AnimationController _strengthAnimationController;
  late AnimationController _shimmerController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  // Particles
  final List<_FloatingParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateParticles();
    _startAnimations();
    _setupFocusListeners();
    _newController.addListener(_checkPasswordStrength);
  }

  void _setupFocusListeners() {
    _currentFocusNode.addListener(_onFocusChange);
    _newFocusNode.addListener(_onFocusChange);
    _confirmFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_currentFocusNode.hasFocus ||
        _newFocusNode.hasFocus ||
        _confirmFocusNode.hasFocus) {
      _fieldAnimationController.forward();
    } else {
      _fieldAnimationController.reverse();
    }
  }

  void _checkPasswordStrength() {
    final password = _newController.text;
    double strength = 0;

    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0;
        _passwordStrengthText = '';
        _passwordStrengthColor = AppTheme.textMuted;
      });
      return;
    }

    // Check length
    if (password.length >= 8) strength += 0.25;
    if (password.length >= 12) strength += 0.25;

    // Check for uppercase
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.25;

    // Check for numbers
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.125;

    // Check for special characters
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.125;

    setState(() {
      _passwordStrength = strength.clamp(0.0, 1.0);

      if (_passwordStrength <= 0.25) {
        _passwordStrengthText = 'ضعيفة';
        _passwordStrengthColor = AppTheme.error;
      } else if (_passwordStrength <= 0.5) {
        _passwordStrengthText = 'متوسطة';
        _passwordStrengthColor = AppTheme.warning;
      } else if (_passwordStrength <= 0.75) {
        _passwordStrengthText = 'جيدة';
        _passwordStrengthColor = AppTheme.info;
      } else {
        _passwordStrengthText = 'قوية جداً';
        _passwordStrengthColor = AppTheme.success;
      }
    });

    _strengthAnimationController.forward();
  }

  void _initializeAnimations() {
    // Background Animation
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_backgroundAnimationController);

    // Form Animation
    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formAnimationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _formAnimationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    // Particle Animation
    _particleAnimationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // Glow Animation
    _glowAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    // Field Animation
    _fieldAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Strength Animation
    _strengthAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Shimmer Animation
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  void _generateParticles() {
    for (int i = 0; i < 20; i++) {
      _particles.add(_FloatingParticle());
    }
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _formAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    _currentFocusNode.dispose();
    _newFocusNode.dispose();
    _confirmFocusNode.dispose();
    _backgroundAnimationController.dispose();
    _formAnimationController.dispose();
    _particleAnimationController.dispose();
    _glowAnimationController.dispose();
    _fieldAnimationController.dispose();
    _strengthAnimationController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthPasswordChangeSuccess) {
            _showSuccessDialog(state.message);
          } else if (state is AuthError) {
            _showErrorSnackBar(state.message);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Stack(
            children: [
              // Animated Background
              _buildAnimatedBackground(),

              // Floating Particles
              _buildParticles(),

              // Main Content
              SafeArea(
                child: Column(
                  children: [
                    _buildMinimalAppBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Transform.scale(
                                scale: _scaleAnimation.value,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildSecurityHeader(),
                                    const SizedBox(height: 32),
                                    _buildGlassPasswordForm(isLoading),
                                    const SizedBox(height: 20),
                                    _buildPasswordTips(),
                                    const SizedBox(height: 40),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMinimalAppBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.darkCard.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.darkBorder.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppTheme.textWhite,
              ),
            ),
          ),

          // Title
          Expanded(
            child: Text(
              'تغيير كلمة المرور',
              style: AppTextStyles.heading3.copyWith(
                color: AppTheme.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Placeholder for symmetry
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _rotationAnimation,
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
            painter: _BackgroundPatternPainter(
              rotation: _rotationAnimation.value,
              glowIntensity: _glowAnimationController.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleAnimationController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            animationValue: _particleAnimationController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildSecurityHeader() {
    return Column(
      children: [
        // Security Icon
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow Effect
            AnimatedBuilder(
              animation: _glowAnimationController,
              builder: (context, child) {
                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primaryBlue.withValues(
                          alpha: 0.1 + (_glowAnimationController.value * 0.2),
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),

            // Icon Container
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                size: 35,
                color: Colors.white,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Title
        ShaderMask(
          shaderCallback: (bounds) =>
              AppTheme.primaryGradient.createShader(bounds),
          child: Text(
            'تأمين حسابك',
            style: AppTextStyles.heading3.copyWith(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(height: 4),

        Text(
          'قم بتغيير كلمة المرور لحماية حسابك',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textMuted.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassPasswordForm(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkCard.withValues(alpha: 0.3),
            AppTheme.darkCard.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPasswordField(
                  controller: _currentController,
                  focusNode: _currentFocusNode,
                  label: 'كلمة المرور الحالية',
                  hint: '••••••••',
                  obscureText: _obscureCurrent,
                  enabled: !isLoading,
                  onToggleVisibility: () {
                    setState(() => _obscureCurrent = !_obscureCurrent);
                  },
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'أدخل كلمة المرور الحالية';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                _buildPasswordField(
                  controller: _newController,
                  focusNode: _newFocusNode,
                  label: 'كلمة المرور الجديدة',
                  hint: '••••••••',
                  obscureText: _obscureNew,
                  enabled: !isLoading,
                  showStrength: true,
                  onToggleVisibility: () {
                    setState(() => _obscureNew = !_obscureNew);
                  },
                  validator: (v) {
                    if (v == null || v.length < 8) {
                      return 'الحد الأدنى 8 أحرف';
                    }
                    if (v == _currentController.text) {
                      return 'كلمة المرور الجديدة مطابقة للحالية';
                    }
                    return null;
                  },
                ),

                // Password Strength Indicator
                if (_passwordStrength > 0) ...[
                  const SizedBox(height: 8),
                  _buildPasswordStrengthIndicator(),
                ],

                const SizedBox(height: 16),

                _buildPasswordField(
                  controller: _confirmController,
                  focusNode: _confirmFocusNode,
                  label: 'تأكيد كلمة المرور الجديدة',
                  hint: '••••••••',
                  obscureText: _obscureConfirm,
                  enabled: !isLoading,
                  onToggleVisibility: () {
                    setState(() => _obscureConfirm = !_obscureConfirm);
                  },
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'أدخل تأكيد كلمة المرور';
                    }
                    if (v != _newController.text) {
                      return 'كلمة المرور غير متطابقة';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                _buildChangeButton(isLoading),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    bool enabled = true,
    bool showStrength = false,
    String? Function(String?)? validator,
  }) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _fieldAnimationController,
        _shimmerController,
      ]),
      builder: (context, child) {
        final isFocused = focusNode.hasFocus;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              if (isFocused)
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isFocused
                      ? AppTheme.primaryBlue.withValues(alpha: 0.03)
                      : AppTheme.darkCard.withValues(alpha: 0.15),
                  isFocused
                      ? AppTheme.primaryPurple.withValues(alpha: 0.02)
                      : AppTheme.darkCard.withValues(alpha: 0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isFocused
                    ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                    : AppTheme.darkBorder.withValues(alpha: 0.15),
                width: isFocused ? 1.5 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: obscureText,
                  enabled: enabled,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: label,
                    hintText: hint,
                    labelStyle: AppTextStyles.bodySmall.copyWith(
                      color: isFocused
                          ? AppTheme.primaryBlue.withValues(alpha: 0.9)
                          : AppTheme.textMuted.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                    hintStyle: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textMuted.withValues(alpha: 0.3),
                      fontSize: 13,
                    ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: isFocused ? AppTheme.primaryGradient : null,
                        color: !isFocused
                            ? AppTheme.darkCard.withValues(alpha: 0.3)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: isFocused
                            ? Colors.white
                            : AppTheme.textMuted.withValues(alpha: 0.6),
                      ),
                    ),
                    suffixIcon: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onToggleVisibility();
                      },
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          obscureText
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: AppTheme.textMuted.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    errorStyle: AppTextStyles.caption.copyWith(
                      color: AppTheme.error,
                      fontSize: 11,
                    ),
                  ),
                  validator: validator,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return AnimatedBuilder(
      animation: _strengthAnimationController,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _passwordStrength,
                      backgroundColor: AppTheme.darkCard.withValues(alpha: 0.3),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _passwordStrengthText,
                  style: AppTextStyles.caption.copyWith(
                    color: _passwordStrengthColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPasswordTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.info.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.info.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppTheme.info.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 8),
              Text(
                'نصائح لكلمة مرور قوية',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.info,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...[
            'استخدم 8 أحرف على الأقل',
            'امزج بين الأحرف الكبيرة والصغيرة',
            'أضف أرقاماً ورموزاً خاصة',
            'تجنب المعلومات الشخصية',
          ].map((tip) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.info.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip,
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildChangeButton(bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : _submit,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: isLoading
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.3),
                    AppTheme.primaryPurple.withValues(alpha: 0.3),
                  ],
                )
              : AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'جاري التحديث...',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.lock_reset,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'تغيير كلمة المرور',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_newController.text != _confirmController.text) {
      _showErrorSnackBar('كلمة المرور الجديدة وتأكيدها غير متطابقين');
      return;
    }

    HapticFeedback.mediumImpact();

    context.read<AuthBloc>().add(ChangePasswordEvent(
          currentPassword: _currentController.text,
          newPassword: _newController.text,
          newPasswordConfirmation: _confirmController.text,
        ));
  }

  void _showSuccessDialog(String message) {
    HapticFeedback.mediumImpact();

    showDialog(
      fullscreenDialog: true,
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkCard.withValues(alpha: 0.9),
                AppTheme.darkCard.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.success.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.success.withValues(alpha: 0.8),
                      AppTheme.success,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 35,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'تم التغيير بنجاح',
                style: AppTextStyles.heading3.copyWith(
                  color: AppTheme.textWhite,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'حسناً',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.error.withValues(alpha: 0.8),
                      AppTheme.error,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// Reuse painters from previous files...
// _BackgroundPatternPainter, _FloatingParticle, _ParticlePainter
// (Same code as in EditProfilePage)

// Reuse Background Pattern Painter from LoginPage
class _BackgroundPatternPainter extends CustomPainter {
  final double rotation;
  final double glowIntensity;

  _BackgroundPatternPainter({
    required this.rotation,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw rotating circles
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 3; i++) {
      paint.shader = RadialGradient(
        colors: [
          AppTheme.primaryBlue.withValues(alpha: 0.05 + (glowIntensity * 0.05)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 200));

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation + (i * math.pi / 3));
      canvas.translate(-center.dx, -center.dy);

      canvas.drawCircle(
        Offset(center.dx + 100, center.dy),
        50 + (i * 30),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Reuse Floating Particle Model from LoginPage
class _FloatingParticle {
  late double x;
  late double y;
  late double vx;
  late double vy;
  late double radius;
  late double opacity;
  late Color color;

  _FloatingParticle() {
    reset();
  }

  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    vx = (math.Random().nextDouble() - 0.5) * 0.001;
    vy = (math.Random().nextDouble() - 0.5) * 0.001;
    radius = math.Random().nextDouble() * 2 + 0.5;
    opacity = math.Random().nextDouble() * 0.3 + 0.05;

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

// Reuse Particle Painter from LoginPage
class _ParticlePainter extends CustomPainter {
  final List<_FloatingParticle> particles;
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
        ..color = particle.color.withValues(alpha: particle.opacity)
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
