import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/booking.dart';
import '../repositories/booking_repository.dart';

class AddServicesToBookingUseCase implements UseCase<Booking, AddServicesToBookingParams> {
  final BookingRepository repository;

  AddServicesToBookingUseCase(this.repository);

  @override
  Future<Either<Failure, Booking>> call(AddServicesToBookingParams params) async {
    return await repository.addServicesToBooking(
      bookingId: params.bookingId,
      serviceId: params.serviceId,
      quantity: params.quantity,
    );
  }
}

class AddServicesToBookingParams extends Equatable {
  final String bookingId;
  final String serviceId;
  final int quantity;

  const AddServicesToBookingParams({
    required this.bookingId,
    required this.serviceId,
    required this.quantity,
  });

  @override
  List<Object> get props => [bookingId, serviceId, quantity];
}