// lib/features/admin_cities/presentation/widgets/city_images_collage.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/cached_image_widget.dart';

class CityImagesCollage extends StatefulWidget {
  final List<String> images;
  final double height;
  final double? width;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool showImageCount;
  final bool enableHoverEffect;

  const CityImagesCollage({
    super.key,
    required this.images,
    this.height = 200,
    this.width,
    this.borderRadius,
    this.onTap,
    this.showImageCount = true,
    this.enableHoverEffect = true,
  });

  @override
  State<CityImagesCollage> createState() => _CityImagesCollageState();
}

class _CityImagesCollageState extends State<CityImagesCollage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return _buildEmptyState();
    }

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.enableHoverEffect
                  ? 1.0 - (_animationController.value * 0.02)
                  : 1.0,
              child: Container(
                height: widget.height,
                width: widget.width,
                decoration: BoxDecoration(
                  borderRadius:
                      widget.borderRadius ?? BorderRadius.circular(16),
                  boxShadow: widget.enableHoverEffect
                      ? [
                          BoxShadow(
                            color: AppTheme.shadowDark.withOpacity(
                              0.2 + (_animationController.value * 0.1),
                            ),
                            blurRadius: 20 + (_animationController.value * 10),
                            offset: Offset(
                                0, 10 + (_animationController.value * 5)),
                          ),
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius:
                      widget.borderRadius ?? BorderRadius.circular(16),
                  child: _buildLayout(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _onHover(bool isHovered) {
    if (!widget.enableHoverEffect) return;
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  Widget _buildLayout() {
    final imageCount = widget.images.length;

    // تحديد التخطيط بناءً على عدد الصور (مثل تيليجرام/واتساب)
    switch (imageCount) {
      case 1:
        return _buildSingleImage();
      case 2:
        return _buildTwoImages();
      case 3:
        return _buildThreeImages();
      case 4:
        return _buildFourImages();
      case 5:
        return _buildFiveImages();
      case 6:
        return _buildSixImages();
      default:
        return _buildManyImages();
    }
  }

  // تخطيط صورة واحدة
  Widget _buildSingleImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildImage(widget.images[0]),
        _buildGradientOverlay(),
      ],
    );
  }

  // تخطيط صورتين (جنب بعض)
  Widget _buildTwoImages() {
    return Stack(
      children: [
        Row(
          children: [
            Expanded(child: _buildImage(widget.images[0])),
            const SizedBox(width: 2),
            Expanded(child: _buildImage(widget.images[1])),
          ],
        ),
        _buildGradientOverlay(),
      ],
    );
  }

  // تخطيط 3 صور (واحدة كبيرة يسار واثنتين صغيرتين يمين)
  Widget _buildThreeImages() {
    return Stack(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildImage(widget.images[0]),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _buildImage(widget.images[1])),
                  const SizedBox(height: 2),
                  Expanded(child: _buildImage(widget.images[2])),
                ],
              ),
            ),
          ],
        ),
        _buildGradientOverlay(),
      ],
    );
  }

  // تخطيط 4 صور (شبكة 2×2)
  Widget _buildFourImages() {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildImage(widget.images[0])),
                  const SizedBox(width: 2),
                  Expanded(child: _buildImage(widget.images[1])),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildImage(widget.images[2])),
                  const SizedBox(width: 2),
                  Expanded(child: _buildImage(widget.images[3])),
                ],
              ),
            ),
          ],
        ),
        _buildGradientOverlay(),
      ],
    );
  }

  // تخطيط 5 صور (صورتين فوق و3 تحت)
  Widget _buildFiveImages() {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Expanded(child: _buildImage(widget.images[0])),
                  const SizedBox(width: 2),
                  Expanded(child: _buildImage(widget.images[1])),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(child: _buildImage(widget.images[2])),
                  const SizedBox(width: 2),
                  Expanded(child: _buildImage(widget.images[3])),
                  const SizedBox(width: 2),
                  Expanded(child: _buildImage(widget.images[4])),
                ],
              ),
            ),
          ],
        ),
        _buildGradientOverlay(),
      ],
    );
  }

  // تخطيط 6 صور (شبكة 3×2)
  Widget _buildSixImages() {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildImage(widget.images[0])),
                  const SizedBox(width: 2),
                  Expanded(child: _buildImage(widget.images[1])),
                  const SizedBox(width: 2),
                  Expanded(child: _buildImage(widget.images[2])),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildImage(widget.images[3])),
                  const SizedBox(width: 2),
                  Expanded(child: _buildImage(widget.images[4])),
                  const SizedBox(width: 2),
                  Expanded(child: _buildImage(widget.images[5])),
                ],
              ),
            ),
          ],
        ),
        _buildGradientOverlay(),
      ],
    );
  }

  // تخطيط للصور الكثيرة (عرض أول 4 مع عداد)
  Widget _buildManyImages() {
    final displayImages = widget.images.take(4).toList();
    final remainingCount = widget.images.length - 4;

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildImage(displayImages[0])),
                  const SizedBox(width: 2),
                  Expanded(child: _buildImage(displayImages[1])),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildImage(displayImages[2])),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImage(displayImages[3]),
                        if (remainingCount > 0)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                            ),
                            child: Center(
                              child: Text(
                                '+$remainingCount',
                                style: AppTextStyles.heading2.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        _buildGradientOverlay(),
      ],
    );
  }

  Widget _buildImage(String imageUrl) {
    return CachedImageWidget(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
    );
  }

  Widget _buildGradientOverlay() {
    if (!widget.showImageCount || widget.images.length <= 1) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.photo,
              size: 12,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              '${widget.images.length}',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkCard.withOpacity(0.5),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.photo,
              size: 32,
              color: AppTheme.textMuted.withOpacity(0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'لا توجد صور',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
