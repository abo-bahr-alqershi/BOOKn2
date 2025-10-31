// lib/features/admin_properties/presentation/widgets/premium_video_player_widget.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';

/// Premium Minimalist Video Player Widget
/// Responsive design for all screens
class VideoPlayerWidget extends StatefulWidget {
  final String videoPath;
  final bool isLocal;
  final VoidCallback? onDelete;
  final double? aspectRatio;
  final bool autoPlay;
  final bool looping;
  final Duration? startAt;
  final String? thumbnailPath;
  final Widget? placeholder;
  final Widget? overlay;
  final bool allowFullScreen;
  final bool allowMuting;
  final bool allowPlaybackSpeedChanging;
  final bool showControls;
  final bool showControlsOnInitialize;
  final List<double>? playbackSpeeds;
  final EdgeInsets? controlsMargin;
  final Color? backgroundColor;

  const VideoPlayerWidget({
    super.key,
    required this.videoPath,
    this.isLocal = false,
    this.onDelete,
    this.aspectRatio,
    this.autoPlay = false,
    this.looping = false,
    this.startAt,
    this.thumbnailPath,
    this.placeholder,
    this.overlay,
    this.allowFullScreen = true,
    this.allowMuting = true,
    this.allowPlaybackSpeedChanging = true,
    this.showControls = true,
    this.showControlsOnInitialize = false,
    this.playbackSpeeds,
    this.controlsMargin,
    this.backgroundColor,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  // Animation controllers
  late AnimationController _fadeInController;
  late AnimationController _scaleController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;

  // State variables
  bool _isInitializing = true;
  bool _hasError = false;
  String? _errorMessage;

  // Responsive breakpoints
  bool get isTablet => MediaQuery.of(context).size.shortestSide >= 600;
  bool get isLandscape =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializePlayer();
  }

  void _setupAnimations() {
    // Fade in animation
    _fadeInController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeInAnimation = CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeOut,
    );

    // Scale animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeOutBack,
      ),
    );
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isInitializing = true;
        _hasError = false;
      });

      // Initialize video controller
      if (widget.isLocal) {
        final file = File(widget.videoPath);
        if (!file.existsSync()) {
          throw Exception('الملف غير موجود');
        }
        _videoController = VideoPlayerController.file(file);
      } else {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoPath),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: true,
            allowBackgroundPlayback: false,
          ),
        );
      }

      // Initialize the controller
      await _videoController!.initialize();

      // Create Chewie controller with premium configuration
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        aspectRatio: widget.aspectRatio ?? _videoController!.value.aspectRatio,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        startAt: widget.startAt,
        allowFullScreen: widget.allowFullScreen,
        allowMuting: widget.allowMuting,
        allowPlaybackSpeedChanging: widget.allowPlaybackSpeedChanging,
        showControls: widget.showControls,
        showControlsOnInitialize: widget.showControlsOnInitialize,
        placeholder: widget.placeholder ?? _buildPlaceholder(),
        overlay: widget.overlay,
        playbackSpeeds:
            widget.playbackSpeeds ?? [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
        errorBuilder: _buildErrorWidget,

        // Premium minimalist controls
        customControls: _buildCustomControls(),

        // Material design options
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.primaryBlue,
          handleColor: AppTheme.primaryBlue,
          backgroundColor: Colors.white.withOpacity(0.1),
          bufferedColor: AppTheme.primaryBlue.withOpacity(0.3),
        ),

        // Auto hide controls
        hideControlsTimer: const Duration(seconds: 3),

        // Fullscreen options
        fullScreenByDefault: false,
        deviceOrientationsAfterFullScreen: [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ],
        deviceOrientationsOnEnterFullScreen: [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],

        // System UI overlays
        systemOverlaysAfterFullScreen: SystemUiOverlay.values,
        systemOverlaysOnEnterFullScreen: [],

        // Additional options
        additionalOptions: (context) {
          return <OptionItem>[
            if (widget.onDelete != null)
              OptionItem(
                onTap: (context) {
                  Navigator.pop(context);
                  widget.onDelete?.call();
                },
                iconData: Icons.delete_outline,
                title: 'حذف الفيديو',
              ),
            OptionItem(
              onTap: (context) => Navigator.pop(context),
              iconData: Icons.high_quality,
              title: 'جودة الفيديو',
            ),
            OptionItem(
              onTap: (context) => Navigator.pop(context),
              iconData: Icons.subtitles_outlined,
              title: 'الترجمة',
            ),
          ];
        },
      );

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });

        // Start animations
        _fadeInController.forward();
        _scaleController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isInitializing = false;
        });
      }
    }
  }

  Widget _buildCustomControls() {
    return _PremiumMinimalistControls(
      backgroundColor: widget.backgroundColor,
      iconColor: Colors.white,
      progressColors: ChewieProgressColors(
        playedColor: AppTheme.primaryBlue,
        handleColor: AppTheme.primaryBlue,
        backgroundColor: Colors.white.withOpacity(0.15),
        bufferedColor: AppTheme.primaryBlue.withOpacity(0.3),
      ),
      onDelete: widget.onDelete,
      isTablet: isTablet,
      isLandscape: isLandscape,
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.6),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white.withOpacity(0.8),
                size: isTablet ? 48 : 36,
              ),
            ),
            if (widget.thumbnailPath != null) ...[
              const SizedBox(height: 16),
              Text(
                'اضغط للتشغيل',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String? errorMessage) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.9),
            AppTheme.error.withOpacity(0.2),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 32 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.white.withOpacity(0.8),
                size: isTablet ? 64 : 48,
              ),
              SizedBox(height: isTablet ? 24 : 16),
              Text(
                'حدث خطأ في تشغيل الفيديو',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isTablet ? 12 : 8),
              Text(
                errorMessage ?? _errorMessage ?? 'تحقق من اتصالك بالإنترنت',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: isTablet ? 14 : 12,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isTablet ? 32 : 24),
              _buildRetryButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRetryButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _retry,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 32 : 24,
            vertical: isTablet ? 14 : 12,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: isTablet ? 20 : 18,
              ),
              SizedBox(width: isTablet ? 12 : 8),
              Text(
                'إعادة المحاولة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 15 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _retry() {
    _disposeControllers();
    _initializePlayer();
  }

  void _disposeControllers() {
    _chewieController?.dispose();
    _videoController?.dispose();
    _chewieController = null;
    _videoController = null;
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    _scaleController.dispose();
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate responsive dimensions
    final videoHeight = isTablet
        ? (isLandscape ? screenHeight * 0.8 : screenHeight * 0.5)
        : (isLandscape ? screenHeight * 0.9 : screenHeight * 0.35);

    final borderRadius = BorderRadius.circular(isTablet ? 24 : 16);
    final padding = EdgeInsets.all(isTablet ? 16 : 8);

    return AnimatedBuilder(
      animation: Listenable.merge([_fadeInAnimation, _scaleAnimation]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeInAnimation,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: videoHeight,
                maxWidth: screenWidth,
              ),
              margin: padding,
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: isTablet ? 30 : 20,
                    offset: Offset(0, isTablet ? 15 : 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: borderRadius,
                child: _buildVideoContent(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoContent() {
    if (_hasError) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: _buildErrorWidget(context, _errorMessage),
      );
    }

    if (_isInitializing) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: _buildLoadingWidget(),
      );
    }

    if (_chewieController == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: _buildLoadingWidget(),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        platform: TargetPlatform.iOS, // For better controls
      ),
      child: Chewie(controller: _chewieController!),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: isTablet ? 60 : 48,
              height: isTablet ? 60 : 48,
              child: CircularProgressIndicator(
                strokeWidth: isTablet ? 3 : 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.8),
                ),
              ),
            ),
            SizedBox(height: isTablet ? 20 : 16),
            Text(
              'جاري التحميل...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: isTablet ? 15 : 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Premium Minimalist Custom Controls
class _PremiumMinimalistControls extends StatefulWidget {
  final Color? backgroundColor;
  final Color iconColor;
  final ChewieProgressColors progressColors;
  final VoidCallback? onDelete;
  final bool isTablet;
  final bool isLandscape;

  const _PremiumMinimalistControls({
    this.backgroundColor,
    required this.iconColor,
    required this.progressColors,
    this.onDelete,
    required this.isTablet,
    required this.isLandscape,
  });

  @override
  State<_PremiumMinimalistControls> createState() =>
      _PremiumMinimalistControlsState();
}

class _PremiumMinimalistControlsState extends State<_PremiumMinimalistControls>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController controller;
  late AnimationController _animationController;
  late Animation<double> _animation;

  bool _hideControls = false;
  bool _displayTapped = false;
  Timer? _hideTimer;

  VideoPlayerValue get videoValue => controller.value;
  bool get isPlaying => videoValue.isPlaying;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final chewieController = ChewieController.of(context);
    controller = chewieController.videoPlayerController;
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();
    setState(() {
      _hideControls = false;
      _displayTapped = true;
    });
    _animationController.forward();
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _hideControls = true;
      });
      _animationController.reverse();
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chewieController = ChewieController.of(context);

    // Responsive sizes
    final iconSize = widget.isTablet ? 32.0 : 24.0;
    final bigIconSize = widget.isTablet ? 56.0 : 42.0;
    final fontSize = widget.isTablet ? 14.0 : 12.0;
    final progressHeight = widget.isTablet ? 4.0 : 3.0;

    return GestureDetector(
      onTap: () {
        if (_hideControls) {
          _cancelAndRestartTimer();
        } else {
          setState(() {
            _hideControls = true;
          });
          _animationController.reverse();
        }
      },
      child: AnimatedOpacity(
        opacity: _hideControls ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Stack(
          children: [
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                ),
              ),
            ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isTablet ? 20 : 16,
                  vertical: widget.isTablet ? 16 : 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button (in fullscreen)
                    if (chewieController.isFullScreen)
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: widget.iconColor,
                          size: iconSize,
                        ),
                        onPressed: () {
                          chewieController.exitFullScreen();
                        },
                      )
                    else
                      const SizedBox(width: 48),

                    // Options
                    Row(
                      children: [
                        if (widget.onDelete != null &&
                            !chewieController.isFullScreen)
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: widget.iconColor,
                              size: iconSize,
                            ),
                            onPressed: widget.onDelete,
                          ),
                        IconButton(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: widget.iconColor,
                            size: iconSize,
                          ),
                          onPressed: () {
                            chewieController.showOptions;
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Center play/pause
            Center(
              child: FadeTransition(
                opacity: _animation,
                child: IconButton(
                  iconSize: bigIconSize,
                  icon: Container(
                    width: bigIconSize + 20,
                    height: bigIconSize + 20,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: widget.iconColor,
                      size: bigIconSize,
                    ),
                  ),
                  onPressed: () {
                    if (isPlaying) {
                      controller.pause();
                    } else {
                      controller.play();
                    }
                    _cancelAndRestartTimer();
                  },
                ),
              ),
            ),

            // Bottom bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  left: widget.isTablet ? 20 : 16,
                  right: widget.isTablet ? 20 : 16,
                  bottom: widget.isTablet ? 20 : 16,
                ),
                child: Column(
                  children: [
                    // Progress bar
                    SizedBox(
                      height: progressHeight,
                      child: VideoProgressIndicator(
                        controller,
                        allowScrubbing: true,
                        padding: EdgeInsets.zero,
                        colors: VideoProgressColors(
                          playedColor: AppTheme.primaryBlue,
                          bufferedColor: AppTheme.primaryBlue.withOpacity(0.3),
                          backgroundColor: Colors.white.withOpacity(0.15),
                        ),
                      ),
                    ),

                    SizedBox(height: widget.isTablet ? 12 : 8),

                    // Controls row
                    Row(
                      children: [
                        // Play/pause
                        IconButton(
                          icon: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: widget.iconColor,
                            size: iconSize,
                          ),
                          onPressed: () {
                            if (isPlaying) {
                              controller.pause();
                            } else {
                              controller.play();
                            }
                            _cancelAndRestartTimer();
                          },
                        ),

                        // Time
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '${_formatDuration(videoValue.position)} / ${_formatDuration(videoValue.duration)}',
                            style: TextStyle(
                              color: widget.iconColor,
                              fontSize: fontSize,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Speed
                        if (chewieController.allowPlaybackSpeedChanging)
                          PopupMenuButton<double>(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Text(
                                '${controller.value.playbackSpeed}x',
                                style: TextStyle(
                                  color: widget.iconColor,
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            onSelected: (speed) {
                              controller.setPlaybackSpeed(speed);
                            },
                            itemBuilder: (context) {
                              return chewieController.playbackSpeeds
                                  .map((speed) {
                                return PopupMenuItem(
                                  value: speed,
                                  child: Text('${speed}x'),
                                );
                              }).toList();
                            },
                          ),

                        // Mute
                        if (chewieController.allowMuting)
                          IconButton(
                            icon: Icon(
                              controller.value.volume == 0
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              color: widget.iconColor,
                              size: iconSize,
                            ),
                            onPressed: () {
                              if (controller.value.volume == 0) {
                                controller.setVolume(1);
                              } else {
                                controller.setVolume(0);
                              }
                            },
                          ),

                        // Fullscreen
                        if (chewieController.allowFullScreen)
                          IconButton(
                            icon: Icon(
                              chewieController.isFullScreen
                                  ? Icons.fullscreen_exit_rounded
                                  : Icons.fullscreen_rounded,
                              color: widget.iconColor,
                              size: iconSize,
                            ),
                            onPressed: () {
                              if (chewieController.isFullScreen) {
                                chewieController.exitFullScreen();
                              } else {
                                chewieController.enterFullScreen();
                              }
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
