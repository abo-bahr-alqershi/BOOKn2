// lib/features/profile/presentation/widgets/upload_user_image.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/cached_image_widget.dart';

class UploadUserImage extends StatefulWidget {
  final String? currentImageUrl;
  final Function(String imagePath) onImageSelected;
  final double size;
  final bool enabled;

  const UploadUserImage({
    super.key,
    this.currentImageUrl,
    required this.onImageSelected,
    this.size = 90, // Reduced from 120
    this.enabled = true,
  });

  @override
  State<UploadUserImage> createState() => _UploadUserImageState();
}

class _UploadUserImageState extends State<UploadUserImage> 
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;
  bool _isHovered = false;
  
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _rotateController = AnimationController(
      duration: const Duration(seconds: 10), // Faster rotation
      vsync: this,
    )..repeat();
    
    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotateController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _isHovered = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _isHovered = false) : null,
      onTapCancel: () => setState(() => _isHovered = false),
      onTap: widget.enabled ? _showImageSourceDialog : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating Gradient Border - Premium Minimal Style
          AnimatedBuilder(
            animation: _rotateAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateAnimation.value,
                child: Container(
                  width: widget.size + 6, // Thinner border
                  height: widget.size + 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        AppTheme.primaryBlue.withOpacity(0.6),
                        AppTheme.primaryPurple.withOpacity(0.4),
                        AppTheme.primaryCyan.withOpacity(0.3),
                        AppTheme.primaryViolet.withOpacity(0.4),
                        AppTheme.primaryBlue.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Main Image Container with Pulse
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value * (_isHovered ? 0.97 : 1.0),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.darkCard.withOpacity(0.8),
                    border: Border.all(
                      color: AppTheme.darkBackground,
                      width: 3, // Slightly thinner
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.15),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildUltraMinimalImageContent(),
                        if (_isLoading)
                          _buildLoadingOverlay(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Ultra Minimal Camera Badge
          if (widget.enabled)
            Positioned(
              bottom: 2,
              right: 2,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isHovered ? 32 : 30,
                height: _isHovered ? 32 : 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withOpacity(0.8),
                      AppTheme.primaryPurple.withOpacity(0.6),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.darkBackground,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  _isLoading ? Icons.hourglass_empty : Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUltraMinimalImageContent() {
    if (_selectedImage != null) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
        width: widget.size,
        height: widget.size,
      );
    } else if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty) {
      return CachedImageWidget(
        imageUrl: widget.currentImageUrl!,
        fit: BoxFit.cover,
        width: widget.size,
        height: widget.size,
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkCard.withOpacity(0.3),
              AppTheme.darkCard.withOpacity(0.2),
            ],
          ),
        ),
        child: Icon(
          Icons.person_outline_rounded,
          size: widget.size * 0.4,
          color: AppTheme.textMuted.withOpacity(0.3),
        ),
      );
    }
  }

  Widget _buildLoadingOverlay() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: Container(
        color: AppTheme.darkBackground.withOpacity(0.6),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.primaryBlue.withOpacity(0.8),
              ),
              strokeWidth: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black26,
      builder: (context) => _UltraMinimalImageSourceSheet(
        hasCurrentImage: _selectedImage != null || widget.currentImageUrl != null,
        onCameraPressed: () {
          Navigator.pop(context);
          _pickImage(ImageSource.camera);
        },
        onGalleryPressed: () {
          Navigator.pop(context);
          _pickImage(ImageSource.gallery);
        },
        onRemovePressed: () {
          Navigator.pop(context);
          setState(() {
            _selectedImage = null;
          });
          widget.onImageSelected('');
        },
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      bool hasPermission = await _checkPermission(source);
      if (!hasPermission) {
        _showMinimalPermissionDialog();
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final croppedFile = await _cropImage(pickedFile.path);
        if (croppedFile != null) {
          setState(() {
            _selectedImage = File(croppedFile.path);
          });
          widget.onImageSelected(croppedFile.path);
        }
      }
    } catch (e) {
      _showMinimalErrorSnackBar('فشل في اختيار الصورة');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _checkPermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        final result = await Permission.camera.request();
        return result.isGranted;
      }
      return true;
    } else {
      if (Platform.isIOS) {
        final status = await Permission.photos.status;
        if (status.isGranted || status.isLimited) return true;
        final result = await Permission.photos.request();
        return result.isGranted || result.isLimited;
      }
      return true;
    }
  }

  Future<CroppedFile?> _cropImage(String imagePath) async {
    return await ImageCropper().cropImage(
      sourcePath: imagePath,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'قص الصورة',
          toolbarColor: AppTheme.darkBackground,
          toolbarWidgetColor: AppTheme.textWhite,
          activeControlsWidgetColor: AppTheme.primaryBlue,
          backgroundColor: AppTheme.darkBackground,
          cropFrameColor: AppTheme.primaryBlue.withOpacity(0.5),
          cropGridColor: AppTheme.primaryBlue.withOpacity(0.1),
          lockAspectRatio: true,
          hideBottomControls: false,
          cropFrameStrokeWidth: 1,
          cropGridStrokeWidth: 1,
          cropGridRowCount: 2,
          cropGridColumnCount: 2,
          initAspectRatio: CropAspectRatioPreset.square,
        ),
        IOSUiSettings(
          title: 'قص الصورة',
          minimumAspectRatio: 1.0,
          aspectRatioLockEnabled: true,
          resetButtonHidden: false,
          rotateButtonsHidden: true,
          doneButtonTitle: 'تم',
          cancelButtonTitle: 'إلغاء',
        ),
      ],
    );
  }

  void _showMinimalPermissionDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => _UltraMinimalDialog(
        icon: Icons.camera_alt_outlined,
        iconColor: AppTheme.warning,
        title: 'الصلاحية مطلوبة',
        message: 'نحتاج صلاحية الوصول للكاميرا أو المعرض',
        confirmText: 'الإعدادات',
        onConfirm: () {
          Navigator.pop(context);
          openAppSettings();
        },
      ),
    );
  }

  void _showMinimalErrorSnackBar(String message) {
    HapticFeedback.heavyImpact();
    
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _UltraMinimalSnackBar(
        message: message,
        icon: Icons.error_outline,
        backgroundColor: AppTheme.error,
      ),
    );
    
    overlay.insert(overlayEntry);
    
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }
}

// Ultra Minimal Image Source Sheet
class _UltraMinimalImageSourceSheet extends StatelessWidget {
  final bool hasCurrentImage;
  final VoidCallback onCameraPressed;
  final VoidCallback onGalleryPressed;
  final VoidCallback onRemovePressed;

  const _UltraMinimalImageSourceSheet({
    required this.hasCurrentImage,
    required this.onCameraPressed,
    required this.onGalleryPressed,
    required this.onRemovePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.darkCard.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.darkBorder.withOpacity(0.05),
                width: 0.5,
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 28,
                    height: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBorder.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Title
                  Text(
                    'اختر صورة',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textWhite.withOpacity(0.9),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Camera option
                  _buildMinimalOption(
                    icon: Icons.camera_alt_outlined,
                    title: 'الكاميرا',
                    subtitle: 'التقط صورة جديدة',
                    onTap: onCameraPressed,
                  ),
                  
                  // Gallery option
                  _buildMinimalOption(
                    icon: Icons.photo_library_outlined,
                    title: 'المعرض',
                    subtitle: 'اختر من الصور',
                    onTap: onGalleryPressed,
                  ),
                  
                  // Remove option
                  if (hasCurrentImage)
                    _buildMinimalOption(
                      icon: Icons.delete_outline,
                      title: 'إزالة',
                      subtitle: 'حذف الصورة الحالية',
                      onTap: onRemovePressed,
                      isDestructive: true,
                    ),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: isDestructive
                    ? LinearGradient(
                        colors: [
                          AppTheme.error.withOpacity(0.1),
                          AppTheme.error.withOpacity(0.05),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          AppTheme.primaryBlue.withOpacity(0.08),
                          AppTheme.primaryPurple.withOpacity(0.04),
                        ],
                      ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isDestructive
                    ? AppTheme.error.withOpacity(0.7)
                    : AppTheme.primaryBlue.withOpacity(0.6),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDestructive
                          ? AppTheme.error.withOpacity(0.8)
                          : AppTheme.textWhite.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11,
                      color: AppTheme.textMuted.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textMuted.withOpacity(0.3),
              size: 12,
            ),
          ],
        ),
      ),
    );
  }
}

// Ultra Minimal Dialog
class _UltraMinimalDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String confirmText;
  final VoidCallback onConfirm;

  const _UltraMinimalDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.darkCard.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: iconColor.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor.withOpacity(0.7),
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted.withOpacity(0.6),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppTheme.darkBorder.withOpacity(0.1),
                                width: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'إلغاء',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onConfirm();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  iconColor.withOpacity(0.7),
                                  iconColor.withOpacity(0.5),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              confirmText,
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Ultra Minimal SnackBar
class _UltraMinimalSnackBar extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color backgroundColor;

  const _UltraMinimalSnackBar({
    required this.message,
    required this.icon,
    required this.backgroundColor,
  });

  @override
  State<_UltraMinimalSnackBar> createState() => _UltraMinimalSnackBarState();
}

class _UltraMinimalSnackBarState extends State<_UltraMinimalSnackBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _controller.forward();
    
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      left: 20,
      right: 20,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppTheme.darkCard.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.backgroundColor.withOpacity(0.2),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.backgroundColor.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.backgroundColor.withOpacity(0.2),
                              widget.backgroundColor.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.backgroundColor.withOpacity(0.8),
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.message,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 12,
                          color: AppTheme.textWhite.withOpacity(0.9),
                        ),
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
}