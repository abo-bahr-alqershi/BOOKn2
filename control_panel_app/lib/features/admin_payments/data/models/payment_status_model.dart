import '../../../../../core/enums/payment_method_enum.dart';

/// Model لحالة الدفع مع الإحصائيات
class PaymentStatusModel {
  final PaymentStatus status;
  final int count;
  final double percentage;
  final double totalAmount;
  final String color;

  PaymentStatusModel({
    required this.status,
    required this.count,
    required this.percentage,
    required this.totalAmount,
    required this.color,
  });

  factory PaymentStatusModel.fromJson(Map<String, dynamic> json) {
    return PaymentStatusModel(
      status: _parseStatus(json['status']),
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      color: json['color'] ?? '#000000',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.backendKey,
      'count': count,
      'percentage': percentage,
      'totalAmount': totalAmount,
      'color': color,
    };
  }

  static PaymentStatus _parseStatus(dynamic status) {
    if (status == null) return PaymentStatus.pending;

    final statusStr = status.toString().toLowerCase();
    switch (statusStr) {
      case 'successful':
      case 'success':
        return PaymentStatus.successful;
      case 'failed':
        return PaymentStatus.failed;
      case 'pending':
        return PaymentStatus.pending;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'voided':
        return PaymentStatus.voided;
      case 'partiallyrefunded':
      case 'partially_refunded':
        return PaymentStatus.partiallyRefunded;
      default:
        return PaymentStatus.pending;
    }
  }
}
