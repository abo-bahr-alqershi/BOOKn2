import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_dimensions.dart';
import '../../domain/entities/unit.dart';

class FuturisticUnitMapView extends StatefulWidget {
  final List<Unit> units;
  final Function(Unit) onUnitSelected;

  const FuturisticUnitMapView({
    super.key,
    required this.units,
    required this.onUnitSelected,
  });

  @override
  State<FuturisticUnitMapView> createState() => _FuturisticUnitMapViewState();
}

class _FuturisticUnitMapViewState extends State<FuturisticUnitMapView>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  Unit? _selectedUnit;
  Offset _mapOffset = Offset.zero;
  double _mapScale = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotationController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.3),
            AppTheme.darkCard.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
        child: Stack(
          children: [
            _buildMapBackground(),
            _buildMapContent(),
            _buildMapControls(),
            if (_selectedUnit != null)
              _buildUnitDetails(_selectedUnit!),
          ],
        ),
      ),
    );
  }

  Widget _buildMapBackground() {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: AppTheme.darkGradient,
          ),
          child: CustomPaint(
            painter: _MapBackgroundPainter(
              rotation: _rotationAnimation.value,
              scale: _mapScale,
              offset: _mapOffset,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildMapContent() {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _mapOffset += details.delta;
        });
      },
      onScaleUpdate: (details) {
        setState(() {
          _mapScale = (_mapScale * details.scale).clamp(0.5, 3.0);
        });
      },
      child: Container(
        color: Colors.transparent,
        child: Transform(
          transform: Matrix4.identity()
            ..translate(_mapOffset.dx, _mapOffset.dy)
            ..scale(_mapScale),
          child: Stack(
            children: widget.units.map((unit) {
              final position = _getUnitPosition(unit);
              return Positioned(
                left: position.dx,
                top: position.dy,
                child: _buildUnitMarker(unit),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildUnitMarker(Unit unit) {
    final isSelected = _selectedUnit?.id == unit.id;
    
    return GestureDetector(
      onTap: () {
        setState(() => _selectedUnit = unit);
        widget.onUnitSelected(unit);
      },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final scale = isSelected ? _pulseAnimation.value : 1.0;
          
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? AppTheme.primaryGradient
                    : LinearGradient(
                        colors: unit.isAvailable
                            ? [AppTheme.success, AppTheme.success.withOpacity(0.8)]
                            : [AppTheme.error, AppTheme.error.withOpacity(0.8)],
                      ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppTheme.primaryBlue.withOpacity(0.5)
                        : unit.isAvailable
                            ? AppTheme.success.withOpacity(0.3)
                            : AppTheme.error.withOpacity(0.3),
                    blurRadius: isSelected ? 20 : 10,
                    spreadRadius: isSelected ? 3 : 1,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.home,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      top: AppDimensions.paddingLarge,
      right: AppDimensions.paddingLarge,
      child: Column(
        children: [
          _buildControlButton(
            Icons.add,
            () => setState(() => _mapScale = (_mapScale * 1.2).clamp(0.5, 3.0)),
          ),
          const SizedBox(height: AppDimensions.spaceSmall),
          _buildControlButton(
            Icons.remove,
            () => setState(() => _mapScale = (_mapScale / 1.2).clamp(0.5, 3.0)),
          ),
          const SizedBox(height: AppDimensions.spaceSmall),
          _buildControlButton(
            Icons.my_location,
            () => setState(() {
              _mapOffset = Offset.zero;
              _mapScale = 1.0;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withOpacity(0.8),
              AppTheme.darkCard.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          border: Border.all(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildUnitDetails(Unit unit) {
    return Positioned(
      bottom: AppDimensions.paddingLarge,
      left: AppDimensions.paddingLarge,
      right: AppDimensions.paddingLarge,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.glassLight.withOpacity(0.1),
                  AppTheme.glassDark.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      child: const Icon(
                        Icons.home,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unit.name,
                            style: AppTextStyles.heading3.copyWith(
                              color: AppTheme.textWhite,
                            ),
                          ),
                          Text(
                            unit.propertyName,
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingSmall,
                        vertical: AppDimensions.paddingXSmall,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: unit.isAvailable
                              ? [AppTheme.success, AppTheme.success.withOpacity(0.8)]
                              : [AppTheme.error, AppTheme.error.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      ),
                      child: Text(
                        unit.isAvailable ? 'متاحة' : 'غير متاحة',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceMedium),
                Row(
                  children: [
                    _buildDetailItem(
                      Icons.attach_money,
                      unit.basePrice.displayAmount,
                      AppTheme.success,
                    ),
                    const SizedBox(width: AppDimensions.spaceMedium),
                    _buildDetailItem(
                      Icons.apartment,
                      unit.unitTypeName,
                      AppTheme.primaryBlue,
                    ),
                    if (unit.capacityDisplay.isNotEmpty) ...[
                      const SizedBox(width: AppDimensions.spaceMedium),
                      _buildDetailItem(
                        Icons.group,
                        unit.capacityDisplay,
                        AppTheme.primaryPurple,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppDimensions.spaceXSmall),
        Text(
          value,
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textLight,
          ),
        ),
      ],
    );
  }

  Offset _getUnitPosition(Unit unit) {
    // Generate pseudo-random positions based on unit ID
    final random = math.Random(unit.id.hashCode);
    final x = 100 + random.nextDouble() * 200;
    final y = 100 + random.nextDouble() * 300;
    return Offset(x, y);
  }
}

class _MapBackgroundPainter extends CustomPainter {
  final double rotation;
  final double scale;
  final Offset offset;

  _MapBackgroundPainter({
    required this.rotation,
    required this.scale,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = AppTheme.primaryBlue.withOpacity(0.05);

    // Draw grid
    const gridSize = 50.0;
    for (double x = -gridSize; x < size.width + gridSize; x += gridSize) {
      canvas.drawLine(
        Offset(x + offset.dx % gridSize, 0),
        Offset(x + offset.dx % gridSize, size.height),
        paint,
      );
    }
    for (double y = -gridSize; y < size.height + gridSize; y += gridSize) {
      canvas.drawLine(
        Offset(0, y + offset.dy % gridSize),
        Offset(size.width, y + offset.dy % gridSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}