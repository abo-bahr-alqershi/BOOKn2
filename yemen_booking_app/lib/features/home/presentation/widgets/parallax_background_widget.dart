// lib/features/home/presentation/widgets/animations/parallax_background_widget.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';

class ParallaxBackgroundWidget extends StatefulWidget {
  final Widget child;
  final double scrollOffset;

  const ParallaxBackgroundWidget({
    super.key,
    required this.child,
    required this.scrollOffset,
  });

  @override
  State<ParallaxBackgroundWidget> createState() =>
      _ParallaxBackgroundWidgetState();
}

class _ParallaxBackgroundWidgetState extends State<ParallaxBackgroundWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  final List<_ParallaxLayer> _layers = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _generateLayers();
  }

  void _generateLayers() {
    for (int i = 0; i < 3; i++) {
      _layers.add(_ParallaxLayer(
        speed: 0.1 + (i * 0.1),
        opacity: 0.1 + (i * 0.05),
      ));
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Parallax layers
        ...List.generate(_layers.length, (index) {
          final layer = _layers[index];
          return Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ParallaxPainter(
                    scrollOffset: widget.scrollOffset * layer.speed,
                    animationValue: _animationController.value,
                    opacity: layer.opacity,
                  ),
                );
              },
            ),
          );
        }),

        // Main content
        widget.child,
      ],
    );
  }
}

class _ParallaxLayer {
  final double speed;
  final double opacity;

  _ParallaxLayer({
    required this.speed,
    required this.opacity,
  });
}

class _ParallaxPainter extends CustomPainter {
  final double scrollOffset;
  final double animationValue;
  final double opacity;

  _ParallaxPainter({
    required this.scrollOffset,
    required this.animationValue,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw geometric shapes
    for (int i = 0; i < 5; i++) {
      final x = (size.width * 0.2 * i) + (scrollOffset % size.width);
      final y =
          math.sin(animationValue * 2 * math.pi + i) * 50 + size.height * 0.5;

      paint.shader = RadialGradient(
        colors: [
          AppTheme.primaryBlue.withOpacity(opacity),
          AppTheme.primaryPurple.withOpacity(opacity * 0.5),
        ],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 100));

      canvas.drawCircle(Offset(x, y), 100, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
