// lib/features/admin_availability_pricing/domain/usecases/pricing/copy_pricing_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../repositories/pricing_repository.dart';

class CopyPricingUseCase implements UseCase<void, CopyPricingParams> {
  final PricingRepository repository;

  CopyPricingUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CopyPricingParams params) async {
    return await repository.copyPricing(
      unitId: params.unitId,
      sourceStartDate: params.sourceStartDate,
      sourceEndDate: params.sourceEndDate,
      targetStartDate: params.targetStartDate,
      repeatCount: params.repeatCount,
      adjustmentType: params.adjustmentType,
      adjustmentValue: params.adjustmentValue,
      overwriteExisting: params.overwriteExisting,
    );
  }
}

class CopyPricingParams extends Equatable {
  final String unitId;
  final DateTime sourceStartDate;
  final DateTime sourceEndDate;
  final DateTime targetStartDate;
  final int repeatCount;
  final String adjustmentType;
  final double adjustmentValue;
  final bool overwriteExisting;

  const CopyPricingParams({
    required this.unitId,
    required this.sourceStartDate,
    required this.sourceEndDate,
    required this.targetStartDate,
    required this.repeatCount,
    required this.adjustmentType,
    required this.adjustmentValue,
    required this.overwriteExisting,
  });

  @override
  List<Object> get props => [
        unitId,
        sourceStartDate,
        sourceEndDate,
        targetStartDate,
        repeatCount,
        adjustmentType,
        adjustmentValue,
        overwriteExisting,
      ];
}