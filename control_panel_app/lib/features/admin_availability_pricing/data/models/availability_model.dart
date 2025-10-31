// lib/features/admin_availability_pricing/data/models/availability_model.dart

import '../../domain/entities/availability.dart';

class UnitAvailabilityEntryModel extends UnitAvailabilityEntry {
  const UnitAvailabilityEntryModel({
    String? availabilityId,
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
    required AvailabilityStatus status,
    String? reason,
    String? notes,
    String? bookingId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super(
          availabilityId: availabilityId,
          unitId: unitId,
          startDate: startDate,
          endDate: endDate,
          status: status,
          reason: reason,
          notes: notes,
          bookingId: bookingId,
          createdBy: createdBy,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory UnitAvailabilityEntryModel.fromJson(Map<String, dynamic> json) {
    return UnitAvailabilityEntryModel(
      availabilityId: json['id'] as String?,
      unitId: json['unitId'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      status: _parseStatus(json['status'] as String),
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      bookingId: json['bookingId'] as String?,
      createdBy: json['createdBy'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (availabilityId != null) 'id': availabilityId,
      'unitId': unitId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': _statusToString(status),
      if (reason != null) 'reason': reason,
      if (notes != null) 'notes': notes,
      if (bookingId != null) 'bookingId': bookingId,
      if (createdBy != null) 'createdBy': createdBy,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  static AvailabilityStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return AvailabilityStatus.available;
      case 'booked':
        return AvailabilityStatus.booked;
      case 'blocked':
        return AvailabilityStatus.blocked;
      case 'maintenance':
        return AvailabilityStatus.maintenance;
      case 'owneruse':
      case 'ownerUse':
      case 'OwnerUse':
        return AvailabilityStatus.ownerUse;
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

  static UnavailabilityReason _parseReason(String reason) {
    switch (reason.toLowerCase()) {
      case 'maintenance':
        return UnavailabilityReason.maintenance;
      case 'vacation':
        return UnavailabilityReason.vacation;
      case 'private_booking':
      case 'privatebooking':
        return UnavailabilityReason.privateBooking;
      case 'renovation':
        return UnavailabilityReason.renovation;
      default:
        return UnavailabilityReason.other;
    }
  }

  static String _reasonToString(UnavailabilityReason reason) {
    switch (reason) {
      case UnavailabilityReason.maintenance:
        return 'maintenance';
      case UnavailabilityReason.vacation:
        return 'vacation';
      case UnavailabilityReason.privateBooking:
        return 'private_booking';
      case UnavailabilityReason.renovation:
        return 'renovation';
      case UnavailabilityReason.other:
        return 'other';
    }
  }
}