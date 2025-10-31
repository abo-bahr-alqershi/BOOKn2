// lib/features/notifications/presentation/widgets/notification_item_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/notification.dart';

class NotificationItemWidget extends StatefulWidget {
  final NotificationEntity notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final VoidCallback? onMarkAsRead;

  const NotificationItemWidget({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
    this.onMarkAsRead,
  });

  @override
  State<NotificationItemWidget> createState() => _NotificationItemWidgetState();
}

class _NotificationItemWidgetState extends State<NotificationItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isHovered = false;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.identity()..scale(_isHovered ? 0.98 : 1.0),
      margin: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(widget.notification.id),
        direction: DismissDirection.endToStart,
        background: _buildDismissBackground(),
        onDismissed: (_) {
          setState(() => _isDismissed = true);
          widget.onDismiss?.call();
        },
        child: GestureDetector(
          onTap: _handleTap,
          onTapDown: (_) => _setHovered(true),
          onTapUp: (_) => _setHovered(false),
          onTapCancel: () => _setHovered(false),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowDark.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.notification.isRead
                          ? [
                              AppTheme.darkCard.withValues(alpha: 0.5),
                              AppTheme.darkCard.withValues(alpha: 0.3),
                            ]
                          : [
                              AppTheme.primaryBlue.withValues(alpha: 0.08),
                              AppTheme.primaryPurple.withValues(alpha: 0.05),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.notification.isRead
                          ? AppTheme.darkBorder.withValues(alpha: 0.2)
                          : AppTheme.primaryBlue.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 350;
                      return isCompact
                          ? _buildCompactContent()
                          : _buildFullContent();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIcon(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.notification.title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: widget.notification.isRead
                              ? FontWeight.w500
                              : FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(widget.notification.createdAt),
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.notification.message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textMuted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildTypeChip(),
                    const Spacer(),
                    if (!widget.notification.isRead)
                      _buildActionButton(
                        icon: CupertinoIcons.check_mark,
                        onTap: widget.onMarkAsRead,
                        tooltip: 'وضع كمقروء',
                      ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: CupertinoIcons.trash,
                      onTap: () {
                        setState(() => _isDismissed = true);
                        widget.onDismiss?.call();
                      },
                      tooltip: 'حذف',
                      color: AppTheme.error,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactContent() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIcon(size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.notification.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: widget.notification.isRead
                            ? FontWeight.w500
                            : FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(widget.notification.createdAt),
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (!widget.notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.notification.message,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textMuted,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTypeChip(isSmall: true),
              const Spacer(),
              if (!widget.notification.isRead)
                _buildCompactActionButton(
                  icon: CupertinoIcons.check_mark,
                  onTap: widget.onMarkAsRead,
                ),
              const SizedBox(width: 4),
              _buildCompactActionButton(
                icon: CupertinoIcons.trash,
                onTap: () {
                  setState(() => _isDismissed = true);
                  widget.onDismiss?.call();
                },
                color: AppTheme.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIcon({double size = 48}) {
    final IconData icon;
    final List<Color> gradient;

    switch (widget.notification.type) {
      case 'booking':
        icon = CupertinoIcons.calendar;
        gradient = [AppTheme.info, AppTheme.neonBlue];
        break;
      case 'payment':
        icon = CupertinoIcons.creditcard_fill;
        gradient = [AppTheme.warning, const Color(0xFFFFD700)];
        break;
      case 'promotion':
        icon = CupertinoIcons.gift_fill;
        gradient = [AppTheme.error, const Color(0xFFFF69B4)];
        break;
      case 'system':
        icon = CupertinoIcons.gear_solid;
        gradient = [AppTheme.textMuted, AppTheme.darkBorder];
        break;
      default:
        icon = CupertinoIcons.bell_fill;
        gradient = [AppTheme.primaryBlue, AppTheme.primaryCyan];
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }

  Widget _buildTypeChip({bool isSmall = false}) {
    String label;
    switch (widget.notification.type) {
      case 'booking':
        label = 'حجز';
        break;
      case 'payment':
        label = 'دفع';
        break;
      case 'promotion':
        label = 'عرض';
        break;
      case 'system':
        label = 'نظام';
        break;
      default:
        label = 'عام';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 8,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(isSmall ? 6 : 8),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppTheme.primaryBlue,
          fontSize: isSmall ? 9 : 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onTap,
    required String tooltip,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: (color ?? AppTheme.primaryBlue).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap?.call();
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              child: Icon(
                icon,
                size: 14,
                color: color ?? AppTheme.primaryBlue,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactActionButton({
    required IconData icon,
    required VoidCallback? onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: (color ?? AppTheme.primaryBlue).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 12,
          color: color ?? AppTheme.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.error.withValues(alpha: 0.1),
            AppTheme.error.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: Icon(
        CupertinoIcons.trash,
        color: AppTheme.error,
        size: 24,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return Formatters.formatDate(dateTime);
    }
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    if (!widget.notification.isRead) {
      widget.onMarkAsRead?.call();
    }
    widget.onTap?.call();
  }

  void _setHovered(bool value) {
    setState(() => _isHovered = value);
    if (value) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
}
