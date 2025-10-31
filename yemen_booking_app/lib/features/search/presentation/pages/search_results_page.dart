// lib/features/search/presentation/pages/search_results_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:yemen_booking_app/injection_container.dart';
import 'package:yemen_booking_app/services/local_storage_service.dart';
import 'package:yemen_booking_app/core/constants/storage_constants.dart';
import 'package:yemen_booking_app/features/favorites/domain/repositories/favorites_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/search_result.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';
import '../widgets/search_result_list_widget.dart';
import '../widgets/search_result_compact_widget.dart';

class SearchResultsPage extends StatefulWidget {
  final List<SearchResult> initialResults;
  final Map<String, dynamic> appliedFilters;

  const SearchResultsPage({
    super.key,
    required this.initialResults,
    required this.appliedFilters,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  ViewMode _viewMode = ViewMode.list;
  
  // Advanced Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _rotationController;
  late AnimationController _waveController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _waveAnimation;
  
  // UI State
  bool _isHeaderExpanded = false;
  double _scrollOffset = 0;
  final List<_NeonParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeAnimations();
    _generateParticles();
    _dispatchInitialSearch();
  }

  Future<void> _onToggleFavorite(SearchResult result) async {
    try {
      final uid = (sl<LocalStorageService>().getData(StorageConstants.userId) ?? '').toString();
      if (uid.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يجب تسجيل الدخول لإضافة إلى المفضلة')),
        );
        return;
      }
      final repo = sl<FavoritesRepository>();
      final status = await repo.checkFavoriteStatus(propertyId: result.id, userId: uid);
      await status.fold(
        // On failure, optimistically try to add
        (_) async {
          await repo.addToFavorites(propertyId: result.id, userId: uid);
        },
        (isFav) async {
          if (isFav) {
            await repo.removeFromFavorites(propertyId: result.id, userId: uid);
          } else {
            await repo.addToFavorites(propertyId: result.id, userId: uid);
          }
        },
      );
    } catch (_) {
      // Ignore errors here to keep UI responsive. Detailed errors are handled in dedicated flows.
    }
  }
  
  void _initializeAnimations() {
    // Fade Animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutQuart,
    ));
    
    // Slide Animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutExpo,
    ));
    
    // Pulse Animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Shimmer Animation
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(_shimmerController);
    
    // Rotation Animation
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotationController);
    
    // Wave Animation
    _waveController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    _waveAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  void _dispatchInitialSearch() {
    // Ensure bloc has a canonical page-1 state so infinite scroll works reliably
    final filters = widget.appliedFilters;
    String? _s<T>(String key) => filters[key] is String ? filters[key] as String : null;
    double? _d(String key) {
      final v = filters[key];
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) {
        final p = double.tryParse(v);
        return p;
      }
      return null;
    }
    int? _i(String key) {
      final v = filters[key];
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }
    DateTime? _dt(String key) {
      final v = filters[key];
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String) {
        try { return DateTime.parse(v); } catch (_) { return null; }
      }
      return null;
    }
    List<String>? _ls(String key) {
      final v = filters[key];
      if (v == null) return null;
      if (v is List) return v.whereType<String>().toList();
      return null;
    }
    Map<String, dynamic>? _map(String key) {
      final v = filters[key];
      if (v == null) return null;
      if (v is Map<String, dynamic>) return v;
      return null;
    }

    context.read<SearchBloc>().add(SearchPropertiesEvent(
      searchTerm: _s('searchTerm'),
      city: _s('city'),
      propertyTypeId: _s('propertyTypeId'),
      minPrice: _d('minPrice'),
      maxPrice: _d('maxPrice'),
      minStarRating: _i('minStarRating'),
      requiredAmenities: _ls('requiredAmenities'),
      unitTypeId: _s('unitTypeId'),
      serviceIds: _ls('serviceIds'),
      dynamicFieldFilters: _map('dynamicFieldFilters'),
      checkIn: _dt('checkIn'),
      checkOut: _dt('checkOut'),
      guestsCount: _i('guestsCount'),
      latitude: _d('latitude'),
      longitude: _d('longitude'),
      radiusKm: _d('radiusKm'),
      sortBy: _s('sortBy'),
      pageNumber: 1,
      pageSize: 20,
    ));
  }
  
  void _generateParticles() {
    for (int i = 0; i < 15; i++) {
      _particles.add(_NeonParticle());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _rotationController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
      _isHeaderExpanded = _scrollOffset < 50;
    });
    
    if (_isBottom) {
      context.read<SearchBloc>().add(const LoadMoreSearchResultsEvent());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          // Ultra-futuristic animated background
          _buildFuturisticBackground(),
          
          // Floating neon particles
          _buildNeonParticles(),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildFuturisticAppBar(),
                Expanded(
                  child: BlocBuilder<SearchBloc, SearchState>(
                    builder: (context, state) {
                      if (state is SearchCombinedState) {
                        final nested = state.searchResultsState;
                        if (nested is SearchLoading) {
                          return _buildFuturisticLoadingState();
                        }
                        if (nested is SearchLoadingMore) {
                          final items = nested.currentResults.items;
                          return _buildResults(items);
                        }
                        if (nested is SearchSuccess) {
                          return _buildResults(nested.searchResults.items);
                        }
                        if (nested is SearchError) {
                          return _buildFuturisticErrorState(nested.message);
                        }
                      }
                      return _buildResults(widget.initialResults);
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Floating action buttons
          _buildFloatingActions(),
        ],
      ),
    );
  }

  Widget _buildFuturisticBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationAnimation, _waveAnimation]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkBackground,
                AppTheme.darkBackground2,
                AppTheme.darkBackground3,
              ],
            ),
          ),
          child: CustomPaint(
            painter: _UltraBackgroundPainter(
              rotation: _rotationAnimation.value,
              wave: _waveAnimation.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
  
  Widget _buildNeonParticles() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return CustomPaint(
          painter: _NeonParticlePainter(
            particles: _particles,
            animationValue: _rotationController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildFuturisticAppBar() {
    final headerOpacity = 1.0 - (_scrollOffset / 100).clamp(0.0, 0.3);
    final headerScale = 1.0 - (_scrollOffset / 200).clamp(0.0, 0.1);
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              transform: Matrix4.identity()
                ..scale(headerScale),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.darkCard.withOpacity(0.95 * headerOpacity),
                    AppTheme.darkCard.withOpacity(0.7 * headerOpacity),
                    AppTheme.darkCard.withOpacity(0.0),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.2 * _pulseAnimation.value),
                    blurRadius: 20 * _pulseAnimation.value,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCompactHeader(),
                      if (widget.appliedFilters.isNotEmpty)
                        _buildActiveFiltersChips(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildCompactHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Ultra-modern back button
          _buildNeonIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            size: 36,
          ),
          
          const SizedBox(width: 12),
          
          // Animated title with count
          Expanded(
            child: AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          begin: Alignment(_shimmerAnimation.value - 1, 0),
                          end: Alignment(_shimmerAnimation.value, 0),
                          colors: [
                            AppTheme.primaryCyan,
                            AppTheme.primaryBlue,
                            AppTheme.primaryPurple,
                            AppTheme.primaryViolet,
                            AppTheme.primaryCyan,
                          ],
                        ).createShader(bounds);
                      },
                      child: Text(
                        'نتائج البحث',
                        style: AppTextStyles.heading3.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    BlocBuilder<SearchBloc, SearchState>(
                      builder: (context, state) {
                        int count = widget.initialResults.length;
                        if (state is SearchCombinedState && 
                            state.searchResultsState is SearchSuccess) {
                          count = (state.searchResultsState as SearchSuccess)
                              .searchResults.items.length;
                        }
                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.neonBlue.withOpacity(0.2),
                                    AppTheme.neonPurple.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.neonBlue.withOpacity(0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                '$count',
                                style: AppTextStyles.overline.copyWith(
                                  color: AppTheme.neonBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'نتيجة',
                              style: AppTextStyles.caption.copyWith(
                                color: AppTheme.textMuted.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          
          // View mode toggle with neon effect
          _buildViewModeSelector(),
          
          const SizedBox(width: 8),
          
          // Filter button
          _buildNeonIconButton(
            icon: Icons.tune_rounded,
            onTap: () {
              HapticFeedback.mediumImpact();
              // Open filters
            },
            size: 36,
            hasNotification: widget.appliedFilters.isNotEmpty,
          ),
        ],
      ),
    );
  }
  
  Widget _buildNeonIconButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 40,
    bool hasNotification = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Stack(
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.darkCard.withOpacity(0.8),
                      AppTheme.darkCard.withOpacity(0.5),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(
                        0.2 * _pulseAnimation.value
                      ),
                      blurRadius: 15 * _pulseAnimation.value,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: size * 0.5,
                  color: AppTheme.textWhite,
                ),
              ),
              
              if (hasNotification)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: AppTheme.neonGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.neonPurple,
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildViewModeSelector() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.6),
            AppTheme.darkCard.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewButton(
            icon: Icons.view_list_rounded,
            isSelected: _viewMode == ViewMode.list,
            onTap: () => setState(() => _viewMode = ViewMode.list),
          ),
          Container(
            width: 0.5,
            height: 20,
            color: AppTheme.darkBorder.withOpacity(0.3),
          ),
          _buildViewButton(
            icon: Icons.view_compact_rounded,
            isSelected: _viewMode == ViewMode.grid,
            onTap: () => setState(() => _viewMode = ViewMode.grid),
          ),
        ],
      ),
    );
  }
  
  Widget _buildViewButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: isSelected ? AppTheme.primaryGradient : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isSelected 
                ? Colors.white 
                : AppTheme.textMuted.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFiltersChips() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: widget.appliedFilters.isEmpty ? 0 : 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: widget.appliedFilters.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(left: 6),
            child: _buildFilterChip(entry.key, entry.value),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildFilterChip(String key, dynamic value) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue.withOpacity(0.15),
                AppTheme.primaryPurple.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(
                0.3 + (0.1 * _pulseAnimation.value)
              ),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getFilterLabel(key, value),
                style: AppTextStyles.overline.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Remove filter
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child:  Icon(
                    Icons.close_rounded,
                    size: 10,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildResults(List<SearchResult> results) {
    if (results.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            // Refresh results
          },
          color: AppTheme.neonBlue,
          backgroundColor: AppTheme.darkCard,
          child: _viewMode == ViewMode.list
              ? SearchResultListWidget(
                  results: results,
                  scrollController: _scrollController,
                  isLoadingMore: false,
                  onItemTap: (result) {
                    HapticFeedback.lightImpact();
                    context.push(
                      '/property/${result.id}',
                      extra: {'unitId': result.unitId},
                    );
                  },
                  onFavoriteToggle: (result) => _onToggleFavorite(result),
                )
              : SearchResultCompactWidget(
                  results: results,
                  scrollController: _scrollController,
                  isLoadingMore: false,
                  onItemTap: (result) {
                    HapticFeedback.lightImpact();
                    context.push(
                      '/property/${result.id}',
                      extra: {'unitId': result.unitId},
                    );
                  },
                  onFavoriteToggle: (result) => _onToggleFavorite(result),
                ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated empty state icon
          AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryBlue.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryBlue.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.search_off_rounded,
                      size: 50,
                      color: AppTheme.textMuted.withOpacity(0.5),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          ShaderMask(
            shaderCallback: (bounds) => 
                AppTheme.primaryGradient.createShader(bounds),
            child: Text(
              'لا توجد نتائج',
              style: AppTextStyles.heading2.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'جرب تغيير معايير البحث',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textMuted.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFloatingActions() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Map view button
              _buildFloatingActionButton(
                icon: Icons.map_rounded,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  // Open map view
                },
                gradient: LinearGradient(
                  colors: [AppTheme.neonBlue, AppTheme.neonPurple],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Sort button
              _buildFloatingActionButton(
                icon: Icons.sort_rounded,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  // Open sort options
                },
                gradient: LinearGradient(
                  colors: [AppTheme.primaryPurple, AppTheme.primaryViolet],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildFloatingActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required Gradient gradient,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: gradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
  
  Widget _buildFuturisticLoadingState() {
    return const Center(
      child: LoadingWidget(
        type: LoadingType.futuristic,
        message: 'جاري التحميل...',
      ),
    );
  }
  
  Widget _buildFuturisticErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppTheme.error.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 50,
              color: AppTheme.error,
            ),
          ),
          
          const SizedBox(height: 20),
          
          Text(
            'حدث خطأ',
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            message,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  String _getFilterLabel(String key, dynamic value) {
    switch (key) {
      case 'city':
        return value;
      case 'propertyTypeId':
        return 'نوع العقار';
      case 'minPrice':
      case 'maxPrice':
        return 'السعر';
      case 'minStarRating':
        return '$value نجوم';
      case 'checkIn':
      case 'checkOut':
        return 'التواريخ';
      default:
        return key;
    }
  }
}

// Ultra Background Painter
class _UltraBackgroundPainter extends CustomPainter {
  final double rotation;
  final double wave;
  
  _UltraBackgroundPainter({
    required this.rotation,
    required this.wave,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    // Draw rotating geometric patterns
    for (int i = 0; i < 3; i++) {
      paint.color = AppTheme.primaryBlue.withOpacity(0.05 - i * 0.01);
      
      canvas.save();
      canvas.translate(size.width / 2, size.height / 2);
      canvas.rotate(rotation + (i * math.pi / 3));
      
      final path = Path();
      for (int j = 0; j < 6; j++) {
        final angle = (j * math.pi * 2) / 6;
        final x = math.cos(angle) * (100 + i * 50);
        final y = math.sin(angle) * (100 + i * 50);
        
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Neon Particle Model
class _NeonParticle {
  late double x;
  late double y;
  late double vx;
  late double vy;
  late double radius;
  late double opacity;
  late Color color;
  late double glowRadius;
  
  _NeonParticle() {
    reset();
  }
  
  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    vx = (math.Random().nextDouble() - 0.5) * 0.001;
    vy = (math.Random().nextDouble() - 0.5) * 0.001;
    radius = math.Random().nextDouble() * 2 + 0.5;
    opacity = math.Random().nextDouble() * 0.4 + 0.1;
    glowRadius = math.Random().nextDouble() * 10 + 5;
    
    final colors = [
      AppTheme.neonBlue,
      AppTheme.neonPurple,
      AppTheme.neonGreen,
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

// Neon Particle Painter
class _NeonParticlePainter extends CustomPainter {
  final List<_NeonParticle> particles;
  final double animationValue;
  
  _NeonParticlePainter({
    required this.particles,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update();
      
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal, 
          particle.glowRadius,
        );
      
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

enum ViewMode { list, grid }