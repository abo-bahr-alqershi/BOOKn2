// lib/features/reference/presentation/bloc/reference_state.dart

import 'package:equatable/equatable.dart';
import '../../domain/entities/city.dart';
import '../../domain/entities/currency.dart';

abstract class ReferenceState extends Equatable {
  const ReferenceState();

  @override
  List<Object?> get props => [];
}

// الحالة الأولية
class ReferenceInitial extends ReferenceState {
  const ReferenceInitial();
}

// حالة التحميل
class ReferenceLoading extends ReferenceState {
  const ReferenceLoading();
}

// حالة تحميل المدن بنجاح
class CitiesLoaded extends ReferenceState {
  final List<City> cities;
  final String? selectedCity;
  final bool isSearchResult;

  const CitiesLoaded({
    required this.cities,
    this.selectedCity,
    this.isSearchResult = false,
  });

  @override
  List<Object?> get props => [cities, selectedCity, isSearchResult];
}

// حالة تحميل العملات بنجاح
class CurrenciesLoaded extends ReferenceState {
  final List<Currency> currencies;
  final String? selectedCurrency;
  final bool isSearchResult;

  const CurrenciesLoaded({
    required this.currencies,
    this.selectedCurrency,
    this.isSearchResult = false,
  });

  @override
  List<Object?> get props => [currencies, selectedCurrency, isSearchResult];
}

// حالة تحميل كل البيانات المرجعية
class ReferenceDataLoaded extends ReferenceState {
  final List<City> cities;
  final List<Currency> currencies;
  final String? selectedCity;
  final String? selectedCurrency;

  const ReferenceDataLoaded({
    required this.cities,
    required this.currencies,
    this.selectedCity,
    this.selectedCurrency,
  });

  @override
  List<Object?> get props => [cities, currencies, selectedCity, selectedCurrency];
}

// حالة اختيار مدينة بنجاح
class CitySelected extends ReferenceState {
  final City city;
  final String message;

  const CitySelected({
    required this.city,
    required this.message,
  });

  @override
  List<Object?> get props => [city, message];
}

// حالة اختيار عملة بنجاح
class CurrencySelected extends ReferenceState {
  final Currency currency;
  final String message;

  const CurrencySelected({
    required this.currency,
    required this.message,
  });

  @override
  List<Object?> get props => [currency, message];
}

// حالة الخطأ
class ReferenceError extends ReferenceState {
  final String message;

  const ReferenceError({required this.message});

  @override
  List<Object?> get props => [message];
}