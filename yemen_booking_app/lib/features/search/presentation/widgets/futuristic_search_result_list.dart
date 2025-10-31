// lib/features/search/presentation/widgets/futuristic_search_result_list.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yemen_booking_app/features/search/presentation/widgets/futuristic_search_result_card.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/search_result.dart';

class FuturisticSearchResultList extends StatefulWidget {
  final List<SearchResult> results;
  final ScrollController? scrollController;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;
  final Function(SearchResult)? onItemTap;
  final Function(SearchResult)? onFavoriteToggle;

  const FuturisticSearchResultList({
    super.key,
    required this.results,
    this.scrollController,
    this.isLoadingMore = false,
    this.onLoadMore,
    this.onItemTap,
    this.onFavoriteToggle,
  });

  @override
  State<FuturisticSearchResultList> createState() => 
      _FuturisticSearchResultListState();
}

class _FuturisticSearchResultListState 
    extends State<FuturisticSearchResultList>
    with TickerProviderStateMixin {
  
  late AnimationController _backgroundAnimationController;
  late AnimationController _emptyStateController;
  late AnimationController _loadingController;
  
  final Map<int, AnimationController> _itemControllers = {};
  ScrollController? _internalScrollController;
  
  ScrollController get _scrollController => 
      widget.scrollController ?? _internalScrollController!;

  @override
  void initState() {
    super.initState();
    
    if (widget.scrollController == null) {
      _internalScrollController = ScrollController();
    }
    
    _initializeAnimations();
    _setupScrollListener();
  }

  void _initializeAnimations() {
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _emptyStateController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    if (widget.results.isEmpty) {
      _emptyStateController.forward();
    }
  }
  
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        widget.onLoadMore?.call();
      }
    });
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _emptyStateController.dispose();
    _loadingController.dispose();
    _itemControllers.forEach((_, controller) => controller.dispose());
    _internalScrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.results.isEmpty) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        // Animated background pattern
        _buildAnimatedBackground(),
        
        // Main list
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification) {
              if (_scrollController.position.extentAfter < 200) {
                widget.onLoadMore?.call();
              }
            }
            return false;
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Results list
              SliverPadding(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final result = widget.results[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: FuturisticSearchResultCard(
                          result: result,
                          onTap: () => widget.onItemTap?.call(result),
                          onFavoriteToggle: widget.onFavoriteToggle != null
                              ? () => widget.onFavoriteToggle!(result)
                              : null,
                          animationDelay: Duration(milliseconds: index * 100),
                        ),
                      );
                    },
                    childCount: widget.results.length,
                  ),
                ),
              ),
              
              // Loading indicator
              if (widget.isLoadingMore)
                SliverToBoxAdapter(
                  child: _buildLoadingIndicator(),
                ),
              
              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _backgroundAnimationController,
          builder: (context, child) {
            return CustomPaint(
              painter: _BackgroundPatternPainter(
                animation: _backgroundAnimationController.value,
                color: AppTheme.primaryBlue.withOpacity(0.01),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: AnimatedBuilder(
        animation: _emptyStateController,
        builder: (context, child) {
          final scale = Curves.elasticOut.transform(_emptyStateController.value);
          final opacity = Curves.easeIn.transform(_emptyStateController.value);
          
          return Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated empty icon with glow
                  Container(
                    width: 140,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow effect
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppTheme.primaryBlue.withOpacity(0.2),
                                AppTheme.primaryPurple.withOpacity(0.1),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        
                        // Glass container
                        ClipRRect(
                          borderRadius: BorderRadius.circular(70),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.1),
                                    Colors.white.withOpacity(0.05),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.search_off_rounded,
                                size: 45,
                                color: AppTheme.textMuted.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Title with gradient
                  ShaderMask(
                    shaderCallback: (bounds) => 
                        AppTheme.primaryGradient.createShader(bounds),
                    child: Text(
                      'لا توجد نتائج',
                      style: AppTextStyles.heading1.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Subtitle
                  Text(
                    'جرب تغيير معايير البحث للعثور على ما تبحث عنه',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textMuted.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Action button
                  _buildRefineSearchButton(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRefineSearchButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        // Navigate to search filters
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.tune_rounded,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              'تعديل البحث',
              style: AppTextStyles.buttonMedium.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: AnimatedBuilder(
          animation: _loadingController,
          builder: (context, child) {
            return Column(
              children: [
                // Futuristic loading animation
                Container(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer rotating ring
                      Transform.rotate(
                        angle: _loadingController.value * 2 * math.pi,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryBlue.withOpacity(0.2),
                              width: 2,
                            ),
                            gradient: SweepGradient(
                              colors: [
                                Colors.transparent,
                                AppTheme.primaryBlue.withOpacity(0.3),
                                AppTheme.primaryPurple.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Inner rotating ring
                      Transform.rotate(
                        angle: -_loadingController.value * 2 * math.pi,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryPurple.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      
                      // Center dot
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Loading text with shimmer
                ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: [
                        AppTheme.primaryCyan,
                        AppTheme.primaryBlue,
                        AppTheme.primaryPurple,
                        AppTheme.primaryCyan,
                      ],
                      stops: [
                        0.0,
                        0.3 + 0.2 * math.sin(_loadingController.value * 2 * math.pi),
                        0.7 + 0.2 * math.sin(_loadingController.value * 2 * math.pi),
                        1.0,
                      ],
                    ).createShader(bounds);
                  },
                  child: Text(
                    'جاري تحميل المزيد...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Background pattern painter
class _BackgroundPatternPainter extends CustomPainter {
  final double animation;
  final Color color;
  
  _BackgroundPatternPainter({
    required this.animation,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    // Draw animated grid pattern
    const spacing = 50.0;
    final offset = animation * spacing;
    
    for (double x = -spacing; x < size.width + spacing; x += spacing) {
      canvas.drawLine(
        Offset(x + offset, 0),
        Offset(x + offset - 100, size.height),
        paint,
      );
    }
    
    for (double y = -spacing; y < size.height + spacing; y += spacing) {
      canvas.drawLine(
        Offset(0, y + offset),
        Offset(size.width, y + offset),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}