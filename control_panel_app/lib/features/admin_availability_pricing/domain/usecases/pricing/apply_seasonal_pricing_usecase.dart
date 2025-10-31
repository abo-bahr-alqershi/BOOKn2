// lib/features/admin_availability_pricing/domain/usecases/pricing/apply_seasonal_pricing_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/seasonal_pricing.dart';
import '../../repositories/pricing_repository.dart';

class ApplySeasonalPricingUseCase
    implements UseCase<void, ApplySeasonalPricingParams> {
  final PricingRepository repository;

  ApplySeasonalPricingUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ApplySeasonalPricingParams params) async {
    return await repository.applySeasonalPricing(
      unitId: params.unitId,
      seasons: params.seasons,
      currency: params.currency,
    );
  }
}

class ApplySeasonalPricingParams extends Equatable {
  final String unitId;
  final List<SeasonalPricing> seasons;
  final String currency;

  const ApplySeasonalPricingParams({
    required this.unitId,
    required this.seasons,
    required this.currency,
  });

  @override
  List<Object> get props => [unitId, seasons, currency];
}