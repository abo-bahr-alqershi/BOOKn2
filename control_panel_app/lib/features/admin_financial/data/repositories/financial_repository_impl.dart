// lib/features/admin_financial/data/repositories/financial_repository_impl.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/chart_of_account.dart';
import '../../domain/entities/financial_report.dart';
import '../../domain/entities/financial_transaction.dart';
import '../../domain/repositories/financial_repository.dart';
import '../datasources/financial_remote_datasource.dart';
import '../models/financial_transaction_model.dart';

/// 📊 تنفيذ مستودع العمليات المالية
class FinancialRepositoryImpl implements FinancialRepository {
  final FinancialRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  FinancialRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<ChartOfAccount>>> getChartOfAccounts() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final accounts = await remoteDataSource.getChartOfAccounts();
      return Right(accounts);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> processOwnerPayouts({
    List<String>? ownerIds,
    double? minimumAmountThreshold,
    bool includePendingTransactions = false,
    bool previewOnly = false,
    String? notes,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final result = await remoteDataSource.processOwnerPayouts(
        ownerIds: ownerIds,
        minimumAmountThreshold: minimumAmountThreshold,
        includePendingTransactions: includePendingTransactions,
        previewOnly: previewOnly,
        notes: notes,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ChartOfAccount>> getAccountById(String accountId) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final account = await remoteDataSource.getAccountById(accountId);
      return Right(account);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ChartOfAccount>>> getAccountsByType(AccountType type) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final accounts = await remoteDataSource.getAccountsByType(type.index);
      return Right(accounts);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ChartOfAccount>>> getMainAccounts() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final accounts = await remoteDataSource.getChartOfAccounts();
      final mainAccounts = accounts.where((a) => a.category == AccountCategory.main).toList();
      return Right(mainAccounts);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ChartOfAccount>>> getSubAccounts(String parentAccountId) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final accounts = await remoteDataSource.getChartOfAccounts();
      final subAccounts = accounts.where((a) => a.parentAccountId == parentAccountId).toList();
      return Right(subAccounts);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ChartOfAccount>>> searchAccounts(String query) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final accounts = await remoteDataSource.searchAccounts(query);
      return Right(accounts);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ChartOfAccount>> createAccount(ChartOfAccount account) async {
    // Not implemented - API endpoint needed
    return Left(ServerFailure('غير مدعوم حالياً'));
  }

  @override
  Future<Either<Failure, ChartOfAccount>> updateAccount(ChartOfAccount account) async {
    // Not implemented - API endpoint needed
    return Left(ServerFailure('غير مدعوم حالياً'));
  }

  @override
  Future<Either<Failure, bool>> deleteAccount(String accountId) async {
    // Not implemented - API endpoint needed
    return Left(ServerFailure('غير مدعوم حالياً'));
  }

  @override
  Future<Either<Failure, bool>> updateAccountBalance(String accountId, double amount, bool isDebit) async {
    // Not implemented - API endpoint needed
    return Left(ServerFailure('غير مدعوم حالياً'));
  }

  @override
  Future<Either<Failure, List<FinancialTransaction>>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    TransactionStatus? status,
    TransactionType? type,
    int? limit,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final transactions = await remoteDataSource.getTransactions(
        startDate: startDate,
        endDate: endDate,
        status: status?.index,
        type: type?.index,
        limit: limit,
      );
      return Right(transactions);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, FinancialTransaction>> getTransactionById(String transactionId) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final transaction = await remoteDataSource.getTransactionById(transactionId);
      return Right(transaction);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<FinancialTransaction>>> getTransactionsByBooking(String bookingId) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final transactions = await remoteDataSource.getTransactionsByBooking(bookingId);
      return Right(transactions);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<FinancialTransaction>>> getTransactionsByProperty(String propertyId) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final transactions = await remoteDataSource.getTransactionsByProperty(propertyId);
      return Right(transactions);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<FinancialTransaction>>> getTransactionsByUser(String userId) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final transactions = await remoteDataSource.getTransactionsByUser(userId);
      return Right(transactions);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<FinancialTransaction>>> getTransactionsByAccount(String accountId) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final transactions = await remoteDataSource.getTransactions();
      final filtered = transactions.where((t) => 
        t.debitAccountId == accountId || t.creditAccountId == accountId
      ).toList();
      return Right(filtered);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<FinancialTransaction>>> searchTransactions(String query) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final transactions = await remoteDataSource.searchTransactions(query);
      return Right(transactions);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, FinancialTransaction>> createTransaction(FinancialTransaction transaction) async {
    // Not implemented - API endpoint needed
    return Left(ServerFailure('غير مدعوم حالياً'));
  }

  @override
  Future<Either<Failure, FinancialTransaction>> updateTransaction(FinancialTransaction transaction) async {
    // Not implemented - API endpoint needed
    return Left(ServerFailure('غير مدعوم حالياً'));
  }

  @override
  Future<Either<Failure, bool>> deleteTransaction(String transactionId) async {
    // Not implemented - API endpoint needed
    return Left(ServerFailure('غير مدعوم حالياً'));
  }

  @override
  Future<Either<Failure, bool>> postTransaction(String transactionId) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final result = await remoteDataSource.postTransaction(transactionId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, FinancialTransaction>> reverseTransaction(String transactionId, String reason) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final transaction = await remoteDataSource.reverseTransaction(transactionId, reason);
      return Right(transaction);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<FinancialTransaction>>> getPendingTransactions() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final transactions = await remoteDataSource.getTransactions(
        status: TransactionStatus.pending.index,
      );
      return Right(transactions);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> postPendingTransactions() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final result = await remoteDataSource.postPendingTransactions();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, FinancialReport>> getFinancialReport(DateTime startDate, DateTime endDate) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final data = await remoteDataSource.getFinancialReport(startDate, endDate);
      final report = FinancialReport(
        startDate: startDate,
        endDate: endDate,
        totalRevenue: (data['totalRevenue'] ?? 0).toDouble(),
        totalExpenses: (data['totalExpenses'] ?? 0).toDouble(),
        totalCommissions: (data['totalCommissions'] ?? 0).toDouble(),
        totalRefunds: (data['totalRefunds'] ?? 0).toDouble(),
        netProfit: (data['netProfit'] ?? 0).toDouble(),
        transactionCount: data['transactionCount'] ?? 0,
        transactionsByType: Map<TransactionType, double>.fromEntries(
          (data['transactionsByType'] as Map<String, dynamic>? ?? {}).entries.map((e) {
            final type = _parseTransactionType(e.key);
            return MapEntry(type, (e.value ?? 0).toDouble());
          }),
        ),
      );
      return Right(report);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AccountStatement>> getAccountStatement(
    String accountId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final data = await remoteDataSource.getAccountStatement(accountId, startDate, endDate);
      final transactions = (data['transactions'] as List? ?? [])
          .map((json) => FinancialTransactionModel.fromJson(json))
          .toList();
      
      final statement = AccountStatement(
        accountId: data['accountId'] ?? accountId,
        accountNumber: data['accountNumber'] ?? '',
        accountName: data['accountName'] ?? '',
        startDate: startDate,
        endDate: endDate,
        openingBalance: (data['openingBalance'] ?? 0).toDouble(),
        closingBalance: (data['closingBalance'] ?? 0).toDouble(),
        transactions: transactions,
        currency: data['currency'] ?? 'YER',
      );
      return Right(statement);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AccountBalance>> getAccountBalance(String accountId, DateTime? atDate) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final data = await remoteDataSource.getAccountBalance(accountId, atDate);
      final balance = AccountBalance(
        accountId: data['accountId'] ?? accountId,
        accountNumber: data['accountNumber'] ?? '',
        accountName: data['accountName'] ?? '',
        balance: (data['balance'] ?? 0).toDouble(),
        currency: data['currency'] ?? 'YER',
        asOfDate: atDate ?? DateTime.now(),
      );
      return Right(balance);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<TransactionType, double>>> getTransactionSummaryByType(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final data = await remoteDataSource.getTransactionSummaryByType(startDate, endDate);
      final summary = Map<TransactionType, double>.fromEntries(
        data.entries.map((e) {
          final type = _parseTransactionType(e.key);
          return MapEntry(type, (e.value ?? 0).toDouble());
        }),
      );
      return Right(summary);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ChartData>>> getRevenueChart(DateTime startDate, DateTime endDate) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final data = await remoteDataSource.getRevenueChart(startDate, endDate);
      final chartData = data.map((item) => ChartData(
        label: item['label'] ?? '',
        value: (item['value'] ?? 0).toDouble(),
        color: item['color'] ?? '#00FF88',
      )).toList();
      return Right(chartData);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ChartData>>> getExpenseChart(DateTime startDate, DateTime endDate) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final data = await remoteDataSource.getExpenseChart(startDate, endDate);
      final chartData = data.map((item) => ChartData(
        label: item['label'] ?? '',
        value: (item['value'] ?? 0).toDouble(),
        color: item['color'] ?? '#FF3366',
      )).toList();
      return Right(chartData);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ChartData>>> getCashFlowChart(DateTime startDate, DateTime endDate) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final data = await remoteDataSource.getCashFlowChart(startDate, endDate);
      final chartData = data.map((item) => ChartData(
        label: item['label'] ?? '',
        value: (item['value'] ?? 0).toDouble(),
        color: item['color'],
      )).toList();
      return Right(chartData);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, FinancialSummary>> getFinancialSummary() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final data = await remoteDataSource.getFinancialSummary();
      final summary = FinancialSummary(
        totalAssets: (data['totalAssets'] ?? 0).toDouble(),
        totalLiabilities: (data['totalLiabilities'] ?? 0).toDouble(),
        totalEquity: (data['totalEquity'] ?? 0).toDouble(),
        currentAssets: (data['currentAssets'] ?? 0).toDouble(),
        currentLiabilities: (data['currentLiabilities'] ?? 0).toDouble(),
        workingCapital: (data['workingCapital'] ?? 0).toDouble(),
        currentRatio: (data['currentRatio'] ?? 0).toDouble(),
        quickRatio: (data['quickRatio'] ?? 0).toDouble(),
        debtToEquityRatio: (data['debtToEquityRatio'] ?? 0).toDouble(),
        returnOnAssets: (data['returnOnAssets'] ?? 0).toDouble(),
        returnOnEquity: (data['returnOnEquity'] ?? 0).toDouble(),
        grossProfitMargin: (data['grossProfitMargin'] ?? 0).toDouble(),
        netProfitMargin: (data['netProfitMargin'] ?? 0).toDouble(),
        operatingProfitMargin: (data['operatingProfitMargin'] ?? 0).toDouble(),
        cashFromOperations: (data['cashFromOperations'] ?? 0).toDouble(),
        netCashFlow: (data['netCashFlow'] ?? 0).toDouble(),
        activeBookings: data['activeBookings'] ?? 0,
        totalProperties: data['totalProperties'] ?? 0,
        totalUnits: data['totalUnits'] ?? 0,
        occupancyRate: (data['occupancyRate'] ?? 0).toDouble(),
        averageBookingValue: (data['averageBookingValue'] ?? 0).toDouble(),
      );
      return Right(summary);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> exportTransactionsToExcel(
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Not implemented - API endpoint needed
    return Left(ServerFailure('التصدير إلى Excel غير متاح حالياً'));
  }

  @override
  Future<Either<Failure, String>> exportAccountStatementToPdf(
    String accountId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Not implemented - API endpoint needed
    return Left(ServerFailure('التصدير إلى PDF غير متاح حالياً'));
  }

  @override
  Future<Either<Failure, String>> exportFinancialReportToPdf(
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Not implemented - API endpoint needed
    return Left(ServerFailure('التصدير إلى PDF غير متاح حالياً'));
  }

  /// 🔄 Helper function to parse TransactionType from string or int
  TransactionType _parseTransactionType(dynamic value) {
    // If it's already a number, use it as index
    if (value is int) {
      // Subtract 1 because backend enums start at 1, Flutter enums start at 0
      final index = value - 1;
      if (index >= 0 && index < TransactionType.values.length) {
        return TransactionType.values[index];
      }
    }
    
    // If it's a string, try to parse it
    if (value is String) {
      // Try to parse as number first
      final intValue = int.tryParse(value);
      if (intValue != null) {
        return _parseTransactionType(intValue);
      }
      
      // Map backend string names to Flutter enum values
      // Backend uses PascalCase (e.g., "NewBooking"), Flutter uses camelCase
      final enumMap = <String, TransactionType>{
        'NewBooking': TransactionType.newBooking,
        'AdvancePayment': TransactionType.advancePayment,
        'FinalPayment': TransactionType.finalPayment,
        'BookingCancellation': TransactionType.bookingCancellation,
        'Refund': TransactionType.refund,
        'PlatformCommission': TransactionType.platformCommission,
        'OwnerPayout': TransactionType.ownerPayout,
        'Tax': TransactionType.tax,
        'ServiceFee': TransactionType.serviceFee,
        'LateFee': TransactionType.lateFee,
        'Compensation': TransactionType.compensation,
        'SecurityDeposit': TransactionType.securityDeposit,
        'SecurityDepositRefund': TransactionType.securityDepositRefund,
        'Discount': TransactionType.discount,
        'OperationalExpense': TransactionType.operationalExpense,
        'OtherIncome': TransactionType.otherIncome,
        'InterAccountTransfer': TransactionType.interAccountTransfer,
        'Adjustment': TransactionType.adjustment,
        'OpeningBalance': TransactionType.openingBalance,
        'AgentCommission': TransactionType.agentCommission,
      };
      
      // Try exact match
      if (enumMap.containsKey(value)) {
        return enumMap[value]!;
      }
      
      // Try case-insensitive match
      final lowerValue = value.toLowerCase();
      for (final entry in enumMap.entries) {
        if (entry.key.toLowerCase() == lowerValue) {
          return entry.value;
        }
      }
      
      // Try to match by converting camelCase to PascalCase
      final pascalCase = value.isNotEmpty 
          ? value[0].toUpperCase() + value.substring(1)
          : value;
      if (enumMap.containsKey(pascalCase)) {
        return enumMap[pascalCase]!;
      }
    }
    
    // Default to 'other' if can't parse
    return TransactionType.adjustment;
  }
}
