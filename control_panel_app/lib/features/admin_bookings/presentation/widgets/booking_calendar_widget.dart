// lib/features/admin_bookings/presentation/widgets/booking_calendar_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/booking_calendar/booking_calendar_state.dart';
import '../bloc/booking_calendar/booking_calendar_event.dart';

class BookingCalendarWidget extends StatefulWidget {
  final Map<DateTime, List<CalendarEvent>> calendarData;
  final DateTime currentMonth;
  final CalendarView currentView;
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;
  final Function(DateTime) onMonthChanged;

  const BookingCalendarWidget({
    super.key,
    required this.calendarData,
    required this.currentMonth,
    required this.currentView,
    this.selectedDate,
    required this.onDateSelected,
    required this.onMonthChanged,
  });

  @override
  State<BookingCalendarWidget> createState() => _BookingCalendarWidgetState();
}

class _BookingCalendarWidgetState extends State<BookingCalendarWidget> {
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _calendarFormat = _getCalendarFormat();
    _focusedDay = widget.currentMonth;
  }

  CalendarFormat _getCalendarFormat() {
    switch (widget.currentView) {
      case CalendarView.month:
        return CalendarFormat.month;
      case CalendarView.week:
        return CalendarFormat.week;
      case CalendarView.day:
        return CalendarFormat.week;
      default:
        return CalendarFormat.month;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              _buildHeader(),
              _buildCalendar(),
              _buildLegend(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.calendar,
            color: AppTheme.primaryBlue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            _formatMonthYear(_focusedDay),
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
            ),
          ),
          const Spacer(),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        _buildNavButton(
          icon: CupertinoIcons.chevron_right,
          onTap: () {
            setState(() {
              _focusedDay = DateTime(
                _focusedDay.year,
                _focusedDay.month - 1,
              );
            });
            widget.onMonthChanged(_focusedDay);
          },
        ),
        const SizedBox(width: 8),
        _buildNavButton(
          icon: CupertinoIcons.calendar_today,
          onTap: () {
            setState(() {
              _focusedDay = DateTime.now();
            });
            widget.onMonthChanged(_focusedDay);
          },
        ),
        const SizedBox(width: 8),
        _buildNavButton(
          icon: CupertinoIcons.chevron_left,
          onTap: () {
            setState(() {
              _focusedDay = DateTime(
                _focusedDay.year,
                _focusedDay.month + 1,
              );
            });
            widget.onMonthChanged(_focusedDay);
          },
        ),
      ],
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 18,
              color: AppTheme.textWhite,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar<CalendarEvent>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) {
        return isSameDay(widget.selectedDate, day);
      },
      eventLoader: (day) {
        return widget.calendarData[DateTime(day.year, day.month, day.day)] ??
            [];
      },
      startingDayOfWeek: StartingDayOfWeek.sunday,
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,

        // Default cell decoration
        defaultDecoration: BoxDecoration(
          color: AppTheme.darkBackground.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
        ),

        // Weekend cell decoration
        weekendDecoration: BoxDecoration(
          color: AppTheme.darkBackground.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),

        // Selected cell decoration
        selectedDecoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        // Today cell decoration
        todayDecoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppTheme.primaryBlue,
            width: 2,
          ),
        ),

        // Text styles
        defaultTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppTheme.textWhite,
        ),
        weekendTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppTheme.textMuted,
        ),
        selectedTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        todayTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppTheme.primaryBlue,
          fontWeight: FontWeight.bold,
        ),

        // Marker decoration
        markerDecoration: BoxDecoration(
          color: AppTheme.primaryPurple,
          shape: BoxShape.circle,
        ),
        markersMaxCount: 3,
        markersAlignment: Alignment.bottomCenter,
        markerSize: 6,
        markerMargin: const EdgeInsets.symmetric(horizontal: 1),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        leftChevronVisible: false,
        rightChevronVisible: false,
        headerPadding: EdgeInsets.zero,
        headerMargin: EdgeInsets.zero,
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: AppTextStyles.caption.copyWith(
          color: AppTheme.textMuted,
          fontWeight: FontWeight.w600,
        ),
        weekendStyle: AppTextStyles.caption.copyWith(
          color: AppTheme.textMuted.withOpacity(0.6),
          fontWeight: FontWeight.w600,
        ),
      ),
      onDaySelected: (selectedDay, focusedDay) {
        widget.onDateSelected(selectedDay);
        setState(() {
          _focusedDay = focusedDay;
        });
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
        widget.onMonthChanged(focusedDay);
      },
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          if (events.isEmpty) return null;

          return Positioned(
            bottom: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: events.take(3).map((event) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _getEventColor(event.type),
                    shape: BoxShape.circle,
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem(
            color: AppTheme.success,
            label: 'تسجيل وصول',
          ),
          _buildLegendItem(
            color: AppTheme.error,
            label: 'تسجيل مغادرة',
          ),
          _buildLegendItem(
            color: AppTheme.primaryBlue,
            label: 'إقامة',
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Color _getEventColor(EventType type) {
    switch (type) {
      case EventType.checkIn:
        return AppTheme.success;
      case EventType.checkOut:
        return AppTheme.error;
      case EventType.stay:
        return AppTheme.primaryBlue;
    }
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
