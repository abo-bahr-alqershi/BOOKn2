// lib/features/admin_availability_pricing/domain/entities/booking_conflict.dart

import 'package:equatable/equatable.dart';

enum ConflictType {
  availability,
  pricing,
}

enum ImpactLevel {
  low,
  medium,
  high,
  critical,
}

class BookingConflict extends Equatable {
  final String? conflictId;
  final String unitId;
  final String bookingId;
  final String? bookingStatus;
  final double? totalAmount;
  final String? paymentStatus;
  final ConflictType? conflictType;
  final ImpactLevel? impactLevel;
  final List<String>? suggestedActions;

  const BookingConflict({
    this.conflictId,
    required this.unitId,
    required this.bookingId,
    this.bookingStatus,
    this.totalAmount,
    this.paymentStatus,
    this.conflictType,
    this.impactLevel,
    this.suggestedActions,
  });

  @override
  List<Object?> get props => [
        conflictId,
        unitId,
        bookingId,
        bookingStatus,
        totalAmount,
        paymentStatus,
        conflictType,
        impactLevel,
        suggestedActions,
      ];
}