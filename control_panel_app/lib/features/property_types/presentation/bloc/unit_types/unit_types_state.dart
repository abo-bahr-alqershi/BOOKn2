import 'package:equatable/equatable.dart';
import '../../../domain/entities/unit_type.dart';

abstract class UnitTypesState extends Equatable {
  const UnitTypesState();

  @override
  List<Object?> get props => [];
}

class UnitTypesInitial extends UnitTypesState {}

class UnitTypesLoading extends UnitTypesState {}

class UnitTypesLoaded extends UnitTypesState {
  final List<UnitType> unitTypes;
  final UnitType? selectedUnitType;
  final int totalCount;
  final int currentPage;

  const UnitTypesLoaded({
    required this.unitTypes,
    this.selectedUnitType,
    required this.totalCount,
    required this.currentPage,
  });

  UnitTypesLoaded copyWith({
    List<UnitType>? unitTypes,
    UnitType? selectedUnitType,
    bool clearSelection = false,
    int? totalCount,
    int? currentPage,
  }) {
    return UnitTypesLoaded(
      unitTypes: unitTypes ?? this.unitTypes,
      selectedUnitType: clearSelection ? null : (selectedUnitType ?? this.selectedUnitType),
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [unitTypes, selectedUnitType, totalCount, currentPage];
}

class UnitTypesError extends UnitTypesState {
  final String message;

  const UnitTypesError({required this.message});

  @override
  List<Object> get props => [message];
}

class UnitTypeOperationLoading extends UnitTypesState {}

class UnitTypeOperationSuccess extends UnitTypesState {
  final String message;

  const UnitTypeOperationSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

class UnitTypeOperationError extends UnitTypesState {
  final String message;

  const UnitTypeOperationError({required this.message});

  @override
  List<Object> get props => [message];
}