// lib/features/reference/presentation/bloc/reference_event.dart

import 'package:equatable/equatable.dart';
import '../../domain/entities/city.dart';
import '../../domain/entities/currency.dart';

abstract class ReferenceEvent extends Equatable {
  const ReferenceEvent();

  @override
  List<Object?> get props => [];
}

// تحميل المدن
class LoadCitiesEvent extends ReferenceEvent {
  final bool forceRefresh;

  const LoadCitiesEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

// تحميل العملات
class LoadCurrenciesEvent extends ReferenceEvent {
  final bool forceRefresh;

  const LoadCurrenciesEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

// تحميل كل البيانات المرجعية
class LoadReferenceDataEvent extends ReferenceEvent {
  const LoadReferenceDataEvent();
}

// اختيار مدينة
class SelectCityEvent extends ReferenceEvent {
  final City city;

  const SelectCityEvent({required this.city});

  @override
  List<Object?> get props => [city];
}

// اختيار عملة
class SelectCurrencyEvent extends ReferenceEvent {
  final Currency currency;

  const SelectCurrencyEvent({required this.currency});

  @override
  List<Object?> get props => [currency];
}

// البحث في المدن
class SearchCitiesEvent extends ReferenceEvent {
  final String query;

  const SearchCitiesEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

// البحث في العملات
class SearchCurrenciesEvent extends ReferenceEvent {
  final String query;

  const SearchCurrenciesEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

// تحميل المدينة المختارة
class LoadSelectedCityEvent extends ReferenceEvent {
  const LoadSelectedCityEvent();
}

// تحميل العملة المختارة
class LoadSelectedCurrencyEvent extends ReferenceEvent {
  const LoadSelectedCurrencyEvent();
}

// مسح الاختيارات
class ClearSelectionEvent extends ReferenceEvent {
  final bool clearCity;
  final bool clearCurrency;

  const ClearSelectionEvent({
    this.clearCity = true,
    this.clearCurrency = true,
  });

  @override
  List<Object?> get props => [clearCity, clearCurrency];
}

// تحديث البيانات المرجعية
class RefreshReferenceDataEvent extends ReferenceEvent {
  const RefreshReferenceDataEvent();
}