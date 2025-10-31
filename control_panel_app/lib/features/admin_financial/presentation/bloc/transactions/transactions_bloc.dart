// lib/features/admin_financial/presentation/bloc/transactions/transactions_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/financial_report.dart';
import '../../../domain/entities/financial_transaction.dart';
import '../../../domain/repositories/financial_repository.dart';

part 'transactions_event.dart';
part 'transactions_state.dart';

/// 💳 Bloc لإدارة المعاملات المالية
class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  final FinancialRepository repository;

  TransactionsBloc({
    required this.repository,
  }) : super(TransactionsInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<SearchTransactions>(_onSearchTransactions);
    on<FilterTransactions>(_onFilterTransactions);
    on<PostTransaction>(_onPostTransaction);
    on<ReverseTransaction>(_onReverseTransaction);
    on<PostPendingTransactions>(_onPostPendingTransactions);
    on<ExportTransactions>(_onExportTransactions);
    on<RefreshTransactions>(_onRefreshTransactions);
    on<LoadTransactionsByBooking>(_onLoadTransactionsByBooking);
    on<LoadTransactionsByUser>(_onLoadTransactionsByUser);
  }

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(TransactionsLoading());

    // Sensible defaults to reduce payload size on dashboard
    final resolvedEnd = event.endDate ?? DateTime.now();
    final resolvedStart = event.startDate ?? resolvedEnd.subtract(const Duration(days: 30));
    final resolvedLimit = event.limit ?? 50;

    final result = await repository.getTransactions(
      startDate: resolvedStart,
      endDate: resolvedEnd,
      status: event.status,
      type: event.type,
      limit: resolvedLimit,
    );

    result.fold(
      (failure) => emit(TransactionsError(failure.message)),
      (transactions) => emit(TransactionsLoaded(
        transactions: transactions,
        startDate: resolvedStart,
        endDate: resolvedEnd,
        selectedStatus: event.status,
        selectedType: event.type,
        report: _buildFinancialReport(
          transactions,
          resolvedStart,
          resolvedEnd,
        ),
      )),
    );
  }

  Future<void> _onSearchTransactions(
    SearchTransactions event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(TransactionsLoading());

    final result = await repository.searchTransactions(event.query);

    result.fold(
      (failure) => emit(TransactionsError(failure.message)),
      (transactions) => emit(TransactionsLoaded(
        transactions: transactions,
        searchQuery: event.query,
        report: _buildFinancialReport(transactions, null, null),
      )),
    );
  }

  Future<void> _onFilterTransactions(
    FilterTransactions event,
    Emitter<TransactionsState> emit,
  ) async {
    final currentState = state;
    if (currentState is TransactionsLoaded) {
      // Apply filters to existing transactions
      var filtered = currentState.allTransactions;

      if (event.status != null) {
        filtered = filtered.where((t) => t.status == event.status).toList();
      }

      if (event.type != null) {
        filtered =
            filtered.where((t) => t.transactionType == event.type).toList();
      }

      if (event.accountId != null) {
        filtered = filtered
            .where((t) =>
                t.debitAccountId == event.accountId ||
                t.creditAccountId == event.accountId)
            .toList();
      }

      emit(currentState.copyWith(
        transactions: filtered,
        selectedStatus: event.status,
        selectedType: event.type,
        report: _buildFinancialReport(
          filtered,
          currentState.startDate,
          currentState.endDate,
        ),
      ));
    }
  }

  Future<void> _onPostTransaction(
    PostTransaction event,
    Emitter<TransactionsState> emit,
  ) async {
    final currentState = state;
    if (currentState is TransactionsLoaded) {
      emit(currentState.copyWith(isProcessing: true));

      final result = await repository.postTransaction(event.transactionId);

      result.fold(
        (failure) => emit(currentState.copyWith(
          isProcessing: false,
          error: failure.message,
        )),
        (success) {
          // Update transaction status in list
          final updatedTransactions = currentState.transactions.map((t) {
            if (t.id == event.transactionId) {
              // Create a new transaction with updated status
              return FinancialTransaction(
                id: t.id,
                transactionNumber: t.transactionNumber,
                transactionDate: t.transactionDate,
                entryType: t.entryType,
                transactionType: t.transactionType,
                debitAccountId: t.debitAccountId,
                creditAccountId: t.creditAccountId,
                debitAccount: t.debitAccount,
                creditAccount: t.creditAccount,
                amount: t.amount,
                currency: t.currency,
                exchangeRate: t.exchangeRate,
                baseAmount: t.baseAmount,
                description: t.description,
                narration: t.narration,
                referenceNumber: t.referenceNumber,
                documentType: t.documentType,
                bookingId: t.bookingId,
                paymentId: t.paymentId,
                firstPartyUserId: t.firstPartyUserId,
                secondPartyUserId: t.secondPartyUserId,
                propertyId: t.propertyId,
                unitId: t.unitId,
                fiscalYear: t.fiscalYear,
                fiscalPeriod: t.fiscalPeriod,
                tax: t.tax,
                taxPercentage: t.taxPercentage,
                commission: t.commission,
                commissionPercentage: t.commissionPercentage,
                discount: t.discount,
                discountPercentage: t.discountPercentage,
                netAmount: t.netAmount,
                journalId: t.journalId,
                batchNumber: t.batchNumber,
                attachmentsJson: t.attachmentsJson,
                notes: t.notes,
                tags: t.tags,
                costCenter: t.costCenter,
                project: t.project,
                department: t.department,
                isReversed: t.isReversed,
                reverseTransactionId: t.reverseTransactionId,
                cancellationReason: t.cancellationReason,
                cancelledAt: t.cancelledAt,
                cancelledBy: t.cancelledBy,
                createdBy: t.createdBy,
                createdAt: t.createdAt,
                updatedBy: t.updatedBy,
                updatedAt: t.updatedAt,
                isAutomatic: t.isAutomatic,
                automaticSource: t.automaticSource,
                status: TransactionStatus.posted,
                isPosted: true,
                postingDate: DateTime.now(),
              );
            }
            return t;
          }).toList();

          emit(currentState.copyWith(
            transactions: updatedTransactions,
            isProcessing: false,
            successMessage: 'تم ترحيل المعاملة بنجاح',
            report: _buildFinancialReport(
              updatedTransactions,
              currentState.startDate,
              currentState.endDate,
            ),
          ));
        },
      );
    }
  }

  Future<void> _onReverseTransaction(
    ReverseTransaction event,
    Emitter<TransactionsState> emit,
  ) async {
    final currentState = state;
    if (currentState is TransactionsLoaded) {
      emit(currentState.copyWith(isProcessing: true));

      final result = await repository.reverseTransaction(
        event.transactionId,
        event.reason,
      );

      result.fold(
        (failure) => emit(currentState.copyWith(
          isProcessing: false,
          error: failure.message,
        )),
        (reversedTransaction) {
          // Add reversed transaction to list
          final updatedTransactions = [
            ...currentState.transactions,
            reversedTransaction
          ];

          emit(currentState.copyWith(
            transactions: updatedTransactions,
            isProcessing: false,
            successMessage: 'تم عكس المعاملة بنجاح',
            report: _buildFinancialReport(
              updatedTransactions,
              currentState.startDate,
              currentState.endDate,
            ),
          ));
        },
      );
    }
  }

  FinancialReport _buildFinancialReport(
    List<FinancialTransaction> transactions,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    final resolvedStart = startDate ??
        (transactions.isNotEmpty
            ? transactions
                .map((t) => t.transactionDate)
                .reduce((a, b) => a.isBefore(b) ? a : b)
            : DateTime.now().subtract(const Duration(days: 30)));

    final resolvedEnd = endDate ??
        (transactions.isNotEmpty
            ? transactions
                .map((t) => t.transactionDate)
                .reduce((a, b) => a.isAfter(b) ? a : b)
            : DateTime.now());

    double totalRevenue = 0;
    double totalExpenses = 0;
    final transactionsByType = <TransactionType, double>{};
    final revenueByMonth = <String, double>{};
    final expensesByCategory = <String, double>{};

    for (final transaction in transactions) {
      transactionsByType[transaction.transactionType] =
          (transactionsByType[transaction.transactionType] ?? 0) +
              transaction.amount;

      final monthKey =
          '${transaction.transactionDate.year}-${transaction.transactionDate.month.toString().padLeft(2, '0')}';

      if (transaction.normalBalance == 'credit') {
        totalRevenue += transaction.amount;
        revenueByMonth[monthKey] =
            (revenueByMonth[monthKey] ?? 0) + transaction.amount;
      } else {
        totalExpenses += transaction.amount;
        final categoryKey = transaction.transactionType.nameAr;
        expensesByCategory[categoryKey] =
            (expensesByCategory[categoryKey] ?? 0) + transaction.amount;
      }
    }

    final totalCommissions =
        (transactionsByType[TransactionType.platformCommission] ?? 0) +
            (transactionsByType[TransactionType.agentCommission] ?? 0);
    final totalRefunds = transactionsByType[TransactionType.refund] ?? 0;
    final netProfit = totalRevenue - totalExpenses;

    return FinancialReport(
      startDate: resolvedStart,
      endDate: resolvedEnd,
      totalRevenue: totalRevenue,
      totalExpenses: totalExpenses,
      totalCommissions: totalCommissions,
      totalRefunds: totalRefunds,
      netProfit: netProfit,
      transactionCount: transactions.length,
      transactionsByType: transactionsByType,
      revenueByMonth: revenueByMonth,
      expensesByCategory: expensesByCategory,
    );
  }

  Future<void> _onPostPendingTransactions(
    PostPendingTransactions event,
    Emitter<TransactionsState> emit,
  ) async {
    final currentState = state;
    if (currentState is TransactionsLoaded) {
      emit(currentState.copyWith(isProcessing: true));

      final result = await repository.postPendingTransactions();

      result.fold(
        (failure) => emit(currentState.copyWith(
          isProcessing: false,
          error: failure.message,
        )),
        (summary) {
          emit(currentState.copyWith(
            isProcessing: false,
            successMessage:
                'تم ترحيل ${summary['posted']} معاملة من أصل ${summary['total']}',
            report: _buildFinancialReport(
              currentState.transactions,
              currentState.startDate,
              currentState.endDate,
            ),
          ));

          // Reload transactions
          add(RefreshTransactions());
        },
      );
    }
  }

  Future<void> _onExportTransactions(
    ExportTransactions event,
    Emitter<TransactionsState> emit,
  ) async {
    final currentState = state;
    if (currentState is TransactionsLoaded) {
      emit(currentState.copyWith(isExporting: true));

      final result = event.format == 'excel'
          ? await repository.exportTransactionsToExcel(
              event.startDate, event.endDate)
          : await repository.exportFinancialReportToPdf(
              event.startDate, event.endDate);

      result.fold(
        (failure) => emit(currentState.copyWith(
          isExporting: false,
          error: failure.message,
        )),
        (filePath) => emit(currentState.copyWith(
          isExporting: false,
          exportedFilePath: filePath,
          successMessage: 'تم تصدير التقرير بنجاح',
        )),
      );
    }
  }

  Future<void> _onRefreshTransactions(
    RefreshTransactions event,
    Emitter<TransactionsState> emit,
  ) async {
    final currentState = state;
    if (currentState is TransactionsLoaded) {
      add(LoadTransactions(
        startDate: currentState.startDate,
        endDate: currentState.endDate,
        status: currentState.selectedStatus,
        type: currentState.selectedType,
      ));
    }
  }

  Future<void> _onLoadTransactionsByBooking(
    LoadTransactionsByBooking event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(TransactionsLoading());

    final result = await repository.getTransactionsByBooking(event.bookingId);

    result.fold(
      (failure) => emit(TransactionsError(failure.message)),
      (transactions) => emit(TransactionsLoaded(
        transactions: transactions,
        report: _buildFinancialReport(transactions, null, null),
      )),
    );
  }

  Future<void> _onLoadTransactionsByUser(
    LoadTransactionsByUser event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(TransactionsLoading());

    final result = await repository.getTransactionsByUser(event.userId);

    result.fold(
      (failure) => emit(TransactionsError(failure.message)),
      (transactions) => emit(TransactionsLoaded(
        transactions: transactions,
        report: _buildFinancialReport(transactions, null, null),
      )),
    );
  }
}
