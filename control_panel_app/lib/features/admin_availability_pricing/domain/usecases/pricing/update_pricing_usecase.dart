// lib/features/admin_availability_pricing/domain/usecases/pricing/update_pricing_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/pricing.dart';
import '../../repositories/pricing_repository.dart';

class UpdatePricingUseCase implements UseCase<void, UpdatePricingParams> {
  final PricingRepository repository;

  UpdatePricingUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdatePricingParams params) async {
    return await repository.updatePricing(
      unitId: params.unitId,
      startDate: params.startDate,
      endDate: params.endDate,
      price: params.price,
      priceType: params.priceType,
      currency: params.currency,
      pricingTier: params.pricingTier,
      percentageChange: params.percentageChange,
      minPrice: params.minPrice,
      maxPrice: params.maxPrice,
      description: params.description,
      overwriteExisting: params.overwriteExisting,
    );
  }
}

class UpdatePricingParams extends Equatable {
  final String unitId;
  final DateTime startDate;
  final DateTime endDate;
  final double price;
  final PriceType priceType;
  final String currency;
  final PricingTier pricingTier;
  final double? percentageChange;
  final double? minPrice;
  final double? maxPrice;
  final String? description;
  final bool overwriteExisting;

  const UpdatePricingParams({
    required this.unitId,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.priceType,
    required this.currency,
    required this.pricingTier,
    this.percentageChange,
    this.minPrice,
    this.maxPrice,
    this.description,
    this.overwriteExisting = false,
  });

  @override
  List<Object?> get props => [
        unitId,
        startDate,
        endDate,
        price,
        priceType,
        currency,
        pricingTier,
        percentageChange,
        minPrice,
        maxPrice,
        description,
        overwriteExisting,
      ];
}