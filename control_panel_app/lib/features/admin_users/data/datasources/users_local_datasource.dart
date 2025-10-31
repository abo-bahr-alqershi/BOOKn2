import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class UsersLocalDataSource {
  Future<List<UserModel>> getCachedUsers();
  Future<void> cacheUsers(List<UserModel> users);
  Future<void> clearCache();
}

class UsersLocalDataSourceImpl implements UsersLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String _cachedUsersKey = 'CACHED_USERS';
  static const String _cacheTimestampKey = 'USERS_CACHE_TIMESTAMP';
  static const Duration _cacheValidDuration = Duration(hours: 1);

  UsersLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<UserModel>> getCachedUsers() async {
    try {
      // Check cache validity
      final timestamp = sharedPreferences.getInt(_cacheTimestampKey);
      if (timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        if (DateTime.now().difference(cacheTime) > _cacheValidDuration) {
          throw CacheException('Cache expired');
        }
      }

      final jsonString = sharedPreferences.getString(_cachedUsersKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList
            .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw CacheException('No cached users found');
      }
    } catch (e) {
      throw CacheException('Failed to get cached users: ${e.toString()}');
    }
  }

  @override
  Future<void> cacheUsers(List<UserModel> users) async {
    try {
      final jsonList = users.map((user) => user.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      await sharedPreferences.setString(_cachedUsersKey, jsonString);
      await sharedPreferences.setInt(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      throw CacheException('Failed to cache users: ${e.toString()}');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await sharedPreferences.remove(_cachedUsersKey);
      await sharedPreferences.remove(_cacheTimestampKey);
    } catch (e) {
      throw CacheException('Failed to clear cache: ${e.toString()}');
    }
  }
}