import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../repositories/bookings_repository.dart';

class CompleteBookingUseCase implements UseCase<bool, CompleteBookingParams> {
  final BookingsRepository repository;

  CompleteBookingUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(CompleteBookingParams params) async {
    return await repository.completeBooking(bookingId: params.bookingId);
  }
}

class CompleteBookingParams extends Equatable {
  final String bookingId;

  const CompleteBookingParams({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}
