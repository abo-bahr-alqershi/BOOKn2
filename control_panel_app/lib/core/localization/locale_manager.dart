import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/storage_constants.dart';
import '../../injection_container.dart'; // Ensure sl is initialized before this is used

class LocaleManager {
  LocaleManager._();

  static const List<Locale> supportedLocales = [
    Locale('en', ''), // English
    Locale('ar', ''), // Arabic
    // Add other supported locales here
  ];

  static const List<String> supportedLocalesShort = ['en', 'ar'];

  // Default locale if none is set or supported
  static const Locale defaultLocale = Locale('ar', ''); // Default to Arabic

  static Future<Locale> getInitialLocale() async {
    final prefs = sl<SharedPreferences>();
    final savedLocale = prefs.getString(StorageConstants.language);
    
    if (savedLocale != null && supportedLocalesShort.contains(savedLocale)) {
      return Locale(savedLocale, '');
    } else {
      // Try to get system locale if available and supported
      final String systemLocale = PlatformDispatcher.instance.locale.toString();
      if (supportedLocalesShort.contains(systemLocale.split('_')[0])) {
        return Locale(systemLocale.split('_')[0], '');
      }
      // Fallback to default locale
      return defaultLocale;
    }
  }

  static Future<void> setLocale(Locale locale) async {
    final prefs = sl<SharedPreferences>();
    await prefs.setString(StorageConstants.language, locale.languageCode);
    // Note: Flutter doesn't automatically rebuild widgets when locale changes.
    // The MaterialApp.router should rebuild when the locale state changes (e.g., via Bloc).
  }

  static Locale getCurrentLocale([BuildContext? context]) {
    if (context != null) {
      // Retrieve locale from MaterialApp's locale setting
      return Localizations.localeOf(context);
    }
    return defaultLocale;
  }
}