// lib/features/admin_availability_pricing/presentation/widgets/availability_calendar_grid.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/unit_availability.dart';
import '../../domain/entities/availability.dart';

class AvailabilityCalendarGrid extends StatefulWidget {
  final UnitAvailability unitAvailability;
  final DateTime currentDate;
  final bool isCompact;
  final Function(DateTime) onDateSelected;
  final Function(DateTime, DateTime) onDateRangeSelected;
  // New: external selection to persist highlight after dialogs
  final DateTime? selectionStart;
  final DateTime? selectionEnd;
  // New: notify parent when a selection is committed (e.g., long-press)
  final void Function(DateTime start, DateTime end, bool fromLongPress)?
      onSelectionCommitted;

  const AvailabilityCalendarGrid({
    super.key,
    required this.unitAvailability,
    required this.currentDate,
    required this.onDateSelected,
    required this.onDateRangeSelected,
    this.isCompact = false,
    this.selectionStart,
    this.selectionEnd,
    this.onSelectionCommitted,
  });

  @override
  State<AvailabilityCalendarGrid> createState() =>
      _AvailabilityCalendarGridState();
}

class _AvailabilityCalendarGridState extends State<AvailabilityCalendarGrid> {
  DateTime? _selectionStart;
  DateTime? _selectionEnd;
  bool _isSelecting = false;
  bool _longPressMode = false; // New: distinguish long-press selection

  // New: key to measure grid and map pointer to cells
  final GlobalKey _gridKey = GlobalKey();
  static const double _cellSpacing = 4.0; // matches GridView spacing

  @override
  Widget build(BuildContext context) {
    final daysInMonth = _getDaysInMonth();
    final firstWeekday = _getFirstWeekday();

    return Padding(
      padding: EdgeInsets.all(widget.isCompact ? 8 : 16),
      child: Column(
        children: [
          // Weekday headers
          _buildWeekdayHeaders(),

          const SizedBox(height: 8),

          // Calendar grid
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanStart: (details) =>
                      _handlePanStart(details, constraints),
                  onPanUpdate: (details) =>
                      _handlePanUpdate(details, constraints),
                  onPanEnd: (_) => _handlePanEnd(),
                  // Long-press selection without dialogs
                  onLongPressStart: (details) {
                    HapticFeedback.selectionClick();
                    _longPressMode = true;
                    final date = _dateFromLocalPosition(
                        details.localPosition, constraints);
                    if (date == null) return;
                    setState(() {
                      _isSelecting = true;
                      _selectionStart = date;
                      _selectionEnd = date;
                    });
                  },
                  onLongPressMoveUpdate: (details) {
                    if (!_isSelecting ||
                        !_longPressMode ||
                        _selectionStart == null) return;
                    final date = _dateFromLocalPosition(
                        details.localPosition, constraints);
                    if (date == null) return;
                    if (_selectionEnd == null ||
                        !_isSameDay(_selectionEnd!, date)) {
                      setState(() {
                        _selectionEnd = date.isBefore(_selectionStart!)
                            ? _selectionStart
                            : date;
                        if (date.isBefore(_selectionStart!)) {
                          _selectionEnd = _selectionStart;
                          _selectionStart = date;
                        }
                      });
                    }
                  },
                  onLongPressEnd: (_) {
                    if (!_isSelecting ||
                        !_longPressMode ||
                        _selectionStart == null) {
                      _longPressMode = false;
                      return;
                    }
                    final start = _selectionStart!;
                    final end = _selectionEnd ?? start;
                    widget.onSelectionCommitted?.call(start, end, true);
                    setState(() {
                      _isSelecting = false;
                      _selectionStart = null;
                      _selectionEnd = null;
                      _longPressMode = false;
                    });
                  },
                  child: GridView.builder(
                    key: _gridKey,
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 1,
                      crossAxisSpacing: _cellSpacing,
                      mainAxisSpacing: _cellSpacing,
                    ),
                    itemCount: 42, // 6 weeks
                    itemBuilder: (context, index) {
                      return _buildDayCell(index, firstWeekday, daysInMonth);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdays = [
      'أحد',
      'إثنين',
      'ثلاثاء',
      'أربعاء',
      'خميس',
      'جمعة',
      'سبت'
    ];

    return Row(
      children: weekdays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayCell(int index, int firstWeekday, int daysInMonth) {
    final dayNumber = index - firstWeekday + 1;

    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return Container(); // Empty cell
    }

    final date =
        DateTime(widget.currentDate.year, widget.currentDate.month, dayNumber);
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final dayStatus = widget.unitAvailability.calendar[dateKey];

    final isSelected = _isDateInSelection(date);
    final isToday = _isToday(date);

    return GestureDetector(
      onTapDown: (_) => _startSelection(date),
      onTapUp: (_) => _endSelection(date),
      onTapCancel: _cancelSelection,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: !isSelected
              ? _getStatusColor(dayStatus?.status).withOpacity(0.2)
              : null,
          borderRadius: BorderRadius.circular(widget.isCompact ? 8 : 10),
          border: Border.all(
            color: isToday
                ? AppTheme.primaryBlue
                : isSelected
                    ? Colors.white.withOpacity(0.3)
                    : _getStatusColor(dayStatus?.status).withOpacity(0.3),
            width: isToday ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Day number
            Positioned(
              top: widget.isCompact ? 2 : 4,
              left: widget.isCompact ? 4 : 6,
              child: Text(
                '$dayNumber',
                style: AppTextStyles.caption.copyWith(
                  color: isSelected
                      ? Colors.white
                      : dayStatus?.status == AvailabilityStatus.available
                          ? AppTheme.textWhite
                          : AppTheme.textMuted,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                  fontSize: widget.isCompact ? 10 : 12,
                ),
              ),
            ),

            // Status icon
            if (dayStatus != null && !widget.isCompact)
              Positioned(
                bottom: 2,
                right: 2,
                child: _buildStatusIcon(dayStatus.status),
              ),

            // Selection overlay
            if (isSelected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(widget.isCompact ? 8 : 10),
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(AvailabilityStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case AvailabilityStatus.available:
        icon = Icons.check_circle;
        color = AppTheme.success;
        break;
      case AvailabilityStatus.booked:
        icon = Icons.event_busy;
        color = AppTheme.warning;
        break;
      case AvailabilityStatus.blocked:
        icon = Icons.block;
        color = AppTheme.error;
        break;
      case AvailabilityStatus.maintenance:
        icon = Icons.build;
        color = AppTheme.info;
        break;
      default:
        icon = Icons.help_outline;
        color = AppTheme.textMuted;
    }

    return Icon(
      icon,
      size: 14,
      color: color,
    );
  }

  Color _getStatusColor(AvailabilityStatus? status) {
    if (status == null) return AppTheme.textMuted;

    switch (status) {
      case AvailabilityStatus.available:
        return AppTheme.success;
      case AvailabilityStatus.booked:
        return AppTheme.warning;
      case AvailabilityStatus.blocked:
        return AppTheme.error;
      case AvailabilityStatus.maintenance:
        return AppTheme.info;
      default:
        return AppTheme.textMuted;
    }
  }

  int _getDaysInMonth() {
    return DateTime(
      widget.currentDate.year,
      widget.currentDate.month + 1,
      0,
    ).day;
  }

  int _getFirstWeekday() {
    return DateTime(
          widget.currentDate.year,
          widget.currentDate.month,
          1,
        ).weekday %
        7;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isDateInSelection(DateTime date) {
    // Prefer active drag selection
    final s = _selectionStart ?? widget.selectionStart;
    final e = _selectionEnd ?? widget.selectionEnd ?? s;
    if (s == null) return false;

    return date.isAfter(s.subtract(const Duration(days: 1))) &&
        date.isBefore(e!.add(const Duration(days: 1)));
  }

  void _startSelection(DateTime date) {
    HapticFeedback.lightImpact();
    setState(() {
      _isSelecting = true;
      _selectionStart = date;
      _selectionEnd = null;
      _longPressMode = false;
    });
  }

  void _endSelection(DateTime date) {
    if (!_isSelecting) return;

    setState(() {
      _isSelecting = false;
      if (_selectionStart != null) {
        if (date.isBefore(_selectionStart!)) {
          _selectionEnd = _selectionStart;
          _selectionStart = date;
        } else {
          _selectionEnd = date;
        }

        final start = _selectionStart!;
        final end = _selectionEnd!;
        // Persist selection to parent
        widget.onSelectionCommitted?.call(start, end, false);

        if (_isSameDay(start, end)) {
          widget.onDateSelected(start);
        } else {
          widget.onDateRangeSelected(start, end);
        }
      }
      _selectionStart = null;
      _selectionEnd = null;
    });
  }

  void _cancelSelection() {
    setState(() {
      _isSelecting = false;
      _selectionStart = null;
      _selectionEnd = null;
      _longPressMode = false;
    });
  }

  // New: Drag selection handlers
  void _handlePanStart(DragStartDetails details, BoxConstraints constraints) {
    final date = _dateFromLocalPosition(details.localPosition, constraints);
    if (date == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _isSelecting = true;
      _selectionStart = date;
      _selectionEnd = date;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    if (!_isSelecting || _selectionStart == null) return;
    final date = _dateFromLocalPosition(details.localPosition, constraints);
    if (date == null) return;
    if (_selectionEnd == null || !_isSameDay(_selectionEnd!, date)) {
      setState(() {
        _selectionEnd =
            date.isBefore(_selectionStart!) ? _selectionStart : date;
        if (date.isBefore(_selectionStart!)) {
          // swap to keep start <= end for highlighting
          _selectionEnd = _selectionStart;
          _selectionStart = date;
        }
      });
    }
  }

  void _handlePanEnd() {
    if (!_isSelecting || _selectionStart == null) return;
    final start = _selectionStart!;
    final end = _selectionEnd ?? start;

    // Notify parent about committed selection for persistence
    widget.onSelectionCommitted?.call(start, end, false);

    // Trigger callbacks
    if (_isSameDay(start, end)) {
      widget.onDateSelected(start);
    } else {
      widget.onDateRangeSelected(start, end);
    }

    // Reset selection
    setState(() {
      _isSelecting = false;
      _selectionStart = null;
      _selectionEnd = null;
    });
  }

  DateTime? _dateFromLocalPosition(
      Offset localPos, BoxConstraints constraints) {
    // Grid occupies full constraints inside Expanded
    final gridWidth = constraints.maxWidth;
    final gridHeight = constraints.maxHeight;

    // 7 columns, 6 rows
    const columns = 7;
    const rows = 6;

    // Compute cell sizes considering spacing
    const totalHSpacing = _cellSpacing * (columns - 1);
    const totalVSpacing = _cellSpacing * (rows - 1);
    final cellWidth = (gridWidth - totalHSpacing) / columns;
    final cellHeight = (gridHeight - totalVSpacing) / rows;

    final visualCol =
        (localPos.dx.clamp(0, gridWidth) / (cellWidth + _cellSpacing)).floor();
    final row = (localPos.dy.clamp(0, gridHeight) / (cellHeight + _cellSpacing))
        .floor();

    if (visualCol < 0 || visualCol >= columns || row < 0 || row >= rows) {
      return null;
    }

    // In RTL, GridView lays out columns from right to left; invert the column index
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;
    final col = isRtl ? (columns - 1 - visualCol) : visualCol;

    final index = row * columns + col;

    final firstWeekday = _getFirstWeekday();
    final daysInMonth = _getDaysInMonth();
    final dayNumber = index - firstWeekday + 1;

    if (dayNumber < 1 || dayNumber > daysInMonth)
      return null; // outside current month

    return DateTime(
        widget.currentDate.year, widget.currentDate.month, dayNumber);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
