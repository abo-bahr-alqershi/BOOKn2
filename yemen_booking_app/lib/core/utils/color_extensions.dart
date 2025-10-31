import 'package:flutter/material.dart';

extension ColorExtensions on Color {
  Color withValues({double? alpha, double? red, double? green, double? blue}) {
    final double baseA = (alpha ?? a).clamp(0.0, 1.0);
    final double baseR = (red ?? r).clamp(0.0, 1.0);
    final double baseG = (green ?? g).clamp(0.0, 1.0);
    final double baseB = (blue ?? b).clamp(0.0, 1.0);

    final int ai = (baseA * 255.0).round().clamp(0, 255);
    final int ri = (baseR * 255.0).round().clamp(0, 255);
    final int gi = (baseG * 255.0).round().clamp(0, 255);
    final int bi = (baseB * 255.0).round().clamp(0, 255);

    return Color.fromARGB(ai, ri, gi, bi);
  }

  Color withAlphaFraction(double alpha) => withValues(alpha: alpha);
}