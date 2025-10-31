import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../repositories/bookings_repository.dart';

class AddServiceToBookingUseCase
    implements UseCase<bool, AddServiceToBookingParams> {
  final BookingsRepository repository;

  AddServiceToBookingUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(AddServiceToBookingParams params) async {
    return await repository.addServiceToBooking(
      bookingId: params.bookingId,
      serviceId: params.serviceId,
    );
  }
}

class AddServiceToBookingParams extends Equatable {
  final String bookingId;
  final String serviceId;

  const AddServiceToBookingParams({
    required this.bookingId,
    required this.serviceId,
  });

  @override
  List<Object> get props => [bookingId, serviceId];
}
