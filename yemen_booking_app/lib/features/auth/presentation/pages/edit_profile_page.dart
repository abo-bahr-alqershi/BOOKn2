// lib/features/auth/presentation/pages/edit_profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/upload_user_image.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  
  final _nameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _bioFocusNode = FocusNode();
  
  // Animation Controllers
  late AnimationController _backgroundAnimationController;
  late AnimationController _formAnimationController;
  late AnimationController _particleAnimationController;
  late AnimationController _glowAnimationController;
  late AnimationController _fieldAnimationController;
  late AnimationController _shimmerController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  
  // Particles
  final List<_FloatingParticle> _particles = [];
  
  // Avatar
  String? _selectedAvatar;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateParticles();
    _startAnimations();
    _setupFocusListeners();
    _loadUserData();
  }
  
  void _loadUserData() {
    // Prefill from AuthBloc state
    final state = context.read<AuthBloc>().state;
    dynamic user;
    if (state is AuthAuthenticated) user = state.user;
    if (state is AuthLoginSuccess) user = state.user;
    if (state is AuthProfileUpdateSuccess) user = state.user;
    if (state is AuthProfileImageUploadSuccess) user = state.user;

    if (user != null) {
      _nameController.text = (user.name ?? '').toString();
      _phoneController.text = (user.phone ?? '').toString();
      _emailController.text = (user.email ?? '').toString();
      _currentImageUrl = (user.profileImage ?? '').toString();
    }
  }
  
  void _setupFocusListeners() {
    _nameFocusNode.addListener(_onFocusChange);
    _phoneFocusNode.addListener(_onFocusChange);
    _emailFocusNode.addListener(_onFocusChange);
    _bioFocusNode.addListener(_onFocusChange);
  }
  
  void _onFocusChange() {
    if (_nameFocusNode.hasFocus || 
        _phoneFocusNode.hasFocus || 
        _emailFocusNode.hasFocus ||
        _bioFocusNode.hasFocus) {
      _fieldAnimationController.forward();
    } else {
      _fieldAnimationController.reverse();
    }
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
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _emailFocusNode.dispose();
    _bioFocusNode.dispose();
    _backgroundAnimationController.dispose();
    _formAnimationController.dispose();
    _particleAnimationController.dispose();
    _glowAnimationController.dispose();
    _fieldAnimationController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthProfileUpdateSuccess) {
            _showSuccessAnimation();
            Future.delayed(const Duration(seconds: 1), () {
              Navigator.of(context).pop();
            });
          } else if (state is AuthProfileImageUploadSuccess) {
            setState(() {
              _currentImageUrl = state.user.profileImage;
            });
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
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildProfileHeader(),
                                    const SizedBox(height: 24),
                                    _buildGlassForm(isLoading),
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
            color: AppTheme.darkBorder.withOpacity(0.1),
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
                color: AppTheme.darkCard.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.darkBorder.withOpacity(0.1),
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
              'تعديل الملف الشخصي',
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
  
  Widget _buildProfileHeader() {
    return Column(
      children: [
        // Avatar Section
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow Effect
            AnimatedBuilder(
              animation: _glowAnimationController,
              builder: (context, child) {
                return Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primaryBlue.withOpacity(
                          0.1 + (_glowAnimationController.value * 0.2),
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
            UploadUserImage(
              currentImageUrl: _currentImageUrl,
              onImageSelected: (imagePath) {
                if (imagePath.isEmpty) {
                  setState(() {
                    _currentImageUrl = null;
                  });
                  return;
                }
                // Update local preview immediately, then dispatch upload
                setState(() {
                  _currentImageUrl = imagePath;
                });
                context.read<AuthBloc>().add(
                      UploadProfileImageEvent(imagePath: imagePath),
                    );
              },
              size: 90,
            ),
            
            // Edit Icon
            Positioned(
              bottom: 5,
              right: 5,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.darkBackground,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // User Info
        ShaderMask(
          shaderCallback: (bounds) => 
              AppTheme.primaryGradient.createShader(bounds),
          child: Text(
            'تحديث معلوماتك',
            style: AppTextStyles.heading3.copyWith(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        const SizedBox(height: 4),
        
        Text(
          'قم بتحديث معلومات ملفك الشخصي',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textMuted.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDefaultAvatar() {
    return Center(
      child: Icon(
        Icons.person_outline_rounded,
        size: 40,
        color: Colors.white.withOpacity(0.7),
      ),
    );
  }
  
  Widget _buildGlassForm(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkCard.withOpacity(0.3),
            AppTheme.darkCard.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.1),
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
                _buildPremiumField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  label: 'الاسم الكامل',
                  hint: 'أدخل اسمك الكامل',
                  icon: Icons.person_outline_rounded,
                  enabled: !isLoading,
                  validator: (v) {
                    if (v == null || v.trim().length < 2) {
                      return 'أدخل اسم صالح (حرفين على الأقل)';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                _buildPremiumField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  label: 'البريد الإلكتروني',
                  hint: 'example@email.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isLoading,
                  validator: (v) {
                    if (v != null && v.isNotEmpty) {
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                        return 'أدخل بريد إلكتروني صحيح';
                      }
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                _buildPremiumField(
                  controller: _phoneController,
                  focusNode: _phoneFocusNode,
                  label: 'رقم الهاتف',
                  hint: '+967 XXX XXX XXX',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  enabled: !isLoading,
                  validator: (v) {
                    if (v != null && v.isNotEmpty) {
                      if (v.length < 9) {
                        return 'أدخل رقم هاتف صحيح';
                      }
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                _buildPremiumField(
                  controller: _bioController,
                  focusNode: _bioFocusNode,
                  label: 'نبذة عنك',
                  hint: 'اكتب نبذة مختصرة عن نفسك',
                  icon: Icons.info_outline_rounded,
                  maxLines: 3,
                  enabled: !isLoading,
                ),
                
                const SizedBox(height: 24),
                
                _buildSaveButton(isLoading),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPremiumField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
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
                  color: AppTheme.primaryBlue.withOpacity(0.08),
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
                      ? AppTheme.primaryBlue.withOpacity(0.03)
                      : AppTheme.darkCard.withOpacity(0.15),
                  isFocused
                      ? AppTheme.primaryPurple.withOpacity(0.02)
                      : AppTheme.darkCard.withOpacity(0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isFocused
                    ? AppTheme.primaryBlue.withOpacity(0.3)
                    : AppTheme.darkBorder.withOpacity(0.15),
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
                  enabled: enabled,
                  maxLines: maxLines,
                  keyboardType: keyboardType,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: label,
                    hintText: hint,
                    labelStyle: AppTextStyles.bodySmall.copyWith(
                      color: isFocused
                          ? AppTheme.primaryBlue.withOpacity(0.9)
                          : AppTheme.textMuted.withOpacity(0.7),
                      fontSize: 12,
                    ),
                    hintStyle: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textMuted.withOpacity(0.3),
                      fontSize: 13,
                    ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: isFocused ? AppTheme.primaryGradient : null,
                        color: !isFocused ? AppTheme.darkCard.withOpacity(0.3) : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: isFocused
                            ? Colors.white
                            : AppTheme.textMuted.withOpacity(0.6),
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
  
  Widget _buildSaveButton(bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : _submit,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: isLoading
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.3),
                    AppTheme.primaryPurple.withOpacity(0.3),
                  ],
                )
              : AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.25),
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
                          Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'جاري الحفظ...',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.8),
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
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.save_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'حفظ التغييرات',
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
    
    HapticFeedback.mediumImpact();
    
    context.read<AuthBloc>().add(UpdateProfileEvent(
      name: _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty 
          ? null 
          : _phoneController.text.trim(),
    ));
  }
  
  void _pickAvatar() {
    HapticFeedback.lightImpact();
    // Implement avatar picker
  }
  
  void _showSuccessAnimation() {
    HapticFeedback.mediumImpact();
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
                      AppTheme.success.withOpacity(0.8),
                      AppTheme.success,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'تم التحديث بنجاح',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'تم حفظ معلوماتك الشخصية',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
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
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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
                      AppTheme.error.withOpacity(0.8),
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
          AppTheme.primaryBlue.withOpacity(0.05 + (glowIntensity * 0.05)),
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
        ..color = particle.color.withOpacity(particle.opacity)
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
