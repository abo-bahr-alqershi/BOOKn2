// lib/features/admin_bookings/presentation/pages/booking_calendar_page.dart

import 'package:bookn_cp_app/features/admin_bookings/domain/entities/booking.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../bloc/booking_calendar/booking_calendar_bloc.dart';
import '../bloc/booking_calendar/booking_calendar_event.dart';
import '../bloc/booking_calendar/booking_calendar_state.dart';
import '../widgets/booking_calendar_widget.dart';
import '../widgets/booking_status_badge.dart';
import 'package:go_router/go_router.dart';
import 'booking_details_page.dart';

class BookingCalendarPage extends StatefulWidget {
  const BookingCalendarPage({super.key});

  @override
  State<BookingCalendarPage> createState() => _BookingCalendarPageState();
}

class _BookingCalendarPageState extends State<BookingCalendarPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  final DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarView _currentView = CalendarView.month;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadCalendarData();
    _animationController.forward();
  }

  void _loadCalendarData() {
    context.read<BookingCalendarBloc>().add(
          LoadCalendarBookingsEvent(
            month: _focusedDay,
            view: _currentView,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          _buildCalendarSection(),
          _buildSelectedDayBookings(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: AppTheme.darkBackground,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Text(
          'تقويم الحجوزات',
          style: AppTextStyles.heading1.copyWith(
            color: AppTheme.textWhite,
            shadows: [
              Shadow(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryBlue.withOpacity(0.1),
                AppTheme.darkBackground,
              ],
            ),
          ),
        ),
      ),
      actions: [
        _buildViewToggle(),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildViewToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          _buildViewButton(
            icon: CupertinoIcons.calendar,
            isSelected: _currentView == CalendarView.month,
            onTap: () => _changeView(CalendarView.month),
          ),
          _buildViewButton(
            icon: CupertinoIcons.calendar_today,
            isSelected: _currentView == CalendarView.week,
            onTap: () => _changeView(CalendarView.week),
          ),
          _buildViewButton(
            icon: CupertinoIcons.list_bullet,
            isSelected: _currentView == CalendarView.day,
            onTap: () => _changeView(CalendarView.day),
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected ? AppTheme.primaryBlue : AppTheme.textMuted,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildCalendarSection() {
    return SliverToBoxAdapter(
      child: BlocBuilder<BookingCalendarBloc, BookingCalendarState>(
        builder: (context, state) {
          if (state is BookingCalendarLoading) {
            return const SizedBox(
              height: 400,
              child: LoadingWidget(
                type: LoadingType.futuristic,
                message: 'جاري تحميل التقويم...',
              ),
            );
          }

          if (state is BookingCalendarError) {
            return SizedBox(
              height: 400,
              child: CustomErrorWidget(
                message: state.message,
                onRetry: _loadCalendarData,
              ),
            );
          }

          if (state is BookingCalendarLoaded) {
            return BookingCalendarWidget(
              calendarData: state.calendarData,
              currentMonth: state.currentMonth,
              currentView: state.currentView,
              selectedDate: state.selectedDate,
              onDateSelected: (date) {
                setState(() => _selectedDay = date);
                context.read<BookingCalendarBloc>().add(
                      SelectCalendarDateEvent(date: date),
                    );
              },
              onMonthChanged: (month) {
                context.read<BookingCalendarBloc>().add(
                      ChangeCalendarMonthEvent(month: month),
                    );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSelectedDayBookings() {
    return BlocBuilder<BookingCalendarBloc, BookingCalendarState>(
      builder: (context, state) {
        if (state is! BookingCalendarLoaded ||
            state.selectedDateBookings == null ||
            state.selectedDateBookings!.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.darkCard.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.darkBorder.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.calendar_today,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'حجوزات ${_formatDate(state.selectedDate!)}',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${state.selectedDateBookings!.length} حجز',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...state.selectedDateBookings!.map((booking) {
                  return _buildBookingCard(booking);
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToDetails(booking.id),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      booking.unitName.substring(0, 2).toUpperCase(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.unitName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.userName,
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                BookingStatusBadge(status: booking.status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _changeView(CalendarView view) {
    setState(() => _currentView = view);
    context.read<BookingCalendarBloc>().add(
          ChangeCalendarViewEvent(view: view),
        );
  }

  void _navigateToDetails(String bookingId) {
    context.push('/admin/bookings/$bookingId');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
