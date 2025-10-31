import 'package:dartz/dartz.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/booking_request.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_datasource.dart';
import '../models/booking_request_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remoteDataSource;
  final InternetConnectionChecker internetConnectionChecker;

  BookingRepositoryImpl({
    required this.remoteDataSource,
    required this.internetConnectionChecker,
  });

  @override
  Future<Either<Failure, Booking>> createBooking(BookingRequest request) async {
    if (!(await internetConnectionChecker.hasConnection)) {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final requestModel = BookingRequestModel.fromEntity(request);
      final result = await remoteDataSource.createBooking(requestModel);
      
      if (result.success && result.data != null) {
        return Right(result.data!);
      } else {
        return Left(ServerFailure(result.message ?? 'فشل إنشاء الحجز'));
      }
    } catch (error) {
      return ErrorHandler.handle(error);
    }
  }

  @override
  Future<Either<Failure, Booking>> getBookingDetails({
    required String bookingId,
    required String userId,
  }) async {
    if (!(await internetConnectionChecker.hasConnection)) {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final result = await remoteDataSource.getBookingDetails(
        bookingId: bookingId,
        userId: userId,
      );
      
      if (result.success && result.data != null) {
        return Right(result.data!);
      } else {
        return Left(ServerFailure(result.message ?? 'فشل الحصول على تفاصيل الحجز'));
      }
    } catch (error) {
      return ErrorHandler.handle(error);
    }
  }

  @override
  Future<Either<Failure, bool>> cancelBooking({
    required String bookingId,
    required String userId,
    required String reason,
  }) async {
    if (!(await internetConnectionChecker.hasConnection)) {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final result = await remoteDataSource.cancelBooking(
        bookingId: bookingId,
        userId: userId,
        reason: reason,
      );
      
      if (result.success) {
        return Right(result.data ?? false);
      } else {
        return Left(ServerFailure(result.message ?? 'فشل إلغاء الحجز'));
      }
    } catch (error) {
      return ErrorHandler.handle(error);
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<Booking>>> getUserBookings({
    required String userId,
    String? status,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    if (!(await internetConnectionChecker.hasConnection)) {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final result = await remoteDataSource.getUserBookings(
        userId: userId,
        status: status,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
      
      if (result.success && result.data != null) {
        final paginatedBookings = PaginatedResult<Booking>(
          items: result.data!.items.cast<Booking>(),
          pageNumber: result.data!.pageNumber,
          pageSize: result.data!.pageSize,
          totalCount: result.data!.totalCount,
          metadata: result.data!.metadata,
        );
        return Right(paginatedBookings);
      } else {
        return Left(ServerFailure(result.message ?? 'فشل الحصول على الحجوزات'));
      }
    } catch (error) {
      return ErrorHandler.handle(error);
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getUserBookingSummary({
    required String userId,
    int? year,
  }) async {
    if (!(await internetConnectionChecker.hasConnection)) {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final result = await remoteDataSource.getUserBookingSummary(
        userId: userId,
        year: year,
      );
      
      if (result.success && result.data != null) {
        return Right(result.data!);
      } else {
        return Left(ServerFailure(result.message ?? 'فشل الحصول على ملخص الحجوزات'));
      }
    } catch (error) {
      return ErrorHandler.handle(error);
    }
  }

  @override
  Future<Either<Failure, Booking>> addServicesToBooking({
    required String bookingId,
    required String serviceId,
    required int quantity,
  }) async {
    if (!(await internetConnectionChecker.hasConnection)) {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final result = await remoteDataSource.addServicesToBooking(
        bookingId: bookingId,
        serviceId: serviceId,
        quantity: quantity,
      );
      
      if (result.success && result.data != null) {
        return Right(result.data!);
      } else {
        return Left(ServerFailure(result.message ?? 'فشل إضافة الخدمة'));
      }
    } catch (error) {
      return ErrorHandler.handle(error);
    }
  }

  @override
  Future<Either<Failure, bool>> checkAvailability({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guestsCount,
  }) async {
    if (!(await internetConnectionChecker.hasConnection)) {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final result = await remoteDataSource.checkAvailability(
        unitId: unitId,
        checkIn: checkIn,
        checkOut: checkOut,
        guestsCount: guestsCount,
      );
      
      if (result.success) {
        return Right(result.data ?? false);
      } else {
        return Left(ServerFailure(result.message ?? 'فشل التحقق من التوفر'));
      }
    } catch (error) {
      return ErrorHandler.handle(error);
    }
  }
}