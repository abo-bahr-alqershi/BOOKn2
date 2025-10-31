import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/exceptions.dart';
import '../models/city_model.dart';

abstract class CitiesLocalDataSource {
  Future<List<CityModel>> getCachedCities();
  Future<void> cacheCities(List<CityModel> cities);
  Future<void> clearCache();
  Future<bool> isCacheValid();
}

class CitiesLocalDataSourceImpl implements CitiesLocalDataSource {
  final SharedPreferences sharedPreferences;
  
  static const String CACHED_CITIES_KEY = 'CACHED_CITIES';
  static const String CACHE_TIMESTAMP_KEY = 'CITIES_CACHE_TIMESTAMP';
  static const Duration CACHE_DURATION = Duration(hours: 24);

  CitiesLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<CityModel>> getCachedCities() async {
    final jsonString = sharedPreferences.getString(CACHED_CITIES_KEY);
    
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList
            .map((json) => CityModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        throw CacheException( 'Failed to decode cached cities');
      }
    } else {
      throw CacheException( 'No cached cities found');
    }
  }

  @override
  Future<void> cacheCities(List<CityModel> cities) async {
    try {
      final jsonList = cities.map((city) => city.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      final success = await sharedPreferences.setString(
        CACHED_CITIES_KEY,
        jsonString,
      );
      
      if (success) {
        await sharedPreferences.setInt(
          CACHE_TIMESTAMP_KEY,
          DateTime.now().millisecondsSinceEpoch,
        );
      } else {
        throw CacheException( 'Failed to cache cities');
      }
    } catch (e) {
      throw CacheException( 'Failed to cache cities: ${e.toString()}');
    }
  }

  @override
  Future<void> clearCache() async {
    await sharedPreferences.remove(CACHED_CITIES_KEY);
    await sharedPreferences.remove(CACHE_TIMESTAMP_KEY);
  }

  @override
  Future<bool> isCacheValid() async {
    final timestamp = sharedPreferences.getInt(CACHE_TIMESTAMP_KEY);
    
    if (timestamp == null) {
      return false;
    }
    
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    
    return now.difference(cacheTime) < CACHE_DURATION;
  }
}