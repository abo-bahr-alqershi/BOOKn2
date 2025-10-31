import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../domain/entities/property_detail.dart';

class PropertyImagesGridWidget extends StatefulWidget {
  final List<PropertyImage> images;
  final Function(int)? onImageTap;
  final double height;

  const PropertyImagesGridWidget({
    super.key,
    required this.images,
    this.onImageTap,
    this.height = 320,
  });

  @override
  State<PropertyImagesGridWidget> createState() =>
      _PropertyImagesGridWidgetState();
}

class _PropertyImagesGridWidgetState extends State<PropertyImagesGridWidget>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _scaleController;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return _buildEmptyState();
    }

    if (widget.images.length == 1) {
      return _buildSingleImage();
    }

    if (widget.images.length == 2) {
      return _buildTwoImagesLayout();
    }

    if (widget.images.length == 3) {
      return _buildThreeImagesLayout();
    }

    return _buildMultiImagesLayout();
  }

  Widget _buildEmptyState() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.6),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.15),
                    AppTheme.primaryBlue.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.image_not_supported_outlined,
                size: 28,
                color: AppTheme.textMuted.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد صور متاحة',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleImage() {
    return GestureDetector(
      onTap: () => widget.onImageTap?.call(0),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImageWithEffects(widget.images[0], 0, true),
            _buildGradientOverlay(),
            _buildImageCounter(1, 1),
          ],
        ),
      ),
    );
  }

  Widget _buildTwoImagesLayout() {
    return SizedBox(
      height: widget.height,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => widget.onImageTap?.call(0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImageWithEffects(widget.images[0], 0, true),
                  _buildGradientOverlay(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 1),
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () => widget.onImageTap?.call(1),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImageWithEffects(widget.images[1], 1, false),
                  _buildGradientOverlay(),
                  _buildImageCounter(2, 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreeImagesLayout() {
    return SizedBox(
      height: widget.height,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => widget.onImageTap?.call(0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImageWithEffects(widget.images[0], 0, true),
                  _buildGradientOverlay(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 1),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onImageTap?.call(1),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImageWithEffects(widget.images[1], 1, false),
                        _buildGradientOverlay(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onImageTap?.call(2),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImageWithEffects(widget.images[2], 2, false),
                        _buildGradientOverlay(),
                        _buildImageCounter(3, 3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiImagesLayout() {
    return SizedBox(
      height: widget.height,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => widget.onImageTap?.call(0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImageWithEffects(widget.images[0], 0, true),
                  _buildGradientOverlay(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 1),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onImageTap?.call(1),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImageWithEffects(widget.images[1], 1, false),
                        _buildGradientOverlay(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => widget.onImageTap?.call(2),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _buildImageWithEffects(widget.images[2], 2, false),
                              _buildGradientOverlay(),
                            ],
                          ),
                        ),
                      ),
                      if (widget.images.length > 3) ...[
                        const SizedBox(width: 1),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => widget.onImageTap?.call(3),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (widget.images.length > 4)
                                  _buildMoreImagesOverlay(widget.images.length - 4)
                                else
                                  _buildImageWithEffects(widget.images[3], 3, false),
                                _buildGradientOverlay(),
                                if (widget.images.length == 4)
                                  _buildImageCounter(4, 4),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWithEffects(PropertyImage image, int index, bool isMain) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..scale(_hoveredIndex == index ? 1.02 : 1.0),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedImageWidget(
              imageUrl: image.url,
              fit: BoxFit.cover,
            ),
            if (_hoveredIndex == index)
              AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ShimmerPainter(
                      shimmerPosition: _shimmerController.value,
                    ),
                  );
                },
              ),
            if (isMain)
              Positioned(
                top: 12,
                left: 12,
                child: _buildFeaturedBadge(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreImagesOverlay(int remainingCount) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.images.length > 3)
          CachedImageWidget(
            imageUrl: widget.images[3].url,
            fit: BoxFit.cover,
          ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.darkBackground.withOpacity(0.7),
          ),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.photo_library,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShaderMask(
                      shaderCallback: (bounds) => 
                          AppTheme.primaryGradient.createShader(bounds),
                      child: Text(
                        '+$remainingCount',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      'صور إضافية',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppTheme.darkBackground.withOpacity(0.15),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCounter(int current, int total) {
    return Positioned(
      bottom: 10,
      right: 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkBackground.withOpacity(0.7),
                  AppTheme.darkBackground.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.photo_camera,
                  size: 12,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  '$current / $total',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            size: 10,
            color: Colors.white,
          ),
          const SizedBox(width: 3),
          Text(
            'مميز',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  final double shimmerPosition;
  
  _ShimmerPainter({required this.shimmerPosition});
  
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment(-1.0 + shimmerPosition * 2, -1.0 + shimmerPosition * 2),
      end: Alignment(-0.5 + shimmerPosition * 2, -0.5 + shimmerPosition * 2),
      colors: [
        Colors.transparent,
        Colors.white.withOpacity(0.08),
        Colors.white.withOpacity(0.15),
        Colors.white.withOpacity(0.08),
        Colors.transparent,
      ],
      stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(rect, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}