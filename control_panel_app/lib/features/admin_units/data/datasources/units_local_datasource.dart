import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/unit_model.dart';

abstract class UnitsLocalDataSource {
  Future<List<UnitModel>> getCachedUnits();
  Future<void> cacheUnits(List<UnitModel> units);
  Future<UnitModel?> getCachedUnit(String unitId);
  Future<void> cacheUnit(UnitModel unit);
  Future<void> clearCache();
}

class UnitsLocalDataSourceImpl implements UnitsLocalDataSource {
  final SharedPreferences sharedPreferences;
  
  static const String CACHED_UNITS_KEY = 'CACHED_UNITS';
  static const String CACHED_UNIT_PREFIX = 'CACHED_UNIT_';
  
  UnitsLocalDataSourceImpl({required this.sharedPreferences});
  
  @override
  Future<List<UnitModel>> getCachedUnits() async {
    final jsonString = sharedPreferences.getString(CACHED_UNITS_KEY);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => UnitModel.fromJson(json)).toList();
    }
    return [];
  }
  
  @override
  Future<void> cacheUnits(List<UnitModel> units) async {
    final jsonList = units.map((unit) => unit.toJson()).toList();
    await sharedPreferences.setString(
      CACHED_UNITS_KEY,
      json.encode(jsonList),
    );
  }
  
  @override
  Future<UnitModel?> getCachedUnit(String unitId) async {
    final jsonString = sharedPreferences.getString('$CACHED_UNIT_PREFIX$unitId');
    if (jsonString != null) {
      return UnitModel.fromJson(json.decode(jsonString));
    }
    return null;
  }
  
  @override
  Future<void> cacheUnit(UnitModel unit) async {
    await sharedPreferences.setString(
      '$CACHED_UNIT_PREFIX${unit.id}',
      json.encode(unit.toJson()),
    );
  }
  
  @override
  Future<void> clearCache() async {
    await sharedPreferences.remove(CACHED_UNITS_KEY);
    // Remove all cached individual units
    final keys = sharedPreferences.getKeys();
    for (final key in keys) {
      if (key.startsWith(CACHED_UNIT_PREFIX)) {
        await sharedPreferences.remove(key);
      }
    }
  }
}