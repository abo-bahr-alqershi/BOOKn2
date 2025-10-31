// lib/features/admin_bookings/presentation/pages/booking_audit_timeline_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../admin_audit_logs/presentation/bloc/audit_logs_bloc.dart';
import '../../../admin_audit_logs/presentation/bloc/audit_logs_event.dart';
import '../../../admin_audit_logs/presentation/bloc/audit_logs_state.dart';
import '../../../admin_audit_logs/presentation/widgets/audit_log_timeline_widget.dart';
import '../../../admin_audit_logs/domain/entities/audit_log.dart';

class BookingAuditTimelinePage extends StatefulWidget {
  final String bookingId;

  const BookingAuditTimelinePage({super.key, required this.bookingId});

  @override
  State<BookingAuditTimelinePage> createState() =>
      _BookingAuditTimelinePageState();
}

class _BookingAuditTimelinePageState extends State<BookingAuditTimelinePage> {
  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  void _loadAuditLogs() {
    final query = AuditLogsQuery(
      pageNumber: 1,
      pageSize: 100,
      // Ask backend to aggregate related logs (Booking + mentions like Payment with BookingId)
      relatedToBookingId: widget.bookingId,
    );
    context.read<AuditLogsBloc>().add(LoadAuditLogsEvent(query: query));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: BlocBuilder<AuditLogsBloc, AuditLogsState>(
                builder: (context, state) {
                  if (state is AuditLogsLoading || state is AuditLogsInitial) {
                    return const LoadingWidget(
                      type: LoadingType.futuristic,
                      message: 'جاري تحميل السجل الزمني للحجز...',
                    );
                  }

                  if (state is AuditLogsError) {
                    return CustomErrorWidget(
                      message: state.message,
                      onRetry: _loadAuditLogs,
                    );
                  }

                  if (state is AuditLogsLoaded) {
                    List<AuditLog> logs = state.auditLogs;

                    if (state.currentQuery.relatedToBookingId != null) {
                      final normalizedId = widget.bookingId.toLowerCase();
                      final legacyFiltered = state.auditLogs.where((l) {
                        final table = l.tableName.toLowerCase();
                        final rid = l.recordId.toLowerCase();
                        final changes = l.changes.toLowerCase();
                        return table == 'booking' ||
                            rid == normalizedId ||
                            changes.contains(normalizedId);
                      }).toList();

                      if (legacyFiltered.isNotEmpty) {
                        logs = legacyFiltered;
                      }
                    }

                    if (logs.isEmpty) {
                      return Center(
                        child: Text(
                          'لا توجد سجلات تدقيق لهذا الحجز',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: AnimationLimiter(
                        child: AuditLogTimelineWidget(
                          auditLogs: logs,
                          onLogTap: _showLogDetails,
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          _buildBackButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سجل تدقيق الحجز',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
                Text(
                  '#${widget.bookingId.substring(0, 8)}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          _buildRefreshButton(),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.darkBorder.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(10),
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child:
                Icon(CupertinoIcons.arrow_right, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.darkBorder.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loadAuditLogs,
          borderRadius: BorderRadius.circular(10),
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(CupertinoIcons.refresh, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }

  void _showLogDetails(AuditLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(color: AppTheme.darkBorder.withOpacity(0.2)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(CupertinoIcons.doc_text,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'تفاصيل السجل',
                          style: AppTextStyles.heading3
                              .copyWith(color: AppTheme.textWhite),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _kv('الكيان', log.tableName),
                  _kv('العملية', log.action),
                  _kv('المعرف', log.recordId),
                  _kv('الاسم', log.recordName),
                  _kv('المستخدم', log.username),
                  _kv('تاريخ', log.timestamp.toString()),
                  if (log.notes.isNotEmpty)
                    _kv('ملاحظات', log.notes, multiline: true),
                  if (log.changes.isNotEmpty)
                    _kv('التغييرات', log.changes, multiline: true),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _kv(String k, String v, {bool multiline = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              k,
              style: AppTextStyles.caption.copyWith(color: AppTheme.textMuted),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              v,
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppTheme.textWhite),
              maxLines: multiline ? null : 2,
              overflow:
                  multiline ? TextOverflow.visible : TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
