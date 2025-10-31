import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../domain/entities/message.dart';
import 'reaction_picker_widget.dart';

class ImageGalleryScreen extends StatefulWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(String)? onReaction;
  final int initialIndex;

  const ImageGalleryScreen({
    super.key,
    required this.message,
    required this.isMe,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onReaction,
    this.initialIndex = 0,
  });

  @override
  State<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _controlsAnimationController;
  late Animation<double> _controlsAnimation;

  int _currentIndex = 0;
  bool _showControls = true;
  bool _showReactions = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _controlsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controlsAnimationController,
      curve: Curves.easeInOut,
    ));

    _controlsAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controlsAnimationController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _controlsAnimationController.forward();
      } else {
        _controlsAnimationController.reverse();
      }
    });
  }

  void _showOptions() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ImageOptionsSheet(
        message: widget.message,
        isMe: widget.isMe,
        currentIndex: _currentIndex,
        onReply: () {
          Navigator.pop(context);
          Navigator.pop(context);
          widget.onReply?.call();
        },
        onEdit: widget.onEdit != null
            ? () {
                Navigator.pop(context);
                Navigator.pop(context);
                widget.onEdit!();
              }
            : null,
        onDelete: widget.onDelete != null
            ? () {
                Navigator.pop(context);
                Navigator.pop(context);
                widget.onDelete!();
              }
            : null,
        onSaveImage: () {
          Navigator.pop(context);
          _saveCurrentImage();
        },
        onShareImage: () {
          Navigator.pop(context);
          _shareCurrentImage();
        },
      ),
    );
  }

  void _saveCurrentImage() {
    // TODO: Implement save to gallery
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم حفظ الصورة'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.success.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _shareCurrentImage() {
    // TODO: Implement share image
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.message.attachments.where((a) => a.isImage).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Image Gallery
            PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (BuildContext context, int index) {
                return PhotoViewGalleryPageOptions.customChild(
                  child: CachedImageWidget(
                    imageUrl: images[index].fileUrl,
                    fit: BoxFit.contain,
                  ),
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3,
                  heroAttributes: PhotoViewHeroAttributes(
                    tag: 'image_${widget.message.id}_$index',
                  ),
                );
              },
              itemCount: images.length,
              loadingBuilder: (context, event) => Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    value: event == null
                        ? 0
                        : event.cumulativeBytesLoaded /
                            event.expectedTotalBytes!,
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ),
              backgroundDecoration: const BoxDecoration(
                color: Colors.black,
              ),
              pageController: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),

            // Top Bar
            FadeTransition(
              opacity: _controlsAnimation,
              child: _buildTopBar(images.length),
            ),

            // Bottom Bar
            FadeTransition(
              opacity: _controlsAnimation,
              child: _buildBottomBar(),
            ),

            // Reaction Picker
            if (_showReactions)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: ReactionPickerWidget(
                    onReaction: (reaction) {
                      widget.onReaction?.call(reaction);
                      setState(() {
                        _showReactions = false;
                      });
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(int imageCount) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 12,
              left: 8,
              right: 8,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.black.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: Row(
              children: [
                // Back Button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Image Counter
                if (imageCount > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / $imageCount',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                const Spacer(),

                // More Options
                IconButton(
                  onPressed: _showOptions,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 12,
              top: 12,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.black.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Reply
                _buildActionButton(
                  icon: Icons.reply_rounded,
                  label: 'رد',
                  onTap: () {
                    Navigator.pop(context);
                    widget.onReply?.call();
                  },
                ),

                // React
                if (widget.onReaction != null)
                  _buildActionButton(
                    icon: Icons.favorite_rounded,
                    label: 'تفاعل',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _showReactions = !_showReactions;
                      });
                    },
                  ),

                // Edit (only for own messages)
                if (widget.isMe && widget.onEdit != null)
                  _buildActionButton(
                    icon: Icons.edit_rounded,
                    label: 'تعديل',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onEdit!();
                    },
                  ),

                // Delete (only for own messages)
                if (widget.isMe && widget.onDelete != null)
                  _buildActionButton(
                    icon: Icons.delete_rounded,
                    label: 'حذف',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onDelete!();
                    },
                    color: AppTheme.error,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final buttonColor = color ?? Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: buttonColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: buttonColor,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: buttonColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageOptionsSheet extends StatelessWidget {
  final Message message;
  final bool isMe;
  final int currentIndex;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSaveImage;
  final VoidCallback? onShareImage;

  const _ImageOptionsSheet({
    required this.message,
    required this.isMe,
    required this.currentIndex,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onSaveImage,
    this.onShareImage,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(20),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.darkCard.withValues(alpha: 0.95),
                AppTheme.darkCard.withValues(alpha: 0.98),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            border: Border.all(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 8),

              // Save Image
              _buildOption(
                icon: Icons.download_rounded,
                title: 'حفظ الصورة',
                onTap: onSaveImage,
                color: AppTheme.success,
              ),

              // Share Image
              _buildOption(
                icon: Icons.share_rounded,
                title: 'مشاركة الصورة',
                onTap: onShareImage,
                color: AppTheme.primaryBlue,
              ),

              // Reply
              _buildOption(
                icon: Icons.reply_rounded,
                title: 'رد على الرسالة',
                onTap: onReply,
                color: AppTheme.primaryBlue,
              ),

              // Edit (only for own messages)
              if (isMe && onEdit != null)
                _buildOption(
                  icon: Icons.edit_rounded,
                  title: 'تعديل الرسالة',
                  onTap: onEdit,
                  color: AppTheme.warning,
                ),

              // Delete (only for own messages)
              if (isMe && onDelete != null)
                _buildOption(
                  icon: Icons.delete_rounded,
                  title: 'حذف الرسالة',
                  onTap: onDelete,
                  color: AppTheme.error,
                ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppTheme.textMuted.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
