// lib/features/admin_availability_pricing/domain/entities/pricing.dart

import 'package:equatable/equatable.dart';

enum PricingTier {
  normal,
  high,
  peak,
  discount,
  custom,
}

enum PriceType {
  base,
  weekend,
  seasonal,
  holiday,
  specialEvent,
  custom,
}

class Pricing extends Equatable {
  final String? pricingId;
  final String? unitId;
  final PriceType priceType;
  final DateTime startDate;
  final DateTime endDate;
  final double priceAmount;
  final PricingTier? pricingTier;
  final double? percentageChange;
  final double? minPrice;
  final double? maxPrice;
  final String? description;
  final String? currency;
  final bool? isActive;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Pricing({
    this.pricingId,
    this.unitId,
    required this.priceType,
    required this.startDate,
    required this.endDate,
    required this.priceAmount,
    this.pricingTier,
    this.percentageChange,
    this.minPrice,
    this.maxPrice,
    this.description,
    this.currency,
    this.isActive,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  Pricing copyWith({
    String? pricingId,
    String? unitId,
    PriceType? priceType,
    DateTime? startDate,
    DateTime? endDate,
    double? priceAmount,
    PricingTier? pricingTier,
    double? percentageChange,
    double? minPrice,
    double? maxPrice,
    String? description,
    String? currency,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pricing(
      pricingId: pricingId ?? this.pricingId,
      unitId: unitId ?? this.unitId,
      priceType: priceType ?? this.priceType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      priceAmount: priceAmount ?? this.priceAmount,
      pricingTier: pricingTier ?? this.pricingTier,
      percentageChange: percentageChange ?? this.percentageChange,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      description: description ?? this.description,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        pricingId,
        unitId,
        priceType,
        startDate,
        endDate,
        priceAmount,
        pricingTier,
        percentageChange,
        minPrice,
        maxPrice,
        description,
        currency,
        isActive,
        createdBy,
        createdAt,
        updatedAt,
      ];
}