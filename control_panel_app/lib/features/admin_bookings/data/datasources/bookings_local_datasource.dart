import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking_model.dart';

abstract class BookingsLocalDataSource {
  Future<void> cacheBookings(List<BookingModel> bookings);
  Future<List<BookingModel>> getCachedBookings();
  Future<void> cacheBookingDetails(String bookingId, BookingModel booking);
  Future<BookingModel?> getCachedBookingDetails(String bookingId);
  Future<void> clearCache();
}

class BookingsLocalDataSourceImpl implements BookingsLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const CACHED_BOOKINGS = 'CACHED_BOOKINGS';
  static const CACHED_BOOKING_PREFIX = 'CACHED_BOOKING_';

  BookingsLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheBookings(List<BookingModel> bookings) async {
    final jsonList = bookings.map((booking) => booking.toJson()).toList();
    await sharedPreferences.setString(
      CACHED_BOOKINGS,
      json.encode(jsonList),
    );
  }

  @override
  Future<List<BookingModel>> getCachedBookings() async {
    final jsonString = sharedPreferences.getString(CACHED_BOOKINGS);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => BookingModel.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<void> cacheBookingDetails(
      String bookingId, BookingModel booking) async {
    await sharedPreferences.setString(
      '$CACHED_BOOKING_PREFIX$bookingId',
      json.encode(booking.toJson()),
    );
  }

  @override
  Future<BookingModel?> getCachedBookingDetails(String bookingId) async {
    final jsonString = sharedPreferences.getString(
      '$CACHED_BOOKING_PREFIX$bookingId',
    );
    if (jsonString != null) {
      return BookingModel.fromJson(json.decode(jsonString));
    }
    return null;
  }

  @override
  Future<void> clearCache() async {
    await sharedPreferences.remove(CACHED_BOOKINGS);
    // Clear individual booking details
    final keys = sharedPreferences.getKeys();
    for (final key in keys) {
      if (key.startsWith(CACHED_BOOKING_PREFIX)) {
        await sharedPreferences.remove(key);
      }
    }
  }
}
