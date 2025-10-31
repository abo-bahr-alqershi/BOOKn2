part of 'unit_details_bloc.dart';

abstract class UnitDetailsEvent extends Equatable {
  const UnitDetailsEvent();

  @override
  List<Object> get props => [];
}

class LoadUnitDetailsEvent extends UnitDetailsEvent {
  final String unitId;

  const LoadUnitDetailsEvent({required this.unitId});

  @override
  List<Object> get props => [unitId];
}

class DeleteUnitDetailsEvent extends UnitDetailsEvent {
  final String unitId;

  const DeleteUnitDetailsEvent({required this.unitId});

  @override
  List<Object> get props => [unitId];
}

class AssignToSectionsEvent extends UnitDetailsEvent {
  final String unitId;
  final List<String> sectionIds;

  const AssignToSectionsEvent({
    required this.unitId,
    required this.sectionIds,
  });

  @override
  List<Object> get props => [unitId, sectionIds];
}