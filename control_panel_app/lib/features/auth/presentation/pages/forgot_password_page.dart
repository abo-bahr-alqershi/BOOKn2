// lib/features/auth/presentation/pages/forgot_password_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();
  final _emailOrPhoneFocusNode = FocusNode();

  // Animation Controller - Single controller for entrance animation only
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // State
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startEntranceAnimation();

    // Listen to focus changes for field styling
    _emailOrPhoneFocusNode.addListener(() => setState(() {}));
  }

  void _initializeAnimations() {
    // Single animation controller for entrance effects only
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Fade animation for entrance
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // Slide animation for entrance
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));
  }

  void _startEntranceAnimation() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _emailOrPhoneFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: BlocListener<AuthBloc, AuthState>(
        listener: _handleAuthState,
        child: Stack(
          children: [
            // Static gradient background - no animation
            _buildStaticBackground(),

            // Main Content
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        _buildTopBar(),
                        const SizedBox(height: 40),

                        // Content with AnimatedSwitcher
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          switchInCurve: Curves.easeInOut,
                          switchOutCurve: Curves.easeInOut,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.05),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: _isSubmitted
                              ? _buildSuccessContent()
                              : _buildResetFormContent(),
                        ),

                        const SizedBox(height: 40),
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

  Widget _buildStaticBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkBackground,
            AppTheme.darkBackground2.withValues(alpha: 0.8),
            AppTheme.darkBackground3.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Static decorative circles - no animation
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.05),
                    AppTheme.primaryBlue.withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryPurple.withValues(alpha: 0.04),
                    AppTheme.primaryPurple.withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        // Back button
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.darkCard.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.darkBorder.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.arrow_back_ios_rounded,
              color: AppTheme.textWhite,
              size: 18,
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildResetFormContent() {
    return Column(
      key: const ValueKey('reset_form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Icon
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Title
        Text(
          'استعادة كلمة المرور',
          style: AppTextStyles.heading2.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.textWhite,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        // Description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'أدخل بريدك الإلكتروني أو رقم هاتفك المسجل\nوسنرسل لك رابط استعادة كلمة المرور',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textMuted,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 40),

        // Form Card
        _buildFormCard(),

        const SizedBox(height: 24),

        // Help Text
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'تذكرت كلمة المرور؟',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.pop();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  'تسجيل الدخول',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      key: const ValueKey('success_view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),

        // Success Icon
        Center(
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.success.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.mark_email_read_outlined,
              size: 45,
              color: AppTheme.success,
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Success Title
        Text(
          'تم الإرسال بنجاح!',
          style: AppTextStyles.heading2.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.textWhite,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // Success Message
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.darkCard.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.darkBorder.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.email_outlined,
                color: AppTheme.primaryBlue,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                'تم إرسال رابط الاستعادة إلى',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _emailOrPhoneController.text,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Action Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _buildButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.pop();
                },
                label: 'العودة لتسجيل الدخول',
                icon: Icons.arrow_back_rounded,
                isPrimary: true,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _isSubmitted = false;
                    _emailOrPhoneController.clear();
                  });
                },
                child: Text(
                  'لم تستلم الرسالة؟ أعد المحاولة',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
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
                _buildInputField(),
                const SizedBox(height: 20),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    return _buildButton(
                      onPressed: isLoading ? null : _onSubmit,
                      label: isLoading
                          ? 'جاري الإرسال...'
                          : 'إرسال رابط الاستعادة',
                      icon: Icons.send_rounded,
                      isLoading: isLoading,
                      isPrimary: true,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField() {
    final isFocused = _emailOrPhoneFocusNode.hasFocus;
    final hasText = _emailOrPhoneController.text.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFocused
              ? AppTheme.primaryBlue.withValues(alpha: 0.4)
              : AppTheme.darkBorder.withValues(alpha: 0.15),
          width: isFocused ? 1.5 : 1,
        ),
        color: AppTheme.darkCard.withValues(alpha: 0.3),
      ),
      child: TextFormField(
        controller: _emailOrPhoneController,
        focusNode: _emailOrPhoneFocusNode,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _onSubmit(),
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppTheme.textWhite,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: 'البريد الإلكتروني أو رقم الهاتف',
          hintText: 'example@email.com',
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelStyle: AppTextStyles.bodySmall.copyWith(
            color: isFocused
                ? AppTheme.primaryBlue
                : AppTheme.textMuted.withValues(alpha: 0.7),
            fontSize: hasText || isFocused ? 11 : 13,
            fontWeight: isFocused ? FontWeight.w600 : FontWeight.w400,
          ),
          hintStyle: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textMuted.withValues(alpha: 0.3),
            fontSize: 13,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: isFocused ? AppTheme.primaryGradient : null,
              color:
                  !isFocused ? AppTheme.darkCard.withValues(alpha: 0.5) : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.email_outlined,
              size: 18,
              color: isFocused
                  ? Colors.white
                  : AppTheme.textMuted.withValues(alpha: 0.6),
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
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'هذا الحقل مطلوب';
          }
          if (!Validators.isValidEmail(value) &&
              !Validators.isValidPhoneNumber(value)) {
            return 'يرجى إدخال بريد إلكتروني أو رقم هاتف صحيح';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildButton({
    required VoidCallback? onPressed,
    required String label,
    IconData? icon,
    bool isLoading = false,
    bool isPrimary = false,
  }) {
    final isDisabled = onPressed == null;

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              HapticFeedback.lightImpact();
              onPressed.call();
            },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: isPrimary && !isDisabled ? AppTheme.primaryGradient : null,
          color: !isPrimary
              ? AppTheme.darkCard.withValues(alpha: 0.4)
              : isDisabled
                  ? AppTheme.darkCard.withValues(alpha: 0.3)
                  : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPrimary && !isDisabled
                ? Colors.transparent
                : AppTheme.darkBorder.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: isPrimary && !isDisabled
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        color: isPrimary || isDisabled
                            ? Colors.white
                                .withValues(alpha: isDisabled ? 0.5 : 1)
                            : AppTheme.textWhite,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: isPrimary || isDisabled
                            ? Colors.white
                                .withValues(alpha: isDisabled ? 0.5 : 1)
                            : AppTheme.textWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      HapticFeedback.mediumImpact();

      context.read<AuthBloc>().add(
            ResetPasswordEvent(
              emailOrPhone: _emailOrPhoneController.text.trim(),
            ),
          );
    }
  }

  void _handleAuthState(BuildContext context, AuthState state) {
    if (state is AuthPasswordResetSent) {
      HapticFeedback.heavyImpact();
      setState(() {
        _isSubmitted = true;
      });
    } else if (state is AuthError) {
      HapticFeedback.heavyImpact();
      _showErrorMessage(state.message);
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: AppTheme.error,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: AppTheme.darkCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
