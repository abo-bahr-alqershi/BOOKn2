// lib/features/admin_availability_pricing/domain/entities/unit_availability.dart

import 'package:equatable/equatable.dart';
import 'availability.dart';

class UnitAvailability extends Equatable {
  final String unitId;
  final String unitName;
  final Map<String, AvailabilityStatusDetail> calendar;
  final List<AvailabilityPeriod> periods;
  final AvailabilityStats stats;

  const UnitAvailability({
    required this.unitId,
    required this.unitName,
    required this.calendar,
    required this.periods,
    required this.stats,
  });

  @override
  List<Object> get props => [unitId, unitName, calendar, periods, stats];
}

class AvailabilityStatusDetail extends Equatable {
  final AvailabilityStatus status;
  final String? reason;
  final String? bookingId;
  final String colorCode;

  const AvailabilityStatusDetail({
    required this.status,
    this.reason,
    this.bookingId,
    required this.colorCode,
  });

  @override
  List<Object?> get props => [status, reason, bookingId, colorCode];
}

class AvailabilityPeriod extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final AvailabilityStatus status;
  final String? reason;
  final String? notes;
  final bool overwriteExisting;

  const AvailabilityPeriod({
    required this.startDate,
    required this.endDate,
    required this.status,
    this.reason,
    this.notes,
    required this.overwriteExisting,
  });

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        status,
        reason,
        notes,
        overwriteExisting,
      ];
}

class AvailabilityStats extends Equatable {
  final int totalDays;
  final int availableDays;
  final int bookedDays;
  final int blockedDays;
  final int maintenanceDays;
  final double occupancyRate;

  const AvailabilityStats({
    required this.totalDays,
    required this.availableDays,
    required this.bookedDays,
    required this.blockedDays,
    required this.maintenanceDays,
    required this.occupancyRate,
  });

  @override
  List<Object> get props => [
        totalDays,
        availableDays,
        bookedDays,
        blockedDays,
        maintenanceDays,
        occupancyRate,
      ];
}