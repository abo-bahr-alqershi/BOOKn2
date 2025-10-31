// lib/core/utils/currency_formatter.dart

import 'package:intl/intl.dart';

/// 💰 أداة تنسيق العملة
class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    symbol: '',
    decimalDigits: 2,
    locale: 'ar_SA',
  );

  static final _compactFormatter = NumberFormat.compactCurrency(
    symbol: '',
    decimalDigits: 0,
    locale: 'ar_SA',
  );

  /// Format currency with full decimals
  static String format(double amount, {String? currency}) {
    final formatted = _formatter.format(amount);
    if (currency != null && currency.isNotEmpty) {
      return '$formatted $currency';
    }
    return '${formatted} ريال';
  }

  /// Format currency in compact form (e.g., 1.5M, 2.3K)
  static String formatCompact(double amount, {String? currency}) {
    final formatted = _compactFormatter.format(amount);
    if (currency != null && currency.isNotEmpty) {
      return '$formatted $currency';
    }
    return '${formatted} ريال';
  }

  /// Format with custom decimal places
  static String formatWithDecimals(double amount, int decimals, {String? currency}) {
    final formatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: decimals,
      locale: 'ar_SA',
    );
    final formatted = formatter.format(amount);
    if (currency != null && currency.isNotEmpty) {
      return '$formatted $currency';
    }
    return '${formatted} ريال';
  }

  /// Format percentage
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  /// Parse string to double
  static double? parseAmount(String value) {
    try {
      // Remove currency symbols and spaces
      final cleanValue = value.replaceAll(RegExp(r'[^\d.-]'), '');
      return double.tryParse(cleanValue);
    } catch (e) {
      return null;
    }
  }
}
