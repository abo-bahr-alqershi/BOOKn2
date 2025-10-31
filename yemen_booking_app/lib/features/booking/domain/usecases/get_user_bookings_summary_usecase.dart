import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/booking_repository.dart';

class GetUserBookingsSummaryUseCase implements UseCase<Map<String, dynamic>, GetUserBookingsSummaryParams> {
  final BookingRepository repository;

  GetUserBookingsSummaryUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(GetUserBookingsSummaryParams params) async {
    return await repository.getUserBookingSummary(
      userId: params.userId,
      year: params.year,
    );
  }
}

class GetUserBookingsSummaryParams extends Equatable {
  final String userId;
  final int? year;

  const GetUserBookingsSummaryParams({
    required this.userId,
    this.year,
  });

  @override
  List<Object?> get props => [userId, year];
}