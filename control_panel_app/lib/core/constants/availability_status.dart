/// حالات الإتاحة
/// Availability Status constants
class AvailabilityStatus {
  static const String available = 'Available';
  static const String booked = 'Booked';
  static const String blocked = 'Blocked';
  static const String maintenance = 'Maintenance';
  static const String ownerUse = 'OwnerUse';

  /// الأسماء بالعربية
  static const Map<String, String> arabicNames = {
    available: 'متاح',
    booked: 'محجوز',
    blocked: 'محظور',
    maintenance: 'صيانة',
    ownerUse: 'استخدام المالك',
  };

  /// الألوان المرتبطة بكل حالة
  static const Map<String, int> statusColors = {
    available: 0xFF4CAF50, // Green
    booked: 0xFFFF9800, // Orange
    blocked: 0xFFF44336, // Red
    maintenance: 0xFF9E9E9E, // Grey
    ownerUse: 0xFF2196F3, // Blue
  };

  /// التحقق من صحة الحالة
  static bool isValidStatus(String status) {
    return status == available ||
        status == booked ||
        status == blocked ||
        status == maintenance ||
        status == ownerUse;
  }

  /// الحصول على الاسم بالعربية
  static String getArabicName(String status) {
    return arabicNames[status] ?? status;
  }

  /// الحصول على لون الحالة
  static int getStatusColor(String status) {
    return statusColors[status] ?? 0xFF9E9E9E;
  }

  /// الحصول على جميع الحالات
  static List<String> getAllStatuses() {
    return [available, booked, blocked, maintenance, ownerUse];
  }
}
