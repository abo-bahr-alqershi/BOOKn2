// lib/features/auth/presentation/widgets/ultra_register_form.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import 'password_strength_indicator.dart';

class RegisterForm extends StatefulWidget {
  final Function(
    String name,
    String email,
    String phone,
    String password,
    String passwordConfirmation,
  ) onSubmit;
  final bool isLoading;

  const RegisterForm({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _showPasswordStrength = false;

  late AnimationController _fieldAnimationController;
  late AnimationController _checkboxAnimationController;

  @override
  void initState() {
    super.initState();

    _fieldAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _checkboxAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _passwordController.addListener(() {
      setState(() {
        _showPasswordStrength = _passwordController.text.isNotEmpty;
      });
    });

    // Add focus listeners for animations
    _nameFocusNode.addListener(() => setState(() {}));
    _emailFocusNode.addListener(() => setState(() {}));
    _phoneFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));
    _confirmPasswordFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _fieldAnimationController.dispose();
    _checkboxAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name field
          _buildUltraCompactField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            label: 'الاسم',
            hint: 'اسمك الكامل',
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_emailFocusNode);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'مطلوب';
              }
              if (value.length < 3) {
                return '3 أحرف على الأقل';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          // Email field
          _buildUltraCompactField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            label: 'البريد',
            hint: 'example@email.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_phoneFocusNode);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'مطلوب';
              }
              if (!Validators.isValidEmail(value)) {
                return 'بريد غير صحيح';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          // Phone field
          _buildUltraCompactField(
            controller: _phoneController,
            focusNode: _phoneFocusNode,
            label: 'الهاتف',
            hint: '967XXXXXXXXX',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_passwordFocusNode);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'مطلوب';
              }
              if (!Validators.isValidPhoneNumber('+$value')) {
                return 'رقم غير صحيح';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          // Password field
          _buildUltraCompactField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            label: 'كلمة المرور',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
            },
            suffixIcon: _buildPasswordToggle(
              obscure: _obscurePassword,
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'مطلوب';
              }
              if (!Validators.isValidPassword(value, minLength: 8)) {
                return '8 أحرف على الأقل';
              }
              return null;
            },
          ),

          // Password strength indicator
          if (_showPasswordStrength) ...[
            const SizedBox(height: 8),
            PasswordStrengthIndicator(
              password: _passwordController.text,
              showRequirements: false,
            ),
          ],

          const SizedBox(height: 12),

          // Confirm password field
          _buildUltraCompactField(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocusNode,
            label: 'تأكيد المرور',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _onSubmit(),
            suffixIcon: _buildPasswordToggle(
              obscure: _obscureConfirmPassword,
              onTap: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'مطلوب';
              }
              if (value != _passwordController.text) {
                return 'كلمات المرور غير متطابقة';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Terms checkbox
          _buildUltraTermsCheckbox(),

          const SizedBox(height: 20),

          // Submit button
          _buildUltraSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildUltraCompactField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    final isFocused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFocused
              ? [
                  AppTheme.primaryBlue.withOpacity(0.05),
                  AppTheme.primaryPurple.withOpacity(0.03),
                ]
              : [
                  AppTheme.darkCard.withOpacity(0.2),
                  AppTheme.darkCard.withOpacity(0.1),
                ],
        ),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: isFocused
              ? AppTheme.primaryBlue.withOpacity(0.3)
              : AppTheme.darkBorder.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            inputFormatters: inputFormatters,
            enabled: !widget.isLoading,
            onFieldSubmitted: onFieldSubmitted,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textWhite.withOpacity(0.9),
              fontSize: 12,
            ),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              labelStyle: AppTextStyles.caption.copyWith(
                color: isFocused
                    ? AppTheme.primaryBlue.withOpacity(0.8)
                    : AppTheme.textMuted.withOpacity(0.5),
                fontSize: 10,
              ),
              hintStyle: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted.withOpacity(0.3),
                fontSize: 11,
              ),
              prefixIcon: Container(
                width: 32,
                height: 42,
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: isFocused
                      ? AppTheme.primaryBlue.withOpacity(0.7)
                      : AppTheme.textMuted.withOpacity(0.4),
                  size: 16,
                ),
              ),
              suffixIcon: suffixIcon,
              filled: false,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(
                left: 12,
                right: 0,
                top: 10,
                bottom: 10,
              ),
              isDense: true,
            ),
            validator: validator,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordToggle({
    required bool obscure,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 32,
        height: 42,
        alignment: Alignment.center,
        child: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppTheme.textMuted.withOpacity(0.4),
          size: 14,
        ),
      ),
    );
  }

  Widget _buildUltraTermsCheckbox() {
    return GestureDetector(
      onTap: widget.isLoading
          ? null
          : () {
              HapticFeedback.lightImpact();
              setState(() {
                _acceptTerms = !_acceptTerms;
                if (_acceptTerms) {
                  _checkboxAnimationController.forward();
                } else {
                  _checkboxAnimationController.reverse();
                }
              });
            },
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              gradient: _acceptTerms ? AppTheme.primaryGradient : null,
              color: !_acceptTerms ? AppTheme.darkCard.withOpacity(0.3) : null,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: _acceptTerms
                    ? Colors.transparent
                    : AppTheme.darkBorder.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: _acceptTerms
                ? const Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted.withOpacity(0.5),
                  fontSize: 10,
                ),
                children: [
                  const TextSpan(text: 'أوافق على '),
                  TextSpan(
                    text: 'الشروط',
                    style: TextStyle(
                      color: AppTheme.primaryBlue.withOpacity(0.7),
                      decoration: TextDecoration.underline,
                      decorationColor: AppTheme.primaryBlue.withOpacity(0.3),
                    ),
                  ),
                  const TextSpan(text: ' و'),
                  TextSpan(
                    text: 'الخصوصية',
                    style: TextStyle(
                      color: AppTheme.primaryBlue.withOpacity(0.7),
                      decoration: TextDecoration.underline,
                      decorationColor: AppTheme.primaryBlue.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUltraSubmitButton() {
    final canSubmit = !widget.isLoading;

    return GestureDetector(
      onTap: canSubmit ? _onSubmit : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        decoration: BoxDecoration(
          gradient: canSubmit
              ? AppTheme.primaryGradient
              : LinearGradient(
                  colors: [
                    AppTheme.darkCard.withOpacity(0.3),
                    AppTheme.darkCard.withOpacity(0.2),
                  ],
                ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: canSubmit
                ? AppTheme.primaryBlue.withOpacity(0.3)
                : AppTheme.darkBorder.withOpacity(0.1),
            width: 0.5,
          ),
          boxShadow: canSubmit
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: widget.isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'جاري التسجيل...',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_add_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'إنشاء حساب',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: Colors.white,
                        fontSize: 13,
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
    if (!_acceptTerms) {
      HapticFeedback.lightImpact();
      _showUltraWarning();
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      HapticFeedback.mediumImpact();

      widget.onSubmit(
        _nameController.text.trim(),
        _emailController.text.trim(),
        '+${_phoneController.text.trim()}',
        _passwordController.text,
        _confirmPasswordController.text,
      );
    }
  }

  void _showUltraWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.warning.withOpacity(0.8),
                      AppTheme.warning.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'يجب الموافقة على الشروط',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textWhite.withOpacity(0.9),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: AppTheme.darkCard.withOpacity(0.95),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
