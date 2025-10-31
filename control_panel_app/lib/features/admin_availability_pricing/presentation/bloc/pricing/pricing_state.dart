// lib/features/admin_availability_pricing/presentation/bloc/pricing/pricing_state.dart

part of 'pricing_bloc.dart';

abstract class PricingState extends Equatable {
  const PricingState();

  @override
  List<Object?> get props => [];
}

class PricingInitial extends PricingState {}

class PricingLoading extends PricingState {}

class PricingLoaded extends PricingState {
  final UnitPricing unitPricing;
  final String selectedUnitId;
  final int currentYear;
  final int currentMonth;
  final List<SeasonalPricing>? seasonalTemplates;

  const PricingLoaded({
    required this.unitPricing,
    required this.selectedUnitId,
    required this.currentYear,
    required this.currentMonth,
    this.seasonalTemplates,
  });

  PricingLoaded copyWith({
    UnitPricing? unitPricing,
    String? selectedUnitId,
    int? currentYear,
    int? currentMonth,
    List<SeasonalPricing>? seasonalTemplates,
  }) {
    return PricingLoaded(
      unitPricing: unitPricing ?? this.unitPricing,
      selectedUnitId: selectedUnitId ?? this.selectedUnitId,
      currentYear: currentYear ?? this.currentYear,
      currentMonth: currentMonth ?? this.currentMonth,
      seasonalTemplates: seasonalTemplates ?? this.seasonalTemplates,
    );
  }

  @override
  List<Object?> get props => [
        unitPricing,
        selectedUnitId,
        currentYear,
        currentMonth,
        seasonalTemplates,
      ];
}

class PricingUpdating extends PricingLoaded {
  const PricingUpdating({
    required super.unitPricing,
    required super.selectedUnitId,
    required super.currentYear,
    required super.currentMonth,
  });
}

class PricingError extends PricingState {
  final String message;

  const PricingError(this.message);

  @override
  List<Object> get props => [message];
}
