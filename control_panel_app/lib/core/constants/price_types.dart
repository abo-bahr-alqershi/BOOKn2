/// أنواع التسعير
/// Price Types constants
class PriceType {
  static const String base = 'Base';
  static const String weekend = 'Weekend';
  static const String seasonal = 'Seasonal';
  static const String holiday = 'Holiday';
  static const String special = 'Special';
  static const String peak = 'Peak';
  static const String offPeak = 'OffPeak';
  static const String earlyBird = 'EarlyBird';
  static const String lastMinute = 'LastMinute';

  /// الأسماء بالعربية
  static const Map<String, String> arabicNames = {
    base: 'السعر الأساسي',
    weekend: 'نهاية الأسبوع',
    seasonal: 'موسمي',
    holiday: 'العطلات',
    special: 'خاص',
    peak: 'الذروة',
    offPeak: 'الركود',
    earlyBird: 'الحجز المبكر',
    lastMinute: 'اللحظة الأخيرة',
  };

  /// الأيقونات المرتبطة
  static const Map<String, String> typeIcons = {
    base: '💰',
    weekend: '🌴',
    seasonal: '🌞',
    holiday: '🎉',
    special: '⭐',
    peak: '📈',
    offPeak: '📉',
    earlyBird: '🐦',
    lastMinute: '⏰',
  };

  /// التحقق من صحة النوع
  static bool isValidType(String type) {
    return arabicNames.containsKey(type);
  }

  /// الحصول على الاسم بالعربية
  static String getArabicName(String type) {
    return arabicNames[type] ?? type;
  }

  /// الحصول على الأيقونة
  static String getIcon(String type) {
    return typeIcons[type] ?? '💰';
  }

  /// الحصول على جميع الأنواع
  static List<String> getAllTypes() {
    return arabicNames.keys.toList();
  }
}

/// فئات التسعير
/// Pricing Tiers constants
class PricingTier {
  static const String standard = 'Standard';
  static const String premium = 'Premium';
  static const String luxury = 'Luxury';
  static const String economy = 'Economy';

  /// الأسماء بالعربية
  static const Map<String, String> arabicNames = {
    standard: 'قياسي',
    premium: 'متميز',
    luxury: 'فاخر',
    economy: 'اقتصادي',
  };

  /// الألوان المرتبطة
  static const Map<String, int> tierColors = {
    standard: 0xFF2196F3, // Blue
    premium: 0xFF9C27B0, // Purple
    luxury: 0xFFFFC107, // Amber
    economy: 0xFF4CAF50, // Green
  };

  /// التحقق من صحة الفئة
  static bool isValidTier(String tier) {
    return arabicNames.containsKey(tier);
  }

  /// الحصول على الاسم بالعربية
  static String getArabicName(String tier) {
    return arabicNames[tier] ?? tier;
  }

  /// الحصول على اللون
  static int getTierColor(String tier) {
    return tierColors[tier] ?? 0xFF2196F3;
  }

  /// الحصول على جميع الفئات
  static List<String> getAllTiers() {
    return arabicNames.keys.toList();
  }
}
