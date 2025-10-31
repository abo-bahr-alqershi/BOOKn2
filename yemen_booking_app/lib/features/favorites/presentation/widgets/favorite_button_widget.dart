import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../bloc/favorites_bloc.dart';
import '../bloc/favorites_event.dart';
import '../bloc/favorites_state.dart';

class FavoriteButtonWidget extends StatefulWidget {
  final String propertyId;
  final String userId;
  final double size;
  final bool showBackground;
  final bool isCompact;

  const FavoriteButtonWidget({
    super.key,
    required this.propertyId,
    required this.userId,
    this.size = 32,
    this.showBackground = true,
    this.isCompact = false,
  });

  @override
  State<FavoriteButtonWidget> createState() => _FavoriteButtonWidgetState();
}

class _FavoriteButtonWidgetState extends State<FavoriteButtonWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _glowAnimation;
  
  bool _isFavorite = false;
  bool _isLoading = false;
  final List<_HeartParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkFavoriteStatus();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }

  void _checkFavoriteStatus() {
    context.read<FavoritesBloc>().add(
      CheckFavoriteStatusEvent(
        propertyId: widget.propertyId,
        userId: widget.userId,
      ),
    );
  }

  void _generateParticles() {
    _particles.clear();
    for (int i = 0; i < 8; i++) {
      _particles.add(_HeartParticle());
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FavoritesBloc, FavoritesState>(
      listener: (context, state) {
        if (state is FavoriteStatusChecked) {
          setState(() {
            _isFavorite = state.isFavorite;
            if (_isFavorite) {
              _glowController.repeat(reverse: true);
            } else {
              _glowController.stop();
              _glowController.reset();
            }
          });
        }
      },
      child: GestureDetector(
        onTap: _toggleFavorite,
        child: Container(
          width: widget.isCompact ? widget.size * 0.8 : widget.size,
          height: widget.isCompact ? widget.size * 0.8 : widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background
              if (widget.showBackground) _buildBackground(),
              
              // Heart particles
              if (_isFavorite) _buildParticles(),
              
              // Main heart icon
              _buildHeartIcon(),
              
              // Loading indicator
              if (_isLoading) _buildLoadingIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isFavorite
                  ? [
                      AppTheme.error.withOpacity(0.15 * _glowAnimation.value),
                      AppTheme.error.withOpacity(0.08 * _glowAnimation.value),
                    ]
                  : [
                      AppTheme.darkCard.withOpacity(0.5),
                      AppTheme.darkCard.withOpacity(0.3),
                    ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: _isFavorite
                  ? AppTheme.error.withOpacity(0.3)
                  : AppTheme.darkBorder.withOpacity(0.08),
              width: 0.5,
            ),
            boxShadow: _isFavorite
                ? [
                    BoxShadow(
                      color: AppTheme.error.withOpacity(0.2 * _glowAnimation.value),
                      blurRadius: 8 + 4 * _glowAnimation.value,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }

  Widget _buildHeartIcon() {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _rotationAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 0.1,
            child: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
              size: widget.isCompact ? widget.size * 0.5 : widget.size * 0.6,
              color: _isFavorite
                  ? AppTheme.error
                  : widget.showBackground
                      ? AppTheme.textWhite.withOpacity(0.7)
                      : AppTheme.textWhite.withOpacity(0.9),
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: _HeartParticlePainter(
            particles: _particles,
            progress: _particleController.value,
            center: Offset(widget.size / 2, widget.size / 2),
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.7),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SizedBox(
          width: widget.size * 0.5,
          height: widget.size * 0.5,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.primaryBlue.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleFavorite() async {
    if (_isLoading) return;
    
    HapticFeedback.mediumImpact();
    
    setState(() {
      _isLoading = true;
    });
    
    // Animate
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
    
    if (!_isFavorite) {
      _rotationController.forward();
      _generateParticles();
      _particleController.forward(from: 0);
    }
    
    // Toggle favorite
    if (_isFavorite) {
      context.read<FavoritesBloc>().add(
        RemoveFromFavoritesEvent(
          propertyId: widget.propertyId,
          userId: widget.userId,
        ),
      );
    } else {
      context.read<FavoritesBloc>().add(
        AddToFavoritesEvent(
          propertyId: widget.propertyId,
          userId: widget.userId,
        ),
      );
    }
    
    setState(() {
      _isFavorite = !_isFavorite;
      _isLoading = false;
    });
    
    if (_isFavorite) {
      _glowController.repeat(reverse: true);
    } else {
      _glowController.stop();
      _glowController.reset();
      _rotationController.reset();
    }
  }
}

// Heart Particle Model
class _HeartParticle {
  final double angle = math.Random().nextDouble() * 2 * math.pi;
  final double velocity = math.Random().nextDouble() * 2 + 1;
  final double size = math.Random().nextDouble() * 3 + 2;
  final Color color = [
    AppTheme.error,
    AppTheme.error.withOpacity(0.8),
    Colors.pink.shade300,
  ][math.Random().nextInt(3)];
}

// Heart Particle Painter
class _HeartParticlePainter extends CustomPainter {
  final List<_HeartParticle> particles;
  final double progress;
  final Offset center;

  _HeartParticlePainter({
    required this.particles,
    required this.progress,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final distance = particle.velocity * progress * 20;
      final x = center.dx + math.cos(particle.angle) * distance;
      final y = center.dy + math.sin(particle.angle) * distance;
      
      final opacity = (1 - progress).clamp(0.0, 1.0);
      
      final paint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(x, y),
        particle.size * (1 - progress * 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}