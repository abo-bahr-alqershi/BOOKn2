import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../repositories/unit_types_repository.dart';

class UpdateUnitTypeUseCase implements UseCase<bool, UpdateUnitTypeParams> {
  final UnitTypesRepository repository;

  UpdateUnitTypeUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(UpdateUnitTypeParams params) async {
    return await repository.updateUnitType(
      unitTypeId: params.unitTypeId,
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

class UpdateUnitTypeParams extends Equatable {
  final String unitTypeId;
  final String name;
  final int maxCapacity;
  final String icon;
  final double? systemCommissionRate;
  final bool isHasAdults;
  final bool isHasChildren;
  final bool isMultiDays;
  final bool isRequiredToDetermineTheHour;

  const UpdateUnitTypeParams({
    required this.unitTypeId,
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
        unitTypeId,
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
