// lib/features/admin_availability_pricing/domain/repositories/availability_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/availability.dart';
import '../entities/unit_availability.dart';
import '../entities/booking_conflict.dart';

abstract class AvailabilityRepository {
  Future<Either<Failure, UnitAvailability>> getMonthlyAvailability(
    String unitId,
    int year,
    int month,
  );

  Future<Either<Failure, void>> updateAvailability(
    UnitAvailabilityEntry availability,
  );

  Future<Either<Failure, void>> bulkUpdateAvailability({
    required String unitId,
    required List<AvailabilityPeriod> periods,
    required bool overwriteExisting,
  });

  Future<Either<Failure, void>> cloneAvailability({
    required String unitId,
    required DateTime sourceStartDate,
    required DateTime sourceEndDate,
    required DateTime targetStartDate,
    required int repeatCount,
  });

  Future<Either<Failure, void>> deleteAvailability({
    required String unitId,
    String? availabilityId,
    DateTime? startDate,
    DateTime? endDate,
    bool? forceDelete,
  });

  Future<Either<Failure, CheckAvailabilityResponse>> checkAvailability({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    int? adults,
    int? children,
    bool? includePricing,
  });

  Future<Either<Failure, List<BookingConflict>>> checkConflicts({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
    String? startTime,
    String? endTime,
    required String checkType,
  });
}

class AvailabilityPeriod {
  final DateTime startDate;
  final DateTime endDate;
  final AvailabilityStatus status;
  final String? reason;
  final String? notes;
  final bool overwriteExisting;

  AvailabilityPeriod({
    required this.startDate,
    required this.endDate,
    required this.status,
    this.reason,
    this.notes,
    required this.overwriteExisting,
  });
}

class CheckAvailabilityResponse {
  final bool isAvailable;
  final String status;
  final List<BlockedPeriod> blockedPeriods;
  final List<AvailablePeriod> availablePeriods;
  final AvailabilityDetails details;
  final List<String> messages;

  CheckAvailabilityResponse({
    required this.isAvailable,
    required this.status,
    required this.blockedPeriods,
    required this.availablePeriods,
    required this.details,
    required this.messages,
  });
}

class BlockedPeriod {
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String reason;
  final String notes;

  BlockedPeriod({
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.reason,
    required this.notes,
  });
}

class AvailablePeriod {
  final DateTime startDate;
  final DateTime endDate;
  final double? price;
  final String? currency;

  AvailablePeriod({
    required this.startDate,
    required this.endDate,
    this.price,
    this.currency,
  });
}

class AvailabilityDetails {
  final String unitId;
  final String unitName;
  final String unitType;
  final int maxAdults;
  final int maxChildren;
  final int totalNights;
  final bool isMultiDays;
  final bool isRequiredToDetermineTheHour;

  AvailabilityDetails({
    required this.unitId,
    required this.unitName,
    required this.unitType,
    required this.maxAdults,
    required this.maxChildren,
    required this.totalNights,
    required this.isMultiDays,
    required this.isRequiredToDetermineTheHour,
  });
}