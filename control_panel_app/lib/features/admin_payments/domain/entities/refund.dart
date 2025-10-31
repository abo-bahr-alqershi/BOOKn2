import 'package:equatable/equatable.dart';
import 'payment.dart';

/// 💸 Entity للاسترداد
class Refund extends Equatable {
  final String id;
  final String paymentId;
  final Money amount;
  final String reason;
  final RefundStatus status;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final String? transactionId;
  final String? processedBy;
  final String? notes;
  final RefundType? type;
  final Map<String, dynamic>? metadata;

  const Refund({
    required this.id,
    required this.paymentId,
    required this.amount,
    required this.reason,
    required this.status,
    required this.requestedAt,
    this.processedAt,
    this.transactionId,
    this.processedBy,
    this.notes,
    this.type,
    this.metadata,
  });

  /// التحقق من اكتمال الاسترداد
  bool get isCompleted => status == RefundStatus.completed;

  /// التحقق من قابلية الإلغاء
  bool get canCancel => status == RefundStatus.pending;

  Refund copyWith({
    String? id,
    String? paymentId,
    Money? amount,
    String? reason,
    RefundStatus? status,
    DateTime? requestedAt,
    DateTime? processedAt,
    String? transactionId,
    String? processedBy,
    String? notes,
    RefundType? type,
    Map<String, dynamic>? metadata,
  }) {
    return Refund(
      id: id ?? this.id,
      paymentId: paymentId ?? this.paymentId,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      processedAt: processedAt ?? this.processedAt,
      transactionId: transactionId ?? this.transactionId,
      processedBy: processedBy ?? this.processedBy,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        paymentId,
        amount,
        reason,
        status,
        requestedAt,
        processedAt,
        transactionId,
        processedBy,
        notes,
        type,
        metadata,
      ];
}

/// حالات الاسترداد
enum RefundStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

/// أنواع الاسترداد
enum RefundType {
  full,
  partial,
  cancellation,
  dispute,
  other,
}

extension RefundStatusExtension on RefundStatus {
  String get displayNameAr {
    switch (this) {
      case RefundStatus.pending:
        return 'معلق';
      case RefundStatus.processing:
        return 'قيد المعالجة';
      case RefundStatus.completed:
        return 'مكتمل';
      case RefundStatus.failed:
        return 'فاشل';
      case RefundStatus.cancelled:
        return 'ملغي';
    }
  }

  String get displayNameEn {
    switch (this) {
      case RefundStatus.pending:
        return 'Pending';
      case RefundStatus.processing:
        return 'Processing';
      case RefundStatus.completed:
        return 'Completed';
      case RefundStatus.failed:
        return 'Failed';
      case RefundStatus.cancelled:
        return 'Cancelled';
    }
  }
}

extension RefundTypeExtension on RefundType {
  String get displayNameAr {
    switch (this) {
      case RefundType.full:
        return 'استرداد كامل';
      case RefundType.partial:
        return 'استرداد جزئي';
      case RefundType.cancellation:
        return 'إلغاء';
      case RefundType.dispute:
        return 'نزاع';
      case RefundType.other:
        return 'أخرى';
    }
  }

  String get displayNameEn {
    switch (this) {
      case RefundType.full:
        return 'Full Refund';
      case RefundType.partial:
        return 'Partial Refund';
      case RefundType.cancellation:
        return 'Cancellation';
      case RefundType.dispute:
        return 'Dispute';
      case RefundType.other:
        return 'Other';
    }
  }
}
