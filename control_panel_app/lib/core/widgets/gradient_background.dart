// lib/core/widgets/gradient_background.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 🎨 Gradient Background Widget
class GradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final AlignmentGeometry? begin;
  final AlignmentGeometry? end;

  const GradientBackground({
    super.key,
    required this.child,
    this.colors,
    this.begin,
    this.end,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin ?? Alignment.topLeft,
          end: end ?? Alignment.bottomRight,
          colors: colors ??
              [
                AppColors.background,
                AppColors.background.withOpacity(0.95),
              ],
        ),
      ),
      child: child,
    );
  }
}
