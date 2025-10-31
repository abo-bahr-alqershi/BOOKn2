import 'package:flutter/material.dart';

/// 🎨 Amenity Icon Model
class AmenityIcon {
  final String name;
  final String label;
  final IconData icon;
  final String category;
  final String emoji;

  const AmenityIcon({
    required this.name,
    required this.label,
    required this.icon,
    required this.category,
    required this.emoji,
  });
}

/// 🏢 Amenity Icons Repository - متوافق مع React
class AmenityIcons {
  AmenityIcons._();

  /// قائمة جميع الأيقونات المتاحة للمرافق
  static const List<AmenityIcon> allIcons = [
    // مرافق أساسية
    AmenityIcon(name: 'wifi', label: 'واي فاي', icon: Icons.wifi, category: 'أساسيات', emoji: '📶'),
    AmenityIcon(name: 'network_wifi', label: 'شبكة واي فاي', icon: Icons.network_wifi, category: 'أساسيات', emoji: '📡'),
    AmenityIcon(name: 'signal_wifi_4_bar', label: 'واي فاي قوي', icon: Icons.signal_wifi_4_bar, category: 'أساسيات', emoji: '📶'),
    AmenityIcon(name: 'router', label: 'راوتر', icon: Icons.router, category: 'أساسيات', emoji: '🔌'),
    AmenityIcon(name: 'ac_unit', label: 'تكييف', icon: Icons.ac_unit, category: 'أساسيات', emoji: '❄️'),
    AmenityIcon(name: 'thermostat', label: 'ثرموستات', icon: Icons.thermostat, category: 'أساسيات', emoji: '🌡️'),
    AmenityIcon(name: 'air', label: 'تهوية', icon: Icons.air, category: 'أساسيات', emoji: '💨'),
    AmenityIcon(name: 'water_drop', label: 'ماء', icon: Icons.water_drop, category: 'أساسيات', emoji: '💧'),
    AmenityIcon(name: 'electric_bolt', label: 'كهرباء', icon: Icons.electric_bolt, category: 'أساسيات', emoji: '⚡'),
    AmenityIcon(name: 'gas_meter', label: 'غاز', icon: Icons.gas_meter, category: 'أساسيات', emoji: '🔥'),
    AmenityIcon(name: 'heat_pump', label: 'تدفئة', icon: Icons.heat_pump, category: 'أساسيات', emoji: '🔥'),
    AmenityIcon(name: 'light', label: 'إضاءة', icon: Icons.light, category: 'أساسيات', emoji: '💡'),
    
    // مرافق المطبخ
    AmenityIcon(name: 'kitchen', label: 'مطبخ', icon: Icons.kitchen, category: 'مطبخ', emoji: '🍳'),
    AmenityIcon(name: 'microwave', label: 'مايكروويف', icon: Icons.microwave, category: 'مطبخ', emoji: '📦'),
    AmenityIcon(name: 'coffee_maker', label: 'صانع القهوة', icon: Icons.coffee_maker, category: 'مطبخ', emoji: '☕'),
    AmenityIcon(name: 'blender', label: 'خلاط', icon: Icons.blender, category: 'مطبخ', emoji: '🥤'),
    AmenityIcon(name: 'dining', label: 'غرفة طعام', icon: Icons.dining, category: 'مطبخ', emoji: '🍽️'),
    AmenityIcon(name: 'restaurant', label: 'مطعم', icon: Icons.restaurant, category: 'مطبخ', emoji: '🍴'),
    AmenityIcon(name: 'local_cafe', label: 'مقهى', icon: Icons.local_cafe, category: 'مطبخ', emoji: '☕'),
    AmenityIcon(name: 'local_bar', label: 'بار', icon: Icons.local_bar, category: 'مطبخ', emoji: '🍺'),
    AmenityIcon(name: 'breakfast_dining', label: 'إفطار', icon: Icons.breakfast_dining, category: 'مطبخ', emoji: '🍳'),
    AmenityIcon(name: 'lunch_dining', label: 'غداء', icon: Icons.lunch_dining, category: 'مطبخ', emoji: '🍽️'),
    AmenityIcon(name: 'dinner_dining', label: 'عشاء', icon: Icons.dinner_dining, category: 'مطبخ', emoji: '🍽️'),
    AmenityIcon(name: 'outdoor_grill', label: 'شواية خارجية', icon: Icons.outdoor_grill, category: 'مطبخ', emoji: '🍖'),
    AmenityIcon(name: 'countertops', label: 'أسطح عمل', icon: Icons.countertops, category: 'مطبخ', emoji: '🔲'),
    
    // أجهزة كهربائية
    AmenityIcon(name: 'tv', label: 'تلفزيون', icon: Icons.tv, category: 'أجهزة', emoji: '📺'),
    AmenityIcon(name: 'desktop_windows', label: 'كمبيوتر', icon: Icons.desktop_windows, category: 'أجهزة', emoji: '💻'),
    AmenityIcon(name: 'laptop', label: 'لابتوب', icon: Icons.laptop, category: 'أجهزة', emoji: '💻'),
    AmenityIcon(name: 'phone_android', label: 'هاتف', icon: Icons.phone_android, category: 'أجهزة', emoji: '📱'),
    AmenityIcon(name: 'tablet', label: 'تابلت', icon: Icons.tablet, category: 'أجهزة', emoji: '📱'),
    AmenityIcon(name: 'speaker', label: 'سماعات', icon: Icons.speaker, category: 'أجهزة', emoji: '🔊'),
    AmenityIcon(name: 'radio', label: 'راديو', icon: Icons.radio, category: 'أجهزة', emoji: '📻'),
    AmenityIcon(name: 'videogame_asset', label: 'ألعاب فيديو', icon: Icons.videogame_asset, category: 'أجهزة', emoji: '🎮'),
    AmenityIcon(name: 'local_laundry_service', label: 'غسالة', icon: Icons.local_laundry_service, category: 'أجهزة', emoji: '🧺'),
    AmenityIcon(name: 'dry_cleaning', label: 'تنظيف جاف', icon: Icons.dry_cleaning, category: 'أجهزة', emoji: '👔'),
    AmenityIcon(name: 'iron', label: 'مكواة', icon: Icons.iron, category: 'أجهزة', emoji: '👔'),
    // Icons.dishwasher may not exist in current Flutter Material set; use alternative
    AmenityIcon(name: 'dishwasher', label: 'غسالة صحون', icon: Icons.kitchen, category: 'أجهزة', emoji: '🍽️'),
    
    // مرافق الحمام
    AmenityIcon(name: 'bathroom', label: 'حمام', icon: Icons.bathroom, category: 'حمام', emoji: '🚿'),
    AmenityIcon(name: 'bathtub', label: 'حوض استحمام', icon: Icons.bathtub, category: 'حمام', emoji: '🛁'),
    AmenityIcon(name: 'shower', label: 'دش', icon: Icons.shower, category: 'حمام', emoji: '🚿'),
    AmenityIcon(name: 'soap', label: 'صابون', icon: Icons.soap, category: 'حمام', emoji: '🧼'),
    AmenityIcon(name: 'dry', label: 'مجفف', icon: Icons.dry, category: 'حمام', emoji: '💨'),
    AmenityIcon(name: 'wash', label: 'غسيل', icon: Icons.wash, category: 'حمام', emoji: '🧴'),
    
    // مرافق النوم والراحة
    AmenityIcon(name: 'bed', label: 'سرير', icon: Icons.bed, category: 'نوم', emoji: '🛏️'),
    AmenityIcon(name: 'king_bed', label: 'سرير كبير', icon: Icons.king_bed, category: 'نوم', emoji: '🛏️'),
    AmenityIcon(name: 'single_bed', label: 'سرير مفرد', icon: Icons.single_bed, category: 'نوم', emoji: '🛏️'),
    AmenityIcon(name: 'bedroom_parent', label: 'غرفة نوم رئيسية', icon: Icons.bedroom_parent, category: 'نوم', emoji: '🛏️'),
    AmenityIcon(name: 'bedroom_child', label: 'غرفة أطفال', icon: Icons.bedroom_child, category: 'نوم', emoji: '🛏️'),
    AmenityIcon(name: 'crib', label: 'سرير أطفال', icon: Icons.crib, category: 'نوم', emoji: '👶'),
    AmenityIcon(name: 'chair', label: 'كرسي', icon: Icons.chair, category: 'نوم', emoji: '🪑'),
    AmenityIcon(name: 'chair_alt', label: 'كرسي مريح', icon: Icons.chair_alt, category: 'نوم', emoji: '🪑'),
    AmenityIcon(name: 'weekend', label: 'أريكة', icon: Icons.weekend, category: 'نوم', emoji: '🛋️'),
    AmenityIcon(name: 'living', label: 'غرفة معيشة', icon: Icons.living, category: 'نوم', emoji: '🛋️'),
    
    // مرافق رياضية وترفيهية
    AmenityIcon(name: 'pool', label: 'مسبح', icon: Icons.pool, category: 'رياضة', emoji: '🏊'),
    AmenityIcon(name: 'hot_tub', label: 'جاكوزي', icon: Icons.hot_tub, category: 'رياضة', emoji: '♨️'),
    AmenityIcon(name: 'fitness_center', label: 'صالة رياضية', icon: Icons.fitness_center, category: 'رياضة', emoji: '💪'),
    AmenityIcon(name: 'sports_tennis', label: 'ملعب تنس', icon: Icons.sports_tennis, category: 'رياضة', emoji: '🎾'),
    AmenityIcon(name: 'sports_soccer', label: 'ملعب كرة قدم', icon: Icons.sports_soccer, category: 'رياضة', emoji: '⚽'),
    AmenityIcon(name: 'sports_basketball', label: 'ملعب كرة سلة', icon: Icons.sports_basketball, category: 'رياضة', emoji: '🏀'),
    AmenityIcon(name: 'sports_volleyball', label: 'كرة طائرة', icon: Icons.sports_volleyball, category: 'رياضة', emoji: '🏐'),
    AmenityIcon(name: 'sports_golf', label: 'جولف', icon: Icons.sports_golf, category: 'رياضة', emoji: '⛳'),
    AmenityIcon(name: 'sports_handball', label: 'كرة يد', icon: Icons.sports_handball, category: 'رياضة', emoji: '🤾'),
    AmenityIcon(name: 'sports_cricket', label: 'كريكيت', icon: Icons.sports_cricket, category: 'رياضة', emoji: '🏏'),
    AmenityIcon(name: 'sports_baseball', label: 'بيسبول', icon: Icons.sports_baseball, category: 'رياضة', emoji: '⚾'),
    AmenityIcon(name: 'sports_esports', label: 'ألعاب إلكترونية', icon: Icons.sports_esports, category: 'رياضة', emoji: '🎮'),
    AmenityIcon(name: 'spa', label: 'سبا', icon: Icons.spa, category: 'رياضة', emoji: '💆'),
    // Icons.sauna may not exist in current Flutter Material set; use spa as fallback
    AmenityIcon(name: 'sauna', label: 'ساونا', icon: Icons.spa, category: 'رياضة', emoji: '🧖'),
    AmenityIcon(name: 'self_improvement', label: 'يوغا', icon: Icons.self_improvement, category: 'رياضة', emoji: '🧘'),
    
    // مرافق المواصلات والمواقف
    AmenityIcon(name: 'local_parking', label: 'موقف سيارات', icon: Icons.local_parking, category: 'مواصلات', emoji: '🅿️'),
    AmenityIcon(name: 'garage', label: 'كراج', icon: Icons.garage, category: 'مواصلات', emoji: '🚗'),
    AmenityIcon(name: 'ev_station', label: 'شحن سيارات كهربائية', icon: Icons.ev_station, category: 'مواصلات', emoji: '🔌'),
    AmenityIcon(name: 'local_gas_station', label: 'محطة وقود', icon: Icons.local_gas_station, category: 'مواصلات', emoji: '⛽'),
    AmenityIcon(name: 'car_rental', label: 'تأجير سيارات', icon: Icons.car_rental, category: 'مواصلات', emoji: '🚙'),
    AmenityIcon(name: 'car_repair', label: 'صيانة سيارات', icon: Icons.car_repair, category: 'مواصلات', emoji: '🔧'),
    AmenityIcon(name: 'directions_car', label: 'سيارة', icon: Icons.directions_car, category: 'مواصلات', emoji: '🚗'),
    AmenityIcon(name: 'directions_bus', label: 'حافلة', icon: Icons.directions_bus, category: 'مواصلات', emoji: '🚌'),
    AmenityIcon(name: 'directions_bike', label: 'دراجة', icon: Icons.directions_bike, category: 'مواصلات', emoji: '🚴'),
    AmenityIcon(name: 'electric_bike', label: 'دراجة كهربائية', icon: Icons.electric_bike, category: 'مواصلات', emoji: '🚴'),
    AmenityIcon(name: 'electric_scooter', label: 'سكوتر كهربائي', icon: Icons.electric_scooter, category: 'مواصلات', emoji: '🛴'),
    AmenityIcon(name: 'moped', label: 'دراجة نارية', icon: Icons.moped, category: 'مواصلات', emoji: '🏍️'),
    
    // مرافق المصاعد والسلالم
    AmenityIcon(name: 'elevator', label: 'مصعد', icon: Icons.elevator, category: 'وصول', emoji: '🛗'),
    AmenityIcon(name: 'stairs', label: 'درج', icon: Icons.stairs, category: 'وصول', emoji: '📶'),
    AmenityIcon(name: 'escalator', label: 'سلم متحرك', icon: Icons.escalator, category: 'وصول', emoji: '🔼'),
    AmenityIcon(name: 'escalator_warning', label: 'تحذير سلم متحرك', icon: Icons.escalator_warning, category: 'وصول', emoji: '⚠️'),
    AmenityIcon(name: 'accessible', label: 'ممر لذوي الاحتياجات', icon: Icons.accessible, category: 'وصول', emoji: '♿'),
    AmenityIcon(name: 'wheelchair_pickup', label: 'كرسي متحرك', icon: Icons.wheelchair_pickup, category: 'وصول', emoji: '♿'),
    AmenityIcon(name: 'elderly', label: 'كبار السن', icon: Icons.elderly, category: 'وصول', emoji: '👴'),
    
    // مرافق الأمان
    AmenityIcon(name: 'security', label: 'أمن', icon: Icons.security, category: 'أمان', emoji: '🔒'),
    AmenityIcon(name: 'lock', label: 'قفل', icon: Icons.lock, category: 'أمان', emoji: '🔒'),
    AmenityIcon(name: 'key', label: 'مفتاح', icon: Icons.key, category: 'أمان', emoji: '🔑'),
    AmenityIcon(name: 'vpn_key', label: 'مفتاح رقمي', icon: Icons.vpn_key, category: 'أمان', emoji: '🔐'),
    AmenityIcon(name: 'shield', label: 'درع', icon: Icons.shield, category: 'أمان', emoji: '🛡️'),
    AmenityIcon(name: 'admin_panel_settings', label: 'لوحة تحكم', icon: Icons.admin_panel_settings, category: 'أمان', emoji: '⚙️'),
    AmenityIcon(name: 'verified_user', label: 'مستخدم موثق', icon: Icons.verified_user, category: 'أمان', emoji: '✅'),
    AmenityIcon(name: 'safety_check', label: 'فحص أمان', icon: Icons.safety_check, category: 'أمان', emoji: '✅'),
    AmenityIcon(name: 'health_and_safety', label: 'صحة وأمان', icon: Icons.health_and_safety, category: 'أمان', emoji: '🏥'),
    AmenityIcon(name: 'local_police', label: 'شرطة', icon: Icons.local_police, category: 'أمان', emoji: '👮'),
    AmenityIcon(name: 'local_fire_department', label: 'إطفاء', icon: Icons.local_fire_department, category: 'أمان', emoji: '🚒'),
    AmenityIcon(name: 'medical_services', label: 'خدمات طبية', icon: Icons.medical_services, category: 'أمان', emoji: '🏥'),
    AmenityIcon(name: 'emergency', label: 'طوارئ', icon: Icons.emergency, category: 'أمان', emoji: '🚨'),
    AmenityIcon(name: 'camera_alt', label: 'كاميرا', icon: Icons.camera_alt, category: 'أمان', emoji: '📷'),
    AmenityIcon(name: 'videocam', label: 'كاميرا فيديو', icon: Icons.videocam, category: 'أمان', emoji: '📹'),
    AmenityIcon(name: 'sensor_door', label: 'حساس باب', icon: Icons.sensor_door, category: 'أمان', emoji: '🚪'),
    AmenityIcon(name: 'sensor_window', label: 'حساس نافذة', icon: Icons.sensor_window, category: 'أمان', emoji: '🪟'),
    AmenityIcon(name: 'doorbell', label: 'جرس الباب', icon: Icons.doorbell, category: 'أمان', emoji: '🔔'),
    AmenityIcon(name: 'smoke_free', label: 'كاشف دخان', icon: Icons.smoke_free, category: 'أمان', emoji: '🚨'),
    AmenityIcon(name: 'fire_extinguisher', label: 'طفاية حريق', icon: Icons.fire_extinguisher, category: 'أمان', emoji: '🧯'),
    
    // خدمات إضافية
    AmenityIcon(name: 'cleaning_services', label: 'خدمة تنظيف', icon: Icons.cleaning_services, category: 'خدمات', emoji: '🧹'),
    AmenityIcon(name: 'room_service', label: 'خدمة الغرف', icon: Icons.room_service, category: 'خدمات', emoji: '🛎️'),
    AmenityIcon(name: 'support_agent', label: 'كونسيرج', icon: Icons.support_agent, category: 'خدمات', emoji: '🧑‍💼'),
    AmenityIcon(name: 'luggage', label: 'أمتعة', icon: Icons.luggage, category: 'خدمات', emoji: '🧳'),
    AmenityIcon(name: 'shopping_cart', label: 'عربة تسوق', icon: Icons.shopping_cart, category: 'خدمات', emoji: '🛒'),
    AmenityIcon(name: 'local_grocery_store', label: 'بقالة', icon: Icons.local_grocery_store, category: 'خدمات', emoji: '🛒'),
    AmenityIcon(name: 'local_mall', label: 'مول', icon: Icons.local_mall, category: 'خدمات', emoji: '🛍️'),
    AmenityIcon(name: 'local_pharmacy', label: 'صيدلية', icon: Icons.local_pharmacy, category: 'خدمات', emoji: '💊'),
    AmenityIcon(name: 'local_hospital', label: 'مستشفى', icon: Icons.local_hospital, category: 'خدمات', emoji: '🏥'),
    AmenityIcon(name: 'local_atm', label: 'صراف آلي', icon: Icons.local_atm, category: 'خدمات', emoji: '💳'),
    AmenityIcon(name: 'local_library', label: 'مكتبة', icon: Icons.local_library, category: 'خدمات', emoji: '📚'),
    AmenityIcon(name: 'local_post_office', label: 'بريد', icon: Icons.local_post_office, category: 'خدمات', emoji: '📮'),
    AmenityIcon(name: 'print', label: 'طباعة', icon: Icons.print, category: 'خدمات', emoji: '🖨️'),
    AmenityIcon(name: 'mail', label: 'بريد', icon: Icons.mail, category: 'خدمات', emoji: '📧'),
    
    // مرافق خارجية
    AmenityIcon(name: 'balcony', label: 'شرفة', icon: Icons.balcony, category: 'خارجي', emoji: '🌅'),
    AmenityIcon(name: 'deck', label: 'سطح', icon: Icons.deck, category: 'خارجي', emoji: '☀️'),
    AmenityIcon(name: 'yard', label: 'فناء', icon: Icons.yard, category: 'خارجي', emoji: '🏡'),
    AmenityIcon(name: 'grass', label: 'حديقة', icon: Icons.grass, category: 'خارجي', emoji: '🌿'),
    AmenityIcon(name: 'park', label: 'منتزه', icon: Icons.park, category: 'خارجي', emoji: '🌳'),
    AmenityIcon(name: 'forest', label: 'غابة', icon: Icons.forest, category: 'خارجي', emoji: '🌲'),
    AmenityIcon(name: 'beach_access', label: 'شاطئ', icon: Icons.beach_access, category: 'خارجي', emoji: '🏖️'),
    AmenityIcon(name: 'water', label: 'مياه', icon: Icons.water, category: 'خارجي', emoji: '💧'),
    AmenityIcon(name: 'fence', label: 'سياج', icon: Icons.fence, category: 'خارجي', emoji: '🚧'),
    AmenityIcon(name: 'roofing', label: 'سقف', icon: Icons.roofing, category: 'خارجي', emoji: '🏗️'),
    
    // مرافق الأطفال
    AmenityIcon(name: 'child_care', label: 'رعاية أطفال', icon: Icons.child_care, category: 'أطفال', emoji: '👶'),
    AmenityIcon(name: 'child_friendly', label: 'صديق للأطفال', icon: Icons.child_friendly, category: 'أطفال', emoji: '👨‍👩‍👧‍👦'),
    AmenityIcon(name: 'baby_changing_station', label: 'غرفة تغيير حفاضات', icon: Icons.baby_changing_station, category: 'أطفال', emoji: '👶'),
    AmenityIcon(name: 'toys', label: 'ألعاب', icon: Icons.toys, category: 'أطفال', emoji: '🧸'),
    AmenityIcon(name: 'stroller', label: 'عربة أطفال', icon: Icons.stroller, category: 'أطفال', emoji: '👶'),
    
    // مرافق الحيوانات الأليفة
    AmenityIcon(name: 'pets', label: 'حيوانات أليفة', icon: Icons.pets, category: 'حيوانات', emoji: '🐾'),
    
    // مرافق العمل والدراسة
    AmenityIcon(name: 'desk', label: 'مكتب', icon: Icons.desk, category: 'عمل', emoji: '🪑'),
    AmenityIcon(name: 'meeting_room', label: 'قاعة اجتماعات', icon: Icons.meeting_room, category: 'عمل', emoji: '👥'),
    AmenityIcon(name: 'business_center', label: 'مركز أعمال', icon: Icons.business_center, category: 'عمل', emoji: '💼'),
    AmenityIcon(name: 'computer', label: 'كمبيوتر', icon: Icons.computer, category: 'عمل', emoji: '💻'),
    AmenityIcon(name: 'scanner', label: 'ماسح ضوئي', icon: Icons.scanner, category: 'عمل', emoji: '📄'),
    AmenityIcon(name: 'fax', label: 'فاكس', icon: Icons.fax, category: 'عمل', emoji: '📠'),
    
    // مرافق دينية
    AmenityIcon(name: 'mosque', label: 'مسجد', icon: Icons.mosque, category: 'ديني', emoji: '🕌'),
    AmenityIcon(name: 'church', label: 'كنيسة', icon: Icons.church, category: 'ديني', emoji: '⛪'),
    AmenityIcon(name: 'synagogue', label: 'كنيس', icon: Icons.synagogue, category: 'ديني', emoji: '🕍'),
    AmenityIcon(name: 'temple_hindu', label: 'معبد هندوسي', icon: Icons.temple_hindu, category: 'ديني', emoji: '🛕'),
    AmenityIcon(name: 'temple_buddhist', label: 'معبد بوذي', icon: Icons.temple_buddhist, category: 'ديني', emoji: '🏛️'),
  ];

  /// الحصول على جميع الفئات
  static List<String> get categories {
    return ['الكل', ...allIcons.map((icon) => icon.category).toSet()];
  }

  /// البحث عن أيقونة بالاسم
  static AmenityIcon? getIconByName(String name) {
    try {
      return allIcons.firstWhere((icon) => icon.name == name);
    } catch (_) {
      return null;
    }
  }

  /// الحصول على IconData من اسم الأيقونة
  static IconData getIconData(String? iconName) {
    if (iconName == null || iconName.isEmpty) return Icons.star_rounded;
    
    final amenityIcon = getIconByName(iconName);
    return amenityIcon?.icon ?? Icons.star_rounded;
  }

  /// الحصول على الإيموجي من اسم الأيقونة
  static String getEmoji(String? iconName) {
    if (iconName == null || iconName.isEmpty) return '🏠';
    
    final amenityIcon = getIconByName(iconName);
    return amenityIcon?.emoji ?? '🏠';
  }

  /// البحث في الأيقونات
  static List<AmenityIcon> searchIcons(String query, {String? category}) {
    return allIcons.where((icon) {
      final matchesQuery = query.isEmpty ||
          icon.name.toLowerCase().contains(query.toLowerCase()) ||
          icon.label.toLowerCase().contains(query.toLowerCase());
      
      final matchesCategory = category == null || 
          category == 'الكل' || 
          icon.category == category;
      
      return matchesQuery && matchesCategory;
    }).toList();
  }
}