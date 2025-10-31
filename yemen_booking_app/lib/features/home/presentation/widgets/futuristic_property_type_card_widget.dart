// lib/features/home/presentation/widgets/categories/ultra_futuristic_property_type_card.dart

import 'package:flutter/material.dart';
import 'package:yemen_booking_app/features/home/domain/entities/property_type.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_text_styles.dart';

class FuturisticPropertyTypeCard extends StatefulWidget {
  final PropertyType propertyType;
  final bool isSelected;
  final VoidCallback onTap;
  final Duration animationDelay;
  final bool isCompact;

  const FuturisticPropertyTypeCard({
    super.key,
    required this.propertyType,
    required this.isSelected,
    required this.onTap,
    this.animationDelay = Duration.zero,
    this.isCompact = false,
  });

  @override
  State<FuturisticPropertyTypeCard> createState() =>
      _FuturisticPropertyTypeCardState();
}

class _FuturisticPropertyTypeCardState extends State<FuturisticPropertyTypeCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _entranceController;
  late AnimationController _orbController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _entranceAnimation;
  late Animation<double> _orbAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _orbController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.93,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.elasticOut,
    );

    _orbAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _orbController,
      curve: Curves.linear,
    ));
  }

  void _startAnimations() {
    Future.delayed(widget.animationDelay, () {
      if (mounted) {
        _entranceController.forward();
        if (widget.isSelected) {
          _glowController.repeat(reverse: true);
          _orbController.repeat();
        }
      }
    });
  }

  @override
  void didUpdateWidget(FuturisticPropertyTypeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _glowController.repeat(reverse: true);
        _orbController.repeat();
      } else {
        _glowController.stop();
        _glowController.reset();
        _orbController.stop();
        _orbController.reset();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    _entranceController.dispose();
    _orbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // تحديد الوضع الحالي (فاتح أم مظلم)
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _onTapDown(),
      onTapUp: (_) => _onTapUp(),
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleAnimation,
          _glowAnimation,
          _entranceAnimation,
          _orbAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _entranceAnimation.value *
                (_isPressed ? _scaleAnimation.value : 1.0),
            child: Opacity(
              opacity: _entranceAnimation.value.clamp(0.0, 1.0),
              child: _buildUltraCard(isDarkMode),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUltraCard(bool isDarkMode) {
    return SizedBox(
      height: widget.isCompact ? 95 : 105,
      child: Stack(
        children: [
          // خلفية زجاجية شفافة Glass Morphism
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.isCompact ? 14 : 16),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: widget.isSelected ? 30 : 20,
                  sigmaY: widget.isSelected ? 30 : 20,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.isSelected
                          ? [
                              // ألوان للكارد المحدد
                              AppTheme.primaryBlue
                                  .withOpacity(isDarkMode ? 0.08 : 0.15),
                              AppTheme.primaryPurple
                                  .withOpacity(isDarkMode ? 0.05 : 0.10),
                            ]
                          : [
                              // شفافية زجاجية للكارد العادي
                              isDarkMode
                                  ? Colors.white.withOpacity(0.03)
                                  : Colors.white.withOpacity(
                                      0.70), // شفافية 70% للوضع الفاتح
                              isDarkMode
                                  ? Colors.white.withOpacity(0.01)
                                  : Colors.white.withOpacity(
                                      0.50), // شفافية 50% للوضع الفاتح
                            ],
                    ),
                    borderRadius:
                        BorderRadius.circular(widget.isCompact ? 14 : 16),
                    border: Border.all(
                      color: widget.isSelected
                          ? AppTheme.primaryBlue
                              .withOpacity(0.3 + _glowAnimation.value * 0.2)
                          : isDarkMode
                              ? Colors.white.withOpacity(0.08)
                              : Colors.white.withOpacity(
                                  0.50), // حدود بيضاء شفافة للوضع الفاتح
                      width: widget.isSelected ? 1.5 : 1,
                    ),
                    boxShadow: [
                      // ظلال ناعمة
                      BoxShadow(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.3)
                            : Colors.black.withOpacity(0.08),
                        blurRadius: isDarkMode ? 20 : 15,
                        offset: const Offset(0, 4),
                      ),
                      // توهج داخلي للوضع الفاتح
                      if (!isDarkMode)
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(-2, -2),
                          spreadRadius: -5,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // طبقة إضافية للشفافية في الوضع الفاتح
          if (!isDarkMode)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(widget.isCompact ? 14 : 16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

          // محتوى الكارد
          Positioned.fill(
            child: _buildCardContent(isDarkMode),
          ),

          // تأثير التوهج للكارد المحدد
          if (widget.isSelected)
            Positioned.fill(
              child: _buildGlowEffect(isDarkMode),
            ),

          // مؤشر التحديد
          if (widget.isSelected)
            Positioned(
              top: 6,
              right: 6,
              child: _buildSelectionIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildCardContent(bool isDarkMode) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // الأيقونة
        _buildIconSection(isDarkMode),

        const SizedBox(height: 6),

        // الاسم مع خلفية شفافة للوضع الفاتح
        Container(
          padding: isDarkMode
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: !isDarkMode
              ? BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                )
              : null,
          child: Text(
            widget.propertyType.name,
            style: AppTextStyles.caption.copyWith(
              color: widget.isSelected
                  ? AppTheme.primaryBlue
                  : isDarkMode
                      ? AppTheme.textWhite.withOpacity(0.8)
                      : AppTheme.textDark
                          .withOpacity(0.85), // نص داكن للوضع الفاتح
              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: widget.isCompact ? 11 : 12,
              shadows: !isDarkMode
                  ? [
                      Shadow(
                        color: Colors.white.withOpacity(0.6),
                        offset: const Offset(0.5, 0.5),
                        blurRadius: 1,
                      ),
                    ]
                  : null,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // العدد
        if (!widget.isCompact && widget.propertyType.propertiesCount > 0)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppTheme.primaryBlue.withOpacity(0.15)
                  : isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white.withOpacity(0.40), // خلفية شفافة للعدد
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.isSelected
                    ? AppTheme.primaryBlue.withOpacity(0.3)
                    : isDarkMode
                        ? Colors.transparent
                        : Colors.white.withOpacity(0.5),
                width: 0.5,
              ),
            ),
            child: Text(
              '${widget.propertyType.propertiesCount}',
              style: AppTextStyles.caption.copyWith(
                color: widget.isSelected
                    ? AppTheme.primaryBlue
                    : isDarkMode
                        ? AppTheme.textMuted.withOpacity(0.6)
                        : AppTheme.textDark
                            .withOpacity(0.7), // نص واضح للوضع الفاتح
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildIconSection(bool isDarkMode) {
    return SizedBox(
      width: widget.isCompact ? 38 : 42,
      height: widget.isCompact ? 38 : 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // حلقة دوارة للأيقونة المحددة
          if (widget.isSelected)
            AnimatedBuilder(
              animation: _orbAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _orbAnimation.value,
                  child: Container(
                    width: widget.isCompact ? 38 : 42,
                    height: widget.isCompact ? 38 : 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryBlue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                );
              },
            ),

          // خلفية الأيقونة بشفافية زجاجية
          Container(
            width: widget.isCompact ? 32 : 36,
            height: widget.isCompact ? 32 : 36,
            decoration: BoxDecoration(
              gradient: widget.isSelected
                  ? LinearGradient(
                      colors: [
                        AppTheme.primaryBlue
                            .withOpacity(isDarkMode ? 0.3 : 0.7),
                        AppTheme.primaryPurple
                            .withOpacity(isDarkMode ? 0.2 : 0.5),
                      ],
                    )
                  : LinearGradient(
                      colors: isDarkMode
                          ? [
                              Colors.white.withOpacity(0.08),
                              Colors.white.withOpacity(0.04),
                            ]
                          : [
                              Colors.white.withOpacity(0.40), // شفافية للخلفية
                              Colors.white.withOpacity(0.20),
                            ],
                    ),
              borderRadius: BorderRadius.circular(widget.isCompact ? 10 : 12),
              border: Border.all(
                color: widget.isSelected
                    ? AppTheme.primaryBlue.withOpacity(isDarkMode ? 0.3 : 0.4)
                    : isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.white.withOpacity(0.5),
                width: 0.5,
              ),
              boxShadow: !isDarkMode
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              _getIconForType(widget.propertyType.icon),
              color: widget.isSelected
                  ? Colors.white
                  : isDarkMode
                      ? AppTheme.textWhite.withOpacity(0.7)
                      : AppTheme.textDark
                          .withOpacity(0.65), // أيقونة واضحة للوضع الفاتح
              size: widget.isCompact ? 18 : 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowEffect(bool isDarkMode) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.isCompact ? 14 : 16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(
                isDarkMode
                    ? (0.15 + _glowAnimation.value * 0.15)
                    : (0.25 + _glowAnimation.value * 0.20),
              ),
              blurRadius: 20 + _glowAnimation.value * 10,
              spreadRadius: -5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionIndicator() {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.5),
            blurRadius: 6,
          ),
        ],
      ),
      child: const Icon(
        Icons.check,
        color: Colors.white,
        size: 8,
      ),
    );
  }

  // دالة محدثة للحصول على الأيقونة الديناميكية
  IconData _getIconForType(String? iconName) {
    if (iconName == null || iconName.isEmpty) {
      return Icons.home_rounded;
    }

    // قائمة الأيقونات المتوافقة مع Material Icons
    final iconMap = <String, IconData>{
      // أيقونات العقارات
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

      // أيقونات الغرف
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

      // أيقونات المرافق
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

      // أيقونات الخدمات
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

      // أيقونات الأمان
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

      // أيقونات المواقع
      'location_on': Icons.location_on_rounded,
      'map': Icons.map_rounded,
      'place': Icons.place_rounded,
      'near_me': Icons.near_me_rounded,
      'my_location': Icons.my_location_rounded,
      'directions': Icons.directions_rounded,
      'navigation': Icons.navigation_rounded,

      // أيقونات المواصلات
      'directions_car': Icons.directions_car_rounded,
      'directions_bus': Icons.directions_bus_rounded,
      'directions_subway': Icons.directions_subway_rounded,
      'directions_train': Icons.directions_train_rounded,
      'directions_boat': Icons.directions_boat_rounded,
      'flight': Icons.flight_rounded,
      'directions_walk': Icons.directions_walk_rounded,
      'directions_bike': Icons.directions_bike_rounded,

      // أيقونات عامة
      'star': Icons.star_rounded,
      'favorite': Icons.favorite_rounded,
      'bookmark': Icons.bookmark_rounded,
      'share': Icons.share_rounded,
      'info': Icons.info_rounded,
      'help': Icons.help_rounded,
      'settings': Icons.settings_rounded,
      'phone': Icons.phone_rounded,
      'email': Icons.email_rounded,
      'message': Icons.message_rounded,
      'notifications': Icons.notifications_rounded,
    };

    return iconMap[iconName] ?? Icons.home_rounded;
  }

  void _onTapDown() {
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _onTapUp() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }
}
