import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/unit.dart';
import '../../../domain/usecases/get_unit_details_usecase.dart';
import '../../../domain/usecases/delete_unit_usecase.dart';
import '../../../domain/usecases/assign_unit_to_sections_usecase.dart';

part 'unit_details_event.dart';
part 'unit_details_state.dart';

class UnitDetailsBloc extends Bloc<UnitDetailsEvent, UnitDetailsState> {
  final GetUnitDetailsUseCase getUnitDetailsUseCase;
  final DeleteUnitUseCase deleteUnitUseCase;
  final AssignUnitToSectionsUseCase assignUnitToSectionsUseCase;

  UnitDetailsBloc({
    required this.getUnitDetailsUseCase,
    required this.deleteUnitUseCase,
    required this.assignUnitToSectionsUseCase,
  }) : super(UnitDetailsInitial()) {
    on<LoadUnitDetailsEvent>(_onLoadUnitDetails);
    on<DeleteUnitDetailsEvent>(_onDeleteUnit);
    on<AssignToSectionsEvent>(_onAssignToSections);
  }

  Future<void> _onLoadUnitDetails(
    LoadUnitDetailsEvent event,
    Emitter<UnitDetailsState> emit,
  ) async {
    emit(UnitDetailsLoading());

    final result = await getUnitDetailsUseCase(
      GetUnitDetailsParams(unitId: event.unitId),
    );

    result.fold(
      (failure) => emit(UnitDetailsError(message: failure.message)),
      (unit) => emit(UnitDetailsLoaded(unit: unit)),
    );
  }

  Future<void> _onDeleteUnit(
    DeleteUnitDetailsEvent event,
    Emitter<UnitDetailsState> emit,
  ) async {
    final result = await deleteUnitUseCase(event.unitId);

    result.fold(
      (failure) => emit(UnitDetailsError(message: failure.message)),
      (_) => emit(UnitDeleted()),
    );
  }

  Future<void> _onAssignToSections(
    AssignToSectionsEvent event,
    Emitter<UnitDetailsState> emit,
  ) async {
    final result = await assignUnitToSectionsUseCase(
      AssignUnitToSectionsParams(
        unitId: event.unitId,
        sectionIds: event.sectionIds,
      ),
    );

    result.fold(
      (failure) => emit(UnitDetailsError(message: failure.message)),
      (_) {
        if (state is UnitDetailsLoaded) {
          add(LoadUnitDetailsEvent(unitId: event.unitId));
        }
      },
    );
  }
}