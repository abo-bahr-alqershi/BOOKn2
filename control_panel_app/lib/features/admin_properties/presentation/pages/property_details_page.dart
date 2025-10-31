// lib/features/admin_properties/presentation/pages/property_details_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/properties/properties_bloc.dart';
import '../../domain/entities/property.dart';
import '../widgets/property_image_gallery.dart';
import '../widgets/property_map_view.dart';
import '../widgets/property_info_card.dart';
import '../widgets/property_amenities_grid.dart';
import '../widgets/property_policies_list.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../bloc/property_images/property_images_bloc.dart';
import '../bloc/property_images/property_images_state.dart';
import '../bloc/property_images/property_images_event.dart';
import 'package:bookn_cp_app/injection_container.dart' as di;

class PropertyDetailsPage extends StatefulWidget {
  final String propertyId;

  const PropertyDetailsPage({
    super.key,
    required this.propertyId,
  });

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });

    // Load property details
    context.read<PropertiesBloc>().add(
          LoadPropertyDetailsEvent(
            propertyId: widget.propertyId,
            includeUnits: true,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PropertyImagesBloc>(
      create: (_) => di.sl<PropertyImagesBloc>()
        ..add(LoadPropertyImagesEvent(propertyId: widget.propertyId)),
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: BlocBuilder<PropertiesBloc, PropertiesState>(
          builder: (context, state) {
            if (state is PropertyDetailsLoading) {
              return _buildLoadingState();
            }

            if (state is PropertyDetailsError) {
              return _buildErrorState(state.message);
            }

            if (state is PropertyDetailsLoaded) {
              return _buildLoadedState(state.property);
            }

            return _buildEmptyState();
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Elegant loading animation
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const CupertinoActivityIndicator(
              color: Colors.white,
              radius: 12,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'جاري تحميل التفاصيل...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.error.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                CupertinoIcons.exclamationmark_triangle,
                color: AppTheme.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'حدث خطأ',
              style: AppTextStyles.heading3.copyWith(
                color: AppTheme.textWhite,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildRetryButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.building_2_fill,
            color: AppTheme.textMuted.withValues(alpha: 0.3),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد بيانات',
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState(Property property) {
    return Stack(
      children: [
        // Main Content
        CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Hero Header
            _buildHeroHeader(property),

            // Property Info
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _animationController,
                child: _buildPropertyContent(property),
              ),
            ),
          ],
        ),

        // Floating Actions
        if (!property.isApproved) _buildFloatingActions(property),
      ],
    );
  }

  Widget _buildHeroHeader(Property property) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: AppTheme.darkCard.withValues(alpha: 0.95),
      leading: _buildBackButton(),
      actions: [_buildEditButton()],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Property Image with Parallax (prefers loaded gallery images if available)
            BlocBuilder<PropertyImagesBloc, PropertyImagesState>(
              builder: (context, imgState) {
                String? heroUrl;
                if (property.images.isNotEmpty) {
                  final img = property.images.first;
                  heroUrl = (img.thumbnails.hd.isNotEmpty
                          ? img.thumbnails.hd
                          : img.thumbnails.large.isNotEmpty
                              ? img.thumbnails.large
                              : img.url)
                      .toString();
                } else if (imgState is PropertyImagesLoaded &&
                    imgState.images.isNotEmpty) {
                  final img = imgState.images.first;
                  heroUrl = (img.thumbnails.hd.isNotEmpty
                          ? img.thumbnails.hd
                          : img.thumbnails.large.isNotEmpty
                              ? img.thumbnails.large
                              : img.url)
                      .toString();
                }
                if (heroUrl != null && heroUrl.isNotEmpty) {
                  return CachedImageWidget(
                    imageUrl: heroUrl,
                    fit: BoxFit.cover,
                  );
                }
                return _buildImagePlaceholder();
              },
            ),

            // Gradient Overlay
            _buildGradientOverlay(),

            // Property Info Overlay
            _buildHeaderInfo(property),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          context.pop();
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.darkCard.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.darkBorder.withValues(alpha: 0.2),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: const Icon(
                CupertinoIcons.chevron_forward,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditButton() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push('/admin/properties/${widget.propertyId}/edit');
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(8),
          child: const Icon(
            CupertinoIcons.pencil,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.3),
            AppTheme.primaryPurple.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          CupertinoIcons.photo,
          size: 48,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppTheme.darkBackground.withValues(alpha: 0.4),
            AppTheme.darkBackground.withValues(alpha: 0.9),
            AppTheme.darkBackground,
          ],
          stops: const [0.2, 0.5, 0.8, 1.0],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(Property property) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Property Name
          Text(
            property.name,
            style: AppTextStyles.heading1.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Location & Rating Row
          Row(
            children: [
              Icon(
                CupertinoIcons.location_solid,
                size: 14,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  property.formattedAddress,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              _buildRatingBadge(property.starRating),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBadge(int rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.star_fill,
            size: 14,
            color: AppTheme.warning,
          ),
          const SizedBox(width: 4),
          Text(
            rating.toString(),
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyContent(Property property) {
    return Column(
      children: [
        // Status & Info Cards
        _buildInfoSection(property),

        // Stats Section
        if (property.stats != null) _buildStatsSection(property.stats!),

        // Tabs Section
        _buildTabsSection(property),

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildInfoSection(Property property) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Status Card
          PropertyInfoCard(
            property: property,
            onOwnerTap: () {
              // Navigate to owner profile
            },
          ),

          const SizedBox(height: 16),

          // Description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.darkCard.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.darkBorder.withValues(alpha: 0.2),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.doc_text,
                          size: 16,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'الوصف',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppTheme.textWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      property.description,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.textLight,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(PropertyStats stats) {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildStatCard(
            icon: CupertinoIcons.calendar,
            label: 'الحجوزات',
            value: stats.totalBookings.toString(),
            gradient: [AppTheme.primaryBlue, AppTheme.primaryCyan],
          ),
          _buildStatCard(
            icon: CupertinoIcons.star_fill,
            label: 'التقييم',
            value: stats.averageRating.toStringAsFixed(1),
            gradient: [AppTheme.warning, AppTheme.neonPurple],
          ),
          _buildStatCard(
            icon: CupertinoIcons.chart_pie_fill,
            label: 'الإشغال',
            value: '${stats.occupancyRate.toInt()}%',
            gradient: [AppTheme.success, AppTheme.neonGreen],
          ),
          _buildStatCard(
            icon: CupertinoIcons.money_dollar_circle_fill,
            label: 'الإيرادات',
            value: '\$${(stats.monthlyRevenue / 1000).toStringAsFixed(0)}k',
            gradient: [AppTheme.primaryPurple, AppTheme.primaryViolet],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required List<Color> gradient,
  }) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient.map((c) => c.withValues(alpha: 0.1)).toList(),
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gradient.first.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: gradient.first, size: 20),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabsSection(Property property) {
    final tabs = [
      _TabItem(
        icon: CupertinoIcons.photo_on_rectangle,
        label: 'الصور',
        count: property.images.length,
      ),
      _TabItem(
        icon: CupertinoIcons.map,
        label: 'الموقع',
      ),
      _TabItem(
        icon: CupertinoIcons.square_grid_2x2,
        label: 'المرافق',
        count: property.amenities.length,
      ),
      _TabItem(
        icon: CupertinoIcons.doc_text,
        label: 'السياسات',
        count: property.policies.length,
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              // Tab Selector
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: tabs.length,
                  itemBuilder: (context, index) {
                    final tab = tabs[index];
                    final isSelected = _selectedTabIndex == index;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTabIndex = index);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          gradient:
                              isSelected ? AppTheme.primaryGradient : null,
                          color: isSelected
                              ? null
                              : AppTheme.darkBackground.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? null
                              : Border.all(
                                  color: AppTheme.darkBorder
                                      .withValues(alpha: 0.2),
                                ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              tab.icon,
                              size: 18,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tab.label,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textMuted,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            if (tab.count != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: (isSelected
                                          ? Colors.white
                                          : AppTheme.primaryBlue)
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  tab.count.toString(),
                                  style: AppTextStyles.caption.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Tab Content
              Container(
                height: 400,
                padding: const EdgeInsets.all(16),
                child: IndexedStack(
                  index: _selectedTabIndex,
                  children: [
                    PropertyImageGallery(
                      propertyId: property.id,
                      initialImages: property.images,
                      onImagesChanged: (_) {},
                      isReadOnly: true,
                    ),
                    PropertyMapView(
                      initialLocation: LatLng(
                        property.latitude ?? 0,
                        property.longitude ?? 0,
                      ),
                      isReadOnly: true,
                    ),
                    PropertyAmenitiesGrid(
                      amenities: property.amenities,
                    ),
                    PropertyPoliciesList(
                      policies: property.policies,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActions(Property property) {
    return Positioned(
      bottom: 32,
      right: 20,
      child: Column(
        children: [
          _buildFloatingActionButton(
            icon: CupertinoIcons.checkmark_circle_fill,
            gradient: [AppTheme.success, AppTheme.neonGreen],
            onTap: () {
              HapticFeedback.mediumImpact();
              context.read<PropertiesBloc>().add(
                    ApprovePropertyEvent(widget.propertyId),
                  );
            },
          ),
          const SizedBox(height: 12),
          _buildFloatingActionButton(
            icon: CupertinoIcons.xmark_circle_fill,
            gradient: [AppTheme.error, AppTheme.neonPurple],
            onTap: () {
              HapticFeedback.mediumImpact();
              context.read<PropertiesBloc>().add(
                    RejectPropertyEvent(widget.propertyId),
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton({
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildRetryButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.read<PropertiesBloc>().add(
              LoadPropertyDetailsEvent(
                propertyId: widget.propertyId,
                includeUnits: true,
              ),
            );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.refresh,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'إعادة المحاولة',
              style: AppTextStyles.buttonMedium.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  final int? count;

  _TabItem({
    required this.icon,
    required this.label,
    this.count,
  });
}
