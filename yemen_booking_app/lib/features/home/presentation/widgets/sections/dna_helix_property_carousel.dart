// lib/features/home/presentation/widgets/sections/dna_helix/dna_helix_property_carousel.dart

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

class DnaHelixPropertyCarousel extends StatefulWidget {
  final List<dynamic> items; // Can be SectionPropertyItemModel or SectionUnitItemModel  
  final Function(String)? onItemTap;
  final bool isUnitView;

  const DnaHelixPropertyCarousel({
    super.key,
    required this.items,
    this.onItemTap,
    this.isUnitView = false,
  });

  @override
  State<DnaHelixPropertyCarousel> createState() =>
      _DnaHelixPropertyCarouselState();
}

class _DnaHelixPropertyCarouselState extends State<DnaHelixPropertyCarousel>
    with TickerProviderStateMixin {
  // DNA Animation Controllers
  late AnimationController _helixRotationController;
  late AnimationController _nucleotideController;
  late AnimationController _phosphateController;
  late AnimationController _hydrogenBondController;
  late AnimationController _mutationController;
  late AnimationController _replicationController;

  // Genetic sequences
  final List<_GeneticSequence> _sequences = [];
  final List<_Nucleotide> _nucleotides = [];
  final List<_PhosphateBond> _phosphateBonds = [];
  final List<_HydrogenBond> _hydrogenBonds = [];

  // DNA states
  final double _helixTwist = 0;
  double _currentStrand = 0;
  int _selectedGene = -1;
  bool _isReplicating = false;

  // Scroll controller for helix
  late PageController _helixPageController;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _initializeDNASystem();
    _generateGeneticStructure();
    _startDNAAnimation();
  }

  void _initializeDNASystem() {
    _helixPageController = PageController(
      viewportFraction: 0.4,
      initialPage: widget.items.length *
          1000, // Start in middle for infinite scroll
    );

    _helixRotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _nucleotideController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _phosphateController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _hydrogenBondController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _mutationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _replicationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  void _generateGeneticStructure() {
    // Generate DNA base pairs
    final bases = ['A', 'T', 'G', 'C'];
    for (int i = 0; i < widget.items.length * 2; i++) {
      _nucleotides.add(_Nucleotide(
        base: bases[math.Random().nextInt(4)],
        position: i.toDouble(),
      ));
    }

    // Generate phosphate backbone
    for (int i = 0; i < widget.items.length * 3; i++) {
      _phosphateBonds.add(_PhosphateBond(
        position: i.toDouble(),
      ));
    }

    // Generate hydrogen bonds
    for (int i = 0; i < widget.items.length; i++) {
      _hydrogenBonds.add(_HydrogenBond(
        strength: math.Random().nextDouble(),
      ));
    }

    // Generate genetic sequences
    for (var rawItem in widget.items) {
      final item = rawItem is SectionPropertyItemModel 
          ? SectionDisplayItem.fromProperty(rawItem)
          : SectionDisplayItem.fromUnit(rawItem as SectionUnitItemModel);
      _sequences.add(_GeneticSequence(
        propertyId: item.id,
        dnaCode: _generateDNACode(),
      ));
    }
  }

  String _generateDNACode() {
    const bases = 'ATGC';
    return List.generate(12, (i) => bases[math.Random().nextInt(4)]).join();
  }

  void _startDNAAnimation() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !_isReplicating) {
        _mutateGene();
      }
    });
  }

  void _mutateGene() {
    setState(() {
      _selectedGene = math.Random().nextInt(widget.items.length);
    });
    _mutationController.forward().then((_) {
      _mutationController.reset();
    });
    HapticFeedback.lightImpact();
  }

  void _startReplication() {
    setState(() {
      _isReplicating = true;
    });
    _replicationController.forward().then((_) {
      _replicationController.reset();
      setState(() {
        _isReplicating = false;
      });
    });
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _helixPageController.dispose();
    _helixRotationController.dispose();
    _nucleotideController.dispose();
    _phosphateController.dispose();
    _hydrogenBondController.dispose();
    _mutationController.dispose();
    _replicationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 600,
      child: Stack(
        children: [
          // DNA Background Structure
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _helixRotationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _DNAHelixBackgroundPainter(
                    rotation: _helixRotationController.value * 2 * math.pi,
                    nucleotides: _nucleotides,
                    phosphateBonds: _phosphateBonds,
                    hydrogenBonds: _hydrogenBonds,
                    bondStrength: _hydrogenBondController.value,
                  ),
                );
              },
            ),
          ),

          // Genetic Sequence Display
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: _buildGeneticSequenceDisplay(),
          ),

          // Main DNA Helix Carousel
          Positioned.fill(
            top: 100,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _helixRotationController,
                _nucleotideController,
              ]),
              builder: (context, child) {
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(_helixRotationController.value * 0.5),
                  child: PageView.builder(
                    controller: _helixPageController,
                    scrollDirection: Axis.vertical,
                    onPageChanged: (index) {
                      setState(() {
                        _currentStrand = index.toDouble();
                      });
                    },
                    itemBuilder: (context, index) {
                      final propertyIndex = index % widget.items.length;
                      final rawItem = widget.items[propertyIndex];
                      final item = rawItem is SectionPropertyItemModel 
                          ? SectionDisplayItem.fromProperty(rawItem)
                          : SectionDisplayItem.fromUnit(rawItem as SectionUnitItemModel);
                      return _DNAStrandCard(
                        item: item,
                        index: propertyIndex,
                        helixPosition: _calculateHelixPosition(index),
                        isSelected: _selectedGene == propertyIndex,
                        isReplicating: _isReplicating,
                        nucleotideAnimation: _nucleotideController.value,
                        onTap: () => _handlePropertyTap(item),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Phosphate Backbone Overlay
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _phosphateController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _PhosphateBackbonePainter(
                      animation: _phosphateController.value,
                      isReplicating: _isReplicating,
                    ),
                  );
                },
              ),
            ),
          ),

          // Mutation Effect
          if (_selectedGene >= 0)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _mutationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _MutationEffectPainter(
                        mutationProgress: _mutationController.value,
                        geneIndex: _selectedGene,
                      ),
                    );
                  },
                ),
              ),
            ),

          // DNA Controls
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: _buildDNAControls(),
          ),
        ],
      ),
    );
  }

  double _calculateHelixPosition(int index) {
    final normalizedIndex = index % widget.items.length;
    return normalizedIndex * (2 * math.pi / widget.items.length);
  }

  Widget _buildGeneticSequenceDisplay() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _nucleotideController,
        builder: (context, child) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _sequences.length,
            itemBuilder: (context, index) {
              final sequence = _sequences[index];
              final isActive = _selectedGene == index;

              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: isActive
                      ? LinearGradient(colors: [
                          AppTheme.neonGreen.withOpacity(0.3),
                          AppTheme.neonBlue.withOpacity(0.2),
                        ])
                      : null,
                  color: !isActive ? AppTheme.darkCard.withOpacity(0.3) : null,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? AppTheme.neonGreen.withOpacity(0.5)
                        : AppTheme.darkBorder.withOpacity(0.2),
                    width: isActive ? 1.5 : 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'GENE ${index + 1}',
                      style: AppTextStyles.caption.copyWith(
                        color:
                            isActive ? AppTheme.neonGreen : AppTheme.textMuted,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sequence.dnaCode,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: isActive ? Colors.white : AppTheme.textLight,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDNAControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Replicate button
        GestureDetector(
          onTap: _startReplication,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppTheme.neonGreen,
                AppTheme.neonBlue,
              ]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonGreen.withOpacity(0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.content_copy, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'REPLICATE DNA',
                  style: AppTextStyles.buttonSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 20),

        // Mutate button
        GestureDetector(
          onTap: _mutateGene,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppTheme.warning,
                AppTheme.error,
              ]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.warning.withOpacity(0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.flash_on, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'MUTATE',
                  style: AppTextStyles.buttonSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handlePropertyTap(SectionDisplayItem item) {
    HapticFeedback.heavyImpact();
    _startReplication();
    widget.onItemTap?.call(item.id);
  }
}

// DNA Strand Card
class _DNAStrandCard extends StatefulWidget {
  final SectionDisplayItem item;
  final int index;
  final double helixPosition;
  final bool isSelected;
  final bool isReplicating;
  final double nucleotideAnimation;
  final VoidCallback onTap;

  const _DNAStrandCard({
    required this.item,
    required this.index,
    required this.helixPosition,
    required this.isSelected,
    required this.isReplicating,
    required this.nucleotideAnimation,
    required this.onTap,
  });

  @override
  State<_DNAStrandCard> createState() => _DNAStrandCardState();
}

class _DNAStrandCardState extends State<_DNAStrandCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final xOffset = math.sin(widget.helixPosition) * 120;
    final zOffset = math.cos(widget.helixPosition) * 50;
    final scale = 0.8 + (math.cos(widget.helixPosition) + 1) * 0.1;

    return GestureDetector(
      onTap: widget.onTap,
      child: Transform(
        transform: Matrix4.identity()
          ..translate(xOffset, 0.0, zOffset)
          ..scale(scale),
        alignment: Alignment.center,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 200,
              height: 120,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.isSelected
                        ? AppTheme.neonGreen.withOpacity(0.5)
                        : AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: widget.isSelected ? 30 : 20,
                    spreadRadius: widget.isSelected ? 5 : 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Property image with DNA filter
                    _buildDNAFilteredImage(),

                    // Nucleotide overlay
                    _buildNucleotideOverlay(),

                    // Content
                    _buildCardContent(),

                    // Replication effect
                    if (widget.isReplicating) _buildReplicationEffect(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDNAFilteredImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Hero(
          tag: 'dna_${widget.item.id}_${widget.index}',
          child: CachedImageWidget(
            imageUrl: widget.item.imageUrl ?? '',
            fit: BoxFit.cover,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryBlue.withOpacity(0.2),
                AppTheme.darkBackground.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNucleotideOverlay() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return CustomPaint(
          painter: _NucleotideOverlayPainter(
            nucleotideAnimation: widget.nucleotideAnimation,
            pulseAnimation: _pulseController.value,
            isSelected: widget.isSelected,
          ),
        );
      },
    );
  }

  Widget _buildCardContent() {
    return Positioned(
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
            // DNA indicator
            Row(
              children: [
                Container(
                  width: 4,
                  height: 12,
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.neonGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  width: 4,
                  height: 12,
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.neonBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  width: 4,
                  height: 12,
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.warning,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  width: 4,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.error,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'DNA STRAND ${widget.index + 1}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                    fontSize: 8,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Property name
            Text(
              widget.item.name,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // Price with genetic marker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [AppTheme.neonGreen, AppTheme.neonBlue],
                  ).createShader(bounds),
                  child: Text(
                    '${widget.item.price.toStringAsFixed(0)} ريال',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Genetic compatibility
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.neonGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '98% MATCH',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.neonGreen,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplicationEffect() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.neonGreen,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

// DNA Models and Painters
class _GeneticSequence {
  final String propertyId;
  final String dnaCode;

  _GeneticSequence({
    required this.propertyId,
    required this.dnaCode,
  });
}

class _Nucleotide {
  final String base;
  final double position;
  Color get color {
    switch (base) {
      case 'A':
        return AppTheme.neonGreen;
      case 'T':
        return AppTheme.neonBlue;
      case 'G':
        return AppTheme.warning;
      case 'C':
        return AppTheme.error;
      default:
        return Colors.white;
    }
  }

  _Nucleotide({required this.base, required this.position});
}

class _PhosphateBond {
  final double position;

  _PhosphateBond({required this.position});
}

class _HydrogenBond {
  final double strength;

  _HydrogenBond({required this.strength});
}

class _DNAHelixBackgroundPainter extends CustomPainter {
  final double rotation;
  final List<_Nucleotide> nucleotides;
  final List<_PhosphateBond> phosphateBonds;
  final List<_HydrogenBond> hydrogenBonds;
  final double bondStrength;

  _DNAHelixBackgroundPainter({
    required this.rotation,
    required this.nucleotides,
    required this.phosphateBonds,
    required this.hydrogenBonds,
    required this.bondStrength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw double helix structure
    for (int i = 0; i < 50; i++) {
      final y = size.height * i / 50;
      final angle1 = rotation + (i * 0.2);
      final angle2 = angle1 + math.pi;

      final x1 = centerX + math.sin(angle1) * 100;
      final x2 = centerX + math.sin(angle2) * 100;

      // Draw phosphate backbone
      final backbonePaint = Paint()
        ..color = AppTheme.primaryBlue.withOpacity(0.1)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      if (i > 0) {
        final prevY = size.height * (i - 1) / 50;
        final prevAngle1 = rotation + ((i - 1) * 0.2);
        final prevAngle2 = prevAngle1 + math.pi;
        final prevX1 = centerX + math.sin(prevAngle1) * 100;
        final prevX2 = centerX + math.sin(prevAngle2) * 100;

        canvas.drawLine(
          Offset(prevX1, prevY),
          Offset(x1, y),
          backbonePaint,
        );

        canvas.drawLine(
          Offset(prevX2, prevY),
          Offset(x2, y),
          backbonePaint,
        );
      }

      // Draw hydrogen bonds between strands
      if (i % 3 == 0) {
        final bondPaint = Paint()
          ..color = AppTheme.neonGreen.withOpacity(0.1 * bondStrength)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

        // Draw dashed line for hydrogen bond
        const dashWidth = 5.0;
        const dashSpace = 5.0;
        final distance = x2 - x1;
        final dashCount = (distance / (dashWidth + dashSpace)).floor();

        for (int j = 0; j < dashCount; j++) {
          final startX = x1 + (j * (dashWidth + dashSpace));
          final endX = startX + dashWidth;

          if (endX <= x2) {
            canvas.drawLine(
              Offset(startX, y),
              Offset(endX, y),
              bondPaint,
            );
          }
        }
      }

      // Draw nucleotides
      if (i % 3 == 0 && i / 3 < nucleotides.length) {
        final nucleotide = nucleotides[(i ~/ 3)];
        final nucleotidePaint = Paint()
          ..color = nucleotide.color.withOpacity(0.5)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(x1, y), 4, nucleotidePaint);
        canvas.drawCircle(Offset(x2, y), 4, nucleotidePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PhosphateBackbonePainter extends CustomPainter {
  final double animation;
  final bool isReplicating;

  _PhosphateBackbonePainter({
    required this.animation,
    required this.isReplicating,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isReplicating) return;

    // Draw replication fork
    final centerX = size.width / 2;
    final forkY = size.height * animation;

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppTheme.neonGreen.withOpacity(0.3),
          AppTheme.neonBlue.withOpacity(0.1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw Y-shaped replication fork
    final path = Path();
    path.moveTo(centerX - 50, forkY - 50);
    path.lineTo(centerX, forkY);
    path.lineTo(centerX + 50, forkY - 50);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MutationEffectPainter extends CustomPainter {
  final double mutationProgress;
  final int geneIndex;

  _MutationEffectPainter({
    required this.mutationProgress,
    required this.geneIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2 + (geneIndex * 50);

    // Draw radiation burst effect
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.warning.withOpacity(0.5 * mutationProgress),
          AppTheme.error.withOpacity(0.3 * mutationProgress),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(centerX, centerY),
        radius: 100 * mutationProgress,
      ))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(centerX, centerY),
      100 * mutationProgress,
      paint,
    );

    // Draw mutation rays
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) + (mutationProgress * math.pi);
      final endX = centerX + math.cos(angle) * 150 * mutationProgress;
      final endY = centerY + math.sin(angle) * 150 * mutationProgress;

      final rayPaint = Paint()
        ..color = AppTheme.warning.withOpacity(0.4 * (1 - mutationProgress))
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(centerX, centerY),
        Offset(endX, endY),
        rayPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _NucleotideOverlayPainter extends CustomPainter {
  final double nucleotideAnimation;
  final double pulseAnimation;
  final bool isSelected;

  _NucleotideOverlayPainter({
    required this.nucleotideAnimation,
    required this.pulseAnimation,
    required this.isSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isSelected) return;

    // Draw base pair connections
    final paint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 4; i++) {
      final y = size.height * (i + 1) / 5;

      paint.color = [
        AppTheme.neonGreen,
        AppTheme.neonBlue,
        AppTheme.warning,
        AppTheme.error,
      ][i]
          .withOpacity(0.3 + pulseAnimation * 0.3);

      // Draw base pair line
      canvas.drawLine(
        Offset(10, y),
        Offset(size.width - 10, y),
        paint,
      );

      // Draw nucleotide circles
      canvas.drawCircle(
        Offset(10 + nucleotideAnimation * (size.width - 20), y),
        3,
        Paint()
          ..color = paint.color
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
