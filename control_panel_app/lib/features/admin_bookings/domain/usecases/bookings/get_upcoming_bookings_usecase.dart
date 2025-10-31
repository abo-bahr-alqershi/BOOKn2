import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/models/paginated_result.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../entities/booking.dart';
import '../../repositories/bookings_repository.dart';
import '../../../../../../core/enums/booking_status.dart';

/// Use case to get upcoming (future) bookings within a horizon window
class GetUpcomingBookingsUseCase
    extends UseCase<PaginatedResult<Booking>, GetUpcomingBookingsParams> {
  final BookingsRepository repository;

  GetUpcomingBookingsUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<Booking>>> call(
    GetUpcomingBookingsParams params,
  ) async {
    final DateTime now = params.now ?? DateTime.now();
    final DateTime end = now.add(Duration(days: params.horizonDays));

    if (params.propertyId != null) {
      return repository.getBookingsByProperty(
        propertyId: params.propertyId!,
        startDate: now,
        endDate: end,
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

    // fallback to date-range query with optional filters
    return repository.getBookingsByDateRange(
      startDate: now,
      endDate: end,
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
      userId: params.userId,
      guestNameOrEmail: params.guestNameOrEmail,
      unitId: params.unitId,
      bookingSource: params.bookingSource,
    );
  }
}

class GetUpcomingBookingsParams extends Equatable {
  final int horizonDays;
  final DateTime? now;
  final int? pageNumber;
  final int? pageSize;

  // Optional filters
  final String? propertyId;
  final String? userId;
  final String? unitId;
  final String? guestNameOrEmail;
  final String? bookingSource;
  final BookingStatus? status;
  final String? paymentStatus;
  final bool? isWalkIn;
  final double? minTotalPrice;
  final int? minGuestsCount;
  final String? sortBy;

  const GetUpcomingBookingsParams({
    this.horizonDays = 30,
    this.now,
    this.pageNumber,
    this.pageSize,
    this.propertyId,
    this.userId,
    this.unitId,
    this.guestNameOrEmail,
    this.bookingSource,
    this.status,
    this.paymentStatus,
    this.isWalkIn,
    this.minTotalPrice,
    this.minGuestsCount,
    this.sortBy,
  });

  @override
  List<Object?> get props => [
        horizonDays,
        now,
        pageNumber,
        pageSize,
        propertyId,
        userId,
        unitId,
        guestNameOrEmail,
        bookingSource,
        status,
        paymentStatus,
        isWalkIn,
        minTotalPrice,
        minGuestsCount,
        sortBy,
      ];
}
