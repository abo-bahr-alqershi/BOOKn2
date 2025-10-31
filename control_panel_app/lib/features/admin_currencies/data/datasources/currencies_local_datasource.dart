import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/currency_model.dart';

abstract class CurrenciesLocalDataSource {
  Future<List<CurrencyModel>> getCachedCurrencies();
  Future<void> cacheCurrencies(List<CurrencyModel> currencies);
  Future<void> clearCache();
}

class CurrenciesLocalDataSourceImpl implements CurrenciesLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String _cacheKey = 'CACHED_CURRENCIES';

  CurrenciesLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<CurrencyModel>> getCachedCurrencies() async {
    final jsonString = sharedPreferences.getString(_cacheKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => CurrencyModel.fromJson(json)).toList();
    }
    throw Exception('No cached currencies found');
  }

  @override
  Future<void> cacheCurrencies(List<CurrencyModel> currencies) async {
    final jsonList = currencies.map((c) => c.toJson()).toList();
    await sharedPreferences.setString(_cacheKey, json.encode(jsonList));
  }

  @override
  Future<void> clearCache() async {
    await sharedPreferences.remove(_cacheKey);
  }
}