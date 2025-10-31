import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class GuestSelectorWidget extends StatefulWidget {
  final String label;
  final String? subtitle;
  final int count;
  final int minCount;
  final int maxCount;
  final Function(int) onChanged;
  final bool enabled;

  const GuestSelectorWidget({
    super.key,
    required this.label,
    this.subtitle,
    required this.count,
    required this.minCount,
    required this.maxCount,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<GuestSelectorWidget> createState() => _GuestSelectorWidgetState();
}

class _GuestSelectorWidgetState extends State<GuestSelectorWidget>
    with TickerProviderStateMixin {
  late AnimationController _increaseController;
  late AnimationController _decreaseController;
  late AnimationController _numberController;
  late Animation<double> _numberScaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _increaseController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _decreaseController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _numberController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _numberScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _numberController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _increaseController.dispose();
    _decreaseController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  void _onIncrease() {
    if (widget.enabled && widget.count < widget.maxCount) {
      HapticFeedback.selectionClick();
      _increaseController.forward().then((_) {
        _increaseController.reverse();
      });
      _numberController.forward().then((_) {
        _numberController.reverse();
      });
      widget.onChanged(widget.count + 1);
    }
  }

  void _onDecrease() {
    if (widget.enabled && widget.count > widget.minCount) {
      HapticFeedback.selectionClick();
      _decreaseController.forward().then((_) {
        _decreaseController.reverse();
      });
      _numberController.forward().then((_) {
        _numberController.reverse();
      });
      widget.onChanged(widget.count - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textWhite.withOpacity(0.9),
                ),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 1),
                Text(
                  widget.subtitle!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted.withOpacity(0.6),
                    fontSize: 9,
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.darkCard.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCompactButton(
                    icon: Icons.remove_rounded,
                    onPressed: widget.enabled && widget.count > widget.minCount
                        ? _onDecrease
                        : null,
                    animationController: _decreaseController,
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: AnimatedBuilder(
                      animation: _numberScaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _numberScaleAnimation.value,
                          child: Text(
                            widget.count.toString(),
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryBlue.withOpacity(0.9),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                  _buildCompactButton(
                    icon: Icons.add_rounded,
                    onPressed: widget.enabled && widget.count < widget.maxCount
                        ? _onIncrease
                        : null,
                    animationController: _increaseController,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactButton({
    required IconData icon,
    VoidCallback? onPressed,
    required AnimationController animationController,
  }) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final scale = 1.0 + (animationController.value * 0.1);
        
        return Transform.scale(
          scale: scale,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: onPressed != null
                      ? LinearGradient(
                          colors: [
                            AppTheme.primaryBlue.withOpacity(0.1),
                            AppTheme.primaryPurple.withOpacity(0.05),
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: onPressed != null
                      ? AppTheme.primaryBlue.withOpacity(0.8)
                      : AppTheme.darkBorder.withOpacity(0.3),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}