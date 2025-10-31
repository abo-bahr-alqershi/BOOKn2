import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/booking.dart';
import '../../../domain/usecases/bookings/get_bookings_by_date_range_usecase.dart';
import '../../../domain/usecases/bookings/get_bookings_by_unit_usecase.dart';
import '../../../domain/usecases/bookings/get_bookings_by_property_usecase.dart';
import 'booking_calendar_event.dart';
import 'booking_calendar_state.dart';

class BookingCalendarBloc
    extends Bloc<BookingCalendarEvent, BookingCalendarState> {
  final GetBookingsByDateRangeUseCase getBookingsByDateRangeUseCase;
  final GetBookingsByUnitUseCase getBookingsByUnitUseCase;
  final GetBookingsByPropertyUseCase getBookingsByPropertyUseCase;

  DateTime _currentMonth = DateTime.now();
  String? _currentUnitId;
  String? _currentPropertyId;
  CalendarView _currentView = CalendarView.month;

  BookingCalendarBloc({
    required this.getBookingsByDateRangeUseCase,
    required this.getBookingsByUnitUseCase,
    required this.getBookingsByPropertyUseCase,
  }) : super(BookingCalendarInitial()) {
    on<LoadCalendarBookingsEvent>(_onLoadCalendarBookings);
    on<ChangeCalendarMonthEvent>(_onChangeCalendarMonth);
    on<ChangeCalendarViewEvent>(_onChangeCalendarView);
    on<SelectCalendarDateEvent>(_onSelectCalendarDate);
    on<SelectCalendarBookingEvent>(_onSelectCalendarBooking);
    on<FilterCalendarByUnitEvent>(_onFilterCalendarByUnit);
    on<FilterCalendarByPropertyEvent>(_onFilterCalendarByProperty);
    on<RefreshCalendarEvent>(_onRefreshCalendar);
    on<ToggleCalendarLegendEvent>(_onToggleCalendarLegend);
  }

  Future<void> _onLoadCalendarBookings(
    LoadCalendarBookingsEvent event,
    Emitter<BookingCalendarState> emit,
  ) async {
    emit(BookingCalendarLoading());

    _currentMonth = event.month;
    _currentView = event.view;

    // حساب نطاق التواريخ بناءً على العرض
    final dateRange = _calculateDateRange(event.month, event.view);

    final result = await getBookingsByDateRangeUseCase(
      GetBookingsByDateRangeParams(
        startDate: dateRange.start,
        endDate: dateRange.end,
        unitId: _currentUnitId,
        pageSize: 20, // جلب جميع الحجوزات للشهر
      ),
    );

    result.fold(
      (failure) => emit(BookingCalendarError(message: failure.message)),
      (bookings) {
        final calendarData = _processBookingsForCalendar(
          bookings.items,
          dateRange.start,
          dateRange.end,
        );

        emit(BookingCalendarLoaded(
          bookings: bookings.items,
          calendarData: calendarData,
          currentMonth: event.month,
          currentView: event.view,
          selectedDate: null,
          selectedBooking: null,
          showLegend: true,
        ));
      },
    );
  }

  Future<void> _onChangeCalendarMonth(
    ChangeCalendarMonthEvent event,
    Emitter<BookingCalendarState> emit,
  ) async {
    add(LoadCalendarBookingsEvent(
      month: event.month,
      view: _currentView,
    ));
  }

  Future<void> _onChangeCalendarView(
    ChangeCalendarViewEvent event,
    Emitter<BookingCalendarState> emit,
  ) async {
    add(LoadCalendarBookingsEvent(
      month: _currentMonth,
      view: event.view,
    ));
  }

  Future<void> _onSelectCalendarDate(
    SelectCalendarDateEvent event,
    Emitter<BookingCalendarState> emit,
  ) async {
    if (state is BookingCalendarLoaded) {
      final currentState = state as BookingCalendarLoaded;

      // جلب الحجوزات لليوم المحدد
      final dayBookings = currentState.bookings.where((booking) {
        return (booking.checkIn.isBefore(event.date) ||
                booking.checkIn.isAtSameMomentAs(event.date)) &&
            (booking.checkOut.isAfter(event.date) ||
                booking.checkOut.isAtSameMomentAs(event.date));
      }).toList();

      emit(currentState.copyWith(
        selectedDate: event.date,
        selectedDateBookings: dayBookings,
      ));
    }
  }

  Future<void> _onSelectCalendarBooking(
    SelectCalendarBookingEvent event,
    Emitter<BookingCalendarState> emit,
  ) async {
    if (state is BookingCalendarLoaded) {
      final currentState = state as BookingCalendarLoaded;
      final booking = currentState.bookings.firstWhere(
        (b) => b.id == event.bookingId,
      );

      emit(currentState.copyWith(selectedBooking: booking));
    }
  }

  Future<void> _onFilterCalendarByUnit(
    FilterCalendarByUnitEvent event,
    Emitter<BookingCalendarState> emit,
  ) async {
    _currentUnitId = event.unitId;
    add(LoadCalendarBookingsEvent(
      month: _currentMonth,
      view: _currentView,
    ));
  }

  Future<void> _onFilterCalendarByProperty(
    FilterCalendarByPropertyEvent event,
    Emitter<BookingCalendarState> emit,
  ) async {
    _currentPropertyId = event.propertyId;

    if (state is BookingCalendarLoaded) {
      final currentState = state as BookingCalendarLoaded;
      emit(BookingCalendarLoading());

      final dateRange = _calculateDateRange(_currentMonth, _currentView);

      final result = await getBookingsByPropertyUseCase(
        GetBookingsByPropertyParams(
          propertyId: event.propertyId,
          startDate: dateRange.start,
          endDate: dateRange.end,
          pageSize: 20,
        ),
      );

      result.fold(
        (failure) => emit(BookingCalendarError(message: failure.message)),
        (bookings) {
          final calendarData = _processBookingsForCalendar(
            bookings.items,
            dateRange.start,
            dateRange.end,
          );

          emit(BookingCalendarLoaded(
            bookings: bookings.items,
            calendarData: calendarData,
            currentMonth: _currentMonth,
            currentView: _currentView,
            selectedDate: currentState.selectedDate,
            selectedBooking: null,
            showLegend: currentState.showLegend,
          ));
        },
      );
    }
  }

  Future<void> _onRefreshCalendar(
    RefreshCalendarEvent event,
    Emitter<BookingCalendarState> emit,
  ) async {
    add(LoadCalendarBookingsEvent(
      month: _currentMonth,
      view: _currentView,
    ));
  }

  Future<void> _onToggleCalendarLegend(
    ToggleCalendarLegendEvent event,
    Emitter<BookingCalendarState> emit,
  ) async {
    if (state is BookingCalendarLoaded) {
      final currentState = state as BookingCalendarLoaded;
      emit(currentState.copyWith(showLegend: !currentState.showLegend));
    }
  }

  DateRange _calculateDateRange(DateTime month, CalendarView view) {
    DateTime start, end;

    switch (view) {
      case CalendarView.day:
        start = DateTime(month.year, month.month, month.day);
        end = start.add(const Duration(days: 1));
        break;
      case CalendarView.week:
        final weekday = month.weekday;
        start = month.subtract(Duration(days: weekday - 1));
        end = start.add(const Duration(days: 7));
        break;
      case CalendarView.month:
        start = DateTime(month.year, month.month, 1);
        end = DateTime(month.year, month.month + 1, 0);
        break;
      case CalendarView.year:
        start = DateTime(month.year, 1, 1);
        end = DateTime(month.year, 12, 31);
        break;
    }

    return DateRange(start: start, end: end);
  }

  Map<DateTime, List<CalendarEvent>> _processBookingsForCalendar(
    List<Booking> bookings,
    DateTime start,
    DateTime end,
  ) {
    final Map<DateTime, List<CalendarEvent>> calendarData = {};

    for (var booking in bookings) {
      // إضافة أحداث لكل يوم في نطاق الحجز
      DateTime currentDate = booking.checkIn;
      while (currentDate.isBefore(booking.checkOut) ||
          currentDate.isAtSameMomentAs(booking.checkOut)) {
        final dateKey = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
        );

        if (!calendarData.containsKey(dateKey)) {
          calendarData[dateKey] = [];
        }

        EventType eventType = EventType.stay;
        if (currentDate.isAtSameMomentAs(booking.checkIn)) {
          eventType = EventType.checkIn;
        } else if (currentDate.isAtSameMomentAs(booking.checkOut)) {
          eventType = EventType.checkOut;
        }

        calendarData[dateKey]!.add(CalendarEvent(
          bookingId: booking.id,
          title: '${booking.userName} - ${booking.unitName}',
          type: eventType,
          status: booking.status,
        ));

        currentDate = currentDate.add(const Duration(days: 1));
      }
    }

    return calendarData;
  }
}

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});
}
