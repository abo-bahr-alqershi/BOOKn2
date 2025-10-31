import 'dart:convert';
import 'package:bookn_cp_app/services/local_storage_service.dart';
import '../models/city_model.dart';
import '../models/currency_model.dart';

abstract class ReferenceLocalDataSource {
  Future<void> cacheCities(List<CityModel> cities);
  Future<void> cacheCurrencies(List<CurrencyModel> currencies);
  List<CityModel> getCachedCities();
  List<CurrencyModel> getCachedCurrencies();
  bool isCitiesCacheFresh();
  bool isCurrenciesCacheFresh();
}

class ReferenceLocalDataSourceImpl implements ReferenceLocalDataSource {
  final LocalStorageService localStorage;

  static const String _citiesKey = 'reference_cities';
  static const String _currenciesKey = 'reference_currencies';
  static const String _citiesTsKey = 'reference_cities_ts';
  static const String _currenciesTsKey = 'reference_currencies_ts';

  ReferenceLocalDataSourceImpl({required this.localStorage});

  @override
  Future<void> cacheCities(List<CityModel> cities) async {
    await localStorage.saveData(
        _citiesKey, jsonEncode(cities.map((e) => e.toJson()).toList()));
    await localStorage.saveData(
        _citiesTsKey, DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Future<void> cacheCurrencies(List<CurrencyModel> currencies) async {
    await localStorage.saveData(
        _currenciesKey, jsonEncode(currencies.map((e) => e.toJson()).toList()));
    await localStorage.saveData(
        _currenciesTsKey, DateTime.now().millisecondsSinceEpoch);
  }

  @override
  List<CityModel> getCachedCities() {
    final jsonStr = localStorage.getData(_citiesKey);
    if (jsonStr is String) {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((e) => CityModel.fromJson(e)).toList();
    }
    return const <CityModel>[];
  }

  @override
  List<CurrencyModel> getCachedCurrencies() {
    final jsonStr = localStorage.getData(_currenciesKey);
    if (jsonStr is String) {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((e) => CurrencyModel.fromJson(e)).toList();
    }
    return const <CurrencyModel>[];
  }

  @override
  bool isCitiesCacheFresh() {
    final ts = localStorage.getData(_citiesTsKey);
    if (ts is int) {
      final diff = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(ts))
          .inHours;
      return diff < 24;
    }
    return false;
  }

  @override
  bool isCurrenciesCacheFresh() {
    final ts = localStorage.getData(_currenciesTsKey);
    if (ts is int) {
      final diff = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(ts))
          .inHours;
      return diff < 24;
    }
    return false;
  }
}
