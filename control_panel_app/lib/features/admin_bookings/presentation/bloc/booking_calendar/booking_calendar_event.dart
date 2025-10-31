import 'package:equatable/equatable.dart';

abstract class BookingCalendarEvent extends Equatable {
  const BookingCalendarEvent();

  @override
  List<Object?> get props => [];
}

/// 📅 حدث تحميل حجوزات التقويم
class LoadCalendarBookingsEvent extends BookingCalendarEvent {
  final DateTime month;
  final CalendarView view;

  const LoadCalendarBookingsEvent({
    required this.month,
    this.view = CalendarView.month,
  });

  @override
  List<Object> get props => [month, view];
}

/// 📆 حدث تغيير الشهر
class ChangeCalendarMonthEvent extends BookingCalendarEvent {
  final DateTime month;

  const ChangeCalendarMonthEvent({required this.month});

  @override
  List<Object> get props => [month];
}

/// 👁️ حدث تغيير طريقة العرض
class ChangeCalendarViewEvent extends BookingCalendarEvent {
  final CalendarView view;

  const ChangeCalendarViewEvent({required this.view});

  @override
  List<Object> get props => [view];
}

/// 📍 حدث اختيار تاريخ
class SelectCalendarDateEvent extends BookingCalendarEvent {
  final DateTime date;

  const SelectCalendarDateEvent({required this.date});

  @override
  List<Object> get props => [date];
}

/// 🎯 حدث اختيار حجز
class SelectCalendarBookingEvent extends BookingCalendarEvent {
  final String bookingId;

  const SelectCalendarBookingEvent({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

/// 🏠 حدث فلترة حسب الوحدة
class FilterCalendarByUnitEvent extends BookingCalendarEvent {
  final String? unitId;

  const FilterCalendarByUnitEvent({this.unitId});

  @override
  List<Object?> get props => [unitId];
}

/// 🏢 حدث فلترة حسب العقار
class FilterCalendarByPropertyEvent extends BookingCalendarEvent {
  final String propertyId;

  const FilterCalendarByPropertyEvent({required this.propertyId});

  @override
  List<Object> get props => [propertyId];
}

/// 🔄 حدث تحديث التقويم
class RefreshCalendarEvent extends BookingCalendarEvent {
  const RefreshCalendarEvent();
}

/// 📋 حدث إظهار/إخفاء وسيلة الإيضاح
class ToggleCalendarLegendEvent extends BookingCalendarEvent {
  const ToggleCalendarLegendEvent();
}

/// طرق عرض التقويم
enum CalendarView {
  day,
  week,
  month,
  year,
}
