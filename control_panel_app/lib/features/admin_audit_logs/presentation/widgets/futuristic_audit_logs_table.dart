// lib/features/admin_audit_logs/presentation/widgets/futuristic_audit_logs_table.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/audit_log.dart';

class FuturisticAuditLogsTable extends StatefulWidget {
  final List<AuditLog> auditLogs;
  final Function(AuditLog) onLogTap;

  const FuturisticAuditLogsTable({
    super.key,
    required this.auditLogs,
    required this.onLogTap,
  });

  @override
  State<FuturisticAuditLogsTable> createState() =>
      _FuturisticAuditLogsTableState();
}

class _FuturisticAuditLogsTableState extends State<FuturisticAuditLogsTable> {
  int? _hoveredIndex;
  String _sortColumn = 'timestamp';
  bool _sortAscending = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 800;

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
              child: Column(
                children: [
                  _buildHeader(isCompact),
                  isCompact
                      ? _buildCompactView()
                      : _buildTableView(constraints),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.doc_text_search,
                  color: AppTheme.primaryPurple,
                  size: isCompact ? 18 : 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'سجل الأنشطة',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                    fontSize: isCompact ? 16 : null,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.auditLogs.length}',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isCompact ? 10 : 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isCompact) _buildSortDropdown(isCompact),
        ],
      ),
    );
  }

  Widget _buildSortDropdown(bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.sort_down,
            size: isCompact ? 14 : 16,
            color: AppTheme.textMuted,
          ),
          SizedBox(width: isCompact ? 4 : 6),
          Text(
            'ترتيب',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
              fontSize: isCompact ? 11 : 12,
            ),
          ),
          SizedBox(width: isCompact ? 4 : 8),
          DropdownButton<String>(
            value: _sortColumn,
            dropdownColor: AppTheme.darkCard,
            underline: const SizedBox.shrink(),
            icon: Icon(
              CupertinoIcons.chevron_down,
              size: isCompact ? 12 : 14,
              color: AppTheme.primaryPurple,
            ),
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.primaryPurple,
              fontSize: isCompact ? 11 : 12,
            ),
            items: const [
              DropdownMenuItem(value: 'timestamp', child: Text('التوقيت')),
              DropdownMenuItem(value: 'action', child: Text('الإجراء')),
              DropdownMenuItem(value: 'user', child: Text('المستخدم')),
              DropdownMenuItem(value: 'table', child: Text('الجدول')),
            ],
            onChanged: (value) {
              setState(() {
                _sortColumn = value!;
                _sortLogs();
              });
            },
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _sortAscending = !_sortAscending;
                _sortLogs();
              });
            },
            icon: Icon(
              _sortAscending
                  ? CupertinoIcons.arrow_up
                  : CupertinoIcons.arrow_down,
              size: isCompact ? 14 : 16,
              color: AppTheme.primaryPurple,
            ),
            padding: EdgeInsets.all(isCompact ? 4 : 8),
            constraints: BoxConstraints(
              minWidth: isCompact ? 24 : 32,
              minHeight: isCompact ? 24 : 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.auditLogs.length,
      itemBuilder: (context, index) {
        final log = widget.auditLogs[index];

        return GestureDetector(
          onTap: () => widget.onLogTap(log),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.darkCard.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.darkBorder.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildActionBadge(log.action),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.recordName,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppTheme.textWhite,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            log.tableName,
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.person,
                      size: 12,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        log.username,
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      Formatters.formatRelativeTime(log.timestamp),
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableView(BoxConstraints constraints) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: constraints.maxWidth > 1200 ? constraints.maxWidth : 1200,
        child: Column(
          children: [
            _buildTableHeader(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.auditLogs.length,
              itemBuilder: (context, index) {
                return _buildTableRow(index, widget.auditLogs[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
          _buildHeaderCell('التوقيت', 150),
          _buildHeaderCell('الإجراء', 100),
          _buildHeaderCell('الجدول', 120),
          _buildHeaderCell('السجل', 200),
          _buildHeaderCell('المستخدم', 150),
          _buildHeaderCell('التغييرات', 250),
          _buildHeaderCell('الملاحظات', 200),
          _buildHeaderCell('', 80),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width) {
    return SizedBox(
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

  Widget _buildTableRow(int index, AuditLog log) {
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTap: () => widget.onLogTap(log),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isHovered
                ? AppTheme.primaryPurple.withValues(alpha: 0.05)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: AppTheme.darkBorder.withValues(alpha: 0.05),
              ),
              left: BorderSide(
                color: _getActionColor(log.action),
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              _buildCell(
                Formatters.formatDateTime(log.timestamp),
                150,
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
              SizedBox(
                width: 100,
                child: _buildActionBadge(log.action),
              ),
              _buildCell(log.tableName, 120),
              _buildCell(
                log.recordName,
                200,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.w500,
                ),
              ),
              _buildCell(log.username, 150),
              _buildCell(
                log.changes.length > 50
                    ? '${log.changes.substring(0, 50)}...'
                    : log.changes,
                250,
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textLight,
                  fontFamily: 'monospace',
                ),
              ),
              _buildCell(log.notes, 200),
              SizedBox(
                width: 80,
                child: Row(
                  children: [
                    if (log.isSlowOperation) _buildSlowIndicator(),
                    const Spacer(),
                    _buildActionIcon(
                      icon: CupertinoIcons.eye,
                      onTap: () => widget.onLogTap(log),
                      tooltip: 'عرض التفاصيل',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(String text, double width, {TextStyle? style}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: style ??
            AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildActionBadge(String action) {
    final color = _getActionColor(action);
    final icon = _getActionIcon(action);
    final label = _getActionLabel(action);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlowIndicator() {
    return Tooltip(
      message: 'عملية بطيئة',
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.warning.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          CupertinoIcons.exclamationmark,
          size: 10,
          color: AppTheme.warning,
        ),
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryPurple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              child: Icon(
                icon,
                size: 14,
                color: AppTheme.primaryPurple,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
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

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
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

  String _getActionLabel(String action) {
    switch (action.toLowerCase()) {
      case 'create':
        return 'إضافة';
      case 'update':
        return 'تحديث';
      case 'delete':
        return 'حذف';
      case 'login':
        return 'دخول';
      case 'logout':
        return 'خروج';
      default:
        return action;
    }
  }

  void _sortLogs() {
    widget.auditLogs.sort((a, b) {
      int result;
      switch (_sortColumn) {
        case 'timestamp':
          result = a.timestamp.compareTo(b.timestamp);
          break;
        case 'action':
          result = a.action.compareTo(b.action);
          break;
        case 'user':
          result = a.username.compareTo(b.username);
          break;
        case 'table':
          result = a.tableName.compareTo(b.tableName);
          break;
        default:
          result = 0;
      }
      return _sortAscending ? result : -result;
    });
  }
}
