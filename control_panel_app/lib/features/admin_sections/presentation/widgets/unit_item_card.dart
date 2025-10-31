import 'package:bookn_cp_app/features/admin_sections/domain/entities/section_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../domain/entities/unit_in_section.dart';
import '../bloc/unit_in_section_images/unit_in_section_images_bloc.dart';
import '../bloc/unit_in_section_images/unit_in_section_images_event.dart';
import 'unit_in_section_image_gallery.dart';
import 'package:bookn_cp_app/injection_container.dart' as di;

class UnitItemCard extends StatefulWidget {
  final UnitInSection unit;
  final VoidCallback? onRemove;
  final bool isReordering;

  const UnitItemCard({
    super.key,
    required this.unit,
    this.onRemove,
    this.isReordering = false,
  });

  @override
  State<UnitItemCard> createState() => _UnitItemCardState();
}

class _UnitItemCardState extends State<UnitItemCard>
    with SingleTickerProviderStateMixin {
  // Animation controller for media panel
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _rotateAnimation;

  // Media management
  bool _showMediaPanel = false;
  String? _tempKey;
  List<SectionImage> _selectedImages = [];
  List<String> _selectedLocalImages = [];
  final GlobalKey<UnitInSectionGalleryState> _galleryKey = GlobalKey();

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
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Initialize images from unit
    _selectedImages = widget.unit.additionalImages ?? [];
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
        _tempKey = '${widget.unit.id}_${DateTime.now().millisecondsSinceEpoch}';
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
                      ? AppTheme.primaryPurple.withValues(alpha: 0.3)
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

                  // Media Panel with animation
                  if (_showMediaPanel)
                    Expanded(
                      child: FadeTransition(
                        opacity: _slideAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, -0.1),
                            end: Offset.zero,
                          ).animate(_slideAnimation),
                          child: _buildMediaPanel(),
                        ),
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
          child: widget.unit.mainImageUrl != null
              ? CachedImageWidget(
                  imageUrl: widget.unit.mainImageUrl!,
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
                    CupertinoIcons.house_fill,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.unit.unitName,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppTheme.textWhite,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.unit.propertyName,
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (widget.unit.isAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.success.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          'متاح',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.success,
                            fontSize: 9,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Capacity
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.info.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.person_2_fill,
                            size: 10,
                            color: AppTheme.info,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${widget.unit.maxCapacity}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.info,
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
                      '${widget.unit.basePrice.toStringAsFixed(0)} ${widget.unit.currency}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Media button with animation
                    if (!widget.isReordering)
                      GestureDetector(
                        onTap: _toggleMediaPanel,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            gradient: _showMediaPanel
                                ? LinearGradient(
                                    colors: [
                                      AppTheme.primaryPurple
                                          .withValues(alpha: 0.2),
                                      AppTheme.primaryViolet
                                          .withValues(alpha: 0.2),
                                    ],
                                  )
                                : null,
                            color: !_showMediaPanel
                                ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                                : null,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _showMediaPanel
                                  ? AppTheme.primaryPurple
                                      .withValues(alpha: 0.5)
                                  : AppTheme.primaryBlue.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RotationTransition(
                                turns: _rotateAnimation,
                                child: Icon(
                                  _showMediaPanel
                                      ? CupertinoIcons.chevron_up
                                      : CupertinoIcons.photo_on_rectangle,
                                  size: 14,
                                  color: _showMediaPanel
                                      ? AppTheme.primaryPurple
                                      : AppTheme.primaryBlue,
                                ),
                              ),
                              if (_selectedImages.isNotEmpty ||
                                  _selectedLocalImages.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
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
      create: (_) => di.sl<UnitInSectionImagesBloc>()
        ..add(LoadUnitInSectionImagesEvent(
          unitInSectionId: widget.unit.id,
        )),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.darkBackground.withValues(alpha: 0.3),
              AppTheme.darkBackground.withValues(alpha: 0.5),
            ],
          ),
          border: Border(
            top: BorderSide(
              color: AppTheme.primaryPurple.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Column(
          children: [
            // Animated Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppTheme.primaryPurple.withValues(alpha: 0.05),
                    AppTheme.primaryViolet.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      CupertinoIcons.photo_fill_on_rectangle_fill,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'معرض وسائط الوحدة',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.photo,
                          size: 12,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_selectedImages.length}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_selectedLocalImages.isNotEmpty) ...[
                          Text(
                            ' + ',
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          ),
                          Text(
                            '${_selectedLocalImages.length}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Gallery
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: UnitInSectionGallery(
                  key: _galleryKey,
                  unitInSectionId: widget.unit.id,
                  tempKey: _tempKey,
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
            ),
            // Status Bar
            if (_selectedLocalImages.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.warning.withValues(alpha: 0.1),
                      AppTheme.warning.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.cloud_upload,
                      size: 14,
                      color: AppTheme.warning,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'يوجد ${_selectedLocalImages.length} ملف جديد في انتظار الرفع',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.warning,
                          fontSize: 11,
                        ),
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
