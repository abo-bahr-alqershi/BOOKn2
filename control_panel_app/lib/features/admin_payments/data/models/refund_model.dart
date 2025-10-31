import 'package:bookn_cp_app/features/admin_payments/domain/entities/payment.dart';

import '../../domain/entities/refund.dart';
import 'money_model.dart';

class RefundModel extends Refund {
  const RefundModel({
    required super.id,
    required super.paymentId,
    required super.amount,
    required super.reason,
    required super.status,
    required super.requestedAt,
    super.processedAt,
    super.transactionId,
    super.processedBy,
    super.notes,
    super.type,
    super.metadata,
  });

  factory RefundModel.fromJson(Map<String, dynamic> json) {
    return RefundModel(
      id: json['id']?.toString() ?? '',
      paymentId: json['paymentId']?.toString() ?? '',
      amount: MoneyModel.fromJson(json['amount'] ?? json['refundAmount']),
      reason: json['reason'] ?? json['refundReason'] ?? '',
      status: _parseRefundStatus(json['status']),
      requestedAt: DateTime.parse(json['requestedAt']),
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'])
          : null,
      transactionId: json['transactionId'],
      processedBy: json['processedBy'],
      notes: json['notes'],
      type: _parseRefundType(json['type']),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paymentId': paymentId,
      'amount': (amount as MoneyModel).toJson(),
      'reason': reason,
      'status': status.displayNameEn,
      'requestedAt': requestedAt.toIso8601String(),
      if (processedAt != null) 'processedAt': processedAt!.toIso8601String(),
      if (transactionId != null) 'transactionId': transactionId,
      if (processedBy != null) 'processedBy': processedBy,
      if (notes != null) 'notes': notes,
      if (type != null) 'type': type!.displayNameEn,
      if (metadata != null) 'metadata': metadata,
    };
  }

  static RefundStatus _parseRefundStatus(dynamic status) {
    if (status == null) return RefundStatus.pending;

    final statusStr = status.toString().toLowerCase();
    switch (statusStr) {
      case 'pending':
        return RefundStatus.pending;
      case 'processing':
        return RefundStatus.processing;
      case 'completed':
      case 'complete':
        return RefundStatus.completed;
      case 'failed':
        return RefundStatus.failed;
      case 'cancelled':
      case 'canceled':
        return RefundStatus.cancelled;
      default:
        return RefundStatus.pending;
    }
  }

  static RefundType? _parseRefundType(dynamic type) {
    if (type == null) return null;

    final typeStr = type.toString().toLowerCase();
    switch (typeStr) {
      case 'full':
        return RefundType.full;
      case 'partial':
        return RefundType.partial;
      case 'cancellation':
        return RefundType.cancellation;
      case 'dispute':
        return RefundType.dispute;
      case 'other':
        return RefundType.other;
      default:
        return RefundType.other;
    }
  }

  factory RefundModel.fromEntity(Refund entity) {
    return RefundModel(
      id: entity.id,
      paymentId: entity.paymentId,
      amount: entity.amount,
      reason: entity.reason,
      status: entity.status,
      requestedAt: entity.requestedAt,
      processedAt: entity.processedAt,
      transactionId: entity.transactionId,
      processedBy: entity.processedBy,
      notes: entity.notes,
      type: entity.type,
      metadata: entity.metadata,
    );
  }
}
