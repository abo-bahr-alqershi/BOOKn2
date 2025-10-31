// lib/features/admin_availability_pricing/presentation/bloc/availability/availability_event.dart

part of 'availability_bloc.dart';

abstract class AvailabilityEvent extends Equatable {
  const AvailabilityEvent();

  @override
  List<Object?> get props => [];
}

class LoadMonthlyAvailability extends AvailabilityEvent {
  final String unitId;
  final int year;
  final int month;

  const LoadMonthlyAvailability({
    required this.unitId,
    required this.year,
    required this.month,
  });

  @override
  List<Object> get props => [unitId, year, month];
}

class UpdateAvailability extends AvailabilityEvent {
  final UnitAvailabilityEntry availability;

  const UpdateAvailability({required this.availability});

  @override
  List<Object> get props => [availability];
}

class UpdateSingleDayAvailability extends AvailabilityEvent {
  final String unitId;
  final DateTime date;
  final AvailabilityStatus status;
  final String? reason;
  final String? notes;

  const UpdateSingleDayAvailability({
    required this.unitId,
    required this.date,
    required this.status,
    this.reason,
    this.notes,
  });

  @override
  List<Object?> get props => [unitId, date, status, reason, notes];
}

class UpdateDateRangeAvailability extends AvailabilityEvent {
  final String unitId;
  final DateTime startDate;
  final DateTime endDate;
  final AvailabilityStatus status;
  final String? reason;
  final String? notes;

  const UpdateDateRangeAvailability({
    required this.unitId,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.reason,
    this.notes,
  });

  @override
  List<Object?> get props => [unitId, startDate, endDate, status, reason, notes];
}

class BulkUpdateAvailability extends AvailabilityEvent {
  final String unitId;
  final DateTime startDate;
  final DateTime endDate;
  final AvailabilityStatus status;
  final List<int>? weekdays;
  final String? reason;
  final String? notes;
  final bool overwriteExisting;

  const BulkUpdateAvailability({
    required this.unitId,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.weekdays,
    this.reason,
    this.notes,
    this.overwriteExisting = false,
  });

  @override
  List<Object?> get props => [
        unitId,
        startDate,
        endDate,
        status,
        weekdays,
        reason,
        notes,
        overwriteExisting,
      ];
}

class CloneAvailability extends AvailabilityEvent {
  final String sourceUnitId;
  final DateTime sourceStartDate;
  final DateTime sourceEndDate;
  final DateTime targetStartDate;
  final int repeatCount;

  const CloneAvailability({
    required this.sourceUnitId,
    required this.sourceStartDate,
    required this.sourceEndDate,
    required this.targetStartDate,
    required this.repeatCount,
  });

  @override
  List<Object> get props => [
        sourceUnitId,
        sourceStartDate,
        sourceEndDate,
        targetStartDate,
        repeatCount,
      ];
}

class DeleteAvailability extends AvailabilityEvent {
  final String unitId;
  final String? availabilityId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? forceDelete;

  const DeleteAvailability({
    required this.unitId,
    this.availabilityId,
    this.startDate,
    this.endDate,
    this.forceDelete,
  });

  @override
  List<Object?> get props => [
        unitId,
        availabilityId,
        startDate,
        endDate,
        forceDelete,
      ];
}

class CheckAvailability extends AvailabilityEvent {
  final String unitId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int? adults;
  final int? children;
  final bool? includePricing;

  const CheckAvailability({
    required this.unitId,
    required this.checkIn,
    required this.checkOut,
    this.adults,
    this.children,
    this.includePricing,
  });

  @override
  List<Object?> get props => [unitId, checkIn, checkOut, adults, children, includePricing];
}

class SelectUnit extends AvailabilityEvent {
  final String unitId;

  const SelectUnit({required this.unitId});

  @override
  List<Object> get props => [unitId];
}

class ChangeMonth extends AvailabilityEvent {
  final int year;
  final int month;

  const ChangeMonth({required this.year, required this.month});

  @override
  List<Object> get props => [year, month];
}

class ExportAvailabilityData extends AvailabilityEvent {
  final String unitId;
  final int year;
  final int month;

  const ExportAvailabilityData({
    required this.unitId,
    required this.year,
    required this.month,
  });

  @override
  List<Object> get props => [unitId, year, month];
}

class ImportAvailabilityData extends AvailabilityEvent {
  final String unitId;
  final Map<String, dynamic> data;

  const ImportAvailabilityData({
    required this.unitId,
    required this.data,
  });

  @override
  List<Object> get props => [unitId, data];
}