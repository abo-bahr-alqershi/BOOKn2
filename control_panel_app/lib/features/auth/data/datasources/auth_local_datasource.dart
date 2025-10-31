import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/exceptions.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';
import '../../../../core/constants/storage_constants.dart';
import '../../../../services/local_storage_service.dart';
import '../../../../injection_container.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheAuthResponse(AuthResponseModel authResponse);
  Future<AuthResponseModel?> getCachedAuthResponse();
  Future<void> cacheAccessToken(String token);
  Future<String?> getCachedAccessToken();
  Future<void> cacheRefreshToken(String token);
  Future<String?> getCachedRefreshToken();
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearAuthData();
  Future<bool> isLoggedIn();

  Future<void> saveData(String key, dynamic value) async {}
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  static const String _authResponseKey = 'AUTH_RESPONSE';
  static const String _accessTokenKey = 'ACCESS_TOKEN';
  static const String _refreshTokenKey = 'REFRESH_TOKEN';
  static const String _userKey = 'USER_DATA';

  @override
   Future<void> saveData(String key, dynamic value ) async {
    try {
      if (value is String) {
        await sharedPreferences.setString(key, value);
      } else if (value is int) {
        await sharedPreferences.setInt(key, value);
      } else if (value is double) {
        await sharedPreferences.setDouble(key, value);
      } else if (value is bool) {
        await sharedPreferences.setBool(key, value);
      } else if (value is List<String>) {
        await sharedPreferences.setStringList(key, value);
      }
    } catch (e) {
      throw const CacheException('فشل حفظ البيانات');
    }
  }
  
  @override
  Future<void> cacheAuthResponse(AuthResponseModel authResponse) async {
    try {
      final jsonString = json.encode(authResponse.toJson());
      await sharedPreferences.setString(_authResponseKey, jsonString);
      await cacheAccessToken(authResponse.accessToken);
      await cacheRefreshToken(authResponse.refreshToken);
      await cacheUser(authResponse.user as UserModel);

      // keep LocalStorageService in sync for interceptors
      final localStorage = sl<LocalStorageService>();
      await localStorage.saveData(StorageConstants.accessToken, authResponse.accessToken);
      await localStorage.saveData(StorageConstants.refreshToken, authResponse.refreshToken);
      await localStorage.saveData(StorageConstants.userId, authResponse.user.userId);
      await localStorage.saveData(StorageConstants.userEmail, authResponse.user.email);
      await localStorage.saveData(StorageConstants.accountRole, (authResponse.user as UserModel).accountRole ?? '');
      await localStorage.saveData(StorageConstants.propertyId, (authResponse.user as UserModel).propertyId ?? '');
      await localStorage.saveData(StorageConstants.propertyName, (authResponse.user as UserModel).propertyName ?? '');
      await localStorage.saveData(StorageConstants.propertyCurrency, (authResponse.user as UserModel).propertyCurrency ?? '');
    } catch (e) {
      throw const CacheException('فشل حفظ بيانات المصادقة');
    }
  }

  @override
  Future<AuthResponseModel?> getCachedAuthResponse() async {
    try {
      final jsonString = sharedPreferences.getString(_authResponseKey);
      if (jsonString != null) {
        final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        return AuthResponseModel.fromJson(jsonMap);
      }
      return null;
    } catch (e) {
      throw const CacheException('فشل قراءة بيانات المصادقة');
    }
  }

  @override
  Future<void> cacheAccessToken(String token) async {
    try {
      await sharedPreferences.setString(_accessTokenKey, token);
      // sync
      final localStorage = sl<LocalStorageService>();
      await localStorage.saveData(StorageConstants.accessToken, token);
    } catch (e) {
      throw const CacheException('فشل حفظ رمز الوصول');
    }
  }

  @override
  Future<String?> getCachedAccessToken() async {
    try {
      return sharedPreferences.getString(_accessTokenKey);
    } catch (e) {
      throw const CacheException('فشل قراءة رمز الوصول');
    }
  }

  @override
  Future<void> cacheRefreshToken(String token) async {
    try {
      await sharedPreferences.setString(_refreshTokenKey, token);
      // sync
      final localStorage = sl<LocalStorageService>();
      await localStorage.saveData(StorageConstants.refreshToken, token);
    } catch (e) {
      throw const CacheException('فشل حفظ رمز التحديث');
    }
  }

  @override
  Future<String?> getCachedRefreshToken() async {
    try {
      return sharedPreferences.getString(_refreshTokenKey);
    } catch (e) {
      throw const CacheException('فشل قراءة رمز التحديث');
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      final jsonString = json.encode(user.toJson());
      await sharedPreferences.setString(_userKey, jsonString);
      // sync
      final localStorage = sl<LocalStorageService>();
      await localStorage.saveData(StorageConstants.userId, user.userId);
      await localStorage.saveData(StorageConstants.userEmail, user.email);
      await localStorage.saveData(StorageConstants.accountRole, user.accountRole ?? '');
      await localStorage.saveData(StorageConstants.propertyId, user.propertyId ?? '');
      await localStorage.saveData(StorageConstants.propertyName, user.propertyName ?? '');
      await localStorage.saveData(StorageConstants.propertyCurrency, user.propertyCurrency ?? '');
    } catch (e) {
      throw const CacheException('فشل حفظ بيانات المستخدم');
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final jsonString = sharedPreferences.getString(_userKey);
      if (jsonString != null) {
        final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        return UserModel.fromJson(jsonMap);
      }
      return null;
    } catch (e) {
      throw const CacheException('فشل قراءة بيانات المستخدم');
    }
  }

  @override
  Future<void> clearAuthData() async {
    try {
      await Future.wait([
        sharedPreferences.remove(_authResponseKey),
        sharedPreferences.remove(_accessTokenKey),
        sharedPreferences.remove(_refreshTokenKey),
        sharedPreferences.remove(_userKey),
      ]);
      // sync
      final localStorage = sl<LocalStorageService>();
      await localStorage.removeData(StorageConstants.accessToken);
      await localStorage.removeData(StorageConstants.refreshToken);
      await localStorage.removeData(StorageConstants.userId);
      await localStorage.removeData(StorageConstants.userEmail);
      await localStorage.removeData(StorageConstants.accountRole);
      await localStorage.removeData(StorageConstants.propertyId);
      await localStorage.removeData(StorageConstants.propertyName);
      await localStorage.removeData(StorageConstants.propertyCurrency);
    } catch (e) {
      throw const CacheException('فشل مسح بيانات المصادقة');
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      final token = await getCachedAccessToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}