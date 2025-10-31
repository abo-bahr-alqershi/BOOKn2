import 'package:dartz/dartz.dart';
import '../../../../../core/error/exceptions.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/models/paginated_result.dart';
import '../../../../../core/network/network_info.dart';
import '../../../../../core/enums/payment_method_enum.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/payment_details.dart';
import '../../domain/entities/payment_analytics.dart';
import '../../domain/entities/refund.dart';
import '../../domain/repositories/payments_repository.dart';
import '../datasources/payments_local_datasource.dart';
import '../datasources/payments_remote_datasource.dart';
import '../models/payment_model.dart';
import '../models/money_model.dart';

class PaymentsRepositoryImpl implements PaymentsRepository {
  final PaymentsRemoteDataSource remoteDataSource;
  final PaymentsLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  PaymentsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, bool>> refundPayment({
    required String paymentId,
    required Money refundAmount,
    required String refundReason,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.refundPayment(
          paymentId: paymentId,
          refundAmount: MoneyModel.fromEntity(refundAmount),
          refundReason: refundReason,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> voidPayment({required String paymentId}) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.voidPayment(
          paymentId: paymentId,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> updatePaymentStatus({
    required String paymentId,
    required PaymentStatus newStatus,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.updatePaymentStatus(
          paymentId: paymentId,
          newStatus: newStatus,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, String>> processPayment({
    required String bookingId,
    required Money amount,
    required PaymentMethod method,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.processPayment(
          bookingId: bookingId,
          amount: MoneyModel.fromEntity(amount),
          method: method,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Payment>> getPaymentById({
    required String paymentId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getPaymentById(
          paymentId: paymentId,
        );
        // Cache the payment
        await localDataSource.cachePaymentDetails(paymentId, result);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    } else {
      // Try to get from cache
      try {
        final cachedPayment =
            await localDataSource.getCachedPaymentDetails(paymentId);
        if (cachedPayment != null) {
          return Right(cachedPayment);
        } else {
          return const Left(CacheFailure('No cached data available'));
        }
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    }
  }

  @override
  Future<Either<Failure, PaymentDetails>> getPaymentDetails({
    required String paymentId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getPaymentDetails(
          paymentId: paymentId,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<Payment>>> getAllPayments({
    PaymentStatus? status,
    PaymentMethod? method,
    String? bookingId,
    String? userId,
    String? propertyId,
    String? unitId,
    double? minAmount,
    double? maxAmount,
    DateTime? startDate,
    DateTime? endDate,
    int? pageNumber,
    int? pageSize,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getAllPayments(
          status: status,
          method: method,
          bookingId: bookingId,
          userId: userId,
          propertyId: propertyId,
          unitId: unitId,
          minAmount: minAmount,
          maxAmount: maxAmount,
          startDate: startDate,
          endDate: endDate,
          pageNumber: pageNumber,
          pageSize: pageSize,
        );

        // Cache first page
        if (pageNumber == 1 || pageNumber == null) {
          await localDataSource.cachePayments(
            result.items.map((p) => PaymentModel.fromEntity(p)).toList(),
          );
        }

        return Right(PaginatedResult<Payment>(
          items: result.items,
          totalCount: result.totalCount,
          pageNumber: result.pageNumber,
          pageSize: result.pageSize,
        ));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    } else {
      // Try to get from cache
      try {
        final cachedPayments = await localDataSource.getCachedPayments();
        return Right(PaginatedResult<Payment>(
          items: cachedPayments,
          totalCount: cachedPayments.length,
          pageNumber: 1,
          pageSize: cachedPayments.length,
        ));
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<Payment>>> getPaymentsByBooking({
    required String bookingId,
    int? pageNumber,
    int? pageSize,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getPaymentsByBooking(
          bookingId: bookingId,
          pageNumber: pageNumber,
          pageSize: pageSize,
        );

        return Right(PaginatedResult<Payment>(
          items: result.items,
          totalCount: result.totalCount,
          pageNumber: result.pageNumber,
          pageSize: result.pageSize,
        ));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<Payment>>> getPaymentsByStatus({
    required PaymentStatus status,
    int? pageNumber,
    int? pageSize,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getPaymentsByStatus(
          status: status,
          pageNumber: pageNumber,
          pageSize: pageSize,
        );

        return Right(PaginatedResult<Payment>(
          items: result.items,
          totalCount: result.totalCount,
          pageNumber: result.pageNumber,
          pageSize: result.pageSize,
        ));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<Payment>>> getPaymentsByUser({
    required String userId,
    int? pageNumber,
    int? pageSize,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getPaymentsByUser(
          userId: userId,
          pageNumber: pageNumber,
          pageSize: pageSize,
        );

        return Right(PaginatedResult<Payment>(
          items: result.items,
          totalCount: result.totalCount,
          pageNumber: result.pageNumber,
          pageSize: result.pageSize,
        ));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<Payment>>> getPaymentsByMethod({
    required PaymentMethod method,
    int? pageNumber,
    int? pageSize,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getPaymentsByMethod(
          method: method,
          pageNumber: pageNumber,
          pageSize: pageSize,
        );

        return Right(PaginatedResult<Payment>(
          items: result.items,
          totalCount: result.totalCount,
          pageNumber: result.pageNumber,
          pageSize: result.pageSize,
        ));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<Payment>>> getPaymentsByProperty({
    required String propertyId,
    DateTime? startDate,
    DateTime? endDate,
    int? pageNumber,
    int? pageSize,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getPaymentsByProperty(
          propertyId: propertyId,
          startDate: startDate,
          endDate: endDate,
          pageNumber: pageNumber,
          pageSize: pageSize,
        );

        return Right(PaginatedResult<Payment>(
          items: result.items,
          totalCount: result.totalCount,
          pageNumber: result.pageNumber,
          pageSize: result.pageSize,
        ));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, PaymentAnalytics>> getPaymentAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String? propertyId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getPaymentAnalytics(
          startDate: startDate,
          endDate: endDate,
          propertyId: propertyId,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getRevenueReport({
    required DateTime startDate,
    required DateTime endDate,
    String? propertyId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getRevenueReport(
          startDate: startDate,
          endDate: endDate,
          propertyId: propertyId,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<PaymentTrend>>> getPaymentTrends({
    required DateTime startDate,
    required DateTime endDate,
    String? propertyId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getPaymentTrends(
          startDate: startDate,
          endDate: endDate,
          propertyId: propertyId,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, RefundAnalytics>> getRefundStatistics({
    DateTime? startDate,
    DateTime? endDate,
    String? propertyId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getRefundStatistics(
          startDate: startDate,
          endDate: endDate,
          propertyId: propertyId,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }
}
