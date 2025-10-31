// lib/features/admin_units/presentation/pages/unit_gallery_page.dart

import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';
import '../../domain/entities/unit.dart';
import '../../domain/entities/unit_image.dart';
import '../bloc/unit_images/unit_images_bloc.dart';
import '../bloc/unit_images/unit_images_event.dart';
import '../bloc/unit_images/unit_images_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class UnitGalleryPage extends StatefulWidget {
  final String unitId;
  final Unit? unit;
  
  const UnitGalleryPage({
    super.key,
    required this.unitId,
    this.unit,
  });

  @override
  State<UnitGalleryPage> createState() => _UnitGalleryPageState();
}

class _UnitGalleryPageState extends State<UnitGalleryPage>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _backgroundAnimationController;
  late AnimationController _contentAnimationController;
  late AnimationController _floatingUIController;
  late AnimationController _pulseController;
  late AnimationController _gridAnimationController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatingUIAnimation;
  
  // Gallery State
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  String _viewMode = 'grid'; // grid, carousel, fullscreen
  bool _showInfo = true;
  bool _isZoomed = false;
  List<UnitImage> _images = [];
  
  // Grid Settings
  int _gridColumns = 3;
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadImages();
    _setupScrollListener();
  }
  
  void _initializeAnimations() {
    // Background Animation
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    // Content Animation
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    ));
    
    // Floating UI Animation
    _floatingUIController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _floatingUIAnimation = CurvedAnimation(
      parent: _floatingUIController,
      curve: Curves.easeOutBack,
    );
    
    // Pulse Animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Grid Animation
    _gridAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Start animations
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _contentAnimationController.forward();
        _floatingUIController.forward();
        _gridAnimationController.forward();
      }
    });
  }
  
  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Add any scroll-based animations here
    });
  }
  
  void _loadImages() {
    context.read<UnitImagesBloc>().add(LoadUnitImagesEvent(unitId: widget.unitId));
  }
  
  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _contentAnimationController.dispose();
    _floatingUIController.dispose();
    _pulseController.dispose();
    _gridAnimationController.dispose();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UnitImagesBloc, UnitImagesState>(
      listener: (context, state) {
        if (state is UnitImagesLoaded) {
          setState(() {
            _images = state.images;
          });
        } else if (state is UnitImagesError) {
          _showErrorMessage(state.message);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppTheme.darkBackground,
          body: Stack(
            children: [
              // Animated Background
              _buildAnimatedBackground(),
              
              // Main Content
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: _buildContent(state),
              ),
              
              // Floating Header
              _buildFloatingHeader(),
              
              // View Mode Selector
              if (_images.isNotEmpty && _viewMode != 'fullscreen')
                _buildViewModeSelector(),
              
              // Floating Info Panel (for carousel/fullscreen)
              if (_viewMode != 'grid' && _showInfo && _images.isNotEmpty)
                _buildFloatingInfoPanel(),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkBackground,
                AppTheme.darkBackground2.withOpacity(0.9),
                AppTheme.darkBackground3.withOpacity(0.7),
              ],
            ),
          ),
          child: CustomPaint(
            painter: _GalleryBackgroundPainter(
              animation: _backgroundAnimationController.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
  
  Widget _buildContent(UnitImagesState state) {
    if (state is UnitImagesLoading) {
      return _buildLoadingState();
    }
    
    if (state is UnitImagesError) {
      return _buildErrorState(state.message);
    }
    
    if (_images.isEmpty) {
      return _buildEmptyState();
    }
    
    switch (_viewMode) {
      case 'carousel':
        return _buildCarouselView();
      case 'fullscreen':
        return _buildFullscreenView();
      default:
        return _buildGridView();
    }
  }
  
  Widget _buildFloatingHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ScaleTransition(
        scale: _floatingUIAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.darkCard.withOpacity(0.9),
                AppTheme.darkCard.withOpacity(0.7),
                AppTheme.darkCard.withOpacity(0.0),
              ],
            ),
          ),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Back Button
                      _buildIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => context.pop(),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => 
                                AppTheme.primaryGradient.createShader(bounds),
                              child: Text(
                                'معرض الصور',
                                style: AppTextStyles.heading2.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (_images.isNotEmpty)
                              Text(
                                '${_images.length} صورة',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Grid Size Selector (only in grid mode)
                      if (_viewMode == 'grid' && _images.isNotEmpty)
                        _buildGridSizeSelector(),
                      
                      const SizedBox(width: 12),
                      
                      // Download All Button
                      if (_images.isNotEmpty)
                        _buildIconButton(
                          icon: Icons.download_rounded,
                          onTap: _downloadAllImages,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildViewModeSelector() {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: ScaleTransition(
        scale: _floatingUIAnimation,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkCard.withOpacity(0.9),
                  AppTheme.darkCard.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppTheme.darkBorder.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewModeButton(
                      icon: Icons.grid_view_rounded,
                      label: 'شبكة',
                      mode: 'grid',
                    ),
                    _buildViewModeButton(
                      icon: Icons.view_carousel_rounded,
                      label: 'عرض',
                      mode: 'carousel',
                    ),
                    _buildViewModeButton(
                      icon: Icons.fullscreen_rounded,
                      label: 'ملء',
                      mode: 'fullscreen',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildViewModeButton({
    required IconData icon,
    required String label,
    required String mode,
  }) {
    final isActive = _viewMode == mode;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _viewMode = mode;
          if (mode == 'fullscreen') {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
          } else {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isActive ? AppTheme.primaryGradient : null,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isActive ? Colors.white : AppTheme.textMuted,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGridView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimationLimiter(
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(
                top: 140,
                left: 16,
                right: 16,
                bottom: 100,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _gridColumns,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  duration: const Duration(milliseconds: 600),
                  columnCount: _gridColumns,
                  child: ScaleAnimation(
                    scale: 0.9,
                    child: FadeInAnimation(
                      child: _buildGridItem(_images[index], index),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildGridItem(UnitImage image, int index) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _openImageViewer(index);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Hero(
          tag: 'gallery-image-${image.id}',
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  CachedNetworkImage(
                    imageUrl: image.thumbnails.medium,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildImagePlaceholder(),
                    errorWidget: (context, url, error) => _buildImageError(),
                  ),
                  
                  // Gradient Overlay
                  _buildImageOverlay(image, index),
                  
                  // Image Info
                  _buildImageInfo(image, index),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.5),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryBlue.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildImageError() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.5),
      ),
      child: Icon(
        Icons.broken_image_outlined,
        color: AppTheme.textMuted.withOpacity(0.3),
        size: 32,
      ),
    );
  }
  
  Widget _buildImageOverlay(UnitImage image, int index) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.4),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImageInfo(UnitImage image, int index) {
    return Positioned(
      bottom: 8,
      left: 8,
      right: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary Badge
          if (image.isPrimary)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.warning,
                    AppTheme.warning.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'رئيسية',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          
          // Image Number
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}/${_images.length}',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              // Image Size
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  image.sizeInMB + ' MB',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildCarouselView() {
    return Stack(
      children: [
        // Main Carousel
        PageView.builder(
          controller: _pageController,
          itemCount: _images.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return _buildCarouselItem(_images[index], index);
          },
        ),
        
        // Thumbnail Strip
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: _buildThumbnailStrip(),
        ),
        
        // Page Indicator
        Positioned(
          bottom: 160,
          left: 0,
          right: 0,
          child: _buildPageIndicator(),
        ),
      ],
    );
  }
  
  Widget _buildCarouselItem(UnitImage image, int index) {
    return GestureDetector(
      onTap: () => _openImageViewer(index),
      onDoubleTap: () {
        setState(() {
          _isZoomed = !_isZoomed;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(_isZoomed ? 0 : 40),
        child: Hero(
          tag: 'carousel-image-${image.id}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_isZoomed ? 0 : 20),
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: image.url,
                fit: _isZoomed ? BoxFit.contain : BoxFit.cover,
                placeholder: (context, url) => _buildImagePlaceholder(),
                errorWidget: (context, url, error) => _buildImageError(),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildThumbnailStrip() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _images.length,
        itemBuilder: (context, index) {
          final isActive = index == _currentIndex;
          
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
              width: isActive ? 70 : 60,
              height: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? AppTheme.primaryBlue
                      : AppTheme.darkBorder.withOpacity(0.3),
                  width: isActive ? 2 : 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: _images[index].thumbnails.small,
                      fit: BoxFit.cover,
                    ),
                    if (!isActive)
                      Container(
                        color: Colors.black.withOpacity(0.3),
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
  
  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_images.length, (index) {
        final isActive = index == _currentIndex;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActive ? 24 : 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primaryBlue
                : AppTheme.darkBorder.withOpacity(0.3),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
  
  Widget _buildFullscreenView() {
    return PhotoViewGallery.builder(
      pageController: _pageController,
      itemCount: _images.length,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      builder: (context, index) {
        return PhotoViewGalleryPageOptions(
          imageProvider: CachedNetworkImageProvider(_images[index].url),
          heroAttributes: PhotoViewHeroAttributes(
            tag: 'fullscreen-image-${_images[index].id}',
          ),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
        );
      },
      backgroundDecoration: BoxDecoration(
        color: AppTheme.darkBackground,
      ),
      loadingBuilder: (context, event) => Center(
        child: CircularProgressIndicator(
          value: event == null ? 0 : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
        ),
      ),
    );
  }
  
  Widget _buildFloatingInfoPanel() {
    if (_images.isEmpty) return const SizedBox.shrink();
    
    final currentImage = _images[_currentIndex];
    
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: ScaleTransition(
        scale: _floatingUIAnimation,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _showInfo = !_showInfo;
            });
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.darkCard.withOpacity(0.8),
                      AppTheme.darkCard.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.darkBorder.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image Counter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_currentIndex + 1} / ${_images.length}',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        // Primary Badge
                        if (currentImage.isPrimary)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.warning.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: AppTheme.warning,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'صورة رئيسية',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.warning,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Image Details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoItem(
                          icon: Icons.aspect_ratio_rounded,
                          label: 'الأبعاد',
                          value: '${currentImage.width} × ${currentImage.height}',
                        ),
                        _buildInfoItem(
                          icon: Icons.storage_rounded,
                          label: 'الحجم',
                          value: currentImage.sizeInMB + ' MB',
                        ),
                        _buildInfoItem(
                          icon: Icons.image_rounded,
                          label: 'النوع',
                          value: currentImage.mimeType.split('/').last.toUpperCase(),
                        ),
                      ],
                    ),
                    
                    // Alt Text (if available)
                    if (currentImage.alt != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        currentImage.alt!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppTheme.primaryBlue.withOpacity(0.7),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
            fontSize: 10,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildGridSizeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildGridSizeOption(2),
          _buildGridSizeOption(3),
          _buildGridSizeOption(4),
        ],
      ),
    );
  }
  
  Widget _buildGridSizeOption(int columns) {
    final isActive = _gridColumns == columns;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _gridColumns = columns;
        });
      },
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryBlue.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '$columns',
            style: AppTextStyles.caption.copyWith(
              color: isActive ? AppTheme.primaryBlue : AppTheme.textMuted,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: AppTheme.textWhite,
          size: 20,
        ),
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'جاري تحميل الصور...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 80,
            color: AppTheme.error.withOpacity(0.7),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _loadImages,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                'إعادة المحاولة',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.1),
                  AppTheme.primaryPurple.withOpacity(0.05),
                ],
              ),
            ),
            child: Icon(
              Icons.photo_library_outlined,
              size: 60,
              color: AppTheme.primaryBlue.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد صور',
            style: AppTextStyles.heading2.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم يتم إضافة أي صور لهذه الوحدة بعد',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper Methods
  void _openImageViewer(int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _ImageViewerOverlay(
            images: _images,
            initialIndex: index,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }
  
  void _downloadAllImages() {
    // Implement download functionality
    _showSuccessMessage('جاري تحميل الصور...');
  }
  
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// Image Viewer Overlay
class _ImageViewerOverlay extends StatefulWidget {
  final List<UnitImage> images;
  final int initialIndex;
  
  const _ImageViewerOverlay({
    required this.images,
    required this.initialIndex,
  });
  
  @override
  State<_ImageViewerOverlay> createState() => _ImageViewerOverlayState();
}

class _ImageViewerOverlayState extends State<_ImageViewerOverlay> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showControls = true;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Stack(
          children: [
            // Main Gallery
            PhotoViewGallery.builder(
              pageController: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: CachedNetworkImageProvider(
                    widget.images[index].url,
                  ),
                  heroAttributes: PhotoViewHeroAttributes(
                    tag: 'viewer-image-${widget.images[index].id}',
                  ),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 4,
                );
              },
              backgroundDecoration: const BoxDecoration(
                color: Colors.black,
              ),
            ),
            
            // Controls
            if (_showControls) ...[
              // Top Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Close Button
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          
                          // Counter
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_currentIndex + 1} / ${widget.images.length}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          
                          // Download Button
                          GestureDetector(
                            onTap: () {
                              // Implement download
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.download,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Gallery Background Painter
class _GalleryBackgroundPainter extends CustomPainter {
  final double animation;
  
  _GalleryBackgroundPainter({required this.animation});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Draw floating particles
    for (int i = 0; i < 20; i++) {
      final progress = (animation + i * 0.05) % 1.0;
      final y = size.height * progress;
      final x = size.width * 0.5 + 
                 math.sin(progress * math.pi * 2 + i) * size.width * 0.3;
      final opacity = math.sin(progress * math.pi).clamp(0.0, 1.0);
      
      paint.shader = RadialGradient(
        colors: [
          AppTheme.primaryBlue.withOpacity(0.05 * opacity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(x, y),
        radius: 30,
      ));
      
      canvas.drawCircle(Offset(x, y), 30, paint);
    }
    
    // Draw grid lines
    paint.shader = null;
    paint.color = AppTheme.primaryBlue.withOpacity(0.02);
    paint.strokeWidth = 0.5;
    paint.style = PaintingStyle.stroke;
    
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      final offset = math.sin(animation * math.pi * 2) * 5;
      canvas.drawLine(
        Offset(x + offset, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    for (double y = 0; y < size.height; y += spacing) {
      final offset = math.cos(animation * math.pi * 2) * 5;
      canvas.drawLine(
        Offset(0, y + offset),
        Offset(size.width, y),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}