import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/usecases/usecase.dart';
import '../../entities/payment_analytics.dart';
import '../../repositories/payments_repository.dart';

class GetPaymentTrendsUseCase
    implements UseCase<List<PaymentTrend>, GetPaymentTrendsParams> {
  final PaymentsRepository repository;

  GetPaymentTrendsUseCase(this.repository);

  @override
  Future<Either<Failure, List<PaymentTrend>>> call(
    GetPaymentTrendsParams params,
  ) async {
    return await repository.getPaymentTrends(
      startDate: params.startDate,
      endDate: params.endDate,
      propertyId: params.propertyId,
    );
  }
}

class GetPaymentTrendsParams extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final String? propertyId;

  const GetPaymentTrendsParams({
    required this.startDate,
    required this.endDate,
    this.propertyId,
  });

  @override
  List<Object?> get props => [startDate, endDate, propertyId];
}
