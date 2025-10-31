import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/booking_repository.dart';

class CheckAvailabilityUseCase implements UseCase<bool, CheckAvailabilityParams> {
  final BookingRepository repository;

  CheckAvailabilityUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(CheckAvailabilityParams params) async {
    return await repository.checkAvailability(
      unitId: params.unitId,
      checkIn: params.checkIn,
      checkOut: params.checkOut,
      guestsCount: params.guestsCount,
    );
  }
}

class CheckAvailabilityParams extends Equatable {
  final String unitId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guestsCount;

  const CheckAvailabilityParams({
    required this.unitId,
    required this.checkIn,
    required this.checkOut,
    required this.guestsCount,
  });

  @override
  List<Object> get props => [unitId, checkIn, checkOut, guestsCount];
}