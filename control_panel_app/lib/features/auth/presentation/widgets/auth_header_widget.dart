import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class AuthHeaderWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient? iconGradient;
  final Color? iconColor;
  
  const AuthHeaderWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconGradient,
    this.iconColor,
  });

  @override
  State<AuthHeaderWidget> createState() => _AuthHeaderWidgetState();
}

class _AuthHeaderWidgetState extends State<AuthHeaderWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotationController);
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _floatAnimation = Tween<double>(
      begin: -10,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Animated Icon Container
        AnimatedBuilder(
          animation: Listenable.merge([
            _rotationAnimation,
            _pulseAnimation,
            _floatAnimation,
          ]),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatAnimation.value),
              child: Transform.scale(
                scale: _pulseAnimation.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Rotating Gradient Ring
                    Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              Colors.transparent,
                              (widget.iconGradient ?? AppTheme.primaryGradient)
                                  .colors[0]
                                  .withValues(alpha: 0.3),
                              (widget.iconGradient ?? AppTheme.primaryGradient)
                                  .colors[1]
                                  .withValues(alpha: 0.5),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.25, 0.75, 1.0],
                          ),
                        ),
                      ),
                    ),
                    
                    // Glass Container
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: widget.iconGradient ?? AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: (widget.iconGradient ?? AppTheme.primaryGradient)
                                .colors[0]
                                .withValues(alpha: 0.4),
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
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.2),
                                  Colors.white.withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                widget.icon,
                                size: 50,
                                color: widget.iconColor ?? Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Pulse Rings
                    ...List.generate(3, (index) {
                      return Transform.scale(
                        scale: _pulseAnimation.value + (index * 0.1),
                        child: Container(
                          width: 100 + (index * 20),
                          height: 100 + (index * 20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: (widget.iconGradient ?? AppTheme.primaryGradient)
                                  .colors[0]
                                  .withValues(alpha: 0.1 * (1 - index * 0.3)),
                              width: 1,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 30),
        
        // Title with Gradient
        ShaderMask(
          shaderCallback: (bounds) => 
              (widget.iconGradient ?? AppTheme.primaryGradient).createShader(bounds),
          child: Text(
            widget.title,
            style: AppTextStyles.heading1.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 28,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            widget.subtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}