import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../entities/booking.dart';
import '../../repositories/bookings_repository.dart';

class GetBookingByIdUseCase implements UseCase<Booking, GetBookingByIdParams> {
  final BookingsRepository repository;

  GetBookingByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Booking>> call(GetBookingByIdParams params) async {
    return await repository.getBookingById(bookingId: params.bookingId);
  }
}

class GetBookingByIdParams extends Equatable {
  final String bookingId;

  const GetBookingByIdParams({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}
