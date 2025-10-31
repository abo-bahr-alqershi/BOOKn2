// lib/features/admin_financial/domain/entities/financial_report.dart

import 'package:equatable/equatable.dart';
import 'financial_transaction.dart';

/// 📊 كيان التقرير المالي
class FinancialReport extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final double totalRevenue;
  final double totalExpenses;
  final double totalCommissions;
  final double totalRefunds;
  final double netProfit;
  final int transactionCount;
  final Map<TransactionType, double> transactionsByType;
  final Map<String, double> revenueByMonth;
  final Map<String, double> expensesByCategory;
  final List<AccountBalance> accountBalances;
  final FinancialSummary? summary;

  const FinancialReport({
    required this.startDate,
    required this.endDate,
    this.totalRevenue = 0,
    this.totalExpenses = 0,
    this.totalCommissions = 0,
    this.totalRefunds = 0,
    this.netProfit = 0,
    this.transactionCount = 0,
    this.transactionsByType = const {},
    this.revenueByMonth = const {},
    this.expensesByCategory = const {},
    this.accountBalances = const [],
    this.summary,
  });

  // 🎯 Helper Methods
  double get profitMargin => totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0;
  double get expenseRatio => totalRevenue > 0 ? (totalExpenses / totalRevenue) * 100 : 0;
  double get commissionRate => totalRevenue > 0 ? (totalCommissions / totalRevenue) * 100 : 0;
  bool get isProfitable => netProfit > 0;

  // 📈 Growth calculations
  double calculateGrowth(double previousValue, double currentValue) {
    if (previousValue == 0) return currentValue > 0 ? 100 : 0;
    return ((currentValue - previousValue) / previousValue) * 100;
  }

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        totalRevenue,
        totalExpenses,
        totalCommissions,
        totalRefunds,
        netProfit,
        transactionCount,
        transactionsByType,
        revenueByMonth,
        expensesByCategory,
        accountBalances,
        summary,
      ];
}

/// 💰 رصيد الحساب
class AccountBalance extends Equatable {
  final String accountId;
  final String accountNumber;
  final String accountName;
  final double balance;
  final String currency;
  final DateTime asOfDate;
  final double debitTotal;
  final double creditTotal;
  final int transactionCount;

  const AccountBalance({
    required this.accountId,
    required this.accountNumber,
    required this.accountName,
    required this.balance,
    this.currency = 'YER',
    required this.asOfDate,
    this.debitTotal = 0,
    this.creditTotal = 0,
    this.transactionCount = 0,
  });

  @override
  List<Object?> get props => [
        accountId,
        accountNumber,
        accountName,
        balance,
        currency,
        asOfDate,
        debitTotal,
        creditTotal,
        transactionCount,
      ];
}

/// 📋 كشف الحساب
class AccountStatement extends Equatable {
  final String accountId;
  final String accountNumber;
  final String accountName;
  final DateTime startDate;
  final DateTime endDate;
  final double openingBalance;
  final double closingBalance;
  final double totalDebits;
  final double totalCredits;
  final List<FinancialTransaction> transactions;
  final String currency;

  const AccountStatement({
    required this.accountId,
    required this.accountNumber,
    required this.accountName,
    required this.startDate,
    required this.endDate,
    this.openingBalance = 0,
    this.closingBalance = 0,
    this.totalDebits = 0,
    this.totalCredits = 0,
    this.transactions = const [],
    this.currency = 'YER',
  });

  // 🎯 Helper Methods
  double get netChange => closingBalance - openingBalance;
  bool get hasIncreased => netChange > 0;
  int get transactionCount => transactions.length;

  @override
  List<Object?> get props => [
        accountId,
        accountNumber,
        accountName,
        startDate,
        endDate,
        openingBalance,
        closingBalance,
        totalDebits,
        totalCredits,
        transactions,
        currency,
      ];
}

/// 📊 ملخص مالي
class FinancialSummary extends Equatable {
  final double totalAssets;
  final double totalLiabilities;
  final double totalEquity;
  final double currentAssets;
  final double currentLiabilities;
  final double workingCapital;
  final double currentRatio;
  final double quickRatio;
  final double debtToEquityRatio;
  final double returnOnAssets;
  final double returnOnEquity;
  final double grossProfitMargin;
  final double netProfitMargin;
  final double operatingProfitMargin;
  final double cashFromOperations;
  final double netCashFlow;
  final int activeBookings;
  final int totalProperties;
  final int totalUnits;
  final double occupancyRate;
  final double averageBookingValue;

  const FinancialSummary({
    this.totalAssets = 0,
    this.totalLiabilities = 0,
    this.totalEquity = 0,
    this.currentAssets = 0,
    this.currentLiabilities = 0,
    this.workingCapital = 0,
    this.currentRatio = 0,
    this.quickRatio = 0,
    this.debtToEquityRatio = 0,
    this.returnOnAssets = 0,
    this.returnOnEquity = 0,
    this.grossProfitMargin = 0,
    this.netProfitMargin = 0,
    this.operatingProfitMargin = 0,
    this.cashFromOperations = 0,
    this.netCashFlow = 0,
    this.activeBookings = 0,
    this.totalProperties = 0,
    this.totalUnits = 0,
    this.occupancyRate = 0,
    this.averageBookingValue = 0,
  });

  // 🎯 Financial Health Indicators
  bool get isFinanciallyHealthy => currentRatio > 1.5 && debtToEquityRatio < 2;
  bool get hasGoodLiquidity => currentRatio > 1.0;
  bool get isProfitable => netProfitMargin > 0;

  @override
  List<Object?> get props => [
        totalAssets,
        totalLiabilities,
        totalEquity,
        currentAssets,
        currentLiabilities,
        workingCapital,
        currentRatio,
        quickRatio,
        debtToEquityRatio,
        returnOnAssets,
        returnOnEquity,
        grossProfitMargin,
        netProfitMargin,
        operatingProfitMargin,
        cashFromOperations,
        netCashFlow,
        activeBookings,
        totalProperties,
        totalUnits,
        occupancyRate,
        averageBookingValue,
      ];
}

/// 📈 بيانات الرسم البياني
class ChartData extends Equatable {
  final String label;
  final double value;
  final String? color;
  final String? icon;
  final Map<String, dynamic>? metadata;

  const ChartData({
    required this.label,
    required this.value,
    this.color,
    this.icon,
    this.metadata,
  });

  @override
  List<Object?> get props => [label, value, color, icon, metadata];
}
