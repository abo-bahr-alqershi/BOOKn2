import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:bookn_cp_app/core/theme/app_colors.dart';
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';
import 'package:bookn_cp_app/core/utils/time_ago_helper.dart';

/// Widget لعرض آخر ظهور للمستخدم بشكل أنيق
class LastSeenWidget extends StatelessWidget {
  final DateTime? lastSeen;
  final LastSeenStyle style;
  final bool showIcon;
  final bool showAnimation;

  const LastSeenWidget({
    super.key,
    required this.lastSeen,
    this.style = LastSeenStyle.compact,
    this.showIcon = true,
    this.showAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    final status = TimeAgoHelper.getActivityStatus(lastSeen);
    final statusText = TimeAgoHelper.getOnlineStatusArabic(lastSeen);

    switch (style) {
      case LastSeenStyle.compact:
        return _buildCompactStyle(status, statusText);
      case LastSeenStyle.detailed:
        return _buildDetailedStyle(status, statusText);
      case LastSeenStyle.badge:
        return _buildBadgeStyle(status, statusText);
      case LastSeenStyle.minimal:
        return _buildMinimalStyle(status, statusText);
    }
  }

  Widget _buildCompactStyle(ActivityStatus status, String statusText) {
    final color = _getStatusColor(status);

    return Container(
      width: double.infinity, // يمتد على عرض الكرت
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showIcon) ...[
            _buildStatusIndicator(status, color, size: 6),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              statusText,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStyle(ActivityStatus status, String statusText) {
    final color = _getStatusColor(status);

    return Container(
      width: double.infinity, // يمتد على عرض الكرت
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showIcon) ...[
            _buildStatusIndicator(status, color, size: 7),
            const SizedBox(width: 8),
          ],
          Text(
            _getStatusLabel(status),
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '•',
            style: TextStyle(
              color: AppTheme.textMuted.withOpacity(0.5),
              fontSize: 8,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              statusText,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textLight,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeStyle(ActivityStatus status, String statusText) {
    final color = _getStatusColor(status);

    return Container(
      width: double.infinity, // يمتد على عرض الكرت
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showIcon && showAnimation && status == ActivityStatus.online)
            _buildPulsingDot(Colors.white, size: 5)
          else if (showIcon)
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          if (showIcon) const SizedBox(width: 6),
          Flexible(
            child: Text(
              statusText,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalStyle(ActivityStatus status, String statusText) {
    final color = _getStatusColor(status);

    return SizedBox(
      width: double.infinity, // يمتد على عرض الكرت
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showIcon) ...[
            _buildStatusIndicator(status, color, size: 5),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              statusText,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(ActivityStatus status, Color color,
      {double size = 8}) {
    if (showAnimation && status == ActivityStatus.online) {
      return _buildPulsingDot(color, size: size);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingDot(Color color, {double size = 8}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.6 * value),
                blurRadius: 8 * value,
                spreadRadius: 2 * value,
              ),
            ],
          ),
        );
      },
      onEnd: () {
        // Animation will rebuild automatically when widget rebuilds
      },
    );
  }

  Color _getStatusColor(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.online:
        return AppTheme.success;
      case ActivityStatus.recentlyActive:
        return AppTheme.warning;
      case ActivityStatus.away:
        return Colors.orange;
      case ActivityStatus.offline:
        return AppTheme.textMuted;
    }
  }

  String _getStatusLabel(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.online:
        return 'متصل';
      case ActivityStatus.recentlyActive:
        return 'نشط مؤخراً';
      case ActivityStatus.away:
        return 'بعيد';
      case ActivityStatus.offline:
        return 'غير متصل';
    }
  }
}

/// Different styles for displaying last seen
enum LastSeenStyle {
  compact, // Small compact badge
  detailed, // Detailed card with status label
  badge, // Colorful badge
  minimal, // Minimal text with dot
}
