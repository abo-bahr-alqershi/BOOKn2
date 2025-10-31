import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repositories/units_repository.dart';

class UpdateUnitUseCase implements UseCase<bool, UpdateUnitParams> {
  final UnitsRepository repository;

  UpdateUnitUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(UpdateUnitParams params) async {
    return await repository.updateUnit(
      unitId: params.unitId,
      name: params.name,
      description: params.description,
      basePrice: params.basePrice,
      customFeatures: params.customFeatures,
      pricingMethod: params.pricingMethod,
      fieldValues: params.fieldValues,
      images: params.images,
      adultCapacity: params.adultCapacity,
      childrenCapacity: params.childrenCapacity,
      allowsCancellation: params.allowsCancellation,
      cancellationWindowDays: params.cancellationWindowDays,
    );
  }
}

class UpdateUnitParams extends Equatable {
  final String unitId;
  final String? name;
  final String? description;
  final Map<String, dynamic>? basePrice;
  final String? customFeatures;
  final String? pricingMethod;
  final List<Map<String, dynamic>>? fieldValues;
  final List<String>? images;
  final int? adultCapacity;
  final int? childrenCapacity;
  final bool? allowsCancellation;
  final int? cancellationWindowDays;

  const UpdateUnitParams({
    required this.unitId,
    this.name,
    this.description,
    this.basePrice,
    this.customFeatures,
    this.pricingMethod,
    this.fieldValues,
    this.images,
    this.adultCapacity,
    this.childrenCapacity,
    this.allowsCancellation,
    this.cancellationWindowDays,
  });

  @override
  List<Object?> get props => [
        unitId,
        name,
        description,
        basePrice,
        customFeatures,
        pricingMethod,
        fieldValues,
        images,
        adultCapacity,
        childrenCapacity,
        allowsCancellation,
        cancellationWindowDays,
      ];
}