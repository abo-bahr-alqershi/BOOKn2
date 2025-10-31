// lib/features/admin_availability_pricing/presentation/bloc/availability/availability_state.dart

part of 'availability_bloc.dart';

abstract class AvailabilityState extends Equatable {
  const AvailabilityState();

  @override
  List<Object?> get props => [];
}

class AvailabilityInitial extends AvailabilityState {}

class AvailabilityLoading extends AvailabilityState {}

class AvailabilityLoaded extends AvailabilityState {
  final UnitAvailability unitAvailability;
  final String selectedUnitId;
  final int currentYear;
  final int currentMonth;
  final CheckAvailabilityResponse? availabilityCheckResponse;
  final List<BookingConflict>? conflicts;

  const AvailabilityLoaded({
    required this.unitAvailability,
    required this.selectedUnitId,
    required this.currentYear,
    required this.currentMonth,
    this.availabilityCheckResponse,
    this.conflicts,
  });

  AvailabilityLoaded copyWith({
    UnitAvailability? unitAvailability,
    String? selectedUnitId,
    int? currentYear,
    int? currentMonth,
    CheckAvailabilityResponse? availabilityCheckResponse,
    List<BookingConflict>? conflicts,
  }) {
    return AvailabilityLoaded(
      unitAvailability: unitAvailability ?? this.unitAvailability,
      selectedUnitId: selectedUnitId ?? this.selectedUnitId,
      currentYear: currentYear ?? this.currentYear,
      currentMonth: currentMonth ?? this.currentMonth,
      availabilityCheckResponse:
          availabilityCheckResponse ?? this.availabilityCheckResponse,
      conflicts: conflicts ?? this.conflicts,
    );
  }

  @override
  List<Object?> get props => [
        unitAvailability,
        selectedUnitId,
        currentYear,
        currentMonth,
        availabilityCheckResponse,
        conflicts,
      ];
}

class AvailabilityUpdating extends AvailabilityLoaded {
  const AvailabilityUpdating({
    required super.unitAvailability,
    required super.selectedUnitId,
    required super.currentYear,
    required super.currentMonth,
  });
}

class AvailabilityError extends AvailabilityState {
  final String message;

  const AvailabilityError(this.message);

  @override
  List<Object> get props => [message];
}
