// lib/features/home/presentation/widgets/categories/property_type_card_widget.dart

import 'package:flutter/material.dart';
import 'package:yemen_booking_app/features/home/domain/entities/property_type.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_text_styles.dart';

class PropertyTypeCard extends StatefulWidget {
  final PropertyType propertyType;
  final bool isSelected;
  final VoidCallback onTap;
  final Duration animationDelay;

  const PropertyTypeCard({
    super.key,
    required this.propertyType,
    required this.isSelected,
    required this.onTap,
    this.animationDelay = Duration.zero,
  });

  @override
  State<PropertyTypeCard> createState() => _PropertyTypeCardState();
}

class _PropertyTypeCardState extends State<PropertyTypeCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _rotationController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotationAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startEntranceAnimation();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotationController);
  }

  void _startEntranceAnimation() {
    Future.delayed(widget.animationDelay, () {
      if (mounted) {
        if (widget.isSelected) {
          _glowController.repeat(reverse: true);
          _rotationController.repeat();
        }
      }
    });
  }

  @override
  void didUpdateWidget(PropertyTypeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _glowController.repeat(reverse: true);
        _rotationController.repeat();
      } else {
        _glowController.stop();
        _rotationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _onTapDown(),
      onTapUp: (_) => _onTapUp(),
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleAnimation,
          _glowAnimation,
          _rotationAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? _scaleAnimation.value : 1.0,
            child: Container(
              decoration: BoxDecoration(
                gradient: widget.isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryBlue.withOpacity(0.2),
                          AppTheme.primaryPurple.withOpacity(0.1),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          AppTheme.darkCard.withOpacity(0.8),
                          AppTheme.darkCard.withOpacity(0.6),
                        ],
                      ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isSelected
                      ? AppTheme.primaryBlue
                          .withOpacity(0.5 + _glowAnimation.value * 0.3)
                      : AppTheme.darkBorder.withOpacity(0.3),
                  width: widget.isSelected ? 2 : 1,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(
                            0.3 + _glowAnimation.value * 0.2,
                          ),
                          blurRadius: 20 + _glowAnimation.value * 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AppTheme.shadowDark.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Stack(
                    children: [
                      // Animated background pattern
                      if (widget.isSelected)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _GridPatternPainter(
                              rotation: _rotationAnimation.value,
                              color: AppTheme.primaryBlue.withOpacity(0.05),
                            ),
                          ),
                        ),

                      // Main content
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon container
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: widget.isSelected
                                    ? AppTheme.primaryGradient
                                    : LinearGradient(
                                        colors: [
                                          AppTheme.primaryBlue.withOpacity(0.3),
                                          AppTheme.primaryPurple
                                              .withOpacity(0.2),
                                        ],
                                      ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: widget.isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.primaryBlue
                                              .withOpacity(0.4),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Icon(
                                _getIconForType(widget.propertyType.name),
                                color: Colors.white,
                                size: 18,
                              ),
                            ),

                            const SizedBox(height: 3),

                            // Type name
                            Text(
                              widget.propertyType.name,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: widget.isSelected
                                    ? AppTheme.primaryBlue
                                    : AppTheme.textWhite,
                                fontWeight: FontWeight.w600,
                                height: 1.1,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 2),

                            // Count badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: widget.isSelected
                                    ? AppTheme.primaryBlue.withOpacity(0.2)
                                    : AppTheme.darkCard.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${widget.propertyType.propertiesCount}',
                                style: AppTextStyles.caption.copyWith(
                                  color: widget.isSelected
                                      ? AppTheme.primaryBlue
                                      : AppTheme.textMuted,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Selection indicator
                      if (widget.isSelected)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForType(String typeName) {
    // Map property type names to icons
    final typeIcons = {
      'شقة': Icons.apartment,
      'فيلا': Icons.villa,
      'مكتب': Icons.business,
      'محل': Icons.store,
      'أرض': Icons.landscape,
      'مزرعة': Icons.agriculture,
      'مستودع': Icons.warehouse,
      'فندق': Icons.hotel,
      'شاليه': Icons.house,
    };

    return typeIcons[typeName] ?? Icons.home;
  }

  void _onTapDown() {
    setState(() {
      _isPressed = true;
    });
    _scaleController.forward();
  }

  void _onTapUp() {
    setState(() {
      _isPressed = false;
    });
    _scaleController.reverse();
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _scaleController.reverse();
  }
}

// Grid Pattern Painter
class _GridPatternPainter extends CustomPainter {
  final double rotation;
  final Color color;

  _GridPatternPainter({
    required this.rotation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotation);
    canvas.translate(-size.width / 2, -size.height / 2);

    // Draw grid
    const spacing = 15.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
