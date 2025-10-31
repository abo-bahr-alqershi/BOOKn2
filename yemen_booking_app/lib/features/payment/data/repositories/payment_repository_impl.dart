/// features/payment/data/repositories/payment_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_datasource.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;
  final InternetConnectionChecker internetConnectionChecker;

  PaymentRepositoryImpl({
    required this.remoteDataSource,
    required this.internetConnectionChecker,
  });

  @override
  Future<Either<Failure, Transaction>> processPayment({
    required String bookingId,
    required String userId,
    required double amount,
    required String paymentMethod,
    required String currency,
    Map<String, dynamic>? paymentDetails,
  }) async {
    if (!(await internetConnectionChecker.hasConnection)) {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final result = await remoteDataSource.processPayment(
        bookingId: bookingId,
        userId: userId,
        amount: amount,
        paymentMethod: paymentMethod,
        currency: currency,
        cardNumber: paymentDetails?['cardNumber'],
        cardHolderName: paymentDetails?['cardHolderName'],
        expiryDate: paymentDetails?['expiryDate'],
        cvv: paymentDetails?['cvv'],
        walletNumber: paymentDetails?['walletNumber'],
        walletPin: paymentDetails?['walletPin'],
      );

      if (result.success && result.data != null) {
        return Right(result.data!);
      } else {
        return Left(ServerFailure(result.message ?? 'فشل في معالجة الدفع'));
      }
    } catch (error) {
      return ErrorHandler.handle(error);
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<Transaction>>> getPaymentHistory({
    required String userId,
    int pageNumber = 1,
    int pageSize = 10,
    String? status,
    String? paymentMethod,
    DateTime? fromDate,
    DateTime? toDate,
    double? minAmount,
    double? maxAmount,
  }) async {
    if (!(await internetConnectionChecker.hasConnection)) {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final result = await remoteDataSource.getPaymentHistory(
        userId: userId,
        pageNumber: pageNumber,
        pageSize: pageSize,
        status: status,
        paymentMethod: paymentMethod,
        fromDate: fromDate,
        toDate: toDate,
        minAmount: minAmount,
        maxAmount: maxAmount,
      );

      if (result.success && result.data != null) {
        final paginatedTransactions = PaginatedResult<Transaction>(
          items: result.data!.items.cast<Transaction>(),
          pageNumber: result.data!.pageNumber,
          pageSize: result.data!.pageSize,
          totalCount: result.data!.totalCount,
          metadata: result.data!.metadata,
        );
        return Right(paginatedTransactions);
      } else {
        return Left(ServerFailure(result.message ?? 'فشل في جلب سجل المدفوعات'));
      }
    } catch (error) {
      return ErrorHandler.handle(error);
    }
  }
}