// // lib/core/theme/app_theme.dart

// import 'package:flutter/material.dart';

// /// 🎨 Unified Theme System - نظام ثيم موحد
// class AppTheme {
//   AppTheme._();

//   // Current theme mode
//   static ThemeMode _themeMode = ThemeMode.system;
//   static ThemeMode get themeMode => _themeMode;

//   // Track current brightness
//   static Brightness _brightness = Brightness.dark;
//   static Brightness get brightness => _brightness;

//   // Initialize theme based on system or manual setting
//   static void init(BuildContext context, {ThemeMode? mode}) {
//     _themeMode = mode ?? ThemeMode.system;
//     final systemBrightness = MediaQuery.of(context).platformBrightness;

//     if (_themeMode == ThemeMode.system) {
//       _brightness = systemBrightness;
//     } else if (_themeMode == ThemeMode.light) {
//       _brightness = Brightness.light;
//     } else {
//       _brightness = Brightness.dark;
//     }
//   }

//   // Helper method to check if dark mode
//   static bool get isDark => _brightness == Brightness.dark;

//   // 🎨 Primary Gradient Colors
//   static Color get primaryBlue => isDark ? const Color(0xFF4FACFE) : const Color(0xFF0066CC);
//   static Color get primaryPurple => isDark ? const Color(0xFF667EEA) : const Color(0xFF6366F1);
//   static Color get primaryViolet => isDark ? const Color(0xFF764BA2) : const Color(0xFF8B5CF6);
//   static Color get primaryCyan => isDark ? const Color(0xFF00F2FE) : const Color(0xFF0891B2);

//   // 🌟 Neon & Glow Colors
//   static Color get neonBlue => isDark ? const Color(0xFF00D4FF) : const Color(0xFF0EA5E9);
//   static Color get neonPurple => isDark ? const Color(0xFF9D50FF) : const Color(0xFFA855F7);
//   static Color get neonGreen => isDark ? const Color(0xFF00FF88) : const Color(0xFF10B981);
//   static Color get glowBlue => isDark ? const Color(0xFF4FACFE) : const Color(0xFF3B82F6);
//   static Color get glowWhite => isDark ? const Color(0xFFFFFFFF) : const Color(0xFFFAFAFA);

//   // 🌙 Base Colors
//   static Color get darkBackground => isDark ? const Color(0xFF0A0E27) : const Color(0xFFFAFAFA);
//   static Color get darkBackground2 => isDark ? const Color(0xFF0F1629) : const Color(0xFFFAFAFA);
//   static Color get darkBackground3 => isDark ? const Color(0xFF1A0E3D) : const Color(0xFFFAFAFA);

//   // static Color get darkBackground => isDark ? const Color(0xFF0A0E27) : const Color(0xFFFAFBFF);
//   // static Color get darkBackground2 => isDark ? const Color(0xFF0D1332) : const Color(0xFFF5F7FE);
//   // static Color get darkBackground3 => isDark ? const Color(0xFF11183F) : const Color(0xFFF0F3FD);

//   // static Color get darkBackground => isDark ? const Color(0xFF0A0E27) : const Color(0xFFF0F4FF);
//   // static Color get darkBackground2 => isDark ? const Color(0xFF1A1547) : const Color(0xFFE8EFFF);
//   // static Color get darkBackground3 => isDark ? const Color(0xFF2D1B69) : const Color(0xFFE0E8FF);

//   static Color get darkSurface => isDark ? const Color(0xFF151930) : const Color(0xFFFFFFFF);
//   static Color get darkCard => isDark ? const Color(0xFF1E2341) : const Color(0xFFFFFFFF);
//   static Color get darkBorder => isDark ? const Color(0xFF2A3050) : const Color(0xFFE5E5E5);

//   // ☀️ Light Theme Base Colors
//   static Color get lightBackground => isDark ? const Color(0xFFF8FAFF) : const Color(0xFFF9FAFB);
//   static Color get lightSurface => isDark ? const Color(0xFFFFFFFF) : const Color(0xFFFFFFFF);
//   static Color get lightCard => isDark ? const Color(0xFFFFFFFF) : const Color(0xFFFFFFFF);
//   static Color get lightBorder => isDark ? const Color(0xFFE8ECFA) : const Color(0xFFE5E7EB);

//   // 📝 Text Colors
//   static Color get textWhite => isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111827);
//   static Color get textLight => isDark ? const Color(0xFFB8C4E6) : const Color(0xFF374151);
//   static Color get textMuted => isDark ? const Color(0xFF8B95B7) : const Color(0xFF6B7280);
//   static Color get textDark => isDark ? const Color(0xFF1A1F36) : const Color(0xFF030712);

//   // ✨ Glass & Blur Effects
//   static Color get glassDark => isDark ? const Color(0x1A000000) : const Color(0x08000000);
//   static Color get glassLight => isDark ? const Color(0x0DFFFFFF) : const Color(0x0F0066CC);
//   static Color get glassOverlay => isDark ? const Color(0x80151930) : const Color(0x66FFFFFF);
//   static Color get frostedGlass => isDark ? const Color(0x30FFFFFF) : const Color(0x99F9FAFB);

//   // 🚦 Status Colors
//   static Color get success => isDark ? const Color(0xFF00FF88) : const Color(0xFF059669);
//   static Color get warning => isDark ? const Color(0xFFFFB800) : const Color(0xFFF59E0B);
//   static Color get error => isDark ? const Color(0xFFFF3366) : const Color(0xFFDC2626);
//   static Color get info => isDark ? const Color(0xFF00D4FF) : const Color(0xFF0284C7);

//   // 🎭 Shadows & Overlays
//   static Color get shadowDark => isDark ? const Color(0x40000000) : const Color(0x0A000000);
//   static Color get shadowLight => isDark ? const Color(0x1A4FACFE) : const Color(0x050066CC);
//   static Color get overlayDark => isDark ? const Color(0xCC0A0E27) : const Color(0x0A111827);
//   static Color get overlayLight => isDark ? const Color(0x99FFFFFF) : const Color(0xE6FFFFFF);

//   // 🌈 Gradient Definitions
//   static LinearGradient get primaryGradient => LinearGradient(
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//     colors: [primaryCyan, primaryBlue, primaryPurple, primaryViolet],
//     stops: const [0.0, 0.3, 0.6, 1.0],
//   );

//   static LinearGradient get darkGradient => isDark
//     ? const LinearGradient(
//         begin: Alignment.topCenter,
//         end: Alignment.bottomCenter,
//         colors: [Color(0xFF1A1F36), Color(0xFF0F1629)],
//       )
//     : const LinearGradient(
//         begin: Alignment.topCenter,
//         end: Alignment.bottomCenter,
//         colors: [Color(0xFFF9FAFB), Color(0xFFFAFAFA)],
//       );

//   static LinearGradient get cardGradient => isDark
//     ? const LinearGradient(
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//         colors: [
//           Color(0x1A4FACFE),
//           Color(0x0D667EEA),
//           Color(0x1A764BA2),
//         ],
//       )
//     : const LinearGradient(
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//         colors: [
//           Color(0x050066CC),
//           Color(0x036366F1),
//           Color(0x058B5CF6),
//         ],
//       );

//   static LinearGradient get neonGradient => LinearGradient(
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//     colors: [neonBlue, neonPurple, neonGreen],
//   );

//   static LinearGradient get glassGradient => isDark
//     ? const LinearGradient(
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//         colors: [
//           Color(0x40FFFFFF),
//           Color(0x1AFFFFFF),
//           Color(0x40FFFFFF),
//         ],
//       )
//     : const LinearGradient(
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//         colors: [
//           Color(0x0DFFFFFF),
//           Color(0x08FFFFFF),
//           Color(0x0DFFFFFF),
//         ],
//       );

//   static RadialGradient get glowGradient => isDark
//     ? const RadialGradient(
//         colors: [
//           Color(0x804FACFE),
//           Color(0x404FACFE),
//           Color(0x004FACFE),
//         ],
//       )
//     : const RadialGradient(
//         colors: [
//           Color(0x1A0066CC),
//           Color(0x0D0066CC),
//           Color(0x000066CC),
//         ],
//       );

//   // 🎯 Component Specific Colors
//   static Color get buttonPrimary => primaryBlue;
//   static Color get buttonSecondary => primaryPurple;
//   static Color get inputBackground => isDark ? const Color(0x0D4FACFE) : const Color(0xFFD1D5DB);
//   static Color get inputBorder => isDark ? const Color(0x334FACFE) : const Color(0xFFD1D5DB);
//   static Color get inputFocusBorder => primaryBlue;

//   // 💎 Special Effects
//   static Color get shimmerBase => primaryBlue.withValues(alpha: isDark ? 0.05 : 0.03);
//   static Color get shimmerHighlight => primaryBlue.withValues(alpha: isDark ? 0.2 : 0.08);
//   static Color get holographic => primaryPurple.withValues(alpha: isDark ? 0.3 : 0.1);

//   // 🔲 Booking Status
//   static Color get bookingPending => isDark ? const Color(0xFFFFB800) : const Color(0xFFF59E0B);
//   static Color get bookingConfirmed => isDark ? const Color(0xFF00FF88) : const Color(0xFF059669);
//   static Color get bookingCancelled => isDark ? const Color(0xFFFF3366) : const Color(0xFFDC2626);
//   static Color get bookingCompleted => isDark ? const Color(0xFF00D4FF) : const Color(0xFF0284C7);

//   // 🔁 Backward-compatible aliases
//   static Color get shadow => shadowDark;
//   static Color get primaryDark => isDark ? const Color(0xFF0F1629) : const Color(0xFF003D7A);
//   static const Color transparent = Colors.transparent;
//   static Color get gray200 => lightBorder;
//   static Color get textDisabled => textMuted;
//   static Color get shimmer => isDark ? const Color(0xFF2A3050) : const Color(0xFFF3F4F6);
// }
// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';

/// 🎨 Unified Theme System - نظام ثيم موحد
class AppTheme {
  AppTheme._();

  // Current theme mode
  static ThemeMode _themeMode = ThemeMode.system;
  static ThemeMode get themeMode => _themeMode;

  // Track current brightness
  static Brightness _brightness = Brightness.dark;
  static Brightness get brightness => _brightness;

  // Initialize theme based on system or manual setting
  static void init(BuildContext context, {ThemeMode? mode}) {
    _themeMode = mode ?? ThemeMode.system;
    final systemBrightness = MediaQuery.of(context).platformBrightness;

    if (_themeMode == ThemeMode.system) {
      _brightness = systemBrightness;
    } else if (_themeMode == ThemeMode.light) {
      _brightness = Brightness.light;
    } else {
      _brightness = Brightness.dark;
    }
  }

  // Helper method to check if dark mode
  static bool get isDark => _brightness == Brightness.dark;

  // 🎨 Primary Gradient Colors - مستوحاة من الشعار
  static Color get primaryBlue =>
      isDark ? const Color(0xFF5B8DEE) : const Color(0xFF3260CC);
  static Color get primaryPurple =>
      isDark ? const Color(0xFF7C6FD8) : const Color(0xFF5E52B8);
  static Color get primaryViolet =>
      isDark ? const Color(0xFF9D7FE8) : const Color(0xFF7B5FCF);
  static Color get primaryCyan =>
      isDark ? const Color(0xFF4A9FFF) : const Color(0xFF2E7DD4);

  // 🌟 Neon & Glow Colors - تأثيرات التوهج من الشعار
  static Color get neonBlue =>
      isDark ? const Color(0xFF6BB6FF) : const Color(0xFF4A9FFF);
  static Color get neonPurple =>
      isDark ? const Color(0xFFA78BFA) : const Color(0xFF8B6FE3);
  static Color get neonGreen =>
      isDark ? const Color(0xFF5EEAD4) : const Color(0xFF14B8A6);
  static Color get glowBlue =>
      isDark ? const Color(0xFF5B8DEE) : const Color(0xFF4A7FDB);
  static Color get glowWhite =>
      isDark ? const Color(0xFFF0F5FF) : const Color(0xFFFFFFFF);

  // 🌙 Base Colors - خلفيات مستوحاة من الشعار
  static Color get darkBackground =>
      isDark ? const Color(0xFF0B1929) : const Color(0xFFF7FAFF);
  static Color get darkBackground2 =>
      isDark ? const Color(0xFF0E1E33) : const Color(0xFFF0F5FF);
  static Color get darkBackground3 =>
      isDark ? const Color(0xFF112240) : const Color(0xFFE8F0FF);

  static Color get darkSurface =>
      isDark ? const Color(0xFF152642) : const Color(0xFFFFFFFF);
  static Color get darkCard =>
      isDark ? const Color(0xFF1A2F4E) : const Color(0xFFFFFFFF);
  static Color get darkBorder =>
      isDark ? const Color(0xFF253859) : const Color(0xFFD4E0F5);

  // ☀️ Light Theme Base Colors
  static Color get lightBackground =>
      isDark ? const Color(0xFFF7FAFF) : const Color(0xFFF9FBFF);
  static Color get lightSurface =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFFFFFFFF);
  static Color get lightCard =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFFFFFFFF);
  static Color get lightBorder =>
      isDark ? const Color(0xFFE2ECFF) : const Color(0xFFD9E3F5);

  // 📝 Text Colors - ألوان نصوص متناسقة
  static Color get textWhiteAlways =>
      isDark ? const Color(0xFFF0F5FF) : const Color(0xFFF0F5FF);
  static Color get textWhite =>
      isDark ? const Color(0xFFF0F5FF) : const Color(0xFF0F172A);
  static Color get textLight =>
      isDark ? const Color(0xFFB4C6E0) : const Color(0xFF334155);
  static Color get textMuted =>
      isDark ? const Color(0xFF8094B3) : const Color(0xFF64748B);
  static Color get textDark =>
      isDark ? const Color(0xFF1E293B) : const Color(0xFF020617);

  // ✨ Glass & Blur Effects - تأثيرات زجاجية فخمة
  static Color get glassDark =>
      isDark ? const Color(0x1A0B1929) : const Color(0x08000000);
  static Color get glassLight =>
      isDark ? const Color(0x0DF0F5FF) : const Color(0x0F3260CC);
  static Color get glassOverlay =>
      isDark ? const Color(0x80152642) : const Color(0x66FFFFFF);
  static Color get frostedGlass =>
      isDark ? const Color(0x30F0F5FF) : const Color(0x99F9FBFF);

  // 🚦 Status Colors - ألوان الحالات بتناسق مع الثيم
  static Color get success =>
      isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
  static Color get warning =>
      isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
  static Color get error =>
      isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
  static Color get info =>
      isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);

  // 🎭 Shadows & Overlays - ظلال ناعمة وراقية
  static Color get shadowDark =>
      isDark ? const Color(0x40000000) : const Color(0x0A000000);
  static Color get shadowLight =>
      isDark ? const Color(0x1A5B8DEE) : const Color(0x053260CC);
  static Color get overlayDark =>
      isDark ? const Color(0xCC0B1929) : const Color(0x0A0F172A);
  static Color get overlayLight =>
      isDark ? const Color(0x99F0F5FF) : const Color(0xE6FFFFFF);

  // 🌈 Gradient Definitions - تدرجات مستوحاة من الشعار
  static LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                const Color(0xFF4A9FFF), // أزرق فاتح
                const Color(0xFF5B8DEE), // أزرق متوسط
                const Color(0xFF7C6FD8), // بنفسجي متوسط
                const Color(0xFF9D7FE8), // بنفسجي فاتح
              ]
            : [
                const Color(0xFF2E7DD4),
                const Color(0xFF3260CC),
                const Color(0xFF5E52B8),
                const Color(0xFF7B5FCF),
              ],
        stops: const [0.0, 0.35, 0.65, 1.0],
      );

  static LinearGradient get darkGradient => isDark
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0B1929), // أزرق غامق جداً
            Color(0xFF0E1E33), // أزرق غامق
            Color(0xFF112240), // أزرق متوسط غامق
          ],
          stops: [0.0, 0.5, 1.0],
        )
      : const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF7FAFF),
            Color(0xFFF0F5FF),
            Color(0xFFE8F0FF),
          ],
          stops: [0.0, 0.5, 1.0],
        );

  static LinearGradient get cardGradient => isDark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x1A5B8DEE), // أزرق شفاف
            Color(0x0D7C6FD8), // بنفسجي شفاف
            Color(0x1A9D7FE8), // بنفسجي فاتح شفاف
          ],
          stops: [0.0, 0.5, 1.0],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x053260CC),
            Color(0x035E52B8),
            Color(0x057B5FCF),
          ],
          stops: [0.0, 0.5, 1.0],
        );

  static LinearGradient get neonGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                const Color(0xFF6BB6FF), // أزرق نيون
                const Color(0xFFA78BFA), // بنفسجي نيون
                const Color(0xFF5EEAD4), // أخضر مائي نيون
              ]
            : [
                const Color(0xFF4A9FFF),
                const Color(0xFF8B6FE3),
                const Color(0xFF14B8A6),
              ],
      );

  static LinearGradient get glassGradient => isDark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x40F0F5FF), // أبيض شفاف
            Color(0x1AF0F5FF),
            Color(0x40F0F5FF),
          ],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x0DFFFFFF),
            Color(0x08FFFFFF),
            Color(0x0DFFFFFF),
          ],
        );

  static RadialGradient get glowGradient => isDark
      ? const RadialGradient(
          colors: [
            Color(0x805B8DEE), // مركز التوهج
            Color(0x405B8DEE), // وسط التوهج
            Color(0x005B8DEE), // حافة التوهج
          ],
        )
      : const RadialGradient(
          colors: [
            Color(0x1A3260CC),
            Color(0x0D3260CC),
            Color(0x003260CC),
          ],
        );

  // 🎯 Component Specific Colors
  static Color get buttonPrimary => primaryBlue;
  static Color get buttonSecondary => primaryPurple;
  static Color get inputBackground =>
      isDark ? const Color(0x0D5B8DEE) : const Color(0xFFE8F0FF);
  static Color get inputBorder =>
      isDark ? const Color(0x335B8DEE) : const Color(0xFFD4E0F5);
  static Color get inputFocusBorder => primaryBlue;

  // 💎 Special Effects - تأثيرات خاصة فخمة
  static Color get shimmerBase =>
      primaryBlue.withValues(alpha: isDark ? 0.08 : 0.04);
  static Color get shimmerHighlight =>
      primaryBlue.withValues(alpha: isDark ? 0.25 : 0.10);
  static Color get holographic =>
      primaryPurple.withValues(alpha: isDark ? 0.35 : 0.12);

  // 🔲 Booking Status - ألوان حالات الحجز المتناسقة
  static Color get bookingPending =>
      isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
  static Color get bookingConfirmed =>
      isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
  static Color get bookingCancelled =>
      isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
  static Color get bookingCompleted =>
      isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);

  // 🔁 Backward-compatible aliases
  static Color get shadow => shadowDark;
  static Color get primaryDark =>
      isDark ? const Color(0xFF0E1E33) : const Color(0xFF1E3A8A);
  static const Color transparent = Colors.transparent;
  static Color get gray200 => lightBorder;
  static Color get textDisabled => textMuted;
  static Color get shimmer =>
      isDark ? const Color(0xFF253859) : const Color(0xFFF3F6FB);
}
