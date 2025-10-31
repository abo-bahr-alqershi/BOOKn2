import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../entities/payment_analytics.dart';
import '../../repositories/payments_repository.dart';

class GetPaymentAnalyticsUseCase
    implements UseCase<PaymentAnalytics, GetPaymentAnalyticsParams> {
  final PaymentsRepository repository;

  GetPaymentAnalyticsUseCase(this.repository);

  @override
  Future<Either<Failure, PaymentAnalytics>> call(
    GetPaymentAnalyticsParams params,
  ) async {
    return await repository.getPaymentAnalytics(
      startDate: params.startDate,
      endDate: params.endDate,
      propertyId: params.propertyId,
    );
  }
}

class GetPaymentAnalyticsParams extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? propertyId;

  const GetPaymentAnalyticsParams({
    this.startDate,
    this.endDate,
    this.propertyId,
  });

  @override
  List<Object?> get props => [startDate, endDate, propertyId];
}
