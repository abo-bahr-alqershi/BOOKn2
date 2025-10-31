import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/booking.dart';
import '../repositories/booking_repository.dart';

class GetBookingDetailsUseCase implements UseCase<Booking, GetBookingDetailsParams> {
  final BookingRepository repository;

  GetBookingDetailsUseCase(this.repository);

  @override
  Future<Either<Failure, Booking>> call(GetBookingDetailsParams params) async {
    return await repository.getBookingDetails(
      bookingId: params.bookingId,
      userId: params.userId,
    );
  }
}

class GetBookingDetailsParams extends Equatable {
  final String bookingId;
  final String userId;

  const GetBookingDetailsParams({
    required this.bookingId,
    required this.userId,
  });

  @override
  List<Object> get props => [bookingId, userId];
}