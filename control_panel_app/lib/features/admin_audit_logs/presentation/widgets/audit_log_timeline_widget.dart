// lib/features/admin_audit_logs/presentation/widgets/audit_log_timeline_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/audit_log.dart';

class AuditLogTimelineWidget extends StatefulWidget {
  final List<AuditLog> auditLogs;
  final Function(AuditLog) onLogTap;

  const AuditLogTimelineWidget({
    super.key,
    required this.auditLogs,
    required this.onLogTap,
  });

  @override
  State<AuditLogTimelineWidget> createState() => _AuditLogTimelineWidgetState();
}

class _AuditLogTimelineWidgetState extends State<AuditLogTimelineWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<double>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.auditLogs.length,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300 + (index * 50)),
      ),
    );

    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeIn,
      ));
    }).toList();

    _slideAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 50.0,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      ));
    }).toList();

    // Start animations sequentially
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        Map<String, List<AuditLog>> groupedLogs = _groupLogsByDate();

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.darkCard.withValues(alpha: 0.3),
                AppTheme.darkBackground.withValues(alpha: 0.5),
              ],
            ),
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
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      itemCount: groupedLogs.length,
                      itemBuilder: (context, index) {
                        final date = groupedLogs.keys.elementAt(index);
                        final logs = groupedLogs[date]!;
                        return _buildDateSection(date, logs, isCompact);
                      },
                    ),
                  ),
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
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryPurple.withValues(alpha: 0.1),
            AppTheme.primaryViolet.withValues(alpha: 0.05),
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
            width: isCompact ? 36 : 40,
            height: isCompact ? 36 : 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryPurple.withValues(alpha: 0.3),
                  AppTheme.primaryViolet.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                CupertinoIcons.time,
                color: AppTheme.primaryPurple,
                size: isCompact ? 18 : 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الخط الزمني',
                  style: (isCompact
                          ? AppTextStyles.bodyLarge
                          : AppTextStyles.heading3)
                      .copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
                Text(
                  '${widget.auditLogs.length} نشاط',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          _buildViewToggle(isCompact),
        ],
      ),
    );
  }

  Widget _buildViewToggle(bool isCompact) {
    return Container(
      padding: const EdgeInsets.all(4),
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
          _buildToggleButton(
            icon: CupertinoIcons.list_bullet,
            isActive: true,
            onTap: () {},
            isCompact: isCompact,
          ),
          _buildToggleButton(
            icon: CupertinoIcons.chart_bar_alt_fill,
            isActive: false,
            onTap: () {},
            isCompact: isCompact,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required bool isCompact,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: [
                  AppTheme.primaryPurple.withValues(alpha: 0.3),
                  AppTheme.primaryViolet.withValues(alpha: 0.2),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: EdgeInsets.all(isCompact ? 6 : 8),
            child: Icon(
              icon,
              color: isActive ? AppTheme.primaryPurple : AppTheme.textMuted,
              size: isCompact ? 14 : 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSection(String date, List<AuditLog> logs, bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Header
        Container(
          margin: const EdgeInsets.only(bottom: 16, top: 8),
          child: Row(
            children: [
              Container(
                width: isCompact ? 8 : 10,
                height: isCompact ? 8 : 10,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryPurple.withValues(alpha: 0.1),
                      AppTheme.primaryViolet.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  date,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.primaryPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryPurple.withValues(alpha: 0.3),
                        AppTheme.primaryPurple.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Timeline Items
        ...logs.asMap().entries.map((entry) {
          final index = entry.key;
          final log = entry.value;
          final globalIndex = widget.auditLogs.indexOf(log);

          return AnimatedBuilder(
            animation: _fadeAnimations[globalIndex],
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimations[globalIndex],
                child: Transform.translate(
                  offset: Offset(0, _slideAnimations[globalIndex].value),
                  child: _buildTimelineItem(
                    log: log,
                    isLast: index == logs.length - 1,
                    isCompact: isCompact,
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildTimelineItem({
    required AuditLog log,
    required bool isLast,
    required bool isCompact,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Line and Dot
          Column(
            children: [
              Container(
                width: isCompact ? 32 : 40,
                height: isCompact ? 32 : 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getActionColor(log.action).withValues(alpha: 0.3),
                      _getActionColor(log.action).withValues(alpha: 0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getActionColor(log.action).withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    _getActionIcon(log.action),
                    color: _getActionColor(log.action),
                    size: isCompact ? 16 : 18,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _getActionColor(log.action).withValues(alpha: 0.3),
                          _getActionColor(log.action).withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onLogTap(log);
              },
              child: Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
                padding: EdgeInsets.all(isCompact ? 12 : 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.darkCard.withValues(alpha: 0.6),
                      AppTheme.darkCard.withValues(alpha: 0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getActionColor(log.action).withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getActionColor(log.action).withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.recordName,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppTheme.textWhite,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                log.tableName,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildTimeBadge(log.timestamp, isCompact),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildUserInfo(log, isCompact),
                    if (log.changes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildChangesPreview(log.changes, isCompact),
                    ],
                    if (log.isSlowOperation) ...[
                      const SizedBox(height: 8),
                      _buildSlowOperationIndicator(isCompact),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBadge(DateTime timestamp, bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryPurple.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.clock,
            size: isCompact ? 10 : 12,
            color: AppTheme.primaryPurple,
          ),
          const SizedBox(width: 4),
          Text(
            Formatters.formatTimeOnly(timestamp),
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.primaryPurple,
              fontSize: isCompact ? 9 : 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(AuditLog log, bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 8 : 10),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: isCompact ? 24 : 28,
            height: isCompact ? 24 : 28,
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
                log.username.isNotEmpty ? log.username[0].toUpperCase() : '?',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: isCompact ? 10 : 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.username,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'ID: ${log.userId}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                    fontSize: isCompact ? 9 : 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 6 : 8,
              vertical: isCompact ? 2 : 3,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getActionColor(log.action).withValues(alpha: 0.2),
                  _getActionColor(log.action).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _getActionLabel(log.action),
              style: AppTextStyles.caption.copyWith(
                color: _getActionColor(log.action),
                fontWeight: FontWeight.bold,
                fontSize: isCompact ? 9 : 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangesPreview(String changes, bool isCompact) {
    final previewText =
        changes.length > 100 ? '${changes.substring(0, 100)}...' : changes;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 8 : 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryViolet.withValues(alpha: 0.05),
            AppTheme.primaryPurple.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.primaryPurple.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.doc_text,
                size: isCompact ? 10 : 12,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                'التغييرات:',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                  fontSize: isCompact ? 9 : 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            previewText,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textLight,
              fontFamily: 'monospace',
              fontSize: isCompact ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlowOperationIndicator(bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            size: isCompact ? 12 : 14,
            color: AppTheme.warning,
          ),
          const SizedBox(width: 6),
          Text(
            'عملية بطيئة',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.warning,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<AuditLog>> _groupLogsByDate() {
    Map<String, List<AuditLog>> grouped = {};

    for (final log in widget.auditLogs) {
      final dateKey = Formatters.formatDate(log.timestamp);
      grouped.putIfAbsent(dateKey, () => []).add(log);
    }

    return grouped;
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
}
