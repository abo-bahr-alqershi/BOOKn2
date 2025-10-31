// lib/features/home/presentation/widgets/sections/liquid_crystal/liquid_crystal_property_list.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:yemen_booking_app/core/theme/app_theme.dart';
import 'package:yemen_booking_app/core/theme/app_text_styles.dart';
import 'package:yemen_booking_app/core/widgets/cached_image_widget.dart';
import 'package:yemen_booking_app/features/home/data/models/section_item_models.dart';
import 'package:yemen_booking_app/features/home/presentation/widgets/sections/models/section_display_item.dart';

class LiquidCrystalPropertyList extends StatefulWidget {
  final List<dynamic>
      items; // Can be SectionPropertyItemModel or SectionUnitItemModel
  final Function(String)? onItemTap;
  final bool isUnitView;

  const LiquidCrystalPropertyList({
    super.key,
    required this.items,
    this.onItemTap,
    this.isUnitView = false,
  });

  @override
  State<LiquidCrystalPropertyList> createState() =>
      _LiquidCrystalPropertyListState();
}

class _LiquidCrystalPropertyListState extends State<LiquidCrystalPropertyList>
    with TickerProviderStateMixin {
  // Liquid animation controllers
  late AnimationController _liquidFlowController;
  late AnimationController _crystalFormationController;
  late AnimationController _viscosityController;
  late AnimationController _refractionController;
  late AnimationController _molecularController;

  // Liquid particles
  final List<_LiquidParticle> _particles = [];
  final List<_CrystalFormation> _crystals = [];
  final List<_MolecularChain> _molecules = [];

  // Fluid dynamics
  double _viscosity = 0.5;
  double _temperature = 0.5;
  final double _pressure = 0.5;

  @override
  void initState() {
    super.initState();
    _initializeLiquidSystem();
    _generateLiquidStructure();
  }

  void _initializeLiquidSystem() {
    _liquidFlowController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _crystalFormationController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat(reverse: true);

    _viscosityController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    _refractionController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _molecularController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  void _generateLiquidStructure() {
    // Generate liquid particles
    for (int i = 0; i < 100; i++) {
      _particles.add(_LiquidParticle());
    }

    // Generate crystal formations
    for (int i = 0; i < 15; i++) {
      _crystals.add(_CrystalFormation());
    }

    // Generate molecular chains
    for (int i = 0; i < 20; i++) {
      _molecules.add(_MolecularChain());
    }
  }

  @override
  void dispose() {
    _liquidFlowController.dispose();
    _crystalFormationController.dispose();
    _viscosityController.dispose();
    _refractionController.dispose();
    _molecularController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 450,
      child: Stack(
        children: [
          // Liquid crystal background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _liquidFlowController,
                _viscosityController,
              ]),
              builder: (context, child) {
                _viscosity = _viscosityController.value;
                return CustomPaint(
                  painter: _LiquidCrystalBackgroundPainter(
                    flowAnimation: _liquidFlowController.value,
                    viscosity: _viscosity,
                    particles: _particles,
                  ),
                );
              },
            ),
          ),

          // Crystal formations
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _crystalFormationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CrystalFormationPainter(
                    crystals: _crystals,
                    formationProgress: _crystalFormationController.value,
                  ),
                );
              },
            ),
          ),

          // Properties list
          ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _LiquidCrystalCard(
                  property: widget.items[index],
                  index: index,
                  viscosity: _viscosity,
                  onTap: () => _handlePropertyTap(widget.items[index]),
                ),
              );
            },
          ),

          // Molecular overlay
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _molecularController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _MolecularOverlayPainter(
                      molecules: _molecules,
                      animation: _molecularController.value,
                    ),
                  );
                },
              ),
            ),
          ),

          // Refraction effect
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _refractionController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _RefractionPainter(
                      refractionIndex: _refractionController.value,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handlePropertyTap(SectionPropertyItemModel property) {
    HapticFeedback.heavyImpact();
    // Trigger crystal formation
    setState(() {
      _temperature = (_temperature + 0.1).clamp(0, 1);
    });
    widget.onItemTap?.call(property.id);
  }
}

// Liquid Crystal Card
class _LiquidCrystalCard extends StatefulWidget {
  final SectionPropertyItemModel property;
  final int index;
  final double viscosity;
  final VoidCallback onTap;

  const _LiquidCrystalCard({
    required this.property,
    required this.index,
    required this.viscosity,
    required this.onTap,
  });

  @override
  State<_LiquidCrystalCard> createState() => _LiquidCrystalCardState();
}

class _LiquidCrystalCardState extends State<_LiquidCrystalCard>
    with TickerProviderStateMixin {
  late AnimationController _crystalController;
  late AnimationController _flowController;
  late AnimationController _hoverController;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    _crystalController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _flowController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _crystalController.dispose();
    _flowController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _onHoverStart(),
      onTapUp: (_) => _onHoverEnd(),
      onTapCancel: _onHoverEnd,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _crystalController,
          _flowController,
          _hoverController,
        ]),
        builder: (context, child) {
          final crystalValue = _crystalController.value;
          final flowValue = _flowController.value;
          final hoverValue = _hoverController.value;

          return Container(
            width: 280,
            height: 360,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(hoverValue * 0.1)
              ..scale(1.0 + hoverValue * 0.05),
            child: Stack(
              children: [
                // Liquid crystal container
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.neonBlue.withOpacity(0.3),
                        blurRadius: 30 + crystalValue * 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Base image with liquid effect
                        _buildLiquidImage(flowValue),

                        // Crystal formation overlay
                        _buildCrystalOverlay(crystalValue),

                        // Content with liquid glass
                        _buildLiquidContent(crystalValue, hoverValue),
                      ],
                    ),
                  ),
                ),

                // Liquid border animation
                if (_isHovered) _buildLiquidBorder(flowValue),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLiquidImage(double flowValue) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Property image
        Hero(
          tag: 'liquid_${widget.property.id}_${widget.index}',
          child: CachedImageWidget(
            imageUrl: widget.property.imageUrl ?? '',
            fit: BoxFit.cover,
          ),
        ),

        // Liquid distortion effect
        ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: math.sin(flowValue * 2 * math.pi) * 2,
              sigmaY: math.cos(flowValue * 2 * math.pi) * 2,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppTheme.darkBackground.withOpacity(0.7),
                    AppTheme.darkBackground.withOpacity(0.95),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCrystalOverlay(double crystalValue) {
    return CustomPaint(
      painter: _LiquidCrystalOverlayPainter(
        crystallization: crystalValue,
        viscosity: widget.viscosity,
      ),
      child: Container(),
    );
  }

  Widget _buildLiquidContent(double crystalValue, double hoverValue) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 15 + crystalValue * 10,
            sigmaY: 15 + crystalValue * 10,
          ),
          child: Container(
            padding: EdgeInsets.all(20 + hoverValue * 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkCard.withOpacity(0.7 + crystalValue * 0.2),
                  AppTheme.darkCard.withOpacity(0.5),
                ],
              ),
              border: Border(
                top: BorderSide(
                  color:
                      AppTheme.neonBlue.withOpacity(0.3 + crystalValue * 0.4),
                  width: 1 + crystalValue,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Liquid crystal indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.neonBlue.withOpacity(0.3),
                        AppTheme.neonPurple.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.neonGreen,
                              AppTheme.neonGreen.withOpacity(0.3),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Liquid Crystal',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.neonGreen,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Property name with liquid effect
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      AppTheme.neonBlue,
                      AppTheme.neonPurple,
                      AppTheme.neonBlue,
                    ],
                    stops: [
                      0.0,
                      0.5 + crystalValue * 0.3,
                      1.0,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    widget.property.name,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16 + hoverValue * 2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 10),

                // Location with liquid flow
                if (widget.property.location != null)
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.neonBlue.withOpacity(0.5),
                              AppTheme.neonBlue.withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.water_drop_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.property.location!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textLight.withOpacity(0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Price with crystal formation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Crystal Price',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              AppTheme.neonBlue,
                              AppTheme.neonPurple,
                              AppTheme.neonGreen,
                            ],
                          ).createShader(bounds),
                          child: Text(
                            '${widget.property.minPrice.toStringAsFixed(0)} ريال',
                            style: AppTextStyles.heading1.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20 + crystalValue * 4,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Crystal formation indicator
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CustomPaint(
                        painter: _CrystalIconPainter(
                          formation: crystalValue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiquidBorder(double flowValue) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            width: 2,
            color: AppTheme.neonBlue.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  void _onHoverStart() {
    setState(() => _isHovered = true);
    _hoverController.forward();
    HapticFeedback.selectionClick();
  }

  void _onHoverEnd() {
    setState(() => _isHovered = false);
    _hoverController.reverse();
  }
}

// Liquid Crystal Models and Painters
class _LiquidParticle {
  late double x;
  late double y;
  late double vx;
  late double vy;
  late double size;
  late Color color;
  late double viscosity;

  _LiquidParticle() {
    reset();
  }

  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    vx = (math.Random().nextDouble() - 0.5) * 0.01;
    vy = (math.Random().nextDouble() - 0.5) * 0.01;
    size = math.Random().nextDouble() * 4 + 2;
    viscosity = math.Random().nextDouble() * 0.5 + 0.5;
    color = [
      AppTheme.neonBlue,
      AppTheme.neonPurple,
      AppTheme.neonGreen,
    ][math.Random().nextInt(3)];
  }

  void update(double globalViscosity) {
    final friction = viscosity * globalViscosity;
    vx *= (1 - friction * 0.1);
    vy *= (1 - friction * 0.1);

    x += vx;
    y += vy;

    // Bounce off edges
    if (x < 0 || x > 1) {
      vx = -vx;
      x = x.clamp(0, 1);
    }
    if (y < 0 || y > 1) {
      vy = -vy;
      y = y.clamp(0, 1);
    }
  }
}

class _CrystalFormation {
  late double x;
  late double y;
  late double size;
  late int branches;
  late double rotation;
  late Color color;

  _CrystalFormation() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    size = math.Random().nextDouble() * 30 + 20;
    branches = 4 + math.Random().nextInt(4);
    rotation = math.Random().nextDouble() * 2 * math.pi;
    color = AppTheme.neonBlue.withOpacity(0.3);
  }
}

class _MolecularChain {
  late List<Offset> nodes;
  late Color color;
  late double thickness;

  _MolecularChain() {
    nodes = [];
    final nodeCount = 5 + math.Random().nextInt(5);
    for (int i = 0; i < nodeCount; i++) {
      nodes.add(Offset(
        math.Random().nextDouble(),
        math.Random().nextDouble(),
      ));
    }
    color = AppTheme.neonPurple.withOpacity(0.2);
    thickness = math.Random().nextDouble() * 2 + 1;
  }
}

class _LiquidCrystalBackgroundPainter extends CustomPainter {
  final double flowAnimation;
  final double viscosity;
  final List<_LiquidParticle> particles;

  _LiquidCrystalBackgroundPainter({
    required this.flowAnimation,
    required this.viscosity,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw liquid flow
    final flowPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final phase = flowAnimation + (i * 0.2);
      final path = Path();

      path.moveTo(0, size.height);

      for (double x = 0; x <= size.width; x += 10) {
        final y = size.height * 0.5 +
            math.sin((x / size.width * 3 * math.pi) + (phase * 2 * math.pi)) *
                (50 * (1 - viscosity));
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.close();

      flowPaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.neonBlue.withOpacity(0.05 - i * 0.01),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(path, flowPaint);
    }

    // Draw liquid particles
    for (var particle in particles) {
      particle.update(viscosity);

      final paint = Paint()
        ..color = particle.color.withOpacity(0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.size / 2);

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CrystalFormationPainter extends CustomPainter {
  final List<_CrystalFormation> crystals;
  final double formationProgress;

  _CrystalFormationPainter({
    required this.crystals,
    required this.formationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var crystal in crystals) {
      canvas.save();
      canvas.translate(crystal.x * size.width, crystal.y * size.height);
      canvas.rotate(crystal.rotation + formationProgress * math.pi / 4);

      final paint = Paint()
        ..color = crystal.color.withOpacity(formationProgress * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;

      // Draw crystal branches
      for (int i = 0; i < crystal.branches; i++) {
        final angle = (i * 2 * math.pi) / crystal.branches;
        final length = crystal.size * formationProgress;

        final path = Path();
        path.moveTo(0, 0);
        path.lineTo(
          math.cos(angle) * length,
          math.sin(angle) * length,
        );

        canvas.drawPath(path, paint);

        // Draw sub-branches
        for (double t = 0.3; t < 1; t += 0.3) {
          final subLength = length * t * 0.3;
          final baseX = math.cos(angle) * length * t;
          final baseY = math.sin(angle) * length * t;

          path.moveTo(baseX, baseY);
          path.lineTo(
            baseX + math.cos(angle + math.pi / 6) * subLength,
            baseY + math.sin(angle + math.pi / 6) * subLength,
          );

          path.moveTo(baseX, baseY);
          path.lineTo(
            baseX + math.cos(angle - math.pi / 6) * subLength,
            baseY + math.sin(angle - math.pi / 6) * subLength,
          );
        }

        canvas.drawPath(path, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MolecularOverlayPainter extends CustomPainter {
  final List<_MolecularChain> molecules;
  final double animation;

  _MolecularOverlayPainter({
    required this.molecules,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var molecule in molecules) {
      final paint = Paint()
        ..color = molecule.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = molecule.thickness
        ..strokeCap = StrokeCap.round;

      final path = Path();

      for (int i = 0; i < molecule.nodes.length; i++) {
        final node = molecule.nodes[i];
        final x = node.dx * size.width;
        final y =
            node.dy * size.height + math.sin(animation * 2 * math.pi + i) * 10;

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          final prevNode = molecule.nodes[i - 1];
          final prevX = prevNode.dx * size.width;
          final prevY = prevNode.dy * size.height +
              math.sin(animation * 2 * math.pi + (i - 1)) * 10;

          path.quadraticBezierTo(
            (prevX + x) / 2,
            (prevY + y) / 2 + 20,
            x,
            y,
          );
        }

        // Draw node
        canvas.drawCircle(
          Offset(x, y),
          3,
          Paint()
            ..color = molecule.color.withOpacity(0.5)
            ..style = PaintingStyle.fill,
        );
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _RefractionPainter extends CustomPainter {
  final double refractionIndex;

  _RefractionPainter({required this.refractionIndex});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw light refraction beams
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 10; i++) {
      final startX = size.width * i / 10;
      const startY = 0.0;

      // Incident ray
      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.neonBlue.withOpacity(0.2),
          AppTheme.neonBlue.withOpacity(0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      const incidentAngle = math.pi / 4;
      final refractionAngle = math.asin(
        math.sin(incidentAngle) / (1.33 + refractionIndex * 0.2),
      );

      final path = Path();
      path.moveTo(startX, startY);

      // Draw incident ray
      path.lineTo(
        startX + 50 * math.sin(incidentAngle),
        startY + 50 * math.cos(incidentAngle),
      );

      // Draw refracted ray
      path.lineTo(
        startX + 50 * math.sin(incidentAngle) + 100 * math.sin(refractionAngle),
        startY + 50 * math.cos(incidentAngle) + 100 * math.cos(refractionAngle),
      );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LiquidCrystalOverlayPainter extends CustomPainter {
  final double crystallization;
  final double viscosity;

  _LiquidCrystalOverlayPainter({
    required this.crystallization,
    required this.viscosity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw crystal lattice formation
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = AppTheme.neonBlue.withOpacity(0.1 * crystallization);

    const spacing = 15.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Hexagonal crystal structure
        final center = Offset(
          x + math.sin(crystallization * 2 * math.pi) * 2,
          y + math.cos(crystallization * 2 * math.pi) * 2,
        );

        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = (i * math.pi / 3) + crystallization * math.pi / 6;
          final vertex = Offset(
            center.dx + spacing * 0.5 * math.cos(angle),
            center.dy + spacing * 0.5 * math.sin(angle),
          );

          if (i == 0) {
            path.moveTo(vertex.dx, vertex.dy);
          } else {
            path.lineTo(vertex.dx, vertex.dy);
          }
        }
        path.close();

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CrystalIconPainter extends CustomPainter {
  final double formation;

  _CrystalIconPainter({required this.formation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Draw rotating crystal structure
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(formation * math.pi);

    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4);
      final length = 20 * formation;

      paint.shader = LinearGradient(
        colors: [
          AppTheme.neonBlue,
          AppTheme.neonPurple.withOpacity(0.5),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: length));

      final path = Path();
      path.moveTo(0, 0);
      path.lineTo(
        math.cos(angle) * length,
        math.sin(angle) * length,
      );

      canvas.drawPath(path, paint);

      // Draw crystal facets
      if (formation > 0.5) {
        final facetLength = length * 0.5;
        path.moveTo(
          math.cos(angle) * length * 0.5,
          math.sin(angle) * length * 0.5,
        );
        path.lineTo(
          math.cos(angle + math.pi / 8) * facetLength,
          math.sin(angle + math.pi / 8) * facetLength,
        );

        canvas.drawPath(path, paint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
