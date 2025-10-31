import 'package:bookn_cp_app/core/enums/payment_method_enum.dart';
import 'package:equatable/equatable.dart';
import 'payment.dart';

/// 📊 Entity لتحليلات المدفوعات
class PaymentAnalytics extends Equatable {
  final PaymentSummary summary;
  final List<PaymentTrend> trends;
  final Map<PaymentMethod, MethodAnalytics> methodAnalytics;
  final Map<PaymentStatus, StatusAnalytics> statusAnalytics;
  final RefundAnalytics refundAnalytics;
  final DateTime startDate;
  final DateTime endDate;

  const PaymentAnalytics({
    required this.summary,
    required this.trends,
    required this.methodAnalytics,
    required this.statusAnalytics,
    required this.refundAnalytics,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [
        summary,
        trends,
        methodAnalytics,
        statusAnalytics,
        refundAnalytics,
        startDate,
        endDate,
      ];
}

/// 📈 ملخص المدفوعات
class PaymentSummary extends Equatable {
  final int totalTransactions;
  final Money totalAmount;
  final Money averageTransactionValue;
  final double successRate;
  final int successfulTransactions;
  final int failedTransactions;
  final int pendingTransactions;
  final Money totalRefunded;
  final int refundCount;

  const PaymentSummary({
    required this.totalTransactions,
    required this.totalAmount,
    required this.averageTransactionValue,
    required this.successRate,
    required this.successfulTransactions,
    required this.failedTransactions,
    required this.pendingTransactions,
    required this.totalRefunded,
    required this.refundCount,
  });

  @override
  List<Object> get props => [
        totalTransactions,
        totalAmount,
        averageTransactionValue,
        successRate,
        successfulTransactions,
        failedTransactions,
        pendingTransactions,
        totalRefunded,
        refundCount,
      ];
}

/// 📊 اتجاه المدفوعات
class PaymentTrend extends Equatable {
  final DateTime date;
  final int transactionCount;
  final Money totalAmount;
  final double successRate;
  final Map<PaymentMethod, int> methodBreakdown;

  const PaymentTrend({
    required this.date,
    required this.transactionCount,
    required this.totalAmount,
    required this.successRate,
    required this.methodBreakdown,
  });

  @override
  List<Object> get props => [
        date,
        transactionCount,
        totalAmount,
        successRate,
        methodBreakdown,
      ];
}

/// 📊 تحليلات طريقة الدفع
class MethodAnalytics extends Equatable {
  final PaymentMethod method;
  final int transactionCount;
  final Money totalAmount;
  final double percentage;
  final double successRate;
  final Money averageAmount;

  const MethodAnalytics({
    required this.method,
    required this.transactionCount,
    required this.totalAmount,
    required this.percentage,
    required this.successRate,
    required this.averageAmount,
  });

  @override
  List<Object> get props => [
        method,
        transactionCount,
        totalAmount,
        percentage,
        successRate,
        averageAmount,
      ];
}

/// 📊 تحليلات حالة الدفع
class StatusAnalytics extends Equatable {
  final PaymentStatus status;
  final int count;
  final Money totalAmount;
  final double percentage;

  const StatusAnalytics({
    required this.status,
    required this.count,
    required this.totalAmount,
    required this.percentage,
  });

  @override
  List<Object> get props => [status, count, totalAmount, percentage];
}

/// 💸 تحليلات الاسترداد
class RefundAnalytics extends Equatable {
  final int totalRefunds;
  final Money totalRefundedAmount;
  final double refundRate;
  final double averageRefundTime;
  final Map<String, int> refundReasons;
  final List<RefundTrend> trends;

  const RefundAnalytics({
    required this.totalRefunds,
    required this.totalRefundedAmount,
    required this.refundRate,
    required this.averageRefundTime,
    required this.refundReasons,
    required this.trends,
  });

  @override
  List<Object> get props => [
        totalRefunds,
        totalRefundedAmount,
        refundRate,
        averageRefundTime,
        refundReasons,
        trends,
      ];
}

/// 📈 اتجاه الاسترداد
class RefundTrend extends Equatable {
  final DateTime date;
  final int refundCount;
  final Money refundedAmount;

  const RefundTrend({
    required this.date,
    required this.refundCount,
    required this.refundedAmount,
  });

  @override
  List<Object> get props => [date, refundCount, refundedAmount];
}
