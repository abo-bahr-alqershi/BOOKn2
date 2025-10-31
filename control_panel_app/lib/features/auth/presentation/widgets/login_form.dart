// lib/features/auth/presentation/widgets/login_form.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/constants/route_constants.dart';

class LoginForm extends StatefulWidget {
  final Function(String emailOrPhone, String password, bool rememberMe)
      onSubmit;
  final bool isLoading;

  const LoginForm({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailOrPhoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _rememberMe = false;

  // Single animation controller for performance
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();

    // Focus listeners for simple state updates
    _emailOrPhoneFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));

    // Auto-fill for testing (remove in production)
    _emailOrPhoneController.text = "admin@example.com";
    _passwordController.text = "Admin@123";
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    _emailOrPhoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildOptimizedField(
              controller: _emailOrPhoneController,
              focusNode: _emailOrPhoneFocusNode,
              label: 'البريد الإلكتروني أو رقم الهاتف',
              hint: 'أدخل بريدك أو رقمك',
              icon: Icons.person_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_passwordFocusNode);
              },
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
            const SizedBox(height: 20),
            _buildOptimizedField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              label: 'كلمة المرور',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _onSubmit(),
              suffixIcon: _buildPasswordToggle(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'هذا الحقل مطلوب';
                }
                if (value.length < 8) {
                  return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildOptions(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizedField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Widget? suffixIcon,
    Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    final isFocused = focusNode.hasFocus;
    final hasText = controller.text.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused
              ? AppTheme.primaryBlue.withValues(alpha: 0.4)
              : AppTheme.darkBorder.withValues(alpha: 0.15),
          width: isFocused ? 1.5 : 1,
        ),
        color: AppTheme.darkCard.withValues(alpha: 0.3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            enabled: !widget.isLoading,
            onFieldSubmitted: onFieldSubmitted,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
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
                margin: const EdgeInsets.all(12),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: isFocused ? AppTheme.primaryGradient : null,
                  color: !isFocused
                      ? AppTheme.darkCard.withValues(alpha: 0.5)
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isFocused
                      ? Colors.white
                      : AppTheme.textMuted.withValues(alpha: 0.6),
                ),
              ),
              suffixIcon: suffixIcon,
              filled: false,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
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
    );
  }

  Widget _buildPasswordToggle() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _obscurePassword = !_obscurePassword;
        });
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.darkBorder.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: Icon(
          _obscurePassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          size: 18,
          color: AppTheme.textMuted.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: widget.isLoading
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _rememberMe = !_rememberMe;
                  });
                },
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  gradient: _rememberMe ? AppTheme.primaryGradient : null,
                  color: !_rememberMe
                      ? AppTheme.darkCard.withValues(alpha: 0.3)
                      : null,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _rememberMe
                        ? Colors.transparent
                        : AppTheme.darkBorder.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: _rememberMe
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'تذكرني',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: widget.isLoading
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  context.push(RouteConstants.forgotPassword);
                },
          child: Text(
            'نسيت كلمة المرور؟',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: widget.isLoading ? null : _onSubmit,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: widget.isLoading
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.3),
                    AppTheme.primaryPurple.withValues(alpha: 0.3),
                  ],
                )
              : AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: widget.isLoading
              ? []
              : [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: widget.isLoading
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
                      'جاري التحقق...',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.login_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'تسجيل الدخول',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: Colors.white,
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

      widget.onSubmit(
        _emailOrPhoneController.text.trim(),
        _passwordController.text,
        _rememberMe,
      );
    }
  }
}
