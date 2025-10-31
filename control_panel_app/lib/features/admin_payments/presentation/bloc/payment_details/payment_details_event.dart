import 'package:equatable/equatable.dart';
import '../../../../../../core/enums/payment_method_enum.dart';
import '../../../domain/entities/payment.dart';

abstract class PaymentDetailsEvent extends Equatable {
  const PaymentDetailsEvent();

  @override
  List<Object?> get props => [];
}

/// 📥 حدث تحميل تفاصيل الدفعة
class LoadPaymentDetailsEvent extends PaymentDetailsEvent {
  final String paymentId;

  const LoadPaymentDetailsEvent({required this.paymentId});

  @override
  List<Object> get props => [paymentId];
}

/// 🔄 حدث تحديث تفاصيل الدفعة
class RefreshPaymentDetailsEvent extends PaymentDetailsEvent {
  const RefreshPaymentDetailsEvent();
}

/// 💸 حدث استرداد المبلغ
class RefundPaymentDetailsEvent extends PaymentDetailsEvent {
  final String paymentId;
  final Money refundAmount;
  final String refundReason;

  const RefundPaymentDetailsEvent({
    required this.paymentId,
    required this.refundAmount,
    required this.refundReason,
  });

  @override
  List<Object> get props => [paymentId, refundAmount, refundReason];
}

/// ❌ حدث إلغاء الدفعة
class VoidPaymentDetailsEvent extends PaymentDetailsEvent {
  final String paymentId;

  const VoidPaymentDetailsEvent({required this.paymentId});

  @override
  List<Object> get props => [paymentId];
}

/// 🔄 حدث تحديث حالة الدفعة
class UpdatePaymentStatusDetailsEvent extends PaymentDetailsEvent {
  final String paymentId;
  final PaymentStatus newStatus;

  const UpdatePaymentStatusDetailsEvent({
    required this.paymentId,
    required this.newStatus,
  });

  @override
  List<Object> get props => [paymentId, newStatus];
}

/// 📝 حدث تحميل أنشطة الدفعة
class LoadPaymentActivitiesEvent extends PaymentDetailsEvent {
  final String paymentId;

  const LoadPaymentActivitiesEvent({required this.paymentId});

  @override
  List<Object> get props => [paymentId];
}

/// 💸 حدث تحميل تاريخ الاستردادات
class LoadRefundHistoryEvent extends PaymentDetailsEvent {
  final String paymentId;

  const LoadRefundHistoryEvent({required this.paymentId});

  @override
  List<Object> get props => [paymentId];
}

/// 🖨️ حدث طباعة الإيصال
class PrintReceiptEvent extends PaymentDetailsEvent {
  final String paymentId;

  const PrintReceiptEvent({required this.paymentId});

  @override
  List<Object> get props => [paymentId];
}

/// 📧 حدث إرسال الإيصال
class SendReceiptEvent extends PaymentDetailsEvent {
  final String paymentId;
  final String? email;
  final String? phone;

  const SendReceiptEvent({
    required this.paymentId,
    this.email,
    this.phone,
  });

  @override
  List<Object?> get props => [paymentId, email, phone];
}

/// 📥 حدث تحميل الفاتورة
class DownloadInvoiceEvent extends PaymentDetailsEvent {
  final String paymentId;

  const DownloadInvoiceEvent({required this.paymentId});

  @override
  List<Object> get props => [paymentId];
}

/// 📝 حدث إضافة ملاحظة
class AddNoteEvent extends PaymentDetailsEvent {
  final String paymentId;
  final String note;

  const AddNoteEvent({
    required this.paymentId,
    required this.note,
  });

  @override
  List<Object> get props => [paymentId, note];
}

/// 🔔 حدث إعادة إرسال الإشعار
class ResendNotificationEvent extends PaymentDetailsEvent {
  final String paymentId;

  const ResendNotificationEvent({required this.paymentId});

  @override
  List<Object> get props => [paymentId];
}
