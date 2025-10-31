// lib/features/home/presentation/widgets/sections/crystal_constellation/crystal_constellation_network.dart

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

class CrystalConstellationNetwork extends StatefulWidget {
  final List<dynamic> items; // Can be SectionPropertyItemModel or SectionUnitItemModel
  final Function(String)? onItemTap;
  final bool isUnitView;

  const CrystalConstellationNetwork({
    super.key,
    required this.items,
    this.onItemTap,
    this.isUnitView = false,
  });

  @override
  State<CrystalConstellationNetwork> createState() => 
      _CrystalConstellationNetworkState();
}

class _CrystalConstellationNetworkState extends State<CrystalConstellationNetwork>
    with TickerProviderStateMixin {
  // Crystal Controllers
  late AnimationController _crystalFormationController;
  late AnimationController _constellationRotationController;
  late AnimationController _resonanceController;
  late AnimationController _fractalGrowthController;
  late AnimationController _prismRefractionController;
  late AnimationController _stellarPulseController;
  late AnimationController _harmonicController;
  late AnimationController _latticeVibrationController;
  
  // Crystal Network
  final Map<int, _CrystalNode> _crystalNodes = {};
  final List<_ConstellationLink> _constellationLinks = [];
  final List<_CrystalShard> _floatingShards = [];
  final List<_StellarLight> _stellarLights = [];
  final List<_PrismBeam> _prismBeams = [];
  final List<_ResonanceWave> _resonanceWaves = [];
  final List<_FractalBranch> _fractalBranches = [];
  
  // Crystal States
  double _crystallizationLevel = 0.5;
  double _resonanceFrequency = 440.0;
  int _activeCrystal = -1;
  bool _isResonating = false;
  Offset? _resonanceCenter;
  
  // Harmonic frequencies for each property
  final Map<int, double> _harmonicFrequencies = {};
  Timer? _crystallizationTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeCrystalSystem();
    _generateCrystalNetwork();
    _startCrystallization();
  }
  
  void _initializeCrystalSystem() {
    _crystalFormationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);
    
    _constellationRotationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
    
    _resonanceController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _fractalGrowthController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat(reverse: true);
    
    _prismRefractionController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    _stellarPulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _harmonicController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();
    
    _latticeVibrationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }
  
  void _generateCrystalNetwork() {
    // Create crystal nodes in 3D space
    for (int i = 0; i < widget.items.length; i++) {
      final theta = (i * 2 * math.pi) / widget.items.length;
      final phi = (i * math.pi) / widget.items.length;
      final radius = 150 + (i % 3) * 50;
      
      _crystalNodes[i] = _CrystalNode(
        position: Offset(
          radius * math.sin(theta) * math.cos(phi),
          radius * math.sin(theta) * math.sin(phi),
        ),
        frequency: 440.0 * math.pow(2, i / 12), // Musical scale
        crystalType: _CrystalType.values[i % _CrystalType.values.length],
        resonancePattern: _generateResonancePattern(),
      );
      
      _harmonicFrequencies[i] = _crystalNodes[i]!.frequency;
    }
    
    // Create constellation links
    _crystalNodes.forEach((id, node) {
      _crystalNodes.forEach((targetId, targetNode) {
        if (id < targetId) {
          final distance = (node.position - targetNode.position).distance;
          if (distance < 200) {
            _constellationLinks.add(_ConstellationLink(
              start: id,
              end: targetId,
              strength: 1.0 - (distance / 200),
            ));
          }
        }
      });
    });
    
    // Generate floating crystal shards
    for (int i = 0; i < 50; i++) {
      _floatingShards.add(_CrystalShard());
    }
    
    // Generate stellar lights
    for (int i = 0; i < 30; i++) {
      _stellarLights.add(_StellarLight());
    }
    
    // Generate prism beams
    for (int i = 0; i < 8; i++) {
      _prismBeams.add(_PrismBeam(
        wavelength: 380 + (i * 50), // Visible spectrum
      ));
    }
    
    // Generate resonance waves
    for (int i = 0; i < 5; i++) {
      _resonanceWaves.add(_ResonanceWave());
    }
    
    // Generate fractal branches
    _generateFractalBranches(Offset.zero, 0, 5);
  }
  
  void _generateFractalBranches(Offset origin, double angle, int depth) {
    if (depth == 0) return;
    
    final length = 50.0 * depth / 5;
    final endPoint = Offset(
      origin.dx + math.cos(angle) * length,
      origin.dy + math.sin(angle) * length,
    );
    
    _fractalBranches.add(_FractalBranch(
      start: origin,
      end: endPoint,
      depth: depth,
    ));
    
    // Recursive branching
    _generateFractalBranches(endPoint, angle - math.pi / 6, depth - 1);
    _generateFractalBranches(endPoint, angle + math.pi / 6, depth - 1);
  }
  
  List<double> _generateResonancePattern() {
    return List.generate(8, (i) => math.Random().nextDouble());
  }
  
  void _startCrystallization() {
    _crystallizationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _activeCrystal = math.Random().nextInt(widget.items.length);
          _crystallizationLevel = (_crystallizationLevel + 0.1).clamp(0, 1);
        });
        _triggerResonance(_activeCrystal);
      }
    });
  }
  
  void _triggerResonance(int crystalId) {
    setState(() {
      _isResonating = true;
      _resonanceCenter = _crystalNodes[crystalId]?.position;
      _resonanceFrequency = _harmonicFrequencies[crystalId] ?? 440.0;
    });
    
    _latticeVibrationController.forward().then((_) {
      _latticeVibrationController.reverse().then((_) {
        setState(() {
          _isResonating = false;
        });
      });
    });
    
    HapticFeedback.heavyImpact();
  }
  
  @override
  void dispose() {
    _crystallizationTimer?.cancel();
    _crystalFormationController.dispose();
    _constellationRotationController.dispose();
    _resonanceController.dispose();
    _fractalGrowthController.dispose();
    _prismRefractionController.dispose();
    _stellarPulseController.dispose();
    _harmonicController.dispose();
    _latticeVibrationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return SizedBox(
      height: size.height,
      child: Stack(
        children: [
          // Stellar background
          Positioned.fill(
            child: _buildStellarBackground(),
          ),
          
          // Fractal crystal growth
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _fractalGrowthController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _FractalCrystalPainter(
                    branches: _fractalBranches,
                    growth: _fractalGrowthController.value,
                    crystallization: _crystallizationLevel,
                  ),
                );
              },
            ),
          ),
          
          // Constellation network
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _constellationRotationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ConstellationNetworkPainter(
                    nodes: _crystalNodes,
                    links: _constellationLinks,
                    rotation: _constellationRotationController.value * 2 * math.pi,
                    activeCrystal: _activeCrystal,
                  ),
                );
              },
            ),
          ),
          
          // Crystal nodes (items)
          ...widget.items.asMap().entries.map((entry) {
            final index = entry.key;
            final dynamic rawItem = entry.value;
            final item = rawItem is SectionPropertyItemModel 
                ? SectionDisplayItem.fromProperty(rawItem)
                : SectionDisplayItem.fromUnit(rawItem as SectionUnitItemModel);
            final node = _crystalNodes[index]!;
            
            return AnimatedBuilder(
              animation: Listenable.merge([
                _crystalFormationController,
                _resonanceController,
                _stellarPulseController,
              ]),
              builder: (context, child) {
                final formation = _crystalFormationController.value;
                final resonance = _resonanceController.value;
                final pulse = _stellarPulseController.value;
                final isActive = _activeCrystal == index;
                
                // Apply 3D transformation
                final rotationY = _constellationRotationController.value * 2 * math.pi;
                final transformed = _apply3DTransform(node.position, rotationY);
                
                return Positioned(
                  left: size.width / 2 + transformed.dx - 110,
                  top: size.height / 2 + transformed.dy - 85,
                  child: _CrystalPropertyNode(
                    item: item,
                    index: index,
                    crystalType: node.crystalType,
                    isActive: isActive,
                    formation: formation,
                    resonance: isActive ? resonance : 0,
                    pulse: pulse,
                    frequency: node.frequency,
                    onTap: () => _handleCrystalTap(item, index),
                  ),
                );
              },
            );
          }),
          
          // Prism refraction overlay
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _prismRefractionController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _PrismRefractionPainter(
                      beams: _prismBeams,
                      refraction: _prismRefractionController.value,
                      crystallization: _crystallizationLevel,
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Resonance waves
          if (_isResonating && _resonanceCenter != null)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _latticeVibrationController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ResonanceWavePainter(
                      center: Offset(
                        size.width / 2 + _resonanceCenter!.dx,
                        size.height / 2 + _resonanceCenter!.dy,
                      ),
                      waves: _resonanceWaves,
                      vibration: _latticeVibrationController.value,
                      frequency: _resonanceFrequency,
                    ),
                  );
                },
              ),
            ),
          
          // Crystal control interface
          Positioned(
            top: 40,
            right: 20,
            child: _buildCrystalControlPanel(),
          ),
        ],
      ),
    );
  }
  
  Offset _apply3DTransform(Offset position, double rotationY) {
    final x = position.dx * math.cos(rotationY) - 
              position.dy * 0.3 * math.sin(rotationY);
    final y = position.dy * 0.8 + position.dx * 0.2 * math.sin(rotationY);
    final z = position.dx * math.sin(rotationY) + 
              position.dy * 0.3 * math.cos(rotationY);
    
    // Perspective projection
    final scale = 1.0 + z / 500;
    
    return Offset(x * scale, y * scale);
  }
  
  Widget _buildStellarBackground() {
    return AnimatedBuilder(
      animation: _stellarPulseController,
      builder: (context, child) {
        return CustomPaint(
          painter: _StellarBackgroundPainter(
            lights: _stellarLights,
            pulse: _stellarPulseController.value,
          ),
        );
      },
    );
  }
  
  Widget _buildCrystalControlPanel() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.9),
            AppTheme.darkCard.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppTheme.primaryPurple,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'CRYSTAL MATRIX',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.primaryPurple,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMetric('Crystallization', 
              '${(_crystallizationLevel * 100).toStringAsFixed(0)}%'),
          _buildMetric('Resonance', 
              '${_resonanceFrequency.toStringAsFixed(0)} Hz'),
          _buildMetric('Nodes', '${_crystalNodes.length}'),
          _buildMetric('Links', '${_constellationLinks.length}'),
        ],
      ),
    );
  }
  
  Widget _buildMetric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
  
  void _handleCrystalTap(SectionDisplayItem item, int crystalId) {
    _triggerResonance(crystalId);
    widget.onItemTap?.call(item.id);
  }
}

// Crystal Property Node Widget
class _CrystalPropertyNode extends StatefulWidget {
  final SectionDisplayItem item;
  final int index;
  final _CrystalType crystalType;
  final bool isActive;
  final double formation;
  final double resonance;
  final double pulse;
  final double frequency;
  final VoidCallback onTap;

  const _CrystalPropertyNode({
    required this.item,
    required this.index,
    required this.crystalType,
    required this.isActive,
    required this.formation,
    required this.resonance,
    required this.pulse,
    required this.frequency,
    required this.onTap,
  });

  @override
  State<_CrystalPropertyNode> createState() => _CrystalPropertyNodeState();
}

class _CrystalPropertyNodeState extends State<_CrystalPropertyNode>
    with TickerProviderStateMixin {
  late AnimationController _crystalSpinController;
  late AnimationController _facetGlowController;
  late AnimationController _latticeController;
  
  @override
  void initState() {
    super.initState();
    
    _crystalSpinController = AnimationController(
      duration: Duration(seconds: 10 + widget.index % 5),
      vsync: this,
    )..repeat();
    
    _facetGlowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _latticeController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _crystalSpinController.dispose();
    _facetGlowController.dispose();
    _latticeController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _crystalSpinController,
          _facetGlowController,
          _latticeController,
        ]),
        builder: (context, child) {
          final spin = _crystalSpinController.value * 2 * math.pi;
          final glow = _facetGlowController.value;
          final lattice = _latticeController.value;
          
          return Container(
            width: 220,
            height: 170,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(spin * 0.1)
              ..rotateZ(math.sin(spin) * 0.05)
              ..scale(widget.isActive ? 1.15 : 1.0),
            child: Stack(
              children: [
                // Crystal structure
                Container(
                  decoration: BoxDecoration(
                    borderRadius: _getCrystalShape(),
                    boxShadow: [
                      // Crystal glow
                      BoxShadow(
                        color: _getCrystalColor().withOpacity(
                          widget.isActive ? 0.6 : 0.3 + glow * 0.2,
                        ),
                        blurRadius: 30 + glow * 15,
                        spreadRadius: 5,
                      ),
                      // Inner light
                      BoxShadow(
                        color: _getCrystalColor().withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  child: ClipPath(
                    clipper: _CrystalClipper(widget.crystalType),
                    child: Stack(
                      children: [
                        // Crystal background
                        _buildCrystalBackground(spin, lattice),
                        
                        // Facet reflections
                        _buildFacetReflections(glow),
                        
                        // Content
                        _buildCrystalContent(),
                        
                        // Resonance effect
                        if (widget.isActive)
                          _buildResonanceEffect(widget.resonance),
                      ],
                    ),
                  ),
                ),
                
                // Crystal lattice overlay
                if (widget.isActive)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CrystalLatticePainter(
                        crystalType: widget.crystalType,
                        animation: lattice,
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
  
  BorderRadius _getCrystalShape() {
    switch (widget.crystalType) {
      case _CrystalType.hexagonal:
        return BorderRadius.circular(30);
      case _CrystalType.cubic:
        return BorderRadius.circular(15);
      case _CrystalType.tetragonal:
        return const BorderRadius.vertical(
          top: Radius.circular(10),
          bottom: Radius.circular(30),
        );
      case _CrystalType.orthorhombic:
        return const BorderRadius.horizontal(
          left: Radius.circular(30),
          right: Radius.circular(10),
        );
    }
  }
  
  Color _getCrystalColor() {
    switch (widget.crystalType) {
      case _CrystalType.hexagonal:
        return AppTheme.neonBlue;
      case _CrystalType.cubic:
        return AppTheme.neonPurple;
      case _CrystalType.tetragonal:
        return AppTheme.neonGreen;
      case _CrystalType.orthorhombic:
        return AppTheme.primaryCyan;
    }
  }
  
  Widget _buildCrystalBackground(double spin, double lattice) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Property image with crystal filter
        Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..scale(1.0 + widget.formation * 0.1)
            ..rotateZ(spin * 0.02),
          alignment: Alignment.center,
          child: Hero(
            tag: 'crystal_${widget.item.id}_${widget.index}',
            child: CachedImageWidget(
              imageUrl: widget.item.imageUrl ?? '',
              fit: BoxFit.cover,
            ),
          ),
        ),
        
        // Crystal gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getCrystalColor().withOpacity(0.2),
                _getCrystalColor().withOpacity(0.1),
                AppTheme.darkBackground.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFacetReflections(double glow) {
    return CustomPaint(
      painter: _FacetReflectionPainter(
        crystalType: widget.crystalType,
        glow: glow,
        color: _getCrystalColor(),
      ),
    );
  }
  
  Widget _buildCrystalContent() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkCard.withOpacity(0.7),
                  AppTheme.darkCard.withOpacity(0.5),
                ],
              ),
              border: Border(
                top: BorderSide(
                  color: _getCrystalColor().withOpacity(0.3),
                  width: widget.isActive ? 2 : 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Crystal type indicator
                Row(
                  children: [
                    Icon(
                      _getCrystalIcon(),
                      size: 12,
                      color: _getCrystalColor(),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getCrystalTypeName(),
                      style: AppTextStyles.caption.copyWith(
                        color: _getCrystalColor(),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Frequency indicator
                    Text(
                      '${widget.frequency.toStringAsFixed(0)} Hz',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Property name with crystal shimmer
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: widget.isActive
                        ? [_getCrystalColor(), Colors.white, _getCrystalColor()]
                        : [Colors.white, Colors.white],
                  ).createShader(bounds),
                  child: Text(
                    widget.item.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Price and formation level
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [_getCrystalColor(), AppTheme.primaryPurple],
                      ).createShader(bounds),
                      child: Text(
                        '${widget.item.displayPrice} ريال',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    // Crystal formation level
                    Container(
                      width: 50,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: widget.formation,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_getCrystalColor(), AppTheme.primaryPurple],
                            ),
                            borderRadius: BorderRadius.circular(2),
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
      ),
    );
  }
  
  Widget _buildResonanceEffect(double resonance) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: _getCrystalColor().withOpacity(resonance),
            width: 2,
          ),
          borderRadius: _getCrystalShape(),
        ),
      ),
    );
  }
  
  IconData _getCrystalIcon() {
    switch (widget.crystalType) {
      case _CrystalType.hexagonal:
        return Icons.hexagon_outlined;
      case _CrystalType.cubic:
        return Icons.crop_square;
      case _CrystalType.tetragonal:
        return Icons.rectangle_outlined;
      case _CrystalType.orthorhombic:
        return Icons.diamond_outlined;
    }
  }
  
  String _getCrystalTypeName() {
    switch (widget.crystalType) {
      case _CrystalType.hexagonal:
        return 'HEXAGONAL';
      case _CrystalType.cubic:
        return 'CUBIC';
      case _CrystalType.tetragonal:
        return 'TETRAGONAL';
      case _CrystalType.orthorhombic:
        return 'ORTHORHOMBIC';
    }
  }
}

// Crystal System Models and Enums
enum _CrystalType {
  hexagonal,
  cubic,
  tetragonal,
  orthorhombic,
}

class _CrystalNode {
  final Offset position;
  final double frequency;
  final _CrystalType crystalType;
  final List<double> resonancePattern;
  
  _CrystalNode({
    required this.position,
    required this.frequency,
    required this.crystalType,
    required this.resonancePattern,
  });
}

class _ConstellationLink {
  final int start;
  final int end;
  final double strength;
  
  _ConstellationLink({
    required this.start,
    required this.end,
    required this.strength,
  });
}

class _CrystalShard {
  late double x;
  late double y;
  late double z;
  late double vx;
  late double vy;
  late double vz;
  late double size;
  late Color color;
  
  _CrystalShard() {
    reset();
  }
  
  void reset() {
    x = math.Random().nextDouble() * 2 - 1;
    y = math.Random().nextDouble() * 2 - 1;
    z = math.Random().nextDouble();
    vx = (math.Random().nextDouble() - 0.5) * 0.01;
    vy = (math.Random().nextDouble() - 0.5) * 0.01;
    vz = (math.Random().nextDouble() - 0.5) * 0.01;
    size = math.Random().nextDouble() * 3 + 1;
    color = [
      AppTheme.neonBlue,
      AppTheme.neonPurple,
      AppTheme.neonGreen,
      AppTheme.primaryCyan,
    ][math.Random().nextInt(4)];
  }
  
  void float() {
    x += vx;
    y += vy;
    z += vz;
    
    if (x.abs() > 1) vx = -vx;
    if (y.abs() > 1) vy = -vy;
    if (z < 0 || z > 1) vz = -vz;
  }
}

class _StellarLight {
  late double x;
  late double y;
  late double brightness;
  late double twinkleSpeed;
  late double twinklePhase;
  
  _StellarLight() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    brightness = math.Random().nextDouble() * 0.5 + 0.5;
    twinkleSpeed = math.Random().nextDouble() * 2 + 1;
    twinklePhase = math.Random().nextDouble() * 2 * math.pi;
  }
}

class _PrismBeam {
  final double wavelength;
  late double angle;
  late double intensity;
  
  _PrismBeam({required this.wavelength}) {
    angle = math.Random().nextDouble() * 2 * math.pi;
    intensity = math.Random().nextDouble() * 0.5 + 0.5;
  }
  
  Color get color {
    // Convert wavelength to RGB color
    if (wavelength < 450) return AppTheme.primaryPurple;
    if (wavelength < 500) return AppTheme.primaryBlue;
    if (wavelength < 550) return AppTheme.primaryCyan;
    if (wavelength < 600) return AppTheme.neonGreen;
    if (wavelength < 650) return AppTheme.warning;
    return AppTheme.error;
  }
}

class _ResonanceWave {
  late double radius;
  late double speed;
  late double intensity;
  
  _ResonanceWave() {
    reset();
  }
  
  void reset() {
    radius = 0;
    speed = 30 + math.Random().nextDouble() * 30;
    intensity = 1.0;
  }
  
  void propagate() {
    radius += speed;
    intensity = math.max(0, 1 - radius / 300);
    if (intensity <= 0) reset();
  }
}

class _FractalBranch {
  final Offset start;
  final Offset end;
  final int depth;
  
  _FractalBranch({
    required this.start,
    required this.end,
    required this.depth,
  });
}

// All Custom Painters for Crystal System

class _StellarBackgroundPainter extends CustomPainter {
  final List<_StellarLight> lights;
  final double pulse;
  
  _StellarBackgroundPainter({
    required this.lights,
    required this.pulse,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw gradient background
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.darkBackground,
          AppTheme.darkBackground2,
          AppTheme.darkBackground3,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );
    
    // Draw stellar lights
    for (var light in lights) {
      final twinkle = math.sin(light.twinklePhase + pulse * light.twinkleSpeed * 2 * math.pi);
      final opacity = light.brightness * (0.5 + 0.5 * twinkle);
      
      final paint = Paint()
        ..color = Colors.white.withOpacity(opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      
      canvas.drawCircle(
        Offset(light.x * size.width, light.y * size.height),
        1 + twinkle,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _FractalCrystalPainter extends CustomPainter {
  final List<_FractalBranch> branches;
  final double growth;
  final double crystallization;
  
  _FractalCrystalPainter({
    required this.branches,
    required this.growth,
    required this.crystallization,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    for (var branch in branches) {
      final opacity = (branch.depth / 5) * growth * crystallization;
      
      final paint = Paint()
        ..strokeWidth = branch.depth / 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            AppTheme.primaryPurple.withOpacity(opacity * 0.3),
            AppTheme.primaryCyan.withOpacity(opacity * 0.2),
          ],
        ).createShader(Rect.fromPoints(
          center + branch.start * 2,
          center + branch.end * 2,
        ));
      
      canvas.drawLine(
        center + branch.start * 2,
        center + branch.end * 2 * growth,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ConstellationNetworkPainter extends CustomPainter {
  final Map<int, _CrystalNode> nodes;
  final List<_ConstellationLink> links;
  final double rotation;
  final int activeCrystal;
  
  _ConstellationNetworkPainter({
    required this.nodes,
    required this.links,
    required this.rotation,
    required this.activeCrystal,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw constellation links
    for (var link in links) {
      if (nodes.containsKey(link.start) && nodes.containsKey(link.end)) {
        final startNode = nodes[link.start]!;
        final endNode = nodes[link.end]!;
        
        final isActive = link.start == activeCrystal || link.end == activeCrystal;
        
        final paint = Paint()
          ..strokeWidth = isActive ? 1.5 : 0.5 * link.strength
          ..style = PaintingStyle.stroke
          ..shader = LinearGradient(
            colors: [
              isActive ? AppTheme.neonBlue : AppTheme.primaryPurple.withOpacity(0.2),
              isActive ? AppTheme.neonPurple : AppTheme.primaryCyan.withOpacity(0.1),
            ],
          ).createShader(Rect.fromPoints(
            center + startNode.position,
            center + endNode.position,
          ));
        
        canvas.drawLine(
          center + startNode.position,
          center + endNode.position,
          paint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PrismRefractionPainter extends CustomPainter {
  final List<_PrismBeam> beams;
  final double refraction;
  final double crystallization;
  
  _PrismRefractionPainter({
    required this.beams,
    required this.refraction,
    required this.crystallization,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    for (var beam in beams) {
      final refractionAngle = beam.angle + refraction * 2 * math.pi;
      final length = size.width * 0.4 * crystallization;
      
      final paint = Paint()
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..shader = LinearGradient(
          colors: [
            beam.color.withOpacity(0.0),
            beam.color.withOpacity(beam.intensity * 0.3),
            beam.color.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCenter(
          center: center,
          width: length * 2,
          height: length * 2,
        ))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      
      canvas.drawLine(
        center,
        center + Offset(
          math.cos(refractionAngle) * length,
          math.sin(refractionAngle) * length,
        ),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ResonanceWavePainter extends CustomPainter {
  final Offset center;
  final List<_ResonanceWave> waves;
  final double vibration;
  final double frequency;
  
  _ResonanceWavePainter({
    required this.center,
    required this.waves,
    required this.vibration,
    required this.frequency,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    for (var wave in waves) {
      wave.propagate();
      
      if (wave.intensity > 0) {
        final paint = Paint()
          ..shader = RadialGradient(
            colors: [
              AppTheme.primaryPurple.withOpacity(wave.intensity * 0.3),
              AppTheme.primaryCyan.withOpacity(wave.intensity * 0.2),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: center, radius: wave.radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 + vibration * 2;
        
        // Draw resonance ring with harmonic distortion
        final path = Path();
        for (double angle = 0; angle < 2 * math.pi; angle += 0.1) {
          final harmonicDistortion = math.sin(angle * frequency / 100) * 5 * vibration;
          final x = center.dx + math.cos(angle) * (wave.radius + harmonicDistortion);
          final y = center.dy + math.sin(angle) * (wave.radius + harmonicDistortion);
          
          if (angle == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
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

class _CrystalClipper extends CustomClipper<Path> {
  final _CrystalType crystalType;
  
  _CrystalClipper(this.crystalType);
  
  @override
  Path getClip(Size size) {
    final path = Path();
    
    switch (crystalType) {
      case _CrystalType.hexagonal:
        // Hexagonal shape
        final centerX = size.width / 2;
        final centerY = size.height / 2;
        final radius = size.width / 2.5;
        
        for (int i = 0; i < 6; i++) {
          final angle = (i * math.pi / 3) - math.pi / 2;
          final x = centerX + radius * math.cos(angle);
          final y = centerY + radius * math.sin(angle);
          
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        break;
        
      case _CrystalType.cubic:
        // Cubic shape with beveled edges
        const bevel = 20.0;
        path.moveTo(bevel, 0);
        path.lineTo(size.width - bevel, 0);
        path.lineTo(size.width, bevel);
        path.lineTo(size.width, size.height - bevel);
        path.lineTo(size.width - bevel, size.height);
        path.lineTo(bevel, size.height);
        path.lineTo(0, size.height - bevel);
        path.lineTo(0, bevel);
        path.close();
        break;
        
      case _CrystalType.tetragonal:
        // Tetragonal shape (elongated octagon)
        path.moveTo(size.width * 0.3, 0);
        path.lineTo(size.width * 0.7, 0);
        path.lineTo(size.width, size.height * 0.3);
        path.lineTo(size.width, size.height * 0.7);
        path.lineTo(size.width * 0.7, size.height);
        path.lineTo(size.width * 0.3, size.height);
        path.lineTo(0, size.height * 0.7);
        path.lineTo(0, size.height * 0.3);
        path.close();
        break;
        
      case _CrystalType.orthorhombic:
        // Orthorhombic shape (diamond)
        path.moveTo(size.width / 2, 0);
        path.lineTo(size.width, size.height / 2);
        path.lineTo(size.width / 2, size.height);
        path.lineTo(0, size.height / 2);
        path.close();
        break;
    }
    
    return path;
  }
  
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _CrystalLatticePainter extends CustomPainter {
  final _CrystalType crystalType;
  final double animation;
  
  _CrystalLatticePainter({
    required this.crystalType,
    required this.animation,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke
      ..color = AppTheme.primaryPurple.withOpacity(0.2);
    
    // Draw crystal lattice structure
    const spacing = 15.0;
    
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        final offset = math.sin(animation * 2 * math.pi + x * 0.01 + y * 0.01) * 2;
        
        // Draw lattice point
        canvas.drawCircle(
          Offset(x + offset, y + offset),
          1,
          paint,
        );
        
        // Draw connections
        if (x + spacing < size.width) {
          canvas.drawLine(
            Offset(x + offset, y + offset),
            Offset(x + spacing + offset, y + offset),
            paint,
          );
        }
        
        if (y + spacing < size.height) {
          canvas.drawLine(
            Offset(x + offset, y + offset),
            Offset(x + offset, y + spacing + offset),
            paint,
          );
        }
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _FacetReflectionPainter extends CustomPainter {
  final _CrystalType crystalType;
  final double glow;
  final Color color;
  
  _FacetReflectionPainter({
    required this.crystalType,
    required this.glow,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    
    // Draw facet reflections based on crystal type
    switch (crystalType) {
      case _CrystalType.hexagonal:
        // Hexagonal facets
        for (int i = 0; i < 6; i++) {
          final angle = (i * math.pi / 3) - math.pi / 2;
          final centerX = size.width / 2;
          final centerY = size.height / 2;
          final radius = size.width / 3;
          
          paint.shader = RadialGradient(
            center: Alignment(
              math.cos(angle) * 0.5,
              math.sin(angle) * 0.5,
            ),
            colors: [
              color.withOpacity(0.1 * glow),
              Colors.transparent,
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
          
          final path = Path();
          path.moveTo(centerX, centerY);
          path.lineTo(
            centerX + radius * math.cos(angle),
            centerY + radius * math.sin(angle),
          );
          path.lineTo(
            centerX + radius * math.cos(angle + math.pi / 3),
            centerY + radius * math.sin(angle + math.pi / 3),
          );
          path.close();
          
          canvas.drawPath(path, paint);
        }
        break;
        
      case _CrystalType.cubic:
      case _CrystalType.tetragonal:
      case _CrystalType.orthorhombic:
        // Simple glow for other types
        paint.shader = RadialGradient(
          colors: [
            color.withOpacity(0.05 * glow),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
        
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height),
          paint,
        );
        break;
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
          