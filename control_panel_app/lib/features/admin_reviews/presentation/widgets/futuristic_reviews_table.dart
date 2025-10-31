// lib/features/admin_reviews/presentation/widgets/futuristic_reviews_table.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/review.dart';
import 'futuristic_review_card.dart';

class FuturisticReviewsTable extends StatefulWidget {
  final List<Review> reviews;
  final Function(Review) onReviewTap;
  final Function(Review) onApproveTap;
  final Function(Review) onDeleteTap;
  final Set<String> approvingReviewIds;
  final bool shrinkWrap;
  
  const FuturisticReviewsTable({
    super.key,
    required this.reviews,
    required this.onReviewTap,
    required this.onApproveTap,
    required this.onDeleteTap,
    this.approvingReviewIds = const <String>{},
    this.shrinkWrap = false,
  });
  
  @override
  State<FuturisticReviewsTable> createState() => _FuturisticReviewsTableState();
}

class _FuturisticReviewsTableState extends State<FuturisticReviewsTable> {
  int? _hoveredIndex;
  String _sortBy = 'date';
  bool _ascending = false;
  
  List<Review> get _sortedReviews {
    final sorted = List<Review>.from(widget.reviews);
    
    switch (_sortBy) {
      case 'date':
        sorted.sort((a, b) => _ascending 
            ? a.createdAt.compareTo(b.createdAt)
            : b.createdAt.compareTo(a.createdAt));
        break;
      case 'rating':
        sorted.sort((a, b) => _ascending
            ? a.averageRating.compareTo(b.averageRating)
            : b.averageRating.compareTo(a.averageRating));
        break;
      case 'user':
        sorted.sort((a, b) => _ascending
            ? a.userName.compareTo(b.userName)
            : b.userName.compareTo(a.userName));
        break;
      case 'property':
        sorted.sort((a, b) => _ascending
            ? a.propertyName.compareTo(b.propertyName)
            : b.propertyName.compareTo(a.propertyName));
        break;
      case 'status':
        sorted.sort((a, b) {
          final statusA = a.isPending ? 0 : (a.isApproved ? 1 : 2);
          final statusB = b.isPending ? 0 : (b.isApproved ? 1 : 2);
          return _ascending 
              ? statusA.compareTo(statusB)
              : statusB.compareTo(statusA);
        });
        break;
    }
    
    return sorted;
  }
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1200;
    final isCompact = size.width < 480;
    
    // في الشاشات الصغيرة جداً، نعرض كروت بدلاً من جدول
    if (isCompact) {
      return ListView.builder(
        shrinkWrap: widget.shrinkWrap,
        physics: widget.shrinkWrap
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: _sortedReviews.length,
        itemBuilder: (context, index) {
          final review = _sortedReviews[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FuturisticReviewCard(
              review: review,
              onTap: () => widget.onReviewTap(review),
              onApprove: () => widget.onApproveTap(review),
              onDelete: () => widget.onDeleteTap(review),
              isApproving: widget.approvingReviewIds.contains(review.id),
            ),
          );
        },
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkCard.withOpacity(0.7),
            AppTheme.darkCard.withOpacity(0.5),
          ],
        ),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowDark.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              // رأس الجدول
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.darkBorder.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withOpacity(0.05),
                      AppTheme.primaryPurple.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 16,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      _buildHeaderCell(
                        'المستخدم',
                        flex: 2,
                        sortKey: 'user',
                        isFirst: true,
                        isCompact: isCompact,
                      ),
                      _buildHeaderCell(
                        'العقار',
                        flex: 2,
                        sortKey: 'property',
                        isCompact: isCompact,
                      ),
                      _buildHeaderCell(
                        'التقييم',
                        flex: 1,
                        sortKey: 'rating',
                        isCompact: isCompact,
                      ),
                      if (isDesktop) ...[
                        _buildHeaderCell(
                          'التاريخ',
                          flex: 1,
                          sortKey: 'date',
                          isCompact: isCompact,
                        ),
                        _buildHeaderCell(
                          'الحالة',
                          flex: 1,
                          sortKey: 'status',
                          isCompact: isCompact,
                        ),
                      ],
                      _buildHeaderCell(
                        'الإجراءات',
                        flex: 1,
                        sortable: false,
                        isCompact: isCompact,
                      ),
                    ],
                  ),
                ),
              ),
              
              // جسم الجدول
              widget.shrinkWrap
                  ? ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _sortedReviews.length,
                      itemBuilder: (context, index) {
                        final review = _sortedReviews[index];
                        return _buildTableRow(review, index, isDesktop);
                      },
                    )
                  : Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _sortedReviews.length,
                        itemBuilder: (context, index) {
                          final review = _sortedReviews[index];
                          return _buildTableRow(review, index, isDesktop);
                        },
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeaderCell(
    String title, {
    required int flex,
    String? sortKey,
    bool sortable = true,
    bool isFirst = false,
    bool isCompact = false,
  }) {
    final isActive = _sortBy == sortKey;
    
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: sortable && sortKey != null
            ? () {
                HapticFeedback.lightImpact();
                setState(() {
                  if (_sortBy == sortKey) {
                    _ascending = !_ascending;
                  } else {
                    _sortBy = sortKey;
                    _ascending = false;
                  }
                });
              }
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.only(
            right: isFirst ? 0 : 8,
            left: 8,
            top: isCompact ? 2 : 4,
            bottom: isCompact ? 2 : 4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: isCompact ? 11 : null,
                    fontWeight: FontWeight.w600,
                    color: isActive 
                        ? AppTheme.primaryBlue
                        : AppTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (sortable && sortKey != null && !isCompact) ...[
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: isActive && _ascending ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.arrow_downward,
                    size: 14,
                    color: isActive
                        ? AppTheme.primaryBlue
                        : AppTheme.textMuted.withOpacity(0.3),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTableRow(Review review, int index, bool isDesktop) {
    final isHovered = _hoveredIndex == index;
    final bool isApproving = widget.approvingReviewIds.contains(review.id);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isHovered
              ? AppTheme.primaryBlue.withOpacity(0.05)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: AppTheme.darkBorder.withOpacity(0.1),
              width: 0.5,
            ),
          ),
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onReviewTap(review);
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 16,
              vertical: 16,
            ),
                  child: Row(
              children: [
                // خلية المستخدم
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.primaryGradient,
                        ),
                        child: Center(
                          child: Text(
                            review.userName.substring(0, 2).toUpperCase(),
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review.userName,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textWhite,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (!isDesktop) ...[
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(review.createdAt),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // خلية العقار
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      review.propertyName,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.textLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                
                // خلية التقييم
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        fit: FlexFit.loose,
                        child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: _getRatingColor(review.averageRating).withOpacity(0.1),
                          border: Border.all(
                            color: _getRatingColor(review.averageRating).withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: _getRatingColor(review.averageRating),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  review.averageRating.toStringAsFixed(1),
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: _getRatingColor(review.averageRating),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // خلية التاريخ (سطح المكتب فقط)
                if (isDesktop) ...[
                  Expanded(
                    flex: 1,
                    child: Text(
                      _formatDate(review.createdAt),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                  
                  // خلية الحالة
                  Expanded(
                    flex: 1,
                    child: _buildStatusBadge(review),
                  ),
                ],
                
                // خلية الإجراءات
                Expanded(
                  flex: 1,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (review.isPending)
                        (isApproving
                            ? _buildLoadingPill(color: AppTheme.success)
                            : _buildActionButton(
                                icon: Icons.check,
                                color: AppTheme.success,
                                onTap: () => widget.onApproveTap(review),
                              )),
                      _buildActionButton(
                        icon: Icons.delete_outline,
                        color: AppTheme.error,
                        onTap: () => widget.onDeleteTap(review),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusBadge(Review review) {
    final color = review.isPending
        ? AppTheme.warning
        : review.isApproved
            ? AppTheme.success
            : AppTheme.error;
    
    final text = review.isPending
        ? 'قيد المراجعة'
        : review.isApproved
            ? 'معتمد'
            : 'مرفوض';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.1),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: color.withOpacity(0.1),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingPill({required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.1),
      ),
      child: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
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
    
    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}