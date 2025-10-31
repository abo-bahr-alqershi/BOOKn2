import 'package:intl/intl.dart'; // Add intl package to pubspec.yaml
import '../constants/app_constants.dart';

class Formatters {
  Formatters._();

  // Format Currency
  static String formatCurrency(double amount, String currencySymbol, {String locale = 'en_US'}) {
    // Use Intl package for proper localization and currency formatting
    // Example: 'en_US' for USD, 'ar_YE' for YER (Yemen Rial)
    // Ensure you have the necessary locales imported or configured if using specific regions.
    try {
      // For Yemen Rial (YER), locale might be 'ar_YE' or a general Arabic locale
      final localeToUse = locale.isEmpty ? 'ar' : locale; // Fallback to 'ar' if locale is empty
      
      // If Intl doesn't have 'ar_YE', using a generic arabic locale might work or default to English formatting
      final NumberFormat formatter = NumberFormat.currency(
        locale: localeToUse,
        symbol: currencySymbol,
        decimalDigits: 2, // Number of decimal places
      );
      return formatter.format(amount);
    } catch (e) {
      // Fallback formatting if locale is not supported or error occurs
      return '$currencySymbol ${amount.toStringAsFixed(2)}';
    }
  }

  // Format Date
  static String formatDate(DateTime date, {String format = AppConstants.dateFormat}) {
    try {
      final formatter = DateFormat(format);
      return formatter.format(date);
    } catch (e) {
      return ''; // Return empty string or handle error appropriately
    }
  }

  // Format Time
  static String formatTime(DateTime dateTime, {String format = AppConstants.timeFormat}) {
     try {
      final formatter = DateFormat(format);
      return formatter.format(dateTime);
    } catch (e) {
      return ''; // Return empty string or handle error appropriately
    }
  }

  // Format Date and Time
  static String formatDateTime(DateTime dateTime, {String format = AppConstants.dateTimeFormat}) {
     try {
      final formatter = DateFormat(format);
      return formatter.format(dateTime);
    } catch (e) {
      return ''; // Return empty string or handle error appropriately
    }
  }

  // Format Phone Number (Example - needs more robust logic for various formats)
  static String formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.startsWith('+967')) {
      return '+967 XXX XXX XXX'; // Masked phone number example
    }
    return phoneNumber; // Return as is if format is unknown
  }

  // Format Name (e.g., capitalize first letter)
  static String formatName(String name) {
    if (name.isEmpty) return '';
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }
  
  // Add other formatting methods as needed
}