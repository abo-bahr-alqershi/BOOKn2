// lib/features/admin_reviews/presentation/widgets/futuristic_review_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/review.dart';

class FuturisticReviewCard extends StatefulWidget {
  final Review review;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onDelete;
  final bool isApproving;

  const FuturisticReviewCard({
    super.key,
    required this.review,
    required this.onTap,
    required this.onApprove,
    required this.onDelete,
    this.isApproving = false,
  });

  @override
  State<FuturisticReviewCard> createState() => _FuturisticReviewCardState();
}

class _FuturisticReviewCardState extends State<FuturisticReviewCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _animationController.forward(),
            onTapUp: (_) {
              _animationController.reverse();
              HapticFeedback.lightImpact();
              widget.onTap();
            },
            onTapCancel: () => _animationController.reverse(),
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.darkCard.withOpacity(_isHovered ? 0.9 : 0.7),
                      AppTheme.darkCard.withOpacity(_isHovered ? 0.7 : 0.5),
                    ],
                  ),
                  border: Border.all(
                    color: _isHovered
                        ? AppTheme.glowBlue.withOpacity(0.3)
                        : AppTheme.darkBorder.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isHovered
                          ? AppTheme.glowBlue.withOpacity(0.2)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: _isHovered ? 30 : 20,
                      spreadRadius: _isHovered ? 5 : 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Stack(
                      children: [
                        // نمط الخلفية
                        if (_isHovered)
                          Positioned(
                            top: -50,
                            right: -50,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppTheme.primaryBlue.withOpacity(0.1),
                                    AppTheme.primaryBlue.withOpacity(0.01),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // المحتوى
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // الرأس
                              Row(
                                children: [
                                  // صورة المستخدم
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppTheme.primaryGradient,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.glowBlue
                                              .withOpacity(0.3),
                                          blurRadius: 15,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        widget.review.userName
                                            .substring(0, 2)
                                            .toUpperCase(),
                                        style:
                                            AppTextStyles.bodyMedium.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // معلومات المستخدم
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.review.userName,
                                          style:
                                              AppTextStyles.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textWhite,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          widget.review.propertyName,
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppTheme.textMuted,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // شارة الحالة
                                  _buildStatusBadge(),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // التقييم
                              Row(
                                children: [
                                  ...List.generate(5, (index) {
                                    final filled = index <
                                        widget.review.averageRating.floor();
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 2),
                                      child: Icon(
                                        filled
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        color: filled
                                            ? AppTheme.warning
                                            : AppTheme.textMuted,
                                        size: 18,
                                      ),
                                    );
                                  }),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.review.averageRating
                                        .toStringAsFixed(1),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.warning,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // عرض كامل للتعليق
                              Text(
                                widget.review.comment,
                                style: AppTextStyles.bodySmall.copyWith(
                                  height: 1.5,
                                  color: AppTheme.textLight,
                                ),
                                softWrap: true,
                              ),
                              if (widget.review.images.isNotEmpty ||
                                  widget.review.hasResponse)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      if (widget.review.images.isNotEmpty) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            color: AppTheme.primaryBlue
                                                .withOpacity(0.1),
                                            border: Border.all(
                                              color: AppTheme.primaryBlue
                                                  .withOpacity(0.3),
                                              width: 0.5,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.image,
                                                size: 12,
                                                color: AppTheme.primaryBlue,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${widget.review.images.length}',
                                                style: AppTextStyles.caption
                                                    .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.primaryBlue,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      if (widget.review.hasResponse)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            color: AppTheme.success
                                                .withOpacity(0.1),
                                            border: Border.all(
                                              color: AppTheme.success
                                                  .withOpacity(0.3),
                                              width: 0.5,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.reply,
                                                size: 12,
                                                color: AppTheme.success,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'تم الرد',
                                                style: AppTextStyles.caption
                                                    .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.success,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 4),

                              // التذييل
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // التاريخ
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: AppTheme.textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(widget.review.createdAt),
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // الإجراءات
                                  Row(
                                    children: [
                                      if (widget.review.isPending)
                                        (widget.isApproving
                                            ? _buildLoadingPill(
                                                color: AppTheme.success)
                                            : _buildActionButton(
                                                icon: Icons.check,
                                                color: AppTheme.success,
                                                onTap: widget.onApprove,
                                              )),
                                      const SizedBox(width: 8),
                                      _buildActionButton(
                                        icon: Icons.delete_outline,
                                        color: AppTheme.error,
                                        onTap: widget.onDelete,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge() {
    final color = widget.review.isPending
        ? AppTheme.warning
        : widget.review.isApproved
            ? AppTheme.success
            : AppTheme.error;

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
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
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withOpacity(0.1),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLoadingPill({required Color color}) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.1),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 0.5,
        ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'منذ ${difference.inMinutes} دقيقة';
      }
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
