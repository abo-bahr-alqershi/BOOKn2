import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:yemen_booking_app/features/property/domain/entities/property_detail.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../injection_container.dart';
import '../bloc/property_bloc.dart';
import '../bloc/property_event.dart';
import '../bloc/property_state.dart';
import '../widgets/property_header_widget.dart';
import '../widgets/property_images_grid_widget.dart';
import '../widgets/property_info_widget.dart';
import '../widgets/amenities_grid_widget.dart';
import '../widgets/units_list_widget.dart';
import '../widgets/reviews_summary_widget.dart';
import '../widgets/policies_widget.dart';
import '../widgets/location_map_widget.dart';
import '../../../../injection_container.dart';
import '../../../../services/local_storage_service.dart';
import '../../../../core/constants/storage_constants.dart';

class PropertyDetailsPage extends StatefulWidget {
  final String propertyId;
  final String? userId;
  final String? unitId;

  const PropertyDetailsPage({
    super.key,
    required this.propertyId,
    this.userId,
    this.unitId,
  });

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _floatingHeaderController;
  late AnimationController _particleController;

  final ScrollController _scrollController = ScrollController();
  bool _showFloatingHeader = false;
  double _scrollOffset = 0;
  int _currentTabIndex = 0;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final List<_AnimatedParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateParticles();
    _tabController = TabController(length: 5, vsync: this);
    _scrollController.addListener(_onScroll);

    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });

    if (widget.unitId != null && widget.unitId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tabController.animateTo(1);
        }
      });
    }

    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _floatingHeaderController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.98,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.elasticOut,
    ));
  }

  void _generateParticles() {
    for (int i = 0; i < 5; i++) {
      _particles.add(_AnimatedParticle());
    }
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _floatingHeaderController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
      final shouldShow = _scrollOffset > 200;

      if (shouldShow != _showFloatingHeader) {
        _showFloatingHeader = shouldShow;
        if (_showFloatingHeader) {
          _floatingHeaderController.forward();
        } else {
          _floatingHeaderController.reverse();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<PropertyBloc>()
        ..add(GetPropertyDetailsEvent(
          propertyId: widget.propertyId,
          userId: (sl<LocalStorageService>().getData(StorageConstants.userId) ??
                  widget.userId)
              ?.toString(),
        ))
        ..add(UpdateViewCountEvent(propertyId: widget.propertyId)),
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        bottomNavigationBar: BlocBuilder<PropertyBloc, PropertyState>(
          buildWhen: (previous, current) => current is! PropertyFavoriteUpdated,
          builder: (context, state) {
            if (state is PropertyDetailsLoaded || state is PropertyWithDetails) {
              return _buildFuturisticBottomBarFromState(context, state);
            }
            return const SizedBox.shrink();
          },
        ),
        body: Stack(
          children: [
            _buildAnimatedBackground(),
            _buildParticles(),
            BlocBuilder<PropertyBloc, PropertyState>(
              buildWhen: (previous, current) =>
                  current is! PropertyFavoriteUpdated,
              builder: (context, state) {
                if (state is PropertyLoading) {
                  return _buildFuturisticLoader();
                }

                if (state is PropertyError) {
                  return _buildFuturisticError(context, state);
                }

                if (state is PropertyDetailsLoaded) {
                  return Stack(
                    children: [
                      CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          _buildFuturisticSliverAppBar(context, state),
                          SliverToBoxAdapter(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 0),
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: Transform.scale(
                                    scale: _scaleAnimation.value,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        PropertyHeaderWidget(
                                          property: state.property,
                                          isFavorite: state.isFavorite,
                                          isFavoritePending: state.isFavoritePending,
                                          onFavoriteToggle: () =>
                                              _toggleFavorite(context, state),
                                          onShare: () => _shareProperty(state),
                                        ),
                                        _buildFuturisticTabBar(),
                                        _buildFuturisticTabContentFromState(
                                            state),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_showFloatingHeader)
                        _buildFuturisticFloatingHeader(context, state),
                    ],
                  );
                }

                if (state is PropertyWithDetails) {
                  final detailsState = PropertyDetailsLoaded(
                    property: state.property,
                    isFavorite: state.isFavorite,
                    selectedImageIndex: state.selectedImageIndex,
                    isFavoritePending: state.isFavoritePending,
                    queuedFavoriteTarget: state.queuedFavoriteTarget,
                  );
                  return Stack(
                    children: [
                      CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          _buildFuturisticSliverAppBar(context, detailsState),
                          SliverToBoxAdapter(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 0),
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: Transform.scale(
                                    scale: _scaleAnimation.value,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        PropertyHeaderWidget(
                                          property: detailsState.property,
                                          isFavorite: detailsState.isFavorite,
                                          isFavoritePending: detailsState.isFavoritePending,
                                          onFavoriteToggle: () =>
                                              _toggleFavorite(
                                                  context, detailsState),
                                          onShare: () =>
                                              _shareProperty(detailsState),
                                        ),
                                        _buildFuturisticTabBar(),
                                        _buildFuturisticTabContentFromState(
                                            state),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_showFloatingHeader)
                        _buildFuturisticFloatingHeader(context, detailsState),
                    ],
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkBackground,
            AppTheme.darkSurface.withOpacity(0.9),
            AppTheme.darkCard.withOpacity(0.4),
          ],
        ),
      ),
    );
  }

  Widget _buildParticles() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          return CustomPaint(
            painter: _ParticlePainter(
              particles: _particles,
              animationValue: _particleController.value,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFuturisticLoader() {
    return const Center(
      child: LoadingWidget(
        type: LoadingType.futuristic,
        message: 'جاري تحميل تفاصيل العقار',
      ),
    );
  }

  Widget _buildFuturisticError(BuildContext context, PropertyError state) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withOpacity(0.8),
              AppTheme.darkCard.withOpacity(0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.error.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppTheme.error.withOpacity(0.2),
                    AppTheme.error.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 32,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'حدث خطأ',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppTheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildGlowingButton(
              onPressed: () {
                context.read<PropertyBloc>().add(
                      GetPropertyDetailsEvent(
                        propertyId: widget.propertyId,
                        userId: widget.userId,
                      ),
                    );
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'إعادة المحاولة',
                    style: AppTextStyles.buttonMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticSliverAppBar(
      BuildContext context, PropertyDetailsLoaded state) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: false,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: _buildGlassBackButton(context),
      actions: [
        _buildGlassActionButton(
          icon: Icons.share_outlined,
          onPressed: () => _shareProperty(state),
        ),
        _buildGlassActionButton(
          icon: state.isFavorite ? Icons.favorite : Icons.favorite_border,
          color: state.isFavorite ? AppTheme.error : null,
          onPressed: state.isFavoritePending
              ? null
              : () {
                  _toggleFavorite(context, state);
                },
        ),
        const SizedBox(width: 6),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'property_${state.property.id}',
          child: PropertyImagesGridWidget(
            images: state.property.images,
            onImageTap: (index) => _openGallery(context, state, index),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassBackButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkCard.withOpacity(0.6),
                  AppTheme.darkCard.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 16),
              color: AppTheme.textWhite,
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkCard.withOpacity(0.6),
                  AppTheme.darkCard.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (color ?? AppTheme.primaryBlue).withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: IconButton(
              icon: Icon(icon, size: 16),
              color: color ?? AppTheme.textWhite,
              onPressed: onPressed,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticTabBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.95),
            AppTheme.darkCard.withOpacity(0.85),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        physics: const BouncingScrollPhysics(),
        labelColor: AppTheme.primaryBlue,
        unselectedLabelColor: AppTheme.textMuted,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorWeight: 0,
        indicator: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        labelStyle: AppTextStyles.bodySmall,
        unselectedLabelStyle: AppTextStyles.caption,
        tabs: [
          _buildFuturisticTab('نظرة عامة', Icons.info_outline, 0),
          _buildFuturisticTab('الوحدات', Icons.meeting_room, 1),
          _buildFuturisticTab('المرافق', Icons.star_border, 2),
          _buildFuturisticTab('التقييمات', Icons.rate_review, 3),
          _buildFuturisticTab('الموقع', Icons.location_on, 4),
        ],
      ),
    );
  }

  Widget _buildFuturisticTab(String label, IconData icon, int index) {
    final isSelected = _currentTabIndex == index;

    return Tab(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected ? null : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppTheme.darkBorder.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : null,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticTabContentFromState(PropertyState state) {
    final detailsState = state is PropertyWithDetails
        ? PropertyDetailsLoaded(
            property: state.property,
            isFavorite: state.isFavorite,
            selectedImageIndex: state.selectedImageIndex,
          )
        : state as PropertyDetailsLoaded;
    final units = state is PropertyWithDetails
        ? state.units
        : detailsState.property.units;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: MediaQuery.of(context).size.height * 0.5,
      child: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildOverviewTab(detailsState),
          _buildUnitsTabWithUnits(detailsState, units),
          _buildAmenitiesTab(detailsState),
          _buildReviewsTab(detailsState),
          _buildLocationTab(detailsState),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(PropertyDetailsLoaded state) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGlassContainer(
            child: PropertyInfoWidget(property: state.property),
          ),
          const SizedBox(height: 12),
          if (state.property.services.isNotEmpty) ...[
            _buildSectionTitle('الخدمات المتاحة', Icons.room_service),
            const SizedBox(height: 10),
            _buildServicesGrid(state),
            const SizedBox(height: 12),
          ],
          if (state.property.policies.isNotEmpty) ...[
            _buildSectionTitle('السياسات والقوانين', Icons.policy),
            const SizedBox(height: 10),
            _buildGlassContainer(
              child: PoliciesWidget(policies: state.property.policies),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUnitsTabWithUnits(
      PropertyDetailsLoaded state, List<dynamic> units) {
    if (widget.unitId != null && widget.unitId!.isNotEmpty) {
      final index = units.indexWhere((u) => u.id == widget.unitId);
      if (index >= 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            const estimatedItemExtent = 240.0;
            final offset = (index * estimatedItemExtent).toDouble();
            _scrollController.animateTo(
              offset.clamp(0, _scrollController.position.maxScrollExtent),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutExpo,
            );
          }
        });
      }
    }

    return UnitsListWidget(
      units: units.cast(),
      selectedUnitId: widget.unitId,
      onUnitSelect: (unit) => _selectUnit(context, unit),
    );
  }

  Widget _buildAmenitiesTab(PropertyDetailsLoaded state) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(12),
      child: _buildGlassContainer(
        child: AmenitiesGridWidget(amenities: state.property.amenities),
      ),
    );
  }

  Widget _buildReviewsTab(PropertyDetailsLoaded state) {
    return ReviewsSummaryWidget(
      propertyId: state.property.id,
      reviewsCount: state.property.reviewsCount,
      averageRating: state.property.averageRating,
      onViewAll: () => _navigateToReviews(context, state),
    );
  }

  Widget _buildLocationTab(PropertyDetailsLoaded state) {
    return LocationMapWidget(
      latitude: state.property.latitude,
      longitude: state.property.longitude,
      propertyName: state.property.name,
      address: state.property.address,
    );
  }

  Widget _buildGlassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withOpacity(0.6),
                AppTheme.darkCard.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  //################### الخدمات
// تحديث دالة بناء الخدمات في Flutter

  Widget _buildServicesGrid(PropertyDetailsLoaded state) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: state.property.services.map((service) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue.withOpacity(0.2),
                AppTheme.primaryPurple.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getServiceIcon(service),
                size: 12,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 6),
              Text(
                service.name,
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              ),
              if (service.price > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${service.price} ${service.currency}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

// دالة للحصول على أيقونة الخدمة الديناميكية
  IconData _getServiceIcon(PropertyService service) {
    // إذا كانت الخدمة تحتوي على أيقونة محددة من الخادم
    if (service.icon.isNotEmpty) {
      return _getIconFromServiceName(service.icon);
    }

    // وإلا استخدم الأيقونة الافتراضية بناءً على الاسم
    final name = service.name.toLowerCase();
    if (name.contains('تنظيف') || name.contains('cleaning'))
      return Icons.cleaning_services;
    if (name.contains('غسيل') || name.contains('laundry'))
      return Icons.local_laundry_service;
    if (name.contains('طعام') || name.contains('food')) return Icons.restaurant;
    if (name.contains('إفطار') || name.contains('breakfast'))
      return Icons.breakfast_dining;
    if (name.contains('غداء') || name.contains('lunch'))
      return Icons.lunch_dining;
    if (name.contains('عشاء') || name.contains('dinner'))
      return Icons.dinner_dining;
    if (name.contains('نقل') || name.contains('transport'))
      return Icons.airport_shuttle;
    if (name.contains('تاكسي') || name.contains('taxi'))
      return Icons.local_taxi;
    if (name.contains('واي فاي') || name.contains('wifi')) return Icons.wifi;
    if (name.contains('سبا') || name.contains('spa')) return Icons.spa;
    if (name.contains('جيم') || name.contains('gym'))
      return Icons.fitness_center;
    if (name.contains('مسبح') || name.contains('pool')) return Icons.pool;

    return Icons.check_circle;
  }

// دالة لتحويل اسم الأيقونة من السلسلة النصية إلى IconData
  IconData _getIconFromServiceName(String iconName) {
    // خريطة شاملة لتحويل أسماء أيقونات الخدمات إلى Material Icons
    final iconMap = <String, IconData>{
      // خدمات التنظيف
      'cleaning_services': Icons.cleaning_services,
      'dry_cleaning': Icons.dry_cleaning,
      'local_laundry_service': Icons.local_laundry_service,
      'iron': Icons.iron,
      'wash': Icons.wash,
      'soap': Icons.soap,
      'plumbing': Icons.plumbing,

      // خدمات الطعام والضيافة
      'room_service': Icons.room_service,
      'restaurant': Icons.restaurant,
      'local_cafe': Icons.local_cafe,
      'local_bar': Icons.local_bar,
      'breakfast_dining': Icons.breakfast_dining,
      'lunch_dining': Icons.lunch_dining,
      'dinner_dining': Icons.dinner_dining,
      'delivery_dining': Icons.delivery_dining,
      'takeout_dining': Icons.takeout_dining,
      'ramen_dining': Icons.ramen_dining,
      'icecream': Icons.icecream,
      'cake': Icons.cake,
      'local_pizza': Icons.local_pizza,
      'fastfood': Icons.fastfood,

      // خدمات النقل
      'airport_shuttle': Icons.airport_shuttle,
      'local_taxi': Icons.local_taxi,
      'car_rental': Icons.car_rental,
      'car_repair': Icons.car_repair,
      'directions_car': Icons.directions_car,
      'directions_bus': Icons.directions_bus,
      'directions_boat': Icons.directions_boat,
      'directions_bike': Icons.directions_bike,
      'electric_bike': Icons.electric_bike,
      'electric_scooter': Icons.electric_scooter,
      'local_shipping': Icons.local_shipping,
      'local_parking': Icons.local_parking,

      // خدمات الاتصالات
      'wifi': Icons.wifi,
      'wifi_calling': Icons.wifi_calling,
      'router': Icons.router,
      'phone_in_talk': Icons.phone_in_talk,
      'phone_callback': Icons.phone_callback,
      'support_agent': Icons.support_agent,
      'headset_mic': Icons.headset_mic,
      'mail': Icons.mail,
      'markunread_mailbox': Icons.markunread_mailbox,
      'print': Icons.print,
      'scanner': Icons.scanner,
      'fax': Icons.fax,

      // خدمات الترفيه
      'spa': Icons.spa,
      'hot_tub': Icons.hot_tub,
      'pool': Icons.pool,
      'fitness_center': Icons.fitness_center,
      'sports_tennis': Icons.sports_tennis,
      'sports_golf': Icons.sports_golf,
      'sports_soccer': Icons.sports_soccer,
      'sports_basketball': Icons.sports_basketball,
      'casino': Icons.casino,
      'theater_comedy': Icons.theater_comedy,
      'movie': Icons.movie,
      'music_note': Icons.music_note,
      'nightlife': Icons.nightlife,
      'celebration': Icons.celebration,

      // خدمات الأعمال
      'business_center': Icons.business_center,
      'meeting_room': Icons.meeting_room,
      'co_present': Icons.co_present,
      'groups': Icons.groups,
      'event': Icons.event,
      'event_available': Icons.event_available,
      'event_seat': Icons.event_seat,
      'mic': Icons.mic,
      'videocam': Icons.videocam,
      'desktop_windows': Icons.desktop_windows,
      'laptop': Icons.laptop,

      // خدمات صحية
      'medical_services': Icons.medical_services,
      'local_hospital': Icons.local_hospital,
      'local_pharmacy': Icons.local_pharmacy,
      'emergency': Icons.emergency,
      'vaccines': Icons.vaccines,
      'healing': Icons.healing,
      'monitor_heart': Icons.monitor_heart,
      'health_and_safety': Icons.health_and_safety,
      'masks': Icons.masks,
      'sanitizer': Icons.sanitizer,
      'psychology': Icons.psychology,
      'self_improvement': Icons.self_improvement,

      // خدمات التسوق
      'shopping_cart': Icons.shopping_cart,
      'shopping_bag': Icons.shopping_bag,
      'local_mall': Icons.local_mall,
      'local_grocery_store': Icons.local_grocery_store,
      'local_convenience_store': Icons.local_convenience_store,
      'store': Icons.store,
      'storefront': Icons.storefront,
      'local_offer': Icons.local_offer,
      'loyalty': Icons.loyalty,
      'card_giftcard': Icons.card_giftcard,

      // خدمات العائلة
      'child_care': Icons.child_care,
      'baby_changing_station': Icons.baby_changing_station,
      'child_friendly': Icons.child_friendly,
      'toys': Icons.toys,
      'stroller': Icons.stroller,
      'family_restroom': Icons.family_restroom,
      'escalator_warning': Icons.escalator_warning,
      'pregnant_woman': Icons.pregnant_woman,

      // حيوانات أليفة
      'pets': Icons.pets,

      // خدمات الأمان
      'security': Icons.security,
      'local_police': Icons.local_police,
      'shield': Icons.shield,
      'verified_user': Icons.verified_user,
      'lock': Icons.lock,
      'key': Icons.key,
      'doorbell': Icons.doorbell,
      'camera_alt': Icons.camera_alt,

      // خدمات مالية
      'local_atm': Icons.local_atm,
      'account_balance': Icons.account_balance,
      'currency_exchange': Icons.currency_exchange,
      'payment': Icons.payment,
      'credit_card': Icons.credit_card,
      'account_balance_wallet': Icons.account_balance_wallet,
      'savings': Icons.savings,

      // خدمات أخرى
      'handshake': Icons.handshake,
      'luggage': Icons.luggage,
      'umbrella': Icons.beach_access,
      'translate': Icons.translate,
      'tour': Icons.tour,
      'map': Icons.map,
      'info': Icons.info,
    };

    return iconMap[iconName] ?? Icons.check_circle;
  }

  //################### الخدمات
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 8),
        ShaderMask(
          shaderCallback: (bounds) =>
              AppTheme.primaryGradient.createShader(bounds),
          child: Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFuturisticFloatingHeader(
      BuildContext context, PropertyDetailsLoaded state) {
    return AnimatedBuilder(
      animation: _floatingHeaderController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -100 * (1 - _floatingHeaderController.value)),
          child: Opacity(
            opacity: _floatingHeaderController.value.clamp(0.0, 1.0).toDouble(),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkCard.withOpacity(0.95),
                    AppTheme.darkCard.withOpacity(0.85),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: SafeArea(
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          _buildGlassBackButton(context),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.property.name,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textWhite,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 10,
                                      color: AppTheme.primaryBlue,
                                    ),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        state.property.address,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppTheme.textMuted,
                                          fontSize: 10,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _buildGlassActionButton(
                            icon: state.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: state.isFavorite ? AppTheme.error : null,
                            onPressed: () => _toggleFavorite(context, state),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFuturisticBottomBarFromState(
      BuildContext context, PropertyState state) {
    final detailsState = state is PropertyWithDetails
        ? PropertyDetailsLoaded(
            property: state.property,
            isFavorite: state.isFavorite,
            selectedImageIndex: state.selectedImageIndex,
          )
        : state as PropertyDetailsLoaded;
    final units = state is PropertyWithDetails
        ? state.units
        : detailsState.property.units;

    final lowestPrice = units.isNotEmpty
        ? units.map((u) => u.basePrice.amount).reduce((a, b) => a < b ? a : b)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.darkCard.withOpacity(0.95),
            AppTheme.darkSurface,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'يبدأ من',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => AppTheme
                                  .primaryGradient
                                  .createShader(bounds),
                              child: Text(
                                lowestPrice.toStringAsFixed(0),
                                style: AppTextStyles.heading2.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'ريال / ليلة',
                              style: AppTextStyles.caption.copyWith(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildGlowingButton(
                    onPressed: () =>
                        _navigateToBooking(context, detailsState),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'احجز الآن',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlowingButton({
    required VoidCallback onPressed,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: child,
          ),
        ),
      ),
    );
  }

  void _toggleFavorite(BuildContext context, PropertyDetailsLoaded state) {
    final uid = (sl<LocalStorageService>().getData(StorageConstants.userId) ??
            widget.userId ??
            '')
        .toString();
    context.read<PropertyBloc>().add(
          ToggleFavoriteEvent(
            propertyId: state.property.id,
            userId: uid,
            isFavorite: state.isFavorite,
          ),
        );

    HapticFeedback.lightImpact();
  }

  void _shareProperty(PropertyDetailsLoaded state) {
    HapticFeedback.mediumImpact();
  }

  void _openGallery(
      BuildContext context, PropertyDetailsLoaded state, int index) {
    context.push(
      '/property/${state.property.id}/gallery',
      extra: {
        'images': state.property.images,
        'initialIndex': index,
      },
    );
  }

  void _selectUnit(BuildContext context, dynamic unit) {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return _buildFuturisticUnitModal(ctx, unit, context);
      },
    );
  }

  Widget _buildFuturisticUnitModal(
      BuildContext ctx, dynamic unit, BuildContext parentContext) {
    return Container(
      height: MediaQuery.of(ctx).size.height * 0.7,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.darkCard,
            AppTheme.darkSurface,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppTheme.primaryGradient.createShader(bounds),
                              child: Text(
                                unit.name,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              unit.unitTypeName,
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (unit.images.isNotEmpty)
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CachedImageWidget(
                              imageUrl: unit.images.first.url,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryBlue.withOpacity(0.1),
                              AppTheme.primaryPurple.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppTheme.primaryGradient.createShader(bounds),
                              child: Text(
                                unit.basePrice.amount.toStringAsFixed(0),
                                style: AppTextStyles.heading2.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${unit.basePrice.currency} / ليلة',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      _buildGlowingButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _navigateToBooking(
                            parentContext,
                            parentContext.read<PropertyBloc>().state
                                    is PropertyWithDetails
                                ? PropertyDetailsLoaded(
                                    property: (parentContext
                                            .read<PropertyBloc>()
                                            .state as PropertyWithDetails)
                                        .property,
                                    isFavorite: (parentContext
                                            .read<PropertyBloc>()
                                            .state as PropertyWithDetails)
                                        .isFavorite,
                                  )
                                : parentContext.read<PropertyBloc>().state
                                    as PropertyDetailsLoaded,
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'احجز هذه الوحدة',
                              style: AppTextStyles.buttonMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToReviews(BuildContext context, PropertyDetailsLoaded state) {
    context.push(
      '/property/${state.property.id}/reviews',
      extra: state.property.name,
    );
  }

  void _navigateToBooking(BuildContext context, PropertyDetailsLoaded state) {
    context.push(
      '/booking/form',
      extra: {
        'propertyId': state.property.id,
        'propertyName': state.property.name,
      },
    );
  }
}

// كلاسات الـ Painters بدون تغيير ولكن بأحجام أصغر
class _AnimatedParticle {
  late double x;
  late double y;
  late double vx;
  late double vy;
  late double radius;
  late double opacity;
  late Color color;

  _AnimatedParticle() {
    reset();
  }

  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    vx = (math.Random().nextDouble() - 0.5) * 0.0005;
    vy = (math.Random().nextDouble() - 0.5) * 0.0005;
    radius = math.Random().nextDouble() * 1.5 + 0.5;
    opacity = math.Random().nextDouble() * 0.2 + 0.05;

    final colors = [
      AppTheme.primaryBlue,
      AppTheme.primaryPurple,
      AppTheme.primaryCyan,
    ];
    color = colors[math.Random().nextInt(colors.length)];
  }

  void update() {
    x += vx;
    y += vy;

    if (x < 0 || x > 1) vx = -vx;
    if (y < 0 || y > 1) vy = -vy;
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_AnimatedParticle> particles;
  final double animationValue;

  _ParticlePainter({
    required this.particles,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update();

      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DNALoaderPainter extends CustomPainter {
  final double animationValue;

  _DNALoaderPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    const pointCount = 15;
    final waveHeight = size.height / 4;
    final dx = size.width / (pointCount - 1);

    for (int j = 0; j < 2; j++) {
      final path = Path();
      final paint = Paint()
        ..shader = AppTheme.primaryGradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < pointCount; i++) {
        final x = i * dx;
        final angle =
            (i / pointCount) * 4 * math.pi + (animationValue * 2 * math.pi);
        final y =
            size.height / 2 + math.sin(angle + (j * math.pi)) * waveHeight;

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
