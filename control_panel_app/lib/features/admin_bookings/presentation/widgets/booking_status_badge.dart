// lib/features/admin_bookings/presentation/widgets/booking_status_badge.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/enums/booking_status.dart';

enum BadgeSize { small, medium, large }

class BookingStatusBadge extends StatelessWidget {
  final BookingStatus status;
  final BadgeSize size;
  final bool showIcon;
  final bool animated;

  const BookingStatusBadge({
    super.key,
    required this.status,
    this.size = BadgeSize.medium,
    this.showIcon = true,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig();

    Widget badge = Container(
      padding: _getPadding(),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            config.color.withOpacity(0.15),
            config.color.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(_getBorderRadius()),
        border: Border.all(
          color: config.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              config.icon,
              size: _getIconSize(),
              color: config.color,
            ),
            SizedBox(width: _getSpacing()),
          ],
          Text(
            status.displayName,
            style: _getTextStyle().copyWith(
              color: config.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (animated && status == BookingStatus.pending) {
      return _AnimatedBadge(child: badge);
    }

    return badge;
  }

  _StatusConfig _getStatusConfig() {
    switch (status) {
      case BookingStatus.confirmed:
        return _StatusConfig(
          color: AppTheme.success,
          icon: CupertinoIcons.checkmark_circle_fill,
        );
      case BookingStatus.pending:
        return _StatusConfig(
          color: AppTheme.warning,
          icon: CupertinoIcons.clock_fill,
        );
      case BookingStatus.cancelled:
        return _StatusConfig(
          color: AppTheme.error,
          icon: CupertinoIcons.xmark_circle_fill,
        );
      case BookingStatus.completed:
        return _StatusConfig(
          color: AppTheme.info,
          icon: CupertinoIcons.checkmark_seal_fill,
        );
      case BookingStatus.checkedIn:
        return _StatusConfig(
          color: AppTheme.primaryBlue,
          icon: CupertinoIcons.house_fill,
        );
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case BadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case BadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case BadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case BadgeSize.small:
        return 8;
      case BadgeSize.medium:
        return 10;
      case BadgeSize.large:
        return 12;
    }
  }

  double _getIconSize() {
    switch (size) {
      case BadgeSize.small:
        return 12;
      case BadgeSize.medium:
        return 14;
      case BadgeSize.large:
        return 16;
    }
  }

  double _getSpacing() {
    switch (size) {
      case BadgeSize.small:
        return 4;
      case BadgeSize.medium:
        return 6;
      case BadgeSize.large:
        return 8;
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case BadgeSize.small:
        return AppTextStyles.caption;
      case BadgeSize.medium:
        return AppTextStyles.bodyMedium;
      case BadgeSize.large:
        return AppTextStyles.bodyLarge;
    }
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;

  const _StatusConfig({
    required this.color,
    required this.icon,
  });
}

class _AnimatedBadge extends StatefulWidget {
  final Widget child;

  const _AnimatedBadge({required this.child});

  @override
  State<_AnimatedBadge> createState() => _AnimatedBadgeState();
}

class _AnimatedBadgeState extends State<_AnimatedBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}
