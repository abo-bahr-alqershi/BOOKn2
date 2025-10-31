import 'package:equatable/equatable.dart';

abstract class UnitTypesEvent extends Equatable {
  const UnitTypesEvent();

  @override
  List<Object?> get props => [];
}

class LoadUnitTypesEvent extends UnitTypesEvent {
  final String propertyTypeId;
  final int pageNumber;
  final int pageSize;

  const LoadUnitTypesEvent({
    required this.propertyTypeId,
    this.pageNumber = 1,
    this.pageSize = 1000,
  });

  @override
  List<Object> get props => [propertyTypeId, pageNumber, pageSize];
}

class CreateUnitTypeEvent extends UnitTypesEvent {
  final String propertyTypeId;
  final String name;
  final int maxCapacity;
  final String icon;
  final double? systemCommissionRate;
  final bool isHasAdults;
  final bool isHasChildren;
  final bool isMultiDays;
  final bool isRequiredToDetermineTheHour;

  const CreateUnitTypeEvent({
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

class UpdateUnitTypeEvent extends UnitTypesEvent {
  final String unitTypeId;
  final String name;
  final int maxCapacity;
  final String icon;
  final double? systemCommissionRate;
  final bool isHasAdults;
  final bool isHasChildren;
  final bool isMultiDays;
  final bool isRequiredToDetermineTheHour;

  const UpdateUnitTypeEvent({
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

class DeleteUnitTypeEvent extends UnitTypesEvent {
  final String unitTypeId;

  const DeleteUnitTypeEvent({required this.unitTypeId});

  @override
  List<Object> get props => [unitTypeId];
}

class SelectUnitTypeEvent extends UnitTypesEvent {
  final String? unitTypeId;

  const SelectUnitTypeEvent({this.unitTypeId});

  @override
  List<Object?> get props => [unitTypeId];
}
