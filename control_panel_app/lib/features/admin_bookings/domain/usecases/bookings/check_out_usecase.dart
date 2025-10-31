import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../repositories/bookings_repository.dart';

class CheckOutUseCase implements UseCase<bool, CheckOutParams> {
  final BookingsRepository repository;

  CheckOutUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(CheckOutParams params) async {
    return await repository.checkOut(bookingId: params.bookingId);
  }
}

class CheckOutParams extends Equatable {
  final String bookingId;

  const CheckOutParams({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}
