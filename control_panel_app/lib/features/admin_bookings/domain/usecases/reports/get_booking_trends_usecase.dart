import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../entities/booking_trends.dart';
import '../../repositories/bookings_repository.dart';

class GetBookingTrendsUseCase
    implements UseCase<BookingTrends, GetBookingTrendsParams> {
  final BookingsRepository repository;

  GetBookingTrendsUseCase(this.repository);

  @override
  Future<Either<Failure, BookingTrends>> call(
      GetBookingTrendsParams params) async {
    return await repository.getBookingTrends(
      propertyId: params.propertyId,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

class GetBookingTrendsParams extends Equatable {
  final String? propertyId;
  final DateTime startDate;
  final DateTime endDate;

  const GetBookingTrendsParams({
    this.propertyId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [propertyId, startDate, endDate];
}
