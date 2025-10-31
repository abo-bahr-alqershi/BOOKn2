import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class MessageStatusIndicator extends StatelessWidget {
  final String status;
  final Color? color;
  final double size;

  const MessageStatusIndicator({
    super.key,
    required this.status,
    this.color,
    this.size = 14, // Reduced from 16
  });

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color iconColor;
    double opacity = 1.0;

    switch (status) {
      case 'sending':
        iconData = Icons.schedule_rounded;
        iconColor = color ?? AppTheme.textMuted;
        opacity = 0.5;
        break;
      case 'sent':
        iconData = Icons.check_rounded;
        iconColor = color ?? AppTheme.textMuted;
        opacity = 0.6;
        break;
      case 'delivered':
        iconData = Icons.done_all_rounded;
        iconColor = color ?? AppTheme.textMuted;
        opacity = 0.7;
        break;
      case 'read':
        iconData = Icons.done_all_rounded;
        iconColor = color ?? AppTheme.primaryBlue;
        opacity = 0.9;
        break;
      case 'failed':
        iconData = Icons.error_outline_rounded;
        iconColor = AppTheme.error;
        opacity = 0.8;
        break;
      default:
        iconData = Icons.check_rounded;
        iconColor = color ?? AppTheme.textMuted;
        opacity = 0.5;
    }

    return Container(
      width: size + 2,
      height: size + 2,
      decoration: status == 'read'
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                  blurRadius: 4,
                  spreadRadius: 0.5,
                ),
              ],
            )
          : null,
      child: Icon(
        iconData,
        size: size,
        color: iconColor.withValues(alpha: opacity),
      ),
    );
  }
}