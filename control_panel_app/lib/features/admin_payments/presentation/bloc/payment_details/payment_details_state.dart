import 'package:equatable/equatable.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/payment_details.dart';
import '../../../domain/entities/refund.dart';

abstract class PaymentDetailsState extends Equatable {
  const PaymentDetailsState();

  @override
  List<Object?> get props => [];
}

/// 🎬 الحالة الابتدائية
class PaymentDetailsInitial extends PaymentDetailsState {}

/// ⏳ حالة التحميل
class PaymentDetailsLoading extends PaymentDetailsState {}

/// ✅ حالة نجاح التحميل
class PaymentDetailsLoaded extends PaymentDetailsState {
  final Payment payment;
  final PaymentDetails? paymentDetails;
  final List<Refund> refunds;
  final List<PaymentActivity> activities;
  final bool isRefreshing;

  const PaymentDetailsLoaded({
    required this.payment,
    this.paymentDetails,
    required this.refunds,
    required this.activities,
    this.isRefreshing = false,
  });

  PaymentDetailsLoaded copyWith({
    Payment? payment,
    PaymentDetails? paymentDetails,
    List<Refund>? refunds,
    List<PaymentActivity>? activities,
    bool? isRefreshing,
  }) {
    return PaymentDetailsLoaded(
      payment: payment ?? this.payment,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      refunds: refunds ?? this.refunds,
      activities: activities ?? this.activities,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  /// حساب المبلغ المسترد
  Money get totalRefunded {
    if (refunds.isEmpty) {
      return Money(
        amount: 0,
        currency: payment.amount.currency,
        formattedAmount: '${payment.amount.currency} 0.00',
      );
    }

    final total = refunds
        .where((r) => r.status == RefundStatus.completed)
        .fold(0.0, (sum, refund) => sum + refund.amount.amount);

    return Money(
      amount: total,
      currency: payment.amount.currency,
      formattedAmount: '${payment.amount.currency} ${total.toStringAsFixed(2)}',
    );
  }

  /// حساب المبلغ المتبقي
  Money get remainingAmount {
    return payment.amount - totalRefunded;
  }

  @override
  List<Object?> get props => [
        payment,
        paymentDetails,
        refunds,
        activities,
        isRefreshing,
      ];
}

/// ❌ حالة الخطأ
class PaymentDetailsError extends PaymentDetailsState {
  final String message;

  const PaymentDetailsError({required this.message});

  @override
  List<Object> get props => [message];
}

/// 🔄 حالة العملية الجارية
class PaymentDetailsOperationInProgress extends PaymentDetailsState {
  final Payment payment;
  final PaymentDetails? paymentDetails;
  final List<Refund> refunds;
  final List<PaymentActivity> activities;
  final String operation;

  const PaymentDetailsOperationInProgress({
    required this.payment,
    this.paymentDetails,
    required this.refunds,
    required this.activities,
    required this.operation,
  });

  @override
  List<Object?> get props => [
        payment,
        paymentDetails,
        refunds,
        activities,
        operation,
      ];
}

/// ✅ حالة نجاح العملية
class PaymentDetailsOperationSuccess extends PaymentDetailsState {
  final Payment payment;
  final PaymentDetails? paymentDetails;
  final List<Refund> refunds;
  final List<PaymentActivity> activities;
  final String message;

  const PaymentDetailsOperationSuccess({
    required this.payment,
    this.paymentDetails,
    required this.refunds,
    required this.activities,
    required this.message,
  });

  @override
  List<Object?> get props => [
        payment,
        paymentDetails,
        refunds,
        activities,
        message,
      ];
}

/// ❌ حالة فشل العملية
class PaymentDetailsOperationFailure extends PaymentDetailsState {
  final Payment payment;
  final PaymentDetails? paymentDetails;
  final List<Refund> refunds;
  final List<PaymentActivity> activities;
  final String message;

  const PaymentDetailsOperationFailure({
    required this.payment,
    this.paymentDetails,
    required this.refunds,
    required this.activities,
    required this.message,
  });

  @override
  List<Object?> get props => [
        payment,
        paymentDetails,
        refunds,
        activities,
        message,
      ];
}

/// 🖨️ حالة الطباعة
class PaymentDetailsPrinting extends PaymentDetailsState {
  final Payment payment;
  final PaymentDetails? paymentDetails;
  final List<Refund> refunds;
  final List<PaymentActivity> activities;

  const PaymentDetailsPrinting({
    required this.payment,
    this.paymentDetails,
    required this.refunds,
    required this.activities,
  });

  @override
  List<Object?> get props => [payment, paymentDetails, refunds, activities];
}

/// 📧 حالة الإرسال
class PaymentDetailsSending extends PaymentDetailsState {
  final Payment payment;
  final PaymentDetails? paymentDetails;
  final List<Refund> refunds;
  final List<PaymentActivity> activities;
  final String recipient;

  const PaymentDetailsSending({
    required this.payment,
    this.paymentDetails,
    required this.refunds,
    required this.activities,
    required this.recipient,
  });

  @override
  List<Object?> get props => [
        payment,
        paymentDetails,
        refunds,
        activities,
        recipient,
      ];
}

/// 📥 حالة التحميل
class PaymentDetailsDownloading extends PaymentDetailsState {
  final Payment payment;
  final PaymentDetails? paymentDetails;
  final List<Refund> refunds;
  final List<PaymentActivity> activities;

  const PaymentDetailsDownloading({
    required this.payment,
    this.paymentDetails,
    required this.refunds,
    required this.activities,
  });

  @override
  List<Object?> get props => [payment, paymentDetails, refunds, activities];
}
