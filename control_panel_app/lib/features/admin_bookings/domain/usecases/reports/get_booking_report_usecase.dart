import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../entities/booking_report.dart';
import '../../repositories/bookings_repository.dart';

class GetBookingReportUseCase
    implements UseCase<BookingReport, GetBookingReportParams> {
  final BookingsRepository repository;

  GetBookingReportUseCase(this.repository);

  @override
  Future<Either<Failure, BookingReport>> call(
      GetBookingReportParams params) async {
    return await repository.getBookingReport(
      startDate: params.startDate,
      endDate: params.endDate,
      propertyId: params.propertyId,
    );
  }
}

class GetBookingReportParams extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final String? propertyId;

  const GetBookingReportParams({
    required this.startDate,
    required this.endDate,
    this.propertyId,
  });

  @override
  List<Object?> get props => [startDate, endDate, propertyId];
}
