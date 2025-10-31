import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../entities/booking_details.dart';
import '../../repositories/bookings_repository.dart';

class GetBookingServicesUseCase
    implements UseCase<List<Service>, GetBookingServicesParams> {
  final BookingsRepository repository;

  GetBookingServicesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Service>>> call(
      GetBookingServicesParams params) async {
    return await repository.getBookingServices(bookingId: params.bookingId);
  }
}

class GetBookingServicesParams extends Equatable {
  final String bookingId;

  const GetBookingServicesParams({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}
