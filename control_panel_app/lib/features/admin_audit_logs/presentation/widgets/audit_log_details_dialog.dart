// lib/features/admin_audit_logs/presentation/widgets/audit_log_details_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/audit_log.dart';
import 'package:bookn_cp_app/injection_container.dart' as di;
import '../../domain/repositories/audit_logs_repository.dart' as repo;

class AuditLogDetailsDialog extends StatefulWidget {
  final AuditLog auditLog;

  const AuditLogDetailsDialog({
    super.key,
    required this.auditLog,
  });

  @override
  State<AuditLogDetailsDialog> createState() => _AuditLogDetailsDialogState();
}

class _AuditLogDetailsDialogState extends State<AuditLogDetailsDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _showOldValues = false;
  bool _showNewValues = false;
  bool _showMetadata = false;
  bool _loading = false;
  late AuditLog _log;

  @override
  void initState() {
    super.initState();
    _log = widget.auditLog;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();

    // Fetch heavy fields on demand
    if (_log.oldValues == null && _log.newValues == null && _log.metadata == null) {
      _fetchDetails();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 500;

                  return Container(
                    width: isCompact ? double.infinity : 600,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.85,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _getActionColor().withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.darkCard.withValues(alpha: 0.95),
                                AppTheme.darkCard.withValues(alpha: 0.85),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _getActionColor().withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildHeader(isCompact),
                              Flexible(
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildMainInfo(isCompact),
                                        const SizedBox(height: 20),
                                        _buildDetailsSection(isCompact),
                                        if (_log.oldValues !=
                                            null) ...[
                                          const SizedBox(height: 20),
                                          _buildValuesSection(
                                            title: 'القيم السابقة',
                                            values: _log.oldValues!,
                                            isExpanded: _showOldValues,
                                            onToggle: () => setState(() =>
                                                _showOldValues =
                                                    !_showOldValues),
                                            color: AppTheme.warning,
                                            isCompact: isCompact,
                                          ),
                                        ],
                                        if (_log.newValues !=
                                            null) ...[
                                          const SizedBox(height: 20),
                                          _buildValuesSection(
                                            title: 'القيم الجديدة',
                                            values: _log.newValues!,
                                            isExpanded: _showNewValues,
                                            onToggle: () => setState(() =>
                                                _showNewValues =
                                                    !_showNewValues),
                                            color: AppTheme.success,
                                            isCompact: isCompact,
                                          ),
                                        ],
                                        if (_log.metadata !=
                                            null) ...[
                                          const SizedBox(height: 20),
                                          _buildValuesSection(
                                            title: 'البيانات الإضافية',
                                            values: _log.metadata!,
                                            isExpanded: _showMetadata,
                                            onToggle: () => setState(() =>
                                                _showMetadata = !_showMetadata),
                                            color: AppTheme.info,
                                            isCompact: isCompact,
                                          ),
                                        ],
                                        if (_loading) ...[
                                          const SizedBox(height: 20),
                                          Center(
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: AppTheme.primaryPurple,
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 20),
                                        _buildActions(isCompact),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
        gradient: LinearGradient(
          colors: [
            _getActionColor().withValues(alpha: 0.2),
            _getActionColor().withValues(alpha: 0.1),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: isCompact ? 40 : 48,
            height: isCompact ? 40 : 48,
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
                size: isCompact ? 20 : 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تفاصيل السجل',
                  style: (isCompact
                          ? AppTextStyles.heading3
                          : AppTextStyles.heading2)
                      .copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
                Text(
                  _getActionLabel(),
                  style: AppTextStyles.caption.copyWith(
                    color: _getActionColor(),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.darkBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    CupertinoIcons.xmark,
                    color: AppTheme.textMuted,
                    size: isCompact ? 18 : 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainInfo(bool isCompact) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkBackground.withValues(alpha: 0.5),
            AppTheme.darkBackground.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: CupertinoIcons.number,
            label: 'معرف السجل',
            value: _log.id,
            isCompact: isCompact,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: CupertinoIcons.doc_text,
            label: 'اسم السجل',
            value: _log.recordName,
            isCompact: isCompact,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: CupertinoIcons.table,
            label: 'الجدول',
            value: _log.tableName,
            isCompact: isCompact,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: CupertinoIcons.person_fill,
            label: 'المستخدم',
            value: _log.username,
            isCompact: isCompact,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: CupertinoIcons.clock_fill,
            label: 'التوقيت',
            value: Formatters.formatDateTime(_log.timestamp),
            isCompact: isCompact,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(bool isCompact) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryPurple.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.doc_text_viewfinder,
                color: AppTheme.primaryPurple,
                size: isCompact ? 18 : 20,
              ),
              const SizedBox(width: 8),
              Text(
                'التغييرات',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppTheme.primaryPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.darkBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              widget.auditLog.changes,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textLight,
                fontFamily: 'monospace',
                fontSize: isCompact ? 12 : 14,
              ),
            ),
          ),
          if (widget.auditLog.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  CupertinoIcons.text_bubble,
                  color: AppTheme.textMuted,
                  size: isCompact ? 14 : 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'ملاحظات:',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SelectableText(
              widget.auditLog.notes,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildValuesSection({
    required String title,
    required Map<String, dynamic> values,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Color color,
    required bool isCompact,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onToggle();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.square_list,
                      color: color,
                      size: isCompact ? 18 : 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        CupertinoIcons.chevron_down,
                        color: color,
                        size: isCompact ? 16 : 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: isExpanded ? null : 0,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.darkBackground.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _buildJsonView(values, isCompact),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildJsonView(Map<String, dynamic> data, bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  '${entry.key}:',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.primaryPurple,
                    fontFamily: 'monospace',
                    fontSize: isCompact ? 11 : 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: SelectableText(
                  entry.value?.toString() ?? 'null',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textLight,
                    fontFamily: 'monospace',
                    fontSize: isCompact ? 11 : 12,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isCompact,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: isCompact ? 14 : 16,
          color: AppTheme.textMuted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label:',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                  fontSize: isCompact ? 11 : 12,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SelectableText(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w500,
                    fontSize: isCompact ? 12 : 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (value.length < 50)
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('تم النسخ'),
                  backgroundColor: AppTheme.success,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            icon: Icon(
              CupertinoIcons.doc_on_doc,
              size: isCompact ? 12 : 14,
              color: AppTheme.textMuted,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  Widget _buildActions(bool isCompact) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 20 : 24,
                  vertical: isCompact ? 10 : 12,
                ),
                child: Text(
                  'إغلاق',
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: Colors.white,
                    fontSize: isCompact ? 12 : 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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

  Future<void> _fetchDetails() async {
    setState(() => _loading = true);
    try {
      final repository = di.sl<repo.AuditLogsRepository>();
      final result = await repository.getAuditLogDetails(_log.id);
      result.fold(
        (_) => setState(() => _loading = false),
        (full) {
          setState(() {
            _log = full;
            _loading = false;
          });
        },
      );
    } catch (_) {
      setState(() => _loading = false);
    }
  }
}
