import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalStorageService {
  final SharedPreferences _prefs;
  
  LocalStorageService(this._prefs);

  // Keys
  static const String _themeKey = 'app_theme';
  static const String _languageKey = 'app_language';
  static const String _onboardingKey = 'onboarding_completed';
  static const String _fcmTokenKey = 'fcm_token';
  static const String _lastSyncKey = 'last_sync';
  static const String _searchHistoryKey = 'search_history';
  static const String _filtersKey = 'search_filters';
  static const String _recentPropertiesKey = 'recent_properties';
  static const String _draftBookingKey = 'draft_booking';
  static const String _selectedCityKey = 'selected_city';
  static const String _selectedCurrencyKey = 'selected_currency';

  // Theme
  Future<bool> saveTheme(String theme) async {
    return await _prefs.setString(_themeKey, theme);
  }

  String? getTheme() {
    return _prefs.getString(_themeKey);
  }

  // Language
  Future<bool> saveLanguage(String languageCode) async {
    return await _prefs.setString(_languageKey, languageCode);
  }

  String getLanguage() {
    return _prefs.getString(_languageKey) ?? 'ar';
  }

  // Onboarding
  Future<bool> setOnboardingCompleted(bool completed) async {
    return await _prefs.setBool(_onboardingKey, completed);
  }

  bool isOnboardingCompleted() {
    return _prefs.getBool(_onboardingKey) ?? false;
  }

  // Selected City
  Future<bool> saveSelectedCity(String cityName) async {
    return await _prefs.setString(_selectedCityKey, cityName);
  }

  String getSelectedCity() {
    return _prefs.getString(_selectedCityKey) ?? '';
  }

// Currency methods
  Future<bool> saveSelectedCurrency(String currencyCode) async {
    return await _prefs.setString(_selectedCurrencyKey, currencyCode);
  }

  String getSelectedCurrency() {
    return _prefs.getString(_selectedCurrencyKey) ?? 'YER';
  }
  
  // FCM Token
  Future<bool> saveFcmToken(String token) async {
    return await _prefs.setString(_fcmTokenKey, token);
  }

  String? getFcmToken() {
    return _prefs.getString(_fcmTokenKey);
  }

  // Last Sync
  Future<bool> saveLastSyncTime(DateTime time) async {
    return await _prefs.setString(_lastSyncKey, time.toIso8601String());
  }

  DateTime? getLastSyncTime() {
    final timeString = _prefs.getString(_lastSyncKey);
    if (timeString != null) {
      return DateTime.tryParse(timeString);
    }
    return null;
  }

  // Search History
  Future<bool> saveSearchHistory(List<String> history) async {
    return await _prefs.setStringList(_searchHistoryKey, history);
  }

  List<String> getSearchHistory() {
    return _prefs.getStringList(_searchHistoryKey) ?? [];
  }

  Future<bool> addToSearchHistory(String query) async {
    final history = getSearchHistory();
    history.remove(query); // Remove if exists
    history.insert(0, query); // Add to beginning
    if (history.length > 10) {
      history.removeLast(); // Keep only last 10
    }
    return await saveSearchHistory(history);
  }

  Future<bool> clearSearchHistory() async {
    return await _prefs.remove(_searchHistoryKey);
  }

  // Search Filters
  Future<bool> saveSearchFilters(Map<String, dynamic> filters) async {
    final jsonString = json.encode(filters);
    return await _prefs.setString(_filtersKey, jsonString);
  }

  Map<String, dynamic>? getSearchFilters() {
    final jsonString = _prefs.getString(_filtersKey);
    if (jsonString != null) {
      try {
        return json.decode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Recent Properties
  Future<bool> saveRecentProperties(List<String> propertyIds) async {
    return await _prefs.setStringList(_recentPropertiesKey, propertyIds);
  }

  List<String> getRecentProperties() {
    return _prefs.getStringList(_recentPropertiesKey) ?? [];
  }

  Future<bool> addToRecentProperties(String propertyId) async {
    final properties = getRecentProperties();
    properties.remove(propertyId);
    properties.insert(0, propertyId);
    if (properties.length > 20) {
      properties.removeLast();
    }
    return await saveRecentProperties(properties);
  }

  // Draft Booking
  Future<bool> saveDraftBooking(Map<String, dynamic> bookingData) async {
    final jsonString = json.encode(bookingData);
    return await _prefs.setString(_draftBookingKey, jsonString);
  }

  Map<String, dynamic>? getDraftBooking() {
    final jsonString = _prefs.getString(_draftBookingKey);
    if (jsonString != null) {
      try {
        return json.decode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<bool> clearDraftBooking() async {
    return await _prefs.remove(_draftBookingKey);
  }

  // Generic methods
  Future<bool> saveData(String key, dynamic value) async {
    if (value is String) {
      return await _prefs.setString(key, value);
    } else if (value is int) {
      return await _prefs.setInt(key, value);
    } else if (value is double) {
      return await _prefs.setDouble(key, value);
    } else if (value is bool) {
      return await _prefs.setBool(key, value);
    } else if (value is List<String>) {
      return await _prefs.setStringList(key, value);
    } else {
      final jsonString = json.encode(value);
      return await _prefs.setString(key, jsonString);
    }
  }

  dynamic getData(String key) {
    return _prefs.get(key);
  }

  Future<bool> removeData(String key) async {
    return await _prefs.remove(key);
  }

  Future<bool> clearAll() async {
    return await _prefs.clear();
  }

  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }
  
  // Static convenience methods for compatibility
  static String? getString(String key) {
    // This is a placeholder - in reality you'd need a singleton instance
    throw UnimplementedError('Use instance methods instead');
  }
  
  static Future<bool> remove(String key) async {
    // This is a placeholder - in reality you'd need a singleton instance
    throw UnimplementedError('Use instance methods instead');
  }
}