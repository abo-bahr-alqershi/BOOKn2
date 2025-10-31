import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/booking.dart';
import '../entities/booking_request.dart';
import '../repositories/booking_repository.dart';

class CreateBookingUseCase implements UseCase<Booking, BookingRequest> {
  final BookingRepository repository;

  CreateBookingUseCase(this.repository);

  @override
  Future<Either<Failure, Booking>> call(BookingRequest params) async {
    return await repository.createBooking(params);
  }
}