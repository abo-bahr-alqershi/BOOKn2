import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../repositories/bookings_repository.dart';

class UpdateBookingUseCase implements UseCase<bool, UpdateBookingParams> {
  final BookingsRepository repository;

  UpdateBookingUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(UpdateBookingParams params) async {
    return await repository.updateBooking(
      bookingId: params.bookingId,
      checkIn: params.checkIn,
      checkOut: params.checkOut,
      guestsCount: params.guestsCount,
    );
  }
}

class UpdateBookingParams extends Equatable {
  final String bookingId;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int? guestsCount;

  const UpdateBookingParams({
    required this.bookingId,
    this.checkIn,
    this.checkOut,
    this.guestsCount,
  });

  @override
  List<Object?> get props => [bookingId, checkIn, checkOut, guestsCount];
}
