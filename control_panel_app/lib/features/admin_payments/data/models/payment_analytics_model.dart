import 'package:bookn_cp_app/core/enums/payment_method_enum.dart';

import '../../domain/entities/payment.dart' hide PaymentStatusExtension;
import '../../domain/entities/payment_analytics.dart';
import 'money_model.dart';

class PaymentAnalyticsModel extends PaymentAnalytics {
  const PaymentAnalyticsModel({
    required super.summary,
    required super.trends,
    required super.methodAnalytics,
    required super.statusAnalytics,
    required super.refundAnalytics,
    required super.startDate,
    required super.endDate,
  });

  factory PaymentAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return PaymentAnalyticsModel(
      summary: PaymentSummaryModel.fromJson(json['summary'] ?? {}),
      trends: (json['trends'] as List? ?? [])
          .map((t) => PaymentTrendModel.fromJson(t))
          .toList(),
      methodAnalytics: _parseMethodAnalytics(json['methodAnalytics']),
      statusAnalytics: _parseStatusAnalytics(json['statusAnalytics']),
      refundAnalytics:
          RefundAnalyticsModel.fromJson(json['refundAnalytics'] ?? {}),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
    );
  }

  static Map<PaymentMethod, MethodAnalytics> _parseMethodAnalytics(
      dynamic data) {
    final Map<PaymentMethod, MethodAnalytics> result = {};
    if (data is Map) {
      data.forEach((key, value) {
        final method = PaymentMethodExtension.fromString(key.toString());
        result[method] = MethodAnalyticsModel.fromJson(value);
      });
    }
    return result;
  }

  static Map<PaymentStatus, StatusAnalytics> _parseStatusAnalytics(
      dynamic data) {
    final Map<PaymentStatus, StatusAnalytics> result = {};
    if (data is Map) {
      data.forEach((key, value) {
        final status = PaymentStatusExtension.fromString(key.toString());
        result[status] = StatusAnalyticsModel.fromJson(value);
      });
    }
    return result;
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': (summary as PaymentSummaryModel).toJson(),
      'trends': trends.map((t) => (t as PaymentTrendModel).toJson()).toList(),
      'methodAnalytics': methodAnalytics.map(
        (k, v) => MapEntry(k.backendValue.toString(),
            (v as MethodAnalyticsModel).toJson()),
      ),
      'statusAnalytics': statusAnalytics.map(
        (k, v) => MapEntry(
            k.backendKey, (v as StatusAnalyticsModel).toJson()),
      ),
      'refundAnalytics': (refundAnalytics as RefundAnalyticsModel).toJson(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }
}

class PaymentSummaryModel extends PaymentSummary {
  const PaymentSummaryModel({
    required super.totalTransactions,
    required super.totalAmount,
    required super.averageTransactionValue,
    required super.successRate,
    required super.successfulTransactions,
    required super.failedTransactions,
    required super.pendingTransactions,
    required super.totalRefunded,
    required super.refundCount,
  });

  factory PaymentSummaryModel.fromJson(Map<String, dynamic> json) {
    return PaymentSummaryModel(
      totalTransactions: json['totalTransactions'] ?? 0,
      totalAmount: MoneyModel.fromJson(json['totalAmount'] ?? {}),
      averageTransactionValue:
          MoneyModel.fromJson(json['averageTransactionValue'] ?? {}),
      successRate: (json['successRate'] ?? 0).toDouble(),
      successfulTransactions: json['successfulTransactions'] ?? 0,
      failedTransactions: json['failedTransactions'] ?? 0,
      pendingTransactions: json['pendingTransactions'] ?? 0,
      totalRefunded: MoneyModel.fromJson(json['totalRefunded'] ?? {}),
      refundCount: json['refundCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTransactions': totalTransactions,
      'totalAmount': (totalAmount as MoneyModel).toJson(),
      'averageTransactionValue':
          (averageTransactionValue as MoneyModel).toJson(),
      'successRate': successRate,
      'successfulTransactions': successfulTransactions,
      'failedTransactions': failedTransactions,
      'pendingTransactions': pendingTransactions,
      'totalRefunded': (totalRefunded as MoneyModel).toJson(),
      'refundCount': refundCount,
    };
  }
}

class PaymentTrendModel extends PaymentTrend {
  const PaymentTrendModel({
    required super.date,
    required super.transactionCount,
    required super.totalAmount,
    required super.successRate,
    required super.methodBreakdown,
  });

  factory PaymentTrendModel.fromJson(Map<String, dynamic> json) {
    return PaymentTrendModel(
      date: DateTime.parse(json['date']),
      transactionCount: json['transactionCount'] ?? 0,
      totalAmount: MoneyModel.fromJson(json['totalAmount'] ?? {}),
      successRate: (json['successRate'] ?? 0).toDouble(),
      methodBreakdown: _parseMethodBreakdown(json['methodBreakdown']),
    );
  }

  static Map<PaymentMethod, int> _parseMethodBreakdown(dynamic data) {
    final Map<PaymentMethod, int> result = {};
    if (data is Map) {
      data.forEach((key, value) {
        final method = PaymentMethodExtension.fromString(key.toString());
        result[method] = value as int;
      });
    }
    return result;
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'transactionCount': transactionCount,
      'totalAmount': (totalAmount as MoneyModel).toJson(),
      'successRate': successRate,
      'methodBreakdown': methodBreakdown.map(
        (k, v) => MapEntry(k.displayNameEn, v),
      ),
    };
  }
}

class MethodAnalyticsModel extends MethodAnalytics {
  const MethodAnalyticsModel({
    required super.method,
    required super.transactionCount,
    required super.totalAmount,
    required super.percentage,
    required super.successRate,
    required super.averageAmount,
  });

  factory MethodAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return MethodAnalyticsModel(
      method: PaymentMethodExtension.fromString(json['method'] ?? 'cash'),
      transactionCount: json['transactionCount'] ?? 0,
      totalAmount: MoneyModel.fromJson(json['totalAmount'] ?? {}),
      percentage: (json['percentage'] ?? 0).toDouble(),
      successRate: (json['successRate'] ?? 0).toDouble(),
      averageAmount: MoneyModel.fromJson(json['averageAmount'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'method': method.displayNameEn,
      'transactionCount': transactionCount,
      'totalAmount': (totalAmount as MoneyModel).toJson(),
      'percentage': percentage,
      'successRate': successRate,
      'averageAmount': (averageAmount as MoneyModel).toJson(),
    };
  }
}

class StatusAnalyticsModel extends StatusAnalytics {
  const StatusAnalyticsModel({
    required super.status,
    required super.count,
    required super.totalAmount,
    required super.percentage,
  });

  factory StatusAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return StatusAnalyticsModel(
      status: PaymentStatusExtension.fromString(json['status'] ?? 'pending'),
      count: json['count'] ?? 0,
      totalAmount: MoneyModel.fromJson(json['totalAmount'] ?? {}),
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.displayNameEn,
      'count': count,
      'totalAmount': (totalAmount as MoneyModel).toJson(),
      'percentage': percentage,
    };
  }
}

class RefundAnalyticsModel extends RefundAnalytics {
  const RefundAnalyticsModel({
    required super.totalRefunds,
    required super.totalRefundedAmount,
    required super.refundRate,
    required super.averageRefundTime,
    required super.refundReasons,
    required super.trends,
  });

  factory RefundAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return RefundAnalyticsModel(
      totalRefunds: json['totalRefunds'] ?? 0,
      totalRefundedAmount:
          MoneyModel.fromJson(json['totalRefundedAmount'] ?? {}),
      refundRate: (json['refundRate'] ?? 0).toDouble(),
      averageRefundTime: (json['averageRefundTime'] ?? 0).toDouble(),
      refundReasons: Map<String, int>.from(json['refundReasons'] ?? {}),
      trends: (json['trends'] as List? ?? [])
          .map((t) => RefundTrendModel.fromJson(t))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRefunds': totalRefunds,
      'totalRefundedAmount': (totalRefundedAmount as MoneyModel).toJson(),
      'refundRate': refundRate,
      'averageRefundTime': averageRefundTime,
      'refundReasons': refundReasons,
      'trends': trends.map((t) => (t as RefundTrendModel).toJson()).toList(),
    };
  }
}

class RefundTrendModel extends RefundTrend {
  const RefundTrendModel({
    required super.date,
    required super.refundCount,
    required super.refundedAmount,
  });

  factory RefundTrendModel.fromJson(Map<String, dynamic> json) {
    return RefundTrendModel(
      date: DateTime.parse(json['date']),
      refundCount: json['refundCount'] ?? 0,
      refundedAmount: MoneyModel.fromJson(json['refundedAmount'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'refundCount': refundCount,
      'refundedAmount': (refundedAmount as MoneyModel).toJson(),
    };
  }
}
