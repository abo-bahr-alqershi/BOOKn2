import 'package:flutter/material.dart';

/// 🎯 مساعد الأيقونات للتحويل بين أسماء الأيقونات و IconData
class IconHelper {
  IconHelper._();

  /// قائمة الأيقونات المتاحة مع أسمائها
  static final Map<String, IconData> _iconMap = {
    // أيقونات المباني والعقارات
    'home': Icons.home,
    'apartment': Icons.apartment,
    'villa': Icons.villa,
    'business': Icons.business,
    'store': Icons.store,
    'hotel': Icons.hotel,
    'house': Icons.house,
    'cabin': Icons.cabin,
    'meeting_room': Icons.meeting_room,
    'stairs': Icons.stairs,
    'roofing': Icons.roofing,
    'warehouse': Icons.warehouse,
    'terrain': Icons.terrain,
    'grass': Icons.grass,
    'location_city': Icons.location_city,
    'cottage': Icons.cottage,
    'holiday_village': Icons.holiday_village,
    'gite': Icons.gite,
    'domain': Icons.domain,
    'foundation': Icons.foundation,
    
    // أيقونات الغرف
    'bed': Icons.bed,
    'king_bed': Icons.king_bed,
    'single_bed': Icons.single_bed,
    'bedroom_parent': Icons.bedroom_parent,
    'bedroom_child': Icons.bedroom_child,
    'living': Icons.living,
    // Icons.dining_room does not exist; use dining instead
    'dining_room': Icons.dining,
    'kitchen': Icons.kitchen,
    'bathroom': Icons.bathroom,
    'bathtub': Icons.bathtub,
    'shower': Icons.shower,
    'garage': Icons.garage,
    'balcony': Icons.balcony,
    'deck': Icons.deck,
    'yard': Icons.yard,
    
    // أيقونات المرافق
    'pool': Icons.pool,
    'hot_tub': Icons.hot_tub,
    'fitness_center': Icons.fitness_center,
    'sports_tennis': Icons.sports_tennis,
    'sports_soccer': Icons.sports_soccer,
    'sports_basketball': Icons.sports_basketball,
    'spa': Icons.spa,
    'local_parking': Icons.local_parking,
    'elevator': Icons.elevator,
    'wifi': Icons.wifi,
    'ac_unit': Icons.ac_unit,
    'fireplace': Icons.fireplace,
    'water_drop': Icons.water_drop,
    'electric_bolt': Icons.electric_bolt,
    
    // أيقونات عامة
    'star': Icons.star,
    'favorite': Icons.favorite,
    'bookmark': Icons.bookmark,
    'share': Icons.share,
    'info': Icons.info,
    'help': Icons.help,
    'settings': Icons.settings,
    'phone': Icons.phone,
    'email': Icons.email,
    'message': Icons.message,
    'notifications': Icons.notifications,
  };

  /// الحصول على IconData من اسم الأيقونة
  static IconData getIconData(String iconName) {
    return _iconMap[iconName] ?? Icons.home;
  }

  /// الحصول على قائمة بجميع الأيقونات المتاحة
  static List<MapEntry<String, IconData>> getAllIcons() {
    return _iconMap.entries.toList();
  }

  /// البحث عن أيقونات بالاسم
  static List<MapEntry<String, IconData>> searchIcons(String query) {
    final lowerQuery = query.toLowerCase();
    return _iconMap.entries
        .where((entry) => entry.key.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// الحصول على أيقونات حسب الفئة
  static List<MapEntry<String, IconData>> getIconsByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'property':
      case 'عقارات':
        return _iconMap.entries
            .where((e) => ['home', 'apartment', 'villa', 'business', 'store', 
                          'hotel', 'house', 'cabin'].contains(e.key))
            .toList();
      case 'room':
      case 'غرف':
        return _iconMap.entries
            .where((e) => ['bed', 'bedroom_parent', 'bedroom_child', 'living',
                          'dining_room', 'kitchen', 'bathroom'].contains(e.key))
            .toList();
      case 'facility':
      case 'مرافق':
        return _iconMap.entries
            .where((e) => ['pool', 'hot_tub', 'fitness_center', 'spa',
                          'local_parking', 'elevator', 'wifi'].contains(e.key))
            .toList();
      default:
        return _iconMap.entries.toList();
    }
  }
}