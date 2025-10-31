// lib/features/admin_financial/domain/repositories/financial_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/chart_of_account.dart';
import '../entities/financial_transaction.dart';
import '../entities/financial_report.dart';

/// 📊 واجهة مستودع العمليات المالية
abstract class FinancialRepository {
  // 📈 Chart of Accounts Operations
  Future<Either<Failure, List<ChartOfAccount>>> getChartOfAccounts();
  Future<Either<Failure, ChartOfAccount>> getAccountById(String accountId);
  Future<Either<Failure, List<ChartOfAccount>>> getAccountsByType(AccountType type);
  Future<Either<Failure, List<ChartOfAccount>>> getMainAccounts();
  Future<Either<Failure, List<ChartOfAccount>>> getSubAccounts(String parentAccountId);
  Future<Either<Failure, List<ChartOfAccount>>> searchAccounts(String query);
  Future<Either<Failure, ChartOfAccount>> createAccount(ChartOfAccount account);
  Future<Either<Failure, ChartOfAccount>> updateAccount(ChartOfAccount account);
  Future<Either<Failure, bool>> deleteAccount(String accountId);
  Future<Either<Failure, bool>> updateAccountBalance(String accountId, double amount, bool isDebit);

  // 💳 Financial Transactions Operations
  Future<Either<Failure, List<FinancialTransaction>>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    TransactionStatus? status,
    TransactionType? type,
    int? limit,
  });
  
  Future<Either<Failure, FinancialTransaction>> getTransactionById(String transactionId);
  Future<Either<Failure, List<FinancialTransaction>>> getTransactionsByBooking(String bookingId);
  Future<Either<Failure, List<FinancialTransaction>>> getTransactionsByProperty(String propertyId);
  Future<Either<Failure, List<FinancialTransaction>>> getTransactionsByUser(String userId);
  Future<Either<Failure, List<FinancialTransaction>>> getTransactionsByAccount(String accountId);
  Future<Either<Failure, List<FinancialTransaction>>> searchTransactions(String query);
  Future<Either<Failure, FinancialTransaction>> createTransaction(FinancialTransaction transaction);
  Future<Either<Failure, FinancialTransaction>> updateTransaction(FinancialTransaction transaction);
  Future<Either<Failure, bool>> deleteTransaction(String transactionId);
  Future<Either<Failure, bool>> postTransaction(String transactionId);
  Future<Either<Failure, FinancialTransaction>> reverseTransaction(String transactionId, String reason);
  Future<Either<Failure, List<FinancialTransaction>>> getPendingTransactions();
  Future<Either<Failure, Map<String, dynamic>>> postPendingTransactions();

  // 📊 Financial Reports Operations
  Future<Either<Failure, FinancialReport>> getFinancialReport(DateTime startDate, DateTime endDate);
  Future<Either<Failure, AccountStatement>> getAccountStatement(
    String accountId,
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, AccountBalance>> getAccountBalance(String accountId, DateTime? atDate);
  Future<Either<Failure, Map<TransactionType, double>>> getTransactionSummaryByType(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, List<ChartData>>> getRevenueChart(DateTime startDate, DateTime endDate);
  Future<Either<Failure, List<ChartData>>> getExpenseChart(DateTime startDate, DateTime endDate);
  Future<Either<Failure, List<ChartData>>> getCashFlowChart(DateTime startDate, DateTime endDate);
  Future<Either<Failure, FinancialSummary>> getFinancialSummary();
  
  // 💸 Owner payouts
  Future<Either<Failure, Map<String, dynamic>>> processOwnerPayouts({
    List<String>? ownerIds,
    double? minimumAmountThreshold,
    bool includePendingTransactions,
    bool previewOnly,
    String? notes,
  });
  
  // 📥 Export Operations
  Future<Either<Failure, String>> exportTransactionsToExcel(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, String>> exportAccountStatementToPdf(
    String accountId,
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, String>> exportFinancialReportToPdf(
    DateTime startDate,
    DateTime endDate,
  );
}
