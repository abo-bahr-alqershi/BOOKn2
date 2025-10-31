import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../repositories/bookings_repository.dart';

class CheckInUseCase implements UseCase<bool, CheckInParams> {
  final BookingsRepository repository;

  CheckInUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(CheckInParams params) async {
    return await repository.checkIn(bookingId: params.bookingId);
  }
}

class CheckInParams extends Equatable {
  final String bookingId;

  const CheckInParams({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}
