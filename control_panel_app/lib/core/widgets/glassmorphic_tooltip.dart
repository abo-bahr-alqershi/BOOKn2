import 'dart:ui';
import 'package:flutter/material.dart';

/// Glassmorphic Tooltip Widget
/// عرض tooltip زجاجي أنيق مع blur effect
class GlasmorphicTooltip {
  static OverlayEntry? _overlayEntry;
  static bool _isVisible = false;

  /// إظهار Tooltip
  static void show({
    required BuildContext context,
    required GlobalKey targetKey,
    required String title,
    required String message,
    required Color accentColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    bool dismissOnTap = true,
  }) {
    if (_isVisible) return;

    final RenderBox? renderBox =
        targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;

    _overlayEntry = OverlayEntry(
      builder: (context) => _GlasmorphicTooltipContent(
        targetOffset: offset,
        targetSize: size,
        screenSize: screenSize,
        title: title,
        message: message,
        accentColor: accentColor,
        icon: icon,
        onDismiss: () => hide(),
        dismissOnTap: dismissOnTap,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isVisible = true;

    // Auto dismiss
    Future.delayed(duration, () {
      hide();
    });
  }

  /// إخفاء Tooltip
  static void hide() {
    if (!_isVisible) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isVisible = false;
  }
}

class _GlasmorphicTooltipContent extends StatefulWidget {
  final Offset targetOffset;
  final Size targetSize;
  final Size screenSize;
  final String title;
  final String message;
  final Color accentColor;
  final IconData? icon;
  final VoidCallback onDismiss;
  final bool dismissOnTap;

  const _GlasmorphicTooltipContent({
    required this.targetOffset,
    required this.targetSize,
    required this.screenSize,
    required this.title,
    required this.message,
    required this.accentColor,
    this.icon,
    required this.onDismiss,
    required this.dismissOnTap,
  });

  @override
  State<_GlasmorphicTooltipContent> createState() =>
      _GlasmorphicTooltipContentState();
}

class _GlasmorphicTooltipContentState
    extends State<_GlasmorphicTooltipContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    // حساب الموقع الأمثل للـ tooltip
    final tooltipWidth = widget.screenSize.width * 0.85;
    final tooltipMaxWidth = 320.0;
    final actualTooltipWidth =
        tooltipWidth > tooltipMaxWidth ? tooltipMaxWidth : tooltipWidth;

    // Center horizontally relative to target
    final centerX = widget.targetOffset.dx + widget.targetSize.width / 2;
    var tooltipLeft = centerX - actualTooltipWidth / 2;

    // Keep tooltip within screen bounds
    if (tooltipLeft < 16) tooltipLeft = 16;
    if (tooltipLeft + actualTooltipWidth > widget.screenSize.width - 16) {
      tooltipLeft = widget.screenSize.width - actualTooltipWidth - 16;
    }

    // Position below the target
    final tooltipTop = widget.targetOffset.dy + widget.targetSize.height + 12;

    return GestureDetector(
      onTap: widget.dismissOnTap ? _dismiss : null,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Background overlay
            Positioned.fill(
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ),
            ),

            // Tooltip
            Positioned(
              left: tooltipLeft,
              top: tooltipTop,
              child: ScaleTransition(
                scale: _scaleAnimation,
                alignment: Alignment.topCenter,
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: Container(
                    width: actualTooltipWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: widget.accentColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                widget.accentColor.withValues(alpha: 0.2),
                                widget.accentColor.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: widget.accentColor.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Row(
                                  children: [
                                    if (widget.icon != null) ...[
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              widget.accentColor,
                                              widget.accentColor
                                                  .withValues(alpha: 0.7),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: widget.accentColor
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          widget.icon,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                    Expanded(
                                      child: Text(
                                        widget.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.white70,
                                        size: 22,
                                      ),
                                      onPressed: _dismiss,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Divider
                                Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withValues(alpha: 0.3),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Message
                                Text(
                                  widget.message,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 14,
                                    height: 1.5,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Arrow indicator (optional)
            Positioned(
              left: widget.targetOffset.dx + widget.targetSize.width / 2 - 8,
              top: tooltipTop - 8,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: CustomPaint(
                  size: const Size(16, 8),
                  painter: _ArrowPainter(color: widget.accentColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;

  _ArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
