import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../repositories/payments_repository.dart';

class GetRevenueReportUseCase
    implements UseCase<Map<String, dynamic>, GetRevenueReportParams> {
  final PaymentsRepository repository;

  GetRevenueReportUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
    GetRevenueReportParams params,
  ) async {
    return await repository.getRevenueReport(
      startDate: params.startDate,
      endDate: params.endDate,
      propertyId: params.propertyId,
    );
  }
}

class GetRevenueReportParams extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final String? propertyId;

  const GetRevenueReportParams({
    required this.startDate,
    required this.endDate,
    this.propertyId,
  });

  @override
  List<Object?> get props => [startDate, endDate, propertyId];
}
