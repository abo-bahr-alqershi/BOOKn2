// lib/features/admin_units/presentation/bloc/units_list/units_list_event.dart

part of 'units_list_bloc.dart';

abstract class UnitsListEvent extends Equatable {
  const UnitsListEvent();

  @override
  List<Object?> get props => [];
}

class LoadUnitsEvent extends UnitsListEvent {
  final int? pageNumber;
  final int? pageSize;

  const LoadUnitsEvent({
    this.pageNumber,
    this.pageSize,
  });

  @override
  List<Object?> get props => [pageNumber, pageSize];
}

class LoadMoreUnitsEvent extends UnitsListEvent {
  final int pageNumber;

  const LoadMoreUnitsEvent({required this.pageNumber});

  @override
  List<Object?> get props => [pageNumber];
}

class SearchUnitsEvent extends UnitsListEvent {
  final String query;

  const SearchUnitsEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

class FilterUnitsEvent extends UnitsListEvent {
  final Map<String, dynamic> filters;

  const FilterUnitsEvent({required this.filters});

  @override
  List<Object?> get props => [filters];
}

class DeleteUnitEvent extends UnitsListEvent {
  final String unitId;

  const DeleteUnitEvent({required this.unitId});

  @override
  List<Object?> get props => [unitId];
}

class RefreshUnitsEvent extends UnitsListEvent {}

// أحداث التحديد
class SelectUnitEvent extends UnitsListEvent {
  final String unitId;

  const SelectUnitEvent({required this.unitId});

  @override
  List<Object?> get props => [unitId];
}

class DeselectUnitEvent extends UnitsListEvent {
  final String unitId;

  const DeselectUnitEvent({required this.unitId});

  @override
  List<Object?> get props => [unitId];
}

class SelectMultipleUnitsEvent extends UnitsListEvent {
  final List<String> unitIds;

  const SelectMultipleUnitsEvent({required this.unitIds});

  @override
  List<Object?> get props => [unitIds];
}

// أحداث الإجراءات الجماعية
class BulkActivateUnitsEvent extends UnitsListEvent {
  final List<String> unitIds;

  const BulkActivateUnitsEvent({required this.unitIds});

  @override
  List<Object?> get props => [unitIds];
}

class BulkDeactivateUnitsEvent extends UnitsListEvent {
  final List<String> unitIds;

  const BulkDeactivateUnitsEvent({required this.unitIds});

  @override
  List<Object?> get props => [unitIds];
}

class BulkDeleteUnitsEvent extends UnitsListEvent {
  final List<String> unitIds;

  const BulkDeleteUnitsEvent({required this.unitIds});

  @override
  List<Object?> get props => [unitIds];
}

class ExportUnitsEvent extends UnitsListEvent {
  final List<String> unitIds;

  const ExportUnitsEvent({required this.unitIds});

  @override
  List<Object?> get props => [unitIds];
}
