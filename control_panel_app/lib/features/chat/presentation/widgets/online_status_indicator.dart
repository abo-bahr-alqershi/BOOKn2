import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class OnlineStatusIndicator extends StatefulWidget {
  final bool isOnline;
  final double size;
  final bool showBorder;
  final bool animate;

  const OnlineStatusIndicator({
    super.key,
    required this.isOnline,
    this.size = 10, // Reduced from 12
    this.showBorder = true,
    this.animate = true,
  });

  @override
  State<OnlineStatusIndicator> createState() => _OnlineStatusIndicatorState();
}

class _OnlineStatusIndicatorState extends State<OnlineStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    if (widget.isOnline && widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(OnlineStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOnline != oldWidget.isOnline) {
      if (widget.isOnline && widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulse effect for online status
            if (widget.isOnline && widget.animate)
              Container(
                width: widget.size + 6 * _pulseAnimation.value,
                height: widget.size + 6 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.3 * (1 - _pulseAnimation.value),
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            
            // Main indicator
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                gradient: widget.isOnline
                    ? LinearGradient(
                        colors: [AppTheme.success, AppTheme.neonGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: !widget.isOnline 
                    ? AppTheme.textMuted.withValues(alpha: 0.3)
                    : null,
                shape: BoxShape.circle,
                border: widget.showBorder
                    ? Border.all(
                        color: Theme.of(context).cardColor,
                        width: 1.5,
                      )
                    : null,
                boxShadow: widget.isOnline
                    ? [
                        BoxShadow(
                          color: AppTheme.success.withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }
}