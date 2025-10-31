// lib/features/home/presentation/widgets/sections/base_section_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yemen_booking_app/features/home/presentation/widgets/section_empty_widget.dart';
import 'package:yemen_booking_app/features/home/presentation/widgets/section_header_widget.dart';
import 'package:yemen_booking_app/features/home/presentation/widgets/section_loading_widget.dart';
import 'package:yemen_booking_app/features/home/presentation/widgets/section_visibility_detector.dart';
// Removed imports for non-existent ClassC and ClassD widgets
import 'package:yemen_booking_app/features/home/presentation/widgets/sections/holographic_single_property_ad_widget.dart';
import 'package:yemen_booking_app/features/home/presentation/widgets/sections/black_hole_gravity_grid.dart';
import 'package:yemen_booking_app/features/home/presentation/widgets/sections/cosmic_single_property_offer_widget.dart';
import 'package:yemen_booking_app/features/home/presentation/widgets/sections/dna_helix_property_carousel.dart';
import 'package:yemen_booking_app/features/home/presentation/widgets/sections/holographic_horizontal_property_list_widget.dart';
import 'package:yemen_booking_app/features/home/presentation/widgets/sections/liquid_crystal_property_list.dart';
import 'package:yemen_booking_app/features/home/presentation/widgets/sections/neuro_morphic_property_grid.dart';
import 'package:yemen_booking_app/features/home/presentation/widgets/sections/premium_carousel_widget.dart';
import 'package:yemen_booking_app/features/home/presentation/widgets/sections/quantum_flash_deals_section_widget.dart';
import 'package:yemen_booking_app/features/home/presentation/widgets/sections/vertical_property_grid_widget.dart';
import 'package:yemen_booking_app/features/home/presentation/widgets/sections/aurora_quantum_portal_matrix.dart';
import 'package:yemen_booking_app/features/home/presentation/widgets/sections/crystal_constellation_network.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/enums/section_type_enum.dart';
import '../../../../../core/models/paginated_result.dart';
import '../../../domain/entities/section.dart';
// Removed imports for non-existent offer and city card widgets
import 'package:yemen_booking_app/features/home/data/models/section_item_models.dart';

class BaseSectionWidget extends StatefulWidget {
  final Section section;
  final PaginatedResult<dynamic>? data;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;
  final Function(String)? onItemTap;
  final VoidCallback? onViewAll;

  const BaseSectionWidget({
    super.key,
    required this.section,
    this.data,
    this.isLoadingMore = false,
    this.onLoadMore,
    this.onItemTap,
    this.onViewAll,
  });

  @override
  State<BaseSectionWidget> createState() => _BaseSectionWidgetState();
}

class _BaseSectionWidgetState extends State<BaseSectionWidget>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _shimmerController;
  late AnimationController _glowController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  bool _isVisible = false;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
    ));
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _shimmerController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(bool isVisible) {
    if (isVisible && !_hasAnimated) {
      setState(() {
        _isVisible = true;
        _hasAnimated = true;
      });
      _entranceController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't render inactive sections
    if (!widget.section.isActive) {
      return const SizedBox.shrink();
    }

    return SectionVisibilityDetector(
      sectionId: widget.section.id,
      onVisibilityChanged: _onVisibilityChanged,
      child: AnimatedBuilder(
        animation: _entranceController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header
                      // if (_shouldShowHeader())
                      //   Padding(
                      //     padding: const EdgeInsets.symmetric(horizontal: 20),
                      //     child: SectionHeaderWidget(
                      //       title: _getSectionTitle(),
                      //       subtitle: _getSectionSubtitle(),
                      //       icon: _getSectionIcon(),
                      //       gradientColors: _getSectionGradient(),
                      //       onViewAll:
                      //           widget.onViewAll ?? () => _handleViewAll(),
                      //       isGlowing: _isSpecialSection(),
                      //     ),
                      //   ),

                      const SizedBox(height: 16),

                      // Section Content
                      _buildSectionContent(),

                      // Load More Indicator
                      if (widget.isLoadingMore) _buildLoadMoreIndicator(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionContent() {
    // Check for loading state
    if (widget.data == null) {
      return const SectionLoadingWidget();
    }

    // Check for empty state
    if (widget.data!.items.isEmpty) {
      return SectionEmptyWidget(
        message: _getEmptyMessage(),
        icon: _getSectionIcon(),
      );
    }

    // Build content based on section type
    return _buildContentByType();
  }

  Widget _buildContentByType() {
    final t = widget.section.uiType;
    switch (t) {
      // Ad Sections
      case SectionType.singlePropertyAd:
        return HolographicSinglePropertyAdWidget(
          sectionId: widget.section.id,
          data: widget.data as PaginatedResult<SectionPropertyItemModel>?,
          onItemTap: widget.onItemTap,
        );

      case SectionType.multiPropertyAd:
        return BlackHoleGravityGrid(
          items: widget.data!.items,
          onItemTap: widget.onItemTap,
        );

      // Offer Sections
      case SectionType.singlePropertyOffer:
        if (widget.data!.items.isNotEmpty) {
          return CosmicSinglePropertyOfferWidget(
            item: widget.data!.items.first,
            onTap: () => widget.onItemTap?.call(
                (widget.data!.items.first is SectionPropertyItemModel)
                    ? (widget.data!.items.first as SectionPropertyItemModel).id
                    : (widget.data!.items.first as SectionUnitItemModel).id),
          );
        }
        return const SizedBox.shrink();

      case SectionType.offersCarousel:
        return DnaHelixPropertyCarousel(
          items: widget.data!.items,
          onItemTap: widget.onItemTap,
        );

      case SectionType.flashDeals:
        return QuantumFlashDealsSectionWidget(
          items: widget.data!.items,
          onItemTap: widget.onItemTap,
        );

      // Property Sections
      case SectionType.horizontalPropertyList:
        return HolographicHorizontalPropertyListWidget(
          items: widget.data!.items,
          onItemTap: widget.onItemTap,
        );

      case SectionType.verticalPropertyGrid:
        return VerticalPropertyGridWidget(
          items: widget.data!.items,
          onItemTap: widget.onItemTap,
        );

      // Destination Sections
      case SectionType.cityCardsGrid:
        return NeuroMorphicPropertyGrid(
          items: widget.data!.items,
          onItemTap: widget.onItemTap,
        );

      // Premium Sections
      case SectionType.premiumCarousel:
        return PremiumCarouselWidget(
          items: widget.data!.items,
          onItemTap: widget.onItemTap,
        );

      // Custom Display Types
      case SectionType.blackHoleGravityGrid:
        return BlackHoleGravityGrid(
          items: widget.data!.items,
          onItemTap:
              widget.onItemTap != null ? (id) => widget.onItemTap!(id) : null,
        );

      case SectionType.cosmicSinglePropertyOffer:
        if (widget.data!.items.isNotEmpty) {
          return CosmicSinglePropertyOfferWidget(
            item: widget.data!.items.first,
            onTap: () => widget.onItemTap?.call(
                (widget.data!.items.first is SectionPropertyItemModel)
                    ? (widget.data!.items.first as SectionPropertyItemModel).id
                    : (widget.data!.items.first as SectionUnitItemModel).id),
          );
        }
        return const SizedBox.shrink();

      case SectionType.dnaHelixPropertyCarousel:
        return DnaHelixPropertyCarousel(
          items: widget.data!.items,
          onItemTap: widget.onItemTap,
        );

      case SectionType.holographicHorizontalPropertyList:
        return HolographicHorizontalPropertyListWidget(
          items: widget.data!.items,
          onItemTap: widget.onItemTap,
        );

      case SectionType.holographicSinglePropertyAd:
        return HolographicSinglePropertyAdWidget(
          sectionId: widget.section.id,
          data: widget.data as PaginatedResult<SectionPropertyItemModel>?,
          onItemTap: widget.onItemTap,
        );

      case SectionType.liquidCrystalPropertyList:
        return LiquidCrystalPropertyList(
          items: widget.data!.items,
          onItemTap: widget.onItemTap,
        );

      case SectionType.neuroMorphicPropertyGrid:
        return NeuroMorphicPropertyGrid(
          items: widget.data!.items,
          onItemTap: widget.onItemTap,
        );

      case SectionType.quantumFlashDeals:
        return QuantumFlashDealsSectionWidget(
          items: widget.data!.items,
          onItemTap: widget.onItemTap,
        );

      case SectionType.auroraQuantumPortalMatrix:
        return AuroraQuantumPortalMatrix(
          items: widget.data!.items,
          onItemTap: widget.onItemTap,
        );

      case SectionType.crystalConstellationNetwork:
        return CrystalConstellationNetwork(
          items: widget.data!.items,
          onItemTap: widget.onItemTap,
        );

      default:
        return HolographicHorizontalPropertyListWidget(
          items: widget.data!.items,
          onItemTap: widget.onItemTap,
        );
    }
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.3),
                  AppTheme.primaryBlue.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(
                    0.3 + (_shimmerController.value * 0.2),
                  ),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              strokeWidth: 2,
            ),
          );
        },
      ),
    );
  }

  bool _shouldShowHeader() {
    // Some sections might not need headers
    return true;
  }

  String _getSectionTitle() {
    // Prefer backend-provided title
    if ((widget.section.title ?? '').trim().isNotEmpty) {
      return widget.section.title!.trim();
    }
    // Fallback: localized title based on uiType
    switch (widget.section.uiType) {
      case SectionType.singlePropertyAd:
        return 'عرض مميز';
      case SectionType.multiPropertyAd:
        return 'إعلانات مميزة';
      case SectionType.singlePropertyOffer:
        return 'عرض خاص';
      case SectionType.offersCarousel:
        return 'عروض حصرية';
      case SectionType.flashDeals:
        return 'عروض سريعة';
      case SectionType.horizontalPropertyList:
        return 'عقارات مميزة';
      case SectionType.verticalPropertyGrid:
        return 'استكشف العقارات';
      case SectionType.premiumCarousel:
        return 'الباقة المميزة';
      case SectionType.interactiveShowcase:
        return 'استكشف';
      case SectionType.blackHoleGravityGrid:
        return 'عروض الثقب الأسود';
      case SectionType.cosmicSinglePropertyOffer:
        return 'العرض الكوني';
      case SectionType.dnaHelixPropertyCarousel:
        return 'عرض الحلزون المزدوج';
      case SectionType.holographicHorizontalPropertyList:
        return 'قائمة ثلاثية الأبعاد';
      case SectionType.holographicSinglePropertyAd:
        return 'إعلان هولوجرامي';
      case SectionType.liquidCrystalPropertyList:
        return 'عرض الكريستال السائل';
      case SectionType.neuroMorphicPropertyGrid:
        return 'الشبكة العصبية';
      case SectionType.quantumFlashDeals:
        return 'عروض كمية سريعة';
      case SectionType.auroraQuantumPortalMatrix:
        return 'بوابة الشفق الكمومي';
      case SectionType.crystalConstellationNetwork:
        return 'شبكة الأبراج البلورية';
      default:
        return 'استكشف';
    }
  }

  String? _getSectionSubtitle() {
    // Prefer backend-provided subtitle
    if ((widget.section.subtitle ?? '').trim().isNotEmpty) {
      return widget.section.subtitle!.trim();
    }
    switch (widget.section.uiType) {
      case SectionType.flashDeals:
        return 'عروض محدودة المدة';
      case SectionType.premiumCarousel:
        return 'أفخم العقارات';
      default:
        return null;
    }
  }

  IconData _getSectionIcon() {
    switch (widget.section.uiType) {
      case SectionType.singlePropertyAd:
      case SectionType.multiPropertyAd:
        return Icons.campaign;
      case SectionType.singlePropertyOffer:
      case SectionType.offersCarousel:
      case SectionType.flashDeals:
        return Icons.local_offer;
      case SectionType.horizontalPropertyList:
      case SectionType.verticalPropertyGrid:
        return Icons.home_work;
      case SectionType.premiumCarousel:
        return Icons.workspace_premium;
      case SectionType.interactiveShowcase:
        return Icons.widgets;
      case SectionType.blackHoleGravityGrid:
        return Icons.blur_circular;
      case SectionType.cosmicSinglePropertyOffer:
        return Icons.star_purple500;
      case SectionType.dnaHelixPropertyCarousel:
        return Icons.biotech;
      case SectionType.holographicHorizontalPropertyList:
        return Icons.view_in_ar;
      case SectionType.holographicSinglePropertyAd:
        return Icons.view_in_ar;
      case SectionType.liquidCrystalPropertyList:
        return Icons.water_drop;
      case SectionType.neuroMorphicPropertyGrid:
        return Icons.psychology;
      case SectionType.quantumFlashDeals:
        return Icons.flash_on;
      case SectionType.auroraQuantumPortalMatrix:
        return Icons.auto_awesome;
      case SectionType.crystalConstellationNetwork:
        return Icons.diamond;
      default:
        return Icons.widgets;
    }
  }

  List<Color> _getSectionGradient() {
    switch (widget.section.uiType) {
      case SectionType.flashDeals:
        return [AppTheme.error, AppTheme.warning];
      case SectionType.premiumCarousel:
        return [AppTheme.warning, const Color(0xFFFFD700)];
      case SectionType.offersCarousel:
        return [AppTheme.success, AppTheme.primaryCyan];
      default:
        return [AppTheme.primaryBlue, AppTheme.primaryPurple];
    }
  }

  bool _isSpecialSection() {
    return widget.section.uiType == SectionType.flashDeals ||
        widget.section.uiType == SectionType.premiumCarousel;
  }

  String _getEmptyMessage() {
    switch (widget.section.uiType) {
      case SectionType.flashDeals:
        return 'لا توجد عروض سريعة حالياً';
      case SectionType.offersCarousel:
        return 'لا توجد عروض متاحة';
      default:
        return 'لا توجد عناصر للعرض';
    }
  }

  void _handleViewAll() {
    HapticFeedback.lightImpact();
    // Navigate to section details or filtered results
  }
}
