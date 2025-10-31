import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../injection_container.dart';
import '../bloc/property_bloc.dart';
import '../bloc/property_event.dart';
import '../bloc/property_state.dart';

class PropertyReviewsPage extends StatefulWidget {
  final String propertyId;
  final String propertyName;

  const PropertyReviewsPage({
    super.key,
    required this.propertyId,
    required this.propertyName,
  });

  @override
  State<PropertyReviewsPage> createState() => _PropertyReviewsPageState();
}

class _PropertyReviewsPageState extends State<PropertyReviewsPage>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int? _selectedRating;
  String _sortBy = 'CreatedAt';
  String _sortDirection = 'Desc';
  bool _withImagesOnly = false;
  
  final List<_AnimatedStar> _stars = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateStars();
    _scrollController.addListener(_onScroll);
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
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
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
  }
  
  void _generateStars() {
    for (int i = 0; i < 15; i++) {
      _stars.add(_AnimatedStar());
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
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      // Load more reviews
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
    return BlocProvider(
      create: (context) => sl<PropertyBloc>()
        ..add(GetPropertyReviewsEvent(
          propertyId: widget.propertyId,
          sortBy: _sortBy,
          sortDirection: _sortDirection,
          withImagesOnly: _withImagesOnly,
        )),
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Stack(
          children: [
            // Animated background
            _buildAnimatedBackground(),
            
            // Floating stars
            _buildFloatingStars(),
            
            // Main content
            Column(
              children: [
                _buildFuturisticAppBar(),
                _buildFuturisticFiltersSection(),
                Expanded(
                  child: BlocBuilder<PropertyBloc, PropertyState>(
                    builder: (context, state) {
                      if (state is PropertyReviewsLoading) {
                        return _buildFuturisticLoader();
                      }

                      if (state is PropertyError) {
                        return _buildFuturisticError(context, state);
                      }

                      if (state is PropertyReviewsLoaded) {
                        if (state.reviews.isEmpty) {
                          return _buildFuturisticEmptyState();
                        }

                        return RefreshIndicator(
                          onRefresh: () async => _loadReviews(context),
                          displacement: 80,
                          backgroundColor: AppTheme.darkCard,
                          color: AppTheme.primaryBlue,
                          child: ListView.separated(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(20),
                            itemCount: state.hasReachedMax
                                ? state.reviews.length
                                : state.reviews.length + 1,
                            separatorBuilder: (context, index) => const SizedBox(
                              height: 16,
                            ),
                            itemBuilder: (context, index) {
                              if (index >= state.reviews.length) {
                                return _buildLoadMoreIndicator();
                              }
                              
                              final review = state.reviews[index];
                              return FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: _buildFuturisticReviewCard(review, index),
                                ),
                              );
                            },
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
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
            AppTheme.darkBackground.withOpacity(0.8),
            AppTheme.darkBackground.withRed(10),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFloatingStars() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: _StarPainter(
            stars: _stars,
            animationValue: _particleController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildFuturisticAppBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.95),
            AppTheme.darkCard.withOpacity(0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: SafeArea(
            child: Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildGlassBackButton(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => 
                              AppTheme.primaryGradient.createShader(bounds),
                          child: Text(
                            'التقييمات',
                            style: AppTextStyles.heading2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          widget.propertyName,
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildWriteReviewButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildGlassBackButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.6),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildWriteReviewButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to write review
            HapticFeedback.mediumImpact();
          },
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.edit,
                  size: 18,
                  color: Colors.white,
                ),
                SizedBox(width: 6),
                Text(
                  'اكتب تقييم',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticFiltersSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              // Rating filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    _buildFuturisticFilterChip(
                      label: 'الكل',
                      isSelected: _selectedRating == null,
                      onSelected: (selected) {
                        setState(() {
                          _selectedRating = null;
                        });
                        _applyFilters(context);
                      },
                    ),
                    const SizedBox(width: 8),
                    ...List.generate(5, (index) {
                      final rating = 5 - index;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _buildFuturisticFilterChip(
                          label: '$rating',
                          icon: Icons.star,
                          isSelected: _selectedRating == rating,
                          onSelected: (selected) {
                            setState(() {
                              _selectedRating = selected ? rating : null;
                            });
                            _applyFilters(context);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              
              // Additional filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildFuturisticFilterChip(
                        label: 'مع صور فقط',
                        icon: Icons.photo_library_outlined,
                        isSelected: _withImagesOnly,
                        onSelected: (selected) {
                          setState(() {
                            _withImagesOnly = selected;
                          });
                          _applyFilters(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildFuturisticSortButton(context),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    return GestureDetector(
      onTap: () {
        onSelected(!isSelected);
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? AppTheme.primaryGradient
              : null,
          color: !isSelected 
              ? AppTheme.darkCard.withOpacity(0.5)
              : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? Colors.transparent
                : AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppTheme.textMuted,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? Colors.white : AppTheme.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticSortButton(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        final parts = value.split('-');
        setState(() {
          _sortBy = parts[0];
          _sortDirection = parts[1];
        });
        _applyFilters(context);
        HapticFeedback.lightImpact();
      },
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: AppTheme.darkCard,
      itemBuilder: (context) => [
        _buildPopupMenuItem('CreatedAt-Desc', 'الأحدث', Icons.schedule),
        _buildPopupMenuItem('CreatedAt-Asc', 'الأقدم', Icons.history),
        _buildPopupMenuItem('Rating-Desc', 'الأعلى تقييماً', Icons.trending_up),
        _buildPopupMenuItem('Rating-Asc', 'الأقل تقييماً', Icons.trending_down),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryPurple.withOpacity(0.2),
              AppTheme.primaryBlue.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.sort, size: 18, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Text(
              _getSortLabel(),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18, color: AppTheme.primaryBlue),
          ],
        ),
      ),
    );
  }
  
  PopupMenuItem<String> _buildPopupMenuItem(String value, String label, IconData icon) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryBlue),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticReviewCard(dynamic review, int index) {
    return Container(
      margin: EdgeInsets.only(
        top: index == 0 ? 0 : 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkCard.withOpacity(0.8),
            AppTheme.darkCard.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReviewHeader(review),
                const SizedBox(height: 16),
                _buildFuturisticRatingBreakdown(review),
                const SizedBox(height: 16),
                _buildReviewContent(review),
                if (review.images.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildReviewImages(review.images),
                ],
                if (review.responseText != null) ...[
                  const SizedBox(height: 16),
                  _buildManagementResponse(review),
                ],
                const SizedBox(height: 16),
                _buildReviewActions(review),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildReviewHeader(dynamic review) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              review.userName[0].toUpperCase(),
              style: AppTextStyles.heading2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                review.userName,
                style: AppTextStyles.heading3.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                   Icon(
                    Icons.schedule,
                    size: 14,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(review.createdAt),
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildRatingBadge(review.averageRating),
      ],
    );
  }
  
  Widget _buildRatingBadge(double rating) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getRatingColor(rating),
                _getRatingColor(rating).withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _getRatingColor(rating).withOpacity(
                  0.3 + (_glowController.value * 0.2),
                ),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFuturisticRatingBreakdown(dynamic review) {
    final categories = [
      {'label': 'النظافة', 'value': review.cleanliness, 'icon': Icons.cleaning_services},
      {'label': 'الخدمة', 'value': review.service, 'icon': Icons.room_service},
      {'label': 'الموقع', 'value': review.location, 'icon': Icons.location_on},
      {'label': 'القيمة', 'value': review.value, 'icon': Icons.attach_money},
    ];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.1),
            AppTheme.primaryPurple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: categories.map((cat) {
          return _buildRatingCategory(
            cat['label'] as String,
            cat['value'] as int,
            cat['icon'] as IconData,
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildRatingCategory(String label, int value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryBlue,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.star,
              size: 14,
              color: AppTheme.warning,
            ),
            const SizedBox(width: 2),
            Text(
              value.toString(),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildReviewContent(dynamic review) {
    return Text(
      review.comment,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppTheme.textLight,
        height: 1.6,
      ),
    );
  }

  Widget _buildReviewImages(List<dynamic> images) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: images.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              // Open image viewer
            },
            child: Container(
              width: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      images[index].url,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
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

  Widget _buildManagementResponse(dynamic review) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryViolet.withOpacity(0.1),
            AppTheme.primaryBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryViolet.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.business,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              ShaderMask(
                shaderCallback: (bounds) => 
                    AppTheme.primaryGradient.createShader(bounds),
                child: Text(
                  'رد الإدارة',
                  style: AppTextStyles.heading3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.responseText!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReviewActions(dynamic review) {
    return Row(
      children: [
        _buildActionButton(
          icon: Icons.thumb_up_outlined,
          label: 'مفيد',
          onTap: () {
            HapticFeedback.lightImpact();
          },
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          icon: Icons.reply,
          label: 'رد',
          onTap: () {
            HapticFeedback.lightImpact();
          },
        ),
        const Spacer(),
        _buildActionButton(
          icon: Icons.flag_outlined,
          label: 'إبلاغ',
          onTap: () {
            HapticFeedback.lightImpact();
          },
        ),
      ],
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFuturisticLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CustomPaint(
              painter: _StarLoaderPainter(
                animationValue: _particleController.value,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ShaderMask(
            shaderCallback: (bounds) => 
                AppTheme.primaryGradient.createShader(bounds),
            child: Text(
              'جاري تحميل التقييمات',
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFuturisticError(BuildContext context, PropertyError state) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.error.withOpacity(0.7),
              AppTheme.error.withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.error.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
           Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ',
              style: AppTextStyles.heading2.copyWith(
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildRetryButton(() => _loadReviews(context)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFuturisticEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.2),
                    AppTheme.primaryBlue.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.rate_review_outlined,
                size: 60,
                color: AppTheme.primaryBlue.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (bounds) => 
                  AppTheme.primaryGradient.createShader(bounds),
              child: Text(
                'لا توجد تقييمات بعد',
                style: AppTextStyles.heading2.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'كن أول من يشارك تجربته',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 32),
            _buildGlowingButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                // Navigate to write review
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'اكتب أول تقييم',
                    style: AppTextStyles.buttonLarge.copyWith(
                      color: Colors.white,
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
  
  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            AppTheme.primaryBlue,
          ),
          strokeWidth: 2,
        ),
      ),
    );
  }
  
  Widget _buildRetryButton(VoidCallback onPressed) {
    return _buildGlowingButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.refresh, size: 20),
          const SizedBox(width: 8),
          Text(
            'إعادة المحاولة',
            style: AppTextStyles.buttonLarge.copyWith(
              color: Colors.white,
            ),
          ),
        ],
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: child,
          ),
        ),
      ),
    );
  }

  String _getSortLabel() {
    if (_sortBy == 'CreatedAt' && _sortDirection == 'Desc') return 'الأحدث';
    if (_sortBy == 'CreatedAt' && _sortDirection == 'Asc') return 'الأقدم';
    if (_sortBy == 'Rating' && _sortDirection == 'Desc') return 'الأعلى تقييماً';
    if (_sortBy == 'Rating' && _sortDirection == 'Asc') return 'الأقل تقييماً';
    return 'ترتيب';
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return AppTheme.success;
    if (rating >= 3.5) return AppTheme.warning;
    if (rating >= 2.5) return Colors.orange;
    return AppTheme.error;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'اليوم';
    if (difference.inDays == 1) return 'أمس';
    if (difference.inDays < 7) return 'منذ ${difference.inDays} أيام';
    if (difference.inDays < 30) return 'منذ ${(difference.inDays / 7).floor()} أسابيع';
    return 'منذ ${(difference.inDays / 30).floor()} أشهر';
  }

  void _loadReviews(BuildContext context) {
    context.read<PropertyBloc>().add(GetPropertyReviewsEvent(
      propertyId: widget.propertyId,
      sortBy: _sortBy,
      sortDirection: _sortDirection,
      withImagesOnly: _withImagesOnly,
    ));
  }

  void _applyFilters(BuildContext context) {
    _loadReviews(context);
  }
}

// Animated stars for background
class _AnimatedStar {
  late double x;
  late double y;
  late double size;
  late double opacity;
  late double speed;
  
  _AnimatedStar() {
    reset();
  }
  
  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    size = math.Random().nextDouble() * 3 + 1;
    opacity = math.Random().nextDouble() * 0.5 + 0.2;
    speed = math.Random().nextDouble() * 0.002 + 0.001;
  }
  
  void update() {
    y -= speed;
    if (y < 0) {
      y = 1.0;
      x = math.Random().nextDouble();
    }
  }
}

class _StarPainter extends CustomPainter {
  final List<_AnimatedStar> stars;
  final double animationValue;
  
  _StarPainter({
    required this.stars,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    for (var star in stars) {
      star.update();
      
      final paint = Paint()
        ..color = AppTheme.warning.withOpacity(star.opacity)
        ..style = PaintingStyle.fill;
      
      _drawStar(
        canvas,
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );
    }
  }
  
  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const angle = math.pi / 5;
    
    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? radius : radius * 0.5;
      final x = center.dx + r * math.cos(i * angle - math.pi / 2);
      final y = center.dy + r * math.sin(i * angle - math.pi / 2);
      
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

class _StarLoaderPainter extends CustomPainter {
  final double animationValue;
  
  _StarLoaderPainter({required this.animationValue});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;
    
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 + animationValue * 360) * math.pi / 180;
      final starCenter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      
      final paint = Paint()
        ..shader = AppTheme.primaryGradient.createShader(
          Rect.fromCircle(center: starCenter, radius: 10),
        )
        ..style = PaintingStyle.fill;
      
      _drawStar(canvas, starCenter, 10, paint);
    }
  }
  
  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const angle = math.pi / 5;
    
    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? radius : radius * 0.5;
      final x = center.dx + r * math.cos(i * angle - math.pi / 2);
      final y = center.dy + r * math.sin(i * angle - math.pi / 2);
      
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