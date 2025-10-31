// lib/features/home/presentation/widgets/sections/single_property_offer/cosmic_single_property_offer_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:yemen_booking_app/core/theme/app_theme.dart';
import 'package:yemen_booking_app/core/theme/app_text_styles.dart';
import 'package:yemen_booking_app/core/widgets/cached_image_widget.dart';
import 'package:yemen_booking_app/features/home/data/models/section_item_models.dart';
import 'package:yemen_booking_app/features/home/presentation/widgets/sections/models/section_display_item.dart';

class CosmicSinglePropertyOfferWidget extends StatefulWidget {
  final dynamic item; // Can be SectionPropertyItemModel or SectionUnitItemModel
  final VoidCallback onTap;
  final bool isUnitView;

  const CosmicSinglePropertyOfferWidget({
    super.key,
    required this.item,
    required this.onTap,
    this.isUnitView = false,
  });

  @override
  State<CosmicSinglePropertyOfferWidget> createState() =>
      _CosmicSinglePropertyOfferWidgetState();
  
  // Helper to get display item
  SectionDisplayItem get displayItem => 
      item is SectionPropertyItemModel 
          ? SectionDisplayItem.fromProperty(item)
          : SectionDisplayItem.fromUnit(item as SectionUnitItemModel);
}

class _CosmicSinglePropertyOfferWidgetState
    extends State<CosmicSinglePropertyOfferWidget>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _cosmicWaveController;
  late AnimationController _ribbonController;
  late AnimationController _glowController;
  late AnimationController _priceController;
  late AnimationController _confettiController;
  late AnimationController _badgePulseController;
  late AnimationController _pressController;
  late AnimationController _starFieldController;
  late AnimationController _nebulaController;

  // Animations
  late Animation<double> _cosmicWaveAnimation;
  late Animation<double> _ribbonAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _priceAnimation;
  late Animation<double> _badgePulseAnimation;
  late Animation<double> _scaleAnimation;

  // Particles
  final List<_CosmicConfetti> _confettiPieces = [];
  final List<_StarParticle> _stars = [];
  final List<_NebulaCloud> _nebulaClouds = [];

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateParticles();
  }

  void _initializeAnimations() {
    _cosmicWaveController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _ribbonController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _priceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _confettiController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _badgePulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _starFieldController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _nebulaController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    // Setup animations
    _cosmicWaveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cosmicWaveController,
      curve: Curves.easeInOut,
    ));

    _ribbonAnimation = Tween<double>(
      begin: -0.02,
      end: 0.02,
    ).animate(CurvedAnimation(
      parent: _ribbonController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _priceAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _priceController,
      curve: Curves.elasticInOut,
    ));

    _badgePulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _badgePulseController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOut,
    ));
  }

  void _generateParticles() {
    // Generate confetti
    for (int i = 0; i < 25; i++) {
      _confettiPieces.add(_CosmicConfetti());
    }

    // Generate stars
    for (int i = 0; i < 30; i++) {
      _stars.add(_StarParticle());
    }

    // Generate nebula clouds
    for (int i = 0; i < 5; i++) {
      _nebulaClouds.add(_NebulaCloud());
    }
  }

  @override
  void dispose() {
    _cosmicWaveController.dispose();
    _ribbonController.dispose();
    _glowController.dispose();
    _priceController.dispose();
    _confettiController.dispose();
    _badgePulseController.dispose();
    _pressController.dispose();
    _starFieldController.dispose();
    _nebulaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark;

    return GestureDetector(
      onTapDown: (_) => _onPressStart(),
      onTapUp: (_) => _onPressEnd(),
      onTapCancel: _onPressEnd,
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              height: 420,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Stack(
                children: [
                  // Cosmic background
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _cosmicWaveController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _CosmicBackgroundPainter(
                            waveAnimation: _cosmicWaveAnimation.value,
                            stars: _stars,
                            nebulaClouds: _nebulaClouds,
                          ),
                        );
                      },
                    ),
                  ),

                  // Confetti layer
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _confettiController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _CosmicConfettiPainter(
                            confetti: _confettiPieces,
                            animationValue: _confettiController.value,
                          ),
                        );
                      },
                    ),
                  ),

                  // Main card
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            // Cosmic glow
                            BoxShadow(
                              color: AppTheme.neonBlue.withOpacity(
                                0.3 + (_glowAnimation.value * 0.2),
                              ),
                              blurRadius: 40 + (_glowAnimation.value * 20),
                              spreadRadius: 8 + (_glowAnimation.value * 5),
                              offset:
                                  Offset(0, 15 + (_glowAnimation.value * 5)),
                            ),
                            // Success glow
                            BoxShadow(
                              color: AppTheme.success.withOpacity(
                                0.2 + (_glowAnimation.value * 0.15),
                              ),
                              blurRadius: 30,
                              spreadRadius: 2,
                              offset: const Offset(0, 10),
                            ),
                            // Dark shadow
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                              blurRadius: 20,
                              spreadRadius: -5,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Background image
                              _buildPropertyImage(),

                              // Gradient overlay
                              _buildGradientOverlay(),

                              // Glass layer
                              _buildGlassLayer(),

                              // Cosmic overlay
                              _buildCosmicOverlay(),

                              // Content
                              _buildContent(),

                              // Offer ribbon
                              Positioned(
                                top: 30,
                                right: -35,
                                child: _buildOfferRibbon(),
                              ),

                              // Limited time badge
                              Positioned(
                                top: 20,
                                left: 20,
                                child: _buildLimitedTimeBadge(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPropertyImage() {
    return Hero(
      tag: 'cosmic_offer_${widget.displayItem.id}',
      child: CachedImageWidget(
        imageUrl: widget.displayItem.imageUrl ?? '',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.1),
            Colors.black.withOpacity(0.5),
            Colors.black.withOpacity(0.9),
          ],
          stops: const [0.2, 0.6, 1.0],
        ),
      ),
    );
  }

  Widget _buildGlassLayer() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
      ),
    );
  }

  Widget _buildCosmicOverlay() {
    return AnimatedBuilder(
      animation: _starFieldController,
      builder: (context, child) {
        return CustomPaint(
          painter: _StarFieldPainter(
            animation: _starFieldController.value,
          ),
        );
      },
    );
  }

  Widget _buildOfferRibbon() {
    return AnimatedBuilder(
      animation: _ribbonAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: math.pi / 4 + _ribbonAnimation.value,
          child: Container(
            width: 180,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.error,
                  AppTheme.warning,
                  AppTheme.error,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.error.withOpacity(0.6),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                'عرض خاص',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLimitedTimeBadge() {
    return AnimatedBuilder(
      animation: _badgePulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.success,
                AppTheme.primaryCyan,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.success.withOpacity(
                  0.5 + (_badgePulseAnimation.value * 0.2),
                ),
                blurRadius: 20 + (_badgePulseAnimation.value * 10),
                spreadRadius: 2 + (_badgePulseAnimation.value * 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'لفترة محدودة',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    final originalPrice = widget.displayItem.price;
    final discount = widget.displayItem.discount ?? 30;
    final discountedPrice = widget.displayItem.discountedPrice ?? originalPrice * (1 - discount / 100);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.darkCard.withOpacity(0.3),
                  AppTheme.darkCard.withOpacity(0.85),
                ],
              ),
              border: Border(
                top: BorderSide(
                  color: AppTheme.success.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.white.withOpacity(0.95),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    widget.displayItem.name,
                    style: AppTextStyles.heading1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 12),

                // Location
                if (widget.displayItem.location != null || widget.displayItem.city != null)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.success.withOpacity(0.25),
                              AppTheme.primaryCyan.withOpacity(0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: AppTheme.success,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.displayItem.location ?? widget.displayItem.city ?? '',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Features
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (widget.displayItem.bedrooms != null &&
                        widget.displayItem.bedrooms! > 0)
                      _buildFeatureChip(
                        Icons.king_bed_rounded,
                        '${widget.displayItem.bedrooms} غرف',
                      ),
                    if (widget.displayItem.bathrooms != null &&
                        widget.displayItem.bathrooms! > 0)
                      _buildFeatureChip(
                        Icons.bathtub_rounded,
                        '${widget.displayItem.bathrooms} حمام',
                      ),
                    if (widget.displayItem.area != null &&
                        widget.displayItem.area! > 0)
                      _buildFeatureChip(
                        Icons.square_foot_rounded,
                        '${widget.displayItem.area!.toStringAsFixed(0)} م²',
                      ),
                    // Unit specific features
                    if (widget.displayItem.maxCapacity != null &&
                        widget.displayItem.maxCapacity! > 0)
                      _buildFeatureChip(
                        Icons.people_rounded,
                        '${widget.displayItem.maxCapacity} أشخاص',
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // Price and CTA Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Price section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Original price
                          Text(
                            '${originalPrice.toStringAsFixed(0)} ريال',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppTheme.textMuted,
                              decoration: TextDecoration.lineThrough,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Discounted price with animation
                          AnimatedBuilder(
                            animation: _priceAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _priceAnimation.value,
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    ShaderMask(
                                      shaderCallback: (bounds) =>
                                          LinearGradient(
                                        colors: [
                                          AppTheme.success,
                                          AppTheme.primaryCyan,
                                        ],
                                      ).createShader(bounds),
                                      child: Text(
                                        discountedPrice.toStringAsFixed(0),
                                        style: AppTextStyles.heading1.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 32,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'ريال/ليلة',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppTheme.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // CTA Button
                    _buildCTAButton(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.success.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.success,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTAButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.success,
            AppTheme.primaryCyan,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.success.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'احجز الآن',
            style: AppTextStyles.buttonMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white,
            size: 18,
          ),
        ],
      ),
    );
  }

  void _onPressStart() {
    setState(() => _isPressed = true);
    _pressController.forward();
    HapticFeedback.selectionClick();
  }

  void _onPressEnd() {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }
}

// Cosmic Confetti Model
class _CosmicConfetti {
  late double x;
  late double y;
  late double vx;
  late double vy;
  late double size;
  late Color color;
  late double rotation;
  late double rotationSpeed;

  _CosmicConfetti() {
    reset();
  }

  void reset() {
    x = math.Random().nextDouble();
    y = -0.1;
    vx = (math.Random().nextDouble() - 0.5) * 0.003;
    vy = math.Random().nextDouble() * 0.004 + 0.002;
    size = math.Random().nextDouble() * 8 + 4;
    rotation = math.Random().nextDouble() * 2 * math.pi;
    rotationSpeed = (math.Random().nextDouble() - 0.5) * 0.15;

    final colors = [
      AppTheme.success,
      AppTheme.warning,
      AppTheme.primaryCyan,
      AppTheme.primaryBlue,
      AppTheme.primaryPurple,
      AppTheme.neonGreen,
    ];
    color = colors[math.Random().nextInt(colors.length)];
  }

  void update() {
    x += vx;
    y += vy;
    rotation += rotationSpeed;
    if (y > 1.1) {
      reset();
    }
  }
}

// Star Particle Model
class _StarParticle {
  late double x;
  late double y;
  late double size;
  late double twinkle;
  late double twinkleSpeed;

  _StarParticle() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    size = math.Random().nextDouble() * 2 + 0.5;
    twinkle = math.Random().nextDouble();
    twinkleSpeed = math.Random().nextDouble() * 0.02 + 0.01;
  }

  void update() {
    twinkle += twinkleSpeed;
    if (twinkle > 1) twinkle = 0;
  }
}

// Nebula Cloud Model
class _NebulaCloud {
  late double x;
  late double y;
  late double size;
  late Color color;
  late double opacity;
  late double drift;

  _NebulaCloud() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    size = math.Random().nextDouble() * 100 + 50;
    opacity = math.Random().nextDouble() * 0.2 + 0.1;
    drift = 0;

    final colors = [
      AppTheme.primaryBlue,
      AppTheme.primaryPurple,
      AppTheme.primaryCyan,
    ];
    color = colors[math.Random().nextInt(colors.length)];
  }

  void update(double animation) {
    drift = math.sin(animation * 2 * math.pi) * 0.02;
  }
}

// Cosmic Background Painter
class _CosmicBackgroundPainter extends CustomPainter {
  final double waveAnimation;
  final List<_StarParticle> stars;
  final List<_NebulaCloud> nebulaClouds;

  _CosmicBackgroundPainter({
    required this.waveAnimation,
    required this.stars,
    required this.nebulaClouds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw nebula clouds
    for (var cloud in nebulaClouds) {
      cloud.update(waveAnimation);

      final paint = Paint()
        ..color = cloud.color.withOpacity(cloud.opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cloud.size / 2);

      canvas.drawCircle(
        Offset((cloud.x + cloud.drift) * size.width, cloud.y * size.height),
        cloud.size,
        paint,
      );
    }

    // Draw stars
    for (var star in stars) {
      star.update();

      final opacity = 0.3 + (0.7 * math.sin(star.twinkle * math.pi));
      final paint = Paint()
        ..color = Colors.white.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Cosmic Confetti Painter
class _CosmicConfettiPainter extends CustomPainter {
  final List<_CosmicConfetti> confetti;
  final double animationValue;

  _CosmicConfettiPainter({
    required this.confetti,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var piece in confetti) {
      piece.update();

      canvas.save();
      canvas.translate(piece.x * size.width, piece.y * size.height);
      canvas.rotate(piece.rotation);

      final paint = Paint()
        ..color = piece.color.withOpacity(0.85)
        ..style = PaintingStyle.fill;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: piece.size,
          height: piece.size * 0.7,
        ),
        Radius.circular(piece.size * 0.2),
      );

      canvas.drawRRect(rrect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Star Field Painter
class _StarFieldPainter extends CustomPainter {
  final double animation;

  _StarFieldPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryBlue.withOpacity(0.02)
      ..style = PaintingStyle.fill;

    // Draw animated cosmic waves
    final path = Path();
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x += 10) {
      final y = size.height * 0.8 +
          math.sin((x / size.width * 4 * math.pi) + (animation * 2 * math.pi)) *
              20;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
