// lib/features/admin_availability_pricing/presentation/bloc/availability/availability_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/unit_availability.dart'
    hide AvailabilityPeriod;
import '../../../domain/entities/availability.dart';
import '../../../domain/entities/booking_conflict.dart';
import '../../../domain/usecases/availability/get_monthly_availability_usecase.dart';
import '../../../domain/usecases/availability/update_availability_usecase.dart';
import '../../../domain/usecases/availability/bulk_update_availability_usecase.dart';
import '../../../domain/usecases/availability/check_availability_usecase.dart';
import '../../../domain/usecases/availability/clone_availability_usecase.dart';
import '../../../domain/usecases/availability/delete_availability_usecase.dart';
import '../../../domain/repositories/availability_repository.dart';

part 'availability_event.dart';
part 'availability_state.dart';

class AvailabilityBloc extends Bloc<AvailabilityEvent, AvailabilityState> {
  final GetMonthlyAvailabilityUseCase getMonthlyAvailabilityUseCase;
  final UpdateAvailabilityUseCase updateAvailabilityUseCase;
  final BulkUpdateAvailabilityUseCase bulkUpdateAvailabilityUseCase;
  final CheckAvailabilityUseCase checkAvailabilityUseCase;
  final CloneAvailabilityUseCase? cloneAvailabilityUseCase;
  final DeleteAvailabilityUseCase? deleteAvailabilityUseCase;

  AvailabilityBloc({
    required this.getMonthlyAvailabilityUseCase,
    required this.updateAvailabilityUseCase,
    required this.bulkUpdateAvailabilityUseCase,
    required this.checkAvailabilityUseCase,
    this.cloneAvailabilityUseCase,
    this.deleteAvailabilityUseCase,
  }) : super(AvailabilityInitial()) {
    on<LoadMonthlyAvailability>(_onLoadMonthlyAvailability);
    on<UpdateAvailability>(_onUpdateAvailability);
    on<UpdateSingleDayAvailability>(_onUpdateSingleDayAvailability);
    on<UpdateDateRangeAvailability>(_onUpdateDateRangeAvailability);
    on<BulkUpdateAvailability>(_onBulkUpdateAvailability);
    on<CheckAvailability>(_onCheckAvailability);
    on<SelectUnit>(_onSelectUnit);
    on<ChangeMonth>(_onChangeMonth);
    on<CloneAvailability>(_onCloneAvailability);
    on<DeleteAvailability>(_onDeleteAvailability);
    on<ExportAvailabilityData>(_onExportAvailabilityData);
    on<ImportAvailabilityData>(_onImportAvailabilityData);
  }

  Future<void> _onLoadMonthlyAvailability(
    LoadMonthlyAvailability event,
    Emitter<AvailabilityState> emit,
  ) async {
    emit(AvailabilityLoading());

    final result = await getMonthlyAvailabilityUseCase(
      GetMonthlyAvailabilityParams(
        unitId: event.unitId,
        year: event.year,
        month: event.month,
      ),
    );

    result.fold(
      (failure) => emit(AvailabilityError(failure.message)),
      (unitAvailability) => emit(AvailabilityLoaded(
        unitAvailability: unitAvailability,
        selectedUnitId: event.unitId,
        currentYear: event.year,
        currentMonth: event.month,
      )),
    );
  }

  Future<void> _onUpdateAvailability(
    UpdateAvailability event,
    Emitter<AvailabilityState> emit,
  ) async {
    if (state is AvailabilityLoaded) {
      final currentState = state as AvailabilityLoaded;
      emit(AvailabilityUpdating(
        unitAvailability: currentState.unitAvailability,
        selectedUnitId: currentState.selectedUnitId,
        currentYear: currentState.currentYear,
        currentMonth: currentState.currentMonth,
      ));

      final result = await updateAvailabilityUseCase(
        UpdateAvailabilityParams(availability: event.availability),
      );

      result.fold(
        (failure) => emit(AvailabilityError(failure.message)),
        (_) {
          add(LoadMonthlyAvailability(
            unitId: currentState.selectedUnitId,
            year: currentState.currentYear,
            month: currentState.currentMonth,
          ));
        },
      );
    }
  }

  Future<void> _onUpdateSingleDayAvailability(
    UpdateSingleDayAvailability event,
    Emitter<AvailabilityState> emit,
  ) async {
    if (state is AvailabilityLoaded) {
      final currentState = state as AvailabilityLoaded;

      final availability = UnitAvailabilityEntry(
        unitId: event.unitId,
        startDate: event.date,
        endDate: event.date,
        status: event.status,
        reason: event.reason,
        notes: event.notes,
      );

      emit(AvailabilityUpdating(
        unitAvailability: currentState.unitAvailability,
        selectedUnitId: currentState.selectedUnitId,
        currentYear: currentState.currentYear,
        currentMonth: currentState.currentMonth,
      ));

      final result = await updateAvailabilityUseCase(
        UpdateAvailabilityParams(availability: availability),
      );

      result.fold(
        (failure) => emit(AvailabilityError(failure.message)),
        (_) {
          add(LoadMonthlyAvailability(
            unitId: currentState.selectedUnitId,
            year: currentState.currentYear,
            month: currentState.currentMonth,
          ));
        },
      );
    }
  }

  Future<void> _onUpdateDateRangeAvailability(
    UpdateDateRangeAvailability event,
    Emitter<AvailabilityState> emit,
  ) async {
    if (state is AvailabilityLoaded) {
      final currentState = state as AvailabilityLoaded;

      final availability = UnitAvailabilityEntry(
        unitId: event.unitId,
        startDate: event.startDate,
        endDate: event.endDate,
        status: event.status,
        reason: event.reason,
        notes: event.notes,
      );

      emit(AvailabilityUpdating(
        unitAvailability: currentState.unitAvailability,
        selectedUnitId: currentState.selectedUnitId,
        currentYear: currentState.currentYear,
        currentMonth: currentState.currentMonth,
      ));

      final result = await updateAvailabilityUseCase(
        UpdateAvailabilityParams(availability: availability),
      );

      result.fold(
        (failure) => emit(AvailabilityError(failure.message)),
        (_) {
          add(LoadMonthlyAvailability(
            unitId: currentState.selectedUnitId,
            year: currentState.currentYear,
            month: currentState.currentMonth,
          ));
        },
      );
    }
  }

  Future<void> _onBulkUpdateAvailability(
    BulkUpdateAvailability event,
    Emitter<AvailabilityState> emit,
  ) async {
    if (state is AvailabilityLoaded) {
      final currentState = state as AvailabilityLoaded;
      emit(AvailabilityUpdating(
        unitAvailability: currentState.unitAvailability,
        selectedUnitId: currentState.selectedUnitId,
        currentYear: currentState.currentYear,
        currentMonth: currentState.currentMonth,
      ));

      // Create AvailabilityPeriod objects
      List<AvailabilityPeriod> periods = [];

      if (event.weekdays != null && event.weekdays!.isNotEmpty) {
        // Filter dates by weekdays
        DateTime currentDate = event.startDate;
        while (currentDate.isBefore(event.endDate) ||
            currentDate.isAtSameMomentAs(event.endDate)) {
          if (event.weekdays!.contains(currentDate.weekday % 7)) {
            periods.add(AvailabilityPeriod(
              startDate: currentDate,
              endDate: currentDate,
              status: event.status,
              reason: event.reason,
              notes: event.notes,
              overwriteExisting: event.overwriteExisting,
            ));
          }
          currentDate = currentDate.add(const Duration(days: 1));
        }
      } else {
        // Update entire range
        periods.add(AvailabilityPeriod(
          startDate: event.startDate,
          endDate: event.endDate,
          status: event.status,
          reason: event.reason,
          notes: event.notes,
          overwriteExisting: event.overwriteExisting,
        ));
      }

      final result = await bulkUpdateAvailabilityUseCase(
        BulkUpdateAvailabilityParams(
          unitId: event.unitId,
          periods: periods,
          overwriteExisting: event.overwriteExisting,
        ),
      );

      result.fold(
        (failure) => emit(AvailabilityError(failure.message)),
        (_) {
          add(LoadMonthlyAvailability(
            unitId: currentState.selectedUnitId,
            year: currentState.currentYear,
            month: currentState.currentMonth,
          ));
        },
      );
    }
  }

  Future<void> _onCheckAvailability(
    CheckAvailability event,
    Emitter<AvailabilityState> emit,
  ) async {
    final result = await checkAvailabilityUseCase(
      CheckAvailabilityParams(
        unitId: event.unitId,
        checkIn: event.checkIn,
        checkOut: event.checkOut,
        adults: event.adults,
        children: event.children,
        includePricing: event.includePricing,
      ),
    );

    result.fold(
      (failure) => emit(AvailabilityError(failure.message)),
      (response) {
        if (state is AvailabilityLoaded) {
          final currentState = state as AvailabilityLoaded;
          emit(currentState.copyWith(
            availabilityCheckResponse: response,
          ));
        }
      },
    );
  }

  Future<void> _onCloneAvailability(
    CloneAvailability event,
    Emitter<AvailabilityState> emit,
  ) async {
    if (cloneAvailabilityUseCase != null && state is AvailabilityLoaded) {
      final currentState = state as AvailabilityLoaded;

      final result = await cloneAvailabilityUseCase!(
        CloneAvailabilityParams(
          unitId: event.sourceUnitId,
          sourceStartDate: event.sourceStartDate,
          sourceEndDate: event.sourceEndDate,
          targetStartDate: event.targetStartDate,
          repeatCount: event.repeatCount,
        ),
      );

      result.fold(
        (failure) => emit(AvailabilityError(failure.message)),
        (_) {
          // Reload current month after cloning
          add(LoadMonthlyAvailability(
            unitId: currentState.selectedUnitId,
            year: currentState.currentYear,
            month: currentState.currentMonth,
          ));
        },
      );
    }
  }

  Future<void> _onDeleteAvailability(
    DeleteAvailability event,
    Emitter<AvailabilityState> emit,
  ) async {
    if (deleteAvailabilityUseCase != null && state is AvailabilityLoaded) {
      final currentState = state as AvailabilityLoaded;

      final result = await deleteAvailabilityUseCase!(
        DeleteAvailabilityParams(
          unitId: event.unitId,
          availabilityId: event.availabilityId,
          startDate: event.startDate,
          endDate: event.endDate,
          forceDelete: event.forceDelete,
        ),
      );

      result.fold(
        (failure) => emit(AvailabilityError(failure.message)),
        (_) {
          // Reload current month after deletion
          add(LoadMonthlyAvailability(
            unitId: currentState.selectedUnitId,
            year: currentState.currentYear,
            month: currentState.currentMonth,
          ));
        },
      );
    }
  }

  void _onSelectUnit(
    SelectUnit event,
    Emitter<AvailabilityState> emit,
  ) {
    if (state is AvailabilityLoaded) {
      final currentState = state as AvailabilityLoaded;
      add(LoadMonthlyAvailability(
        unitId: event.unitId,
        year: currentState.currentYear,
        month: currentState.currentMonth,
      ));
    } else {
      // If no state, load current month
      final now = DateTime.now();
      add(LoadMonthlyAvailability(
        unitId: event.unitId,
        year: now.year,
        month: now.month,
      ));
    }
  }

  void _onChangeMonth(
    ChangeMonth event,
    Emitter<AvailabilityState> emit,
  ) {
    if (state is AvailabilityLoaded) {
      final currentState = state as AvailabilityLoaded;
      add(LoadMonthlyAvailability(
        unitId: currentState.selectedUnitId,
        year: event.year,
        month: event.month,
      ));
    }
  }

  Future<void> _onExportAvailabilityData(
    ExportAvailabilityData event,
    Emitter<AvailabilityState> emit,
  ) async {
    // TODO: Implement export functionality
    // This would typically call an export use case
  }

  Future<void> _onImportAvailabilityData(
    ImportAvailabilityData event,
    Emitter<AvailabilityState> emit,
  ) async {
    // TODO: Implement import functionality
    // This would typically call an import use case
    if (state is AvailabilityLoaded) {
      final currentState = state as AvailabilityLoaded;
      // After import, reload current month
      add(LoadMonthlyAvailability(
        unitId: currentState.selectedUnitId,
        year: currentState.currentYear,
        month: currentState.currentMonth,
      ));
    }
  }
}
