// lib/features/search/presentation/widgets/futuristic_filter_type_card.dart

import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

enum FilterCardType { property, unit }

class FuturisticFilterTypeCard extends StatefulWidget {
  final String id;
  final String name;
  final String icon;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final Duration animationDelay;
  final FilterCardType cardType;

  const FuturisticFilterTypeCard({
    super.key,
    required this.id,
    required this.name,
    required this.icon,
    required this.count,
    required this.isSelected,
    required this.onTap,
    required this.cardType,
    this.animationDelay = Duration.zero,
  });

  @override
  State<FuturisticFilterTypeCard> createState() => 
      _FuturisticFilterTypeCardState();
}

class _FuturisticFilterTypeCardState extends State<FuturisticFilterTypeCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _entranceController;
  late AnimationController _rippleController;
  late AnimationController _rotationController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _entranceAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _rotationAnimation;
  
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutBack,
    );
    
    _rippleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
  }

  void _startAnimations() {
    Future.delayed(widget.animationDelay, () {
      if (mounted) {
        _entranceController.forward();
        if (widget.isSelected) {
          _glowController.repeat(reverse: true);
          _rippleController.repeat(reverse: true);
          _rotationController.repeat();
        }
      }
    });
  }

  @override
  void didUpdateWidget(FuturisticFilterTypeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _glowController.repeat(reverse: true);
        _rippleController.repeat(reverse: true);
        _rotationController.repeat();
      } else {
        _glowController.stop();
        _glowController.reset();
        _rippleController.stop();
        _rippleController.reset();
        _rotationController.stop();
        _rotationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    _entranceController.dispose();
    _rippleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // تصميم مختلف حسب نوع الكارد
    if (widget.cardType == FilterCardType.unit) {
      return _buildModernUnitCard();
    } else {
      return _buildPropertyCard();
    }
  }

  // تصميم محسّن لكروت الوحدات
  Widget _buildModernUnitCard() {
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
          _rippleAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _entranceAnimation.value * 
                   (_isPressed ? _scaleAnimation.value : 1.0),
            child: Opacity(
              opacity: _entranceAnimation.value.clamp(0.0, 1.0),
              child: Container(
                width: 75,
                height: 95,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // خلفية متحركة للكارد المحدد
                    if (widget.isSelected)
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _rippleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _rippleAnimation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      AppTheme.primaryPurple.withOpacity(0.1),
                                      AppTheme.primaryPurple.withOpacity(0.0),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // حاوي الأيقونة
                        _buildUnitIconContainer(),
                        
                        const SizedBox(height: 8),
                        
                        // النص
                        Text(
                          widget.name,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            fontWeight: widget.isSelected 
                                ? FontWeight.w600 
                                : FontWeight.w500,
                            color: widget.isSelected
                                ? AppTheme.primaryPurple
                                : AppTheme.textMuted.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        // شارة العدد
                        if (widget.count > 0) ...[
                          const SizedBox(height: 2),
                          _buildCountBadge(),
                        ],
                      ],
                    ),
                    
                    // مؤشر التحديد المحسّن
                    if (widget.isSelected)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _buildSelectionBadge(),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnitIconContainer() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: 50,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // خلفية متحركة للأيقونة المحددة
              if (widget.isSelected)
                AnimatedBuilder(
                  animation: _rotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: SweepGradient(
                            colors: [
                              AppTheme.primaryPurple.withOpacity(0.0),
                              AppTheme.primaryPurple.withOpacity(0.3),
                              AppTheme.primaryCyan.withOpacity(0.3),
                              AppTheme.primaryPurple.withOpacity(0.0),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    );
                  },
                ),
              
              // الحاوي الرئيسي للأيقونة
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.isSelected
                        ? [
                            AppTheme.primaryPurple.withOpacity(0.15),
                            AppTheme.primaryCyan.withOpacity(0.10),
                          ]
                        : [
                            Colors.white.withOpacity(0.08),
                            Colors.white.withOpacity(0.04),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.isSelected
                        ? AppTheme.primaryPurple.withOpacity(0.3 + _glowAnimation.value * 0.2)
                        : Colors.white.withOpacity(0.1),
                    width: widget.isSelected ? 1.5 : 1,
                  ),
                  boxShadow: widget.isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryPurple.withOpacity(0.2 * _glowAnimation.value),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  _getIconForType(widget.icon),
                  size: 22,
                  color: widget.isSelected
                      ? AppTheme.primaryPurple
                      : AppTheme.textWhite.withOpacity(0.6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: widget.isSelected
            ? LinearGradient(
                colors: [
                  AppTheme.primaryPurple.withOpacity(0.15),
                  AppTheme.primaryCyan.withOpacity(0.10),
                ],
              )
            : null,
        color: !widget.isSelected 
            ? Colors.white.withOpacity(0.05) 
            : null,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.isSelected
              ? AppTheme.primaryPurple.withOpacity(0.2)
              : Colors.white.withOpacity(0.08),
          width: 0.5,
        ),
      ),
      child: Text(
        '${widget.count}',
        style: AppTextStyles.caption.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: widget.isSelected
              ? AppTheme.primaryPurple
              : AppTheme.textMuted.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildSelectionBadge() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryPurple,
                AppTheme.primaryCyan,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryPurple.withOpacity(0.4 + _glowAnimation.value * 0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 10,
          ),
        );
      },
    );
  }

  // التصميم الأصلي للعقارات (محسّن قليلاً)
  Widget _buildPropertyCard() {
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
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _entranceAnimation.value * 
                   (_isPressed ? _scaleAnimation.value : 1.0),
            child: Opacity(
              opacity: _entranceAnimation.value.clamp(0.0, 1.0),
              child: _buildPropertyCardContent(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPropertyCardContent() {
    return Container(
      height: 105,
      child: Stack(
        children: [
          // خلفية مع Glass morphism
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: widget.isSelected ? 25 : 15,
                  sigmaY: widget.isSelected ? 25 : 15,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.isSelected
                          ? [
                              AppTheme.primaryBlue.withOpacity(0.08),
                              AppTheme.primaryCyan.withOpacity(0.05),
                            ]
                          : [
                              Colors.white.withOpacity(0.03),
                              Colors.white.withOpacity(0.01),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.isSelected
                          ? AppTheme.primaryBlue.withOpacity(0.3)
                          : Colors.white.withOpacity(0.08),
                      width: widget.isSelected ? 1.5 : 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // محتوى الكارد
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPropertyIcon(),
                const SizedBox(height: 8),
                Text(
                  widget.name,
                  style: AppTextStyles.caption.copyWith(
                    color: widget.isSelected 
                        ? AppTheme.primaryBlue
                        : AppTheme.textWhite.withOpacity(0.8),
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.count > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? AppTheme.primaryBlue.withOpacity(0.15)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.count}',
                      style: AppTextStyles.caption.copyWith(
                        color: widget.isSelected
                            ? AppTheme.primaryBlue
                            : AppTheme.textMuted.withOpacity(0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // مؤشر التحديد
          if (widget.isSelected)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 16,
                height: 16,
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
                  size: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPropertyIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: widget.isSelected
            ? LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.2),
                  AppTheme.primaryCyan.withOpacity(0.1),
                ],
              )
            : LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.04),
                ],
              ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.isSelected
              ? AppTheme.primaryBlue.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Icon(
        _getIconForType(widget.icon),
        color: widget.isSelected
            ? AppTheme.primaryBlue
            : AppTheme.textWhite.withOpacity(0.7),
        size: 24,
      ),
    );
  }

  IconData _getIconForType(String? iconName) {
    if (iconName == null || iconName.isEmpty) {
      return widget.cardType == FilterCardType.property 
          ? Icons.home_rounded 
          : Icons.bed_rounded;
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
    };
    
    return iconMap[iconName] ?? (widget.cardType == FilterCardType.property 
        ? Icons.home_rounded 
        : Icons.bed_rounded);
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