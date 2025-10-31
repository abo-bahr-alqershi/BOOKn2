import 'package:equatable/equatable.dart';
import '../../../../../../core/enums/payment_method_enum.dart';
import '../../../domain/entities/payment.dart';

abstract class PaymentsListEvent extends Equatable {
  const PaymentsListEvent();

  @override
  List<Object?> get props => [];
}

/// 📥 حدث تحميل المدفوعات
class LoadPaymentsEvent extends PaymentsListEvent {
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
  final int pageNumber;
  final int pageSize;

  const LoadPaymentsEvent({
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
    this.pageNumber = 1,
    this.pageSize = 10,
  });

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
        pageNumber,
        pageSize,
      ];
}

/// 🔄 حدث تحديث قائمة المدفوعات
class RefreshPaymentsEvent extends PaymentsListEvent {
  const RefreshPaymentsEvent();
}

/// 💸 حدث استرداد دفعة
class RefundPaymentEvent extends PaymentsListEvent {
  final String paymentId;
  final Money refundAmount;
  final String refundReason;

  const RefundPaymentEvent({
    required this.paymentId,
    required this.refundAmount,
    required this.refundReason,
  });

  @override
  List<Object> get props => [paymentId, refundAmount, refundReason];
}

/// ❌ حدث إلغاء دفعة
class VoidPaymentEvent extends PaymentsListEvent {
  final String paymentId;

  const VoidPaymentEvent({required this.paymentId});

  @override
  List<Object> get props => [paymentId];
}

/// 🔄 حدث تحديث حالة الدفعة
class UpdatePaymentStatusEvent extends PaymentsListEvent {
  final String paymentId;
  final PaymentStatus newStatus;

  const UpdatePaymentStatusEvent({
    required this.paymentId,
    required this.newStatus,
  });

  @override
  List<Object> get props => [paymentId, newStatus];
}

/// 🔍 حدث البحث في المدفوعات
class SearchPaymentsEvent extends PaymentsListEvent {
  final String searchTerm;

  const SearchPaymentsEvent({required this.searchTerm});

  @override
  List<Object> get props => [searchTerm];
}

/// 🏷️ حدث تطبيق الفلاتر
class FilterPaymentsEvent extends PaymentsListEvent {
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

  const FilterPaymentsEvent({
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

/// 📑 حدث تغيير الصفحة
class ChangePageEvent extends PaymentsListEvent {
  final int pageNumber;

  const ChangePageEvent({required this.pageNumber});

  @override
  List<Object> get props => [pageNumber];
}

/// 🔢 حدث تغيير حجم الصفحة
class ChangePageSizeEvent extends PaymentsListEvent {
  final int pageSize;

  const ChangePageSizeEvent({required this.pageSize});

  @override
  List<Object> get props => [pageSize];
}

/// 🎯 حدث اختيار دفعة
class SelectPaymentEvent extends PaymentsListEvent {
  final String paymentId;

  const SelectPaymentEvent({required this.paymentId});

  @override
  List<Object> get props => [paymentId];
}

/// ❌ حدث إلغاء اختيار دفعة
class DeselectPaymentEvent extends PaymentsListEvent {
  final String paymentId;

  const DeselectPaymentEvent({required this.paymentId});

  @override
  List<Object> get props => [paymentId];
}

/// 📋 حدث اختيار دفعات متعددة
class SelectMultiplePaymentsEvent extends PaymentsListEvent {
  final List<String> paymentIds;

  const SelectMultiplePaymentsEvent({required this.paymentIds});

  @override
  List<Object> get props => [paymentIds];
}

/// 🧹 حدث مسح الاختيار
class ClearSelectionEvent extends PaymentsListEvent {
  const ClearSelectionEvent();
}

/// 📤 حدث تصدير المدفوعات
class ExportPaymentsEvent extends PaymentsListEvent {
  final ExportFormat format;

  const ExportPaymentsEvent({required this.format});

  @override
  List<Object> get props => [format];
}

/// صيغ التصدير
enum ExportFormat {
  pdf,
  excel,
  csv,
}
