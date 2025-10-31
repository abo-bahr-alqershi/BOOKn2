import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../bloc/favorites_bloc.dart';
import '../bloc/favorites_event.dart';
import '../bloc/favorites_state.dart';
import '../widgets/favorite_property_card_widget.dart';
import '../../../../injection_container.dart';
import '../../../../services/local_storage_service.dart';
import '../../../../core/constants/storage_constants.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late AnimationController _filterController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _filterAnimation;
  
  // UI State
  final ScrollController _scrollController = ScrollController();
  final List<_MinimalParticle> _particles = [];
  String _selectedFilter = 'all';
  String _sortBy = 'recent';
  bool _isGridView = false;
  
  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateParticles();
    _loadFavorites();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _filterController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _particleAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_particleController);
    
    _filterAnimation = CurvedAnimation(
      parent: _filterController,
      curve: Curves.easeOutQuart,
    );
    
    // Start animations
    _fadeController.forward();
    _scaleController.forward();
    _filterController.forward();
  }

  void _generateParticles() {
    for (int i = 0; i < 5; i++) {
      _particles.add(_MinimalParticle());
    }
  }

  void _loadFavorites() {
    context.read<FavoritesBloc>().add(const LoadFavoritesEvent());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _filterController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          // Premium animated background
          _buildPremiumBackground(),
          
          // Floating particles
          _buildFloatingParticles(),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Premium App Bar
                _buildPremiumAppBar(),
                
                // Search and Filters
                _buildSearchAndFilters(),
                
                // Content
                Expanded(
                  child: BlocBuilder<FavoritesBloc, FavoritesState>(
                    builder: (context, state) {
                      if (state is FavoritesLoading) {
                        return _buildLoadingState();
                      }
                      
                      if (state is FavoritesError) {
                        return _buildErrorState(state.message);
                      }
                      
                      if (state is FavoritesLoaded) {
                        if (state.favorites.isEmpty) {
                          return _buildEmptyState();
                        }
                        
                        final filteredFavorites = _filterAndSortFavorites(state.favorites);
                        
                        if (filteredFavorites.isEmpty) {
                          return _buildNoResultsState();
                        }
                        
                        return _buildFavoritesList(filteredFavorites);
                      }
                      
                      return _buildInitialState();
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

  Widget _buildPremiumBackground() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkBackground,
                AppTheme.darkBackground.withOpacity(0.95),
                AppTheme.darkSurface.withOpacity(0.9),
              ],
            ),
          ),
          child: CustomPaint(
            painter: _PremiumBackgroundPainter(
              animation: _particleAnimation.value,
              glowIntensity: _glowAnimation.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            animation: _particleController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildPremiumAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Title with gradient
          Expanded(
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withOpacity(0.8),
                      AppTheme.primaryPurple.withOpacity(0.8),
                    ],
                    stops: [
                      0.3 + 0.2 * _glowAnimation.value,
                      0.7 + 0.2 * _glowAnimation.value,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'المفضلة',
                    style: AppTextStyles.heading2.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // View toggle
          _buildMinimalIconButton(
            icon: _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          
          // More options
          _buildMinimalIconButton(
            icon: Icons.more_vert_rounded,
            onTap: _showMoreOptions,
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.03),
              Colors.white.withOpacity(0.01),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: AppTheme.textWhite.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return FadeTransition(
      opacity: _filterAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            // Search bar
            Container(
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkCard.withOpacity(0.5),
                    AppTheme.darkCard.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.darkBorder.withOpacity(0.08),
                  width: 0.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: TextField(
                    controller: _searchController,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 12,
                      color: AppTheme.textWhite.withOpacity(0.9),
                    ),
                    decoration: InputDecoration(
                      hintText: 'البحث في المفضلة...',
                      hintStyle: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.textMuted.withOpacity(0.4),
                        fontSize: 12,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppTheme.textMuted.withOpacity(0.4),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Filter chips
            SizedBox(
              height: 28,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildFilterChip(
                    label: 'الكل',
                    value: 'all',
                    isSelected: _selectedFilter == 'all',
                  ),
                  _buildFilterChip(
                    label: 'شقق',
                    value: 'apartment',
                    isSelected: _selectedFilter == 'apartment',
                  ),
                  _buildFilterChip(
                    label: 'فلل',
                    value: 'villa',
                    isSelected: _selectedFilter == 'villa',
                  ),
                  _buildFilterChip(
                    label: 'محلات',
                    value: 'shop',
                    isSelected: _selectedFilter == 'shop',
                  ),
                  _buildFilterChip(
                    label: 'أراضي',
                    value: 'land',
                    isSelected: _selectedFilter == 'land',
                  ),
                  const SizedBox(width: 8),
                  // Sort button
                  GestureDetector(
                    onTap: _showSortOptions,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryBlue.withOpacity(0.08),
                            AppTheme.primaryPurple.withOpacity(0.04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withOpacity(0.15),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sort_rounded,
                            size: 14,
                            color: AppTheme.primaryBlue.withOpacity(0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ترتيب',
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.primaryBlue.withOpacity(0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedFilter = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.15),
                    AppTheme.primaryPurple.withOpacity(0.08),
                  ],
                )
              : null,
          color: !isSelected
              ? AppTheme.darkCard.withOpacity(0.3)
              : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlue.withOpacity(0.3)
                : AppTheme.darkBorder.withOpacity(0.08),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isSelected
                  ? AppTheme.primaryBlue
                  : AppTheme.textMuted.withOpacity(0.6),
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesList(List<dynamic> favorites) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          context.read<FavoritesBloc>().add(const RefreshFavoritesEvent());
        },
        color: AppTheme.primaryBlue,
        backgroundColor: AppTheme.darkCard,
        child: _isGridView
            ? GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  return FavoritePropertyCardWidget(
                    favorite: favorites[index],
                    isGridView: true,
                    animationDelay: Duration(milliseconds: index * 50),
                    onTap: () => _navigateToProperty(favorites[index]),
                    onRemove: () => _removeFromFavorites(favorites[index]),
                  );
                },
              )
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  return FavoritePropertyCardWidget(
                    favorite: favorites[index],
                    isGridView: false,
                    animationDelay: Duration(milliseconds: index * 50),
                    onTap: () => _navigateToProperty(favorites[index]),
                    onRemove: () => _removeFromFavorites(favorites[index]),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: LoadingWidget(
        type: LoadingType.futuristic,
        message: 'جاري التحميل...',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkCard.withOpacity(0.4),
                    AppTheme.darkCard.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.darkBorder.withOpacity(0.08),
                  width: 0.5,
                ),
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
                          AppTheme.primaryBlue.withOpacity(0.1),
                          AppTheme.primaryPurple.withOpacity(0.05),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite_outline_rounded,
                      size: 32,
                      color: AppTheme.primaryBlue.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'لا توجد مفضلات',
                    style: AppTextStyles.heading3.copyWith(
                      fontSize: 16,
                      color: AppTheme.textWhite.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ابدأ بإضافة العقارات المفضلة لديك',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textMuted.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.go('/properties');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'تصفح العقارات',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppTheme.textMuted.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد نتائج',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'جرب البحث بكلمات مختلفة',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.error.withOpacity(0.08),
              AppTheme.error.withOpacity(0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.error.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: AppTheme.error.withOpacity(0.7),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.error.withOpacity(0.8),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _loadFavorites,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.error.withOpacity(0.7),
                      AppTheme.error.withOpacity(0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'إعادة المحاولة',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return const SizedBox.shrink();
  }

  List<dynamic> _filterAndSortFavorites(List<dynamic> favorites) {
    var filtered = favorites.where((favorite) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final title = (favorite.propertyName ?? '').toString().toLowerCase();
        final location = (favorite.propertyLocation ?? '').toString().toLowerCase();
        
        if (!title.contains(query) && !location.contains(query)) {
          return false;
        }
      }
      
      // Type filter
      if (_selectedFilter != 'all') {
        final typeName = (favorite.typeName ?? '').toString().toLowerCase();
        if (!typeName.contains(_selectedFilter.toLowerCase())) return false;
      }
      
      return true;
    }).toList();
    
    // Sort
    switch (_sortBy) {
      case 'recent':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'price_low':
        filtered.sort((a, b) => (a.minPrice ?? 0).compareTo(b.minPrice ?? 0));
        break;
      case 'price_high':
        filtered.sort((a, b) => (b.minPrice ?? 0).compareTo(a.minPrice ?? 0));
        break;
      case 'name':
        filtered.sort((a, b) => (a.propertyName ?? '').compareTo(b.propertyName ?? ''));
        break;
    }
    
    return filtered;
  }

  void _showSortOptions() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SortOptionsSheet(
        currentSort: _sortBy,
        onSortChanged: (value) {
          setState(() {
            _sortBy = value;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showMoreOptions() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MoreOptionsSheet(
        onClearAll: _clearAllFavorites,
        onExport: _exportFavorites,
      ),
    );
  }

  void _navigateToProperty(dynamic favorite) {
    HapticFeedback.lightImpact();
    context.push('/property/${favorite.propertyId}');
  }

  void _removeFromFavorites(dynamic favorite) {
    HapticFeedback.mediumImpact();
    final uid = (sl<LocalStorageService>().getData(StorageConstants.userId) ?? '').toString();
    context.read<FavoritesBloc>().add(
      RemoveFromFavoritesEvent(
        propertyId: favorite.propertyId,
        userId: uid,
      ),
    );
  }

  void _clearAllFavorites() {
    HapticFeedback.heavyImpact();
    context.read<FavoritesBloc>().add(const ClearFavoritesEvent());
  }

  void _exportFavorites() {
    HapticFeedback.lightImpact();
    // Implement export functionality
  }
}

// Sort Options Sheet
class _SortOptionsSheet extends StatelessWidget {
  final String currentSort;
  final Function(String) onSortChanged;

  const _SortOptionsSheet({
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkCard.withOpacity(0.9),
                  AppTheme.darkCard.withOpacity(0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.darkBorder.withOpacity(0.08),
                width: 0.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.darkBorder.withOpacity(0.2),
                        AppTheme.darkBorder.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                _buildSortOption(
                  title: 'الأحدث',
                  value: 'recent',
                  isSelected: currentSort == 'recent',
                ),
                _buildSortOption(
                  title: 'السعر (الأقل)',
                  value: 'price_low',
                  isSelected: currentSort == 'price_low',
                ),
                _buildSortOption(
                  title: 'السعر (الأعلى)',
                  value: 'price_high',
                  isSelected: currentSort == 'price_high',
                ),
                _buildSortOption(
                  title: 'الاسم',
                  value: 'name',
                  isSelected: currentSort == 'name',
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption({
    required String title,
    required String value,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => onSortChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
                      )
                    : null,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppTheme.darkBorder.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected
                    ? AppTheme.primaryBlue
                    : AppTheme.textWhite.withOpacity(0.7),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// More Options Sheet
class _MoreOptionsSheet extends StatelessWidget {
  final VoidCallback onClearAll;
  final VoidCallback onExport;

  const _MoreOptionsSheet({
    required this.onClearAll,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkCard.withOpacity(0.9),
                  AppTheme.darkCard.withOpacity(0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.darkBorder.withOpacity(0.08),
                width: 0.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.darkBorder.withOpacity(0.2),
                        AppTheme.darkBorder.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                _buildOption(
                  icon: Icons.download_rounded,
                  title: 'تصدير المفضلات',
                  onTap: () {
                    Navigator.pop(context);
                    onExport();
                  },
                ),
                _buildOption(
                  icon: Icons.clear_all_rounded,
                  title: 'مسح الكل',
                  color: AppTheme.error,
                  onTap: () {
                    Navigator.pop(context);
                    onClearAll();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (color ?? AppTheme.primaryBlue).withOpacity(0.1),
                    (color ?? AppTheme.primaryBlue).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: (color ?? AppTheme.primaryBlue).withOpacity(0.8),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: (color ?? AppTheme.textWhite).withOpacity(0.8),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Minimal Particle
class _MinimalParticle {
  double x = math.Random().nextDouble();
  double y = math.Random().nextDouble();
  double vx = (math.Random().nextDouble() - 0.5) * 0.0003;
  double vy = (math.Random().nextDouble() - 0.5) * 0.0003;
  double radius = math.Random().nextDouble() + 0.5;
  double opacity = math.Random().nextDouble() * 0.05 + 0.02;
  Color color = [
    AppTheme.primaryBlue,
    AppTheme.primaryPurple,
    AppTheme.primaryCyan,
  ][math.Random().nextInt(3)];

  void update() {
    x += vx;
    y += vy;
    if (x < 0 || x > 1) vx = -vx;
    if (y < 0 || y > 1) vy = -vy;
  }
}

// Painters
class _PremiumBackgroundPainter extends CustomPainter {
  final double animation;
  final double glowIntensity;

  _PremiumBackgroundPainter({
    required this.animation,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.15
      ..color = AppTheme.primaryBlue.withOpacity(0.015 * glowIntensity);

    const spacing = 50.0;
    final offset = animation * spacing;

    for (double x = -spacing + offset % spacing; x < size.width + spacing; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ParticlePainter extends CustomPainter {
  final List<_MinimalParticle> particles;
  final double animation;

  _ParticlePainter({
    required this.particles,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update();
      
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      
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