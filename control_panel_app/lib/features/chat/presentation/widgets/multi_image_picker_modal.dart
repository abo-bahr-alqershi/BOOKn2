import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'image_preview_screen.dart';

class MultiImagePickerModal extends StatefulWidget {
  final Function(List<File>) onImagesSelected;
  final int maxImages;

  const MultiImagePickerModal({
    super.key,
    required this.onImagesSelected,
    this.maxImages = 10,
  });

  @override
  State<MultiImagePickerModal> createState() => _MultiImagePickerModalState();
}

class _MultiImagePickerModalState extends State<MultiImagePickerModal>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final List<AssetEntity> _mediaList = [];
  final Map<String, AssetEntity> _selectedAssets = {};
  bool _isLoading = true;
  bool _hasPermission = false;
  int _currentPage = 0;
  bool _hasMore = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAnimations();
    _requestPermission();
    _scrollController.addListener(_onScroll);
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    // Stop change notifications if started
    try {
      PhotoManager.removeChangeCallback(_onPhotoLibraryChanged);
      PhotoManager.stopChangeNotify();
    } catch (_) {}
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recheckPermissionAfterSettings();
    }
  }

  Future<void> _recheckPermissionAfterSettings() async {
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!mounted) return;
      if (permission.isAuth || permission == PermissionState.limited) {
        // If permission newly granted, reload media from scratch
        setState(() {
          _hasPermission = true;
          _isLoading = true;
          _mediaList.clear();
          _selectedAssets.clear();
          _currentPage = 0;
          _hasMore = true;
        });
        await _loadMedia();
      } else {
        setState(() {
          _hasPermission = false;
          _isLoading = false;
        });
      }
    } catch (_) {
      // No-op; keep current UI
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreMedia();
    }
  }

  Future<void> _requestPermission() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (permission.isAuth || permission == PermissionState.limited) {
      // Handle limited library access on iOS
      if (permission == PermissionState.limited) {
        PhotoManager.addChangeCallback(_onPhotoLibraryChanged);
        await PhotoManager.startChangeNotify();
      }
      setState(() => _hasPermission = true);
      await _loadMedia();
    } else {
      // On Android 13+, READ_MEDIA_IMAGES is required; request again gracefully
      // If still denied, keep the no-permission UI
      setState(() {
        _hasPermission = false;
        _isLoading = false;
      });
    }
  }

  void _onPhotoLibraryChanged(MethodCall call) {
    // Reload when user changes selected photos in limited access mode
    _mediaList.clear();
    _currentPage = 0;
    _hasMore = true;
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
    );

    if (albums.isNotEmpty) {
      // Ensure we always use the special 'Recent' (All) album when present
      final AssetPathEntity target = albums.firstWhere(
        (a) => a.isAll,
        orElse: () => albums.first,
      );
      final mediaPage = await target.getAssetListPaged(
        page: _currentPage,
        size: 60,
      );

      setState(() {
        _mediaList.addAll(mediaPage);
        _isLoading = false;
        _hasMore = mediaPage.length == 60;
      });
    }
  }

  Future<void> _loadMoreMedia() async {
    if (!_hasMore || _isLoading) return;

    setState(() => _isLoading = true);
    _currentPage++;
    await _loadMedia();
  }

  void _toggleSelection(AssetEntity asset) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedAssets.containsKey(asset.id)) {
        _selectedAssets.remove(asset.id);
      } else {
        if (_selectedAssets.length < widget.maxImages) {
          _selectedAssets[asset.id] = asset;
        } else {
          _showMaxImagesAlert();
        }
      }
    });
  }

  void _showMaxImagesAlert() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'يمكنك اختيار ${widget.maxImages} صور كحد أقصى',
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor: AppTheme.error.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _proceedWithSelection() async {
    if (_selectedAssets.isEmpty) return;

    HapticFeedback.lightImpact();

    // Convert selected assets to files
    final List<File> files = [];
    for (final asset in _selectedAssets.values) {
      final file = await asset.file;
      if (file != null) {
        files.add(file);
      }
    }

    if (!mounted) return;

    // Navigate to preview screen
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ImagePreviewScreen(
          images: files,
          onSend: (editedImages) {
            Navigator.pop(context); // Close preview
            Navigator.pop(context); // Close picker
            widget.onImagesSelected(editedImages);
          },
        ),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.95,
                end: 1.0,
              ).animate(animation),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _hasPermission ? _buildMediaGrid() : _buildNoPermission(),
          ),
          if (_selectedAssets.isNotEmpty) _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Cancel button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.darkCard.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.close,
                color: AppTheme.textWhite.withValues(alpha: 0.6),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Title
          Text(
            'اختر الصور',
            style: AppTextStyles.heading3.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const Spacer(),

          // Selected count
          if (_selectedAssets.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.8),
                    AppTheme.primaryPurple.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_selectedAssets.length}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaGrid() {
    if (_isLoading && _mediaList.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            AppTheme.primaryBlue.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: _mediaList.length + (_isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _mediaList.length) {
              return Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryBlue.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              );
            }

            final asset = _mediaList[index];
            final isSelected = _selectedAssets.containsKey(asset.id);
            final selectionOrder = isSelected
                ? _selectedAssets.keys.toList().indexOf(asset.id) + 1
                : null;

            return _MediaTile(
              asset: asset,
              isSelected: isSelected,
              selectionOrder: selectionOrder,
              onTap: () => _toggleSelection(asset),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoPermission() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 48,
            color: AppTheme.textMuted.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'السماح بالوصول إلى الصور',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'يرجى السماح بالوصول إلى مكتبة الصور',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textMuted.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<PermissionState>(
            future: PhotoManager.requestPermissionExtend(),
            builder: (context, snapshot) {
              final state = snapshot.data;
              if (state == null) return const SizedBox.shrink();
              final isLimited = state == PermissionState.limited;
              final text = isLimited
                  ? 'تم منح صلاحية محدودة - اختر صورًا مسموحًا بها'
                  : 'الوصول مرفوض - يرجى السماح من الإعدادات';
              return Text(
                text,
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Open settings
              GestureDetector(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  try {
                    await PhotoManager.openSetting();
                  } catch (_) {
                    await openAppSettings();
                  }
                  // Give the system a moment, then re-check
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (!mounted) return;
                  await _recheckPermissionAfterSettings();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryBlue.withValues(alpha: 0.8),
                        AppTheme.primaryPurple.withValues(alpha: 0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'فتح الإعدادات',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Manual retry
              GestureDetector(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await _recheckPermissionAfterSettings();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.darkBorder.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    'تحقق الآن',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textWhite.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // System photo picker fallback (no permission required on Android 13+/iOS)
              GestureDetector(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  try {
                    final picker = ImagePicker();
                    final picks = await picker.pickMultiImage(
                      maxWidth: 1920,
                      maxHeight: 1920,
                      imageQuality: 85,
                    );
                    if (picks.isNotEmpty) {
                      if (!mounted) return;
                      Navigator.pop(context);
                      widget.onImagesSelected(
                        picks.map((x) => File(x.path)).toList(),
                      );
                    }
                  } catch (_) {}
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    'منتقي النظام',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textWhite.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Quick camera button
            GestureDetector(
              onTap: () async {
                HapticFeedback.lightImpact();
                final picker = ImagePicker();
                final photo = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 90,
                );
                if (photo != null) {
                  Navigator.pop(context);
                  widget.onImagesSelected([File(photo.path)]);
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.darkCard.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: AppTheme.primaryBlue.withValues(alpha: 0.7),
                  size: 22,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Continue button
            Expanded(
              child: GestureDetector(
                onTap: _proceedWithSelection,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryBlue.withValues(alpha: 0.8),
                        AppTheme.primaryPurple.withValues(alpha: 0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'متابعة (${_selectedAssets.length})',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaTile extends StatefulWidget {
  final AssetEntity asset;
  final bool isSelected;
  final int? selectionOrder;
  final VoidCallback onTap;

  const _MediaTile({
    required this.asset,
    required this.isSelected,
    this.selectionOrder,
    required this.onTap,
  });

  @override
  State<_MediaTile> createState() => _MediaTileState();
}

class _MediaTileState extends State<_MediaTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image thumbnail (via PhotoManager thumbnail bytes)
                FutureBuilder<Uint8List?>(
                  future: widget.asset
                      .thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(color: AppTheme.darkCard);
                    }
                    final data = snapshot.data;
                    if (data == null || data.isEmpty) {
                      return Container(
                        color: AppTheme.darkCard,
                        child: Icon(
                          Icons.broken_image,
                          color: AppTheme.textMuted.withValues(alpha: 0.3),
                        ),
                      );
                    }
                    return Image.memory(
                      data,
                      fit: BoxFit.cover,
                    );
                  },
                ),

                // Selection overlay
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: widget.isSelected
                        ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppTheme.primaryBlue.withValues(alpha: 0.3),
                              AppTheme.primaryPurple.withValues(alpha: 0.2),
                            ],
                          )
                        : null,
                    border: widget.isSelected
                        ? Border.all(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          )
                        : null,
                  ),
                ),

                // Selection number
                if (widget.isSelected && widget.selectionOrder != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryBlue,
                            AppTheme.primaryPurple,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${widget.selectionOrder}',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Video duration if applicable
                if (widget.asset.type == AssetType.video)
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.videocam,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _formatDuration(widget.asset.duration),
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
