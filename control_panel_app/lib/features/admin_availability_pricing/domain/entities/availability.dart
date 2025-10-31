// lib/features/admin_availability_pricing/domain/entities/availability.dart

import 'package:equatable/equatable.dart';

enum AvailabilityStatus {
  available,
  booked,
  blocked,
  maintenance,
  ownerUse, // استخدام المالك - Owner use
}

enum UnavailabilityReason {
  maintenance,
  vacation,
  privateBooking,
  renovation,
  other,
}

class UnitAvailabilityEntry extends Equatable {
  final String? availabilityId;
  final String unitId;
  final DateTime startDate;
  final DateTime endDate;
  final AvailabilityStatus status;
  final String? reason;
  final String? notes;
  final String? bookingId;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UnitAvailabilityEntry({
    this.availabilityId,
    required this.unitId,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.reason,
    this.notes,
    this.bookingId,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  UnitAvailabilityEntry copyWith({
    String? availabilityId,
    String? unitId,
    DateTime? startDate,
    DateTime? endDate,
    AvailabilityStatus? status,
    String? reason,
    String? notes,
    String? bookingId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UnitAvailabilityEntry(
      availabilityId: availabilityId ?? this.availabilityId,
      unitId: unitId ?? this.unitId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      bookingId: bookingId ?? this.bookingId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        availabilityId,
        unitId,
        startDate,
        endDate,
        status,
        reason,
        notes,
        bookingId,
        createdBy,
        createdAt,
        updatedAt,
      ];
}