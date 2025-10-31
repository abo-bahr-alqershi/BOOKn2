import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../injection_container.dart';
import '../../services/local_storage_service.dart';
import '../../features/splash/presentation/bloc/splash_bloc.dart';
import '../../features/splash/presentation/bloc/splash_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _shimmerController;
  late AnimationController _particleController;
  late AnimationController _textController;
  
  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _textSlide;
  late Animation<double> _textFade;
  
  // Particles
  final List<_Particle> particles = [];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateParticles();
    _startAnimationSequence();
    _navigateAfterDelay();
  }
  
  void _initializeAnimations() {
    // Logo animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));
    
    _logoFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    ));
    
    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Rotate animation
    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotateController);
    
    // Shimmer animation
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(_shimmerController);
    
    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    // Text animations
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _textSlide = Tween<double>(
      begin: 50,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
    ));
    
    _textFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
    ));
  }
  
  void _generateParticles() {
    for (int i = 0; i < 20; i++) {
      particles.add(_Particle());
    }
  }
  
  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    if (_logoController.status == AnimationStatus.dismissed) {
      _logoController.forward();
    }
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    if (_textController.status == AnimationStatus.dismissed) {
      _textController.forward();
    }
  }
  
  void _navigateAfterDelay() {
    // Wait for preload to complete or timeout
    final splashBloc = context.read<SplashBloc>();
    bool navigated = false;
    Timer(const Duration(seconds: 6), () {
      if (!navigated && mounted) {
        navigated = true;
        _checkAuthAndNavigate();
      }
    });
    splashBloc.stream.listen((state) {
      if (navigated || !mounted) return;
      if (state is SplashLoaded || state is SplashError) {
        navigated = true;
        _checkAuthAndNavigate();
      }
    });
  }
  
  void _checkAuthAndNavigate() {
  final localStorage = sl<LocalStorageService>();
    final isFirstRun = !localStorage.isOnboardingCompleted();

    if (isFirstRun) {
      // توجيه إلى صفحة اختيار المدينة والعملة للمستخدم الجديد
      context.go('/onboarding/select-city-currency');
      return;
    }

    final authState = context.read<AuthBloc>().state;
    
    if (authState is AuthAuthenticated) {
      context.go('/main');
    } else {
      // للمستخدم الذي أكمل onboarding لكنه غير مسجل دخول
      context.go('/login');
    }
  }
  
  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _shimmerController.dispose();
    _particleController.dispose();
    _textController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          // Gradient Background
          Container(
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
          ),
          
          // Animated Particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ParticlePainter(
                  particles: particles,
                  animationValue: _particleController.value,
                ),
                size: Size.infinite,
              );
            },
          ),
          
          // Blur Overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(
              color: Colors.transparent,
            ),
          ),
          
          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Section
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _logoFade,
                    _logoScale,
                    _pulseAnimation,
                    _rotateAnimation,
                  ]),
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _logoFade,
                      child: Transform.scale(
                        scale: _logoScale.value * _pulseAnimation.value,
                        child: _buildFuturisticLogo(),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 60),
                
                // App Name
                AnimatedBuilder(
                  animation: Listenable.merge([_textFade, _textSlide]),
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _textFade,
                      child: Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: _buildAppName(),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 100),
                
                // Loading Indicator with progress
                BlocBuilder<SplashBloc, SplashState>(
                  builder: (context, state) {
                    final progress = state is SplashLoading ? state.progress : (state is SplashLoaded ? 1.0 : 0.0);
                    return Column(
                      children: [
                AnimatedBuilder(
                  animation: _textFade,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _textFade,
                      child: _buildFuturisticLoader(),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: progress.clamp(0, 1),
                          minHeight: 3,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation(AppTheme.primaryCyan),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Bottom Text
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _textFade,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _textFade,
                  child: _buildBottomText(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFuturisticLogo() {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating Gradient Ring
          AnimatedBuilder(
            animation: _rotateAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateAnimation.value,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        Colors.transparent,
                        AppTheme.primaryCyan,
                        AppTheme.primaryBlue,
                        AppTheme.primaryPurple,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                    ),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Inner Circle with Glass Effect
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.cardGradient,
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: AppTheme.primaryPurple.withOpacity(0.3),
                  blurRadius: 50,
                  spreadRadius: 20,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: AppTheme.darkCard.withOpacity(0.3),
                  child: Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
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
          
          // Shimmer Effect
          AnimatedBuilder(
            animation: _shimmerAnimation,
            builder: (context, child) {
              return Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(75),
                  child: CustomPaint(
                    painter: _ShimmerPainter(
                      shimmerPosition: _shimmerAnimation.value,
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Pulse Rings
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (index * 0.3) + (_pulseController.value * 0.2);
                final opacity = (1.0 - (index * 0.3) - _pulseController.value) * 0.3;
                
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryBlue.withOpacity(opacity.clamp(0.0, 1.0)),
                        width: 1,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildAppName() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
          child: Text(
            'bookn',
            style: AppTextStyles.displayLarge.copyWith(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
              height: 1,
              color: AppTheme.textWhite,
              fontFamily: 'SF Pro Display',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'نظام إدارة الحجوزات الذكي',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textLight.withOpacity(0.7),
            letterSpacing: 1.5,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
  
  Widget _buildFuturisticLoader() {
    return SizedBox(
      width: 200,
      child: Column(
        children: [
          // DNA-style loader
          SizedBox(
            height: 40,
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _DNALoaderPainter(
                    animationValue: _shimmerController.value,
                  ),
                  size: const Size(200, 40),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          // Loading text with dots
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              final dotCount = (_shimmerController.value * 3).floor() + 1;
              return Text(
                'جاري التحميل${'.' * dotCount}',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                  letterSpacing: 1,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomText() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppTheme.primaryBlue.withOpacity(0.5),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'تقنية متقدمة',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                  letterSpacing: 2,
                  fontSize: 10,
                ),
              ),
            ),
            Container(
              width: 30,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'POWERED BY ARMA-SOFT',
          style: AppTextStyles.overline.copyWith(
            color: AppTheme.primaryBlue.withOpacity(0.4),
            letterSpacing: 3,
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// Particle System
class _Particle {
  late double x;
  late double y;
  late double speed;
  late double radius;
  late double opacity;
  
  _Particle() {
    reset();
  }
  
  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    speed = math.Random().nextDouble() * 0.5 + 0.1;
    radius = math.Random().nextDouble() * 2 + 1;
    opacity = math.Random().nextDouble() * 0.5 + 0.1;
  }
  
  void update(double animationValue) {
    y -= speed * 0.01;
    if (y < 0) {
      y = 1.0;
      x = math.Random().nextDouble();
    }
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;
  
  _ParticlePainter({
    required this.particles,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update(animationValue);
      
      final paint = Paint()
        ..color = AppTheme.primaryBlue.withOpacity(particle.opacity)
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

// Shimmer Painter
class _ShimmerPainter extends CustomPainter {
  final double shimmerPosition;
  
  _ShimmerPainter({required this.shimmerPosition});
  
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment(-1.0 + shimmerPosition * 2, -1.0 + shimmerPosition * 2),
      end: Alignment(-0.5 + shimmerPosition * 2, -0.5 + shimmerPosition * 2),
      colors: [
        Colors.transparent,
        Colors.white.withOpacity(0.1),
        Colors.white.withOpacity(0.2),
        Colors.white.withOpacity(0.1),
        Colors.transparent,
      ],
      stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(rect, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// DNA Loader Painter
class _DNALoaderPainter extends CustomPainter {
  final double animationValue;
  
  _DNALoaderPainter({required this.animationValue});
  
  @override
  void paint(Canvas canvas, Size size) {
    const pointCount = 10;
    final waveHeight = size.height / 2;
    final dx = size.width / (pointCount - 1);
    
    for (int j = 0; j < 2; j++) {
      final path = Path();
      final paint = Paint()
        ..color = j == 0 ? AppTheme.primaryBlue : AppTheme.primaryPurple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      
      for (int i = 0; i < pointCount; i++) {
        final x = i * dx;
        final angle = (i / pointCount) * 2 * math.pi + (animationValue * 2 * math.pi);
        final y = size.height / 2 + math.sin(angle + (j * math.pi)) * waveHeight;
        
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
        
        // Connection dots
        if (i % 2 == 0) {
          final oppY = size.height / 2 - math.sin(angle + (j * math.pi)) * waveHeight;
          final dotPaint = Paint()
            ..color = AppTheme.primaryCyan.withOpacity(0.6)
            ..style = PaintingStyle.fill;
          
          canvas.drawCircle(Offset(x, y), 3, dotPaint);
          
          // Connection lines
          if (j == 0) {
            final linePaint = Paint()
              ..color = AppTheme.primaryCyan.withOpacity(0.2)
              ..strokeWidth = 1;
            canvas.drawLine(Offset(x, y), Offset(x, oppY), linePaint);
          }
        }
      }
      
      canvas.drawPath(path, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}