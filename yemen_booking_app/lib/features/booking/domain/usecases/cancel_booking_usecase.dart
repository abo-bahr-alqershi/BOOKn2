import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/booking_repository.dart';

class CancelBookingUseCase implements UseCase<bool, CancelBookingParams> {
  final BookingRepository repository;

  CancelBookingUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(CancelBookingParams params) async {
    return await repository.cancelBooking(
      bookingId: params.bookingId,
      userId: params.userId,
      reason: params.reason,
    );
  }
}

class CancelBookingParams extends Equatable {
  final String bookingId;
  final String userId;
  final String reason;

  const CancelBookingParams({
    required this.bookingId,
    required this.userId,
    required this.reason,
  });

  @override
  List<Object> get props => [bookingId, userId, reason];
}