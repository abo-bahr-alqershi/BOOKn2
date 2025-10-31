import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';
import '../theme/app_dimensions.dart';

class LoadingWidget extends StatelessWidget {
  final LoadingType type;
  final double? size;
  final Color? color;
  final String? message;
  final EdgeInsets? padding;
  final String? svgAsset;

  const LoadingWidget({
    super.key,
    this.type = LoadingType.circular,
    this.size,
    this.color,
    this.message,
    this.padding,
    this.svgAsset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? AppTheme.primaryBlue;
    final effectiveSize = size ?? 40.0;
    final effectiveSvgAsset = svgAsset ?? 'assets/images/progress.svg';

    Widget loadingIndicator;

    switch (type) {
      case LoadingType.circular:
        loadingIndicator = _FuturisticLoading(
          color: effectiveColor,
          height: (effectiveSize * 5).clamp(200.0, 300.0),
          innerSize: (effectiveSize * 3.5).clamp(140.0, 200.0),
          svgAsset: effectiveSvgAsset,
        );
        break;
      case LoadingType.linear:
        loadingIndicator = _buildLinearLoader(effectiveColor);
        break;
      case LoadingType.shimmer:
        loadingIndicator = _buildShimmerLoader();
        break;
      case LoadingType.pulse:
        loadingIndicator = _buildPulseLoader(effectiveColor, effectiveSize);
        break;
      case LoadingType.dots:
        loadingIndicator = _buildDotsLoader(effectiveColor);
        break;
      case LoadingType.futuristic:
        loadingIndicator = _FuturisticLoading(
          color: effectiveColor,
          height: (effectiveSize * 5).clamp(200.0, 300.0),
          innerSize: (effectiveSize * 3.5).clamp(140.0, 200.0),
          svgAsset: effectiveSvgAsset,
        );
        break;
    }

    if (message != null) {
      loadingIndicator = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loadingIndicator,
          const SizedBox(height: AppDimensions.spaceMedium),
          Text(
            message!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Center(child: loadingIndicator),
    );
  }

  Widget _buildLinearLoader(Color color) {
    return SizedBox(
      width: double.infinity,
      child: LinearProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(color),
        backgroundColor: color.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: AppTheme.shimmer,
      highlightColor: AppTheme.shimmer.withValues(alpha: 0.5),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.borderMedium),
        ),
      ),
    );
  }

  Widget _buildPulseLoader(Color color, double size) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.2),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: size * 0.6,
                height: size * 0.6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
      onEnd: () {},
    );
  }

  Widget _buildDotsLoader(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 600 + (index * 200)),
          builder: (context, value, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color.withValues(alpha: value),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

enum LoadingType {
  circular,
  linear,
  shimmer,
  pulse,
  dots,
  futuristic,
}

class _FuturisticLoading extends StatefulWidget {
  final Color color;
  final double height;
  final double innerSize;
  final String svgAsset;

  const _FuturisticLoading({
    required this.color,
    required this.height,
    required this.innerSize,
    required this.svgAsset,
  });

  @override
  State<_FuturisticLoading> createState() => _FuturisticLoadingState();
}

class _FuturisticLoadingState extends State<_FuturisticLoading>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.height,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _controller,
          _rotationController,
          _scaleAnimation,
        ]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // رسم الموجات الخارجية
              CustomPaint(
                painter: _RipplePainter(
                  animationValue: _controller.value,
                  color: AppTheme.primaryBlue,
                ),
                child: const SizedBox.expand(),
              ),


              // الدائرة الخارجية الثابتة
              Container(
                width: widget.innerSize,
                height: widget.innerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryBlue.withOpacity(0.3),
                      AppTheme.primaryBlue.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Center(
                  child: SizedBox(
                    width: widget.innerSize * 0.82,
                    height: widget.innerSize * 0.82,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                    ),
                  ),
                ),
              ),

              // الدائرة المتحركة
              const SizedBox.shrink(),

              // حاوي الصورة SVG (بدون دوران أو نبض)
              Container(
                width: widget.innerSize * 0.56,
                height: widget.innerSize * 0.56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    widget.svgAsset,
                    width: widget.innerSize * 0.38,
                    height: widget.innerSize * 0.38,
                    fit: BoxFit.contain,
                    allowDrawingOutsideViewBox: true,
                  ),
                ),
              ),


            ],
          );
        },
      ),
    );
  }
}

// رسام الدائرة المتحركة
class _CircularProgressPainter extends CustomPainter {
  final Color color;
  final double progress;

  _CircularProgressPainter({
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 6) / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // رسم القوس الأول مع تدرج
    final gradient1 = SweepGradient(
      colors: [
        Colors.transparent,
        color.withValues(alpha: 0.3),
        color,
        color,
        color.withValues(alpha: 0.3),
        Colors.transparent,
      ],
      stops: const [0.0, 0.1, 0.3, 0.7, 0.9, 1.0],
      startAngle: 0,
      endAngle: 2 * 3.14159,
    );

    paint.shader = gradient1.createShader(rect);

    const startAngle = -3.14159 / 2;
    final sweepAngle = 3.14159 * progress * 1.5;

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      paint,
    );

    // رسم القوس الثاني المعاكس
    final paint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.3);

    canvas.drawArc(
      rect,
      startAngle + 3.14159,
      sweepAngle * 0.6,
      false,
      paint2,
    );

    // نقاط مضيئة في نهاية الأقواس
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // حساب موقع النقطة الأولى
    final angle1 = startAngle + sweepAngle;
    final x1 = center.dx + radius * math.cos(angle1);
    final y1 = center.dy + radius * math.sin(angle1);
    canvas.drawCircle(Offset(x1, y1), 3.5, dotPaint);

    // إضافة توهج للنقطة
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(x1, y1), 6, glowPaint);

    // حساب موقع النقطة الثانية
    final angle2 = startAngle + 3.14159 + (sweepAngle * 0.6);
    final x2 = center.dx + radius * math.cos(angle2);
    final y2 = center.dy + radius * math.sin(angle2);
    canvas.drawCircle(
        Offset(x2, y2), 2.5, dotPaint..color = color.withValues(alpha: 0.7));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// رسام الموجات
class _RipplePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _RipplePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);

    // رسم 3 موجات كما في واجهة الرئيسية
    for (int i = 0; i < 3; i++) {
      final radius = 50.0 + (i * 30) + (animationValue * 20);
      final opacity = (1.0 - animationValue) * 0.3;

      paint.color = color.withValues(alpha: opacity);

      canvas.drawCircle(center, radius, paint);
    }

  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
