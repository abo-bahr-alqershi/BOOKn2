import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../../../core/widgets/rating_widget.dart';
import '../../domain/entities/review.dart';
import 'response_card_widget.dart';
import 'upload_review_image_widget.dart';

class ReviewCardWidget extends StatefulWidget {
  final Review review;
  final VoidCallback? onLike;
  final bool showFullContent;

  const ReviewCardWidget({
    super.key,
    required this.review,
    this.onLike,
    this.showFullContent = false,
  });

  @override
  State<ReviewCardWidget> createState() => _ReviewCardWidgetState();
}

class _ReviewCardWidgetState extends State<ReviewCardWidget> {
  bool _isExpanded = false;
  bool _showAllImages = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLg),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (widget.review.isRecommended) _buildRecommendationBadge(),
            _buildRatingDetails(),
            _buildComment(),
            if (widget.review.hasImages) _buildImages(),
            if (widget.review.hasManagementReply) _buildManagementReply(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserAvatar(),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.review.userName,
                        style: AppTextStyles.heading3.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (widget.review.isUserReview) _buildUserBadge(),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingXs),
                Row(
                  children: [
                    RatingWidget(
                      rating: widget.review.rating,
                      starSize: 16,
                      showLabel: false,
                    ),
                    const SizedBox(width: AppDimensions.spacingSm),
                    Text(
                      widget.review.rating.toStringAsFixed(1),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingXs),
                Text(
                  _formatDate(widget.review.createdAt),
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          _buildOptionsMenu(),
        ],
      ),
    );
  }

  Widget _buildUserAvatar() {
    if (widget.review.userAvatar != null) {
      return ClipOval(
        child: CachedImageWidget(
          imageUrl: widget.review.userAvatar!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          widget.review.userName.isNotEmpty 
              ? widget.review.userName[0].toUpperCase()
              : 'U',
          style: AppTextStyles.heading2.copyWith(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildUserBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSmall,
        vertical: AppDimensions.paddingXSmall,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusXs),
      ),
      child: Text(
        'تقييمك',
        style: AppTextStyles.caption.copyWith(
          color: AppTheme.primaryBlue,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRecommendationBadge() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.thumb_up,
            size: 16,
            color: AppTheme.success,
          ),
          const SizedBox(width: AppDimensions.spacingXs),
          Text(
            'يوصي بهذا المكان',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'التفاصيل',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingXs),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: AppTheme.primaryBlue,
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const SizedBox(height: AppDimensions.spacingSm),
                _buildRatingDetailItem('النظافة', widget.review.cleanliness),
                _buildRatingDetailItem('الخدمة', widget.review.service),
                _buildRatingDetailItem('الموقع', widget.review.location),
                _buildRatingDetailItem('القيمة', widget.review.value),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingDetailItem(String label, int rating) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXs),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: rating / 5,
                    backgroundColor: AppTheme.darkBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getRatingColor(rating.toDouble()),
                    ),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingSm),
                Text(
                  rating.toString(),
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComment() {
    final bool shouldTruncate = !widget.showFullContent && 
                               widget.review.comment.length > 200;
    final String displayText = shouldTruncate && !_isExpanded
        ? '${widget.review.comment.substring(0, 200)}...'
        : widget.review.comment;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.review.title.isNotEmpty) ...[
            Text(
              widget.review.title,
              style: AppTextStyles.heading3.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingSm),
          ],
          Text(
            displayText,
            style: AppTextStyles.bodyMedium.copyWith(
              height: 1.5,
            ),
          ),
          if (shouldTruncate) ...[
            const SizedBox(height: AppDimensions.spacingSm),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Text(
                _isExpanded ? 'عرض أقل' : 'عرض المزيد',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImages() {
    final images = widget.review.images;
    final displayImages = _showAllImages ? images : images.take(3).toList();
    final remainingCount = images.length - 3;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.paddingSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: displayImages.length + (remainingCount > 0 && !_showAllImages ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(
                width: AppDimensions.spacingSm,
              ),
              itemBuilder: (context, index) {
                if (index == displayImages.length && remainingCount > 0 && !_showAllImages) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _showAllImages = true;
                      });
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.borderRadiusMd,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              color: AppTheme.textWhite,
                              size: 28,
                            ),
                            Text(
                              '+$remainingCount',
                              style: AppTextStyles.heading2.copyWith(
                                color: AppTheme.textWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return UploadReviewImageWidget(
                  imageUrl: displayImages[index].url,
                  onTap: () => _showImageGallery(context, images, index),
                );
              },
            ),
          ),
          if (_showAllImages && images.length > 3) ...[
            const SizedBox(height: AppDimensions.spacingSm),
            GestureDetector(
              onTap: () {
                setState(() {
                  _showAllImages = false;
                });
              },
              child: Text(
                'عرض أقل',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildManagementReply() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: ResponseCardWidget(
        reply: widget.review.managementReply!,
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildActionButton(
            icon: widget.review.isLikedByUser 
                ? Icons.thumb_up 
                : Icons.thumb_up_outlined,
            label: widget.review.likesCount > 0 
                ? widget.review.likesCount.toString()
                : 'مفيد',
            color: widget.review.isLikedByUser 
                ? AppTheme.primaryBlue 
                : AppTheme.textMuted,
            onTap: widget.onLike,
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          _buildActionButton(
            icon: Icons.share_outlined,
            label: 'مشاركة',
            color: AppTheme.textMuted,
            onTap: () => _shareReview(),
          ),
          const Spacer(),
          if (widget.review.bookingType != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingSmall,
                vertical: AppDimensions.paddingXSmall,
              ),
              decoration: BoxDecoration(
                color: AppTheme.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusXs,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified,
                    size: 14,
                    color: AppTheme.info,
                  ),
                  const SizedBox(width: AppDimensions.spacingXs),
                  Text(
                    'حجز مؤكد',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.info,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingSmall,
          vertical: AppDimensions.paddingXSmall,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: AppDimensions.spacingXs),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsMenu() {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: AppTheme.textMuted,
        size: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMd),
      ),
      onSelected: (value) {
        switch (value) {
          case 'report':
            _reportReview();
            break;
          case 'share':
            _shareReview();
            break;
        }
      },
      itemBuilder: (context) => [
        if (!widget.review.isUserReview)
          const PopupMenuItem(
            value: 'report',
            child: Row(
              children: [
                Icon(Icons.flag_outlined, size: 20),
                SizedBox(width: 12),
                Text('الإبلاغ عن المراجعة'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share_outlined, size: 20),
              SizedBox(width: 12),
              Text('مشاركة'),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else if (difference.inDays < 30) {
      return 'منذ ${(difference.inDays / 7).floor()} أسابيع';
    } else if (difference.inDays < 365) {
      return DateFormat('d MMMM', 'ar').format(date);
    } else {
      return DateFormat('d MMMM yyyy', 'ar').format(date);
    }
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return AppTheme.success;
    if (rating >= 3.5) return AppTheme.warning;
    if (rating >= 2.5) return AppTheme.warning;
    return AppTheme.error;
  }

  void _showImageGallery(BuildContext context, List<dynamic> images, int initialIndex) {
    // TODO: Implement image gallery viewer
  }

  void _reportReview() {
    // TODO: Implement report review
  }

  void _shareReview() {
    // TODO: Implement share review
  }
}