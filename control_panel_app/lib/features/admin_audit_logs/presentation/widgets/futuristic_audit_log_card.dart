// lib/features/admin_audit_logs/presentation/widgets/futuristic_audit_log_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/audit_log.dart';

class FuturisticAuditLogCard extends StatefulWidget {
  final AuditLog auditLog;
  final VoidCallback? onTap;
  final bool isCompact;
  final bool isGridView; // 🎯 إضافة للتمييز بين العرض الشبكي والقائمة

  const FuturisticAuditLogCard({
    super.key,
    required this.auditLog,
    this.onTap,
    this.isCompact = false,
    this.isGridView = false, // 🎯 القيمة الافتراضية
  });

  @override
  State<FuturisticAuditLogCard> createState() => _FuturisticAuditLogCardState();
}

class _FuturisticAuditLogCardState extends State<FuturisticAuditLogCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isHovered = false;

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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.identity()..scale(_isHovered ? 0.98 : 1.0),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _setHovered(true),
        onTapUp: (_) => _setHovered(false),
        onTapCancel: () => _setHovered(false),
        child: Container(
          margin: EdgeInsets.only(
            bottom: widget.isGridView ? 0 : (widget.isCompact ? 8 : 16),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _getActionColor().withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
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
                    colors: [
                      AppTheme.darkCard.withValues(alpha: 0.8),
                      AppTheme.darkCard.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getActionColor().withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: widget.isGridView
                    ? _buildGridContent() // 🎯 محتوى مخصص للعرض الشبكي
                    : widget.isCompact
                        ? _buildCompactContent()
                        : _buildFullContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🎯 محتوى مخصص ومحسّن للعرض الشبكي
  Widget _buildGridContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header مضغوط
                _buildGridHeader(),
                const SizedBox(height: 10),

                // Main Info
                _buildGridMainInfo(),
                const SizedBox(height: 10),

                // User & Time
                _buildGridUserInfo(),
                const SizedBox(height: 10),

                // Changes Preview (مختصر)
                if (widget.auditLog.changes.isNotEmpty)
                  _buildGridChangesPreview(),

                // Footer
                const SizedBox(height: 8),
                _buildGridFooter(),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🎯 Header مضغوط للعرض الشبكي
  Widget _buildGridHeader() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getActionColor().withValues(alpha: 0.3),
                _getActionColor().withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(
              _getActionIcon(),
              color: _getActionColor(),
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _getActionLabel(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: _getActionColor(),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getActionColor().withValues(alpha: 0.2),
                _getActionColor().withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _getActionColor().withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            widget.auditLog.action.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              color: _getActionColor(),
              fontWeight: FontWeight.bold,
              fontSize: 8,
            ),
          ),
        ),
      ],
    );
  }

  // 🎯 المعلومات الرئيسية للعرض الشبكي
  Widget _buildGridMainInfo() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.doc_text,
                size: 10,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.auditLog.recordName,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                CupertinoIcons.table,
                size: 10,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.auditLog.tableName,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🎯 معلومات المستخدم للعرض الشبكي
  Widget _buildGridUserInfo() {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue.withValues(alpha: 0.3),
                AppTheme.primaryCyan.withValues(alpha: 0.2),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              widget.auditLog.username.isNotEmpty
                  ? widget.auditLog.username[0].toUpperCase()
                  : '?',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            widget.auditLog.username,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textWhite,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Icon(
          CupertinoIcons.clock,
          size: 10,
          color: AppTheme.textMuted,
        ),
        const SizedBox(width: 2),
        Text(
          Formatters.formatRelativeTime(widget.auditLog.timestamp),
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  // 🎯 معاينة التغييرات للعرض الشبكي (مختصرة جداً)
  Widget _buildGridChangesPreview() {
    final changes = widget.auditLog.changes.length > 30
        ? '${widget.auditLog.changes.substring(0, 30)}...'
        : widget.auditLog.changes;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryPurple.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        changes,
        style: AppTextStyles.caption.copyWith(
          color: AppTheme.textLight,
          fontFamily: 'monospace',
          fontSize: 9,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // 🎯 Footer للعرض الشبكي
  Widget _buildGridFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (widget.auditLog.isSlowOperation)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppTheme.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.exclamationmark_triangle_fill,
                  size: 8,
                  color: AppTheme.warning,
                ),
                const SizedBox(width: 2),
                Text(
                  'بطيء',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.warning,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        else
          const SizedBox.shrink(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.darkBackground.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.calendar,
                size: 8,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 2),
              Text(
                Formatters.formatDate(widget.auditLog.timestamp),
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // باقي الدوال الأصلية...
  Widget _buildFullContent() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildBody(),
            const SizedBox(height: 12),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactContent() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildActionIcon(size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.auditLog.recordName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.auditLog.action} - ${widget.auditLog.username}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _buildTimestamp(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _buildActionIcon(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getActionLabel(),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: _getActionColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                widget.auditLog.tableName,
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildBody() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            icon: CupertinoIcons.doc_text,
            label: 'السجل',
            value: widget.auditLog.recordName,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: CupertinoIcons.person_fill,
            label: 'المستخدم',
            value: widget.auditLog.username,
          ),
          if (widget.auditLog.changes.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildChangesPreview(),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTimestamp(),
        if (widget.auditLog.isSlowOperation) _buildSlowOperationBadge(),
      ],
    );
  }

  Widget _buildActionIcon({double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getActionColor().withValues(alpha: 0.3),
            _getActionColor().withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          _getActionIcon(),
          color: _getActionColor(),
          size: size * 0.5,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getActionColor().withValues(alpha: 0.2),
            _getActionColor().withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getActionColor().withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        widget.auditLog.action.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: _getActionColor(),
          fontWeight: FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: AppTheme.textMuted,
        ),
        const SizedBox(width: 6),
        Text(
          '$label:',
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildChangesPreview() {
    final changes = widget.auditLog.changes.length > 50
        ? '${widget.auditLog.changes.substring(0, 50)}...'
        : widget.auditLog.changes;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryPurple.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        changes,
        style: AppTextStyles.caption.copyWith(
          color: AppTheme.textLight,
          fontFamily: 'monospace',
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTimestamp() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          CupertinoIcons.clock,
          size: 12,
          color: AppTheme.textMuted,
        ),
        const SizedBox(width: 4),
        Text(
          Formatters.formatRelativeTime(widget.auditLog.timestamp),
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildSlowOperationBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppTheme.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            size: 10,
            color: AppTheme.warning,
          ),
          const SizedBox(width: 2),
          Text(
            'بطيء',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.warning,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getActionColor() {
    switch (widget.auditLog.action.toLowerCase()) {
      case 'create':
        return AppTheme.success;
      case 'update':
        return AppTheme.info;
      case 'delete':
        return AppTheme.error;
      case 'login':
        return AppTheme.primaryBlue;
      case 'logout':
        return AppTheme.warning;
      default:
        return AppTheme.primaryPurple;
    }
  }

  IconData _getActionIcon() {
    switch (widget.auditLog.action.toLowerCase()) {
      case 'create':
        return CupertinoIcons.plus_circle_fill;
      case 'update':
        return CupertinoIcons.pencil_circle_fill;
      case 'delete':
        return CupertinoIcons.trash_circle_fill;
      case 'login':
        return CupertinoIcons.arrow_right_circle_fill;
      case 'logout':
        return CupertinoIcons.arrow_left_circle_fill;
      default:
        return CupertinoIcons.info_circle_fill;
    }
  }

  String _getActionLabel() {
    switch (widget.auditLog.action.toLowerCase()) {
      case 'create':
        return 'إضافة جديد';
      case 'update':
        return 'تحديث';
      case 'delete':
        return 'حذف';
      case 'login':
        return 'تسجيل دخول';
      case 'logout':
        return 'تسجيل خروج';
      default:
        return widget.auditLog.action;
    }
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
