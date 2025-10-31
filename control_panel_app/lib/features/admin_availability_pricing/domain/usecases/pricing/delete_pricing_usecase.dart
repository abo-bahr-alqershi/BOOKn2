// lib/features/admin_availability_pricing/domain/usecases/pricing/delete_pricing_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../repositories/pricing_repository.dart';

class DeletePricingUseCase implements UseCase<void, DeletePricingParams> {
  final PricingRepository repository;

  DeletePricingUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeletePricingParams params) async {
    return await repository.deletePricing(
      unitId: params.unitId,
      pricingId: params.pricingId,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

class DeletePricingParams extends Equatable {
  final String unitId;
  final String? pricingId;
  final DateTime? startDate;
  final DateTime? endDate;

  const DeletePricingParams({
    required this.unitId,
    this.pricingId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [unitId, pricingId, startDate, endDate];
}