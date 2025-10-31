// lib/features/admin_reviews/presentation/widgets/review_images_gallery.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/review_image.dart';

class ReviewImagesGallery extends StatefulWidget {
  final List<ReviewImage> images;
  final bool isDesktop;

  const ReviewImagesGallery({
    super.key,
    required this.images,
    required this.isDesktop,
  });

  @override
  State<ReviewImagesGallery> createState() => _ReviewImagesGalleryState();
}

class _ReviewImagesGalleryState extends State<ReviewImagesGallery>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int? _selectedImageIndex;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = widget.isDesktop ? 4 : 3;
    final aspectRatio = widget.isDesktop ? 1.5 : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // معرض الصور بشبكة
        ScaleTransition(
          scale: _scaleAnimation,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return _buildImageThumbnail(index);
            },
          ),
        ),

        // معلومات الصور
        if (widget.images.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildImageInfo(),
          ),
      ],
    );
  }

  Widget _buildImageThumbnail(int index) {
    final image = widget.images[index];
    final isSelected = _selectedImageIndex == index;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedImageIndex = index);
              _showImageViewer(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryBlue
                      : AppTheme.darkBorder.withOpacity(0.3),
                  width: isSelected ? 2 : 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppTheme.primaryBlue.withOpacity(0.3)
                        : Colors.black.withOpacity(0.2),
                    blurRadius: isSelected ? 20 : 10,
                    spreadRadius: isSelected ? 2 : 0,
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // الصورة
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      image.url,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppTheme.darkCard,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: AppTheme.primaryBlue,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.darkCard,
                                AppTheme.darkCard.withOpacity(0.8),
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AppTheme.textMuted,
                            size: 32,
                          ),
                        );
                      },
                    ),
                  ),

                  // تدرج التراكب
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // شارة الفئة
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppTheme.inputBackground.withOpacity(0.8),
                        border: Border.all(
                          color: AppTheme.glowWhite.withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        _getCategoryName(image.category),
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // رقم الصورة
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppTheme.inputBackground.withOpacity(0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.photo_outlined,
                            size: 12,
                            color: AppTheme.glowWhite,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${index + 1}/${widget.images.length}',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.glowWhite,
                            ),
                          ),
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
    );
  }

  Widget _buildImageInfo() {
    final totalSize = widget.images.fold<int>(
      0,
      (sum, image) => sum + image.sizeBytes,
    );

    final categoryCounts = <ImageCategory, int>{};
    for (final image in widget.images) {
      categoryCounts[image.category] =
          (categoryCounts[image.category] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.inputBackground.withOpacity(0.3),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // إجمالي الصور
          _buildInfoItem(
            icon: Icons.collections_outlined,
            label: 'الإجمالي',
            value: '${widget.images.length} صورة',
          ),
          const SizedBox(width: 24),

          // الحجم الإجمالي
          _buildInfoItem(
            icon: Icons.storage_outlined,
            label: 'الحجم',
            value: _formatFileSize(totalSize),
          ),
          const SizedBox(width: 24),

          // الفئات
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categoryCounts.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    '${_getCategoryName(entry.key)} (${entry.value})',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.textMuted,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
            Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textWhite,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showImageViewer(int initialIndex) {
    showDialog(
      fullscreenDialog: true,
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _ImageViewerDialog(
        images: widget.images,
        initialIndex: initialIndex,
      ),
    );
  }

  String _getCategoryName(ImageCategory category) {
    switch (category) {
      case ImageCategory.exterior:
        return 'خارجي';
      case ImageCategory.interior:
        return 'داخلي';
      case ImageCategory.amenity:
        return 'مرافق';
      case ImageCategory.floorPlan:
        return 'مخطط';
      case ImageCategory.documents:
        return 'مستندات';
      case ImageCategory.avatar:
        return 'صورة شخصية';
      case ImageCategory.cover:
        return 'غلاف';
      case ImageCategory.gallery:
        return 'معرض';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes بايت';
    if (bytes < 1024 * 1024)
      return '${(bytes / 1024).toStringAsFixed(1)} كيلوبايت';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} ميجابايت';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} جيجابايت';
  }
}

// نافذة عرض الصور
class _ImageViewerDialog extends StatefulWidget {
  final List<ReviewImage> images;
  final int initialIndex;

  const _ImageViewerDialog({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<_ImageViewerDialog>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.all(10),
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: size.width * 0.9,
          height: size.height * 0.8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: AppTheme.darkBackground,
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Column(
                children: [
                  // الرأس
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.darkBorder.withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // معلومات الصورة
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.images[_currentIndex].name,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textWhite,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_currentIndex + 1} من ${widget.images.length}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // زر الإغلاق
                        IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.inputBackground.withOpacity(0.5),
                            ),
                            child: Icon(
                              Icons.close,
                              color: AppTheme.textWhite,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // عارض الصور
                  Expanded(
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() => _currentIndex = index);
                          },
                          itemCount: widget.images.length,
                          itemBuilder: (context, index) {
                            return InteractiveViewer(
                              panEnabled: true,
                              minScale: 0.5,
                              maxScale: 4.0,
                              child: Center(
                                child: Image.network(
                                  widget.images[index].url,
                                  fit: BoxFit.contain,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),

                        // أزرار التنقل
                        if (_currentIndex > 0)
                          Positioned(
                            left: 16,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: _buildNavButton(
                                icon: Icons.chevron_left,
                                onTap: () {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                              ),
                            ),
                          ),

                        if (_currentIndex < widget.images.length - 1)
                          Positioned(
                            right: 16,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: _buildNavButton(
                                icon: Icons.chevron_right,
                                onTap: () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // الصور المصغرة
                  Container(
                    height: 80,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppTheme.darkBorder.withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.images.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == _currentIndex;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 56,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryBlue
                                    : AppTheme.darkBorder.withOpacity(0.3),
                                width: isSelected ? 2 : 0.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.images[index].url,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.inputBackground.withOpacity(0.8),
          border: Border.all(
            color: AppTheme.glowWhite.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          color: AppTheme.glowWhite,
          size: 24,
        ),
      ),
    );
  }
}
