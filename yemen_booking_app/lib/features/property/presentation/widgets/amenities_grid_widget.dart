// lib/features/property/presentation/widgets/amenities_grid_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/amenity.dart';

class AmenitiesGridWidget extends StatefulWidget {
  final List<Amenity> amenities;

  const AmenitiesGridWidget({
    super.key,
    required this.amenities,
  });

  @override
  State<AmenitiesGridWidget> createState() => _AmenitiesGridWidgetState();
}

class _AmenitiesGridWidgetState extends State<AmenitiesGridWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final Map<String, bool> _expandedCategories = {};
  String? _selectedAmenityId;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    
    // Initialize categories as expanded
    final categories = _groupAmenitiesByCategory();
    for (final category in categories.keys) {
      _expandedCategories[category] = true;
    }
  }
  
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
  
  Map<String, List<Amenity>> _groupAmenitiesByCategory() {
    final groupedAmenities = <String, List<Amenity>>{};
    for (final amenity in widget.amenities) {
      final category = amenity.category ?? 'عام';
      if (!groupedAmenities.containsKey(category)) {
        groupedAmenities[category] = [];
      }
      groupedAmenities[category]!.add(amenity);
    }
    return groupedAmenities;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.amenities.isEmpty) {
      return _buildUltraMinimalEmptyState();
    }

    final groupedAmenities = _groupAmenitiesByCategory();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: groupedAmenities.length,
        itemBuilder: (context, index) {
          final category = groupedAmenities.keys.elementAt(index);
          final categoryAmenities = groupedAmenities[category]!;
          
          return _buildUltraMinimalCategory(
            category,
            categoryAmenities,
            index,
          );
        },
      ),
    );
  }
  
  Widget _buildUltraMinimalEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.info_outline,
              size: 24,
              color: AppTheme.primaryBlue.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد مرافق',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'سيتم إضافة المرافق قريباً',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUltraMinimalCategory(
    String category,
    List<Amenity> amenities,
    int categoryIndex,
  ) {
    final isExpanded = _expandedCategories[category] ?? false;
    final categoryColor = _getCategoryColor(category);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.05),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              _buildMinimalCategoryHeader(category, categoryColor, amenities.length),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: isExpanded ? null : 0,
                child: isExpanded
                    ? _buildMinimalAmenitiesGrid(amenities, categoryIndex)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMinimalCategoryHeader(String category, Color color, int count) {
    final isExpanded = _expandedCategories[category] ?? false;
    
    return InkWell(
      onTap: () {
        setState(() {
          _expandedCategories[category] = !isExpanded;
        });
        HapticFeedback.selectionClick();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.05),
              color.withOpacity(0.02),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.1),
                    color.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getCategoryIcon(category),
                size: 16,
                color: color.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textWhite.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '$count مرافق',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.expand_more,
                color: AppTheme.textMuted.withOpacity(0.3),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMinimalAmenitiesGrid(List<Amenity> amenities, int categoryIndex) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: amenities.map((amenity) {
          return _buildUltraMinimalAmenityChip(amenity);
        }).toList(),
      ),
    );
  }
  
  Widget _buildUltraMinimalAmenityChip(Amenity amenity) {
    final isSelected = _selectedAmenityId == amenity.id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAmenityId = isSelected ? null : amenity.id;
        });
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.08),
                    AppTheme.primaryPurple.withOpacity(0.04),
                  ],
                )
              : null,
          color: !isSelected
              ? amenity.isActive
                  ? AppTheme.darkCard.withOpacity(0.05)
                  : AppTheme.darkCard.withOpacity(0.02)
              : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlue.withOpacity(0.2)
                : amenity.isActive
                    ? AppTheme.darkBorder.withOpacity(0.1)
                    : AppTheme.darkBorder.withOpacity(0.05),
            width: isSelected ? 1 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getAmenityIcon(amenity),
              size: 14,
              color: amenity.isActive
                  ? isSelected
                      ? AppTheme.primaryBlue.withOpacity(0.8)
                      : AppTheme.textMuted.withOpacity(0.6)
                  : AppTheme.textMuted.withOpacity(0.3),
            ),
            const SizedBox(width: 6),
            Text(
              amenity.name,
              style: AppTextStyles.caption.copyWith(
                color: amenity.isActive
                    ? isSelected
                        ? AppTheme.primaryBlue.withOpacity(0.9)
                        : AppTheme.textWhite.withOpacity(0.8)
                    : AppTheme.textMuted.withOpacity(0.4),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (!amenity.isActive) ...[
              const SizedBox(width: 4),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'أساسيات':
      case 'basics':
        return Icons.check_circle_outline;
      case 'مرافق':
      case 'facilities':
        return Icons.business_outlined;
      case 'خدمات':
      case 'services':
        return Icons.room_service_outlined;
      case 'ترفيه':
      case 'entertainment':
        return Icons.sports_esports_outlined;
      case 'أمان':
      case 'security':
        return Icons.security_outlined;
      case 'مطبخ':
        return Icons.kitchen_outlined;
      case 'أجهزة':
        return Icons.devices_outlined;
      case 'حمام':
        return Icons.bathroom_outlined;
      case 'نوم':
        return Icons.bed_outlined;
      case 'رياضة':
        return Icons.fitness_center_outlined;
      case 'مواصلات':
        return Icons.directions_car_outlined;
      case 'وصول':
        return Icons.accessible_outlined;
      case 'خارجي':
        return Icons.deck_outlined;
      case 'أطفال':
        return Icons.child_care_outlined;
      case 'حيوانات':
        return Icons.pets_outlined;
      case 'عمل':
        return Icons.business_center_outlined;
      case 'ديني':
        return Icons.mosque_outlined;
      default:
        return Icons.category_outlined;
    }
  }
  
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'أساسيات':
      case 'basics':
        return AppTheme.primaryBlue;
      case 'مرافق':
      case 'facilities':
        return AppTheme.primaryCyan;
      case 'خدمات':
      case 'services':
        return AppTheme.primaryPurple;
      case 'ترفيه':
      case 'entertainment':
        return AppTheme.primaryViolet;
      case 'أمان':
      case 'security':
        return AppTheme.success;
      case 'مطبخ':
        return AppTheme.warning;
      case 'رياضة':
        return AppTheme.info;
      default:
        return AppTheme.primaryBlue;
    }
  }

  // دالة محدثة للحصول على أيقونة المرفق من الخادم أو استخدام افتراضية
  IconData _getAmenityIcon(Amenity amenity) {
    // إذا كان للمرفق أيقونة محددة من الخادم
    if (amenity.icon != null && amenity.icon!.isNotEmpty) {
      return _getIconFromName(amenity.icon!);
    }
    
    // وإلا استخدم الأيقونة الافتراضية بناءً على الاسم
    final name = amenity.name.toLowerCase();
    if (name.contains('wifi') || name.contains('واي فاي')) return Icons.wifi;
    if (name.contains('parking') || name.contains('موقف')) return Icons.local_parking;
    if (name.contains('pool') || name.contains('مسبح')) return Icons.pool;
    if (name.contains('gym') || name.contains('جيم')) return Icons.fitness_center;
    if (name.contains('kitchen') || name.contains('مطبخ')) return Icons.kitchen;
    if (name.contains('ac') || name.contains('تكييف')) return Icons.ac_unit;
    if (name.contains('tv') || name.contains('تلفاز')) return Icons.tv;
    if (name.contains('elevator') || name.contains('مصعد')) return Icons.elevator;
    return Icons.check_circle_outline;
  }

  // دالة لتحويل اسم الأيقونة من السلسلة النصية إلى IconData
  IconData _getIconFromName(String iconName) {
    // خريطة شاملة لتحويل أسماء الأيقونات إلى Material Icons
    final iconMap = <String, IconData>{
      // أساسيات
      'wifi': Icons.wifi,
      'network_wifi': Icons.network_wifi,
      'signal_wifi_4_bar': Icons.signal_wifi_4_bar,
      'router': Icons.router,
      'ac_unit': Icons.ac_unit,
      'thermostat': Icons.thermostat,
      'air': Icons.air,
      'water_drop': Icons.water_drop,
      'electric_bolt': Icons.electric_bolt,
      'gas_meter': Icons.gas_meter,
      'heating': Icons.heat_pump,
      'light': Icons.light,
      
      // مطبخ
      'kitchen': Icons.kitchen,
      'microwave': Icons.microwave,
      'coffee_maker': Icons.coffee_maker,
      'blender': Icons.blender_outlined,
      'dining_room': Icons.dining,
      'restaurant': Icons.restaurant,
      'local_cafe': Icons.local_cafe,
      'local_bar': Icons.local_bar,
      'breakfast_dining': Icons.breakfast_dining,
      'lunch_dining': Icons.lunch_dining,
      'dinner_dining': Icons.dinner_dining,
      'outdoor_grill': Icons.outdoor_grill,
      'countertops': Icons.countertops,
      
      // أجهزة
      'tv': Icons.tv,
      'desktop_windows': Icons.desktop_windows,
      'laptop': Icons.laptop,
      'phone_android': Icons.phone_android,
      'tablet': Icons.tablet,
      'speaker': Icons.speaker,
      'radio': Icons.radio,
      'videogame_asset': Icons.videogame_asset,
      'local_laundry_service': Icons.local_laundry_service,
      'dry_cleaning': Icons.dry_cleaning,
      'iron': Icons.iron,
      'dishwasher': Icons.kitchen,
      
      // حمام
      'bathroom': Icons.bathroom,
      'bathtub': Icons.bathtub,
      'shower': Icons.shower,
      'soap': Icons.soap,
      'dry': Icons.dry,
      'wash': Icons.wash,
      
      // نوم
      'bed': Icons.bed,
      'king_bed': Icons.king_bed,
      'single_bed': Icons.single_bed,
      'bedroom_parent': Icons.bed,
      'bedroom_child': Icons.child_care,
      'crib': Icons.crib,
      'chair': Icons.chair,
      'chair_alt': Icons.chair_alt,
      'weekend': Icons.weekend,
      'living': Icons.living,
      
      // رياضة
      'pool': Icons.pool,
      'hot_tub': Icons.hot_tub,
      'fitness_center': Icons.fitness_center,
      'sports_tennis': Icons.sports_tennis,
      'sports_soccer': Icons.sports_soccer,
      'sports_basketball': Icons.sports_basketball,
      'sports_volleyball': Icons.sports_volleyball,
      'sports_golf': Icons.sports_golf,
      'sports_handball': Icons.sports_handball,
      'sports_cricket': Icons.sports_cricket,
      'sports_baseball': Icons.sports_baseball,
      'sports_esports': Icons.sports_esports,
      'spa': Icons.spa,
      'sauna': Icons.hot_tub,
      'self_improvement': Icons.self_improvement,
      
      // مواصلات
      'local_parking': Icons.local_parking,
      'garage': Icons.garage,
      'ev_station': Icons.ev_station,
      'local_gas_station': Icons.local_gas_station,
      'car_rental': Icons.car_rental,
      'car_repair': Icons.car_repair,
      'directions_car': Icons.directions_car,
      'directions_bus': Icons.directions_bus,
      'directions_bike': Icons.directions_bike,
      'electric_bike': Icons.electric_bike,
      'electric_scooter': Icons.electric_scooter,
      'moped': Icons.moped,
      
      // وصول
      'elevator': Icons.elevator,
      'stairs': Icons.stairs,
      'escalator': Icons.escalator,
      'escalator_warning': Icons.escalator_warning,
      'accessible': Icons.accessible,
      'wheelchair_pickup': Icons.wheelchair_pickup,
      'elderly': Icons.elderly,
      
      // أمان
      'security': Icons.security,
      'lock': Icons.lock,
      'key': Icons.key,
      'vpn_key': Icons.vpn_key,
      'shield': Icons.shield,
      'admin_panel_settings': Icons.admin_panel_settings,
      'verified_user': Icons.verified_user,
      'safety_check': Icons.safety_check,
      'health_and_safety': Icons.health_and_safety,
      'local_police': Icons.local_police,
      'local_fire_department': Icons.local_fire_department,
      'medical_services': Icons.medical_services,
      'emergency': Icons.emergency,
      'camera_alt': Icons.camera_alt,
      'videocam': Icons.videocam,
      'sensor_door': Icons.sensor_door,
      'sensor_window': Icons.sensor_window,
      'doorbell': Icons.doorbell,
      
      // خدمات
      'cleaning_services': Icons.cleaning_services,
      'room_service': Icons.room_service,
      'luggage': Icons.luggage,
      'shopping_cart': Icons.shopping_cart,
      'local_grocery_store': Icons.local_grocery_store,
      'local_mall': Icons.local_mall,
      'local_pharmacy': Icons.local_pharmacy,
      'local_hospital': Icons.local_hospital,
      'local_atm': Icons.local_atm,
      'local_library': Icons.local_library,
      'local_post_office': Icons.local_post_office,
      'print': Icons.print,
      'mail': Icons.mail,
      
      // خارجي
      'balcony': Icons.balcony,
      'deck': Icons.deck,
      'yard': Icons.yard,
      'grass': Icons.grass,
      'park': Icons.park,
      'forest': Icons.forest,
      'beach_access': Icons.beach_access,
      'water': Icons.water,
      'fence': Icons.fence,
      'roofing': Icons.roofing,
      
      // أطفال
      'child_care': Icons.child_care,
      'child_friendly': Icons.child_friendly,
      'baby_changing_station': Icons.baby_changing_station,
      'toys': Icons.toys,
      'stroller': Icons.stroller,
      
      // حيوانات
      'pets': Icons.pets,
      
      // عمل
      'desk': Icons.desk,
      'meeting_room': Icons.meeting_room,
      'business_center': Icons.business_center,
      'computer': Icons.computer,
      'scanner': Icons.scanner,
      'fax': Icons.fax,
      
      // ديني
      'mosque': Icons.mosque,
    };
    
    return iconMap[iconName] ?? Icons.check_circle_outline;
  }
}