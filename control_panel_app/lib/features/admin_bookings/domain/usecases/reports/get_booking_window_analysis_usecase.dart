import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../entities/booking_window_analysis.dart';
import '../../repositories/bookings_repository.dart';

class GetBookingWindowAnalysisUseCase
    implements UseCase<BookingWindowAnalysis, GetBookingWindowAnalysisParams> {
  final BookingsRepository repository;

  GetBookingWindowAnalysisUseCase(this.repository);

  @override
  Future<Either<Failure, BookingWindowAnalysis>> call(
    GetBookingWindowAnalysisParams params,
  ) async {
    return await repository.getBookingWindowAnalysis(
      propertyId: params.propertyId,
    );
  }
}

class GetBookingWindowAnalysisParams extends Equatable {
  final String propertyId;

  const GetBookingWindowAnalysisParams({required this.propertyId});

  @override
  List<Object> get props => [propertyId];
}
