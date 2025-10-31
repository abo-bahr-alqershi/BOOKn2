import 'package:equatable/equatable.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/refund.dart';

abstract class PaymentRefundEvent extends Equatable {
  const PaymentRefundEvent();

  @override
  List<Object?> get props => [];
}

/// 🎬 حدث تهيئة الاسترداد
class InitializeRefundEvent extends PaymentRefundEvent {
  final String paymentId;

  const InitializeRefundEvent({required this.paymentId});

  @override
  List<Object> get props => [paymentId];
}

/// 🧮 حدث حساب مبلغ الاسترداد
class CalculateRefundAmountEvent extends PaymentRefundEvent {
  final RefundType refundType;
  final Money? customAmount;

  const CalculateRefundAmountEvent({
    required this.refundType,
    this.customAmount,
  });

  @override
  List<Object?> get props => [refundType, customAmount];
}

/// ✅ حدث التحقق من صحة الاسترداد
class ValidateRefundEvent extends PaymentRefundEvent {
  const ValidateRefundEvent();
}

/// 💸 حدث معالجة الاسترداد
class ProcessRefundEvent extends PaymentRefundEvent {
  final String paymentId;
  final Money refundAmount;
  final String refundReason;

  const ProcessRefundEvent({
    required this.paymentId,
    required this.refundAmount,
    required this.refundReason,
  });

  @override
  List<Object> get props => [paymentId, refundAmount, refundReason];
}

/// 🔄 حدث تغيير نوع الاسترداد
class ChangeRefundTypeEvent extends PaymentRefundEvent {
  final RefundType refundType;

  const ChangeRefundTypeEvent({required this.refundType});

  @override
  List<Object> get props => [refundType];
}

/// 📝 حدث تحديث سبب الاسترداد
class UpdateRefundReasonEvent extends PaymentRefundEvent {
  final String reason;

  const UpdateRefundReasonEvent({required this.reason});

  @override
  List<Object> get props => [reason];
}

/// 📜 حدث تحميل تاريخ الاستردادات
class LoadRefundHistoryEvent extends PaymentRefundEvent {
  final String paymentId;

  const LoadRefundHistoryEvent({required this.paymentId});

  @override
  List<Object> get props => [paymentId];
}

/// ❌ حدث إلغاء الاسترداد
class CancelRefundEvent extends PaymentRefundEvent {
  const CancelRefundEvent();
}

/// 🔄 حدث إعادة محاولة الاسترداد
class RetryRefundEvent extends PaymentRefundEvent {
  const RetryRefundEvent();
}
