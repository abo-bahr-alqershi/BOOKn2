// lib/features/admin_users/presentation/widgets/user_form_dialog.dart

import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';

class UserFormDialog extends StatefulWidget {
  final dynamic user;
  final Function(Map<String, String>) onSave;

  const UserFormDialog({
    super.key,
    this.user,
    required this.onSave,
  });

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog>
    with TickerProviderStateMixin {
  // Form
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _profileImageController;
  
  // Animation Controllers
  late AnimationController _backgroundAnimationController;
  late AnimationController _glowController;
  late AnimationController _entranceController;
  
  // Animations
  late Animation<double> _backgroundRotation;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  // Focus Nodes
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _imageFocus = FocusNode();
  
  // State
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    
    _nameController = TextEditingController(text: widget.user?.userName ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _phoneController = TextEditingController(text: widget.user?.phoneNumber ?? '');
    _profileImageController = TextEditingController(text: widget.user?.avatarUrl ?? '');
    
    _initializeAnimations();
    _setupFocusListeners();
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
    
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 400),
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
    
    _scaleAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.elasticOut,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeIn,
    );
    
    _entranceController.forward();
  }
  
  void _setupFocusListeners() {
    _nameFocus.addListener(() => setState(() {}));
    _emailFocus.addListener(() => setState(() {}));
    _phoneFocus.addListener(() => setState(() {}));
    _imageFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _glowController.dispose();
    _entranceController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _profileImageController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _imageFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkCard.withOpacity(0.95),
                  AppTheme.darkCard.withOpacity(0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Stack(
                  children: [
                    // Animated Background Pattern
                    _buildAnimatedBackground(),
                    
                    // Form Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 24),
                            _buildFormFields(),
                            const SizedBox(height: 24),
                            _buildActions(),
                          ],
                        ),
                      ),
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
  
  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _backgroundRotation,
        builder: (context, child) {
          return CustomPaint(
            painter: _DialogBackgroundPainter(
              rotation: _backgroundRotation.value,
              glowIntensity: _glowAnimation.value,
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.4 * _glowAnimation.value),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                widget.user != null
                    ? Icons.edit_rounded
                    : Icons.person_add_rounded,
                color: Colors.white,
                size: 24,
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                child: Text(
                  widget.user != null
                      ? 'تعديل بيانات المستخدم'
                      : 'إضافة مستخدم جديد',
                  style: AppTextStyles.heading3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.user != null
                    ? 'قم بتحديث البيانات المطلوبة'
                    : 'قم بملء البيانات المطلوبة',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _buildInputField(
          controller: _nameController,
          focusNode: _nameFocus,
          label: 'الاسم الكامل',
          hint: 'أدخل الاسم الكامل',
          icon: Icons.person_rounded,
          validator: Validators.validateName,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocus),
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _emailController,
          focusNode: _emailFocus,
          label: 'البريد الإلكتروني',
          hint: 'أدخل البريد الإلكتروني',
          icon: Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.validateEmail,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(_phoneFocus),
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _phoneController,
          focusNode: _phoneFocus,
          label: 'رقم الهاتف',
          hint: 'أدخل رقم الهاتف',
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          validator: Validators.validatePhone,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(_imageFocus),
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _profileImageController,
          focusNode: _imageFocus,
          label: 'رابط الصورة الشخصية',
          hint: 'اختياري',
          icon: Icons.image_rounded,
          validator: (value) => null,
          onSubmitted: (_) => _handleSave(),
        ),
      ],
    );
  }
  
  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Function(String)? onSubmitted,
  }) {
    final isFocused = focusNode.hasFocus;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isFocused ? AppTheme.primaryBlue : AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isFocused
                  ? [
                      AppTheme.primaryBlue.withOpacity(0.1),
                      AppTheme.primaryPurple.withOpacity(0.05),
                    ]
                  : [
                      AppTheme.darkCard.withOpacity(0.5),
                      AppTheme.darkCard.withOpacity(0.3),
                    ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFocused
                  ? AppTheme.primaryBlue.withOpacity(0.5)
                  : AppTheme.darkBorder.withOpacity(0.3),
              width: isFocused ? 1.5 : 1,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted.withOpacity(0.5),
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: isFocused
                      ? AppTheme.primaryGradient
                      : null,
                  color: !isFocused
                      ? AppTheme.textMuted.withOpacity(0.3)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: validator,
            onFieldSubmitted: onSubmitted,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        // Cancel Button
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              height: 48,
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
        
        // Save Button
        Expanded(
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return GestureDetector(
                onTap: _isSubmitting ? null : _handleSave,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(
                          0.3 + 0.2 * _glowAnimation.value,
                        ),
                        blurRadius: 12 + 8 * _glowAnimation.value,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'حفظ',
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
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

  void _handleSave() {
    if (_formKey.currentState!.validate() && !_isSubmitting) {
      setState(() => _isSubmitting = true);
      
      widget.onSave({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'profileImage': _profileImageController.text,
      });
      
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop();
    }
  }
}

// Custom Background Painter for Dialog
class _DialogBackgroundPainter extends CustomPainter {
  final double rotation;
  final double glowIntensity;
  
  _DialogBackgroundPainter({
    required this.rotation,
    required this.glowIntensity,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    // Draw subtle grid pattern
    paint.color = AppTheme.primaryBlue.withOpacity(0.03);
    const spacing = 30.0;
    
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
    
    // Draw rotating accent
    final center = Offset(size.width / 2, size.height / 2);
    paint.color = AppTheme.primaryBlue.withOpacity(0.02 * glowIntensity);
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);
    
    final rect = Rect.fromCenter(
      center: center,
      width: size.width * 0.8,
      height: size.height * 0.8,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(20)),
      paint,
    );
    
    canvas.restore();
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}