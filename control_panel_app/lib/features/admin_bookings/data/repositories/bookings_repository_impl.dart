import 'package:dartz/dartz.dart';
import '../../../../../core/error/exceptions.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/models/paginated_result.dart';
import '../../../../../core/enums/booking_status.dart';
import '../../../../../core/network/network_info.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/booking_details.dart';
import '../../domain/entities/booking_report.dart';
import '../../domain/entities/booking_trends.dart';
import '../../domain/entities/booking_window_analysis.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../../domain/usecases/register_booking_payment.dart';
import '../datasources/bookings_local_datasource.dart';
import '../datasources/bookings_remote_datasource.dart';
import '../models/booking_model.dart';

class BookingsRepositoryImpl implements BookingsRepository {
  final BookingsRemoteDataSource remoteDataSource;
  final BookingsLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  BookingsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, bool>> cancelBooking({
    required String bookingId,
    required String cancellationReason,
    bool refundPayments = false,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.cancelBooking(
          bookingId: bookingId,
          cancellationReason: cancellationReason,
          refundPayments: refundPayments,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure.meta(
          message: e.message,
          code: e.code,
          showAsDialog: e.showAsDialog,
        ));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateBooking({
    required String bookingId,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guestsCount,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.updateBooking(
          bookingId: bookingId,
          checkIn: checkIn,
          checkOut: checkOut,
          guestsCount: guestsCount,
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
  Future<Either<Failure, bool>> confirmBooking(
      {required String bookingId}) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.confirmBooking(
          bookingId: bookingId,
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
  Future<Either<Failure, bool>> checkIn({required String bookingId}) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.checkIn(
          bookingId: bookingId,
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
  Future<Either<Failure, bool>> checkOut({required String bookingId}) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.checkOut(
          bookingId: bookingId,
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
  Future<Either<Failure, bool>> completeBooking(
      {required String bookingId}) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.completeBooking(
          bookingId: bookingId,
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
  Future<Either<Failure, Payment>> registerBookingPayment(
      RegisterPaymentParams params) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.registerBookingPayment(params);
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
  Future<Either<Failure, bool>> addServiceToBooking({
    required String bookingId,
    required String serviceId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.addServiceToBooking(
          bookingId: bookingId,
          serviceId: serviceId,
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
  Future<Either<Failure, bool>> removeServiceFromBooking({
    required String bookingId,
    required String serviceId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.removeServiceFromBooking(
          bookingId: bookingId,
          serviceId: serviceId,
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
  Future<Either<Failure, List<Service>>> getBookingServices({
    required String bookingId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getBookingServices(
          bookingId: bookingId,
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
  Future<Either<Failure, Booking>> getBookingById({
    required String bookingId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getBookingById(
          bookingId: bookingId,
        );
        // Cache the booking
        await localDataSource.cacheBookingDetails(bookingId, result);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    } else {
      // Try to get from cache
      try {
        final cachedBooking =
            await localDataSource.getCachedBookingDetails(bookingId);
        if (cachedBooking != null) {
          return Right(cachedBooking);
        } else {
          return const Left(CacheFailure('No cached data available'));
        }
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    }
  }

  @override
  Future<Either<Failure, BookingDetails>> getBookingDetails({
    required String bookingId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getBookingDetails(
          bookingId: bookingId,
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
  Future<Either<Failure, PaginatedResult<Booking>>> getBookingsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int? pageNumber,
    int? pageSize,
    String? userId,
    String? guestNameOrEmail,
    String? unitId,
    String? bookingSource,
    bool? isWalkIn,
    double? minTotalPrice,
    int? minGuestsCount,
    String? sortBy,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteBookings = await remoteDataSource.getBookingsByDateRange(
          startDate: startDate,
          endDate: endDate,
          pageNumber: pageNumber,
          pageSize: pageSize,
          userId: userId,
          guestNameOrEmail: guestNameOrEmail,
          unitId: unitId,
          bookingSource: bookingSource,
          isWalkIn: isWalkIn,
          minTotalPrice: minTotalPrice,
          minGuestsCount: minGuestsCount,
          sortBy: sortBy,
        );

        return Right(PaginatedResult<Booking>(
          items: remoteBookings.items,
          pageNumber: remoteBookings.pageNumber,
          pageSize: remoteBookings.pageSize,
          totalCount: remoteBookings.totalCount,
          metadata: remoteBookings.metadata,
        ));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    } else {
      // Try to get from cache
      try {
        final cachedBookings = await localDataSource.getCachedBookings();
        return Right(PaginatedResult<Booking>(
          items: cachedBookings,
          totalCount: cachedBookings.length,
          pageNumber: 1,
          pageSize: cachedBookings.length,
        ));
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<Booking>>> getBookingsByProperty({
    required String propertyId,
    DateTime? startDate,
    DateTime? endDate,
    int? pageNumber,
    int? pageSize,
    BookingStatus? status,
    String? paymentStatus,
    String? guestNameOrEmail,
    String? bookingSource,
    bool? isWalkIn,
    double? minTotalPrice,
    int? minGuestsCount,
    String? sortBy,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getBookingsByProperty(
          propertyId: propertyId,
          startDate: startDate,
          endDate: endDate,
          pageNumber: pageNumber,
          pageSize: pageSize,
          status: status,
          paymentStatus: paymentStatus,
          guestNameOrEmail: guestNameOrEmail,
          bookingSource: bookingSource,
          isWalkIn: isWalkIn,
          minTotalPrice: minTotalPrice,
          minGuestsCount: minGuestsCount,
          sortBy: sortBy,
        );

        return Right(PaginatedResult<Booking>(
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
  Future<Either<Failure, PaginatedResult<Booking>>> getBookingsByStatus({
    required BookingStatus status,
    int? pageNumber,
    int? pageSize,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getBookingsByStatus(
          status: status,
          pageNumber: pageNumber,
          pageSize: pageSize,
        );

        return Right(PaginatedResult<Booking>(
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
  Future<Either<Failure, PaginatedResult<Booking>>> getBookingsByUnit({
    required String unitId,
    DateTime? startDate,
    DateTime? endDate,
    int? pageNumber,
    int? pageSize,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getBookingsByUnit(
          unitId: unitId,
          startDate: startDate,
          endDate: endDate,
          pageNumber: pageNumber,
          pageSize: pageSize,
        );

        return Right(PaginatedResult<Booking>(
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
  Future<Either<Failure, PaginatedResult<Booking>>> getBookingsByUser({
    required String userId,
    int? pageNumber,
    int? pageSize,
    BookingStatus? status,
    String? guestNameOrEmail,
    String? unitId,
    String? bookingSource,
    bool? isWalkIn,
    double? minTotalPrice,
    int? minGuestsCount,
    String? sortBy,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getBookingsByUser(
          userId: userId,
          pageNumber: pageNumber,
          pageSize: pageSize,
          status: status,
          guestNameOrEmail: guestNameOrEmail,
          unitId: unitId,
          bookingSource: bookingSource,
          isWalkIn: isWalkIn,
          minTotalPrice: minTotalPrice,
          minGuestsCount: minGuestsCount,
          sortBy: sortBy,
        );

        return Right(PaginatedResult<Booking>(
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
  Future<Either<Failure, BookingReport>> getBookingReport({
    required DateTime startDate,
    required DateTime endDate,
    String? propertyId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getBookingReport(
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
  Future<Either<Failure, BookingTrends>> getBookingTrends({
    String? propertyId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getBookingTrends(
          propertyId: propertyId,
          startDate: startDate,
          endDate: endDate,
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
  Future<Either<Failure, BookingWindowAnalysis>> getBookingWindowAnalysis({
    required String propertyId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getBookingWindowAnalysis(
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
