import 'package:flutter/material.dart';
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
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();
  final _emailOrPhoneFocusNode = FocusNode();
  
  late AnimationController _animationController;
  late AnimationController _floatingAnimationController;
  late AnimationController _successAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _floatingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _successAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successAnimationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _emailOrPhoneFocusNode.dispose();
    _animationController.dispose();
    _floatingAnimationController.dispose();
    _successAnimationController.dispose();
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
            // Animated Background
            _buildAnimatedBackground(),
            
            // Main Content
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _isSubmitted 
                        ? _buildSuccessView() 
                        : _buildResetForm(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.darkGradient,
      ),
      child: CustomPaint(
        painter: _FloatingCirclesPainter(
          animation: _floatingAnimationController,
        ),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildResetForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBackButton(),
        const SizedBox(height: 40),
        _buildAnimatedIcon(),
        const SizedBox(height: 40),
        _buildHeader(),
        const SizedBox(height: 50),
        _buildGlassForm(),
      ],
    );
  }

  Widget _buildSuccessView() {
    _successAnimationController.forward();
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 100),
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.success.withOpacity(0.2),
                  AppTheme.neonGreen.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.success.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.success.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.mark_email_read_outlined,
                size: 60,
                color: AppTheme.success,
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        ShaderMask(
          shaderCallback: (bounds) => 
              LinearGradient(
                colors: [AppTheme.success, AppTheme.neonGreen],
              ).createShader(bounds),
          child: Text(
            'تم الإرسال بنجاح',
            style: AppTextStyles.heading1.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'تم إرسال تعليمات إعادة تعيين كلمة المرور إلى بريدك الإلكتروني أو رقم هاتفك',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 60),
        _buildGlassButton(
          onPressed: () => context.pop(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'العودة لتسجيل الدخول',
                style: AppTextStyles.buttonLarge.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildBackButton() {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withOpacity(0.5),
              AppTheme.darkCard.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryBlue.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.pop(),
                borderRadius: BorderRadius.circular(16),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppTheme.textWhite,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return AnimatedBuilder(
      animation: _floatingAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimationController.value * 10 - 5),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => 
              AppTheme.primaryGradient.createShader(bounds),
          child: Text(
            'نسيت كلمة المرور؟',
            style: AppTextStyles.heading1.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 28,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'أدخل بريدك الإلكتروني أو رقم هاتفك وسنرسل لك تعليمات إعادة تعيين كلمة المرور',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildGlassForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkCard.withOpacity(0.5),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildEmailField(),
                const SizedBox(height: 30),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    final isFocused = _emailOrPhoneFocusNode.hasFocus;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFocused
              ? [
                  AppTheme.primaryBlue.withOpacity(0.1),
                  AppTheme.primaryPurple.withOpacity(0.05),
                ]
              : [
                  AppTheme.darkCard.withOpacity(0.3),
                  AppTheme.darkCard.withOpacity(0.2),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused
              ? AppTheme.primaryBlue.withOpacity(0.5)
              : AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: _emailOrPhoneController,
        focusNode: _emailOrPhoneFocusNode,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppTheme.textWhite,
        ),
        decoration: InputDecoration(
          labelText: 'البريد الإلكتروني أو رقم الهاتف',
          hintText: 'أدخل بريدك الإلكتروني أو رقم هاتفك',
          labelStyle: AppTextStyles.bodySmall.copyWith(
            color: isFocused
                ? AppTheme.primaryBlue
                : AppTheme.textMuted,
          ),
          hintStyle: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textMuted.withOpacity(0.5),
          ),
          prefixIcon: Icon(
            Icons.email_outlined,
            color: isFocused
                ? AppTheme.primaryBlue
                : AppTheme.textMuted,
          ),
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
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

  Widget _buildSubmitButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        
        return _buildGlassButton(
          onPressed: isLoading ? null : _onSubmit,
          isLoading: isLoading,
          child: isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'جاري الإرسال...',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'إرسال تعليمات إعادة التعيين',
                      style: AppTextStyles.buttonLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
  
  Widget _buildGlassButton({
    required Widget child,
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: isLoading
            ? LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.5),
                  AppTheme.primaryPurple.withOpacity(0.5),
                ],
              )
            : AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isLoading
            ? []
            : [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(child: child),
        ),
      ),
    );
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        ResetPasswordEvent(
          emailOrPhone: _emailOrPhoneController.text.trim(),
        ),
      );
    }
  }

  void _handleAuthState(BuildContext context, AuthState state) {
    if (state is AuthPasswordResetSent) {
      setState(() {
        _isSubmitted = true;
      });
    } else if (state is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// Floating Circles Painter
class _FloatingCirclesPainter extends CustomPainter {
  final Animation<double> animation;
  
  _FloatingCirclesPainter({required this.animation}) : super(repaint: animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    // Draw floating circles
    final circles = [
      {'x': 0.2, 'y': 0.3, 'radius': 80.0, 'color': AppTheme.primaryBlue.withOpacity(0.05)},
      {'x': 0.8, 'y': 0.5, 'radius': 120.0, 'color': AppTheme.primaryPurple.withOpacity(0.03)},
      {'x': 0.5, 'y': 0.8, 'radius': 100.0, 'color': AppTheme.primaryCyan.withOpacity(0.04)},
    ];
    
    for (var circle in circles) {
      final offset = Offset(
        size.width * (circle['x'] as double),
        size.height * (circle['y'] as double) + 
            (animation.value * 20 - 10),
      );
      
      paint.color = circle['color'] as Color;
      canvas.drawCircle(offset, circle['radius'] as double, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}