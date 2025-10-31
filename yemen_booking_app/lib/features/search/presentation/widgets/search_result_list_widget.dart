import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/search_result.dart';
import 'search_result_card_widget.dart';

class SearchResultListWidget extends StatefulWidget {
  final List<SearchResult> results;
  final ScrollController? scrollController;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;
  final Function(SearchResult)? onItemTap;
  final Function(SearchResult)? onFavoriteToggle;

  const SearchResultListWidget({
    super.key,
    required this.results,
    this.scrollController,
    this.isLoadingMore = false,
    this.onLoadMore,
    this.onItemTap,
    this.onFavoriteToggle,
  });

  @override
  State<SearchResultListWidget> createState() => _SearchResultListWidgetState();
}

class _SearchResultListWidgetState extends State<SearchResultListWidget>
    with TickerProviderStateMixin {
  late AnimationController _listAnimationController;
  final Map<int, AnimationController> _itemAnimations = {};

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
    
    // Create animation for each item
    for (int i = 0; i < widget.results.length; i++) {
      _itemAnimations[i] = AnimationController(
        duration: Duration(milliseconds: 300 + (i * 50)),
        vsync: this,
      )..forward();
    }
  }

  @override
  void didUpdateWidget(covariant SearchResultListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync animation controllers with updated results length
    final oldLen = oldWidget.results.length;
    final newLen = widget.results.length;

    if (newLen > oldLen) {
      for (int i = oldLen; i < newLen; i++) {
        _itemAnimations[i] = AnimationController(
          duration: Duration(milliseconds: 300 + (i * 50)),
          vsync: this,
        )..forward();
      }
    } else if (newLen < oldLen) {
      for (int i = newLen; i < oldLen; i++) {
        final controller = _itemAnimations.remove(i);
        controller?.dispose();
      }
    }
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    for (var controller in _itemAnimations.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.results.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _listAnimationController,
      builder: (context, child) {
        return ListView.builder(
          controller: widget.scrollController,
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          itemCount: widget.results.length + (widget.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == widget.results.length) {
              return _buildLoadingIndicator();
            }

            final result = widget.results[index];
            var animationController = _itemAnimations[index];
            
            // Fallback: lazily create controller if missing for any reason
            animationController ??= _itemAnimations[index] = AnimationController(
              duration: Duration(milliseconds: 300 + (index * 50)),
              vsync: this,
            )..forward();

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.3, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animationController,
                curve: Curves.easeOutBack,
              )),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: animationController,
                  curve: Curves.easeIn,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SearchResultCardWidget(
                    result: result,
                    onTap: () => widget.onItemTap?.call(result),
                    onFavoriteToggle: widget.onFavoriteToggle != null
                        ? () => widget.onFavoriteToggle!(result)
                        : null,
                    displayType: CardDisplayType.list,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Empty Icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primaryBlue.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.search_off_rounded,
                    size: 60,
                    color: AppTheme.textMuted.withOpacity(0.5),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          ShaderMask(
            shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
            child: Text(
              'لا توجد نتائج',
              style: AppTextStyles.heading2.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'جرب تغيير معايير البحث',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            // Custom Loading Animation
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const LoadingWidget(
                type: LoadingType.futuristic,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'جاري تحميل المزيد...',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}