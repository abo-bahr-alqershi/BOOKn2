// lib/features/admin_availability_pricing/domain/usecases/pricing/bulk_update_pricing_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../repositories/pricing_repository.dart';

class BulkUpdatePricingUseCase
    implements UseCase<void, BulkUpdatePricingParams> {
  final PricingRepository repository;

  BulkUpdatePricingUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(BulkUpdatePricingParams params) async {
    return await repository.bulkUpdatePricing(
      unitId: params.unitId,
      periods: params.periods,
      overwriteExisting: params.overwriteExisting,
    );
  }
}

class BulkUpdatePricingParams extends Equatable {
  final String unitId;
  final List<PricingPeriod> periods;
  final bool overwriteExisting;

  const BulkUpdatePricingParams({
    required this.unitId,
    required this.periods,
    required this.overwriteExisting,
  });

  @override
  List<Object> get props => [unitId, periods, overwriteExisting];
}