import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class TimezoneHelper {
  static String? _cachedTimezone;
  static int? _cachedOffset;
  static bool _isInitialized = false;

  /// تهيئة timezone
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      _isInitialized = true;

      // الحصول على timezone مباشرة عند التهيئة
      await getDeviceTimezone();
    } catch (e) {
      print('Error initializing timezone: $e');
    }
  }

  /// الحصول على المنطقة الزمنية للجهاز
  static Future<String> getDeviceTimezone() async {
    if (_cachedTimezone != null) return _cachedTimezone!;

    try {
      // الحصول على timezone ID (مثل: Asia/Riyadh)
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      _cachedTimezone = timezoneInfo.identifier;

      // حساب الـ offset بالدقائق
      final now = DateTime.now();
      _cachedOffset = now.timeZoneOffset.inMinutes;

      print('📍 Device Timezone: $_cachedTimezone');
      print('⏰ UTC Offset: $_cachedOffset minutes');

      return _cachedTimezone!;
    } catch (e) {
      print('Error getting timezone: $e');

      // في حالة الفشل، استخدم UTC offset
      final offset = DateTime.now().timeZoneOffset;
      _cachedOffset = offset.inMinutes;
      _cachedTimezone = 'UTC${_formatOffset(offset)}';

      return _cachedTimezone!;
    }
  }

  /// الحصول على offset المنطقة الزمنية بالدقائق
  static int getTimezoneOffset() {
    if (_cachedOffset != null) return _cachedOffset!;

    final offset = DateTime.now().timeZoneOffset;
    _cachedOffset = offset.inMinutes;
    return _cachedOffset!;
  }

  /// تنسيق الـ offset للعرض
  static String _formatOffset(Duration offset) {
    final hours = offset.inHours;
    final minutes = offset.inMinutes.remainder(60).abs();
    final sign = offset.isNegative ? '-' : '+';

    if (minutes == 0) {
      return '$sign${hours.abs().toString().padLeft(2, '0')}:00';
    } else {
      return '$sign${hours.abs().toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    }
  }

  /// مسح الـ cache (للاستخدام عند تغيير timezone)
  static void clearCache() {
    _cachedTimezone = null;
    _cachedOffset = null;
  }

  /// الحصول على headers للـ API
  static Map<String, String> getTimezoneHeaders() {
    return {
      'X-TimeZone': _cachedTimezone ?? 'UTC',
      'X-TimeZone-Offset': (_cachedOffset ?? 0).toString(),
    };
  }

  /// تحويل التوقيت من UTC إلى المحلي
  static DateTime convertFromUtc(DateTime utcDateTime) {
    if (_cachedOffset == null) {
      getTimezoneOffset();
    }

    return utcDateTime.add(Duration(minutes: _cachedOffset ?? 0));
  }

  /// تحويل التوقيت من المحلي إلى UTC
  static DateTime convertToUtc(DateTime localDateTime) {
    if (_cachedOffset == null) {
      getTimezoneOffset();
    }

    return localDateTime.subtract(Duration(minutes: _cachedOffset ?? 0));
  }
}
