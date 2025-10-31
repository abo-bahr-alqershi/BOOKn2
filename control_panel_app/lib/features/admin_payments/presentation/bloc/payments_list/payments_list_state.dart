import 'package:equatable/equatable.dart';
import '../../../../../../core/models/paginated_result.dart';
import '../../../../../../core/enums/payment_method_enum.dart';
import '../../../domain/entities/payment.dart';
import 'payments_list_event.dart';

abstract class PaymentsListState extends Equatable {
  const PaymentsListState();

  @override
  List<Object?> get props => [];
}

/// 🎬 الحالة الابتدائية
class PaymentsListInitial extends PaymentsListState {}

/// ⏳ حالة التحميل
class PaymentsListLoading extends PaymentsListState {}

/// 🔄 حالة تحميل المزيد (Pagination)
class PaymentsListLoadingMore extends PaymentsListState {
  final PaginatedResult<Payment> payments;
  final List<Payment> selectedPayments;
  final PaymentFilters? filters;
  final Map<String, dynamic>? stats;

  const PaymentsListLoadingMore({
    required this.payments,
    this.selectedPayments = const [],
    this.filters,
    this.stats,
  });

  @override
  List<Object?> get props => [payments, selectedPayments, filters, stats];
}

/// ✅ حالة نجاح التحميل
class PaymentsListLoaded extends PaymentsListState {
  final PaginatedResult<Payment> payments;
  final List<Payment> selectedPayments;
  final PaymentFilters? filters;
  final Map<String, dynamic>? stats;

  const PaymentsListLoaded({
    required this.payments,
    this.selectedPayments = const [],
    this.filters,
    this.stats,
  });

  PaymentsListLoaded copyWith({
    PaginatedResult<Payment>? payments,
    List<Payment>? selectedPayments,
    PaymentFilters? filters,
    Map<String, dynamic>? stats,
  }) {
    return PaymentsListLoaded(
      payments: payments ?? this.payments,
      selectedPayments: selectedPayments ?? this.selectedPayments,
      filters: filters ?? this.filters,
      stats: stats ?? this.stats,
    );
  }

  /// حساب الإحصائيات
  Map<String, dynamic> get statistics {
    return {
      'totalPayments': payments.totalCount,
      'totalAmount': payments.items.fold(
        0.0,
        (sum, payment) => sum + payment.amount.amount,
      ),
      'successfulPayments': payments.items
          .where((p) => p.status == PaymentStatus.successful)
          .length,
      'pendingPayments':
          payments.items.where((p) => p.status == PaymentStatus.pending).length,
      'failedPayments':
          payments.items.where((p) => p.status == PaymentStatus.failed).length,
      'refundedPayments': payments.items
          .where((p) =>
              p.status == PaymentStatus.refunded ||
              p.status == PaymentStatus.partiallyRefunded)
          .length,
    };
  }

  @override
  List<Object?> get props => [payments, selectedPayments, filters, stats];
}

/// ❌ حالة الخطأ
class PaymentsListError extends PaymentsListState {
  final String message;

  const PaymentsListError({required this.message});

  @override
  List<Object> get props => [message];
}

/// 🔄 حالة العملية الجارية
class PaymentOperationInProgress extends PaymentsListState {
  final PaginatedResult<Payment> payments;
  final List<Payment> selectedPayments;
  final String operation;
  final String? paymentId;

  const PaymentOperationInProgress({
    required this.payments,
    required this.selectedPayments,
    required this.operation,
    this.paymentId,
  });

  @override
  List<Object?> get props => [payments, selectedPayments, operation, paymentId];
}

/// ✅ حالة نجاح العملية
class PaymentOperationSuccess extends PaymentsListState {
  final PaginatedResult<Payment> payments;
  final List<Payment> selectedPayments;
  final String message;
  final String? paymentId;

  const PaymentOperationSuccess({
    required this.payments,
    required this.selectedPayments,
    required this.message,
    this.paymentId,
  });

  @override
  List<Object?> get props => [payments, selectedPayments, message, paymentId];
}

/// ❌ حالة فشل العملية
class PaymentOperationFailure extends PaymentsListState {
  final PaginatedResult<Payment> payments;
  final List<Payment> selectedPayments;
  final String message;
  final String? paymentId;

  const PaymentOperationFailure({
    required this.payments,
    required this.selectedPayments,
    required this.message,
    this.paymentId,
  });

  @override
  List<Object?> get props => [payments, selectedPayments, message, paymentId];
}

/// 📤 حالة التصدير
class PaymentsExporting extends PaymentsListState {
  final PaginatedResult<Payment> payments;
  final List<Payment> selectedPayments;
  final ExportFormat format;

  const PaymentsExporting({
    required this.payments,
    required this.selectedPayments,
    required this.format,
  });

  @override
  List<Object> get props => [payments, selectedPayments, format];
}

/// ✅ حالة نجاح التصدير
class PaymentsExportSuccess extends PaymentsListState {
  final PaginatedResult<Payment> payments;
  final List<Payment> selectedPayments;
  final String message;

  const PaymentsExportSuccess({
    required this.payments,
    required this.selectedPayments,
    required this.message,
  });

  @override
  List<Object> get props => [payments, selectedPayments, message];
}

/// 📊 فلاتر المدفوعات
class PaymentFilters extends Equatable {
  final PaymentStatus? status;
  final PaymentMethod? method;
  final String? bookingId;
  final String? userId;
  final String? propertyId;
  final String? unitId;
  final double? minAmount;
  final double? maxAmount;
  final DateTime? startDate;
  final DateTime? endDate;

  const PaymentFilters({
    this.status,
    this.method,
    this.bookingId,
    this.userId,
    this.propertyId,
    this.unitId,
    this.minAmount,
    this.maxAmount,
    this.startDate,
    this.endDate,
  });

  PaymentFilters copyWith({
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
  }) {
    return PaymentFilters(
      status: status ?? this.status,
      method: method ?? this.method,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  List<Object?> get props => [
        status,
        method,
        bookingId,
        userId,
        propertyId,
        unitId,
        minAmount,
        maxAmount,
        startDate,
        endDate,
      ];
}
