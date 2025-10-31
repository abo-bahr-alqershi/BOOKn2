import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../repositories/unit_types_repository.dart';

class CreateUnitTypeUseCase implements UseCase<String, CreateUnitTypeParams> {
  final UnitTypesRepository repository;

  CreateUnitTypeUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(CreateUnitTypeParams params) async {
    return await repository.createUnitType(
      propertyTypeId: params.propertyTypeId,
      name: params.name,
      maxCapacity: params.maxCapacity,
      icon: params.icon,
      systemCommissionRate: params.systemCommissionRate,
      isHasAdults: params.isHasAdults,
      isHasChildren: params.isHasChildren,
      isMultiDays: params.isMultiDays,
      isRequiredToDetermineTheHour: params.isRequiredToDetermineTheHour,
    );
  }
}

class CreateUnitTypeParams extends Equatable {
  final String propertyTypeId;
  final String name;
  final int maxCapacity;
  final String icon;
  final double? systemCommissionRate;
  final bool isHasAdults;
  final bool isHasChildren;
  final bool isMultiDays;
  final bool isRequiredToDetermineTheHour;

  const CreateUnitTypeParams({
    required this.propertyTypeId,
    required this.name,
    required this.maxCapacity,
    required this.icon,
    this.systemCommissionRate,
    required this.isHasAdults,
    required this.isHasChildren,
    required this.isMultiDays,
    required this.isRequiredToDetermineTheHour,
  });

  @override
  List<Object?> get props => [
        propertyTypeId,
        name,
        maxCapacity,
        icon,
        systemCommissionRate,
        isHasAdults,
        isHasChildren,
        isMultiDays,
        isRequiredToDetermineTheHour,
      ];
}
