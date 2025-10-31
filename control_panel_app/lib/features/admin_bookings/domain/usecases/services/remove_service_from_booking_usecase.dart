import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../repositories/bookings_repository.dart';

class RemoveServiceFromBookingUseCase
    implements UseCase<bool, RemoveServiceFromBookingParams> {
  final BookingsRepository repository;

  RemoveServiceFromBookingUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(
      RemoveServiceFromBookingParams params) async {
    return await repository.removeServiceFromBooking(
      bookingId: params.bookingId,
      serviceId: params.serviceId,
    );
  }
}

class RemoveServiceFromBookingParams extends Equatable {
  final String bookingId;
  final String serviceId;

  const RemoveServiceFromBookingParams({
    required this.bookingId,
    required this.serviceId,
  });

  @override
  List<Object> get props => [bookingId, serviceId];
}
