// lib/core/extensions/datetime_extension.dart

import 'package:bookn_cp_app/core/utils/timezone_helper.dart';

import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  /// تحويل من UTC إلى التوقيت المحلي
  DateTime get toLocalTime {
    if (isUtc) {
      return TimezoneHelper.convertFromUtc(this);
    }
    return this;
  }

  /// تحويل إلى UTC
  DateTime get toUtcTime {
    if (!isUtc) {
      return TimezoneHelper.convertToUtc(this);
    }
    return this;
  }

  /// تنسيق التاريخ للعرض (تاريخ فقط)
  String toDateString() {
    final local = toLocalTime;
    return DateFormat('dd/MM/yyyy').format(local);
  }

  /// تنسيق الوقت للعرض (وقت فقط)
  String toTimeString() {
    final local = toLocalTime;
    return DateFormat('HH:mm').format(local);
  }

  /// تنسيق التاريخ والوقت للعرض
  String toFormattedString() {
    final local = toLocalTime;
    return DateFormat('dd/MM/yyyy HH:mm').format(local);
  }

  /// تنسيق نسبي (منذ دقيقة، منذ ساعة، إلخ)
  String toRelativeString() {
    final now = DateTime.now();
    final difference = now.difference(toLocalTime);

    if (difference.inDays > 365) {
      return 'منذ ${difference.inDays ~/ 365} سنة';
    } else if (difference.inDays > 30) {
      return 'منذ ${difference.inDays ~/ 30} شهر';
    } else if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }
}

// Extension للتعامل مع String dates
extension StringDateExtension on String {
  /// تحويل string إلى DateTime مع معالجة timezone
  DateTime? toDateTime() {
    try {
      final utcDate = DateTime.parse(this);
      return TimezoneHelper.convertFromUtc(utcDate);
    } catch (_) {
      return null;
    }
  }

  /// تحويل وتنسيق string date
  String toFormattedDate() {
    final dt = toDateTime();
    if (dt == null) return this;
    return dt.toFormattedString();
  }
}
