import 'dart:convert';
import '../../../../services/local_storage_service.dart';
import '../../../../core/error/exceptions.dart';
import '../models/app_settings_model.dart';

abstract class SettingsLocalDataSource {
  Future<AppSettingsModel> getSettings();
  Future<bool> saveSettings(AppSettingsModel settings);
  Future<bool> updateLanguage(String languageCode);
  Future<bool> updateTheme(bool isDarkMode);
  Future<bool> updateNotificationSettings(NotificationSettingsModel settings);
  Future<bool> updateCurrency(String currencyCode);
  Future<bool> updateTimeZone(String timeZone);
  Future<bool> clearSettings();
  Future<AppSettingsModel?> getCachedSettings();
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final LocalStorageService localStorage;
  static const String _settingsKey = 'app_settings';
  static const String _languageKey = 'preferred_language';
  static const String _themeKey = 'dark_mode';
  static const String _currencyKey = 'preferred_currency';
  static const String _timeZoneKey = 'time_zone';
  static const String _notificationKey = 'notification_settings';

  SettingsLocalDataSourceImpl({required this.localStorage});

  @override
  Future<AppSettingsModel> getSettings() async {
    try {
      final settingsJson = localStorage.getData(_settingsKey);
      
      if (settingsJson != null && settingsJson is String) {
        final Map<String, dynamic> json = jsonDecode(settingsJson);
        return AppSettingsModel.fromJson(json);
      }
      
      // Return default settings if none exist
      return _createDefaultSettings();
    } catch (e) {
      throw CacheException('Failed to load settings: $e');
    }
  }

  @override
  Future<bool> saveSettings(AppSettingsModel settings) async {
    try {
      final json = jsonEncode(settings.toJson());
      return await localStorage.saveData(_settingsKey, json);
    } catch (e) {
      throw CacheException('Failed to save settings: $e');
    }
  }

  @override
  Future<bool> updateLanguage(String languageCode) async {
    try {
      await localStorage.saveData(_languageKey, languageCode);
      
      final settings = await getSettings();
      final updatedSettings = AppSettingsModel.fromEntity(
        settings.copyWith(
          preferredLanguage: languageCode,
          lastUpdated: DateTime.now(),
        ),
      );
      
      return await saveSettings(updatedSettings);
    } catch (e) {
      throw CacheException('Failed to update language: $e');
    }
  }

  @override
  Future<bool> updateTheme(bool isDarkMode) async {
    try {
      await localStorage.saveData(_themeKey, isDarkMode);
      
      final settings = await getSettings();
      final updatedSettings = AppSettingsModel.fromEntity(
        settings.copyWith(
          darkMode: isDarkMode,
          lastUpdated: DateTime.now(),
        ),
      );
      
      return await saveSettings(updatedSettings);
    } catch (e) {
      throw CacheException('Failed to update theme: $e');
    }
  }

  @override
  Future<bool> updateNotificationSettings(NotificationSettingsModel settings) async {
    try {
      final json = jsonEncode(settings.toJson());
      await localStorage.saveData(_notificationKey, json);
      
      final currentSettings = await getSettings();
      final updatedSettings = AppSettingsModel.fromEntity(
        currentSettings.copyWith(
          notificationSettings: settings,
          lastUpdated: DateTime.now(),
        ),
      );
      
      return await saveSettings(updatedSettings);
    } catch (e) {
      throw CacheException('Failed to update notification settings: $e');
    }
  }

  @override
  Future<bool> updateCurrency(String currencyCode) async {
    try {
      await localStorage.saveData(_currencyKey, currencyCode);
      
      final settings = await getSettings();
      final updatedSettings = AppSettingsModel.fromEntity(
        settings.copyWith(
          preferredCurrency: currencyCode,
          lastUpdated: DateTime.now(),
        ),
      );
      
      return await saveSettings(updatedSettings);
    } catch (e) {
      throw CacheException('Failed to update currency: $e');
    }
  }

  @override
  Future<bool> updateTimeZone(String timeZone) async {
    try {
      await localStorage.saveData(_timeZoneKey, timeZone);
      
      final settings = await getSettings();
      final updatedSettings = AppSettingsModel.fromEntity(
        settings.copyWith(
          timeZone: timeZone,
          lastUpdated: DateTime.now(),
        ),
      );
      
      return await saveSettings(updatedSettings);
    } catch (e) {
      throw CacheException('Failed to update time zone: $e');
    }
  }

  @override
  Future<bool> clearSettings() async {
    try {
      await localStorage.removeData(_settingsKey);
      await localStorage.removeData(_languageKey);
      await localStorage.removeData(_themeKey);
      await localStorage.removeData(_currencyKey);
      await localStorage.removeData(_timeZoneKey);
      await localStorage.removeData(_notificationKey);
      return true;
    } catch (e) {
      throw CacheException('Failed to clear settings: $e');
    }
  }

  @override
  Future<AppSettingsModel?> getCachedSettings() async {
    try {
      final settingsJson = localStorage.getData(_settingsKey);
      if (settingsJson != null && settingsJson is String) {
        final Map<String, dynamic> json = jsonDecode(settingsJson);
        return AppSettingsModel.fromJson(json);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  AppSettingsModel _createDefaultSettings() {
    return AppSettingsModel(
      preferredLanguage: 'ar',
      preferredCurrency: 'YER',
      timeZone: 'Asia/Aden',
      darkMode: false,
      notificationSettings: const NotificationSettingsModel(),
      additionalSettings: const {},
      lastUpdated: DateTime.now(),
    );
  }
}