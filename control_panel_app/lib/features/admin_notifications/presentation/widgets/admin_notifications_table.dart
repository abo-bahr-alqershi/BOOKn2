// lib/features/admin_notifications/presentation/widgets/admin_notifications_table.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/admin_notification.dart';

class AdminNotificationsTable extends StatefulWidget {
  final List<AdminNotificationEntity> notifications;
  final Function(String) onNotificationTap;
  final Function(String)? onResend;
  final Function(String)? onDelete;

  const AdminNotificationsTable({
    super.key,
    required this.notifications,
    required this.onNotificationTap,
    this.onResend,
    this.onDelete,
  });

  @override
  State<AdminNotificationsTable> createState() =>
      _AdminNotificationsTableState();
}

class _AdminNotificationsTableState extends State<AdminNotificationsTable> {
  final String _sortColumn = 'date';
  final bool _sortAscending = false;
  int? _hoveredIndex;
  Set<String> _selectedIds = {};
  bool _selectAll = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 800;
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          return _buildMobileView();
        } else if (isCompact) {
          return _buildCompactView();
        } else {
          return _buildDesktopView(constraints);
        }
      },
    );
  }

  Widget _buildMobileView() {
    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: widget.notifications
              .asMap()
              .entries
              .map((entry) => _buildMobileCard(entry.value, entry.key))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildMobileCard(AdminNotificationEntity notification, int index) {
    final isSelected = _selectedIds.contains(notification.id);

    return GestureDetector(
      onTap: () => widget.onNotificationTap(notification.id),
      onLongPress: () => _toggleSelection(notification.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.primaryBlue.withValues(alpha: 0.2)
                  : AppTheme.shadowDark.withValues(alpha: 0.1),
              blurRadius: isSelected ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSelected
                      ? [
                          AppTheme.primaryBlue.withValues(alpha: 0.15),
                          AppTheme.primaryPurple.withValues(alpha: 0.1),
                        ]
                      : [
                          AppTheme.darkCard.withValues(alpha: 0.8),
                          AppTheme.darkCard.withValues(alpha: 0.6),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryBlue.withValues(alpha: 0.5)
                      : AppTheme.darkBorder.withValues(alpha: 0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Stack(
                children: [
                  if (isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.checkmark,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildTypeIcon(notification.type),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notification.title,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppTheme.textWhite,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _buildPriorityBadge(
                                          notification.priority),
                                      const SizedBox(width: 8),
                                      _buildStatusBadge(notification.status),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          notification.message,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppTheme.textLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        _buildRecipientBlock(notification),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDateTime(notification.createdAt),
                              style: AppTextStyles.caption.copyWith(
                                color: AppTheme.textMuted,
                              ),
                            ),
                            if (widget.onResend != null ||
                                widget.onDelete != null)
                              _buildActionButtons(notification.id),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactView() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              _buildTableHeader(isCompact: true),
              ...widget.notifications
                  .asMap()
                  .entries
                  .map((entry) => _buildCompactRow(entry.value, entry.key)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopView(BoxConstraints constraints) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: constraints.maxWidth > 1200 ? constraints.maxWidth : 1200,
              child: Column(
                children: [
                  _buildTableHeader(isCompact: false),
                  ...widget.notifications
                      .asMap()
                      .entries
                      .map((entry) => _buildTableRow(entry.value, entry.key)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader({required bool isCompact}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Checkbox(
              value: _selectAll,
              onChanged: (value) => _toggleSelectAll(value!),
              activeColor: AppTheme.primaryBlue,
              checkColor: Colors.white,
            ),
          ),
          if (!isCompact) ...[
            _buildHeaderCell('النوع', 80),
            _buildHeaderCell('العنوان', 200),
            _buildHeaderCell('المستلم', 150),
            _buildHeaderCell('الحالة', 100),
            _buildHeaderCell('الأولوية', 100),
            _buildHeaderCell('التاريخ', 150),
            _buildHeaderCell('الإجراءات', 120),
          ] else ...[
            _buildHeaderCell('الإشعار', 250, isExpanded: true),
            _buildHeaderCell('الحالة', 100),
            _buildHeaderCell('الإجراءات', 100),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width,
      {bool isExpanded = false}) {
    return isExpanded
        ? Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        : SizedBox(
            width: width,
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
  }

  Widget _buildTableRow(AdminNotificationEntity notification, int index) {
    final isSelected = _selectedIds.contains(notification.id);
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTap: () => widget.onNotificationTap(notification.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isHovered
                ? AppTheme.primaryBlue.withValues(alpha: 0.05)
                : isSelected
                    ? AppTheme.primaryBlue.withValues(alpha: 0.02)
                    : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: AppTheme.darkBorder.withValues(alpha: 0.05),
              ),
              left: BorderSide(
                color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSelection(notification.id),
                  activeColor: AppTheme.primaryBlue,
                  checkColor: Colors.white,
                ),
              ),
              SizedBox(
                width: 80,
                child: _buildTypeIcon(notification.type),
              ),
              _buildCell(notification.title, 200),
              _buildRecipientInline(notification, 260),
              SizedBox(
                width: 100,
                child: _buildStatusBadge(notification.status),
              ),
              SizedBox(
                width: 100,
                child: _buildPriorityBadge(notification.priority),
              ),
              _buildCell(_formatDateTime(notification.createdAt), 150),
              SizedBox(
                width: 120,
                child: _buildActionButtons(notification.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactRow(AdminNotificationEntity notification, int index) {
    final isSelected = _selectedIds.contains(notification.id);

    return GestureDetector(
      onTap: () => widget.onNotificationTap(notification.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.05)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: AppTheme.darkBorder.withValues(alpha: 0.05),
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleSelection(notification.id),
                activeColor: AppTheme.primaryBlue,
                checkColor: Colors.white,
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  _buildTypeIcon(notification.type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppTheme.textWhite,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        _buildRecipientSummary(notification),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 100,
              child: _buildStatusBadge(notification.status),
            ),
            SizedBox(
              width: 100,
              child: _buildActionButtons(notification.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppTheme.textWhite,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildRecipientInline(AdminNotificationEntity n, double width) {
    final name = n.recipientName?.isNotEmpty == true ? n.recipientName! : n.recipientId;
    final email = n.recipientEmail;
    final phone = n.recipientPhone;
    final subtitle = [
      if (email != null && email.isNotEmpty) email,
      if (phone != null && phone.isNotEmpty) phone,
    ].join(' • ');

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildRecipientSummary(AdminNotificationEntity n) {
    final name = n.recipientName?.isNotEmpty == true ? n.recipientName! : n.recipientId;
    final email = n.recipientEmail;
    final phone = n.recipientPhone;
    final lines = <String>[];
    lines.add(name);
    if (email != null && email.isNotEmpty) lines.add(email);
    if (phone != null && phone.isNotEmpty) lines.add(phone);
    return Text(
      lines.join(' • '),
      style: AppTextStyles.caption.copyWith(
        color: AppTheme.textMuted,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildRecipientBlock(AdminNotificationEntity n) {
    final name = n.recipientName?.isNotEmpty == true ? n.recipientName! : n.recipientId;
    final email = n.recipientEmail;
    final phone = n.recipientPhone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              CupertinoIcons.person,
              size: 14,
              color: AppTheme.textMuted,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'المستلم: $name',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (email != null && email.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                CupertinoIcons.envelope,
                size: 14,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'بريد المستلم: $email',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        if (phone != null && phone.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                CupertinoIcons.phone,
                size: 14,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'رقم هاتف المستلم: $phone',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTypeIcon(String type) {
    IconData icon;
    Color color;

    switch (type.toLowerCase()) {
      case 'booking':
        icon = CupertinoIcons.calendar;
        color = AppTheme.info;
        break;
      case 'payment':
        icon = CupertinoIcons.creditcard_fill;
        color = AppTheme.warning;
        break;
      case 'promotion':
        icon = CupertinoIcons.gift_fill;
        color = AppTheme.error;
        break;
      case 'system':
        icon = CupertinoIcons.gear_solid;
        color = AppTheme.textMuted;
        break;
      default:
        icon = CupertinoIcons.bell_fill;
        color = AppTheme.primaryBlue;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: color,
        size: 16,
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'sent':
        statusColor = AppTheme.success;
        statusText = 'مُرسل';
        statusIcon = CupertinoIcons.checkmark_circle;
        break;
      case 'pending':
        statusColor = AppTheme.warning;
        statusText = 'قيد الانتظار';
        statusIcon = CupertinoIcons.clock;
        break;
      case 'failed':
        statusColor = AppTheme.error;
        statusText = 'فشل';
        statusIcon = CupertinoIcons.xmark_circle;
        break;
      case 'scheduled':
        statusColor = AppTheme.info;
        statusText = 'مجدول';
        statusIcon = CupertinoIcons.calendar;
        break;
      default:
        statusColor = AppTheme.textMuted;
        statusText = status;
        statusIcon = CupertinoIcons.circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 12,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              statusText,
              style: AppTextStyles.caption.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color priorityColor;
    String priorityText;

    switch (priority.toLowerCase()) {
      case 'low':
        priorityColor = AppTheme.info;
        priorityText = 'منخفضة';
        break;
      case 'normal':
        priorityColor = AppTheme.primaryBlue;
        priorityText = 'عادية';
        break;
      case 'high':
        priorityColor = AppTheme.warning;
        priorityText = 'عالية';
        break;
      case 'urgent':
        priorityColor = AppTheme.error;
        priorityText = 'عاجلة';
        break;
      default:
        priorityColor = AppTheme.textMuted;
        priorityText = priority;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            priorityColor.withValues(alpha: 0.15),
            priorityColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: priorityColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        priorityText,
        style: AppTextStyles.caption.copyWith(
          color: priorityColor,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildActionButtons(String notificationId) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onResend != null)
          _buildActionIcon(
            icon: CupertinoIcons.arrow_counterclockwise,
            onTap: () => widget.onResend!(notificationId),
            tooltip: 'إعادة إرسال',
            color: AppTheme.info,
          ),
        if (widget.onDelete != null) ...[
          const SizedBox(width: 4),
          _buildActionIcon(
            icon: CupertinoIcons.trash,
            onTap: () => widget.onDelete!(notificationId),
            tooltip: 'حذف',
            color: AppTheme.error,
          ),
        ],
      ],
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required VoidCallback onTap,
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
              onTap();
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

  void _toggleSelection(String id) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleSelectAll(bool value) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectAll = value;
      if (value) {
        _selectedIds = widget.notifications.map((n) => n.id).toSet();
      } else {
        _selectedIds.clear();
      }
    });
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
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
