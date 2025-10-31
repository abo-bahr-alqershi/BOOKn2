import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/models/paginated_result.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../../../../../core/enums/booking_status.dart';
import '../../entities/booking.dart';
import '../../repositories/bookings_repository.dart';

class GetBookingsByUserUseCase
    implements UseCase<PaginatedResult<Booking>, GetBookingsByUserParams> {
  final BookingsRepository repository;

  GetBookingsByUserUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<Booking>>> call(
    GetBookingsByUserParams params,
  ) async {
    return await repository.getBookingsByUser(
      userId: params.userId,
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
      status: params.status,
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

class GetBookingsByUserParams extends Equatable {
  final String userId;
  final int? pageNumber;
  final int? pageSize;
  final BookingStatus? status;
  final String? guestNameOrEmail;
  final String? unitId;
  final String? bookingSource;
  final bool? isWalkIn;
  final double? minTotalPrice;
  final int? minGuestsCount;
  final String? sortBy;

  const GetBookingsByUserParams({
    required this.userId,
    this.pageNumber,
    this.pageSize,
    this.status,
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
        userId,
        pageNumber,
        pageSize,
        status,
        guestNameOrEmail,
        unitId,
        bookingSource,
        isWalkIn,
        minTotalPrice,
        minGuestsCount,
        sortBy,
      ];
}
