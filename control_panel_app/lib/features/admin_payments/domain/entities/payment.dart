import 'package:equatable/equatable.dart';
import '../../../../../core/enums/payment_method_enum.dart';

/// 💳 Entity للدفعة
class Payment extends Equatable {
  final String id;
  final String bookingId;
  final Money amount;
  final String transactionId;
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime paymentDate;

  // معلومات إضافية
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String? unitId;
  final String? unitName;
  final String? propertyId;
  final String? propertyName;
  final String? description;
  final String? notes;
  final String? receiptUrl;
  final String? invoiceNumber;
  final Map<String, dynamic>? metadata;

  // معلومات الاسترداد
  final bool? isRefundable;
  final DateTime? refundDeadline;
  final double? refundedAmount;
  final DateTime? refundedAt;
  final String? refundReason;
  final String? refundTransactionId;

  // معلومات الإلغاء
  final bool? isVoided;
  final DateTime? voidedAt;
  final String? voidReason;

  const Payment({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.transactionId,
    required this.method,
    required this.status,
    required this.paymentDate,
    this.userId,
    this.userName,
    this.userEmail,
    this.unitId,
    this.unitName,
    this.propertyId,
    this.propertyName,
    this.description,
    this.notes,
    this.receiptUrl,
    this.invoiceNumber,
    this.metadata,
    this.isRefundable,
    this.refundDeadline,
    this.refundedAmount,
    this.refundedAt,
    this.refundReason,
    this.refundTransactionId,
    this.isVoided,
    this.voidedAt,
    this.voidReason,
  });

  /// التحقق من إمكانية الاسترداد
  bool get canRefund {
    if (status != PaymentStatus.successful) return false;
    if (isVoided == true) return false;
    if (refundedAmount != null && refundedAmount! >= amount.amount)
      return false;
    if (refundDeadline != null && DateTime.now().isAfter(refundDeadline!))
      return false;
    return isRefundable ?? true;
  }

  /// التحقق من إمكانية الإلغاء
  bool get canVoid {
    if (status != PaymentStatus.pending) return false;
    if (isVoided == true) return false;
    return true;
  }

  /// حساب المبلغ المتبقي للاسترداد
  double get remainingRefundableAmount {
    if (!canRefund) return 0;
    return amount.amount - (refundedAmount ?? 0);
  }

  Payment copyWith({
    String? id,
    String? bookingId,
    Money? amount,
    String? transactionId,
    PaymentMethod? method,
    PaymentStatus? status,
    DateTime? paymentDate,
    String? userId,
    String? userName,
    String? userEmail,
    String? unitId,
    String? unitName,
    String? propertyId,
    String? propertyName,
    String? description,
    String? notes,
    String? receiptUrl,
    String? invoiceNumber,
    Map<String, dynamic>? metadata,
    bool? isRefundable,
    DateTime? refundDeadline,
    double? refundedAmount,
    DateTime? refundedAt,
    String? refundReason,
    String? refundTransactionId,
    bool? isVoided,
    DateTime? voidedAt,
    String? voidReason,
  }) {
    return Payment(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      amount: amount ?? this.amount,
      transactionId: transactionId ?? this.transactionId,
      method: method ?? this.method,
      status: status ?? this.status,
      paymentDate: paymentDate ?? this.paymentDate,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      metadata: metadata ?? this.metadata,
      isRefundable: isRefundable ?? this.isRefundable,
      refundDeadline: refundDeadline ?? this.refundDeadline,
      refundedAmount: refundedAmount ?? this.refundedAmount,
      refundedAt: refundedAt ?? this.refundedAt,
      refundReason: refundReason ?? this.refundReason,
      refundTransactionId: refundTransactionId ?? this.refundTransactionId,
      isVoided: isVoided ?? this.isVoided,
      voidedAt: voidedAt ?? this.voidedAt,
      voidReason: voidReason ?? this.voidReason,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookingId,
        amount,
        transactionId,
        method,
        status,
        paymentDate,
        userId,
        userName,
        userEmail,
        unitId,
        unitName,
        propertyId,
        propertyName,
        description,
        notes,
        receiptUrl,
        invoiceNumber,
        metadata,
        isRefundable,
        refundDeadline,
        refundedAmount,
        refundedAt,
        refundReason,
        refundTransactionId,
        isVoided,
        voidedAt,
        voidReason,
      ];
}

/// 💰 Entity للمبلغ المالي
class Money extends Equatable {
  final double amount;
  final String currency;
  final String formattedAmount;

  const Money({
    required this.amount,
    required this.currency,
    required this.formattedAmount,
  });

  Money copyWith({
    double? amount,
    String? currency,
    String? formattedAmount,
  }) {
    return Money(
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      formattedAmount: formattedAmount ?? this.formattedAmount,
    );
  }

  /// عمليات حسابية
  Money operator +(Money other) {
    if (currency != other.currency) {
      throw Exception('Cannot add amounts with different currencies');
    }
    final newAmount = amount + other.amount;
    return Money(
      amount: newAmount,
      currency: currency,
      formattedAmount: _formatAmount(newAmount, currency),
    );
  }

  Money operator -(Money other) {
    if (currency != other.currency) {
      throw Exception('Cannot subtract amounts with different currencies');
    }
    final newAmount = amount - other.amount;
    return Money(
      amount: newAmount,
      currency: currency,
      formattedAmount: _formatAmount(newAmount, currency),
    );
  }

  Money operator *(double multiplier) {
    final newAmount = amount * multiplier;
    return Money(
      amount: newAmount,
      currency: currency,
      formattedAmount: _formatAmount(newAmount, currency),
    );
  }

  String _formatAmount(double amount, String currency) {
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  @override
  List<Object> get props => [amount, currency, formattedAmount];
}

