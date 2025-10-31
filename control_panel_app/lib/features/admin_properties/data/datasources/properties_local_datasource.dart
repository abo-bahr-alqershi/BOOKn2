// lib/features/admin_properties/data/datasources/properties_local_datasource.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bookn_cp_app/core/error/exceptions.dart';
import '../models/property_model.dart';

abstract class PropertiesLocalDataSource {
  Future<List<PropertyModel>> getCachedProperties();
  Future<void> cacheProperties(List<PropertyModel> properties);
  Future<PropertyModel?> getCachedPropertyById(String propertyId);
  Future<void> cacheProperty(PropertyModel property);
  Future<void> clearCache();
  Future<DateTime?> getLastCacheTime();
}

class PropertiesLocalDataSourceImpl implements PropertiesLocalDataSource {
  final SharedPreferences sharedPreferences;
  
  static const CACHED_PROPERTIES = 'CACHED_PROPERTIES';
  static const CACHED_PROPERTY_PREFIX = 'CACHED_PROPERTY_';
  static const CACHE_TIME = 'PROPERTIES_CACHE_TIME';
  
  PropertiesLocalDataSourceImpl({required this.sharedPreferences});
  
  @override
  Future<List<PropertyModel>> getCachedProperties() async {
    final jsonString = sharedPreferences.getString(CACHED_PROPERTIES);
    
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList
            .map((json) => PropertyModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        throw CacheException('Failed to decode cached properties');
      }
    } else {
      throw CacheException('No cached properties found');
    }
  }
  
  @override
  Future<void> cacheProperties(List<PropertyModel> properties) async {
    try {
      final jsonList = properties.map((property) => property.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      await sharedPreferences.setString(CACHED_PROPERTIES, jsonString);
      await sharedPreferences.setString(
        CACHE_TIME,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      throw CacheException('Failed to cache properties');
    }
  }
  
  @override
  Future<PropertyModel?> getCachedPropertyById(String propertyId) async {
    final jsonString = sharedPreferences.getString('$CACHED_PROPERTY_PREFIX$propertyId');
    
    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString);
        return PropertyModel.fromJson(json as Map<String, dynamic>);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
  
  @override
  Future<void> cacheProperty(PropertyModel property) async {
    try {
      final jsonString = json.encode(property.toJson());
      await sharedPreferences.setString(
        '$CACHED_PROPERTY_PREFIX${property.id}',
        jsonString,
      );
    } catch (e) {
      throw CacheException('Failed to cache property');
    }
  }
  
  @override
  Future<void> clearCache() async {
    await sharedPreferences.remove(CACHED_PROPERTIES);
    await sharedPreferences.remove(CACHE_TIME);
    
    // Clear individual property caches
    final keys = sharedPreferences.getKeys();
    for (final key in keys) {
      if (key.startsWith(CACHED_PROPERTY_PREFIX)) {
        await sharedPreferences.remove(key);
      }
    }
  }
  
  @override
  Future<DateTime?> getLastCacheTime() async {
    final timeString = sharedPreferences.getString(CACHE_TIME);
    if (timeString != null) {
      return DateTime.tryParse(timeString);
    }
    return null;
  }
}