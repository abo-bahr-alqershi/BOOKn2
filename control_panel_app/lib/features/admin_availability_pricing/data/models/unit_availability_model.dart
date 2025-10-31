// lib/features/admin_availability_pricing/data/models/unit_availability_model.dart

import '../../domain/entities/unit_availability.dart';
import '../../domain/entities/availability.dart';
import '../../domain/repositories/availability_repository.dart'
    as availability_repo;
import 'package:intl/intl.dart';

class UnitAvailabilityModel extends UnitAvailability {
  const UnitAvailabilityModel({
    required super.unitId,
    required super.unitName,
    required super.calendar,
    required super.periods,
    required super.stats,
  });

  factory UnitAvailabilityModel.fromJson(Map<String, dynamic> json) {
    final Map<String, AvailabilityStatusDetail> calendar = {};
    if (json['calendar'] != null) {
      final dateFmt = DateFormat('yyyy-MM-dd');
      (json['calendar'] as Map<String, dynamic>).forEach((key, value) {
        String normalizedKey = key;
        try {
          // Handle keys like '2025-09-14T00:00:00' or RFC strings
          final dt = DateTime.parse(key);
          normalizedKey = dateFmt.format(DateTime(dt.year, dt.month, dt.day));
        } catch (_) {
          // If parsing fails, attempt to trim to date portion if possible
          if (key.length >= 10) {
            normalizedKey = key.substring(0, 10);
          }
        }
        calendar[normalizedKey] = AvailabilityStatusDetailModel.fromJson(value);
      });
    }

    final List<AvailabilityPeriod> periods = [];
    if (json['periods'] != null) {
      periods.addAll(
        (json['periods'] as List)
            .map((e) => AvailabilityPeriodModel.fromJson(e))
            .toList(),
      );
    }

    return UnitAvailabilityModel(
      unitId: json['unitId'] as String,
      unitName: json['unitName'] as String,
      calendar: calendar,
      periods: periods,
      stats: AvailabilityStatsModel.fromJson(json['stats']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> calendarJson = {};
    calendar.forEach((key, value) {
      calendarJson[key] = (value as AvailabilityStatusDetailModel).toJson();
    });

    return {
      'unitId': unitId,
      'unitName': unitName,
      'calendar': calendarJson,
      'periods':
          periods.map((e) => (e as AvailabilityPeriodModel).toJson()).toList(),
      'stats': (stats as AvailabilityStatsModel).toJson(),
    };
  }
}

class AvailabilityStatusDetailModel extends AvailabilityStatusDetail {
  const AvailabilityStatusDetailModel({
    required super.status,
    super.reason,
    super.bookingId,
    required super.colorCode,
  });

  factory AvailabilityStatusDetailModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityStatusDetailModel(
      status: _parseStatus(json['status'] as String),
      reason: json['reason'] as String?,
      bookingId: json['bookingId'] as String?,
      colorCode: json['colorCode'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': _statusToString(status),
      if (reason != null) 'reason': reason,
      if (bookingId != null) 'bookingId': bookingId,
      'colorCode': colorCode,
    };
  }

  static AvailabilityStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return AvailabilityStatus.available;
      case 'unavailable':
        return AvailabilityStatus.blocked;
      case 'maintenance':
        return AvailabilityStatus.maintenance;
      case 'blocked':
        return AvailabilityStatus.blocked;
      case 'booked':
        return AvailabilityStatus.booked;
      default:
        return AvailabilityStatus.available;
    }
  }

  static String _statusToString(AvailabilityStatus status) {
    switch (status) {
      case AvailabilityStatus.available:
        return 'available';
      case AvailabilityStatus.booked:
        return 'booked';
      case AvailabilityStatus.blocked:
        return 'blocked';
      case AvailabilityStatus.maintenance:
        return 'maintenance';
      case AvailabilityStatus.ownerUse:
        return 'OwnerUse';
    }
  }
}

class AvailabilityPeriodModel extends AvailabilityPeriod {
  const AvailabilityPeriodModel({
    required super.startDate,
    required super.endDate,
    required super.status,
    super.reason,
    super.notes,
    required super.overwriteExisting,
  });

  factory AvailabilityPeriodModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityPeriodModel(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      status:
          AvailabilityStatusDetailModel._parseStatus(json['status'] as String),
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      overwriteExisting: json['overwriteExisting'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': AvailabilityStatusDetailModel._statusToString(status),
      if (reason != null) 'reason': reason,
      if (notes != null) 'notes': notes,
      'overwriteExisting': overwriteExisting,
    };
  }
}

class AvailabilityStatsModel extends AvailabilityStats {
  const AvailabilityStatsModel({
    required super.totalDays,
    required super.availableDays,
    required super.bookedDays,
    required super.blockedDays,
    required super.maintenanceDays,
    required super.occupancyRate,
  });

  factory AvailabilityStatsModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityStatsModel(
      totalDays: json['totalDays'] as int,
      availableDays: json['availableDays'] as int,
      bookedDays: json['bookedDays'] as int,
      blockedDays: json['blockedDays'] as int,
      maintenanceDays: (json['maintenanceDays'] as int?) ?? 0,
      occupancyRate: (json['occupancyRate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDays': totalDays,
      'availableDays': availableDays,
      'bookedDays': bookedDays,
      'blockedDays': blockedDays,
      'maintenanceDays': maintenanceDays,
      'occupancyRate': occupancyRate,
    };
  }
}

class CheckAvailabilityResponseModel
    extends availability_repo.CheckAvailabilityResponse {
  CheckAvailabilityResponseModel({
    required super.isAvailable,
    required super.status,
    required super.blockedPeriods,
    required super.availablePeriods,
    required super.details,
    required super.messages,
  });

  factory CheckAvailabilityResponseModel.fromJson(Map<String, dynamic> json) {
    return CheckAvailabilityResponseModel(
      isAvailable: json['isAvailable'] as bool,
      status: json['status'] as String,
      blockedPeriods: (json['blockedPeriods'] as List)
          .map((e) => BlockedPeriodModel.fromJson(e))
          .toList(),
      availablePeriods: (json['availablePeriods'] as List)
          .map((e) => AvailablePeriodModel.fromJson(e))
          .toList(),
      details: AvailabilityDetailsModel.fromJson(json['details']),
      messages: List<String>.from(json['messages'] ?? []),
    );
  }
}

class BlockedPeriodModel extends availability_repo.BlockedPeriod {
  BlockedPeriodModel({
    required super.startDate,
    required super.endDate,
    required super.status,
    required super.reason,
    required super.notes,
  });

  factory BlockedPeriodModel.fromJson(Map<String, dynamic> json) {
    return BlockedPeriodModel(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      status: json['status'] as String,
      reason: json['reason'] as String,
      notes: json['notes'] as String,
    );
  }
}

class AvailablePeriodModel extends availability_repo.AvailablePeriod {
  AvailablePeriodModel({
    required super.startDate,
    required super.endDate,
    super.price,
    super.currency,
  });

  factory AvailablePeriodModel.fromJson(Map<String, dynamic> json) {
    return AvailablePeriodModel(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      currency: json['currency'] as String?,
    );
  }
}

class AvailabilityDetailsModel extends availability_repo.AvailabilityDetails {
  AvailabilityDetailsModel({
    required super.unitId,
    required super.unitName,
    required super.unitType,
    required super.maxAdults,
    required super.maxChildren,
    required super.totalNights,
    required super.isMultiDays,
    required super.isRequiredToDetermineTheHour,
  });

  factory AvailabilityDetailsModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityDetailsModel(
      unitId: json['unitId'] as String,
      unitName: json['unitName'] as String,
      unitType: json['unitType'] as String,
      maxAdults: json['maxAdults'] as int,
      maxChildren: json['maxChildren'] as int,
      totalNights: json['totalNights'] as int,
      isMultiDays: json['isMultiDays'] as bool,
      isRequiredToDetermineTheHour:
          json['isRequiredToDetermineTheHour'] as bool,
    );
  }
}
