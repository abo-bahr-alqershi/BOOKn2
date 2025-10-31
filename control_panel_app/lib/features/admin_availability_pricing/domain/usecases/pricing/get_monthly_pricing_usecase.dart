// lib/features/admin_availability_pricing/domain/usecases/pricing/get_monthly_pricing_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/pricing_rule.dart';
import '../../repositories/pricing_repository.dart';

class GetMonthlyPricingUseCase
    implements UseCase<UnitPricing, GetMonthlyPricingParams> {
  final PricingRepository repository;

  GetMonthlyPricingUseCase(this.repository);

  @override
  Future<Either<Failure, UnitPricing>> call(
    GetMonthlyPricingParams params,
  ) async {
    return await repository.getMonthlyPricing(
      params.unitId,
      params.year,
      params.month,
    );
  }
}

class GetMonthlyPricingParams extends Equatable {
  final String unitId;
  final int year;
  final int month;

  const GetMonthlyPricingParams({
    required this.unitId,
    required this.year,
    required this.month,
  });

  @override
  List<Object> get props => [unitId, year, month];
}