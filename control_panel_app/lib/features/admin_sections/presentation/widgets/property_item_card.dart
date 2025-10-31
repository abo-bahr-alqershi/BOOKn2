import 'package:bookn_cp_app/features/admin_sections/domain/entities/section_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../domain/entities/property_in_section.dart';
import '../bloc/property_in_section_images/property_in_section_images_bloc.dart';
import '../bloc/property_in_section_images/property_in_section_images_event.dart';
import 'property_in_section_image_gallery.dart';
import 'package:bookn_cp_app/injection_container.dart' as di;

class PropertyItemCard extends StatefulWidget {
  final PropertyInSection property;
  final VoidCallback? onRemove;
  final bool isReordering;

  const PropertyItemCard({
    super.key,
    required this.property,
    this.onRemove,
    this.isReordering = false,
  });

  @override
  State<PropertyItemCard> createState() => _PropertyItemCardState();
}

class _PropertyItemCardState extends State<PropertyItemCard>
    with SingleTickerProviderStateMixin {
  // Animation controller for media panel
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  // Media management
  bool _showMediaPanel = false;
  String? _tempKey;
  List<SectionImage> _selectedImages = [];
  List<String> _selectedLocalImages = [];
  final GlobalKey<PropertyInSectionGalleryState> _galleryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Initialize images from property
    _selectedImages = widget.property.additionalImages ?? [];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMediaPanel() {
    setState(() {
      _showMediaPanel = !_showMediaPanel;
      if (_showMediaPanel) {
        // Generate temp key for this session
        _tempKey =
            '${widget.property.id}_${DateTime.now().millisecondsSinceEpoch}';
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _showMediaPanel ? 420 : 110,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowDark.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.darkCard.withValues(alpha: 0.8),
                    AppTheme.darkCard.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _showMediaPanel
                      ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                      : AppTheme.darkBorder.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Main Card Content
                  SizedBox(
                    height: 108,
                    child: _buildMainContent(),
                  ),

                  // Media Panel
                  if (_showMediaPanel)
                    Expanded(
                      child: FadeTransition(
                        opacity: _slideAnimation,
                        child: _buildMediaPanel(),
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

  Widget _buildMainContent() {
    return Row(
      children: [
        // Image
        Container(
          width: 108,
          height: 108,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(15),
              bottomRight: Radius.circular(15),
            ),
          ),
          child: widget.property.mainImageUrl != null
              ? CachedImageWidget(
                  imageUrl: widget.property.mainImageUrl!,
                  fit: BoxFit.cover,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                  ),
                  child: Icon(
                    CupertinoIcons.building_2_fill,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 40,
                  ),
                ),
        ),
        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.property.propertyName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.property.isFeatured)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'مميز',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.location,
                      size: 12,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.property.city,
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Rating
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.warning.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.star_fill,
                            size: 10,
                            color: AppTheme.warning,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            widget.property.averageRating.toStringAsFixed(1),
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.warning,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Price
                    Text(
                      '${widget.property.basePrice.toStringAsFixed(0)} ${widget.property.currency}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Media button with indicator
                    if (!widget.isReordering)
                      GestureDetector(
                        onTap: _toggleMediaPanel,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _showMediaPanel
                                ? AppTheme.primaryBlue.withValues(alpha: 0.2)
                                : AppTheme.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _showMediaPanel
                                  ? AppTheme.primaryBlue.withValues(alpha: 0.5)
                                  : AppTheme.primaryBlue.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.photo_on_rectangle,
                                size: 14,
                                color: AppTheme.primaryBlue,
                              ),
                              if (_selectedImages.isNotEmpty ||
                                  _selectedLocalImages.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_selectedImages.length + _selectedLocalImages.length}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    // Remove button
                    if (widget.onRemove != null && !widget.isReordering)
                      GestureDetector(
                        onTap: widget.onRemove,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppTheme.error.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Icon(
                            CupertinoIcons.trash,
                            size: 14,
                            color: AppTheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaPanel() {
    return BlocProvider(
      create: (_) => di.sl<PropertyInSectionImagesBloc>()
        ..add(LoadPropertyInSectionImagesEvent(
          propertyInSectionId: widget.property.id,
        )),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.darkBackground.withValues(alpha: 0.3),
          border: Border(
            top: BorderSide(
              color: AppTheme.darkBorder.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(
                  CupertinoIcons.photo_fill_on_rectangle_fill,
                  size: 16,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  'وسائط العقار',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_selectedImages.length + _selectedLocalImages.length} صورة/فيديو',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Gallery
            Expanded(
              child: PropertyInSectionGallery(
                key: _galleryKey,
                propertyInSectionId: widget.property.id,
                // tempKey: _tempKey,
                isReadOnly: false,
                maxImages: 20,
                maxVideos: 5,
                initialImages: _selectedImages,
                onImagesChanged: (images) {
                  setState(() {
                    _selectedImages = images;
                  });
                },
                onLocalImagesChanged: (paths) {
                  setState(() {
                    _selectedLocalImages = paths;
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            // Save indicator
            if (_selectedLocalImages.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.info_circle_fill,
                      size: 12,
                      color: AppTheme.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'سيتم حفظ ${_selectedLocalImages.length} صورة جديدة عند حفظ التغييرات',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.warning,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
