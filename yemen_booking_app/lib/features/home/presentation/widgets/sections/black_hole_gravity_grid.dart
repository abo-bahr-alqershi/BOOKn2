// lib/features/home/presentation/widgets/sections/black_hole/black_hole_gravity_grid.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:async';
import 'package:yemen_booking_app/core/theme/app_theme.dart';
import 'package:yemen_booking_app/core/theme/app_text_styles.dart';
import 'package:yemen_booking_app/core/widgets/cached_image_widget.dart';
import 'package:yemen_booking_app/features/home/data/models/section_item_models.dart';
import 'package:yemen_booking_app/features/home/presentation/widgets/sections/models/section_display_item.dart';

class BlackHoleGravityGrid extends StatefulWidget {
  final List<dynamic> items; // Can be SectionPropertyItemModel or SectionUnitItemModel
  final Function(String)? onItemTap;
  final bool isUnitView;

  const BlackHoleGravityGrid({
    super.key,
    required this.items,
    this.onItemTap,
    this.isUnitView = false,
  });

  @override
  State<BlackHoleGravityGrid> createState() => _BlackHoleGravityGridState();
}

class _BlackHoleGravityGridState extends State<BlackHoleGravityGrid>
    with TickerProviderStateMixin {
  // Black hole controllers
  late AnimationController _rotationController;
  late AnimationController _gravitationalWaveController;
  late AnimationController _accretionDiskController;
  late AnimationController _eventHorizonController;
  late AnimationController _hawkingRadiationController;
  late AnimationController _spacetimeWarpController;

  // Particle systems
  final List<_SpaceDebris> _debris = [];
  final List<_PhotonRing> _photonRings = [];
  final List<_GravitationalWave> _gravitationalWaves = [];
  final List<_HawkingParticle> _hawkingParticles = [];

  // Black hole physics
  double _mass = 1.0;
  final double _spin = 0.5;
  final double _charge = 0.0;
  Offset _singularity = Offset.zero;
  double _schwarzschildRadius = 100;

  // Property positions in gravitational field
  final Map<int, Offset> _propertyPositions = {};
  final Map<int, double> _propertyOrbits = {};

  @override
  void initState() {
    super.initState();
    _initializeBlackHole();
    _generateSpacetimeField();
    _startGravitationalCollapse();
  }

  void _initializeBlackHole() {
    _rotationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _gravitationalWaveController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _accretionDiskController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _eventHorizonController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _hawkingRadiationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _spacetimeWarpController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);
  }

  void _generateSpacetimeField() {
    // Position properties in orbital configuration
    for (int i = 0; i < widget.items.length; i++) {
      final angle = (i * 2 * math.pi) / widget.items.length;
      final radius = 150 + (i % 3) * 50;
      _propertyPositions[i] = Offset(
        math.cos(angle) * radius,
        math.sin(angle) * radius,
      );
      _propertyOrbits[i] = radius.toDouble();
    }

    // Generate space debris
    for (int i = 0; i < 50; i++) {
      _debris.add(_SpaceDebris());
    }

    // Generate photon rings
    for (int i = 0; i < 3; i++) {
      _photonRings.add(_PhotonRing(
        radius: _schwarzschildRadius * (1.5 + i * 0.5),
      ));
    }

    // Generate gravitational waves
    for (int i = 0; i < 5; i++) {
      _gravitationalWaves.add(_GravitationalWave());
    }

    // Generate Hawking radiation
    for (int i = 0; i < 20; i++) {
      _hawkingParticles.add(_HawkingParticle());
    }
  }

  void _startGravitationalCollapse() {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _mass = (_mass + 0.1).clamp(0.5, 2.0);
          _schwarzschildRadius = 100 * _mass;
        });
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _gravitationalWaveController.dispose();
    _accretionDiskController.dispose();
    _eventHorizonController.dispose();
    _hawkingRadiationController.dispose();
    _spacetimeWarpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _singularity = Offset(size.width / 2, size.height / 2);

    return SizedBox(
      height: size.height,
      child: Stack(
        children: [
          // Spacetime grid warping
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _spacetimeWarpController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _SpacetimeGridPainter(
                    singularity: _singularity,
                    warpIntensity: _spacetimeWarpController.value,
                    schwarzschildRadius: _schwarzschildRadius,
                  ),
                );
              },
            ),
          ),

          // Accretion disk
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _accretionDiskController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _AccretionDiskPainter(
                    center: _singularity,
                    rotation: _accretionDiskController.value * 2 * math.pi,
                    innerRadius: _schwarzschildRadius,
                    outerRadius: _schwarzschildRadius * 3,
                  ),
                );
              },
            ),
          ),

          // Photon sphere
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _PhotonSpherePainter(
                    center: _singularity,
                    photonRings: _photonRings,
                    rotation: _rotationController.value * 2 * math.pi,
                  ),
                );
              },
            ),
          ),

          // Properties in gravitational field
          ...widget.items.asMap().entries.map((entry) {
            final index = entry.key;
            final dynamic rawItem = entry.value;
            final item = rawItem is SectionPropertyItemModel 
                ? SectionDisplayItem.fromProperty(rawItem)
                : SectionDisplayItem.fromUnit(rawItem as SectionUnitItemModel);
            final position = _propertyPositions[index] ?? Offset.zero;

            return AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                final angle = (_rotationController.value * 2 * math.pi) +
                    (index * 2 * math.pi / widget.items.length);
                final radius = _propertyOrbits[index] ?? 150;

                final orbitalPosition = Offset(
                  _singularity.dx + math.cos(angle) * radius,
                  _singularity.dy + math.sin(angle) * radius,
                );

                // Apply gravitational lensing
                final distanceToSingularity =
                    (orbitalPosition - _singularity).distance;
                final lensing = 1.0 -
                    (_schwarzschildRadius / distanceToSingularity)
                        .clamp(0, 0.5);

                return Positioned(
                  left: orbitalPosition.dx - 100,
                  top: orbitalPosition.dy - 75,
                  child: _GravitationalPropertyCard(
                    item: item,
                    index: index,
                    gravitationalLensing: lensing,
                    distanceToEventHorizon:
                        distanceToSingularity - _schwarzschildRadius,
                    onTap: () => widget.onItemTap?.call(item.id),
                  ),
                );
              },
            );
          }),

          // Event horizon
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _eventHorizonController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _EventHorizonPainter(
                    center: _singularity,
                    radius: _schwarzschildRadius,
                    pulsation: _eventHorizonController.value,
                  ),
                );
              },
            ),
          ),

          // Gravitational waves
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _gravitationalWaveController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _GravitationalWavesPainter(
                      center: _singularity,
                      waves: _gravitationalWaves,
                      animation: _gravitationalWaveController.value,
                    ),
                  );
                },
              ),
            ),
          ),

          // Hawking radiation
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _hawkingRadiationController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _HawkingRadiationPainter(
                      center: _singularity,
                      particles: _hawkingParticles,
                      animation: _hawkingRadiationController.value,
                      eventHorizonRadius: _schwarzschildRadius,
                    ),
                  );
                },
              ),
            ),
          ),

          // Black hole info display
          Positioned(
            top: 40,
            left: 20,
            child: _buildBlackHoleInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildBlackHoleInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BLACK HOLE METRICS',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.primaryPurple,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildMetric('Mass', '${_mass.toStringAsFixed(1)} M☉'),
          _buildMetric('Spin', '${(_spin * 100).toStringAsFixed(0)}%'),
          _buildMetric(
              'Event Horizon', '${_schwarzschildRadius.toStringAsFixed(0)} km'),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 20),
          Text(
            value,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textLight,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _handlePropertyTap(SectionDisplayItem item) {
    HapticFeedback.heavyImpact();
    widget.onItemTap?.call(item.id);
  }
}

// Gravitational Property Card
class _GravitationalPropertyCard extends StatefulWidget {
  final SectionDisplayItem item;
  final int index;
  final double gravitationalLensing;
  final double distanceToEventHorizon;
  final VoidCallback onTap;

  const _GravitationalPropertyCard({
    required this.item,
    required this.index,
    required this.gravitationalLensing,
    required this.distanceToEventHorizon,
    required this.onTap,
  });

  @override
  State<_GravitationalPropertyCard> createState() =>
      _GravitationalPropertyCardState();
}

class _GravitationalPropertyCardState extends State<_GravitationalPropertyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _tidalLockController; // تم التصحيح هنا

  @override
  void initState() {
    super.initState();
    _tidalLockController = AnimationController(
      // وهنا أيضاً
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _tidalLockController.dispose(); // وهنا
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double normalizedDistance = math.max(
      0.0,
      math.min(1.0, widget.distanceToEventHorizon / 300),
    );
    final double dangerLevel = 1.0 - normalizedDistance;
    final isNearEventHorizon = dangerLevel > 0.7;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _tidalLockController,
        builder: (context, child) {
          return Container(
            width: 200 * widget.gravitationalLensing,
            height: 150 * widget.gravitationalLensing,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..scale(widget.gravitationalLensing)
              ..rotateZ(_tidalLockController.value * 0.05 * dangerLevel),
            child: Stack(
              children: [
                // Gravitational distortion container
                Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(20 / widget.gravitationalLensing),
                    boxShadow: [
                      BoxShadow(
                        color: isNearEventHorizon
                            ? AppTheme.error.withOpacity(0.5)
                            : AppTheme.primaryPurple.withOpacity(0.3),
                        blurRadius: 20 + (dangerLevel * 30),
                        spreadRadius: 2 + (dangerLevel * 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(20 / widget.gravitationalLensing),
                    child: Stack(
                      children: [
                        // Distorted property image
                        Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateX(dangerLevel * 0.2)
                            ..scale(1.0 + dangerLevel * 0.1),
                          alignment: Alignment.center,
                          child: CachedImageWidget(
                            imageUrl: widget.item.imageUrl ?? '',
                            fit: BoxFit.cover,
                          ),
                        ),

                        // Gravitational redshift effect
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.error.withOpacity(dangerLevel * 0.3),
                                AppTheme.darkBackground
                                    .withOpacity(0.7 + dangerLevel * 0.2),
                              ],
                            ),
                          ),
                        ),

                        // Content
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.darkCard.withOpacity(0.9),
                                  AppTheme.darkCard.withOpacity(0.7),
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Warning indicator
                                if (isNearEventHorizon)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    margin: const EdgeInsets.only(bottom: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.error.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '⚠ NEAR EVENT HORIZON',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppTheme.error,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                // Property name with distortion
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: isNearEventHorizon
                                        ? [AppTheme.error, AppTheme.warning]
                                        : [
                                            AppTheme.primaryPurple,
                                            AppTheme.primaryBlue
                                          ],
                                  ).createShader(bounds),
                                  child: Text(
                                    widget.item.name,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize:
                                          12 * widget.gravitationalLensing,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${widget.item.displayPrice} ريال',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          color: Colors.white.withOpacity(
                                              widget.gravitationalLensing),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      fit: FlexFit.loose,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerRight,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppTheme.primaryPurple
                                                    .withOpacity(0.3),
                                                AppTheme.primaryBlue
                                                    .withOpacity(0.2),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${widget.distanceToEventHorizon.toStringAsFixed(0)} km',
                                            maxLines: 1,
                                            overflow: TextOverflow.fade,
                                            style: AppTextStyles.caption.copyWith(
                                              color: AppTheme.textLight,
                                              fontSize: 9,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Tidal force indicator
                        if (dangerLevel > 0.5)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color:
                                      AppTheme.error.withOpacity(dangerLevel),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Black Hole Physics Models and Painters
class _SpaceDebris {
  late double x;
  late double y;
  late double vx;
  late double vy;
  late double mass;

  _SpaceDebris() {
    reset();
  }

  void reset() {
    final angle = math.Random().nextDouble() * 2 * math.pi;
    final radius = 200 + math.Random().nextDouble() * 200;
    x = math.cos(angle) * radius;
    y = math.sin(angle) * radius;

    final speed = math.Random().nextDouble() * 0.02;
    vx = -y * speed / radius;
    vy = x * speed / radius;

    mass = math.Random().nextDouble() * 5;
  }

  void updateOrbit(Offset singularity, double schwarzschildRadius) {
    final dx = singularity.dx - x;
    final dy = singularity.dy - y;
    final distance = math.sqrt(dx * dx + dy * dy);

    if (distance < schwarzschildRadius) {
      reset();
      return;
    }

    final gravity = 1000 / (distance * distance);
    vx += (dx / distance) * gravity;
    vy += (dy / distance) * gravity;

    x += vx;
    y += vy;
  }
}

class _PhotonRing {
  final double radius;

  _PhotonRing({required this.radius});
}

class _GravitationalWave {
  late double radius;
  late double intensity;
  late double speed;

  _GravitationalWave() {
    reset();
  }

  void reset() {
    radius = 0;
    intensity = 1.0;
    speed = 50;
  }

  void propagate() {
    radius += speed;
    intensity = math.max(0, 1 - radius / 500);
    if (intensity <= 0) reset();
  }
}

class _HawkingParticle {
  late double angle;
  late double distance;
  late double speed;
  late Color color;

  _HawkingParticle() {
    reset();
  }

  void reset() {
    angle = math.Random().nextDouble() * 2 * math.pi;
    distance = 0;
    speed = 1 + math.Random().nextDouble() * 2;
    color = [
      AppTheme.neonBlue,
      AppTheme.neonPurple,
      AppTheme.neonGreen
    ][math.Random().nextInt(3)];
  }

  void emit(double schwarzschildRadius) {
    distance += speed;
    if (distance > schwarzschildRadius * 3) {
      reset();
    }
  }
}

// All the CustomPainters for black hole effects

class _SpacetimeGridPainter extends CustomPainter {
  final Offset singularity;
  final double warpIntensity;
  final double schwarzschildRadius;

  _SpacetimeGridPainter({
    required this.singularity,
    required this.warpIntensity,
    required this.schwarzschildRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke
      ..color = AppTheme.primaryBlue.withOpacity(0.2);

    const gridSpacing = 30.0;

    // Draw warped grid lines
    for (double x = 0; x < size.width; x += gridSpacing) {
      final path = Path();
      path.moveTo(x, 0);

      for (double y = 0; y < size.height; y += 5) {
        final point = Offset(x, y);
        final distanceToSingularity = (point - singularity).distance;

        final warpAmount = schwarzschildRadius *
            2 /
            math.max(schwarzschildRadius, distanceToSingularity);

        final warpedPoint = Offset(
          x + (singularity.dx - x) * warpAmount * warpIntensity * 0.1,
          y,
        );

        path.lineTo(warpedPoint.dx, warpedPoint.dy);
      }

      canvas.drawPath(path, paint);
    }

    for (double y = 0; y < size.height; y += gridSpacing) {
      final path = Path();
      path.moveTo(0, y);

      for (double x = 0; x < size.width; x += 5) {
        final point = Offset(x, y);
        final distanceToSingularity = (point - singularity).distance;

        final warpAmount = schwarzschildRadius *
            2 /
            math.max(schwarzschildRadius, distanceToSingularity);

        final warpedPoint = Offset(
          x,
          y + (singularity.dy - y) * warpAmount * warpIntensity * 0.1,
        );

        path.lineTo(warpedPoint.dx, warpedPoint.dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _AccretionDiskPainter extends CustomPainter {
  final Offset center;
  final double rotation;
  final double innerRadius;
  final double outerRadius;

  _AccretionDiskPainter({
    required this.center,
    required this.rotation,
    required this.innerRadius,
    required this.outerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    // Draw accretion disk with temperature gradient
    for (double r = innerRadius; r < outerRadius; r += 5) {
      final temperature = 1 - (r - innerRadius) / (outerRadius - innerRadius);
      final paint = Paint()
        ..shader = SweepGradient(
          colors: [
            AppTheme.warning.withOpacity(temperature * 0.3),
            AppTheme.error.withOpacity(temperature * 0.4),
            AppTheme.primaryPurple.withOpacity(temperature * 0.2),
            AppTheme.warning.withOpacity(temperature * 0.3),
          ],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(Offset.zero, r, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PhotonSpherePainter extends CustomPainter {
  final Offset center;
  final List<_PhotonRing> photonRings;
  final double rotation;

  _PhotonSpherePainter({
    required this.center,
    required this.photonRings,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var ring in photonRings) {
      final paint = Paint()
        ..shader = SweepGradient(
          colors: [
            AppTheme.neonBlue.withOpacity(0.3),
            AppTheme.neonPurple.withOpacity(0.2),
            Colors.transparent,
            AppTheme.neonBlue.withOpacity(0.3),
          ],
          transform: GradientRotation(rotation),
        ).createShader(Rect.fromCircle(center: center, radius: ring.radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(center, ring.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _EventHorizonPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final double pulsation;

  _EventHorizonPainter({
    required this.center,
    required this.radius,
    required this.pulsation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw event horizon
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black,
          Colors.black.withOpacity(0.9),
          AppTheme.primaryPurple.withOpacity(0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7, 0.9, 1.0],
      ).createShader(Rect.fromCircle(
          center: center, radius: radius * (1 + pulsation * 0.1)))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * (1 + pulsation * 0.1), paint);

    // Draw event horizon boundary
    final boundaryPaint = Paint()
      ..color = AppTheme.error.withOpacity(0.3 + pulsation * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawCircle(center, radius, boundaryPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _GravitationalWavesPainter extends CustomPainter {
  final Offset center;
  final List<_GravitationalWave> waves;
  final double animation;

  _GravitationalWavesPainter({
    required this.center,
    required this.waves,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var wave in waves) {
      wave.propagate();

      if (wave.intensity > 0) {
        final paint = Paint()
          ..color = AppTheme.primaryBlue.withOpacity(wave.intensity * 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

        canvas.drawCircle(center, wave.radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _HawkingRadiationPainter extends CustomPainter {
  final Offset center;
  final List<_HawkingParticle> particles;
  final double animation;
  final double eventHorizonRadius;

  _HawkingRadiationPainter({
    required this.center,
    required this.particles,
    required this.animation,
    required this.eventHorizonRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.emit(eventHorizonRadius);

      final x = center.dx +
          math.cos(particle.angle) * (eventHorizonRadius + particle.distance);
      final y = center.dy +
          math.sin(particle.angle) * (eventHorizonRadius + particle.distance);

      final paint = Paint()
        ..color = particle.color.withOpacity(
            0.8 * (1 - particle.distance / (eventHorizonRadius * 3)))
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(Offset(x, y), 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
