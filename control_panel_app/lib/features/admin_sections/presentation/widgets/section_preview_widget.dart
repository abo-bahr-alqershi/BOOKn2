import 'package:bookn_cp_app/core/enums/section_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../domain/entities/section.dart';
import '../../../../core/enums/section_content_type.dart';
import '../../domain/entities/property_in_section.dart';
import '../../domain/entities/unit_in_section.dart';
import '../../../../core/enums/section_display_style.dart';
import '../../../../core/enums/section_target.dart';
import '../../../../core/widgets/cached_image_widget.dart';

class SectionPreviewWidget extends StatefulWidget {
  final Section section;
  final List<dynamic>? items; // PropertyInSection or UnitInSection
  final bool isExpanded;
  final VoidCallback? onExpand;
  final VoidCallback? onEdit;
  final VoidCallback? onManageItems;

  const SectionPreviewWidget({
    super.key,
    required this.section,
    this.items,
    this.isExpanded = false,
    this.onExpand,
    this.onEdit,
    this.onManageItems,
  });

  @override
  State<SectionPreviewWidget> createState() => _SectionPreviewWidgetState();
}

class _SectionPreviewWidgetState extends State<SectionPreviewWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _rotationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ScrollController _scrollController = ScrollController();
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    if (widget.isExpanded) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(SectionPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rotationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: widget.section.isActive
                  ? AppTheme.primaryBlue.withValues(alpha: 0.2)
                  : AppTheme.shadowDark.withValues(alpha: 0.1),
              blurRadius: _isHovered ? 30 : 20,
              offset: const Offset(0, 10),
              spreadRadius: _isHovered ? 5 : 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.darkCard.withValues(alpha: 0.8),
                    AppTheme.darkCard.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.section.isActive
                      ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                      : AppTheme.darkBorder.withValues(alpha: 0.2),
                  width: widget.section.isActive ? 2 : 1,
                ),
              ),
              child: Stack(
                children: [
                  // Animated background
                  if (widget.section.isActive)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _rotationController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _AnimatedBackgroundPainter(
                              rotation: _rotationController.value,
                              color: AppTheme.primaryBlue,
                            ),
                          );
                        },
                      ),
                    ),
                  // Content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: widget.isExpanded ? null : 200,
                        child: widget.isExpanded
                            ? _buildExpandedContent()
                            : _buildCollapsedContent(),
                      ),
                      if (widget.isExpanded)
                        SizeTransition(
                          sizeFactor: _expandAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: _buildActions(),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Section icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: widget.section.isActive
                      ? AppTheme.primaryGradient
                      : LinearGradient(
                          colors: [
                            AppTheme.textMuted.withValues(alpha: 0.3),
                            AppTheme.textMuted.withValues(alpha: 0.2),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: widget.section.isActive
                          ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                          : Colors.transparent,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _getSectionIcon(),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.section.title ??
                                widget.section.name ??
                                'قسم',
                            style: AppTextStyles.heading2.copyWith(
                              color: AppTheme.textWhite,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.section.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.success.withValues(alpha: 0.9),
                                  AppTheme.success.withValues(alpha: 0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'نشط',
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (widget.section.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.section.subtitle!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Expand button
              IconButton(
                onPressed: widget.onExpand,
                icon: AnimatedRotation(
                  turns: widget.isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    CupertinoIcons.chevron_down_circle_fill,
                    color: AppTheme.primaryBlue,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Info chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                icon: CupertinoIcons.layers_alt,
                label: widget.section.type.value,
                color: AppTheme.primaryBlue,
              ),
              _buildInfoChip(
                icon: CupertinoIcons.square_stack_3d_up,
                label: widget.section.contentType.name,
                color: AppTheme.primaryPurple,
              ),
              _buildInfoChip(
                icon: CupertinoIcons.eye,
                label: widget.section.displayStyle.apiValue,
                color: AppTheme.primaryViolet,
              ),
              _buildInfoChip(
                icon: CupertinoIcons.number,
                label: 'ترتيب: ${widget.section.displayOrder}',
                color: AppTheme.info,
              ),
              _buildInfoChip(
                icon: CupertinoIcons.square_grid_2x2,
                label: '${widget.section.itemsToShow} عنصر',
                color: AppTheme.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: _buildPreviewContent(),
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPreviewContent(),
          const SizedBox(height: 20),
          if (widget.section.description != null) ...[
            Text(
              'الوصف',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.section.description!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 20),
          ],
          _buildDetailsGrid(),
        ],
      ),
    );
  }

  Widget _buildPreviewContent() {
    if (widget.items != null && widget.items!.isNotEmpty) {
      return _buildItemsPreview();
    }

    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkBackground.withValues(alpha: 0.3),
            AppTheme.darkBackground.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.square_stack_3d_down_right,
              color: AppTheme.textMuted.withValues(alpha: 0.5),
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              'معاينة القسم',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getPreviewDescription(),
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsPreview() {
    switch (widget.section.displayStyle) {
      case SectionDisplayStyle.grid:
        return _buildGridPreview();
      case SectionDisplayStyle.list:
        return _buildListPreview();
      case SectionDisplayStyle.carousel:
        return _buildCarouselPreview();
      case SectionDisplayStyle.map:
        return _buildMapPreview();
    }
  }

  Widget _buildGridPreview() {
    final itemsToShow = math.min(widget.items!.length, 4);

    return SizedBox(
      height: 200,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.8,
        ),
        itemCount: itemsToShow,
        itemBuilder: (context, index) {
          return _buildPreviewItem(widget.items![index]);
        },
      ),
    );
  }

  Widget _buildListPreview() {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: math.min(widget.items!.length, 3),
        itemBuilder: (context, index) {
          return Container(
            width: 240,
            margin: const EdgeInsets.only(left: 12),
            child: _buildPreviewItem(widget.items![index]),
          );
        },
      ),
    );
  }

  Widget _buildCarouselPreview() {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.85),
        itemCount: math.min(widget.items!.length, 5),
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildPreviewItem(widget.items![index]),
          );
        },
      ),
    );
  }

  Widget _buildMapPreview() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.info.withValues(alpha: 0.1),
            AppTheme.info.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.info.withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.map_fill,
              color: AppTheme.info,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              'عرض الخريطة',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.info,
              ),
            ),
            Text(
              '${widget.items!.length} موقع',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.info.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewItem(dynamic item) {
    String? imageUrl;
    String title = '';
    String subtitle = '';

    if (item is PropertyInSection) {
      imageUrl = item.mainImageUrl;
      title = item.propertyName;
      subtitle = item.city;
    } else if (item is UnitInSection) {
      imageUrl = item.mainImageUrl;
      title = item.unitName;
      subtitle = item.propertyName;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              CachedImageWidget(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
              )
            else
              Container(
                color: AppTheme.darkCard,
                child: Icon(
                  widget.section.target == SectionTarget.properties
                      ? CupertinoIcons.building_2_fill
                      : CupertinoIcons.house_fill,
                  color: AppTheme.textMuted.withValues(alpha: 0.3),
                  size: 30,
                ),
              ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppTheme.darkBackground.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
            // Text
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 9,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkBackground.withValues(alpha: 0.3),
            AppTheme.darkBackground.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تفاصيل القسم',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildDetailItem('الهدف', widget.section.target.apiValue),
              _buildDetailItem(
                  'عدد الأعمدة', widget.section.columnsCount.toString()),
              if (widget.section.cityName != null)
                _buildDetailItem('المدينة', widget.section.cityName!),
              if (widget.section.minPrice != null)
                _buildDetailItem(
                    'السعر الأدنى', widget.section.minPrice.toString()),
              if (widget.section.maxPrice != null)
                _buildDetailItem(
                    'السعر الأقصى', widget.section.maxPrice.toString()),
              if (widget.section.minRating != null)
                _buildDetailItem(
                    'التقييم الأدنى', widget.section.minRating.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
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

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: CupertinoIcons.pencil_circle_fill,
              label: 'تعديل',
              color: AppTheme.primaryBlue,
              onTap: widget.onEdit,
            ),
          ),
          const SizedBox(width: 12),
          if (widget.section.contentType != SectionContentType.none)
            Expanded(
              child: _buildActionButton(
                icon: CupertinoIcons.square_stack_3d_down_right_fill,
                label: 'إدارة العناصر',
                color: AppTheme.primaryPurple,
                onTap: widget.onManageItems,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSectionIcon() {
    switch (widget.section.type) {
      case SectionTypeEnum.singlePropertyAd:
        return CupertinoIcons.star_fill;
      case SectionTypeEnum.multiPropertyAd:
        return CupertinoIcons.flame_fill;
      case SectionTypeEnum.unitShowcaseAd:
        return CupertinoIcons.sparkles;
      case SectionTypeEnum.singlePropertyOffer:
        return CupertinoIcons.chart_bar_alt_fill;
      case SectionTypeEnum.flashDeals:
        return CupertinoIcons.tag_fill;
      case SectionTypeEnum.cityCardsGrid:
        return CupertinoIcons.location_fill;
      case SectionTypeEnum.premiumCarousel:
        return CupertinoIcons.hand_thumbsup_fill;
      case SectionTypeEnum.verticalPropertyGrid:
        return CupertinoIcons.square_grid_2x2_fill;
      case SectionTypeEnum.horizontalPropertyList:
        return CupertinoIcons.wrench_fill;
      default:
        return CupertinoIcons.square_fill;
    }
  }

  String _getPreviewDescription() {
    return 'سيتم عرض ${widget.section.itemsToShow} ${widget.section.target == SectionTarget.properties ? 'عقار' : 'وحدة'} '
        'بنمط ${widget.section.displayStyle.apiValue} '
        'في ${widget.section.columnsCount} عمود';
  }
}

// Custom painter for animated background
class _AnimatedBackgroundPainter extends CustomPainter {
  final double rotation;
  final Color color;

  _AnimatedBackgroundPainter({
    required this.rotation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.5;

    // Draw rotating gradient circles
    for (int i = 0; i < 3; i++) {
      final angle = rotation * 2 * math.pi + (i * math.pi / 3);
      final offset = Offset(
        center.dx + math.cos(angle) * radius * 0.3,
        center.dy + math.sin(angle) * radius * 0.3,
      );

      paint.shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.05 - (i * 0.015)),
          color.withValues(alpha: 0.02 - (i * 0.005)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: offset,
        radius: radius * (0.4 - i * 0.1),
      ));

      canvas.drawCircle(offset, radius * (0.4 - i * 0.1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
