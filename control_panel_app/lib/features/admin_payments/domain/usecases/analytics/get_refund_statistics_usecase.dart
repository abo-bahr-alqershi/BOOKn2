import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../entities/payment_analytics.dart';
import '../../repositories/payments_repository.dart';

class GetRefundStatisticsUseCase
    implements UseCase<RefundAnalytics, GetRefundStatisticsParams> {
  final PaymentsRepository repository;

  GetRefundStatisticsUseCase(this.repository);

  @override
  Future<Either<Failure, RefundAnalytics>> call(
    GetRefundStatisticsParams params,
  ) async {
    return await repository.getRefundStatistics(
      startDate: params.startDate,
      endDate: params.endDate,
      propertyId: params.propertyId,
    );
  }
}

class GetRefundStatisticsParams extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? propertyId;

  const GetRefundStatisticsParams({
    this.startDate,
    this.endDate,
    this.propertyId,
  });

  @override
  List<Object?> get props => [startDate, endDate, propertyId];
}
