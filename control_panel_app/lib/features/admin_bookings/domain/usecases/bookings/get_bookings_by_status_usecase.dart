import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/models/paginated_result.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../../../../../core/enums/booking_status.dart';
import '../../entities/booking.dart';
import '../../repositories/bookings_repository.dart';

class GetBookingsByStatusUseCase
    implements UseCase<PaginatedResult<Booking>, GetBookingsByStatusParams> {
  final BookingsRepository repository;

  GetBookingsByStatusUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<Booking>>> call(
    GetBookingsByStatusParams params,
  ) async {
    return await repository.getBookingsByStatus(
      status: params.status,
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
    );
  }
}

class GetBookingsByStatusParams extends Equatable {
  final BookingStatus status;
  final int? pageNumber;
  final int? pageSize;

  const GetBookingsByStatusParams({
    required this.status,
    this.pageNumber,
    this.pageSize,
  });

  @override
  List<Object?> get props => [status, pageNumber, pageSize];
}
