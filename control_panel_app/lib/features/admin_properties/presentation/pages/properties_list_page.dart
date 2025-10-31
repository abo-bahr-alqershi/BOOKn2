// lib/features/admin_properties/presentation/pages/properties_list_page.dart

import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:bookn_cp_app/features/admin_properties/domain/entities/property.dart';
import 'package:bookn_cp_app/features/admin_properties/presentation/widgets/property_map_cluster_view.dart';
import 'package:bookn_cp_app/injection_container.dart' as di;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:bookn_cp_app/core/theme/app_colors.dart';
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';
import '../bloc/properties/properties_bloc.dart';
import '../widgets/futuristic_property_table.dart';
import '../widgets/property_filters_widget.dart';
import '../widgets/property_stats_card.dart';
import 'package:bookn_cp_app/core/widgets/loading_widget.dart';
import 'package:bookn_cp_app/features/admin_properties/presentation/bloc/amenities/amenities_bloc.dart'
    as ap_am_bloc;
import 'package:bookn_cp_app/features/admin_properties/domain/repositories/amenities_repository.dart'
    as ap_repo;

class PropertiesListPage extends StatefulWidget {
  const PropertiesListPage({super.key});

  @override
  State<PropertiesListPage> createState() => _PropertiesListPageState();
}

class _PropertiesListPageState extends State<PropertiesListPage>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _backgroundAnimationController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late AnimationController _contentAnimationController;

  // Animations
  late Animation<double> _backgroundRotation;
  late Animation<double> _glowAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;

  // State
  final ScrollController _scrollController = ScrollController();
  bool _showFilters = false;
  String _selectedView = 'table'; // grid, table, map
  bool _isDeleting = false;

  void _showDeletingDialog({String message = 'جاري حذف العقار...'}) {
    if (_isDeleting) return;
    _isDeleting = true;
    showDialog(
      fullscreenDialog: true,
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        elevation: 0,
        child: Center(
          child: LoadingWidget(
            type: LoadingType.futuristic,
            message: message,
          ),
        ),
      ),
    );
  }

  void _dismissDeletingDialog() {
    if (_isDeleting) {
      _isDeleting = false;
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadProperties();
    _scrollController.addListener(_onScroll);
  }

  void _initializeAnimations() {
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _particleController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _backgroundRotation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _backgroundAnimationController,
      curve: Curves.linear,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _contentFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOut,
    ));

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOutQuart,
    ));

    // Start animations
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _contentAnimationController.forward();
      }
    });
  }

  void _loadProperties() {
    context.read<PropertiesBloc>().add(const LoadPropertiesEvent(pageSize: 20));
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _contentAnimationController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent * 0.9) {
      final current = context.read<PropertiesBloc>().state;
      if (current is PropertiesLoaded && current.hasNextPage) {
        context.read<PropertiesBloc>().add(const LoadMorePropertiesEvent());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PropertiesBloc, PropertiesState>(
      listener: (context, state) {
        if (state is PropertyDeleting) {
          _showDeletingDialog();
        } else if (state is PropertyDeleted) {
          _dismissDeletingDialog();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تم حذف العقار بنجاح'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (state is PropertiesError && _isDeleting) {
          _dismissDeletingDialog();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل الحذف: ${state.message}'),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Stack(
          children: [
            // Animated Background
            _buildAnimatedBackground(),

            // Main Content with CustomScrollView for scrolling
            RefreshIndicator(
              onRefresh: () async {
                context.read<PropertiesBloc>().add(const LoadPropertiesEvent());
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                // App Bar similar to bookings page
                _buildSliverAppBar(),

                // Stats Cards as SliverToBoxAdapter
                SliverToBoxAdapter(
                  child: _buildStatsSection(),
                ),

                // Filters Section as SliverToBoxAdapter
                if (_showFilters)
                  SliverToBoxAdapter(
                    child: _buildFiltersSection(),
                  ),

                // Content Area - المحتوى الرئيسي
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _contentFadeAnimation,
                    child: SlideTransition(
                      position: _contentSlideAnimation,
                      child: _buildContent(),
                    ),
                  ),
                ),

                // Load more indicator space
                SliverToBoxAdapter(child: _buildLoadMoreIndicator()),

                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
                ],
              ),
            ),

            // Removed FAB: Add action exists in AppBar
          ],
        ),
      ),
    );
  }

  // SliverAppBar aligned with bookings page styling
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      centerTitle: false,
      backgroundColor: AppTheme.darkBackground,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 16),
        title: Text(
          'إدارة العقارات',
          style: AppTextStyles.heading1.copyWith(
            color: AppTheme.textWhite,
            shadows: [
              Shadow(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                blurRadius: 10,
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryBlue.withOpacity(0.1),
                AppTheme.darkBackground,
              ],
            ),
          ),
        ),
      ),
      actions: _buildAppBarActions(context),
    );
  }

  // Compact icon-only action for AppBar to avoid overflow
  Widget _buildAppBarIconAction({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: Icon(
        icon,
        color: AppTheme.textWhite,
        size: 20,
      ),
      splashRadius: 20,
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 720) {
      return [
        _buildAppBarIconAction(
          icon: Icons.filter_list_rounded,
          onPressed: () => setState(() => _showFilters = !_showFilters),
        ),
        _buildAppBarIconAction(
          icon: Icons.add_rounded,
          onPressed: () async {
            await context.push('/admin/properties/create');
            if (!mounted) return;
            context.read<PropertiesBloc>().add(const LoadPropertiesEvent());
          },
        ),
        _buildOverflowMenu(),
        const SizedBox(width: 4),
      ];
    }

    return [
      _buildAppBarIconAction(
        icon: Icons.filter_list_rounded,
        onPressed: () => setState(() => _showFilters = !_showFilters),
      ),
      // _buildAppBarIconAction(
      //   icon: Icons.grid_view_rounded,
      //   onPressed: () => setState(() => _selectedView = 'grid'),
      // ),
      _buildAppBarIconAction(
        icon: Icons.table_chart_rounded,
        onPressed: () => setState(() => _selectedView = 'table'),
      ),
      _buildAppBarIconAction(
        icon: Icons.map_rounded,
        onPressed: () => setState(() => _selectedView = 'map'),
      ),
      _buildAppBarIconAction(
        icon: Icons.add_rounded,
        onPressed: () async {
          await context.push('/admin/properties/create');
          if (!mounted) return;
          context.read<PropertiesBloc>().add(const LoadPropertiesEvent());
        },
      ),
      const SizedBox(width: 4),
    ];
  }

  Widget _buildOverflowMenu() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: AppTheme.textWhite),
      onSelected: (value) {
        switch (value) {
          case 'grid':
            setState(() => _selectedView = 'grid');
            break;
          case 'table':
            setState(() => _selectedView = 'table');
            break;
          case 'map':
            setState(() => _selectedView = 'map');
            break;
        }
      },
      itemBuilder: (context) => [
        // const PopupMenuItem(
        //   value: 'grid',
        //   child: Row(
        //     children: [
        //       Icon(Icons.grid_view_rounded, size: 18),
        //       SizedBox(width: 8),
        //       Text('شبكة'),
        //     ],
        //   ),
        // ),
        const PopupMenuItem(
          value: 'table',
          child: Row(
            children: [
              Icon(Icons.table_chart_rounded, size: 18),
              SizedBox(width: 8),
              Text('جدول'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'map',
          child: Row(
            children: [
              Icon(Icons.map_rounded, size: 18),
              SizedBox(width: 8),
              Text('خريطة'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([_backgroundRotation, _glowAnimation]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkBackground,
                AppTheme.darkBackground2.withOpacity(0.8),
                AppTheme.darkBackground3.withOpacity(0.6),
              ],
            ),
          ),
          child: CustomPaint(
            painter: _FuturisticBackgroundPainter(
              rotation: _backgroundRotation.value,
              glowIntensity: _glowAnimation.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.7),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              // Title Section
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              AppTheme.primaryGradient.createShader(bounds),
                          child: Text(
                            'إدارة العقارات',
                            style: AppTextStyles.heading1.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'إدارة جميع العقارات والوحدات المسجلة',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Action Buttons - مع scroll أفقي
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.filter_list_rounded,
                      label: 'فلتر',
                      onTap: () => setState(() => _showFilters = !_showFilters),
                      isActive: _showFilters,
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.grid_view_rounded,
                      label: 'شبكة',
                      onTap: () => setState(() => _selectedView = 'grid'),
                      isActive: _selectedView == 'grid',
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.table_chart_rounded,
                      label: 'جدول',
                      onTap: () => setState(() => _selectedView = 'table'),
                      isActive: _selectedView == 'table',
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.map_rounded,
                      label: 'خريطة',
                      onTap: () => setState(() => _selectedView = 'map'),
                      isActive: _selectedView == 'map',
                    ),
                    const SizedBox(width: 16),
                    _buildPrimaryActionButton(
                      icon: Icons.add_rounded,
                      label: 'إضافة عقار',
                      onTap: () => context.push('/admin/properties/create'),
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive
              ? AppTheme.primaryGradient
              : LinearGradient(
                  colors: [
                    AppTheme.darkCard.withOpacity(0.5),
                    AppTheme.darkCard.withOpacity(0.3),
                  ],
                ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppTheme.primaryBlue.withOpacity(0.5)
                : AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isActive ? Colors.white : AppTheme.textMuted,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.buttonMedium.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: BlocBuilder<PropertiesBloc, PropertiesState>(
        builder: (context, state) {
          final totalProperties = state is PropertiesLoaded
              ? (state.stats != null && state.stats!['totalProperties'] != null
                  ? int.tryParse('${state.stats!['totalProperties']}') ?? state.totalCount
                  : state.totalCount)
              : 0;
          final activeCount = state is PropertiesLoaded
              ? (state.stats != null && state.stats!['activeProperties'] != null
                  ? int.tryParse('${state.stats!['activeProperties']}') ?? 0
                  : 0)
              : 0;
          final pendingCount = state is PropertiesLoaded
              ? (state.stats != null && state.stats!['pendingProperties'] != null
                  ? int.tryParse('${state.stats!['pendingProperties']}') ?? 0
                  : 0)
              : 0;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 200,
                  child: PropertyStatsCard(
                    title: 'إجمالي العقارات',
                    value: totalProperties.toString(),
                    icon: Icons.business_rounded,
                    color: AppTheme.primaryBlue,
                    trend: '+12%',
                    isPositive: true,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 200,
                  child: PropertyStatsCard(
                    title: 'في انتظار الموافقة',
                    value: pendingCount.toString(),
                    icon: Icons.pending_rounded,
                    color: AppTheme.warning,
                    trend: '5',
                    isPositive: false,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 200,
                  child: PropertyStatsCard(
                    title: 'عقارات نشطة',
                    value: activeCount.toString(),
                    icon: Icons.check_circle_rounded,
                    color: AppTheme.success,
                    trend: '+8%',
                    isPositive: true,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 200,
                  child: PropertyStatsCard(
                    title: 'معدل الإشغال',
                    value: '78%',
                    icon: Icons.analytics_rounded,
                    color: AppTheme.primaryPurple,
                    trend: '+3%',
                    isPositive: true,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFiltersSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 300,
      child: SingleChildScrollView(
        child: BlocProvider<ap_am_bloc.AmenitiesBloc>(
          create: (_) => di.sl<ap_am_bloc.AmenitiesBloc>(),
          child: PropertyFiltersWidget(
            onFilterChanged: (filters) {
              context.read<PropertiesBloc>().add(
                    FilterPropertiesEvent(
                      propertyTypeId: filters['propertyTypeId'],
                      minPrice: filters['minPrice'],
                      maxPrice: filters['maxPrice'],
                      amenityIds: filters['amenityIds'],
                      starRatings: filters['starRatings'],
                      minAverageRating: filters['minAverageRating'],
                      isApproved: filters['isApproved'],
                      // دعم فلتر يحتوي حجوزات نشطة
                      hasActiveBookings: filters['hasActiveBookings'],
                    ),
                  );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<PropertiesBloc, PropertiesState>(
      builder: (context, state) {
        if (state is PropertiesLoading) {
          return _buildLoadingState();
        }

        if (state is PropertiesError) {
          return _buildErrorState(state.message);
        }

        if (state is PropertiesLoaded) {
          switch (_selectedView) {
            case 'grid':
              return _buildGridView(state);
            case 'table':
              return Padding(
                padding: const EdgeInsets.all(16),
                child: FuturisticPropertyTable(
                  properties: state.properties,
                  onPropertyTap: (property) => _navigateToProperty(property.id),
                  onEdit: (property) => _navigateToEditProperty(property.id),
                  onApprove: (propertyId) {
                    _showApproveConfirmation(propertyId);
                  },
                  onReject: (propertyId) {
                    _showRejectConfirmation(propertyId);
                  },
                  onDelete: (propertyId) {
                    _showDeleteConfirmation(propertyId);
                  },
                  onAssignAmenities: (property) {
                    _openAssignAmenities(
                      propertyId: property.id,
                      propertyName: property.name,
                      propertyTypeId: property.typeId,
                    );
                  },
                ),
              );
            case 'map':
              return _buildMapView(state);
            default:
              return _buildGridView(state);
          }
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildGridView(PropertiesLoaded state) {
    // حساب عدد الأعمدة بناءً على عرض الشاشة
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = 3;
    if (width < 900) {
      crossAxisCount = 2;
    }
    if (width < 600) {
      crossAxisCount = 1;
    }

    final hasMore = state.hasNextPage;
    final itemCount = state.properties.length + (hasMore ? 1 : 0);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index >= state.properties.length) {
            return Center(child: _buildInlineLoader());
          }
          final property = state.properties[index];
          return _PropertyGridCard(
            property: property,
            onTap: () => _navigateToProperty(property.id),
            onEdit: () => _navigateToEditProperty(property.id),
            onDelete: () => _showDeleteConfirmation(property.id),
            onApprove: () => _showApproveConfirmation(property.id),
            onReject: () => _showRejectConfirmation(property.id),
          );
        },
      ),
    );
  }

  Widget _buildMapView(PropertiesLoaded state) {
    // حساب الارتفاع الديناميكي بناءً على حجم الشاشة
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    // احتساب الارتفاع المتاح (الشاشة كاملة ناقص الأجزاء العلوية)
    final availableHeight =
        screenHeight - appBarHeight - statusBarHeight - 100; // 100 للهوامش

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height:
          availableHeight.clamp(500.0, 900.0), // الحد الأدنى 500 والأقصى 900
      child: PropertyMapClusterView(
        properties: state.properties,
        onPropertySelected: (property) {
          _navigateToProperty(property.id);
        },
        onFilterChanged: (filters) {
          context.read<PropertiesBloc>().add(
                FilterPropertiesEvent(
                  propertyTypeId: filters['propertyTypeId'],
                  minPrice: filters['minPrice'],
                  maxPrice: filters['maxPrice'],
                  amenityIds: filters['amenityIds'],
                  starRatings: filters['starRatings'],
                  minAverageRating: filters['minAverageRating'],
                  isApproved: filters['isApproved'],
                  hasActiveBookings: filters['hasActiveBookings'],
                ),
              );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 400,
      child: Center(
        child: LoadingWidget(
          type: LoadingType.futuristic,
          message: 'جاري تحميل العقارات...',
        ),
      ),
    );
  }

  Widget _buildInlineLoader() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: LoadingWidget(
          type: LoadingType.futuristic,
          message: 'جاري التحميل...'
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return BlocBuilder<PropertiesBloc, PropertiesState>(
      builder: (context, state) {
        if (state is PropertiesLoaded && state.hasNextPage) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: LoadingWidget(
                type: LoadingType.futuristic,
                message: 'جاري تحميل المزيد...'
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      height: 400,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppTheme.error.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.error,
            ),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _loadProperties,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'إعادة المحاولة',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Removed FAB: Add action exists in AppBar

  Future<void> _navigateToProperty(String propertyId) async {
    final pid = Uri.encodeComponent(propertyId);
    await context.push('/admin/properties/$pid');
    if (!mounted) return;
    context.read<PropertiesBloc>().add(const LoadPropertiesEvent());
  }

  Future<void> _navigateToEditProperty(String propertyId) async {
    final pid = Uri.encodeComponent(propertyId);
    await context.push('/admin/properties/$pid/edit');
    if (!mounted) return;
    context.read<PropertiesBloc>().add(const LoadPropertiesEvent());
  }

  void _openAssignAmenities({
    required String propertyId,
    required String propertyName,
    required String propertyTypeId,
  }) {
    HapticFeedback.mediumImpact();
    showDialog(
      fullscreenDialog: true,
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => BlocProvider<ap_am_bloc.AmenitiesBloc>(
        create: (_) => di.sl<ap_am_bloc.AmenitiesBloc>()
          ..add(ap_am_bloc.LoadAmenitiesEventWithType(
            propertyTypeId: propertyTypeId,
            pageNumber: 1,
            pageSize: 100,
          )),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.primaryPurple.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: _PropertyAmenitiesAssignView(
                  propertyId: propertyId, propertyName: propertyName),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String propertyId) {
    showDialog(
      fullscreenDialog: true,
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.error.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.error.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.error.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: AppTheme.error,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'حذف العقار؟',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'لا يمكن التراجع عن هذا الإجراء',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'إلغاء',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppTheme.textLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          context
                              .read<PropertiesBloc>()
                              .add(DeletePropertyEvent(propertyId));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'حذف',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showApproveConfirmation(String propertyId) {
    HapticFeedback.mediumImpact();
    showDialog(
      fullscreenDialog: true,
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.success.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.success.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.success.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.success,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'الموافقة على العقار؟',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'سيتم اعتماد هذا العقار. هل تريد المتابعة؟',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'إلغاء',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppTheme.textLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          context
                              .read<PropertiesBloc>()
                              .add(ApprovePropertyEvent(propertyId));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'موافقة',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRejectConfirmation(String propertyId) {
    HapticFeedback.mediumImpact();
    showDialog(
      fullscreenDialog: true,
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.error.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.error.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.error.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.highlight_off_rounded,
                    color: AppTheme.error,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'رفض العقار؟',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'سيتم رفض هذا العقار. هل تريد المتابعة؟',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'إلغاء',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppTheme.textLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          context
                              .read<PropertiesBloc>()
                              .add(RejectPropertyEvent(propertyId));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'رفض',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Property Grid Card Widget - تبقى كما هي
class _PropertyGridCard extends StatefulWidget {
  final Property property;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PropertyGridCard({
    required this.property,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<_PropertyGridCard> createState() => _PropertyGridCardState();
}

class _PropertyGridCardState extends State<_PropertyGridCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isSmall = width < 500;
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _hoverAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _hoverAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isHovered
                        ? [
                            AppTheme.primaryBlue.withOpacity(0.1),
                            AppTheme.primaryPurple.withOpacity(0.05),
                          ]
                        : [
                            AppTheme.darkCard.withOpacity(0.7),
                            AppTheme.darkCard.withOpacity(0.5),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isHovered
                        ? AppTheme.primaryBlue.withOpacity(0.5)
                        : AppTheme.darkBorder.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isHovered
                          ? AppTheme.primaryBlue.withOpacity(0.2)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: _isHovered ? 20 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Stack(
                      children: [
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.primaryGradient,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.business_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.property.name,
                                          style: TextStyle(
                                            color: AppTheme.textWhite,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          widget.property.city,
                                          style: TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const Spacer(),

                              // Stats
                              Row(
                                children: [
                                  _buildStat(
                                    icon: Icons.star_rounded,
                                    value:
                                        widget.property.starRating.toString(),
                                    color: AppTheme.warning,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStat(
                                      icon: Icons.location_on_rounded,
                                      value: widget.property.city,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.property.isApproved
                                      ? AppTheme.success.withOpacity(0.2)
                                      : AppTheme.warning.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: widget.property.isApproved
                                        ? AppTheme.success.withOpacity(0.5)
                                        : AppTheme.warning.withOpacity(0.5),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  widget.property.isApproved
                                      ? 'معتمد'
                                      : 'قيد المراجعة',
                                  style: TextStyle(
                                    color: widget.property.isApproved
                                        ? AppTheme.success
                                        : AppTheme.warning,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              // Actions Row (Edit/Delete) + Approve/Reject responsive placement
                              const SizedBox(height: 8),
                              if (!isSmall) _buildTopRightActions(),
                              if (isSmall) _buildBottomActions(),
                            ],
                          ),
                        ),

                        // Hover Actions on large screens only (kept for desktop aesthetics)
                        if (_isHovered && !isSmall)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: _buildTopRightActions(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopRightActions() {
    return Row(
      children: [
        _buildActionIcon(
          Icons.edit_rounded,
          widget.onEdit,
        ),
        const SizedBox(width: 4),
        _buildActionIcon(
          Icons.delete_rounded,
          widget.onDelete,
          color: AppTheme.error,
        ),
        if (!widget.property.isApproved) ...[
          const SizedBox(width: 4),
          _buildActionIcon(
            Icons.check_rounded,
            widget.onApprove,
            color: AppTheme.success,
          ),
          const SizedBox(width: 4),
          _buildActionIcon(
            Icons.close_rounded,
            widget.onReject,
            color: AppTheme.warning,
          ),
        ],
      ],
    );
  }

  Widget _buildBottomActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildActionChip(
              icon: Icons.edit_rounded,
              label: 'تعديل',
              onTap: widget.onEdit,
            ),
            const SizedBox(width: 6),
            _buildActionChip(
              icon: Icons.delete_rounded,
              label: 'حذف',
              onTap: widget.onDelete,
              color: AppTheme.error,
            ),
          ],
        ),
        if (!widget.property.isApproved) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionChip(
                icon: Icons.check_rounded,
                label: 'موافقة',
                onTap: widget.onApprove,
                color: AppTheme.success,
              ),
              const SizedBox(width: 6),
              _buildActionChip(
                icon: Icons.close_rounded,
                label: 'رفض',
                onTap: widget.onReject,
                color: AppTheme.warning,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.darkBackground.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (color ?? AppTheme.primaryBlue).withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color ?? AppTheme.primaryBlue),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color ?? AppTheme.primaryBlue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionIcon(
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppTheme.darkBackground.withOpacity(0.8),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: (color ?? AppTheme.primaryBlue).withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          size: 12,
          color: color ?? AppTheme.primaryBlue,
        ),
      ),
    );
  }
}

// Delete Confirmation Dialog - تبقى كما هي
class _DeleteConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const _DeleteConfirmationDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(10),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withOpacity(0.95),
              AppTheme.darkCard.withOpacity(0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.error.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.error.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.error.withOpacity(0.2),
                    AppTheme.error.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_rounded,
                color: AppTheme.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'تأكيد الحذف',
              style: AppTextStyles.heading3.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'هل أنت متأكد من حذف هذا العقار؟\nلا يمكن التراجع عن هذا الإجراء.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.darkBorder.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'إلغاء',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onConfirm();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.error,
                            AppTheme.error.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.error.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'حذف',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Background Painter - تبقى كما هي
class _FuturisticBackgroundPainter extends CustomPainter {
  final double rotation;
  final double glowIntensity;

  _FuturisticBackgroundPainter({
    required this.rotation,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw grid
    paint.color = AppTheme.primaryBlue.withOpacity(0.05);
    const spacing = 50.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw rotating circles
    final center = Offset(size.width / 2, size.height / 2);
    paint.color = AppTheme.primaryBlue.withOpacity(0.03 * glowIntensity);

    for (int i = 0; i < 3; i++) {
      final radius = 200.0 + i * 100;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation + i * 0.5);
      canvas.translate(-center.dx, -center.dy);
      canvas.drawCircle(center, radius, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PropertyAmenitiesAssignView extends StatefulWidget {
  final String propertyId;
  final String propertyName;
  const _PropertyAmenitiesAssignView(
      {required this.propertyId, required this.propertyName});

  @override
  State<_PropertyAmenitiesAssignView> createState() =>
      _PropertyAmenitiesAssignViewState();
}

class _PropertyAmenitiesAssignViewState
    extends State<_PropertyAmenitiesAssignView> {
  bool _loading = true;
  String? _error;
  List<dynamic> _allAmenities = [];
  Set<String> _assignedAmenityIds = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final amenitiesBloc = context.read<ap_am_bloc.AmenitiesBloc>();
      // request both: all amenities and property amenities
      amenitiesBloc.add(
          const ap_am_bloc.LoadAmenitiesEvent(pageNumber: 1, pageSize: 100));
      final repo = di.sl<ap_repo.AmenitiesRepository>();
      final propertyAmenitiesEither =
          await repo.getPropertyAmenities(widget.propertyId);
      propertyAmenitiesEither.fold((f) {
        _error = f.message;
      }, (list) {
        _assignedAmenityIds = list.map((a) => a.id).toSet();
      });
      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        width: 640,
        height: 520,
        child: Center(
            child: LoadingWidget(
                type: LoadingType.futuristic,
                message: 'جاري تحميل المرافق...')),
      );
    }
    if (_error != null) {
      return SizedBox(
        width: 640,
        height: 520,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    color: AppTheme.error, size: 40),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style:
                      AppTextStyles.bodyMedium.copyWith(color: AppTheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: 720,
      constraints: const BoxConstraints(maxHeight: 640),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppTheme.primaryPurple.withOpacity(0.1),
          AppTheme.primaryBlue.withOpacity(0.05)
        ]),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10)),
            child:
                const Icon(Icons.link_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تعيين مرافق للعقار',
                    style: AppTextStyles.bodyLarge.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.bold)),
                Text(widget.propertyName,
                    style: AppTextStyles.caption
                        .copyWith(color: AppTheme.textMuted)),
              ],
            ),
          ),
          IconButton(
            onPressed: _submitting ? null : () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<ap_am_bloc.AmenitiesBloc, ap_am_bloc.AmenitiesState>(
      builder: (context, state) {
        if (state is ap_am_bloc.AmenitiesLoaded) {
          _allAmenities = state.amenities;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.amenities.length,
            itemBuilder: (context, index) {
              final amenity = state.amenities[index];
              final selected = _assignedAmenityIds.contains(amenity.id);
              return _buildAmenityRow(amenity, selected);
            },
          );
        }
        if (state is ap_am_bloc.AmenitiesError) {
          return Center(
              child: Text(state.message,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppTheme.error)));
        }
        return const Center(
            child: LoadingWidget(
                type: LoadingType.futuristic, message: 'جاري التحميل...'));
      },
    );
  }

  Widget _buildAmenityRow(dynamic amenity, bool selected) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: selected
                ? AppTheme.primaryPurple.withOpacity(0.3)
                : AppTheme.darkBorder.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: selected ? AppTheme.primaryPurple : AppTheme.textMuted,
              size: 18),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(amenity.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textWhite, fontWeight: FontWeight.w600)),
              if ((amenity.description as String?)?.isNotEmpty == true)
                Text(amenity.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption
                        .copyWith(color: AppTheme.textMuted)),
            ]),
          ),
          Switch(
            value: selected,
            onChanged:
                _submitting ? null : (val) => _toggleAmenity(amenity.id, val),
            activeThumbColor: AppTheme.primaryPurple,
          )
        ],
      ),
    );
  }

  Future<void> _toggleAmenity(String amenityId, bool enable) async {
    setState(() => _submitting = true);
    try {
      final repo = di.sl<ap_repo.AmenitiesRepository>();
      if (enable) {
        final res = await repo.assignAmenityToProperty(
            amenityId, widget.propertyId, {'isAvailable': true});
        res.fold((f) => _showError(f.message),
            (_) => _assignedAmenityIds.add(amenityId));
      } else {
        final res = await repo.unassignAmenityFromProperty(
            amenityId, widget.propertyId);
        res.fold((f) => _showError(f.message),
            (_) => _assignedAmenityIds.remove(amenityId));
      }
      setState(() {});
    } finally {
      setState(() => _submitting = false);
    }
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppTheme.darkSurface.withOpacity(0.6),
          AppTheme.darkSurface.withOpacity(0.3)
        ]),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('عدد المرافق المعينة: ${_assignedAmenityIds.length}',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppTheme.textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: _submitting ? null : () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('تم'),
          )
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppTheme.error));
  }
}
