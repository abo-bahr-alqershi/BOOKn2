import 'package:intl/intl.dart'; // Add intl package to pubspec.yaml
import '../constants/app_constants.dart';

class DateUtils {
  DateUtils._();

  static DateTime? parseDate(String? dateString, {String format = AppConstants.dateFormat}) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateFormat(format).parse(dateString);
    } on FormatException {
      return null; // Handle parsing errors
    }
  }

  static DateTime? parseDateTime(String? dateTimeString, {String format = AppConstants.dateTimeFormat}) {
     if (dateTimeString == null || dateTimeString.isEmpty) return null;
    try {
      return DateFormat(format).parse(dateTimeString);
    } on FormatException {
      return null; // Handle parsing errors
    }
  }

  static String formatRelativeTime(DateTime dateTime) {
    final Duration difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} سنة'; // years ago
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} شهر'; // months ago
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} أسبوع'; // weeks ago
    } else if (difference.inDays == 1) {
      return 'أمس'; // yesterday
    } else if (difference.inDays > 0) {
      return '${difference.inDays} يوم'; // days ago
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعة'; // hours ago
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} دقيقة'; // minutes ago
    } else if (difference.inSeconds > 0) {
      return '${difference.inSeconds} ثانية'; // seconds ago
    } else {
      return 'الآن'; // just now
    }
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  static DateTime addDays(DateTime date, int days) {
    return date.add(Duration(days: days));
  }

  static DateTime subtractDays(DateTime date, int days) {
    return date.subtract(Duration(days: days));
  }

  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  // Add more date utility functions as needed
}