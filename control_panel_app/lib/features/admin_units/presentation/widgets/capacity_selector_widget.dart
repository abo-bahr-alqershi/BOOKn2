// lib/features/admin_units/presentation/widgets/capacity_selector_widget.dart

import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';
import '../../domain/entities/unit_type.dart';

class CapacitySelectorWidget extends StatefulWidget {
  final UnitType unitType;
  final Function(int?, int?) onCapacityChanged;
  final int? initialAdults;
  final int? initialChildren;

  const CapacitySelectorWidget({
    super.key,
    required this.unitType,
    required this.onCapacityChanged,
    this.initialAdults,
    this.initialChildren,
  });

  @override
  State<CapacitySelectorWidget> createState() => _CapacitySelectorWidgetState();
}

class _CapacitySelectorWidgetState extends State<CapacitySelectorWidget>
    with SingleTickerProviderStateMixin {
  int? _adults;
  int? _children;
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _adults = widget.initialAdults ?? 2;
    _children = widget.initialChildren ?? 0;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.unitType.isHasAdults && !widget.unitType.isHasChildren) {
      return const SizedBox.shrink();
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryBlue.withOpacity(0.1),
              AppTheme.primaryPurple.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryBlue.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.group_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'السعة الاستيعابية',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      if (widget.unitType.isHasAdults)
                        Expanded(
                          child: _buildCapacityField(
                            label: 'البالغين',
                            icon: Icons.person_rounded,
                            value: _adults ?? 0,
                            onChanged: (value) {
                              setState(() => _adults = value);
                              widget.onCapacityChanged(_adults, _children);
                            },
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      if (widget.unitType.isHasAdults && widget.unitType.isHasChildren)
                        const SizedBox(width: 16),
                      if (widget.unitType.isHasChildren)
                        Expanded(
                          child: _buildCapacityField(
                            label: 'الأطفال',
                            icon: Icons.child_care_rounded,
                            value: _children ?? 0,
                            onChanged: (value) {
                              setState(() => _children = value);
                              widget.onCapacityChanged(_adults, _children);
                            },
                            color: AppTheme.primaryPurple,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCapacityField({
    required String label,
    required IconData icon,
    required int value,
    required Function(int) onChanged,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildCounterButton(
                icon: Icons.remove,
                onTap: () {
                  if (value > 0) {
                    onChanged(value - 1);
                  }
                },
                isEnabled: value > 0,
              ),
              Expanded(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      value.toString(),
                      key: ValueKey(value),
                      style: AppTextStyles.heading2.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              _buildCounterButton(
                icon: Icons.add,
                onTap: () {
                  onChanged(value + 1);
                },
                isEnabled: true,
                isPrimary: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isEnabled,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: isEnabled
          ? () {
              HapticFeedback.lightImpact();
              onTap();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: isPrimary && isEnabled
              ? AppTheme.primaryGradient
              : null,
          color: !isPrimary
              ? (isEnabled
                  ? AppTheme.darkCard.withOpacity(0.5)
                  : AppTheme.darkCard.withOpacity(0.2))
              : null,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isEnabled
                ? (isPrimary
                    ? AppTheme.primaryBlue.withOpacity(0.5)
                    : AppTheme.darkBorder.withOpacity(0.3))
                : AppTheme.darkBorder.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isEnabled
              ? (isPrimary ? Colors.white : AppTheme.textMuted)
              : AppTheme.textMuted.withOpacity(0.3),
        ),
      ),
    );
  }
}