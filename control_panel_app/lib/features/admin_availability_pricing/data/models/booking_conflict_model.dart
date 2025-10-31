// lib/features/admin_availability_pricing/data/models/booking_conflict_model.dart

import '../../domain/entities/booking_conflict.dart';

class BookingConflictModel extends BookingConflict {
  const BookingConflictModel({
    String? conflictId,
    required String unitId,
    required String bookingId,
    String? bookingStatus,
    double? totalAmount,
    String? paymentStatus,
    ConflictType? conflictType,
    ImpactLevel? impactLevel,
    List<String>? suggestedActions,
  }) : super(
          conflictId: conflictId,
          unitId: unitId,
          bookingId: bookingId,
          bookingStatus: bookingStatus,
          totalAmount: totalAmount,
          paymentStatus: paymentStatus,
          conflictType: conflictType,
          impactLevel: impactLevel,
          suggestedActions: suggestedActions,
        );

  factory BookingConflictModel.fromJson(Map<String, dynamic> json) {
    return BookingConflictModel(
      conflictId: json['conflictId'] as String?,
      unitId: json['unitId'] as String,
      bookingId: json['bookingId'] as String,
      bookingStatus: json['bookingStatus'] as String?,
      totalAmount: json['totalAmount'] != null
          ? (json['totalAmount'] as num).toDouble()
          : null,
      paymentStatus: json['paymentStatus'] as String?,
      conflictType: json['conflictType'] != null
          ? _parseConflictType(json['conflictType'] as String)
          : null,
      impactLevel: json['impactLevel'] != null
          ? _parseImpactLevel(json['impactLevel'] as String)
          : null,
      suggestedActions: json['suggestedActions'] != null
          ? List<String>.from(json['suggestedActions'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (conflictId != null) 'conflictId': conflictId,
      'unitId': unitId,
      'bookingId': bookingId,
      if (bookingStatus != null) 'bookingStatus': bookingStatus,
      if (totalAmount != null) 'totalAmount': totalAmount,
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
      if (conflictType != null) 'conflictType': _conflictTypeToString(conflictType!),
      if (impactLevel != null) 'impactLevel': _impactLevelToString(impactLevel!),
      if (suggestedActions != null) 'suggestedActions': suggestedActions,
    };
  }

  static ConflictType _parseConflictType(String type) {
    switch (type.toLowerCase()) {
      case 'availability':
        return ConflictType.availability;
      case 'pricing':
        return ConflictType.pricing;
      default:
        return ConflictType.availability;
    }
  }

  static String _conflictTypeToString(ConflictType type) {
    switch (type) {
      case ConflictType.availability:
        return 'availability';
      case ConflictType.pricing:
        return 'pricing';
    }
  }

  static ImpactLevel _parseImpactLevel(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return ImpactLevel.low;
      case 'medium':
        return ImpactLevel.medium;
      case 'high':
        return ImpactLevel.high;
      case 'critical':
        return ImpactLevel.critical;
      default:
        return ImpactLevel.low;
    }
  }

  static String _impactLevelToString(ImpactLevel level) {
    switch (level) {
      case ImpactLevel.low:
        return 'low';
      case ImpactLevel.medium:
        return 'medium';
      case ImpactLevel.high:
        return 'high';
      case ImpactLevel.critical:
        return 'critical';
    }
  }
}