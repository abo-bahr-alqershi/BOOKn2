import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service_model.dart';

/// 💾 Local Data Source للخدمات
abstract class ServicesLocalDataSource {
  Future<void> cacheServices(List<ServiceModel> services);
  Future<List<ServiceModel>?> getCachedServices();
  Future<void> clearCache();
}

class ServicesLocalDataSourceImpl implements ServicesLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String _cacheKey = 'CACHED_SERVICES';
  static const String _cacheTimestampKey = 'SERVICES_CACHE_TIMESTAMP';
  static const Duration _cacheValidDuration = Duration(hours: 1);

  ServicesLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheServices(List<ServiceModel> services) async {
    final jsonList = services.map((service) => service.toJson()).toList();
    await sharedPreferences.setString(
      _cacheKey,
      json.encode(jsonList),
    );
    await sharedPreferences.setInt(
      _cacheTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  Future<List<ServiceModel>?> getCachedServices() async {
    final jsonString = sharedPreferences.getString(_cacheKey);
    if (jsonString == null) return null;

    // Check cache validity
    final timestamp = sharedPreferences.getInt(_cacheTimestampKey);
    if (timestamp != null) {
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cacheTime) > _cacheValidDuration) {
        await clearCache();
        return null;
      }
    }

    final jsonList = json.decode(jsonString) as List;
    return jsonList.map((json) => ServiceModel.fromJson(json)).toList();
  }

  @override
  Future<void> clearCache() async {
    await sharedPreferences.remove(_cacheKey);
    await sharedPreferences.remove(_cacheTimestampKey);
  }
}