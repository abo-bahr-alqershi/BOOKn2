import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/currency.dart';
import '../../domain/usecases/delete_currency_usecase.dart';
import '../../domain/usecases/get_currencies_usecase.dart';
import '../../domain/repositories/currencies_repository.dart';
import '../../domain/usecases/save_currencies_usecase.dart';
import '../../domain/usecases/set_default_currency_usecase.dart';
import 'currencies_event.dart';
import 'currencies_state.dart';

class CurrenciesBloc extends Bloc<CurrenciesEvent, CurrenciesState> {
  final GetCurrenciesUseCase getCurrencies;
  final SaveCurrenciesUseCase saveCurrencies;
  final DeleteCurrencyUseCase deleteCurrency;
  final SetDefaultCurrencyUseCase setDefaultCurrency;
  final CurrenciesRepository repository;

  List<Currency> _allCurrencies = [];

  CurrenciesBloc({
    required this.getCurrencies,
    required this.saveCurrencies,
    required this.deleteCurrency,
    required this.setDefaultCurrency,
    required this.repository,
  }) : super(CurrenciesInitial()) {
    on<LoadCurrenciesEvent>(_onLoadCurrencies);
    on<AddCurrencyEvent>(_onAddCurrency);
    on<UpdateCurrencyEvent>(_onUpdateCurrency);
    on<DeleteCurrencyEvent>(_onDeleteCurrency);
    on<SetDefaultCurrencyEvent>(_onSetDefaultCurrency);
    on<UpdateExchangeRateEvent>(_onUpdateExchangeRate);
    on<SearchCurrenciesEvent>(_onSearchCurrencies);
    on<RefreshCurrenciesEvent>(_onRefreshCurrencies);
  }

  Future<void> _onLoadCurrencies(
    LoadCurrenciesEvent event,
    Emitter<CurrenciesState> emit,
  ) async {
    emit(CurrenciesLoading());

    final result = await getCurrencies(NoParams());

    await result.fold(
      (failure) async {
        if (!emit.isDone) {
          emit(CurrenciesError(message: failure.message));
        }
      },
      (currencies) async {
        _allCurrencies = currencies;
        // Try fetch backend stats for last 30 days
        Map<String, dynamic>? stats;
        final now = DateTime.now();
        final last30 = now.subtract(const Duration(days: 30));
        final statsResult =
            await repository.getCurrencyStats(startDate: last30, endDate: now);
        stats = statsResult.fold((_) => null, (data) => data);
        if (!emit.isDone) {
          emit(CurrenciesLoaded(
            currencies: currencies,
            filteredCurrencies: currencies,
            stats: stats,
          ));
        }
      },
    );
  }

  Future<void> _onAddCurrency(
    AddCurrencyEvent event,
    Emitter<CurrenciesState> emit,
  ) async {
    if (state is CurrenciesLoaded) {
      final currentState = state as CurrenciesLoaded;
      // Validation: prevent multiple default currencies on add
      if (event.currency.isDefault && _allCurrencies.any((c) => c.isDefault)) {
        emit(const CurrenciesError(
            message:
                'لا يمكن تعيين هذه العملة كافتراضية لوجود عملة افتراضية مسبقاً'));
        // Re-emit previous loaded state to keep UI intact
        emit(currentState.copyWith(isSaving: false));
        return;
      }

      emit(currentState.copyWith(isSaving: true));

      final updatedCurrencies = [..._allCurrencies, event.currency];

      final result = await saveCurrencies(
        SaveCurrenciesParams(currencies: updatedCurrencies),
      );

      result.fold(
        (failure) => emit(CurrenciesError(message: failure.message)),
        (_) {
          _allCurrencies = updatedCurrencies;
          // Emit success first for snackbar, then return to Loaded to keep UI content visible
          emit(const CurrencyOperationSuccess(
              message: 'تمت إضافة العملة بنجاح'));
          emit(CurrenciesLoaded(
            currencies: updatedCurrencies,
            filteredCurrencies: _filterCurrencies(
              updatedCurrencies,
              currentState.searchQuery,
            ),
            searchQuery: currentState.searchQuery,
          ));
        },
      );
    }
  }

  Future<void> _onUpdateCurrency(
    UpdateCurrencyEvent event,
    Emitter<CurrenciesState> emit,
  ) async {
    if (state is CurrenciesLoaded) {
      final currentState = state as CurrenciesLoaded;
      // Validation: prevent multiple default currencies on update
      if (event.currency.isDefault) {
        final hasAnotherDefault = _allCurrencies.any(
          (c) => c.isDefault && c.code != event.oldCode,
        );
        if (hasAnotherDefault) {
          emit(const CurrenciesError(
              message:
                  'لا يمكن جعل هذه العملة افتراضية لوجود عملة افتراضية مسبقاً'));
          // Re-emit previous loaded state to keep UI intact
          emit(currentState.copyWith(isSaving: false));
          return;
        }
      }

      emit(currentState.copyWith(isSaving: true));

      final updatedCurrencies = _allCurrencies.map((c) {
        return c.code == event.oldCode ? event.currency : c;
      }).toList();

      final result = await saveCurrencies(
        SaveCurrenciesParams(currencies: updatedCurrencies),
      );

      result.fold(
        (failure) => emit(CurrenciesError(message: failure.message)),
        (_) {
          _allCurrencies = updatedCurrencies;
          emit(
              const CurrencyOperationSuccess(message: 'تم تحديث العملة بنجاح'));
          emit(CurrenciesLoaded(
            currencies: updatedCurrencies,
            filteredCurrencies: _filterCurrencies(
              updatedCurrencies,
              currentState.searchQuery,
            ),
            searchQuery: currentState.searchQuery,
          ));
        },
      );
    }
  }

  Future<void> _onDeleteCurrency(
    DeleteCurrencyEvent event,
    Emitter<CurrenciesState> emit,
  ) async {
    if (state is CurrenciesLoaded) {
      final currentState = state as CurrenciesLoaded;
      emit(currentState.copyWith(isSaving: true));

      final result = await deleteCurrency(
        DeleteCurrencyParams(code: event.code),
      );

      result.fold(
        (failure) => emit(CurrenciesError(message: failure.message)),
        (_) {
          _allCurrencies =
              _allCurrencies.where((c) => c.code != event.code).toList();
          emit(const CurrencyOperationSuccess(message: 'تم حذف العملة بنجاح'));
          emit(CurrenciesLoaded(
            currencies: _allCurrencies,
            filteredCurrencies: _filterCurrencies(
              _allCurrencies,
              currentState.searchQuery,
            ),
            searchQuery: currentState.searchQuery,
          ));
        },
      );
    }
  }

  Future<void> _onSetDefaultCurrency(
    SetDefaultCurrencyEvent event,
    Emitter<CurrenciesState> emit,
  ) async {
    if (state is CurrenciesLoaded) {
      final currentState = state as CurrenciesLoaded;
      emit(currentState.copyWith(isSaving: true));

      final result = await setDefaultCurrency(
        SetDefaultCurrencyParams(code: event.code),
      );

      result.fold(
        (failure) => emit(CurrenciesError(message: failure.message)),
        (_) {
          _allCurrencies = _allCurrencies.map((c) {
            return c.copyWith(isDefault: c.code == event.code);
          }).toList();

          emit(const CurrencyOperationSuccess(
              message: 'تم تعيين العملة الافتراضية'));
          emit(CurrenciesLoaded(
            currencies: _allCurrencies,
            filteredCurrencies: _filterCurrencies(
              _allCurrencies,
              currentState.searchQuery,
            ),
            searchQuery: currentState.searchQuery,
          ));
        },
      );
    }
  }

  Future<void> _onUpdateExchangeRate(
    UpdateExchangeRateEvent event,
    Emitter<CurrenciesState> emit,
  ) async {
    if (state is CurrenciesLoaded) {
      final currentState = state as CurrenciesLoaded;

      final updatedCurrencies = _allCurrencies.map((c) {
        if (c.code == event.code) {
          return c.copyWith(
            exchangeRate: event.rate,
            lastUpdated: DateTime.now(),
          );
        }
        return c;
      }).toList();

      _allCurrencies = updatedCurrencies;

      emit(CurrenciesLoaded(
        currencies: updatedCurrencies,
        filteredCurrencies: _filterCurrencies(
          updatedCurrencies,
          currentState.searchQuery,
        ),
        searchQuery: currentState.searchQuery,
      ));
    }
  }

  void _onSearchCurrencies(
    SearchCurrenciesEvent event,
    Emitter<CurrenciesState> emit,
  ) {
    if (state is CurrenciesLoaded) {
      final currentState = state as CurrenciesLoaded;

      emit(CurrenciesLoaded(
        currencies: _allCurrencies,
        filteredCurrencies: _filterCurrencies(_allCurrencies, event.query),
        searchQuery: event.query,
      ));
    }
  }

  Future<void> _onRefreshCurrencies(
    RefreshCurrenciesEvent event,
    Emitter<CurrenciesState> emit,
  ) async {
    await _onLoadCurrencies(LoadCurrenciesEvent(), emit);
  }

  List<Currency> _filterCurrencies(List<Currency> currencies, String query) {
    if (query.isEmpty) return currencies;

    final lowerQuery = query.toLowerCase();
    return currencies.where((currency) {
      return currency.code.toLowerCase().contains(lowerQuery) ||
          currency.name.toLowerCase().contains(lowerQuery) ||
          currency.arabicName.contains(query) ||
          currency.arabicCode.contains(query);
    }).toList();
  }
}
