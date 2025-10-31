// lib/features/admin_bookings/presentation/pages/booking_timeline_page.dart

import 'package:bookn_cp_app/features/admin_bookings/domain/entities/booking.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/date_utils.dart' as app_date;
import '../bloc/bookings_list/bookings_list_bloc.dart';
import '../bloc/bookings_list/bookings_list_event.dart';
import '../bloc/bookings_list/bookings_list_state.dart';
import '../widgets/booking_timeline_widget.dart';
import '../widgets/booking_status_badge.dart';
import 'package:go_router/go_router.dart';
import 'booking_details_page.dart';

class BookingTimelinePage extends StatefulWidget {
  const BookingTimelinePage({super.key});

  @override
  State<BookingTimelinePage> createState() => _BookingTimelinePageState();
}

class _BookingTimelinePageState extends State<BookingTimelinePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadBookings();
    _animationController.forward();
  }

  void _loadBookings() {
    context.read<BookingsListBloc>().add(
          LoadBookingsEvent(
            startDate: DateTime(
                _selectedDate.year, _selectedDate.month, _selectedDate.day),
            endDate: DateTime(_selectedDate.year, _selectedDate.month,
                _selectedDate.day, 23, 59, 59),
            pageNumber: 1,
            pageSize: 100,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          _buildDateSelector(),
          _buildTimelineContent(),
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
          'الخط الزمني',
          style: AppTextStyles.heading1.copyWith(
            color: AppTheme.textWhite,
            shadows: [
              Shadow(
                color: AppTheme.primaryViolet.withOpacity(0.3),
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
                AppTheme.primaryViolet.withOpacity(0.1),
                AppTheme.darkBackground,
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(CupertinoIcons.calendar),
          onPressed: _showDatePicker,
        ),
        IconButton(
          icon: const Icon(CupertinoIcons.arrow_2_circlepath),
          onPressed: _loadBookings,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDateSelector() {
    return SliverToBoxAdapter(
      child: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 7,
          itemBuilder: (context, index) {
            final date = DateTime.now().subtract(Duration(days: 3 - index));
            final isSelected =
                app_date.DateUtils.isSameDay(date, _selectedDate);
            final isToday = app_date.DateUtils.isSameDay(date, DateTime.now());

            return GestureDetector(
              onTap: () {
                setState(() => _selectedDate = date);
                _loadBookings();
              },
              child: Container(
                width: 70,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.primaryGradient : null,
                  color: isSelected ? null : AppTheme.darkCard.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : isToday
                            ? AppTheme.primaryBlue
                            : AppTheme.darkBorder.withOpacity(0.3),
                    width: isToday ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getDayName(date),
                      style: AppTextStyles.caption.copyWith(
                        color: isSelected ? Colors.white : AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date.day.toString(),
                      style: AppTextStyles.heading2.copyWith(
                        color: isSelected ? Colors.white : AppTheme.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getMonthName(date),
                      style: AppTextStyles.caption.copyWith(
                        color: isSelected
                            ? Colors.white.withOpacity(0.8)
                            : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimelineContent() {
    return BlocBuilder<BookingsListBloc, BookingsListState>(
      builder: (context, state) {
        if (state is BookingsListLoading) {
          return const SliverFillRemaining(
            child: LoadingWidget(
              type: LoadingType.futuristic,
              message: 'جاري تحميل الخط الزمني...',
            ),
          );
        }

        if (state is BookingsListError) {
          return SliverFillRemaining(
            child: CustomErrorWidget(
              message: state.message,
              onRetry: _loadBookings,
            ),
          );
        }

        if (state is BookingsListLoaded) {
          final bookings = _groupBookingsByTime(state.bookings.items);

          if (bookings.isEmpty) {
            return SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.calendar_badge_minus,
                      size: 80,
                      color: AppTheme.textMuted.withOpacity(0.3),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'لا توجد حجوزات',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'لا توجد حجوزات في ${_formatDate(_selectedDate)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final timeSlot = bookings.keys.elementAt(index);
                  final slotBookings = bookings[timeSlot]!;

                  return BookingTimelineWidget(
                    timeSlot: timeSlot,
                    bookings: slotBookings,
                    isFirst: index == 0,
                    isLast: index == bookings.length - 1,
                    onBookingTap: (bookingId) {
                      context.push('/admin/bookings/$bookingId');
                    },
                  );
                },
                childCount: bookings.length,
              ),
            ),
          );
        }

        return const SliverFillRemaining(child: SizedBox.shrink());
      },
    );
  }

  Map<String, List<Booking>> _groupBookingsByTime(List<Booking> bookings) {
    final Map<String, List<Booking>> grouped = {};

    for (final booking in bookings) {
      String timeKey;

      // Group by check-in time
      if (app_date.DateUtils.isSameDay(booking.checkIn, _selectedDate)) {
        timeKey = _formatTime(booking.checkIn);
        grouped.putIfAbsent(timeKey, () => []).add(booking);
      }

      // Group by check-out time
      if (app_date.DateUtils.isSameDay(booking.checkOut, _selectedDate)) {
        timeKey = _formatTime(booking.checkOut);
        grouped.putIfAbsent(timeKey, () => []).add(booking);
      }
    }

    // Sort by time
    final sortedKeys = grouped.keys.toList()..sort((a, b) => a.compareTo(b));

    final sortedMap = <String, List<Booking>>{};
    for (final key in sortedKeys) {
      sortedMap[key] = grouped[key]!;
    }

    return sortedMap;
  }

  String _getDayName(DateTime date) {
    const days = [
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت'
    ];
    return days[date.weekday % 7];
  }

  String _getMonthName(DateTime date) {
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
    return months[date.month - 1];
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date)} ${date.year}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              surface: AppTheme.darkCard,
              onSurface: AppTheme.textWhite,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadBookings();
    }
  }
}
