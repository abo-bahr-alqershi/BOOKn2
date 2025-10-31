// lib/features/admin_financial/presentation/bloc/financial_overview/financial_overview_event.dart

part of 'financial_overview_bloc.dart';

/// 📋 أحداث النظرة العامة المالية
abstract class FinancialOverviewEvent extends Equatable {
  const FinancialOverviewEvent();

  @override
  List<Object?> get props => [];
}

/// 📥 تحميل النظرة العامة المالية
class LoadFinancialOverview extends FinancialOverviewEvent {
  final DateTime startDate;
  final DateTime endDate;

  const LoadFinancialOverview({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

/// 🔄 تحديث النظرة العامة المالية
class RefreshFinancialOverview extends FinancialOverviewEvent {}

/// 📅 تغيير الفترة الزمنية
class ChangePeriod extends FinancialOverviewEvent {
  final DateTime startDate;
  final DateTime endDate;

  const ChangePeriod({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

/// 📊 تحميل بيانات الرسم البياني
class LoadChartData extends FinancialOverviewEvent {
  final String chartType; // revenue, expense, cashflow

  const LoadChartData({required this.chartType});

  @override
  List<Object?> get props => [chartType];
}

/// 📤 تصدير التقرير
class ExportReport extends FinancialOverviewEvent {
  final String format; // pdf, excel

  const ExportReport({required this.format});

  @override
  List<Object?> get props => [format];
}
