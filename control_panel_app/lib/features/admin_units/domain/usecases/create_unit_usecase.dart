import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repositories/units_repository.dart';

class CreateUnitUseCase implements UseCase<String, CreateUnitParams> {
  final UnitsRepository repository;

  CreateUnitUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(CreateUnitParams params) async {
    return await repository.createUnit(
      propertyId: params.propertyId,
      unitTypeId: params.unitTypeId,
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
      tempKey: params.tempKey,
    );
  }
}

class CreateUnitParams extends Equatable {
  final String propertyId;
  final String unitTypeId;
  final String name;
  final String description; 
  final Map<String, dynamic> basePrice;
  final String customFeatures;
  final String pricingMethod;
  final List<Map<String, dynamic>>? fieldValues;
  final List<String>? images;
  final int? adultCapacity;
  final int? childrenCapacity;
  final String? tempKey;
  final bool? allowsCancellation;
  final int? cancellationWindowDays;

  const CreateUnitParams({
    required this.propertyId,
    required this.unitTypeId,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.customFeatures,
    required this.pricingMethod,
    this.fieldValues,
    this.images,
    this.adultCapacity,
    this.childrenCapacity,
    this.tempKey,
    this.allowsCancellation,
    this.cancellationWindowDays,
  });

  // إضافة toJson للـ debugging
  Map<String, dynamic> toJson() => {
    'propertyId': propertyId,
    'unitTypeId': unitTypeId,
    'name': name,
    'description': description,
    'basePrice': basePrice,
    'customFeatures': customFeatures,
    'pricingMethod': pricingMethod,
    'fieldValues': fieldValues,
    'images': images,
    'adultCapacity': adultCapacity,
    'childrenCapacity': childrenCapacity,
    'tempKey': tempKey,
    'allowsCancellation': allowsCancellation,
    'cancellationWindowDays': cancellationWindowDays,
  };

  @override
  List<Object?> get props => [
    propertyId,
    unitTypeId,
    name,
    description,
    basePrice,
    customFeatures,
    pricingMethod,
    fieldValues,
    images,
    adultCapacity,
    childrenCapacity,
    tempKey,
  ];
}