import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

enum BadgeSize { small, medium, large }

class SectionStatusBadge extends StatelessWidget {
  final bool isActive;
  final BadgeSize size;

  const SectionStatusBadge({
    super.key,
    required this.isActive,
    this.size = BadgeSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _getPadding().horizontal,
        vertical: _getPadding().vertical,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [
                  AppTheme.success.withValues(alpha: 0.9),
                  AppTheme.success.withValues(alpha: 0.7),
                ]
              : [
                  AppTheme.textMuted.withValues(alpha: 0.7),
                  AppTheme.textMuted.withValues(alpha: 0.5),
                ],
        ),
        borderRadius: BorderRadius.circular(_getBorderRadius()),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? AppTheme.success.withValues(alpha: 0.3)
                : AppTheme.shadowDark.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _getDotSize(),
            height: _getDotSize(),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          SizedBox(width: _getSpacing()),
          Text(
            isActive ? 'نشط' : 'متوقف',
            style: _getTextStyle(),
          ),
        ],
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case BadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
      case BadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case BadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case BadgeSize.small:
        return 6;
      case BadgeSize.medium:
        return 8;
      case BadgeSize.large:
        return 10;
    }
  }

  double _getDotSize() {
    switch (size) {
      case BadgeSize.small:
        return 4;
      case BadgeSize.medium:
        return 5;
      case BadgeSize.large:
        return 6;
    }
  }

  double _getSpacing() {
    switch (size) {
      case BadgeSize.small:
        return 3;
      case BadgeSize.medium:
        return 4;
      case BadgeSize.large:
        return 6;
    }
  }

  TextStyle _getTextStyle() {
    TextStyle baseStyle;
    switch (size) {
      case BadgeSize.small:
        baseStyle = AppTextStyles.caption;
        break;
      case BadgeSize.medium:
        baseStyle = AppTextStyles.bodySmall;
        break;
      case BadgeSize.large:
        baseStyle = AppTextStyles.bodyMedium;
        break;
    }
    return baseStyle.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      height: 1.0,
    );
  }
}
