import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/glassmorphic_tooltip.dart';

class AmenityStatsCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Gradient gradient;
  final String? subtitle;
  final double? percentage;
  final String? detailedDescription;
  final Map<String, dynamic>? additionalStats;

  const AmenityStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    this.subtitle,
    this.percentage,
    this.detailedDescription,
    this.additionalStats,
  });

  @override
  State<AmenityStatsCard> createState() => _AmenityStatsCardState();
}

class _AmenityStatsCardState extends State<AmenityStatsCard>
    with SingleTickerProviderStateMixin {
  final GlobalKey _cardKey = GlobalKey();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleLongPress() {
    setState(() => _isPressed = true);

    Color color = widget.gradient.colors.first;
    String message = '📊 القيمة الحالية: ${widget.value}\n\n';
    message += widget.detailedDescription ?? 'معلومات تفصيلية عن المرافق';

    if (widget.additionalStats != null && widget.additionalStats!.isNotEmpty) {
      message += '\n\n📈 تفاصيل إضافية:';
      widget.additionalStats!.forEach((key, value) {
        message += '\n• $key: $value';
      });
    }

    GlasmorphicTooltip.show(
      context: context,
      targetKey: _cardKey,
      title: widget.title,
      message: message,
      accentColor: color,
      icon: widget.icon,
      duration: const Duration(seconds: 5),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _isPressed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _cardKey,
      onLongPress: _handleLongPress,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(_isHovered ? -0.05 : 0)
            ..rotateY(_isHovered ? 0.05 : 0)
            ..scale(_isHovered ? 1.02 : 1.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkCard.withOpacity(0.8),
                AppTheme.darkCard.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isPressed
                  ? widget.gradient.colors.first.withOpacity(0.7)
                  : _isHovered
                      ? widget.gradient.colors.first.withOpacity(0.5)
                      : AppTheme.darkBorder.withOpacity(0.3),
              width: _isPressed ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? widget.gradient.colors.first.withOpacity(0.3)
                    : Colors.black.withOpacity(0.2),
                blurRadius: _isHovered ? 25 : 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Stack(
                children: [
                  // Background Pattern
                  if (_isHovered)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _PatternPainter(
                          color: widget.gradient.colors.first.withOpacity(0.05),
                        ),
                      ),
                    ),

                  // Floating Icon Background
                  Positioned(
                    top: -20,
                    right: -20,
                    child: AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationAnimation.value,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: widget.gradient.scale(0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: widget.gradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: widget.gradient.colors.first
                                    .withOpacity(0.4),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),

                        const SizedBox(height: AppDimensions.paddingMedium),

                        // Title
                        Text(
                          widget.title,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),

                        // Value with Info Icon
                        Row(
                          children: [
                            Expanded(
                              child: AnimatedBuilder(
                                animation: _scaleAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _isHovered
                                        ? _scaleAnimation.value
                                        : 1.0,
                                    child: ShaderMask(
                                      shaderCallback: (bounds) =>
                                          widget.gradient.createShader(bounds),
                                      child: Text(
                                        widget.value,
                                        style: AppTextStyles.heading1.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Icon(
                              Icons.info_outline_rounded,
                              color: AppTheme.textMuted.withValues(alpha: 0.5),
                              size: 14,
                            ),
                          ],
                        ),

                        // Subtitle or Percentage
                        if (widget.subtitle != null ||
                            widget.percentage != null)
                          Row(
                            children: [
                              if (widget.subtitle != null)
                                Text(
                                  widget.subtitle!,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.textMuted.withOpacity(0.7),
                                  ),
                                ),
                              if (widget.percentage != null) ...[
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.percentage! > 0
                                        ? AppTheme.success.withOpacity(0.2)
                                        : AppTheme.error.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        widget.percentage! > 0
                                            ? Icons.trending_up_rounded
                                            : Icons.trending_down_rounded,
                                        size: 12,
                                        color: widget.percentage! > 0
                                            ? AppTheme.success
                                            : AppTheme.error,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${widget.percentage!.abs().toStringAsFixed(1)}%',
                                        style: AppTextStyles.caption.copyWith(
                                          color: widget.percentage! > 0
                                              ? AppTheme.success
                                              : AppTheme.error,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final Color color;

  _PatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const spacing = 20.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height / 3, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
