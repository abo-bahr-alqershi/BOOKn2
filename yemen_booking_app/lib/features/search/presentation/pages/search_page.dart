// lib/features/search/presentation/pages/search_page.dart (محسّنة ومُحدثة)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:async';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';
import '../widgets/search_input_widget.dart';
import '../widgets/filter_chips_widget.dart';
import '../widgets/sort_options_widget.dart';
import '../widgets/search_result_list_widget.dart';
import '../widgets/search_result_compact_widget.dart';
import 'search_filters_page.dart';
import 'search_results_map_page.dart';
import '../../domain/entities/search_navigation_params.dart';

class SearchPage extends StatefulWidget {
  final SearchNavigationParams? initialParams;
  const SearchPage({super.key, this.initialParams});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> 
    with TickerProviderStateMixin {
  Map<String, dynamic> _lastFilters = {};
  final ScrollController _scrollController = ScrollController();
  
  // Enhanced Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late AnimationController _rippleController;
  late AnimationController _morphController;
  late AnimationController _parallaxController;
  
  // Enhanced Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _morphAnimation;
  late Animation<double> _parallaxAnimation;
  
  // Ultra Particles System
  final List<_UltraParticle> _particles = [];
  final List<_FloatingOrb> _orbs = [];
  
  // View State
  ViewMode _viewMode = ViewMode.list;
  bool _isSearchExpanded = false;
  double _scrollOffset = 0;
  SearchSuccess? _lastSuccess;
  
  @override
  void initState() {
    super.initState();
    _initializeUltraAnimations();
    _generateUltraParticles();
    _setupScrollListener();
    context.read<SearchBloc>().add(const GetSearchFiltersEvent());
    _applyInitialParams();
  }
  
  void _initializeUltraAnimations() {
    // Fade Animation with curve
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutExpo,
    ));
    
    // Slide with elastic curve
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    // Scale with bounce
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.bounceOut,
    ));
    
    // Continuous glow
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(
      begin: 0.2,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    // Ripple effect
    _rippleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_rippleController);
    
    // Morph animation
    _morphController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _morphAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeInOut,
    ));
    
    // Parallax effect
    _parallaxController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    _parallaxAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(_parallaxController);
    
    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
    
    // Start all animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }
  
  void _generateUltraParticles() {
    // Generate particles
    for (int i = 0; i < 30; i++) {
      _particles.add(_UltraParticle());
    }
    
    // Generate floating orbs
    for (int i = 0; i < 5; i++) {
      _orbs.add(_FloatingOrb());
    }
  }
  
  void _setupScrollListener() {
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
        _isSearchExpanded = _scrollOffset < 50;
      });
      _onScroll();
    });
  }
  
  void _applyInitialParams() {
    if (widget.initialParams != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final params = widget.initialParams!;
        final initialFilters = <String, dynamic>{
          'propertyTypeId': params.propertyTypeId,
          'unitTypeId': params.unitTypeId,
          'dynamicFieldFilters': params.dynamicFieldFilters,
          'city': params.city,
          'searchTerm': params.searchTerm,
          'checkIn': params.checkIn,
          'checkOut': params.checkOut,
          'adults': params.adults,
          'children': params.children,
          'guestsCount': params.guestsCount,
        }..removeWhere((key, value) => value == null);

        context.read<SearchBloc>().add(UpdateSearchFiltersEvent(filters: initialFilters));
        if (initialFilters.isNotEmpty) {
          _lastFilters = initialFilters;
          _performSearch(initialFilters);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _rippleController.dispose();
    _morphController.dispose();
    _parallaxController.dispose();
    super.dispose();
  }

  void _onScroll() {
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
          _buildUltraAnimatedBackground(),
          
          // Floating particles system
          _buildUltraParticles(),
          
          // Floating orbs
          _buildFloatingOrbs(),
          
          // Main content with glass effect
          SafeArea(
            child: Column(
              children: [
                _buildUltraFuturisticHeader(),
                Expanded(
                  child: BlocBuilder<SearchBloc, SearchState>(
                    builder: (context, state) {
                      if (state is SearchCombinedState) {
                        final nested = state.searchResultsState;
                        if (nested is SearchSuccess) {
                          _lastSuccess = nested;
                          return _buildUltraResultsView(nested);
                        }
                        if (nested == null || nested is SearchInitial) {
                          if (_lastSuccess != null) {
                            return _buildUltraResultsView(_lastSuccess!);
                          }
                          return _buildUltraInitialView();
                        }
                        if (nested is SearchLoading) {
                          return _buildUltraLoadingView();
                        }
                        if (nested is SearchError) {
                          return _buildUltraErrorView(nested.message);
                        }
                        if (nested is SearchLoadingMore) {
                          return _buildUltraLoadingView();
                        }
                        return const SizedBox.shrink();
                      }
                      // Legacy state handling
                      if (state is SearchInitial) {
                        if (_lastSuccess != null) {
                          return _buildUltraResultsView(_lastSuccess!);
                        }
                        return _buildUltraInitialView();
                      } else if (state is SearchLoading) {
                        return _buildUltraLoadingView();
                      } else if (state is SearchSuccess) {
                        _lastSuccess = state;
                        return _buildUltraResultsView(state);
                      } else if (state is SearchError) {
                        return _buildUltraErrorView(state.message);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
          
        ],
      ),
    );
  }
  
  Widget _buildUltraAnimatedBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _morphAnimation,
        _parallaxAnimation,
        _rippleAnimation,
      ]),
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
                AppTheme.darkBackground3,
              ],
            ),
          ),
          child: CustomPaint(
            painter: _UltraFuturisticBackgroundPainter(
              morph: _morphAnimation.value,
              parallax: _parallaxAnimation.value,
              ripple: _rippleAnimation.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
  
  Widget _buildUltraParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: _UltraParticlePainter(
            particles: _particles,
            animationValue: _particleController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
  
  Widget _buildFloatingOrbs() {
    return AnimatedBuilder(
      animation: _morphController,
      builder: (context, child) {
        return CustomPaint(
          painter: _FloatingOrbPainter(
            orbs: _orbs,
            animationValue: _morphController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
  
  Widget _buildUltraFuturisticHeader() {
    final headerOpacity = 1.0 - (_scrollOffset / 150).clamp(0.0, 0.4);
    final headerBlur = (_scrollOffset / 10).clamp(0.0, 20.0);
    
    return AnimatedBuilder(
      animation: Listenable.merge([_glowAnimation, _rippleAnimation]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.darkCard.withOpacity(0.9 * headerOpacity),
                AppTheme.darkCard.withOpacity(0.6 * headerOpacity),
                AppTheme.darkCard.withOpacity(0.0),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(
                  _glowAnimation.value * 0.2
                ),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: headerBlur, sigmaY: headerBlur),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildUltraSearchBar(),
                  _buildUltraActiveFilters(),
                  _buildUltraResultsBar(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildUltraSearchBar() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: Row(
            children: [
              // Ultra-modern back button
              _buildNeonGlowButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                size: 36,
              ),
              
              const SizedBox(width: 10),
              
              // Enhanced search input
              Expanded(
                child: AnimatedScale(
                  scale: _scaleAnimation.value,
                  duration: const Duration(milliseconds: 300),
                  child: Hero(
                    tag: 'search_bar',
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.darkCard.withOpacity(0.6),
                            AppTheme.darkCard.withOpacity(0.4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withOpacity(0.2),
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.15),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: AppTheme.neonBlue.withOpacity(0.1),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: SearchInputWidget(
                        onSubmitted: (query) {
                          HapticFeedback.mediumImpact();
                          context.read<SearchBloc>().add(
                            SearchPropertiesEvent(searchTerm: query),
                          );
                        },
                        autofocus: false,
                        showSuggestions: true,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 10),
              
              // Ultra filter button
              _buildUltraFilterButton(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNeonGlowButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 40,
    Color? color,
  }) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  (color ?? AppTheme.primaryBlue).withOpacity(
                    _glowAnimation.value * 0.3
                  ),
                  Colors.transparent,
                ],
                radius: 1.5,
              ),
              shape: BoxShape.circle,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkCard.withOpacity(0.7),
                    AppTheme.darkCard.withOpacity(0.4),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: (color ?? AppTheme.primaryBlue).withOpacity(0.3),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (color ?? AppTheme.primaryBlue).withOpacity(
                      0.2 * _glowAnimation.value
                    ),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: color ?? AppTheme.textWhite,
                size: size * 0.5,
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildUltraFilterButton() {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        bool hasFilters = false;
        if (state is SearchCombinedState && 
            state.searchResultsState is SearchSuccess) {
          hasFilters = (state.searchResultsState as SearchSuccess)
              .currentFilters.isNotEmpty;
        } else if (state is SearchSuccess) {
          hasFilters = state.currentFilters.isNotEmpty;
        }
        
        return AnimatedBuilder(
          animation: _rippleAnimation,
          builder: (context, child) {
            return Stack(
              children: [
                // Ripple effect when has filters
                if (hasFilters)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.neonPurple.withOpacity(
                            0.3 * (1 - _rippleAnimation.value)
                          ),
                          width: 2 * _rippleAnimation.value,
                        ),
                      ),
                    ),
                  ),
                
                _buildNeonGlowButton(
                  icon: Icons.tune_rounded,
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _openFilters();
                  },
                  color: hasFilters ? AppTheme.neonPurple : null,
                  size: 36,
                ),
                
                // Notification dot
                if (hasFilters)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.neonPurple,
                                  AppTheme.neonBlue,
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.neonPurple,
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
  
  Widget _buildUltraActiveFilters() {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        Map<String, dynamic> currentFilters = {};
        if (state is SearchCombinedState && 
            state.searchResultsState is SearchSuccess) {
          currentFilters = (state.searchResultsState as SearchSuccess)
              .currentFilters;
        } else if (state is SearchSuccess) {
          currentFilters = state.currentFilters;
        }
        
        if (currentFilters.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          height: 47,
          margin: const EdgeInsets.only(bottom: 8),
          child: FilterChipsWidget(
            filters: currentFilters,
            onRemoveFilter: (key) {
              // منع حذف الحقول المطلوبة
              if (_isRequiredField(key, currentFilters)) {
                _showRequiredFieldError(key);
                return;
              }
              
              HapticFeedback.lightImpact();
              final updatedFilters = Map<String, dynamic>.from(
                currentFilters,
              )..remove(key);
              
              // إذا تم حذف نوع العقار، احذف نوع الوحدة والحقول الديناميكية
              if (key == 'propertyTypeId') {
                updatedFilters.remove('unitTypeId');
                updatedFilters.remove('dynamicFieldFilters');
              }
              
              // إذا تم حذف نوع الوحدة، احذف الحقول الديناميكية
              if (key == 'unitTypeId') {
                updatedFilters.remove('dynamicFieldFilters');
              }
              
              context.read<SearchBloc>().add(
                UpdateSearchFiltersEvent(filters: updatedFilters),
              );
              
              _performSearch(updatedFilters);
            },
            onClearAll: () {
              HapticFeedback.mediumImpact();
              
              // احتفظ بالحقول المطلوبة عند مسح الكل
              final requiredFields = _extractRequiredFields(currentFilters);
              
              if (requiredFields.isNotEmpty) {
                context.read<SearchBloc>().add(
                  UpdateSearchFiltersEvent(filters: requiredFields),
                );
                _performSearch(requiredFields);
              } else {
                context.read<SearchBloc>().add(const ClearSearchEvent());
              }
            },
          ),
        );

      },
    );
  }
  
  Widget _buildUltraResultsBar() {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        SearchSuccess? s;
        if (state is SearchCombinedState && 
            state.searchResultsState is SearchSuccess) {
          s = state.searchResultsState as SearchSuccess;
        } else if (state is SearchSuccess) {
          s = state;
        }
        
        if (s == null) {
          return const SizedBox.shrink();
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Results count with animation
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryBlue.withOpacity(0.15),
                            AppTheme.primaryPurple.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.neonBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${s?.searchResults.totalCount ?? 0}',
                            style: AppTextStyles.overline.copyWith(
                              color: AppTheme.neonBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'نتيجة',
                            style: AppTextStyles.overline.copyWith(
                              color: AppTheme.textMuted.withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              // Sort and view options
              Row(
                children: [
                  // Compact sort widget
                  Container(
                    height: 30,
                    child: SortOptionsWidget(
                      currentSort: s.currentFilters['sortBy'],
                      onSortChanged: (sortBy) {
                        HapticFeedback.selectionClick();
                        context.read<SearchBloc>().add(
                          UpdateSearchFiltersEvent(
                            filters: {'sortBy': sortBy},
                          ),
                        );
                        _performSearch({'sortBy': sortBy});
                      },
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // View mode toggle
                  _buildUltraViewModeToggle(s.viewMode),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildUltraViewModeToggle(ViewMode currentMode) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.7),
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
          _buildViewModeButton(
            icon: Icons.view_list_rounded,
            isSelected: currentMode == ViewMode.list,
            onTap: () => _changeViewMode(ViewMode.list),
          ),
          Container(
            width: 0.5,
            height: 16,
            color: AppTheme.darkBorder.withOpacity(0.2),
          ),
          _buildViewModeButton(
            icon: Icons.view_compact_rounded,
            isSelected: currentMode == ViewMode.grid,
            onTap: () => _changeViewMode(ViewMode.grid),
          ),
          Container(
            width: 0.5,
            height: 16,
            color: AppTheme.darkBorder.withOpacity(0.2),
          ),
          _buildViewModeButton(
            icon: Icons.map_rounded,
            isSelected: currentMode == ViewMode.map,
            onTap: () => _changeViewMode(ViewMode.map),
          ),
        ],
      ),
    );
  }
  
  Widget _buildViewModeButton({
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: isSelected
                ? AppTheme.primaryGradient
                : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isSelected
                ? AppTheme.textWhite
                : AppTheme.textMuted.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
  
  void _changeViewMode(ViewMode mode) {
    setState(() {
      _viewMode = mode;
    });
    context.read<SearchBloc>().add(ToggleViewModeEvent(mode: mode));
  }
  
  Widget _buildUltraInitialView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUltraRecentSearches(),
              const SizedBox(height: 24),
              _buildUltraSearchCategories(),
              const SizedBox(height: 24),
              _buildUltraTrendingProperties(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildUltraPopularDestinations() {
    final destinations = [
      {'name': 'صنعاء', 'count': '234', 'icon': Icons.location_city, 'color': AppTheme.primaryBlue},
      {'name': 'عدن', 'count': '189', 'icon': Icons.beach_access, 'color': AppTheme.neonBlue},
      {'name': 'تعز', 'count': '156', 'icon': Icons.terrain, 'color': AppTheme.primaryPurple},
      {'name': 'المكلا', 'count': '98', 'icon': Icons.water, 'color': AppTheme.neonPurple},
      {'name': 'سيئون', 'count': '67', 'icon': Icons.mosque, 'color': AppTheme.primaryViolet},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.2),
                    AppTheme.primaryPurple.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.trending_up_rounded,
                size: 18,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (bounds) => 
                  AppTheme.primaryGradient.createShader(bounds),
              child: Text(
                'الوجهات الشائعة',
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppTheme.textWhite,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: destinations.length,
            itemBuilder: (context, index) {
              final destination = destinations[index];
              return _buildUltraDestinationCard(destination, index);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildUltraDestinationCard(Map<String, dynamic> destination, int index) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 400 + (index * 100)),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value * _scaleAnimation.value,
              child: Container(
                width: 110,
                margin: const EdgeInsets.only(left: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.read<SearchBloc>().add(
                        SearchPropertiesEvent(city: destination['name']),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            (destination['color'] as Color).withOpacity(0.1),
                            (destination['color'] as Color).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (destination['color'] as Color).withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        destination['color'] as Color,
                                        (destination['color'] as Color).withOpacity(0.7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (destination['color'] as Color).withOpacity(0.3),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    destination['icon'] as IconData,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  destination['name'],
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: AppTheme.textWhite,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (destination['color'] as Color).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${destination['count']}',
                                    style: AppTextStyles.overline.copyWith(
                                      color: destination['color'] as Color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
      },
    );
  }
  
  // ... (Continue with remaining methods)
  Widget _buildUltraRecentSearches() {
    // Implementation
    return const SizedBox();
  }
  
  Widget _buildUltraSearchCategories() {
    // Implementation  
    return const SizedBox();
  }
  
  Widget _buildUltraTrendingProperties() {
    // Implementation
    return const SizedBox();
  }
  
  Widget _buildUltraLoadingView() {
    return const Center(
      child: LoadingWidget(
        type: LoadingType.futuristic,
        message: 'جاري التحميل...',
      ),
    );
  }
  
  Widget _buildUltraResultsView(SearchSuccess state) {
    if (state.viewMode == ViewMode.map) {
      return SearchResultsMapPage(
        results: state.searchResults.items,
        onBackToList: () {
          context.read<SearchBloc>().add(const ToggleViewModeEvent());
        },
      );
    }

    if (state.searchResults.items.isEmpty) {
      return _buildUltraEmptyResults();
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        _performSearch(state.currentFilters);
      },
      color: AppTheme.neonBlue,
      backgroundColor: AppTheme.darkCard,
      child: state.viewMode == ViewMode.list
          ? SearchResultListWidget(
              results: state.searchResults.items,
              scrollController: _scrollController,
              isLoadingMore: state is SearchLoadingMore,
              onItemTap: (result) {
                HapticFeedback.lightImpact();
                context.push(
                  '/property/${result.id}',
                  extra: {'unitId': result.unitId},
                );
              },
            )
          : SearchResultCompactWidget(
              results: state.searchResults.items,
              scrollController: _scrollController,
              isLoadingMore: state is SearchLoadingMore,
              onItemTap: (result) {
                HapticFeedback.lightImpact();
                context.push(
                  '/property/${result.id}',
                  extra: {'unitId': result.unitId},
                );
              },
            ),
    );
  }
  
  Widget _buildUltraEmptyResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ultra empty state
          Container(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _morphAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.primaryBlue.withOpacity(
                              0.1 * _morphAnimation.value
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Icon(
                  Icons.search_off_rounded,
                  size: 60,
                  color: AppTheme.textMuted.withOpacity(0.3),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          Text(
            'لم يتم العثور على نتائج',
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'جرب تغيير معايير البحث',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textMuted.withOpacity(0.7),
            ),
          ),
          
          const SizedBox(height: 24),
          
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.read<SearchBloc>().add(const ClearSearchEvent());
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('إعادة تعيين'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUltraErrorView(String message) {
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
                  AppTheme.error.withOpacity(0.7),
                  AppTheme.error.withOpacity(0.5),
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
          
          const SizedBox(height: 24),
          
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.read<SearchBloc>().add(const SearchPropertiesEvent());
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }


  Widget _buildFloatingButton({
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
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
  
  void _openFilters() async {
    final filters = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => SearchFiltersPage(
          initialFilters: _lastFilters.isEmpty ? null : _lastFilters,
        ),
        fullscreenDialog: true,
      ),
    );

    if (!mounted) return;

    if (filters != null) {
      context.read<SearchBloc>().add(
        UpdateSearchFiltersEvent(filters: filters),
      );
      _lastFilters = filters;
      _performSearch(filters);
    }
  }
  
  void _performSearch(Map<String, dynamic> filters) {
    context.read<SearchBloc>().add(
      SearchPropertiesEvent(
        searchTerm: filters['searchTerm'],
        city: filters['city'],
        propertyTypeId: filters['propertyTypeId'],
        minPrice: filters['minPrice'],
        maxPrice: filters['maxPrice'],
        minStarRating: filters['minStarRating'],
        requiredAmenities: filters['requiredAmenities'],
        unitTypeId: filters['unitTypeId'],
        serviceIds: filters['serviceIds'],
        dynamicFieldFilters: filters['dynamicFieldFilters'],
        checkIn: filters['checkIn'],
        checkOut: filters['checkOut'],
        adults: filters['adults'],
        children: filters['children'],
        guestsCount: filters['guestsCount'],
        latitude: filters['latitude'],
        longitude: filters['longitude'],
        radiusKm: filters['radiusKm'],
        sortBy: filters['sortBy'],
      ),
    );
  }

  // أضف هذه الدوال المساعدة في State class:
    bool _isRequiredField(String key, Map<String, dynamic> filters) {
    // الحقول الأساسية المطلوبة
    if (key == 'propertyTypeId' || key == 'unitTypeId') {
      return true;
    }
    
    // التحقق من الحقول الديناميكية المطلوبة
    if (key == 'dynamicFieldFilters') {
      // تحقق من وجود حقول ديناميكية مطلوبة
      return _hasMandatoryDynamicFields(filters);
    }
    
    // التحقق من الحقول الديناميكية المطلوبة
    if (key == 'checkIn' || key == 'checkOut') {
      // تحقق من وجود حقول ديناميكية مطلوبة
      return true;
    }

    return false;
  }

bool _hasMandatoryDynamicFields(Map<String, dynamic> filters) {
  // هنا يمكنك التحقق من الحقول الديناميكية المطلوبة
  // بناءً على نوع الوحدة المحدد
  final unitTypeId = filters['unitTypeId'];
  if (unitTypeId == null) return false;
  
  // يمكنك جلب معلومات الحقول المطلوبة من LocalDataService
  // أو من البيانات المحفوظة
  return false; // مؤقتاً
}

Map<String, dynamic> _extractRequiredFields(Map<String, dynamic> filters) {
  final required = <String, dynamic>{};
  
  // احتفظ بنوع العقار ونوع الوحدة
  if (filters.containsKey('propertyTypeId')) {
    required['propertyTypeId'] = filters['propertyTypeId'];
  }
  
  if (filters.containsKey('unitTypeId')) {
    required['unitTypeId'] = filters['unitTypeId'];
  }
  
  // احتفظ بالحقول الديناميكية المطلوبة
  if (filters.containsKey('dynamicFieldFilters')) {
    final dynamicFields = filters['dynamicFieldFilters'] as Map<String, dynamic>;
    // هنا يمكنك فلترة الحقول المطلوبة فقط
    required['dynamicFieldFilters'] = dynamicFields;
  }
  
  return required;
}

void _showRequiredFieldError(String fieldKey) {
  String message = '';
  
  switch (fieldKey) {
    case 'propertyTypeId':
      message = 'نوع العقار مطلوب ولا يمكن إلغاؤه';
      break;
    case 'unitTypeId':
      message = 'نوع الوحدة مطلوب ولا يمكن إلغاؤه';
      break;
    case 'dynamicFieldFilters':
      message = 'هناك حقول مطلوبة لا يمكن إلغاؤها';
      break;
    case 'checkIn':
      message = 'تاريخ الوصول مطلوب ولا يمكن إلغاؤه';
      break;
    case 'checkOut':
      message = 'تاريخ المغادرة مطلوب ولا يمكن إلغاؤه';
      break;
    default:
      message = 'هذا الحقل مطلوب';
  }
  
  HapticFeedback.mediumImpact();
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: AppTheme.warning,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppTheme.darkCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ),
  );
}
}

// Painter Classes
// Ultra Futuristic Background Painter
class _UltraFuturisticBackgroundPainter extends CustomPainter {
  final double morph;
  final double parallax;
  final double ripple;
  
  _UltraFuturisticBackgroundPainter({
    required this.morph,
    required this.parallax,
    required this.ripple,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Implementation
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Ultra Particle Model
class _UltraParticle {
  late double x, y, vx, vy;
  late double radius, opacity, glowRadius;
  late Color color;
  
  _UltraParticle() {
    reset();
  }
  
  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    vx = (math.Random().nextDouble() - 0.5) * 0.001;
    vy = (math.Random().nextDouble() - 0.5) * 0.001;
    radius = math.Random().nextDouble() * 1.5 + 0.5;
    opacity = math.Random().nextDouble() * 0.3 + 0.1;
    glowRadius = math.Random().nextDouble() * 8 + 4;
    
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

// Ultra Particle Painter
class _UltraParticlePainter extends CustomPainter {
  final List<_UltraParticle> particles;
  final double animationValue;
  
  _UltraParticlePainter({
    required this.particles,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update();
      
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity * 0.5)
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

// Floating Orb Model
class _FloatingOrb {
  late double x, y, radius;
  late Color color;
  
  _FloatingOrb() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    radius = math.Random().nextDouble() * 30 + 20;
    
    final colors = [
      AppTheme.primaryBlue,
      AppTheme.primaryPurple,
      AppTheme.primaryViolet,
    ];
    color = colors[math.Random().nextInt(colors.length)];
  }
}

// Floating Orb Painter
class _FloatingOrbPainter extends CustomPainter {
  final List<_FloatingOrb> orbs;
  final double animationValue;
  
  _FloatingOrbPainter({
    required this.orbs,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    for (var orb in orbs) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            orb.color.withOpacity(0.1 * animationValue),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(orb.x * size.width, orb.y * size.height),
          radius: orb.radius * (1 + animationValue * 0.3),
        ));
      
      canvas.drawCircle(
        Offset(orb.x * size.width, orb.y * size.height),
        orb.radius * (1 + animationValue * 0.3),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
