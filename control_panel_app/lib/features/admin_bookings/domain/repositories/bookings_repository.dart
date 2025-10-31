import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/models/paginated_result.dart';
import '../../../../../core/enums/booking_status.dart';
import '../entities/booking.dart';
import '../entities/booking_details.dart';
import '../entities/booking_report.dart';
import '../entities/booking_trends.dart';
import '../entities/booking_window_analysis.dart';
import '../usecases/register_booking_payment.dart';

/// 📦 Repository interface للحجوزات
abstract class BookingsRepository {
  // Commands
  /// إلغاء حجز
  Future<Either<Failure, bool>> cancelBooking({
    required String bookingId,
    required String cancellationReason,
    bool refundPayments = false,
  });

  /// تحديث بيانات الحجز
  Future<Either<Failure, bool>> updateBooking({
    required String bookingId,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guestsCount,
  });

  /// تأكيد الحجز
  Future<Either<Failure, bool>> confirmBooking({required String bookingId});

  /// تسجيل الوصول
  Future<Either<Failure, bool>> checkIn({required String bookingId});

  /// تسجيل المغادرة
  Future<Either<Failure, bool>> checkOut({required String bookingId});

  /// إكمال الحجز
  Future<Either<Failure, bool>> completeBooking({required String bookingId});

  /// تسجيل دفعة للحجز
  Future<Either<Failure, Payment>> registerBookingPayment(
    RegisterPaymentParams params,
  );

  // Services
  /// إضافة خدمة للحجز
  Future<Either<Failure, bool>> addServiceToBooking({
    required String bookingId,
    required String serviceId,
  });

  /// إزالة خدمة من الحجز
  Future<Either<Failure, bool>> removeServiceFromBooking({
    required String bookingId,
    required String serviceId,
  });

  /// جلب خدمات الحجز
  Future<Either<Failure, List<Service>>> getBookingServices({
    required String bookingId,
  });

  // Queries
  /// جلب حجز بواسطة المعرف
  Future<Either<Failure, Booking>> getBookingById({
    required String bookingId,
  });

  /// جلب تفاصيل الحجز الكاملة
  Future<Either<Failure, BookingDetails>> getBookingDetails({
    required String bookingId,
  });

  /// استعلام الحجوزات في نطاق زمني
  Future<Either<Failure, PaginatedResult<Booking>>> getBookingsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int? pageNumber,
    int? pageSize,
    String? userId,
    String? guestNameOrEmail,
    String? unitId,
    String? bookingSource,
    bool? isWalkIn,
    double? minTotalPrice,
    int? minGuestsCount,
    String? sortBy,
  });

  /// جلب الحجوزات حسب العقار
  Future<Either<Failure, PaginatedResult<Booking>>> getBookingsByProperty({
    required String propertyId,
    DateTime? startDate,
    DateTime? endDate,
    int? pageNumber,
    int? pageSize,
    BookingStatus? status,
    String? paymentStatus,
    String? guestNameOrEmail,
    String? bookingSource,
    bool? isWalkIn,
    double? minTotalPrice,
    int? minGuestsCount,
    String? sortBy,
  });

  /// جلب الحجوزات حسب الحالة
  Future<Either<Failure, PaginatedResult<Booking>>> getBookingsByStatus({
    required BookingStatus status,
    int? pageNumber,
    int? pageSize,
  });

  /// جلب الحجوزات حسب الوحدة
  Future<Either<Failure, PaginatedResult<Booking>>> getBookingsByUnit({
    required String unitId,
    DateTime? startDate,
    DateTime? endDate,
    int? pageNumber,
    int? pageSize,
  });

  /// جلب حجوزات المستخدم
  Future<Either<Failure, PaginatedResult<Booking>>> getBookingsByUser({
    required String userId,
    int? pageNumber,
    int? pageSize,
    BookingStatus? status,
    String? guestNameOrEmail,
    String? unitId,
    String? bookingSource,
    bool? isWalkIn,
    double? minTotalPrice,
    int? minGuestsCount,
    String? sortBy,
  });

  // Reports
  /// جلب تقرير الحجوزات
  Future<Either<Failure, BookingReport>> getBookingReport({
    required DateTime startDate,
    required DateTime endDate,
    String? propertyId,
  });

  /// جلب اتجاهات الحجوزات
  Future<Either<Failure, BookingTrends>> getBookingTrends({
    String? propertyId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// جلب تحليل نافذة الحجز
  Future<Either<Failure, BookingWindowAnalysis>> getBookingWindowAnalysis({
    required String propertyId,
  });
}
