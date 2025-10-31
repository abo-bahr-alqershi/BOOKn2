import 'package:flutter/material.dart';
import 'package:yemen_booking_app/core/theme/app_theme.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();
  
  // 🚀 Display Styles (للعناوين الكبيرة)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -1.5,
    fontFamily: 'SF Pro Display',
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -1.0,
    fontFamily: 'SF Pro Display',
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.5,
    fontFamily: 'SF Pro Display',
  );
  
  // 📝 Heading Styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.3,
    fontFamily: 'SF Pro Display',
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
    fontFamily: 'SF Pro Display',
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: 0,
    fontFamily: 'SF Pro Text',
  );
  
  // 📖 Body Styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.15,
    fontFamily: 'SF Pro Text',
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    letterSpacing: 0.1,
    fontFamily: 'SF Pro Text',
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.1,
    fontFamily: 'SF Pro Text',
  );
  
  // 🔘 Button & Label Styles
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: 0.5,
    fontFamily: 'SF Pro Text',
  );
  
  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: 0.4,
    fontFamily: 'SF Pro Text',
  );
  
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: 0.3,
    fontFamily: 'SF Pro Text',
  );
  
  // 🏷️ Caption & Helper Styles
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.35,
    letterSpacing: 0.2,
    fontFamily: 'SF Pro Text',
  );
  
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 1.0,
    fontFamily: 'SF Pro Text',
  );
  
  // ⭐ Rating text style used in rating badges
  static const TextStyle rating = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.3,
    fontFamily: 'SF Pro Text',
  );
  
  // ✨ Special Gradient Text Style Helper
  static TextStyle gradientText({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: 1.2,
      fontFamily: 'SF Pro Display',
      foreground: Paint()
        ..shader = AppTheme.primaryGradient.createShader(
          const Rect.fromLTWH(0, 0, 200, 70),
        ),
    );
  }
  
  // 💫 Neon Text Style Helper
  static TextStyle neonText({
    required double fontSize,
    Color? color,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    final Color resolvedColor = color ?? AppTheme.neonBlue;
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: resolvedColor,
      fontFamily: 'SF Pro Display',
      shadows: [
        Shadow(
          color: resolvedColor.withOpacity(0.8),
          blurRadius: 10,
        ),
        Shadow(
          color: resolvedColor.withOpacity(0.6),
          blurRadius: 20,
        ),
        Shadow(
          color: resolvedColor.withOpacity(0.4),
          blurRadius: 30,
        ),
      ],
    );
  }
  
  // 🌟 Glass Text Style Helper
  static TextStyle glassText({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: AppTheme.textWhite.withOpacity(0.9),
      fontFamily: 'SF Pro Display',
      shadows: const [
        Shadow(
          color: Colors.black26,
          offset: Offset(0, 2),
          blurRadius: 4,
        ),
      ],
    );
  }
}