// lib/features/admin_financial/presentation/bloc/transactions/transactions_state.dart

part of 'transactions_bloc.dart';

/// 📋 حالات المعاملات المالية
abstract class TransactionsState extends Equatable {
  const TransactionsState();

  @override
  List<Object?> get props => [];
}

/// 🔄 الحالة الأولية
class TransactionsInitial extends TransactionsState {}

/// ⏳ جاري التحميل
class TransactionsLoading extends TransactionsState {}

/// ✅ تم التحميل بنجاح
class TransactionsLoaded extends TransactionsState {
  final List<FinancialTransaction> transactions;
  final List<FinancialTransaction> allTransactions; // For filtering
  final DateTime? startDate;
  final DateTime? endDate;
  final TransactionStatus? selectedStatus;
  final TransactionType? selectedType;
  final String? searchQuery;
  final bool isProcessing;
  final bool isExporting;
  final String? exportedFilePath;
  final String? successMessage;
  final String? error;
  final FinancialReport report;

  const TransactionsLoaded({
    required this.transactions,
    List<FinancialTransaction>? allTransactions,
    this.startDate,
    this.endDate,
    this.selectedStatus,
    this.selectedType,
    this.searchQuery,
    this.isProcessing = false,
    this.isExporting = false,
    this.exportedFilePath,
    this.successMessage,
    this.error,
    required this.report,
  }) : allTransactions = allTransactions ?? transactions;

  // 🎯 Helper Methods
  int get totalCount => transactions.length;

  double get totalAmount {
    return transactions.fold(0, (sum, t) => sum + t.amount);
  }

  double get totalDebit {
    return transactions
        .where((t) => t.normalBalance == 'debit')
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get totalCredit {
    return transactions
        .where((t) => t.normalBalance == 'credit')
        .fold(0, (sum, t) => sum + t.amount);
  }

  List<FinancialTransaction> get pendingTransactions {
    return transactions
        .where((t) => t.status == TransactionStatus.pending)
        .toList();
  }

  List<FinancialTransaction> get postedTransactions {
    return transactions.where((t) => t.isPosted).toList();
  }

  TransactionsLoaded copyWith({
    List<FinancialTransaction>? transactions,
    List<FinancialTransaction>? allTransactions,
    DateTime? startDate,
    DateTime? endDate,
    TransactionStatus? selectedStatus,
    TransactionType? selectedType,
    String? searchQuery,
    bool? isProcessing,
    bool? isExporting,
    String? exportedFilePath,
    String? successMessage,
    String? error,
    FinancialReport? report,
  }) {
    return TransactionsLoaded(
      transactions: transactions ?? this.transactions,
      allTransactions: allTransactions ?? this.allTransactions,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedType: selectedType ?? this.selectedType,
      searchQuery: searchQuery ?? this.searchQuery,
      isProcessing: isProcessing ?? this.isProcessing,
      isExporting: isExporting ?? this.isExporting,
      exportedFilePath: exportedFilePath ?? this.exportedFilePath,
      successMessage: successMessage ?? this.successMessage,
      error: error ?? this.error,
      report: report ?? this.report,
    );
  }

  @override
  List<Object?> get props => [
        transactions,
        allTransactions,
        startDate,
        endDate,
        selectedStatus,
        selectedType,
        searchQuery,
        isProcessing,
        isExporting,
        exportedFilePath,
        successMessage,
        error,
        report,
      ];
}

/// ❌ حالة الخطأ
class TransactionsError extends TransactionsState {
  final String message;

  const TransactionsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Extension to add normalBalance property
extension TransactionExtensions on FinancialTransaction {
  String get normalBalance {
    // Determine if transaction is debit or credit based on type
    switch (transactionType) {
      case TransactionType.newBooking:
      case TransactionType.advancePayment:
      case TransactionType.finalPayment:
      case TransactionType.platformCommission:
      case TransactionType.serviceFee:
      case TransactionType.lateFee:
      case TransactionType.otherIncome:
        return 'credit';
      case TransactionType.bookingCancellation:
      case TransactionType.refund:
      case TransactionType.ownerPayout:
      case TransactionType.tax:
      case TransactionType.discount:
      case TransactionType.compensation:
      case TransactionType.securityDepositRefund:
      case TransactionType.interAccountTransfer:
      case TransactionType.adjustment:
      case TransactionType.openingBalance:
      case TransactionType.agentCommission:
      case TransactionType.operationalExpense:
      case TransactionType.securityDeposit:
        return 'debit';
    }
  }
}
