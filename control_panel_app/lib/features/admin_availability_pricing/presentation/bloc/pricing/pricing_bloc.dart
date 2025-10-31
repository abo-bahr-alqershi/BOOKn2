// lib/features/admin_availability_pricing/presentation/bloc/pricing/pricing_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/pricing_rule.dart';
import '../../../domain/entities/pricing.dart';
import '../../../domain/entities/seasonal_pricing.dart';
import '../../../domain/usecases/pricing/get_monthly_pricing_usecase.dart';
import '../../../domain/usecases/pricing/update_pricing_usecase.dart';
import '../../../domain/usecases/pricing/bulk_update_pricing_usecase.dart';
import '../../../domain/usecases/pricing/apply_seasonal_pricing_usecase.dart';
import '../../../domain/usecases/pricing/copy_pricing_usecase.dart';
import '../../../domain/usecases/pricing/delete_pricing_usecase.dart';
import '../../../domain/repositories/pricing_repository.dart';
import '../../../../../injection_container.dart';
import '../../../../../services/local_storage_service.dart';

part 'pricing_event.dart';
part 'pricing_state.dart';

class PricingBloc extends Bloc<PricingEvent, PricingState> {
  final GetMonthlyPricingUseCase getMonthlyPricingUseCase;
  final UpdatePricingUseCase updatePricingUseCase;
  final BulkUpdatePricingUseCase bulkUpdatePricingUseCase;
  final ApplySeasonalPricingUseCase applySeasonalPricingUseCase;
  final CopyPricingUseCase? copyPricingUseCase;
  final DeletePricingUseCase? deletePricingUseCase;

  PricingBloc({
    required this.getMonthlyPricingUseCase,
    required this.updatePricingUseCase,
    required this.bulkUpdatePricingUseCase,
    required this.applySeasonalPricingUseCase,
    this.copyPricingUseCase,
    this.deletePricingUseCase,
  }) : super(PricingInitial()) {
    on<LoadMonthlyPricing>(_onLoadMonthlyPricing);
    on<UpdatePricing>(_onUpdatePricing);
    on<UpdateSingleDayPricing>(_onUpdateSingleDayPricing);
    on<UpdateDateRangePricing>(_onUpdateDateRangePricing);
    on<BulkUpdatePricing>(_onBulkUpdatePricing);
    on<ApplySeasonalPricing>(_onApplySeasonalPricing);
    on<CopyPricing>(_onCopyPricing);
    on<DeletePricing>(_onDeletePricing);
    on<SelectPricingUnit>(_onSelectUnit);
    on<ChangePricingMonth>(_onChangeMonth);
  }

  Future<void> _onLoadMonthlyPricing(
    LoadMonthlyPricing event,
    Emitter<PricingState> emit,
  ) async {
    emit(PricingLoading());

    final result = await getMonthlyPricingUseCase(
      GetMonthlyPricingParams(
        unitId: event.unitId,
        year: event.year,
        month: event.month,
      ),
    );

    result.fold(
      (failure) => emit(PricingError(failure.message)),
      (unitPricing) => emit(PricingLoaded(
        unitPricing: unitPricing,
        selectedUnitId: event.unitId,
        currentYear: event.year,
        currentMonth: event.month,
      )),
    );
  }

  Future<void> _onUpdatePricing(
    UpdatePricing event,
    Emitter<PricingState> emit,
  ) async {
    if (state is PricingLoaded) {
      final currentState = state as PricingLoaded;
      emit(PricingUpdating(
        unitPricing: currentState.unitPricing,
        selectedUnitId: currentState.selectedUnitId,
        currentYear: currentState.currentYear,
        currentMonth: currentState.currentMonth,
      ));

      final result = await updatePricingUseCase(event.params);

      result.fold(
        (failure) => emit(PricingError(failure.message)),
        (_) {
          add(LoadMonthlyPricing(
            unitId: currentState.selectedUnitId,
            year: currentState.currentYear,
            month: currentState.currentMonth,
          ));
        },
      );
    }
  }

  Future<void> _onUpdateSingleDayPricing(
    UpdateSingleDayPricing event,
    Emitter<PricingState> emit,
  ) async {
    if (state is PricingLoaded) {
      final currentState = state as PricingLoaded;

      emit(PricingUpdating(
        unitPricing: currentState.unitPricing,
        selectedUnitId: currentState.selectedUnitId,
        currentYear: currentState.currentYear,
        currentMonth: currentState.currentMonth,
      ));

      final result = await updatePricingUseCase(
        UpdatePricingParams(
          unitId: event.unitId,
          startDate: event.date,
          endDate: event.date,
          price: event.price,
          priceType: event.priceType ?? PriceType.custom,
          currency: event.currency ?? _resolveContextCurrency(),
          pricingTier: event.pricingTier ?? PricingTier.normal,
          overwriteExisting: event.overwriteExisting,
        ),
      );

      result.fold(
        (failure) => emit(PricingError(failure.message)),
        (_) {
          add(LoadMonthlyPricing(
            unitId: currentState.selectedUnitId,
            year: currentState.currentYear,
            month: currentState.currentMonth,
          ));
        },
      );
    }
  }

  Future<void> _onUpdateDateRangePricing(
    UpdateDateRangePricing event,
    Emitter<PricingState> emit,
  ) async {
    if (state is PricingLoaded) {
      final currentState = state as PricingLoaded;

      emit(PricingUpdating(
        unitPricing: currentState.unitPricing,
        selectedUnitId: currentState.selectedUnitId,
        currentYear: currentState.currentYear,
        currentMonth: currentState.currentMonth,
      ));

      final result = await updatePricingUseCase(
        UpdatePricingParams(
          unitId: event.unitId,
          startDate: event.startDate,
          endDate: event.endDate,
          price: event.price,
          priceType: event.priceType ?? PriceType.custom,
          currency: event.currency ?? _resolveContextCurrency(),
          pricingTier: event.pricingTier ?? PricingTier.normal,
          overwriteExisting: event.overwriteExisting,
        ),
      );

      result.fold(
        (failure) => emit(PricingError(failure.message)),
        (_) {
          add(LoadMonthlyPricing(
            unitId: currentState.selectedUnitId,
            year: currentState.currentYear,
            month: currentState.currentMonth,
          ));
        },
      );
    }
  }

  Future<void> _onBulkUpdatePricing(
    BulkUpdatePricing event,
    Emitter<PricingState> emit,
  ) async {
    if (state is PricingLoaded) {
      final currentState = state as PricingLoaded;
      emit(PricingUpdating(
        unitPricing: currentState.unitPricing,
        selectedUnitId: currentState.selectedUnitId,
        currentYear: currentState.currentYear,
        currentMonth: currentState.currentMonth,
      ));

      // Create PricingPeriod objects
      List<PricingPeriod> periods = [];

      final currencyCode = currentState.unitPricing.currency;
      if (event.weekdays != null && event.weekdays!.isNotEmpty) {
        // Filter dates by weekdays
        DateTime currentDate = event.startDate;
        while (currentDate.isBefore(event.endDate) ||
            currentDate.isAtSameMomentAs(event.endDate)) {
          if (event.weekdays!.contains(currentDate.weekday % 7)) {
            periods.add(PricingPeriod(
              startDate: currentDate,
              endDate: currentDate,
              price: event.price,
              priceType: event.priceType,
              currency: currencyCode,
              tier: event.pricingTier,
              percentageChange: event.percentageChange,
              overwriteExisting: true,
            ));
          }
          currentDate = currentDate.add(const Duration(days: 1));
        }
      } else {
        // Update entire range
        periods.add(PricingPeriod(
          startDate: event.startDate,
          endDate: event.endDate,
          price: event.price,
          priceType: event.priceType,
          currency: currencyCode,
          tier: event.pricingTier,
          percentageChange: event.percentageChange,
          overwriteExisting: true,
        ));
      }

      final result = await bulkUpdatePricingUseCase(
        BulkUpdatePricingParams(
          unitId: event.unitId,
          periods: periods,
          overwriteExisting: event.overwriteExisting,
        ),
      );

      result.fold(
        (failure) => emit(PricingError(failure.message)),
        (_) {
          add(LoadMonthlyPricing(
            unitId: currentState.selectedUnitId,
            year: currentState.currentYear,
            month: currentState.currentMonth,
          ));
        },
      );
    }
  }

  Future<void> _onApplySeasonalPricing(
    ApplySeasonalPricing event,
    Emitter<PricingState> emit,
  ) async {
    if (state is PricingLoaded) {
      final currentState = state as PricingLoaded;
      emit(PricingUpdating(
        unitPricing: currentState.unitPricing,
        selectedUnitId: currentState.selectedUnitId,
        currentYear: currentState.currentYear,
        currentMonth: currentState.currentMonth,
      ));

      final result = await applySeasonalPricingUseCase(event.params);

      result.fold(
        (failure) => emit(PricingError(failure.message)),
        (_) {
          add(LoadMonthlyPricing(
            unitId: currentState.selectedUnitId,
            year: currentState.currentYear,
            month: currentState.currentMonth,
          ));
        },
      );
    }
  }

  Future<void> _onCopyPricing(
    CopyPricing event,
    Emitter<PricingState> emit,
  ) async {
    if (copyPricingUseCase != null && state is PricingLoaded) {
      final currentState = state as PricingLoaded;

      final result = await copyPricingUseCase!(
        CopyPricingParams(
          unitId: event.unitId,
          sourceStartDate: event.sourceStartDate,
          sourceEndDate: event.sourceEndDate,
          targetStartDate: event.targetStartDate,
          repeatCount: event.repeatCount,
          adjustmentType: event.adjustmentType,
          adjustmentValue: event.adjustmentValue,
          overwriteExisting: event.overwriteExisting,
        ),
      );

      result.fold(
        (failure) => emit(PricingError(failure.message)),
        (_) {
          // Reload current month after copy
          add(LoadMonthlyPricing(
            unitId: currentState.selectedUnitId,
            year: currentState.currentYear,
            month: currentState.currentMonth,
          ));
        },
      );
    }
  }

  Future<void> _onDeletePricing(
    DeletePricing event,
    Emitter<PricingState> emit,
  ) async {
    if (deletePricingUseCase != null && state is PricingLoaded) {
      final currentState = state as PricingLoaded;

      final result = await deletePricingUseCase!(
        DeletePricingParams(
          unitId: event.unitId,
          pricingId: event.pricingId,
          startDate: event.startDate,
          endDate: event.endDate,
        ),
      );

      result.fold(
        (failure) => emit(PricingError(failure.message)),
        (_) {
          // Reload current month after deletion
          add(LoadMonthlyPricing(
            unitId: currentState.selectedUnitId,
            year: currentState.currentYear,
            month: currentState.currentMonth,
          ));
        },
      );
    }
  }

  void _onSelectUnit(
    SelectPricingUnit event,
    Emitter<PricingState> emit,
  ) {
    if (state is PricingLoaded) {
      final currentState = state as PricingLoaded;
      add(LoadMonthlyPricing(
        unitId: event.unitId,
        year: currentState.currentYear,
        month: currentState.currentMonth,
      ));
    } else {
      // If no state, load current month
      final now = DateTime.now();
      add(LoadMonthlyPricing(
        unitId: event.unitId,
        year: now.year,
        month: now.month,
      ));
    }
  }

  void _onChangeMonth(
    ChangePricingMonth event,
    Emitter<PricingState> emit,
  ) {
    if (state is PricingLoaded) {
      final currentState = state as PricingLoaded;
      add(LoadMonthlyPricing(
        unitId: currentState.selectedUnitId,
        year: event.year,
        month: event.month,
      ));
    }
  }

  String _resolveContextCurrency() {
    try {
      final storage = sl<LocalStorageService>();
      final role = storage.getAccountRole().toLowerCase();
      final propertyCurrency = storage.getPropertyCurrency();
      if (role == 'owner' || role == 'staff') {
        if (propertyCurrency.isNotEmpty) return propertyCurrency;
      }
      final selected = storage.getSelectedCurrency();
      return selected.isNotEmpty ? selected : 'YER';
    } catch (_) {
      return 'YER';
    }
  }
}
