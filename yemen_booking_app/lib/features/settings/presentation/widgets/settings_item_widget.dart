import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class FuturisticSettingsItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Gradient gradient;
  final bool isDestructive;
  final bool enabled;

  const FuturisticSettingsItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    required this.gradient,
    this.isDestructive = false,
    this.enabled = true,
  });

  @override
  State<FuturisticSettingsItem> createState() => _FuturisticSettingsItemState();
}

class _FuturisticSettingsItemState extends State<FuturisticSettingsItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: GestureDetector(
        onTapDown: (_) => _handleHover(true),
        onTapUp: (_) {
          _handleHover(false);
          if (widget.enabled && widget.onTap != null) {
            widget.onTap!();
          }
        },
        onTapCancel: () => _handleHover(false),
        child: AnimatedBuilder(
          animation: _hoverAnimation,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isHovered
                      ? [
                          widget.gradient.colors[0].withOpacity(0.15),
                          widget.gradient.colors[1].withOpacity(0.1),
                        ]
                      : [
                          AppTheme.darkCard.withOpacity(0.3),
                          AppTheme.darkCard.withOpacity(0.2),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isHovered
                      ? widget.gradient.colors[0].withOpacity(0.5)
                      : AppTheme.darkBorder.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                          color: widget.gradient.colors[0].withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: _isHovered ? 15 : 10,
                    sigmaY: _isHovered ? 15 : 10,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.enabled ? widget.onTap : null,
                      borderRadius: BorderRadius.circular(16),
                      splashColor: widget.gradient.colors[0].withOpacity(0.2),
                      highlightColor: widget.gradient.colors[1].withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Animated Icon Container
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: _isHovered
                                    ? widget.gradient
                                    : LinearGradient(
                                        colors: [
                                          widget.gradient.colors[0].withOpacity(0.3),
                                          widget.gradient.colors[1].withOpacity(0.2),
                                        ],
                                      ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: _isHovered
                                    ? [
                                        BoxShadow(
                                          color: widget.gradient.colors[0].withOpacity(0.4),
                                          blurRadius: 12,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Transform.scale(
                                scale: _isHovered ? 1.1 : 1.0,
                                child: Icon(
                                  widget.icon,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // Title and Subtitle
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.title,
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: widget.isDestructive
                                          ? AppTheme.error
                                          : AppTheme.textWhite,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (widget.subtitle != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.subtitle!,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppTheme.textMuted,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            
                            // Trailing Widget
                            if (widget.trailing != null)
                              widget.trailing!
                            else if (widget.onTap != null)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                transform: Matrix4.translationValues(
                                  _isHovered ? 5 : 0,
                                  0,
                                  0,
                                ),
                                child: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 18,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Futuristic Toggle Item
class FuturisticSettingsToggle extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Gradient gradient;
  final bool enabled;

  const FuturisticSettingsToggle({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    required this.gradient,
    this.enabled = true,
  });

  @override
  State<FuturisticSettingsToggle> createState() => _FuturisticSettingsToggleState();
}

class _FuturisticSettingsToggleState extends State<FuturisticSettingsToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _toggleController;
  late Animation<double> _toggleAnimation;

  @override
  void initState() {
    super.initState();
    _toggleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: widget.value ? 1.0 : 0.0,
    );
    _toggleAnimation = CurvedAnimation(
      parent: _toggleController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(FuturisticSettingsToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _toggleController.forward();
      } else {
        _toggleController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _toggleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FuturisticSettingsItem(
      icon: widget.icon,
      title: widget.title,
      subtitle: widget.subtitle,
      gradient: widget.gradient,
      enabled: widget.enabled,
      trailing: GestureDetector(
        onTap: widget.enabled
            ? () => widget.onChanged?.call(!widget.value)
            : null,
        child: AnimatedBuilder(
          animation: _toggleAnimation,
          builder: (context, child) {
            return Container(
              width: 56,
              height: 30,
              decoration: BoxDecoration(
                gradient: widget.value
                    ? widget.gradient
                    : LinearGradient(
                        colors: [
                          AppTheme.darkCard.withOpacity(0.5),
                          AppTheme.darkCard.withOpacity(0.3),
                        ],
                      ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: widget.value
                      ? Colors.transparent
                      : AppTheme.darkBorder.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: widget.value
                    ? [
                        BoxShadow(
                          color: widget.gradient.colors[0].withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: widget.value ? 28 : 2,
                    top: 2,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      onTap: widget.enabled
          ? () => widget.onChanged?.call(!widget.value)
          : null,
    );
  }
}