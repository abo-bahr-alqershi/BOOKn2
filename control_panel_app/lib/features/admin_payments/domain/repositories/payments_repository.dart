import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/models/paginated_result.dart';
import '../../../../../core/enums/payment_method_enum.dart';
import '../entities/payment.dart';
import '../entities/payment_details.dart';
import '../entities/payment_analytics.dart';
import '../entities/refund.dart';

/// 📦 Repository interface للمدفوعات
abstract class PaymentsRepository {
  // Commands
  /// استرداد دفعة
  Future<Either<Failure, bool>> refundPayment({
    required String paymentId,
    required Money refundAmount,
    required String refundReason,
  });

  /// إلغاء دفعة
  Future<Either<Failure, bool>> voidPayment({required String paymentId});

  /// تحديث حالة الدفعة
  Future<Either<Failure, bool>> updatePaymentStatus({
    required String paymentId,
    required PaymentStatus newStatus,
  });

  /// معالجة دفعة جديدة
  Future<Either<Failure, String>> processPayment({
    required String bookingId,
    required Money amount,
    required PaymentMethod method,
  });

  // Queries
  /// جلب دفعة بواسطة المعرف
  Future<Either<Failure, Payment>> getPaymentById({
    required String paymentId,
  });

  /// جلب تفاصيل الدفعة الكاملة
  Future<Either<Failure, PaymentDetails>> getPaymentDetails({
    required String paymentId,
  });

  /// جلب جميع المدفوعات مع الفلاتر
  Future<Either<Failure, PaginatedResult<Payment>>> getAllPayments({
    PaymentStatus? status,
    PaymentMethod? method,
    String? bookingId,
    String? userId,
    String? propertyId,
    String? unitId,
    double? minAmount,
    double? maxAmount,
    DateTime? startDate,
    DateTime? endDate,
    int? pageNumber,
    int? pageSize,
  });

  /// جلب المدفوعات حسب الحجز
  Future<Either<Failure, PaginatedResult<Payment>>> getPaymentsByBooking({
    required String bookingId,
    int? pageNumber,
    int? pageSize,
  });

  /// جلب المدفوعات حسب الحالة
  Future<Either<Failure, PaginatedResult<Payment>>> getPaymentsByStatus({
    required PaymentStatus status,
    int? pageNumber,
    int? pageSize,
  });

  /// جلب المدفوعات حسب المستخدم
  Future<Either<Failure, PaginatedResult<Payment>>> getPaymentsByUser({
    required String userId,
    int? pageNumber,
    int? pageSize,
  });

  /// جلب المدفوعات حسب طريقة الدفع
  Future<Either<Failure, PaginatedResult<Payment>>> getPaymentsByMethod({
    required PaymentMethod method,
    int? pageNumber,
    int? pageSize,
  });

  /// جلب المدفوعات حسب العقار
  Future<Either<Failure, PaginatedResult<Payment>>> getPaymentsByProperty({
    required String propertyId,
    DateTime? startDate,
    DateTime? endDate,
    int? pageNumber,
    int? pageSize,
  });

  // Analytics
  /// جلب تحليلات المدفوعات
  Future<Either<Failure, PaymentAnalytics>> getPaymentAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String? propertyId,
  });

  /// جلب تقرير الإيرادات
  Future<Either<Failure, Map<String, dynamic>>> getRevenueReport({
    required DateTime startDate,
    required DateTime endDate,
    String? propertyId,
  });

  /// جلب اتجاهات المدفوعات
  Future<Either<Failure, List<PaymentTrend>>> getPaymentTrends({
    required DateTime startDate,
    required DateTime endDate,
    String? propertyId,
  });

  /// جلب إحصائيات الاستردادات
  Future<Either<Failure, RefundAnalytics>> getRefundStatistics({
    DateTime? startDate,
    DateTime? endDate,
    String? propertyId,
  });
}
