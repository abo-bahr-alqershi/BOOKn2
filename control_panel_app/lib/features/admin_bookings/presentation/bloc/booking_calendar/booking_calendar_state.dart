import 'package:equatable/equatable.dart';
import '../../../../../../core/enums/booking_status.dart';
import '../../../domain/entities/booking.dart';
import 'booking_calendar_event.dart';

abstract class BookingCalendarState extends Equatable {
  const BookingCalendarState();

  @override
  List<Object?> get props => [];
}

/// 🎬 الحالة الابتدائية
class BookingCalendarInitial extends BookingCalendarState {}

/// ⏳ حالة التحميل
class BookingCalendarLoading extends BookingCalendarState {}

/// ✅ حالة نجاح التحميل
class BookingCalendarLoaded extends BookingCalendarState {
  final List<Booking> bookings;
  final Map<DateTime, List<CalendarEvent>> calendarData;
  final DateTime currentMonth;
  final CalendarView currentView;
  final DateTime? selectedDate;
  final List<Booking>? selectedDateBookings;
  final Booking? selectedBooking;
  final bool showLegend;

  const BookingCalendarLoaded({
    required this.bookings,
    required this.calendarData,
    required this.currentMonth,
    required this.currentView,
    this.selectedDate,
    this.selectedDateBookings,
    this.selectedBooking,
    this.showLegend = true,
  });

  BookingCalendarLoaded copyWith({
    List<Booking>? bookings,
    Map<DateTime, List<CalendarEvent>>? calendarData,
    DateTime? currentMonth,
    CalendarView? currentView,
    DateTime? selectedDate,
    List<Booking>? selectedDateBookings,
    Booking? selectedBooking,
    bool? showLegend,
  }) {
    return BookingCalendarLoaded(
      bookings: bookings ?? this.bookings,
      calendarData: calendarData ?? this.calendarData,
      currentMonth: currentMonth ?? this.currentMonth,
      currentView: currentView ?? this.currentView,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedDateBookings: selectedDateBookings ?? this.selectedDateBookings,
      selectedBooking: selectedBooking ?? this.selectedBooking,
      showLegend: showLegend ?? this.showLegend,
    );
  }

  /// حساب إحصائيات الشهر
  MonthStatistics get monthStatistics {
    int totalBookings = 0;
    int checkIns = 0;
    int checkOuts = 0;
    double totalRevenue = 0;

    calendarData.forEach((date, events) {
      for (var event in events) {
        if (event.type == EventType.checkIn) checkIns++;
        if (event.type == EventType.checkOut) checkOuts++;
        totalBookings++;

        // حساب الإيرادات
        final booking = bookings.firstWhere((b) => b.id == event.bookingId);
        if (event.type == EventType.checkIn) {
          totalRevenue += booking.totalPrice.amount;
        }
      }
    });

    return MonthStatistics(
      totalBookings: bookings.length,
      checkIns: checkIns,
      checkOuts: checkOuts,
      totalRevenue: totalRevenue,
      occupancyRate: _calculateOccupancyRate(),
    );
  }

  double _calculateOccupancyRate() {
    if (bookings.isEmpty) return 0;

    int totalDays = 0;
    int occupiedDays = 0;

    final daysInMonth =
        DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    totalDays = daysInMonth;

    calendarData.forEach((date, events) {
      if (events.isNotEmpty) occupiedDays++;
    });

    return (occupiedDays / totalDays) * 100;
  }

  @override
  List<Object?> get props => [
        bookings,
        calendarData,
        currentMonth,
        currentView,
        selectedDate,
        selectedDateBookings,
        selectedBooking,
        showLegend,
      ];
}

/// ❌ حالة الخطأ
class BookingCalendarError extends BookingCalendarState {
  final String message;

  const BookingCalendarError({required this.message});

  @override
  List<Object> get props => [message];
}

/// 📅 حدث التقويم
class CalendarEvent extends Equatable {
  final String bookingId;
  final String title;
  final EventType type;
  final BookingStatus status;

  const CalendarEvent({
    required this.bookingId,
    required this.title,
    required this.type,
    required this.status,
  });

  @override
  List<Object> get props => [bookingId, title, type, status];
}

/// نوع الحدث في التقويم
enum EventType {
  checkIn,
  checkOut,
  stay,
}

/// إحصائيات الشهر
class MonthStatistics extends Equatable {
  final int totalBookings;
  final int checkIns;
  final int checkOuts;
  final double totalRevenue;
  final double occupancyRate;

  const MonthStatistics({
    required this.totalBookings,
    required this.checkIns,
    required this.checkOuts,
    required this.totalRevenue,
    required this.occupancyRate,
  });

  @override
  List<Object> get props => [
        totalBookings,
        checkIns,
        checkOuts,
        totalRevenue,
        occupancyRate,
      ];
}
