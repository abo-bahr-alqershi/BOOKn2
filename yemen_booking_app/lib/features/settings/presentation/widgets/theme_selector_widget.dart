import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';

class FuturisticThemeToggle extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool)? onChanged;

  const FuturisticThemeToggle({
    super.key,
    required this.isDarkMode,
    this.onChanged,
  });

  @override
  State<FuturisticThemeToggle> createState() => _FuturisticThemeToggleState();
}

class _FuturisticThemeToggleState extends State<FuturisticThemeToggle>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _switchController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _switchAnimation;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    _switchController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
      value: widget.isDarkMode ? 1.0 : 0.0,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotationController);
    
    _switchAnimation = CurvedAnimation(
      parent: _switchController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(FuturisticThemeToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      if (widget.isDarkMode) {
        _switchController.forward();
      } else {
        _switchController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _switchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleThemeChange(!widget.isDarkMode),
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationAnimation, _switchAnimation]),
        builder: (context, child) {
          return Container(
            width: 60,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.isDarkMode
                    ? [
                        const Color(0xFF1A1B3A),
                        const Color(0xFF2D2F5F),
                      ]
                    : [
                        const Color(0xFFFFD700),
                        const Color(0xFFFFA500),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isDarkMode
                    ? AppTheme.primaryBlue.withOpacity(0.3)
                    : Colors.orange.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isDarkMode
                      ? AppTheme.primaryBlue.withOpacity(0.3)
                      : Colors.orange.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Stars/Sun rays
                if (widget.isDarkMode)
                  ...List.generate(3, (index) {
                    return Positioned(
                      left: 8 + (index * 12),
                      top: 8 + (index * 4),
                      child: Icon(
                        Icons.star,
                        size: 4 + (index * 2),
                        color: Colors.white.withOpacity(0.6),
                      ),
                    );
                  })
                else
                  Center(
                    child: Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: Icon(
                        Icons.wb_sunny,
                        size: 20,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
                
                // Switch button
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: widget.isDarkMode ? 32 : 4,
                  top: 4,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: widget.isDarkMode
                            ? [
                                const Color(0xFF4A5568),
                                const Color(0xFF2D3748),
                              ]
                            : [
                                const Color(0xFFFFF9C4),
                                const Color(0xFFFFEB3B),
                              ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.isDarkMode
                              ? Colors.black.withOpacity(0.3)
                              : Colors.orange.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        widget.isDarkMode
                            ? Icons.nightlight_round
                            : Icons.wb_sunny,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleThemeChange(bool isDark) {
    if (widget.onChanged != null) {
      widget.onChanged!(isDark);
    } else {
      context.read<SettingsBloc>().add(UpdateThemeEvent(isDark));
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppTheme.primaryBlue, AppTheme.primaryPurple]
                        : [Colors.orange, Colors.yellow],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDark ? Icons.nightlight_round : Icons.wb_sunny,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isDark ? 'تم تفعيل الوضع الليلي' : 'تم تفعيل الوضع النهاري',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: AppTheme.darkCard.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(20),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// Advanced Theme Selector with Preview
class FuturisticThemeSelector extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool)? onChanged;

  const FuturisticThemeSelector({
    super.key,
    required this.isDarkMode,
    this.onChanged,
  });

  @override
  State<FuturisticThemeSelector> createState() => _FuturisticThemeSelectorState();
}

class _FuturisticThemeSelectorState extends State<FuturisticThemeSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.6),
            AppTheme.darkCard.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildThemeOption(
            icon: Icons.wb_sunny,
            label: 'نهاري',
            isSelected: !widget.isDarkMode,
            gradient: const LinearGradient(
              colors: [Colors.orange, Colors.yellow],
            ),
            onTap: () => _handleThemeChange(false),
          ),
          const SizedBox(width: 8),
          _buildThemeOption(
            icon: Icons.nightlight_round,
            label: 'ليلي',
            isSelected: widget.isDarkMode,
            gradient: LinearGradient(
              colors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
            ),
            onTap: () => _handleThemeChange(true),
          ),
        ],
      ),
    );
  }
  
  Widget _buildThemeOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isSelected ? _scaleAnimation.value : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                gradient: isSelected ? gradient : null,
                color: !isSelected
                    ? AppTheme.darkCard.withOpacity(0.3)
                    : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: gradient.colors[0].withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? Colors.white
                        : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textMuted,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  void _handleThemeChange(bool isDark) {
    if (widget.onChanged != null) {
      widget.onChanged!(isDark);
    } else {
      context.read<SettingsBloc>().add(UpdateThemeEvent(isDark));
    }
  }
}