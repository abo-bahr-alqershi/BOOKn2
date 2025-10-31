// lib/features/admin_financial/presentation/bloc/financial_overview/financial_overview_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/chart_of_account.dart';
import '../../../domain/entities/financial_report.dart';
import '../../../domain/entities/financial_transaction.dart';
import '../../../domain/repositories/financial_repository.dart';

part 'financial_overview_event.dart';
part 'financial_overview_state.dart';

/// 📊 Bloc لإدارة النظرة العامة المالية
class FinancialOverviewBloc extends Bloc<FinancialOverviewEvent, FinancialOverviewState> {
  final FinancialRepository repository;

  FinancialOverviewBloc({
    required this.repository,
  }) : super(FinancialOverviewInitial()) {
    on<LoadFinancialOverview>(_onLoadFinancialOverview);
    on<RefreshFinancialOverview>(_onRefreshFinancialOverview);
    on<ChangePeriod>(_onChangePeriod);
    on<LoadChartData>(_onLoadChartData);
    on<ExportReport>(_onExportReport);
  }

  Future<void> _onLoadFinancialOverview(
    LoadFinancialOverview event,
    Emitter<FinancialOverviewState> emit,
  ) async {
    emit(FinancialOverviewLoading());

    try {
      // Load multiple data concurrently
      final futures = await Future.wait([
        repository.getFinancialReport(event.startDate, event.endDate),
        repository.getChartOfAccounts(),
        repository.getTransactions(
          startDate: event.startDate,
          endDate: event.endDate,
          limit: 10,
        ),
        repository.getFinancialSummary(),
      ]);

      final reportResult = futures[0] as dynamic;
      final accountsResult = futures[1] as dynamic;
      final transactionsResult = futures[2] as dynamic;
      final summaryResult = futures[3] as dynamic;

      if (reportResult.isLeft() || 
          accountsResult.isLeft() || 
          transactionsResult.isLeft() ||
          summaryResult.isLeft()) {
        emit(FinancialOverviewError('فشل تحميل البيانات المالية'));
        return;
      }

      final report = reportResult.fold(
        (l) => null,
        (r) => r as FinancialReport,
      );

      final accounts = accountsResult.fold(
        (l) => <ChartOfAccount>[],
        (r) => r as List<ChartOfAccount>,
      );

      final transactions = transactionsResult.fold(
        (l) => <FinancialTransaction>[],
        (r) => r as List<FinancialTransaction>,
      );

      final summary = summaryResult.fold(
        (l) => null,
        (r) => r as FinancialSummary,
      );

      // Load chart data in parallel
      final chartResults = await Future.wait([
        repository.getRevenueChart(event.startDate, event.endDate),
        repository.getExpenseChart(event.startDate, event.endDate),
        repository.getCashFlowChart(event.startDate, event.endDate),
      ]);

      final revenueChartResult = chartResults[0];
      final expenseChartResult = chartResults[1];
      final cashFlowChartResult = chartResults[2];

      final revenueChart = revenueChartResult.fold(
        (l) => <ChartData>[],
        (r) => r,
      );

      final expenseChart = expenseChartResult.fold(
        (l) => <ChartData>[],
        (r) => r,
      );

      final cashFlowChart = cashFlowChartResult.fold(
        (l) => <ChartData>[],
        (r) => r,
      );

      emit(FinancialOverviewLoaded(
        report: report!,
        accounts: accounts,
        recentTransactions: transactions,
        summary: summary,
        revenueChartData: revenueChart,
        expenseChartData: expenseChart,
        cashFlowChartData: cashFlowChart,
        startDate: event.startDate,
        endDate: event.endDate,
      ));
    } catch (e) {
      emit(FinancialOverviewError('حدث خطأ: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshFinancialOverview(
    RefreshFinancialOverview event,
    Emitter<FinancialOverviewState> emit,
  ) async {
    final currentState = state;
    if (currentState is FinancialOverviewLoaded) {
      add(LoadFinancialOverview(
        startDate: currentState.startDate,
        endDate: currentState.endDate,
      ));
    }
  }

  Future<void> _onChangePeriod(
    ChangePeriod event,
    Emitter<FinancialOverviewState> emit,
  ) async {
    add(LoadFinancialOverview(
      startDate: event.startDate,
      endDate: event.endDate,
    ));
  }

  Future<void> _onLoadChartData(
    LoadChartData event,
    Emitter<FinancialOverviewState> emit,
  ) async {
    final currentState = state;
    if (currentState is FinancialOverviewLoaded) {
      emit(currentState.copyWith(isLoadingChart: true));

      try {
        final result = await repository.getRevenueChart(
          currentState.startDate,
          currentState.endDate,
        );

        result.fold(
          (failure) => emit(currentState.copyWith(isLoadingChart: false)),
          (chartData) => emit(currentState.copyWith(
            revenueChartData: chartData,
            isLoadingChart: false,
          )),
        );
      } catch (e) {
        emit(currentState.copyWith(isLoadingChart: false));
      }
    }
  }

  Future<void> _onExportReport(
    ExportReport event,
    Emitter<FinancialOverviewState> emit,
  ) async {
    final currentState = state;
    if (currentState is FinancialOverviewLoaded) {
      emit(currentState.copyWith(isExporting: true));

      try {
        final result = await repository.exportFinancialReportToPdf(
          currentState.startDate,
          currentState.endDate,
        );

        result.fold(
          (failure) => emit(currentState.copyWith(
            isExporting: false,
            exportError: failure.toString(),
          )),
          (filePath) => emit(currentState.copyWith(
            isExporting: false,
            exportedFilePath: filePath,
          )),
        );
      } catch (e) {
        emit(currentState.copyWith(
          isExporting: false,
          exportError: e.toString(),
        ));
      }
    }
  }
}
