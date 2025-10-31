// أضف هذا الويدجيت المساعد في ملف utils
import 'package:flutter/material.dart';

class AdaptiveTextContainer extends StatelessWidget {
  final Widget child;
  final bool addBackground;
  
  const AdaptiveTextContainer({
    Key? key,
    required this.child,
    this.addBackground = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (!isDarkMode && addBackground) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        child: child,
      );
    }
    
    return child;
  }
}