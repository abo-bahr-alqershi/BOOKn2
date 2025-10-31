// lib/core/utils/formatters.dart

import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class Formatters {
  Formatters._();

  // Format Currency
  static String formatCurrency(double amount, String currencySymbol,
      {String locale = 'en_US'}) {
    try {
      final localeToUse = locale.isEmpty ? 'ar' : locale;

      final NumberFormat formatter = NumberFormat.currency(
        locale: localeToUse,
        symbol: currencySymbol,
        decimalDigits: 2,
      );
      return formatter.format(amount);
    } catch (e) {
      return '$currencySymbol ${amount.toStringAsFixed(2)}';
    }
  }

  // Format Date
  static String formatDate(DateTime date,
      {String format = AppConstants.dateFormat}) {
    try {
      final formatter = DateFormat(format);
      return formatter.format(date);
    } catch (e) {
      return '';
    }
  }

  // Format Time
  static String formatTime(DateTime dateTime,
      {String format = AppConstants.timeFormat}) {
    try {
      final formatter = DateFormat(format);
      return formatter.format(dateTime);
    } catch (e) {
      return '';
    }
  }

  // Format Date and Time
  static String formatDateTime(DateTime dateTime,
      {String format = AppConstants.dateTimeFormat}) {
    try {
      final formatter = DateFormat(format);
      return formatter.format(dateTime);
    } catch (e) {
      return '';
    }
  }

  // 🎯 Format Time Only (HH:mm)
  static String formatTimeOnly(DateTime dateTime) {
    try {
      final formatter = DateFormat('HH:mm');
      return formatter.format(dateTime);
    } catch (e) {
      return '';
    }
  }

  // 🎯 Format Relative Time (منذ 5 دقائق، قبل ساعة، الأمس، إلخ)
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // أقل من دقيقة
    if (difference.inSeconds < 60) {
      if (difference.inSeconds <= 0) {
        return 'الآن';
      }
      return 'منذ ${difference.inSeconds} ${_getTimeUnit(difference.inSeconds, 'ثانية', 'ثانيتين', 'ثواني', 'ثانية')}';
    }

    // أقل من ساعة
    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} ${_getTimeUnit(difference.inMinutes, 'دقيقة', 'دقيقتين', 'دقائق', 'دقيقة')}';
    }

    // أقل من يوم
    if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ${_getTimeUnit(difference.inHours, 'ساعة', 'ساعتين', 'ساعات', 'ساعة')}';
    }

    // أقل من أسبوع
    if (difference.inDays < 7) {
      if (difference.inDays == 1) {
        return 'أمس';
      }
      return 'منذ ${difference.inDays} ${_getTimeUnit(difference.inDays, 'يوم', 'يومين', 'أيام', 'يوم')}';
    }

    // أقل من شهر
    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'منذ $weeks ${_getTimeUnit(weeks, 'أسبوع', 'أسبوعين', 'أسابيع', 'أسبوع')}';
    }

    // أقل من سنة
    if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'منذ $months ${_getTimeUnit(months, 'شهر', 'شهرين', 'شهور', 'شهر')}';
    }

    // أكثر من سنة
    final years = (difference.inDays / 365).floor();
    return 'منذ $years ${_getTimeUnit(years, 'سنة', 'سنتين', 'سنوات', 'سنة')}';
  }

  // 🎯 Helper function for Arabic pluralization
  static String _getTimeUnit(int count, String singular, String dual,
      String plural3to10, String plural11plus) {
    if (count == 1) {
      return singular;
    } else if (count == 2) {
      return dual;
    } else if (count >= 3 && count <= 10) {
      return plural3to10;
    } else {
      return plural11plus;
    }
  }

  // Format Phone Number
  static String formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) return '';

    // Remove any non-digit characters except +
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Yemen phone number format
    if (cleaned.startsWith('+967')) {
      if (cleaned.length >= 12) {
        // Format: +967 XXX XXX XXX
        return '+967 ${cleaned.substring(4, 7)} ${cleaned.substring(7, 10)} ${cleaned.substring(10)}';
      }
      return cleaned;
    }

    // Local Yemen number without country code
    if (cleaned.startsWith('7') && cleaned.length == 9) {
      // Format: 7XX XXX XXX
      return '${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6)}';
    }

    // Default formatting for other numbers
    if (cleaned.length >= 10) {
      // Generic format: XXX XXX XXXX
      return '${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6)}';
    }

    return phoneNumber;
  }

  // Format Name (with proper capitalization)
  static String formatName(String name) {
    if (name.isEmpty) return '';

    // Split by spaces and capitalize each word
    return name.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // 🎯 Format Number with Abbreviation (1K, 1M, etc.)
  static String formatCompactNumber(num number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(1)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  // 🎯 Format File Size
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }

  // 🎯 Format Duration
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} ${_getTimeUnit(duration.inDays, 'يوم', 'يومين', 'أيام', 'يوم')}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} ${_getTimeUnit(duration.inHours, 'ساعة', 'ساعتين', 'ساعات', 'ساعة')}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} ${_getTimeUnit(duration.inMinutes, 'دقيقة', 'دقيقتين', 'دقائق', 'دقيقة')}';
    } else {
      return '${duration.inSeconds} ${_getTimeUnit(duration.inSeconds, 'ثانية', 'ثانيتين', 'ثواني', 'ثانية')}';
    }
  }

  // 🎯 Format Percentage
  static String formatPercentage(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  // 🎯 Format Rating
  static String formatRating(double rating, {int decimals = 1}) {
    return rating.toStringAsFixed(decimals);
  }

  // 🎯 Format Distance (for maps/locations)
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} متر';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)} كم';
    }
  }

  // 🎯 Format Month Name
  static String formatMonthName(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }

  // 🎯 Format Day Name
  static String formatDayName(int weekday) {
    const days = [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد'
    ];
    if (weekday < 1 || weekday > 7) return '';
    return days[weekday - 1];
  }

  // 🎯 Format Credit Card Number (masked)
  static String formatCreditCard(String cardNumber) {
    if (cardNumber.length < 4) return cardNumber;

    final lastFour = cardNumber.substring(cardNumber.length - 4);
    return '**** **** **** $lastFour';
  }

  // 🎯 Format Boolean to Arabic
  static String formatBoolean(bool value) {
    return value ? 'نعم' : 'لا';
  }

  // 🎯 Format Status to Arabic
  static String formatStatus(String status) {
    final statusMap = {
      'pending': 'قيد الانتظار',
      'confirmed': 'مؤكد',
      'cancelled': 'ملغى',
      'completed': 'مكتمل',
      'active': 'نشط',
      'inactive': 'غير نشط',
      'approved': 'موافق عليه',
      'rejected': 'مرفوض',
      'draft': 'مسودة',
      'published': 'منشور',
    };

    return statusMap[status.toLowerCase()] ?? status;
  }
}
