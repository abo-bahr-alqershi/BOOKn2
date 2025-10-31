import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';

class IconPickerModal extends StatefulWidget {
  final String selectedIcon;
  final Function(String) onSelectIcon;
  final String? iconCategory;

  const IconPickerModal({
    super.key,
    required this.selectedIcon,
    required this.onSelectIcon,
    this.iconCategory,
  });

  @override
  State<IconPickerModal> createState() => _IconPickerModalState();

  static IconData getIconFromString(String iconName) {
    final iconMap = {
      'home': Icons.home_rounded,
      'apartment': Icons.apartment_rounded,
      'villa': Icons.villa_rounded,
      'business': Icons.business_rounded,
      'store': Icons.store_rounded,
      'hotel': Icons.hotel_rounded,
      'house': Icons.house_rounded,
      'cabin': Icons.cabin_rounded,
      'meeting_room': Icons.meeting_room_rounded,
      'stairs': Icons.stairs_rounded,
      'roofing': Icons.roofing_rounded,
      'warehouse': Icons.warehouse_rounded,
      'terrain': Icons.terrain_rounded,
      'grass': Icons.grass_rounded,
      'location_city': Icons.location_city_rounded,
      'cottage': Icons.cottage_rounded,
      'holiday_village': Icons.holiday_village_rounded,
      'gite': Icons.gite_rounded,
      'domain': Icons.domain_rounded,
      'foundation': Icons.foundation_rounded,
      'bed': Icons.bed_rounded,
      'king_bed': Icons.king_bed_rounded,
      'single_bed': Icons.single_bed_rounded,
      'bedroom_parent': Icons.bedroom_parent_rounded,
      'bedroom_child': Icons.bedroom_child_rounded,
      'living_room': Icons.living_rounded,
      'dining_room': Icons.dining_rounded,
      'kitchen': Icons.kitchen_rounded,
      'bathroom': Icons.bathroom_rounded,
      'bathtub': Icons.bathtub_rounded,
      'shower': Icons.shower_rounded,
      'garage': Icons.garage_rounded,
      'balcony': Icons.balcony_rounded,
      'deck': Icons.deck_rounded,
      'yard': Icons.yard_rounded,
      'pool': Icons.pool_rounded,
      'hot_tub': Icons.hot_tub_rounded,
      'fitness_center': Icons.fitness_center_rounded,
      'sports_tennis': Icons.sports_tennis_rounded,
      'sports_soccer': Icons.sports_soccer_rounded,
      'sports_basketball': Icons.sports_basketball_rounded,
      'spa': Icons.spa_rounded,
      'local_parking': Icons.local_parking_rounded,
      'elevator': Icons.elevator_rounded,
      'wifi': Icons.wifi_rounded,
      'ac_unit': Icons.ac_unit_rounded,
      'fireplace': Icons.fireplace_rounded,
      'water_drop': Icons.water_drop_rounded,
      'electric_bolt': Icons.electric_bolt_rounded,
      'cleaning_services': Icons.cleaning_services_rounded,
      'room_service': Icons.room_service_rounded,
      'local_laundry_service': Icons.local_laundry_service_rounded,
      'dry_cleaning': Icons.dry_cleaning_rounded,
      'iron': Icons.iron_rounded,
      'breakfast_dining': Icons.breakfast_dining_rounded,
      'lunch_dining': Icons.lunch_dining_rounded,
      'dinner_dining': Icons.dinner_dining_rounded,
      'restaurant': Icons.restaurant_rounded,
      'local_cafe': Icons.local_cafe_rounded,
      'local_bar': Icons.local_bar_rounded,
      'security': Icons.security_rounded,
      'lock': Icons.lock_rounded,
      'key': Icons.key_rounded,
      'shield': Icons.shield_rounded,
      'verified_user': Icons.verified_user_rounded,
      'safety_check': Icons.safety_check_rounded,
      'emergency': Icons.emergency_rounded,
      'local_police': Icons.local_police_rounded,
      'local_fire_department': Icons.local_fire_department_rounded,
      'medical_services': Icons.medical_services_rounded,
      'location_on': Icons.location_on_rounded,
      'map': Icons.map_rounded,
      'place': Icons.place_rounded,
      'near_me': Icons.near_me_rounded,
      'my_location': Icons.my_location_rounded,
      'directions': Icons.directions_rounded,
      'navigation': Icons.navigation_rounded,
    };
    return iconMap[iconName] ?? Icons.home_rounded;
  }
}

class _IconPickerModalState extends State<IconPickerModal> {
  String _searchQuery = '';
  String _selectedCategory = 'الكل';

  final Map<String, List<Map<String, dynamic>>> _iconCategories = {
    'عقارات': [
      {'name': 'home', 'label': 'منزل'},
      {'name': 'apartment', 'label': 'شقة'},
      {'name': 'villa', 'label': 'فيلا'},
      {'name': 'business', 'label': 'مكتب'},
      {'name': 'store', 'label': 'محل'},
      {'name': 'hotel', 'label': 'فندق'},
      {'name': 'house', 'label': 'بيت'},
      {'name': 'cabin', 'label': 'شاليه'},
      {'name': 'meeting_room', 'label': 'استوديو'},
      {'name': 'stairs', 'label': 'دوبلكس'},
      {'name': 'roofing', 'label': 'بنتهاوس'},
      {'name': 'warehouse', 'label': 'مستودع'},
      {'name': 'terrain', 'label': 'أرض'},
      {'name': 'grass', 'label': 'مزرعة'},
      {'name': 'location_city', 'label': 'مدينة'},
      {'name': 'cottage', 'label': 'كوخ'},
      {'name': 'holiday_village', 'label': 'قرية سياحية'},
      {'name': 'gite', 'label': 'نزل'},
      {'name': 'domain', 'label': 'نطاق'},
      {'name': 'foundation', 'label': 'أساس'},
    ],
    'غرف': [
      {'name': 'bed', 'label': 'سرير'},
      {'name': 'king_bed', 'label': 'سرير كبير'},
      {'name': 'single_bed', 'label': 'سرير مفرد'},
      {'name': 'bedroom_parent', 'label': 'غرفة نوم رئيسية'},
      {'name': 'bedroom_child', 'label': 'غرفة أطفال'},
      {'name': 'living_room', 'label': 'غرفة معيشة'},
      {'name': 'dining_room', 'label': 'غرفة طعام'},
      {'name': 'kitchen', 'label': 'مطبخ'},
      {'name': 'bathroom', 'label': 'حمام'},
      {'name': 'bathtub', 'label': 'حوض استحمام'},
      {'name': 'shower', 'label': 'دش'},
      {'name': 'garage', 'label': 'كراج'},
      {'name': 'balcony', 'label': 'شرفة'},
      {'name': 'deck', 'label': 'سطح'},
      {'name': 'yard', 'label': 'فناء'},
    ],
    'مرافق': [
      {'name': 'pool', 'label': 'مسبح'},
      {'name': 'hot_tub', 'label': 'جاكوزي'},
      {'name': 'fitness_center', 'label': 'صالة رياضية'},
      {'name': 'sports_tennis', 'label': 'ملعب تنس'},
      {'name': 'sports_soccer', 'label': 'ملعب كرة قدم'},
      {'name': 'sports_basketball', 'label': 'ملعب كرة سلة'},
      {'name': 'spa', 'label': 'سبا'},
      {'name': 'local_parking', 'label': 'موقف سيارات'},
      {'name': 'elevator', 'label': 'مصعد'},
      {'name': 'stairs', 'label': 'درج'},
      {'name': 'wifi', 'label': 'واي فاي'},
      {'name': 'ac_unit', 'label': 'تكييف'},
      {'name': 'fireplace', 'label': 'مدفأة'},
      {'name': 'water_drop', 'label': 'ماء'},
      {'name': 'electric_bolt', 'label': 'كهرباء'},
    ],
    'خدمات': [
      {'name': 'cleaning_services', 'label': 'خدمة تنظيف'},
      {'name': 'room_service', 'label': 'خدمة الغرف'},
      {'name': 'local_laundry_service', 'label': 'غسيل'},
      {'name': 'dry_cleaning', 'label': 'تنظيف جاف'},
      {'name': 'iron', 'label': 'كوي'},
      {'name': 'breakfast_dining', 'label': 'إفطار'},
      {'name': 'lunch_dining', 'label': 'غداء'},
      {'name': 'dinner_dining', 'label': 'عشاء'},
      {'name': 'restaurant', 'label': 'مطعم'},
      {'name': 'local_cafe', 'label': 'مقهى'},
      {'name': 'local_bar', 'label': 'بار'},
    ],
    'أمان': [
      {'name': 'security', 'label': 'أمن'},
      {'name': 'lock', 'label': 'قفل'},
      {'name': 'key', 'label': 'مفتاح'},
      {'name': 'shield', 'label': 'درع'},
      {'name': 'verified_user', 'label': 'مستخدم موثق'},
      {'name': 'safety_check', 'label': 'فحص أمان'},
      {'name': 'emergency', 'label': 'طوارئ'},
      {'name': 'local_police', 'label': 'شرطة'},
      {'name': 'local_fire_department', 'label': 'إطفاء'},
      {'name': 'medical_services', 'label': 'خدمات طبية'},
    ],
  };

  List<Map<String, dynamic>> get filteredIcons {
    List<Map<String, dynamic>> icons = [];

    if (_selectedCategory == 'الكل') {
      for (var categoryIcons in _iconCategories.values) {
        icons.addAll(categoryIcons);
      }
    } else {
      icons = _iconCategories[_selectedCategory] ?? [];
    }

    if (_searchQuery.isNotEmpty) {
      icons = icons.where((icon) {
        return icon['label']
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            icon['name'].toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return icons;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmall = size.width < 600;
    final EdgeInsets inset = isSmall
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
        : const EdgeInsets.all(20);
    final double dialogWidth = isSmall ? (size.width - inset.horizontal) : 800;
    final double dialogHeight =
        isSmall ? (size.height * 0.95) : (size.height * 0.85);

    return Dialog(
      insetPadding: const EdgeInsets.all(10),
      backgroundColor: Colors.transparent,
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withOpacity(0.95),
              AppTheme.darkCard.withOpacity(0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                _buildCategoryTabs(),
                Expanded(child: _buildIconGrid()),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.1),
            AppTheme.primaryPurple.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.category_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اختر أيقونة',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'هذه الأيقونات متوافقة مع Material Icons في Flutter',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close_rounded,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
          decoration: InputDecoration(
            hintText: 'ابحث عن أيقونة...',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted.withOpacity(0.5),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppTheme.textMuted.withOpacity(0.5),
            ),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = ['الكل', ..._iconCategories.keys];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedCategory = category);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.primaryGradient : null,
                  color:
                      isSelected ? null : AppTheme.darkSurface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryBlue.withOpacity(0.5)
                        : AppTheme.darkBorder.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    category,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected ? Colors.white : AppTheme.textMuted,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIconGrid() {
    final icons = filteredIcons;
    final width = MediaQuery.of(context).size.width;
    int columns;
    if (width < 380) {
      columns = 3;
    } else if (width < 600) {
      columns = 4;
    } else if (width < 900) {
      columns = 5;
    } else {
      columns = 6;
    }

    if (icons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppTheme.textMuted.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد أيقونات مطابقة للبحث',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final icon = icons[index];
        final isSelected = widget.selectedIcon == icon['name'];

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onSelectIcon(icon['name']);
            Navigator.pop(context);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? AppTheme.primaryGradient
                  : LinearGradient(
                      colors: [
                        AppTheme.darkCard.withOpacity(0.5),
                        AppTheme.darkCard.withOpacity(0.3),
                      ],
                    ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryBlue.withOpacity(0.5)
                    : AppTheme.darkBorder.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cellH = constraints.maxHeight;
                final double iconSize = cellH < 90 ? 24 : 32;
                final double gap = cellH < 90 ? 6 : 8;
                final double labelFont = cellH < 90 ? 9 : 10;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      IconPickerModal.getIconFromString(icon['name']),
                      size: iconSize,
                      color: isSelected ? Colors.white : AppTheme.primaryBlue,
                    ),
                    SizedBox(height: gap),
                    Text(
                      icon['label'],
                      style: AppTextStyles.caption.copyWith(
                        color: isSelected ? Colors.white : AppTheme.textMuted,
                        fontSize: labelFont,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  IconPickerModal.getIconFromString(widget.selectedIcon),
                  size: 20,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  'الأيقونة المختارة: ${widget.selectedIcon}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            'استخدم Icons.${widget.selectedIcon} في Flutter',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
