import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class AnimatedAuthButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Gradient? gradient;
  final Color? textColor;
  final IconData? icon;
  final double height;
  
  const AnimatedAuthButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.gradient,
    this.textColor,
    this.icon,
    this.height = 56,
  });

  @override
  State<AnimatedAuthButton> createState() => _AnimatedAuthButtonState();
}

class _AnimatedAuthButtonState extends State<AnimatedAuthButton>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _shimmerController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;
  
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOut,
    ));
    
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(_shimmerController);
  }

  @override
  void dispose() {
    _pressController.dispose();
    _shimmerController.dispose();
    _particleController.dispose();
    super.dispose();
  }
  
  void _handleTapDown(TapDownDetails details) {
    if (!widget.isLoading && widget.onPressed != null) {
      setState(() => _isPressed = true);
      _pressController.forward();
      _particleController.forward(from: 0);
    }
  }
  
  void _handleTapUp(TapUpDetails details) {
    if (!widget.isLoading && widget.onPressed != null) {
      setState(() => _isPressed = false);
      _pressController.reverse();
      widget.onPressed?.call();
    }
  }
  
  void _handleTapCancel() {
    if (!widget.isLoading) {
      setState(() => _isPressed = false);
      _pressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleAnimation,
          _shimmerAnimation,
          _particleController,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              height: widget.height,
              child: Stack(
                children: [
                  // Particle Effect
                  if (_particleController.value > 0)
                    ...List.generate(8, (index) {
                      final angle = (index * math.pi * 2) / 8;
                      final distance = _particleController.value * 50;
                      return Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Transform.translate(
                            offset: Offset(
                              math.cos(angle) * distance,
                              math.sin(angle) * distance,
                            ),
                            child: Opacity(
                              opacity: 1 - _particleController.value,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  gradient: widget.gradient ?? AppTheme.primaryGradient,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  
                  // Main Button
                  Container(
                    decoration: BoxDecoration(
                      gradient: widget.isLoading
                          ? LinearGradient(
                              colors: [
                                AppTheme.primaryBlue.withOpacity(0.5),
                                AppTheme.primaryPurple.withOpacity(0.5),
                              ],
                            )
                          : (widget.gradient ?? AppTheme.primaryGradient),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: widget.isLoading
                          ? []
                          : [
                              BoxShadow(
                                color: (widget.gradient ?? AppTheme.primaryGradient)
                                    .colors[0]
                                    .withOpacity(_isPressed ? 0.6 : 0.4),
                                blurRadius: _isPressed ? 30 : 20,
                                spreadRadius: _isPressed ? 4 : 2,
                                offset: Offset(0, _isPressed ? 6 : 4),
                              ),
                            ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          // Shimmer Effect
                          if (!widget.isLoading)
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.3,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment(-1.0 + _shimmerAnimation.value * 2, 0),
                                      end: Alignment(-0.5 + _shimmerAnimation.value * 2, 0),
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withOpacity(0.3),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          
                          // Button Content
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: widget.isLoading ? null : widget.onPressed,
                              borderRadius: BorderRadius.circular(16),
                              splashColor: Colors.white.withOpacity(0.2),
                              child: Container(
                                height: widget.height,
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Center(
                                  child: widget.isLoading
                                      ? _buildLoadingContent()
                                      : _buildNormalContent(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildNormalContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(
            widget.icon,
            color: widget.textColor ?? Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          widget.text,
          style: AppTextStyles.buttonLarge.copyWith(
            color: widget.textColor ?? Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildLoadingContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              (widget.textColor ?? Colors.white).withOpacity(0.9),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'جاري المعالجة...',
          style: AppTextStyles.bodyMedium.copyWith(
            color: (widget.textColor ?? Colors.white).withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}