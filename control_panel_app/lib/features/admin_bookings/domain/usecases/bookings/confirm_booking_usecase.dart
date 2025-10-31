import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../repositories/bookings_repository.dart';

class ConfirmBookingUseCase implements UseCase<bool, ConfirmBookingParams> {
  final BookingsRepository repository;

  ConfirmBookingUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(ConfirmBookingParams params) async {
    return await repository.confirmBooking(bookingId: params.bookingId);
  }
}

class ConfirmBookingParams extends Equatable {
  final String bookingId;

  const ConfirmBookingParams({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}
