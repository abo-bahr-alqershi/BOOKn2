// lib/features/admin_services/presentation/pages/admin_services_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/empty_widget.dart';
import '../../domain/entities/service.dart';
import '../../domain/entities/money.dart';
import '../../domain/entities/pricing_model.dart';
import '../bloc/services_bloc.dart';
import '../bloc/services_event.dart';
import '../bloc/services_state.dart';
import '../widgets/futuristic_service_card.dart';
import '../widgets/futuristic_services_table.dart';
import 'create_service_page.dart';
import '../widgets/service_icon_picker.dart';
import '../widgets/service_details_dialog.dart';
import '../widgets/service_stats_row.dart';
import '../widgets/service_filters_widget.dart';
import '../../../../services/local_storage_service.dart';
import '../../../../core/constants/storage_constants.dart';
import '../../../../injection_container.dart' as di;
import '../utils/service_icons.dart';

/// 🎯 Ultra Premium Admin Services Page
class AdminServicesPage extends StatefulWidget {
  const AdminServicesPage({super.key});

  @override
  State<AdminServicesPage> createState() => _AdminServicesPageState();
}

class _AdminServicesPageState extends State<AdminServicesPage>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _backgroundAnimationController;
  late AnimationController _particlesAnimationController;
  late AnimationController _glowAnimationController;
  late AnimationController _cardEntranceController;

  // Animations
  late Animation<double> _backgroundRotationAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _cardEntranceAnimation;

  // Particles
  final List<_Particle> _particles = [];

  // View Mode
  bool _isGridView = false;
  bool _showFilters = false;

  // Selected Property
  String? _selectedPropertyId;
  String? _selectedPropertyName;
  bool _hidePropertySelector = false;

  // Search
  String _searchQuery = '';

  // Scroll
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateParticles();
    _loadRoleAndContextThenData();
    _scrollController.addListener(_onScroll);
  }

  void _initializeAnimations() {
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _particlesAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _glowAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _cardEntranceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _backgroundRotationAnimation = Tween<double>(
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
      parent: _glowAnimationController,
      curve: Curves.easeInOut,
    ));

    _cardEntranceAnimation = CurvedAnimation(
      parent: _cardEntranceController,
      curve: Curves.easeOutCubic,
    );

    // Start entrance animation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _cardEntranceController.forward();
      }
    });
  }

  void _generateParticles() {
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle());
    }
  }

  void _loadInitialData() {
    if (_selectedPropertyId != null && _selectedPropertyId!.isNotEmpty) {
      context
          .read<ServicesBloc>()
          .add(LoadServicesEvent(propertyId: _selectedPropertyId));
    } else {
      context.read<ServicesBloc>().add(const LoadServicesEvent(
          serviceType: 'all', pageNumber: 1, pageSize: 20));
    }
  }

  void _loadRoleAndContextThenData() {
    try {
      final storage = di.sl<LocalStorageService>();
      final role =
          storage.getData(StorageConstants.accountRole)?.toString() ?? '';
      final isAdmin = role.toLowerCase() == 'admin';
      _hidePropertySelector = !isAdmin;
      if (!isAdmin) {
        final pid =
            storage.getData(StorageConstants.propertyId)?.toString() ?? '';
        final pname =
            storage.getData(StorageConstants.propertyName)?.toString() ?? '';
        if (pid.isNotEmpty) {
          _selectedPropertyId = pid;
          _selectedPropertyName = pname.isNotEmpty ? pname : null;
          // trigger selection in bloc
          context
              .read<ServicesBloc>()
              .add(SelectPropertyEvent(_selectedPropertyId));
        }
      }
    } catch (_) {}
    _loadInitialData();
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _particlesAnimationController.dispose();
    _glowAnimationController.dispose();
    _cardEntranceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent * 0.9) {
      final current = context.read<ServicesBloc>().state;
      if (current is ServicesLoaded &&
          current.paginatedServices != null &&
          current.paginatedServices!.hasNextPage &&
          !current.isLoadingMore) {
        context.read<ServicesBloc>().add(const LoadMoreServicesEvent());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1200;

    return BlocListener<ServicesBloc, ServicesState>(
      listenWhen: (previous, current) {
        // Restart entrance animation only on initial/full loads, not on load-more merges
        if (previous is ServicesLoaded && current is ServicesLoaded) {
          final wasLoadingMore = previous.isLoadingMore;
          final prevCount = previous.services.length;
          final currCount = current.services.length;
          // If previous was loadingMore and now finished with more items, this is pagination → do not restart
          if (wasLoadingMore && currCount > prevCount)
            return true; // allow listener to run, but we will not restart
          // Allow listener for other transitions too
          return true;
        }
        return true;
      },
      listener: (context, state) {
        if (state is ServicesDeleting) {
          _showDeletingDialog();
        } else if (state is ServicesDeleteFailed) {
          _dismissDeletingDialog();
          _showSnack(state.message, AppTheme.error);
        } else if (state is ServicesDeleteSuccess) {
          _dismissDeletingDialog();
          _showSnack('تم حذف الخدمة بنجاح', AppTheme.success);
        } else if (state is ServicesLoaded) {
          // Only restart entrance animation if this is not a pagination append
          // We infer pagination by comparing with last frame via animation status and item growth handled in listenWhen
          // Conservative approach: restart only when list shrank (filter/search/property) or was empty before
          // Note: We don't have direct access to previous state items here; rely on animation state as proxy
          if (!_cardEntranceController.isAnimating &&
              (_cardEntranceController.value == 0.0 ||
                  _cardEntranceController.value == 1.0)) {
            // Do not force reset on load-more; the animation remains as-is for smoothness
            // Keep initial entrance for first load
            if (_cardEntranceController.value == 0.0) {
              _cardEntranceController.forward();
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Stack(
          children: [
            // Animated Background
            _buildAnimatedBackground(),

            // Floating Particles
            _buildFloatingParticles(),

            // Main Content
            RefreshIndicator(
              onRefresh: () async {
                if (_selectedPropertyId != null) {
                  context
                      .read<ServicesBloc>()
                      .add(LoadServicesEvent(propertyId: _selectedPropertyId));
                } else {
                  context.read<ServicesBloc>().add(const LoadServicesEvent(
                      serviceType: 'all', pageNumber: 1, pageSize: 20));
                }
              },
              color: AppTheme.primaryBlue,
              backgroundColor: AppTheme.darkCard,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  // Premium App Bar
                  _buildSliverAppBar(isMobile),

                  // Stats Cards
                  SliverToBoxAdapter(
                    child: _buildStatsCards(),
                  ),

                  // Filters
                  if (_showFilters)
                    SliverToBoxAdapter(
                      child: _buildFilters(),
                    ),

                  // Content
                  SliverPadding(
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    sliver: _buildContent(isMobile, isTablet),
                  ),

                  // Futuristic bottom loader (same style as payments)
                  BlocBuilder<ServicesBloc, ServicesState>(
                    builder: (context, state) {
                      if (state is ServicesLoaded && state.isLoadingMore) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: LoadingWidget(
                                  type: LoadingType.futuristic,
                                  message: 'جاري تحميل المزيد...'),
                            ),
                          ),
                        );
                      }
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    },
                  ),

                  // Bottom padding
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool isMobile) {
    return SliverAppBar(
      expandedHeight: isMobile ? 140 : 160,
      floating: true,
      pinned: true,
      centerTitle: false,
      backgroundColor: AppTheme.darkBackground.withOpacity(0.95),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsetsDirectional.only(
          start: isMobile ? 16 : 24,
          bottom: 16,
        ),
        title: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue
                        .withOpacity(0.1 * _glowAnimation.value),
                    AppTheme.primaryPurple
                        .withOpacity(0.05 * _glowAnimation.value),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryBlue
                      .withOpacity(0.2 * _glowAnimation.value),
                  width: 1,
                ),
              ),
              child: Text(
                'إدارة الخدمات',
                style: AppTextStyles.heading2.copyWith(
                  color: AppTheme.textWhite,
                  fontSize: isMobile ? 18 : 20,
                  shadows: [
                    Shadow(
                      color: AppTheme.primaryBlue.withOpacity(0.5),
                      blurRadius: 15,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        background: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.15),
                    AppTheme.primaryPurple.withOpacity(0.08),
                    AppTheme.darkBackground.withOpacity(0.95),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _AppBarPatternPainter(
                  animation: _backgroundRotationAnimation.value,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: _buildAppBarActions(context),
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    return [
      _buildAppBarIconAction(
        icon: CupertinoIcons.plus,
        onPressed: _navigateToCreatePage,
      ),
      _buildAppBarIconAction(
        icon: _isGridView
            ? CupertinoIcons.list_bullet
            : CupertinoIcons.square_grid_2x2,
        onPressed: () => setState(() => _isGridView = !_isGridView),
      ),
      _buildAppBarIconAction(
        icon: _showFilters
            ? CupertinoIcons.xmark
            : CupertinoIcons.slider_horizontal_3,
        onPressed: () => setState(() => _showFilters = !_showFilters),
      ),
      const SizedBox(width: 8),
    ];
  }

  Widget _buildAppBarIconAction({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: AppTheme.textWhite,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundRotationAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkBackground,
                AppTheme.darkBackground2.withOpacity(0.95),
                AppTheme.darkBackground3.withOpacity(0.9),
              ],
            ),
          ),
          child: CustomPaint(
            painter: _GridPatternPainter(
              rotation: _backgroundRotationAnimation.value * 0.1,
              opacity: 0.03,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: _particlesAnimationController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            animationValue: _particlesAnimationController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildStatsCards() {
    return BlocBuilder<ServicesBloc, ServicesState>(
      builder: (context, state) {
        if (state is ServicesLoaded) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: ServiceStatsRow(
              totalServices: state.totalServices,
              paidServices: state.paidServices,
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFilters() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ServiceFiltersWidget(
        selectedPropertyId: _selectedPropertyId,
        selectedPropertyName: _selectedPropertyName,
        onPropertyChanged: (propertyId) {
          setState(() => _selectedPropertyId = propertyId);
          context.read<ServicesBloc>().add(
                SelectPropertyEvent(propertyId),
              );
        },
        onPropertyFieldTap: _onPropertyFieldTap,
        onClearProperty: () {
          setState(() {
            _selectedPropertyId = null;
            _selectedPropertyName = null;
          });
          context.read<ServicesBloc>().add(const SelectPropertyEvent(null));
        },
        searchQuery: _searchQuery,
        onSearchChanged: (query) {
          setState(() => _searchQuery = query);
          context.read<ServicesBloc>().add(
                SearchServicesEvent(query),
              );
        },
        selectedPricingModel: null,
        onPricingModelChanged: (model) {
          // TODO: Implement pricing model filter
        },
        minPrice: null,
        maxPrice: null,
        onMinPriceChanged: (price) {
          // TODO: Implement min price filter
        },
        onMaxPriceChanged: (price) {
          // TODO: Implement max price filter
        },
        showOnlyFree: null,
        onShowOnlyFreeChanged: (value) {
          // TODO: Implement show only free filter
        },
        hidePropertySelector: _hidePropertySelector,
      ),
    );
  }

  Widget _buildContent(bool isMobile, bool isTablet) {
    return BlocBuilder<ServicesBloc, ServicesState>(
      builder: (context, state) {
        if (state is ServicesLoading) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: LoadingWidget(
                type: LoadingType.futuristic,
              ),
            ),
          );
        }

        if (state is ServicesError) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CustomErrorWidget(
                message: state.message,
                onRetry: _loadInitialData,
              ),
            ),
          );
        }

        if (state is ServicesLoaded) {
          if (state.services.isEmpty) {
            return const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: EmptyWidget(
                  message: 'لا توجد خدمات حالياً',
                  // icon: Icons.miscellaneous_services_rounded,
                  // actionLabel: 'إضافة خدمة',
                  // onAction: _navigateToCreatePage,
                ),
              ),
            );
          }

          return _isGridView
              ? _buildGridView(state.services, state, isMobile, isTablet)
              : _buildListView(state.services, state);
        }

        return const SliverToBoxAdapter(
          child: SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildGridView(
    List<Service> services,
    ServicesLoaded state,
    bool isMobile,
    bool isTablet,
  ) {
    // Determine grid layout based on screen size
    int crossAxisCount;
    double childAspectRatio;

    if (isMobile) {
      crossAxisCount = 1; // Single column for mobile
      childAspectRatio = 2.2;
    } else if (isTablet) {
      crossAxisCount = 2;
      childAspectRatio = 1.8;
    } else {
      crossAxisCount = 3;
      childAspectRatio = 1.5;
    }

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index < services.length) {
            final service = services[index];
            return AnimatedBuilder(
              animation: _cardEntranceAnimation,
              builder: (context, child) {
                // Map global animation [0..1] into per-item interval so that at 1.0 all cards reach full opacity
                final v = _cardEntranceAnimation.value; // 0..1
                final start = (index % 10) * 0.08; // stagger start
                final end =
                    (start + 0.6).clamp(0.0, 1.0); // duration for each item
                double adjustedValue =
                    ((v - start) / (end - start)).clamp(0.0, 1.0);
                if (_cardEntranceController.status ==
                    AnimationStatus.completed) {
                  adjustedValue = 1.0;
                }

                return Transform.translate(
                  offset: Offset(0, 12 * (1 - adjustedValue)),
                  child: Opacity(
                    opacity: 1.0,
                    child: FuturisticServiceCard(
                      service: service,
                      onTap: () => _showServiceDetails(service),
                      onEdit: () => _showEditDialog(service),
                      onDelete: () => _confirmDelete(service),
                    ),
                  ),
                );
              },
            );
          }

          return null;
        },
        childCount: services.length,
      ),
    );
  }

  Widget _buildListView(List<Service> services, ServicesLoaded state) {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _cardEntranceAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - _cardEntranceAnimation.value)),
            child: Opacity(
              opacity: _cardEntranceAnimation.value,
              child: FuturisticServicesTable(
                services: services,
                onServiceTap: _showServiceDetails,
                onEdit: _showEditDialog,
                onDelete: _confirmDelete,
                // لا تنشئ Controller في كل بناء لتجنب الوميض؛ اترك الودجت يمتلكه داخلياً
                controller: null,
                embeddedInScrollView: true,
                onLoadMore: state.paginatedServices?.hasNextPage == true
                    ? () => context
                        .read<ServicesBloc>()
                        .add(const LoadMoreServicesEvent())
                    : null,
                hasReachedMax: !(state.paginatedServices?.hasNextPage == true),
                isLoadingMore: state.isLoadingMore,
              ),
            ),
          );
        },
      ),
    );
  }

  // Removed FAB: Add action moved to AppBar

  bool _isDeleting = false;

  void _showDeletingDialog() {
    if (_isDeleting) return;
    _isDeleting = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => const Center(
        child: LoadingWidget(
          type: LoadingType.futuristic,
          message: 'جاري حذف الخدمة...',
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

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.9),
                color.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                color == AppTheme.success
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Future<void> _navigateToCreatePage() async {
    HapticFeedback.mediumImpact();
    final result = await context.push('/admin/services/create',
        extra: {'propertyId': _selectedPropertyId});
    if (result is Map && result['refresh'] == true) {
      final pid = (result['propertyId'] as String?) ?? _selectedPropertyId;
      setState(() => _selectedPropertyId = pid);
      if (pid != null) {
        context.read<ServicesBloc>().add(LoadServicesEvent(propertyId: pid));
      } else {
        context.read<ServicesBloc>().add(const LoadServicesEvent(
            serviceType: 'all', pageNumber: 1, pageSize: 20));
      }
    }
  }

  void _onPropertyFieldTap() {
    HapticFeedback.lightImpact();
    context.push('/helpers/search/properties', extra: {
      'allowMultiSelect': false,
      'onPropertySelected': (dynamic property) {
        setState(() {
          _selectedPropertyId = property.id as String?;
          _selectedPropertyName = property.name as String?;
        });
        context
            .read<ServicesBloc>()
            .add(SelectPropertyEvent(_selectedPropertyId));
      },
    });
  }

  Future<void> _showEditDialog(Service service) async {
    HapticFeedback.lightImpact();
    final result = await context.push('/admin/services/${service.id}/edit',
        extra: service);
    if (result is Map && result['refresh'] == true) {
      if (_selectedPropertyId != null) {
        context
            .read<ServicesBloc>()
            .add(LoadServicesEvent(propertyId: _selectedPropertyId));
      } else {
        context.read<ServicesBloc>().add(const LoadServicesEvent(
            serviceType: 'all', pageNumber: 1, pageSize: 20));
      }
    }
  }

  Future<void> _showServiceDetails(Service service) async {
    HapticFeedback.lightImpact();
    context.read<ServicesBloc>().add(LoadServiceDetailsEvent(service.id));
    await showDialog(
      context: context,
      builder: (context) => ServiceDetailsDialog(service: service),
    );
    if (!mounted) return;
    if (_selectedPropertyId != null) {
      context
          .read<ServicesBloc>()
          .add(LoadServicesEvent(propertyId: _selectedPropertyId));
    } else {
      context.read<ServicesBloc>().add(const LoadServicesEvent(
          serviceType: 'all', pageNumber: 1, pageSize: 20));
    }
  }

  void _confirmDelete(Service service) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogCtx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkCard.withOpacity(0.95),
                  AppTheme.darkCard.withOpacity(0.85),
                ],
              ),
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
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.error.withOpacity(0.2),
                        AppTheme.error.withOpacity(0.1),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.error.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: AppTheme.error,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'حذف الخدمة',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'هل أنت متأكد من حذف "${service.name}"؟',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.error.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    'لا يمكن التراجع عن هذا الإجراء',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor:
                              AppTheme.darkSurface.withOpacity(0.3),
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
                          Navigator.pop(dialogCtx);
                          context.read<ServicesBloc>().add(
                                DeleteServiceEvent(service.id),
                              );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.delete_outline,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'حذف',
                              style: AppTextStyles.buttonMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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

// Enhanced Particle Model
class _Particle {
  late double x, y, z;
  late double vx, vy;
  late double radius;
  late double opacity;
  late Color color;
  late double lifespan;

  _Particle() {
    reset();
  }

  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    z = math.Random().nextDouble();
    vx = (math.Random().nextDouble() - 0.5) * 0.002;
    vy = (math.Random().nextDouble() - 0.5) * 0.002;
    radius = math.Random().nextDouble() * 3 + 0.5;
    opacity = math.Random().nextDouble() * 0.4 + 0.1;
    lifespan = math.Random().nextDouble();

    final colors = [
      AppTheme.primaryBlue,
      AppTheme.primaryPurple,
      AppTheme.primaryCyan,
      AppTheme.primaryViolet,
    ];
    color = colors[math.Random().nextInt(colors.length)];
  }

  void update() {
    x += vx;
    y += vy;
    lifespan -= 0.01;

    if (x < -0.1 || x > 1.1) vx = -vx;
    if (y < -0.1 || y > 1.1) vy = -vy;

    if (lifespan <= 0) {
      reset();
    }
  }
}

// Enhanced Particle Painter
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
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
        ..color =
            particle.color.withOpacity(particle.opacity * particle.lifespan)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          3,
        );

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.radius * (1 + 0.2 * math.sin(animationValue * 2 * math.pi)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Enhanced Grid Pattern Painter
class _GridPatternPainter extends CustomPainter {
  final double rotation;
  final double opacity;

  _GridPatternPainter({
    required this.rotation,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotation);
    canvas.translate(-size.width / 2, -size.height / 2);

    const spacing = 40.0;

    // Draw hexagonal grid pattern
    for (double x = -spacing; x < size.width + spacing; x += spacing * 1.5) {
      for (double y = -spacing; y < size.height + spacing; y += spacing) {
        final offset =
            (x / (spacing * 1.5)).floor() % 2 == 0 ? 0.0 : spacing / 2;

        paint.shader = RadialGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(opacity),
            AppTheme.primaryPurple.withOpacity(opacity * 0.5),
            Colors.transparent,
          ],
          radius: 0.5,
        ).createShader(Rect.fromCircle(
          center: Offset(x, y + offset),
          radius: spacing / 2,
        ));

        _drawHexagon(canvas, Offset(x, y + offset), spacing / 3, paint);
      }
    }

    canvas.restore();
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// App Bar Pattern Painter
class _AppBarPatternPainter extends CustomPainter {
  final double animation;

  _AppBarPatternPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw animated wave pattern
    for (int i = 0; i < 5; i++) {
      paint.color = AppTheme.primaryBlue.withOpacity(0.05 - i * 0.01);

      final path = Path();
      path.moveTo(0, size.height * 0.5);

      for (double x = 0; x <= size.width; x += 10) {
        final y = size.height * 0.5 +
            math.sin((x / size.width * 4 * math.pi) + animation + i * 0.5) *
                (20 + i * 5);
        path.lineTo(x, y);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
