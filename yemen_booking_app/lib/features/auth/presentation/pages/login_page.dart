import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/route_constants.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/login_form.dart';
import '../widgets/social_login_buttons.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> 
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _backgroundAnimationController;
  late AnimationController _formAnimationController;
  late AnimationController _particleAnimationController;
  late AnimationController _glowAnimationController;
  
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
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _formAnimationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
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
  }
  
  void _generateParticles() {
    for (int i = 0; i < 15; i++) {
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
    _backgroundAnimationController.dispose();
    _formAnimationController.dispose();
    _particleAnimationController.dispose();
    _glowAnimationController.dispose();
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
            
            // Floating Particles
            _buildParticles(),
            
            // Main Content
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 40),
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child:_buildFuturisticHeader(),
                            ),
                            const SizedBox(height: 50),
                            _buildGlassLoginForm(),
                            const SizedBox(height: 30),
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child:_buildDivider(),
                            ),
                            const SizedBox(height: 30),
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child:_buildSocialLogin(),
                            ),
                            const SizedBox(height: 40),
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child:_buildRegisterLink(),
                            ),
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
  
  Widget _buildFuturisticHeader() {
    return Column(
      children: [
        // Logo Container
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow Effect
            AnimatedBuilder(
              animation: _glowAnimationController,
              builder: (context, child) {
                return Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primaryBlue.withOpacity(
                          0.2 + (_glowAnimationController.value * 0.3),
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
            
            // Glass Container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: AppTheme.darkCard.withOpacity(0.3),
                    child: Center(
                      child: ShaderMask(
                        shaderCallback: (bounds) => 
                            AppTheme.primaryGradient.createShader(bounds),
                        child: const Text(
                          'B',
                          style: TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 30),
        
        // App Name
        ShaderMask(
          shaderCallback: (bounds) => 
              AppTheme.primaryGradient.createShader(bounds),
          child: Text(
            'bookn',
            style: AppTextStyles.displayLarge.copyWith(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              color: AppTheme.textWhite,
              fontFamily: 'SF Pro Display',
            ),
          ),
        ),
        
        const SizedBox(height: 10),
        
        Text(
          'مرحباً بعودتك',
          style: AppTextStyles.heading2.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w300,
            letterSpacing: 1,
          ),
        ),
        
        const SizedBox(height: 5),
        
        Text(
          'سجل دخولك للمتابعة',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textMuted,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
  
  Widget _buildGlassLoginForm() {
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
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowDark.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return LoginForm(
                onSubmit: (emailOrPhone, password, rememberMe) {
                  context.read<AuthBloc>().add(
                    LoginEvent(
                      emailOrPhone: emailOrPhone,
                      password: password,
                      rememberMe: rememberMe,
                    ),
                  );
                },
                isLoading: state is AuthLoading,
              );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.primaryBlue.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'أو',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSocialLogin() {
    return const SocialLoginButtons();
  }
  
  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'ليس لديك حساب؟',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => context.push(RouteConstants.register),
          child: ShaderMask(
            shaderCallback: (bounds) => 
                AppTheme.primaryGradient.createShader(bounds),
            child: Text(
              'سجل الآن',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  void _handleAuthState(BuildContext context, AuthState state) {
    if (state is AuthLoginSuccess || state is AuthAuthenticated) {
      context.go(RouteConstants.main);
    } else if (state is AuthError) {
      _showFuturisticSnackBar(state.message);
    }
  }
  
  void _showFuturisticSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.error.withOpacity(0.8),
                      AppTheme.error,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.error_outline,
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
                      'خطأ في تسجيل الدخول',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.9),
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
        margin: const EdgeInsets.all(20),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }
}

// Background Pattern Painter
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
          AppTheme.primaryBlue.withOpacity(0.1 + (glowIntensity * 0.1)),
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

// Floating Particle Model
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
    vx = (math.Random().nextDouble() - 0.5) * 0.002;
    vy = (math.Random().nextDouble() - 0.5) * 0.002;
    radius = math.Random().nextDouble() * 3 + 1;
    opacity = math.Random().nextDouble() * 0.5 + 0.1;
    
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

// Particle Painter
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
        ..style = PaintingStyle.fill;
      
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