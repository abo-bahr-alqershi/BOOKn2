// lib/features/home/presentation/widgets/sections/single_property_ad/holographic_single_property_ad_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:yemen_booking_app/core/theme/app_theme.dart';
import 'package:yemen_booking_app/core/theme/app_text_styles.dart';
import 'package:yemen_booking_app/core/widgets/cached_image_widget.dart';
import 'package:yemen_booking_app/features/home/data/models/section_item_models.dart';
import 'package:yemen_booking_app/core/models/paginated_result.dart';
import 'package:yemen_booking_app/features/home/presentation/widgets/sections/models/section_display_item.dart';

class HolographicSinglePropertyAdWidget extends StatefulWidget {
  final String sectionId;
  final PaginatedResult<SectionPropertyItemModel>? data;
  final Function(String)? onItemTap;

  const HolographicSinglePropertyAdWidget({
    super.key,
    required this.sectionId,
    this.data,
    this.onItemTap,
  });
  
  SectionDisplayItem? get displayItem {
    if (data == null || data!.items.isEmpty) return null;
    final item = data!.items.first;
    return item is SectionPropertyItemModel
        ? SectionDisplayItem.fromProperty(item)
        : SectionDisplayItem.fromUnit(item as SectionUnitItemModel);
  }

  @override
  State<HolographicSinglePropertyAdWidget> createState() =>
      _HolographicSinglePropertyAdWidgetState();
}

class _HolographicSinglePropertyAdWidgetState
    extends State<HolographicSinglePropertyAdWidget>
    with TickerProviderStateMixin {
  // Holographic Controllers
  late AnimationController _hologramController;
  late AnimationController _glitchController;
  late AnimationController _scanlineController;
  late AnimationController _neonPulseController;
  late AnimationController _dataStreamController;
  late AnimationController _prismController;
  late AnimationController _pressController;

  // Animations
  late Animation<double> _hologramAnimation;
  late Animation<double> _glitchAnimation;
  late Animation<double> _scanlineAnimation;
  late Animation<double> _neonPulseAnimation;
  late Animation<double> _dataStreamAnimation;
  late Animation<double> _prismAnimation;
  late Animation<double> _scaleAnimation;

  // Hologram layers
  final List<_HologramLayer> _hologramLayers = [];
  final List<_DataStream> _dataStreams = [];

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _initializeHolographicAnimations();
    _generateHologramLayers();
    _generateDataStreams();
  }

  void _initializeHolographicAnimations() {
    _hologramController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _scanlineController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _neonPulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _dataStreamController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();

    _prismController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // Setup animations
    _hologramAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_hologramController);

    _glitchAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glitchController,
      curve: Curves.elasticOut,
    ));

    _scanlineAnimation = Tween<double>(
      begin: -0.2,
      end: 1.2,
    ).animate(_scanlineController);

    _neonPulseAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _neonPulseController,
      curve: Curves.easeInOut,
    ));

    _dataStreamAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_dataStreamController);

    _prismAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_prismController);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOut,
    ));

    // Random glitch effect
    _startRandomGlitch();
  }

  void _startRandomGlitch() {
    Future.delayed(Duration(seconds: 3 + math.Random().nextInt(5)), () {
      if (mounted) {
        _glitchController.forward().then((_) {
          _glitchController.reverse().then((_) {
            _startRandomGlitch();
          });
        });
      }
    });
  }

  void _generateHologramLayers() {
    for (int i = 0; i < 3; i++) {
      _hologramLayers.add(_HologramLayer(
        offset: i * 0.02,
        color: [
          AppTheme.neonBlue,
          AppTheme.neonPurple,
          AppTheme.neonGreen,
        ][i],
      ));
    }
  }

  void _generateDataStreams() {
    for (int i = 0; i < 10; i++) {
      _dataStreams.add(_DataStream());
    }
  }

  @override
  void dispose() {
    _hologramController.dispose();
    _glitchController.dispose();
    _scanlineController.dispose();
    _neonPulseController.dispose();
    _dataStreamController.dispose();
    _prismController.dispose();
    _pressController.dispose();
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
        HapticFeedback.heavyImpact();
        if (widget.displayItem != null) {
          widget.onItemTap?.call(widget.displayItem!.id);
        }
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              height: 400,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Stack(
                children: [
                  // Data streams background
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _dataStreamAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _DataStreamPainter(
                            streams: _dataStreams,
                            animation: _dataStreamAnimation.value,
                          ),
                        );
                      },
                    ),
                  ),

                  // Main holographic card
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _hologramAnimation,
                      _glitchAnimation,
                      _neonPulseAnimation,
                    ]),
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            // Neon glow
                            BoxShadow(
                              color: AppTheme.neonBlue.withOpacity(
                                0.3 * _neonPulseAnimation.value,
                              ),
                              blurRadius: 40 + (_neonPulseAnimation.value * 20),
                              spreadRadius: 5,
                            ),
                            // Warning glow
                            BoxShadow(
                              color: AppTheme.warning.withOpacity(
                                0.2 * _neonPulseAnimation.value,
                              ),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Holographic layers
                              ..._buildHologramLayers(),

                              // Glitch effect
                              if (_glitchAnimation.value > 0)
                                _buildGlitchEffect(),

                              // Scanline effect
                              _buildScanlineEffect(),

                              // Prism refraction
                              _buildPrismEffect(),

                              // Ad badge
                              Positioned(
                                top: 20,
                                left: 20,
                                child: _buildHolographicAdBadge(),
                              ),

                              // Content
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: _buildHolographicContent(),
                              ),

                              // Holographic border
                              _buildHolographicBorder(),
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

  List<Widget> _buildHologramLayers() {
    return _hologramLayers.map((layer) {
      return AnimatedBuilder(
        animation: _hologramAnimation,
        builder: (context, child) {
          final offset = math.sin(_hologramAnimation.value * 2 * math.pi) *
              layer.offset *
              10;

          return Transform.translate(
            offset: Offset(offset, offset / 2),
            child: Opacity(
              opacity: 0.3,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  layer.color.withOpacity(0.5),
                  BlendMode.screen,
                ),
                child: CachedImageWidget(
                  imageUrl: widget.displayItem?.imageUrl ?? '',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildGlitchEffect() {
    return AnimatedBuilder(
      animation: _glitchAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            (math.Random().nextDouble() - 0.5) * 10 * _glitchAnimation.value,
            (math.Random().nextDouble() - 0.5) * 10 * _glitchAnimation.value,
          ),
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              AppTheme.error.withOpacity(0.2),
              BlendMode.screen,
            ),
            child: CachedImageWidget(
              imageUrl: widget.displayItem?.imageUrl ?? '',
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildScanlineEffect() {
    return AnimatedBuilder(
      animation: _scanlineAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: _ScanlinePainter(
            position: _scanlineAnimation.value,
          ),
        );
      },
    );
  }

  Widget _buildPrismEffect() {
    return AnimatedBuilder(
      animation: _prismAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: _PrismPainter(
            rotation: _prismAnimation.value,
          ),
        );
      },
    );
  }

  Widget _buildHolographicAdBadge() {
    return AnimatedBuilder(
      animation: _neonPulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.neonBlue,
                AppTheme.neonPurple,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.neonBlue.withOpacity(
                  0.5 + (_neonPulseAnimation.value * 0.3),
                ),
                blurRadius: 20 + (_neonPulseAnimation.value * 10),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'إعلان هولوجرامي',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHolographicContent() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
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
                color: AppTheme.neonBlue.withOpacity(0.3),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title with holographic effect
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    AppTheme.neonBlue,
                    AppTheme.neonPurple,
                    AppTheme.neonGreen,
                  ],
                ).createShader(bounds),
                child: Text(
                  widget.displayItem?.name ?? '',
                  style: AppTextStyles.heading1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 12),

              // Location with neon effect
              if (widget.displayItem?.location != null || widget.displayItem?.city != null)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.neonBlue.withOpacity(0.25),
                            AppTheme.neonPurple.withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: AppTheme.neonBlue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.displayItem?.location ?? widget.displayItem?.city ?? '',
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

              // Holographic features
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (widget.displayItem?.bedrooms != null &&
                      widget.displayItem!.bedrooms! > 0)
                    _buildHolographicFeature(
                      Icons.king_bed_rounded,
                      '${widget.displayItem!.bedrooms} غرف',
                    ),
                  if (widget.displayItem?.bathrooms != null &&
                      widget.displayItem!.bathrooms! > 0)
                    _buildHolographicFeature(
                      Icons.bathtub_rounded,
                      '${widget.displayItem!.bathrooms} حمام',
                    ),
                  if (widget.displayItem?.area != null && widget.displayItem!.area! > 0)
                    _buildHolographicFeature(
                      Icons.square_foot_rounded,
                      '${widget.displayItem!.area!.toStringAsFixed(0)} م²',
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // Price and CTA
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Holographic price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'السعر الحصري',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.neonBlue,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            AppTheme.neonBlue,
                            AppTheme.neonPurple,
                          ],
                        ).createShader(bounds),
                        child: Text(
                          '${widget.displayItem?.displayPrice ?? '0'} ريال',
                          style: AppTextStyles.heading1.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Holographic CTA button
                  _buildHolographicCTA(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHolographicFeature(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.neonBlue.withOpacity(0.3),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonBlue.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.neonBlue,
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

  Widget _buildHolographicCTA() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonBlue,
            AppTheme.neonPurple,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonBlue.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'عرض التفاصيل',
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

  Widget _buildHolographicBorder() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              width: 2,
              color: AppTheme.neonBlue.withOpacity(0.3),
            ),
          ),
        ),
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

// Hologram Layer Model
class _HologramLayer {
  final double offset;
  final Color color;

  _HologramLayer({
    required this.offset,
    required this.color,
  });
}

// Data Stream Model
class _DataStream {
  late double x;
  late double speed;
  late String data;
  late Color color;

  _DataStream() {
    reset();
  }

  void reset() {
    x = math.Random().nextDouble();
    speed = math.Random().nextDouble() * 0.002 + 0.001;
    data = _generateRandomData();

    final colors = [
      AppTheme.neonBlue,
      AppTheme.neonPurple,
      AppTheme.neonGreen,
    ];
    color = colors[math.Random().nextInt(colors.length)];
  }

  String _generateRandomData() {
    const chars = '01010101ABCDEF';
    return List.generate(
        8, (index) => chars[math.Random().nextInt(chars.length)]).join();
  }

  void update() {
    x -= speed;
    if (x < -0.2) {
      reset();
      x = 1.2;
    }
  }
}

// Data Stream Painter
class _DataStreamPainter extends CustomPainter {
  final List<_DataStream> streams;
  final double animation;

  _DataStreamPainter({
    required this.streams,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (var stream in streams) {
      stream.update();

      textPainter.text = TextSpan(
        text: stream.data,
        style: TextStyle(
          color: stream.color.withOpacity(0.2),
          fontSize: 10,
          fontFamily: 'monospace',
        ),
      );

      textPainter.layout();

      final y = math.Random().nextDouble() * size.height;
      textPainter.paint(
        canvas,
        Offset(stream.x * size.width, y),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Scanline Painter
class _ScanlinePainter extends CustomPainter {
  final double position;

  _ScanlinePainter({required this.position});

  @override
  void paint(Canvas canvas, Size size) {
    if (position < 0 || position > 1) return;

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          AppTheme.neonGreen.withOpacity(0.1),
          AppTheme.neonGreen.withOpacity(0.2),
          AppTheme.neonGreen.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 20));

    final y = position * size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, y - 10, size.width, 20),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Prism Painter
class _PrismPainter extends CustomPainter {
  final double rotation;

  _PrismPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 3; i++) {
      final angle = rotation + (i * 2 * math.pi / 3);
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            [
              AppTheme.neonBlue,
              AppTheme.neonPurple,
              AppTheme.neonGreen,
            ][i]
                .withOpacity(0.05),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + math.cos(angle) * size.width,
          center.dy + math.sin(angle) * size.height,
        )
        ..lineTo(
          center.dx + math.cos(angle + 0.1) * size.width,
          center.dy + math.sin(angle + 0.1) * size.height,
        )
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
