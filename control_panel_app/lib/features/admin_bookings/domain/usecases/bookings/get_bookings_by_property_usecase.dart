import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/models/paginated_result.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../../../../../core/enums/booking_status.dart';
import '../../entities/booking.dart';
import '../../repositories/bookings_repository.dart';

class GetBookingsByPropertyUseCase
    implements UseCase<PaginatedResult<Booking>, GetBookingsByPropertyParams> {
  final BookingsRepository repository;

  GetBookingsByPropertyUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<Booking>>> call(
    GetBookingsByPropertyParams params,
  ) async {
    return await repository.getBookingsByProperty(
      propertyId: params.propertyId,
      startDate: params.startDate,
      endDate: params.endDate,
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
      status: params.status,
      paymentStatus: params.paymentStatus,
      guestNameOrEmail: params.guestNameOrEmail,
      bookingSource: params.bookingSource,
      isWalkIn: params.isWalkIn,
      minTotalPrice: params.minTotalPrice,
      minGuestsCount: params.minGuestsCount,
      sortBy: params.sortBy,
    );
  }
}

class GetBookingsByPropertyParams extends Equatable {
  final String propertyId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? pageNumber;
  final int? pageSize;
  final BookingStatus? status;
  final String? paymentStatus;
  final String? guestNameOrEmail;
  final String? bookingSource;
  final bool? isWalkIn;
  final double? minTotalPrice;
  final int? minGuestsCount;
  final String? sortBy;

  const GetBookingsByPropertyParams({
    required this.propertyId,
    this.startDate,
    this.endDate,
    this.pageNumber,
    this.pageSize,
    this.status,
    this.paymentStatus,
    this.guestNameOrEmail,
    this.bookingSource,
    this.isWalkIn,
    this.minTotalPrice,
    this.minGuestsCount,
    this.sortBy,
  });

  @override
  List<Object?> get props => [
        propertyId,
        startDate,
        endDate,
        pageNumber,
        pageSize,
        status,
        paymentStatus,
        guestNameOrEmail,
        bookingSource,
        isWalkIn,
        minTotalPrice,
        minGuestsCount,
        sortBy,
      ];
}
