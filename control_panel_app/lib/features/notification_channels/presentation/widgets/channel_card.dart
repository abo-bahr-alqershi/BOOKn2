import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/notification_channel.dart';

class ChannelCard extends StatelessWidget {
  final NotificationChannel channel;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onManageUsers;
  final VoidCallback? onSendNotification;

  const ChannelCard({
    super.key,
    required this.channel,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onManageUsers,
    this.onSendNotification,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.darkCard.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: channel.isActive
                  ? AppTheme.primaryBlue.withOpacity(0.2)
                  : AppTheme.darkBorder.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildDescription(),
              const SizedBox(height: 16),
              _buildStatistics(),
              const SizedBox(height: 16),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getChannelColor().withOpacity(0.8),
                _getChannelColor().withOpacity(0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              channel.displayIcon,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      channel.name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildTypeBadge(),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'معرف: ${channel.identifier}',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
        _buildStatusIndicator(),
      ],
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getTypeColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getTypeColor().withOpacity(0.4),
        ),
      ),
      child: Text(
        channel.typeLabel,
        style: AppTextStyles.caption.copyWith(
          color: _getTypeColor(),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: channel.isActive ? AppTheme.success : AppTheme.textMuted,
        boxShadow: channel.isActive
            ? [
                BoxShadow(
                  color: AppTheme.success.withOpacity(0.4),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildDescription() {
    if (channel.description == null || channel.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      channel.description!,
      style: AppTextStyles.bodySmall.copyWith(
        color: AppTheme.textLight,
        height: 1.5,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStatistics() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildStatItem(
            icon: CupertinoIcons.person_2,
            label: 'المشتركين',
            value: channel.subscribersCount.toString(),
            color: AppTheme.primaryBlue,
          ),
          Container(
            width: 1,
            height: 30,
            color: AppTheme.darkBorder.withOpacity(0.3),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          _buildStatItem(
            icon: CupertinoIcons.paperplane,
            label: 'الإشعارات',
            value: channel.notificationsSentCount.toString(),
            color: AppTheme.primaryPurple,
          ),
          Container(
            width: 1,
            height: 30,
            color: AppTheme.darkBorder.withOpacity(0.3),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          _buildStatItem(
            icon: CupertinoIcons.clock,
            label: 'آخر نشاط',
            value: _getLastActivityText(),
            color: AppTheme.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        if (onManageUsers != null) ...[
          _buildActionButton(
            icon: CupertinoIcons.person_add,
            label: 'المستخدمين',
            onTap: onManageUsers!,
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(width: 8),
        ],
        if (onSendNotification != null) ...[
          _buildActionButton(
            icon: CupertinoIcons.paperplane,
            label: 'إرسال',
            onTap: onSendNotification!,
            color: AppTheme.success,
          ),
          const SizedBox(width: 8),
        ],
        if (onEdit != null && channel.isDeletable) ...[
          _buildActionButton(
            icon: CupertinoIcons.pencil,
            label: 'تعديل',
            onTap: onEdit!,
            color: AppTheme.warning,
          ),
          const SizedBox(width: 8),
        ],
        if (onDelete != null && channel.isDeletable) ...[
          _buildActionButton(
            icon: CupertinoIcons.trash,
            label: 'حذف',
            onTap: onDelete!,
            color: AppTheme.error,
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: color.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getChannelColor() {
    if (channel.color != null && channel.color!.isNotEmpty) {
      try {
        return Color(int.parse(channel.color!.replaceFirst('#', '0xff')));
      } catch (_) {}
    }
    return AppTheme.primaryBlue;
  }

  Color _getTypeColor() {
    switch (channel.type) {
      case 'SYSTEM':
        return AppTheme.error;
      case 'CUSTOM':
        return AppTheme.primaryBlue;
      case 'ROLE_BASED':
        return AppTheme.primaryPurple;
      case 'EVENT_BASED':
        return AppTheme.warning;
      default:
        return AppTheme.textMuted;
    }
  }

  String _getLastActivityText() {
    if (channel.lastNotificationAt == null) {
      return 'لا يوجد';
    }

    final difference = DateTime.now().difference(channel.lastNotificationAt!);
    
    if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }
}
