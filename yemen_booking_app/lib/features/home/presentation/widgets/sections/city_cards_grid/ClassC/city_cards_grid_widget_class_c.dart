// lib/features/home/presentation/widgets/sections/city_cards_grid/city_cards_grid_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:yemen_booking_app/core/theme/app_theme.dart';
import 'package:yemen_booking_app/core/theme/app_text_styles.dart';
import 'package:yemen_booking_app/features/home/data/models/section_item_models.dart';
import 'package:yemen_booking_app/features/home/presentation/widgets/sections/city_cards_grid/ClassC/city_card_class_c.dart';

class CityCardsGridWidgetClassC extends StatefulWidget {
  final List<SectionPropertyItemModel> cities;
  final Function(String)? onItemTap;

  const CityCardsGridWidgetClassC({
    super.key,
    required this.cities,
    this.onItemTap,
  });

  @override
  State<CityCardsGridWidgetClassC> createState() =>
      _CityCardsGridWidgetClassCState();
}

class _CityCardsGridWidgetClassCState extends State<CityCardsGridWidgetClassC>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _floatController;
  late AnimationController _shimmerController;

  final Map<int, AnimationController> _entranceControllers = {};
  final Map<int, AnimationController> _hoverControllers = {};
  final Map<int, bool> _hoveredItems = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _waveController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Initialize controllers for each city
    for (int i = 0; i < math.min(widget.cities.length, 4); i++) {
      _entranceControllers[i] = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );

      _hoverControllers[i] = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );

      _hoveredItems[i] = false;
    }
  }

  void _startAnimations() {
    for (int i = 0; i < _entranceControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _entranceControllers[i]?.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _floatController.dispose();
    _shimmerController.dispose();
    _entranceControllers.forEach((_, controller) => controller.dispose());
    _hoverControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayCities = widget.cities.take(4).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: displayCities.length,
        itemBuilder: (context, index) {
          return _buildCityCard(displayCities[index], index);
        },
      ),
    );
  }

  Widget _buildCityCard(SectionPropertyItemModel city, int index) {
    final entranceAnimation = CurvedAnimation(
      parent: _entranceControllers[index]!,
      curve: Curves.easeOutBack,
    );

    final hoverAnimation = CurvedAnimation(
      parent: _hoverControllers[index]!,
      curve: Curves.easeInOut,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([
        entranceAnimation,
        hoverAnimation,
        _floatController,
      ]),
      builder: (context, child) {
        // Entrance effects
        final entranceScale = 0.8 + (entranceAnimation.value * 0.2);
        final entranceOpacity = entranceAnimation.value.clamp(0.0, 1.0);

        // Hover effects
        final hoverScale = 1.0 + (hoverAnimation.value * 0.05);
        final hoverElevation = hoverAnimation.value;

        // Float animation
        final floatOffset =
            math.sin((_floatController.value + index * 0.3) * math.pi * 2) * 3;

        return Transform.translate(
          offset: Offset(0, index.isEven ? floatOffset : -floatOffset),
          child: Transform.scale(
            scale: entranceScale * hoverScale,
            child: Opacity(
              opacity: entranceOpacity,
              child: _buildGlassMorphicCard(city, index, hoverElevation),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassMorphicCard(
      SectionPropertyItemModel city, int index, double hoverElevation) {
    final isDark = AppTheme.isDark;

    return GestureDetector(
      onTapDown: (_) => _onHoverStart(index),
      onTapUp: (_) => _onHoverEnd(index),
      onTapCancel: () => _onHoverEnd(index),
      onTap: () => _handleCityTap(city),
      child: MouseRegion(
        onEnter: (_) => _onHoverStart(index),
        onExit: (_) => _onHoverEnd(index),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              // Outer glow
              BoxShadow(
                color: AppTheme.primaryCyan.withOpacity(
                  isDark
                      ? 0.15 + (hoverElevation * 0.15)
                      : 0.08 + (hoverElevation * 0.08),
                ),
                blurRadius: 20 + (hoverElevation * 10),
                spreadRadius: 2 + (hoverElevation * 3),
                offset: Offset(0, 4 + (hoverElevation * 4)),
              ),
              // Depth shadow
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 12,
                spreadRadius: -2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: isDark ? 12 : 20,
                sigmaY: isDark ? 12 : 20,
              ),
              child: CityCardClassC(
                city: city,
                index: index,
                isHovered: _hoveredItems[index] ?? false,
                shimmerAnimation: _shimmerController.value,
                onTap: () => _handleCityTap(city),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onHoverStart(int index) {
    setState(() {
      _hoveredItems[index] = true;
    });
    _hoverControllers[index]?.forward();
    HapticFeedback.selectionClick();
  }

  void _onHoverEnd(int index) {
    setState(() {
      _hoveredItems[index] = false;
    });
    _hoverControllers[index]?.reverse();
  }

  void _handleCityTap(SectionPropertyItemModel city) {
    HapticFeedback.mediumImpact();
    widget.onItemTap?.call(city.id);
  }
}
