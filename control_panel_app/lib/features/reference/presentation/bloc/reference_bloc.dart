// lib/features/reference/presentation/bloc/reference_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../services/local_storage_service.dart';
import '../../domain/entities/city.dart';
import '../../domain/entities/currency.dart';
import '../../domain/usecases/get_cities_usecase.dart';
import '../../domain/usecases/get_currencies_usecase.dart';
import 'reference_event.dart';
import 'reference_state.dart';

class ReferenceBloc extends Bloc<ReferenceEvent, ReferenceState> {
  final GetCitiesUseCase getCitiesUseCase;
  final GetCurrenciesUseCase getCurrenciesUseCase;
  final LocalStorageService localStorage;
  
  // Cache للبيانات
  List<City>? _cachedCities;
  List<Currency>? _cachedCurrencies;
  String? _selectedCity;
  String? _selectedCurrency;

  ReferenceBloc({
    required this.getCitiesUseCase,
    required this.getCurrenciesUseCase,
    required this.localStorage,
  }) : super(const ReferenceInitial()) {
    on<LoadCitiesEvent>(_onLoadCities);
    on<LoadCurrenciesEvent>(_onLoadCurrencies);
    on<LoadReferenceDataEvent>(_onLoadReferenceData);
    on<SelectCityEvent>(_onSelectCity);
    on<SelectCurrencyEvent>(_onSelectCurrency);
    on<SearchCitiesEvent>(_onSearchCities);
    on<SearchCurrenciesEvent>(_onSearchCurrencies);
    on<LoadSelectedCityEvent>(_onLoadSelectedCity);
    on<LoadSelectedCurrencyEvent>(_onLoadSelectedCurrency);
    on<ClearSelectionEvent>(_onClearSelection);
    on<RefreshReferenceDataEvent>(_onRefreshReferenceData);
  }

  Future<void> _onLoadCities(
    LoadCitiesEvent event,
    Emitter<ReferenceState> emit,
  ) async {
    // استخدم الكاش إذا كان متاحاً ولا يريد المستخدم التحديث القسري
    if (_cachedCities != null && !event.forceRefresh) {
      _selectedCity = localStorage.getSelectedCity();
      emit(CitiesLoaded(
        cities: _cachedCities!,
        selectedCity: _selectedCity,
      ));
      return;
    }

    emit(const ReferenceLoading());

    final result = await getCitiesUseCase(NoParams());
    
    result.fold(
      (failure) => emit(ReferenceError(message: failure.message)),
      (cities) {
        _cachedCities = cities;
        _selectedCity = localStorage.getSelectedCity();
        emit(CitiesLoaded(
          cities: cities,
          selectedCity: _selectedCity,
        ));
      },
    );
  }

  Future<void> _onLoadCurrencies(
    LoadCurrenciesEvent event,
    Emitter<ReferenceState> emit,
  ) async {
    // استخدم الكاش إذا كان متاحاً
    if (_cachedCurrencies != null && !event.forceRefresh) {
      _selectedCurrency = localStorage.getSelectedCurrency();
      emit(CurrenciesLoaded(
        currencies: _cachedCurrencies!,
        selectedCurrency: _selectedCurrency,
      ));
      return;
    }

    emit(const ReferenceLoading());

    final result = await getCurrenciesUseCase(NoParams());
    
    result.fold(
      (failure) => emit(ReferenceError(message: failure.message)),
      (currencies) {
        _cachedCurrencies = currencies;
        _selectedCurrency = localStorage.getSelectedCurrency();
        emit(CurrenciesLoaded(
          currencies: currencies,
          selectedCurrency: _selectedCurrency,
        ));
      },
    );
  }

  Future<void> _onLoadReferenceData(
    LoadReferenceDataEvent event,
    Emitter<ReferenceState> emit,
  ) async {
    emit(const ReferenceLoading());

    try {
      // تحميل البيانات بشكل متوازي
      final citiesResult = await getCitiesUseCase(NoParams());
      final currenciesResult = await getCurrenciesUseCase(NoParams());
      
      if (citiesResult.isLeft() || currenciesResult.isLeft()) {
        emit(const ReferenceError(message: 'فشل تحميل البيانات المرجعية'));
        return;
      }
      
      _cachedCities = citiesResult.getOrElse(() => []);
      _cachedCurrencies = currenciesResult.getOrElse(() => []);
      _selectedCity = localStorage.getSelectedCity();
      _selectedCurrency = localStorage.getSelectedCurrency();
      
      emit(ReferenceDataLoaded(
        cities: _cachedCities!,
        currencies: _cachedCurrencies!,
        selectedCity: _selectedCity,
        selectedCurrency: _selectedCurrency,
      ));
    } catch (e) {
      emit(ReferenceError(message: e.toString()));
    }
  }

  Future<void> _onSelectCity(
    SelectCityEvent event,
    Emitter<ReferenceState> emit,
  ) async {
    try {
      // حفظ المدينة المختارة
      await localStorage.saveSelectedCity(event.city.name);
      _selectedCity = event.city.name;
      
      // تحديث الحالة
      if (_cachedCities != null) {
        emit(CitiesLoaded(
          cities: _cachedCities!,
          selectedCity: _selectedCity,
        ));
      }
      
      // إرسال حدث نجاح الاختيار
      emit(CitySelected(
        city: event.city,
        message: 'تم اختيار ${event.city.name}',
      ));
      
      // العودة للحالة السابقة
      if (_cachedCities != null) {
        emit(CitiesLoaded(
          cities: _cachedCities!,
          selectedCity: _selectedCity,
        ));
      }
    } catch (e) {
      emit(ReferenceError(message: 'فشل حفظ المدينة المختارة'));
    }
  }

  Future<void> _onSelectCurrency(
    SelectCurrencyEvent event,
    Emitter<ReferenceState> emit,
  ) async {
    try {
      // حفظ العملة المختارة
      await localStorage.saveSelectedCurrency(event.currency.code);
      _selectedCurrency = event.currency.code;
      
      // تحديث الحالة
      if (_cachedCurrencies != null) {
        emit(CurrenciesLoaded(
          currencies: _cachedCurrencies!,
          selectedCurrency: _selectedCurrency,
        ));
      }
      
      // إرسال حدث نجاح الاختيار
      emit(CurrencySelected(
        currency: event.currency,
        message: 'تم اختيار ${event.currency.arabicName}',
      ));
      
      // العودة للحالة السابقة
      if (_cachedCurrencies != null) {
        emit(CurrenciesLoaded(
          currencies: _cachedCurrencies!,
          selectedCurrency: _selectedCurrency,
        ));
      }
    } catch (e) {
      emit(ReferenceError(message: 'فشل حفظ العملة المختارة'));
    }
  }

  void _onSearchCities(
    SearchCitiesEvent event,
    Emitter<ReferenceState> emit,
  ) {
    if (_cachedCities == null) {
      emit(const ReferenceError(message: 'لا توجد مدن محملة'));
      return;
    }

    final query = event.query.toLowerCase();
    
    if (query.isEmpty) {
      emit(CitiesLoaded(
        cities: _cachedCities!,
        selectedCity: _selectedCity,
      ));
      return;
    }

    final filteredCities = _cachedCities!.where((city) =>
        city.name.toLowerCase().contains(query) ||
        city.country.toLowerCase().contains(query)).toList();

    emit(CitiesLoaded(
      cities: filteredCities,
      selectedCity: _selectedCity,
      isSearchResult: true,
    ));
  }

  void _onSearchCurrencies(
    SearchCurrenciesEvent event,
    Emitter<ReferenceState> emit,
  ) {
    if (_cachedCurrencies == null) {
      emit(const ReferenceError(message: 'لا توجد عملات محملة'));
      return;
    }

    final query = event.query.toLowerCase();
    
    if (query.isEmpty) {
      emit(CurrenciesLoaded(
        currencies: _cachedCurrencies!,
        selectedCurrency: _selectedCurrency,
      ));
      return;
    }

    final filteredCurrencies = _cachedCurrencies!.where((currency) =>
        currency.code.toLowerCase().contains(query) ||
        currency.name.toLowerCase().contains(query) ||
        currency.arabicName.toLowerCase().contains(query)).toList();

    emit(CurrenciesLoaded(
      currencies: filteredCurrencies,
      selectedCurrency: _selectedCurrency,
      isSearchResult: true,
    ));
  }

  void _onLoadSelectedCity(
    LoadSelectedCityEvent event,
    Emitter<ReferenceState> emit,
  ) {
    _selectedCity = localStorage.getSelectedCity();
    
    if (_cachedCities != null) {
      emit(CitiesLoaded(
        cities: _cachedCities!,
        selectedCity: _selectedCity,
      ));
    }
  }

  void _onLoadSelectedCurrency(
    LoadSelectedCurrencyEvent event,
    Emitter<ReferenceState> emit,
  ) {
    _selectedCurrency = localStorage.getSelectedCurrency();
    
    if (_cachedCurrencies != null) {
      emit(CurrenciesLoaded(
        currencies: _cachedCurrencies!,
        selectedCurrency: _selectedCurrency,
      ));
    }
  }

  Future<void> _onClearSelection(
    ClearSelectionEvent event,
    Emitter<ReferenceState> emit,
  ) async {
    if (event.clearCity) {
      await localStorage.saveSelectedCity('');
      _selectedCity = null;
    }
    
    if (event.clearCurrency) {
      await localStorage.saveSelectedCurrency('');
      _selectedCurrency = null;
    }
    
    // إعادة تحميل البيانات الحالية
    if (_cachedCities != null && _cachedCurrencies != null) {
      emit(ReferenceDataLoaded(
        cities: _cachedCities!,
        currencies: _cachedCurrencies!,
        selectedCity: _selectedCity,
        selectedCurrency: _selectedCurrency,
      ));
    }
  }

  Future<void> _onRefreshReferenceData(
    RefreshReferenceDataEvent event,
    Emitter<ReferenceState> emit,
  ) async {
    // مسح الكاش
    _cachedCities = null;
    _cachedCurrencies = null;
    
    // إعادة تحميل البيانات
    add(const LoadReferenceDataEvent());
  }
}