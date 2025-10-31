// lib/features/admin_availability_pricing/data/datasources/availability_local_datasource.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/unit_availability_model.dart';
import '../../../../core/constants/storage_constants.dart';

abstract class AvailabilityLocalDataSource {
  Future<void> cacheMonthlyAvailability(
    String unitId,
    int year,
    int month,
    UnitAvailabilityModel availability,
  );
  
  Future<UnitAvailabilityModel?> getCachedMonthlyAvailability(
    String unitId,
    int year,
    int month,
  );
  
  Future<void> clearCache();
}

class AvailabilityLocalDataSourceImpl implements AvailabilityLocalDataSource {
  final SharedPreferences sharedPreferences;

  AvailabilityLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheMonthlyAvailability(
    String unitId,
    int year,
    int month,
    UnitAvailabilityModel availability,
  ) async {
    final key = _getCacheKey(unitId, year, month);
    final jsonString = json.encode(availability.toJson());
    await sharedPreferences.setString(key, jsonString);
    
    // Save cache timestamp
    final timestampKey = '${key}_timestamp';
    await sharedPreferences.setInt(
      timestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  Future<UnitAvailabilityModel?> getCachedMonthlyAvailability(
    String unitId,
    int year,
    int month,
  ) async {
    final key = _getCacheKey(unitId, year, month);
    final jsonString = sharedPreferences.getString(key);
    
    if (jsonString == null) return null;
    
    // Check if cache is still valid
    final timestampKey = '${key}_timestamp';
    final timestamp = sharedPreferences.getInt(timestampKey);
    
    if (timestamp == null) return null;
    
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    
    // Cache is valid for 1 hour
    if (now.difference(cacheTime).inHours > 1) {
      // Cache expired, remove it
      await sharedPreferences.remove(key);
      await sharedPreferences.remove(timestampKey);
      return null;
    }
    
    try {
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return UnitAvailabilityModel.fromJson(jsonMap);
    } catch (e) {
      // Invalid cache data, remove it
      await sharedPreferences.remove(key);
      await sharedPreferences.remove(timestampKey);
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    final keys = sharedPreferences.getKeys();
    for (final key in keys) {
      if (key.startsWith(StorageConstants.availabilityCachePrefix)) {
        await sharedPreferences.remove(key);
      }
    }
  }

  String _getCacheKey(String unitId, int year, int month) {
    return '${StorageConstants.availabilityCachePrefix}_${unitId}_${year}_$month';
  }
}