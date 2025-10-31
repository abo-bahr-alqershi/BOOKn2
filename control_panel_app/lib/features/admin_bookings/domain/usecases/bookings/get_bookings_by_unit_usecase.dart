import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/models/paginated_result.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../entities/booking.dart';
import '../../repositories/bookings_repository.dart';

class GetBookingsByUnitUseCase
    implements UseCase<PaginatedResult<Booking>, GetBookingsByUnitParams> {
  final BookingsRepository repository;

  GetBookingsByUnitUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<Booking>>> call(
    GetBookingsByUnitParams params,
  ) async {
    return await repository.getBookingsByUnit(
      unitId: params.unitId,
      startDate: params.startDate,
      endDate: params.endDate,
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
    );
  }
}

class GetBookingsByUnitParams extends Equatable {
  final String unitId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? pageNumber;
  final int? pageSize;

  const GetBookingsByUnitParams({
    required this.unitId,
    this.startDate,
    this.endDate,
    this.pageNumber,
    this.pageSize,
  });

  @override
  List<Object?> get props => [
        unitId,
        startDate,
        endDate,
        pageNumber,
        pageSize,
      ];
}
