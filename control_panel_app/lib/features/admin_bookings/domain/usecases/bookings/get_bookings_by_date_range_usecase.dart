import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/models/paginated_result.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../entities/booking.dart';
import '../../repositories/bookings_repository.dart';

class GetBookingsByDateRangeUseCase
    implements UseCase<PaginatedResult<Booking>, GetBookingsByDateRangeParams> {
  final BookingsRepository repository;

  GetBookingsByDateRangeUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<Booking>>> call(
    GetBookingsByDateRangeParams params,
  ) async {
    return await repository.getBookingsByDateRange(
      startDate: params.startDate,
      endDate: params.endDate,
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
      userId: params.userId,
      guestNameOrEmail: params.guestNameOrEmail,
      unitId: params.unitId,
      bookingSource: params.bookingSource,
      isWalkIn: params.isWalkIn,
      minTotalPrice: params.minTotalPrice,
      minGuestsCount: params.minGuestsCount,
      sortBy: params.sortBy,
    );
  }
}

class GetBookingsByDateRangeParams extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final int? pageNumber;
  final int? pageSize;
  final String? userId;
  final String? guestNameOrEmail;
  final String? unitId;
  final String? bookingSource;
  final bool? isWalkIn;
  final double? minTotalPrice;
  final int? minGuestsCount;
  final String? sortBy;

  const GetBookingsByDateRangeParams({
    required this.startDate,
    required this.endDate,
    this.pageNumber,
    this.pageSize,
    this.userId,
    this.guestNameOrEmail,
    this.unitId,
    this.bookingSource,
    this.isWalkIn,
    this.minTotalPrice,
    this.minGuestsCount,
    this.sortBy,
  });

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        pageNumber,
        pageSize,
        userId,
        guestNameOrEmail,
        unitId,
        bookingSource,
        isWalkIn,
        minTotalPrice,
        minGuestsCount,
        sortBy,
      ];
}
