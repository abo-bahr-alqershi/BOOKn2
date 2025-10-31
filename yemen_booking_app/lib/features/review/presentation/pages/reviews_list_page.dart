import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../injection_container.dart';
import '../bloc/review_bloc.dart';
import '../bloc/review_event.dart';
import '../bloc/review_state.dart';
import '../widgets/review_card_widget.dart';

class ReviewsListPage extends StatefulWidget {
  final String propertyId;
  final String propertyName;

  const ReviewsListPage({
    super.key,
    required this.propertyId,
    required this.propertyName,
  });

  @override
  State<ReviewsListPage> createState() => _ReviewsListPageState();
}

class _ReviewsListPageState extends State<ReviewsListPage> {
  final ScrollController _scrollController = ScrollController();
  int? _selectedRating;
  bool _withImagesOnly = false;
  String _sortBy = 'CreatedAt';
  String _sortDirection = 'Desc';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<ReviewBloc>().add(const LoadMoreReviewsEvent());
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
      create: (context) => sl<ReviewBloc>()
        ..add(GetPropertyReviewsEvent(propertyId: widget.propertyId)),
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildFiltersSection(),
            const Divider(height: 1),
            Expanded(
              child: BlocBuilder<ReviewBloc, ReviewState>(
                builder: (context, state) {
                  if (state is ReviewLoading) {
                    return const Center(
                      child: LoadingWidget(
                        type: LoadingType.circular,
                      ),
                    );
                  }

                  if (state is ReviewError) {
                    return Center(
                      child: CustomErrorWidget(
                        message: state.message,
                        onRetry: () {
                          context.read<ReviewBloc>().add(
                            GetPropertyReviewsEvent(
                              propertyId: widget.propertyId,
                            ),
                          );
                        },
                      ),
                    );
                  }

                  if (state is ReviewsLoaded) {
                    if (state.reviews.items.isEmpty) {
                      return _buildEmptyState();
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<ReviewBloc>().add(
                          RefreshReviewsEvent(propertyId: widget.propertyId),
                        );
                      },
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                        itemCount: state.hasReachedMax
                            ? state.reviews.items.length
                            : state.reviews.items.length + 1,
                        separatorBuilder: (context, index) => const SizedBox(
                          height: AppDimensions.spacingMd,
                        ),
                        itemBuilder: (context, index) {
                          if (index >= state.reviews.items.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(AppDimensions.paddingMedium),
                                child: LoadingWidget(
                                  type: LoadingType.dots,
                                ),
                              ),
                            );
                          }
                          return ReviewCardWidget(
                            review: state.reviews.items[index],
                            onLike: () {
                              // Handle like
                            },
                          );
                        },
                      ),
                    );
                  }

                  if (state is ReviewLoadingMore) {
                    return ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                      itemCount: state.currentReviews.length + 1,
                      separatorBuilder: (context, index) => const SizedBox(
                        height: AppDimensions.spacingMd,
                      ),
                      itemBuilder: (context, index) {
                        if (index >= state.currentReviews.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppDimensions.paddingMedium),
                              child: LoadingWidget(
                                type: LoadingType.dots,
                              ),
                            ),
                          );
                        }
                        return ReviewCardWidget(
                          review: state.currentReviews[index],
                          onLike: () {
                            // Handle like
                          },
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.textWhite,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'التقييمات',
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
            ),
          ),
          Text(
            widget.propertyName,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppTheme.darkBorder,
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      color: AppTheme.textWhite,
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'الكل',
                  isSelected: _selectedRating == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedRating = null;
                    });
                    _applyFilters();
                  },
                ),
                const SizedBox(width: AppDimensions.spacingSm),
                ...List.generate(5, (index) {
                  final rating = 5 - index;
                  return Padding(
                    padding: const EdgeInsets.only(
                      right: AppDimensions.spacingSm,
                    ),
                    child: _buildFilterChip(
                      label: '$rating ⭐',
                      isSelected: _selectedRating == rating,
                      onSelected: (selected) {
                        setState(() {
                          _selectedRating = selected ? rating : null;
                        });
                        _applyFilters();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  label: 'مع صور فقط',
                  icon: Icons.photo_library_outlined,
                  isSelected: _withImagesOnly,
                  onSelected: (selected) {
                    setState(() {
                      _withImagesOnly = selected;
                    });
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              PopupMenuButton<String>(
                onSelected: (value) {
                  final parts = value.split('-');
                  setState(() {
                    _sortBy = parts[0];
                    _sortDirection = parts[1];
                  });
                  _applyFilters();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'CreatedAt-Desc',
                    child: Text('الأحدث'),
                  ),
                  const PopupMenuItem(
                    value: 'CreatedAt-Asc',
                    child: Text('الأقدم'),
                  ),
                  const PopupMenuItem(
                    value: 'Rating-Desc',
                    child: Text('الأعلى تقييماً'),
                  ),
                  const PopupMenuItem(
                    value: 'Rating-Asc',
                    child: Text('الأقل تقييماً'),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingMedium,
                    vertical: AppDimensions.paddingSmall,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.darkBorder),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.borderRadiusSm,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sort,
                        size: 20,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: AppDimensions.spacingXs),
                      Text(
                        _getSortLabel(),
                        style: AppTextStyles.bodyMedium,
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: AppTheme.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16),
            const SizedBox(width: AppDimensions.spacingXs),
          ],
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
      backgroundColor: AppTheme.darkCard,
      side: BorderSide(
        color: isSelected ? AppTheme.primaryBlue : AppTheme.darkBorder,
      ),
      labelStyle: AppTextStyles.bodySmall.copyWith(
        color: isSelected ? AppTheme.primaryBlue : AppTheme.textMuted,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 80,
            color: AppTheme.textMuted.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          Text(
            'لا توجد تقييمات',
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(
            'كن أول من يقيم هذا العقار',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _getSortLabel() {
    if (_sortBy == 'CreatedAt' && _sortDirection == 'Desc') {
      return 'الأحدث';
    } else if (_sortBy == 'CreatedAt' && _sortDirection == 'Asc') {
      return 'الأقدم';
    } else if (_sortBy == 'Rating' && _sortDirection == 'Desc') {
      return 'الأعلى تقييماً';
    } else if (_sortBy == 'Rating' && _sortDirection == 'Asc') {
      return 'الأقل تقييماً';
    }
    return 'ترتيب';
  }

  void _applyFilters() {
    context.read<ReviewBloc>().add(
      FilterReviewsEvent(
        rating: _selectedRating,
        withImagesOnly: _withImagesOnly,
        sortBy: _sortBy,
        sortDirection: _sortDirection,
      ),
    );
  }
}