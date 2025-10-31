import 'package:bookn_cp_app/core/enums/section_content_type.dart';
import 'package:bookn_cp_app/core/enums/section_display_style.dart';
import 'package:bookn_cp_app/core/enums/section_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/section.dart';
import 'section_status_badge.dart';

enum CardDisplayMode {
  compact, // عرض مضغوط (سطر واحد مع الأزرار الأساسية)
  expanded, // عرض موسع (معلومات كاملة مع كل الأزرار)
  grid, // عرض شبكي (محتوى عمودي محسن للشبكة)
  fullClassic, // التصميم الكلاسيكي الكامل من الإصدار القديم
}

class FuturisticSectionCard extends StatefulWidget {
  final Section section;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStatus;
  final VoidCallback? onManageItems;
  final CardDisplayMode cardMode;

  const FuturisticSectionCard({
    super.key,
    required this.section,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleStatus,
    this.onManageItems,
    this.cardMode = CardDisplayMode.expanded,
  });

  @override
  State<FuturisticSectionCard> createState() => _FuturisticSectionCardState();
}

class _FuturisticSectionCardState extends State<FuturisticSectionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isHovered = false;
  bool _showActions = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // استخدام التصميم الكلاسيكي الجميل للأوضاع الكاملة
    if (widget.cardMode == CardDisplayMode.fullClassic ||
        widget.cardMode == CardDisplayMode.expanded) {
      return _buildClassicDesign();
    }

    // استخدام التصميم البسيط للأوضاع الأخرى
    return _buildSimpleDesign();
  }

  // التصميم الكلاسيكي الجميل من الإصدار القديم
  Widget _buildClassicDesign() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.identity()
        ..scale(_isHovered ? 0.98 : 1.0)
        ..rotateZ(_isHovered ? 0.002 : 0),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: () {
          HapticFeedback.mediumImpact();
          setState(() => _showActions = !_showActions);
        },
        onTapDown: (_) => _setHovered(true),
        onTapUp: (_) => _setHovered(false),
        onTapCancel: () => _setHovered(false),
        child: Container(
          margin: EdgeInsets.only(
            bottom: widget.cardMode == CardDisplayMode.compact ? 8 : 16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.section.isActive
                    ? AppTheme.primaryBlue.withValues(alpha: 0.2)
                    : AppTheme.shadowDark.withValues(alpha: 0.1),
                blurRadius: widget.section.isActive ? 20 : 15,
                offset: const Offset(0, 8),
                spreadRadius: widget.section.isActive ? 2 : 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.section.isActive
                        ? [
                            AppTheme.primaryBlue.withValues(alpha: 0.15),
                            AppTheme.primaryPurple.withValues(alpha: 0.1),
                          ]
                        : [
                            AppTheme.darkCard.withValues(alpha: 0.8),
                            AppTheme.darkCard.withValues(alpha: 0.6),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.section.isActive
                        ? AppTheme.primaryBlue.withValues(alpha: 0.5)
                        : AppTheme.darkBorder.withValues(alpha: 0.2),
                    width: widget.section.isActive ? 2 : 1,
                  ),
                ),
                child: _buildContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // التصميم البسيط للأوضاع المضغوطة والشبكية
  Widget _buildSimpleDesign() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.identity()..scale(_isHovered ? 0.98 : 1.0),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) => setState(() => _isHovered = false),
        onTapCancel: () => setState(() => _isHovered = false),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.section.isActive
                    ? AppTheme.primaryBlue.withOpacity(0.15)
                    : AppTheme.shadowDark.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: widget.section.isActive ? 1 : 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.section.isActive
                      ? [
                          AppTheme.primaryBlue.withOpacity(0.1),
                          AppTheme.primaryPurple.withOpacity(0.05),
                        ]
                      : [
                          AppTheme.darkCard.withOpacity(0.9),
                          AppTheme.darkCard.withOpacity(0.7),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.section.isActive
                      ? AppTheme.primaryBlue.withOpacity(0.3)
                      : AppTheme.darkBorder.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (widget.cardMode) {
      case CardDisplayMode.compact:
        return _buildCompactContent();
      case CardDisplayMode.expanded:
        return _buildExpandedClassicContent();
      case CardDisplayMode.grid:
        return _buildGridContent();
      case CardDisplayMode.fullClassic:
        return _buildFullClassicContent();
    }
  }

  // التصميم الكلاسيكي الكامل من الإصدار القديم
  Widget _buildFullClassicContent() {
    return IntrinsicHeight(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildClassicHeader(),
          Flexible(
            child: _buildClassicBody(),
          ),
          _buildClassicFooter(),
        ],
      ),
    );
  }

  Widget _buildClassicHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withValues(alpha: 0.3),
            AppTheme.darkCard.withValues(alpha: 0.1),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          _buildClassicTypeIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.section.title ?? widget.section.name ?? 'قسم',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.section.subtitle != null)
                  Text(
                    widget.section.subtitle!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SectionStatusBadge(
                  isActive: widget.section.isActive,
                  size: BadgeSize.medium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassicBody() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildClassicInfoRow(
            icon: CupertinoIcons.layers_alt_fill,
            label: 'النوع',
            value: widget.section.type.value ==
                    SectionTypeEnum.singlePropertyAd.value
                ? 'مميز'
                : widget.section.type.value ==
                        SectionTypeEnum.multiPropertyAd.value
                    ? 'شائع'
                    : widget.section.type.value ==
                            SectionTypeEnum.unitShowcaseAd.value
                        ? 'وارد حديثاً'
                        : widget.section.type.value ==
                                SectionTypeEnum.singlePropertyOffer.value
                            ? 'الأعلى تقييماً'
                            : widget.section.type.value ==
                                    SectionTypeEnum.flashDeals.value
                                ? 'مخفض'
                                : widget.section.type.value ==
                                        SectionTypeEnum.cityCardsGrid.value
                                    ? 'بالقرب مني'
                                    : widget.section.type.value ==
                                            SectionTypeEnum.premiumCarousel.value
                                        ? 'موصى به'
                                        : widget.section.type.value ==
                                                SectionTypeEnum
                                                    .verticalPropertyGrid.value
                                            ? 'فئة'
                                            : widget.section.type.value ==
                                                    SectionTypeEnum
                                                        .horizontalPropertyList.value
                                                ? 'مخصص'
                                                : 'غير معروف',
          ),
          const SizedBox(height: 8),
          _buildClassicInfoRow(
            icon: CupertinoIcons.square_stack_3d_up_fill,
            label: 'المحتوى',
            value: widget.section.contentType.name ==
                    SectionContentType.properties.name
                ? 'عقارات'
                : widget.section.contentType.name ==
                        SectionContentType.units.name
                    ? 'وحدات'
                    : widget.section.contentType.name ==
                            SectionContentType.mixed.name
                        ? 'مختلط'
                        : 'غير معروف',
          ),
          const SizedBox(height: 8),
          _buildClassicInfoRow(
            icon: CupertinoIcons.eye_fill,
            label: 'العرض',
            value: widget.section.displayStyle.name ==
                    SectionDisplayStyle.grid.name
                ? 'شبكة'
                : widget.section.displayStyle.name ==
                        SectionDisplayStyle.list.name
                    ? 'قائمة'
                    : widget.section.displayStyle.name ==
                            SectionDisplayStyle.carousel.name
                        ? 'دائري'
                        : widget.section.displayStyle.name ==
                                SectionDisplayStyle.map.name
                            ? 'خريطة'
                            : 'غير معروف',
          ),
          const SizedBox(height: 8),
          _buildClassicInfoRow(
            icon: CupertinoIcons.number,
            label: 'ترتيب العرض',
            value: widget.section.displayOrder.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildClassicFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildClassicActionButton(
                icon: CupertinoIcons.eye,
                label: 'عرض',
                onTap: widget.onTap,
              ),
              const SizedBox(width: 8),
              _buildClassicActionButton(
                icon: CupertinoIcons.pencil,
                label: 'تعديل',
                onTap: widget.onEdit,
                isPrimary: true,
              ),
              const SizedBox(width: 8),
              _buildClassicActionButton(
                icon: widget.section.isActive
                    ? CupertinoIcons.pause_circle
                    : CupertinoIcons.play_circle,
                label: widget.section.isActive ? 'إيقاف' : 'تفعيل',
                onTap: widget.onToggleStatus,
              ),
            ],
          ),
          if (widget.onManageItems != null && widget.section.contentType != SectionContentType.none) ...[
            const SizedBox(height: 8),
            _buildFullWidthActionButton(
              icon: CupertinoIcons.square_stack_3d_down_right,
              label: 'إدارة العناصر',
              onTap: widget.onManageItems,
              color: AppTheme.primaryPurple,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClassicTypeIcon() {
    IconData iconData;
    Color iconColor;

    switch (widget.section.type) {
      case SectionTypeEnum.singlePropertyAd:
        iconData = CupertinoIcons.star_fill;
        iconColor = AppTheme.warning;
        break;
      case SectionTypeEnum.multiPropertyAd:
        iconData = CupertinoIcons.flame_fill;
        iconColor = AppTheme.error;
        break;
      case SectionTypeEnum.unitShowcaseAd:
        iconData = CupertinoIcons.sparkles;
        iconColor = AppTheme.success;
        break;
      case SectionTypeEnum.singlePropertyOffer:
        iconData = CupertinoIcons.chart_bar_alt_fill;
        iconColor = AppTheme.primaryPurple;
        break;
      case SectionTypeEnum.flashDeals:
        iconData = CupertinoIcons.tag_fill;
        iconColor = AppTheme.warning;
        break;
      case SectionTypeEnum.cityCardsGrid:
        iconData = CupertinoIcons.location_fill;
        iconColor = AppTheme.info;
        break;
      case SectionTypeEnum.premiumCarousel:
        iconData = CupertinoIcons.hand_thumbsup_fill;
        iconColor = AppTheme.primaryBlue;
        break;
      case SectionTypeEnum.verticalPropertyGrid:
        iconData = CupertinoIcons.square_grid_2x2_fill;
        iconColor = AppTheme.primaryViolet;
        break;
      case SectionTypeEnum.horizontalPropertyList:
        iconData = CupertinoIcons.wrench_fill;
        iconColor = AppTheme.textMuted;
        break;
      default:
        iconData = CupertinoIcons.square_fill;
        iconColor = AppTheme.textMuted;
        break;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            iconColor.withValues(alpha: 0.2),
            iconColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  Widget _buildClassicInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.textMuted,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildClassicActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool isPrimary = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            gradient: isPrimary ? AppTheme.primaryGradient : null,
            color: isPrimary
                ? null
                : AppTheme.darkBackground.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: isPrimary
                ? null
                : Border.all(
                    color: AppTheme.darkBorder.withValues(alpha: 0.3),
                  ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isPrimary ? Colors.white : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: isPrimary ? Colors.white : AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // التصميم الموسع مع BackdropFilter
  Widget _buildExpandedClassicContent() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // الرأس
          Row(
            children: [
              _buildSmallTypeIcon(size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.section.title ?? widget.section.name ?? 'قسم',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.section.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.section.subtitle!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              _buildMiniStatusBadge(),
            ],
          ),

          const SizedBox(height: 12),

          // المعلومات
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.darkBackground.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: CupertinoIcons.layers,
                  label: 'النوع',
                  value: widget.section.type.value ==
                          SectionTypeEnum.singlePropertyAd.value
                      ? 'مميز'
                      : widget.section.type.value ==
                              SectionTypeEnum.multiPropertyAd.value
                          ? 'شائع'
                          : widget.section.type.value ==
                                  SectionTypeEnum.unitShowcaseAd.value
                              ? 'وارد حديثاً'
                              : widget.section.type.value ==
                                      SectionTypeEnum.singlePropertyOffer.value
                                  ? 'الأعلى تقييماً'
                                  : widget.section.type.value ==
                                          SectionTypeEnum.flashDeals.value
                                      ? 'مخفض'
                                      : widget.section.type.value ==
                                              SectionTypeEnum.cityCardsGrid.value
                                          ? 'بالقرب مني'
                                          : widget.section.type.value ==
                                                  SectionTypeEnum
                                                      .premiumCarousel.value
                                              ? 'موصى به'
                                              : widget.section.type.value ==
                                                      SectionTypeEnum
                                                          .verticalPropertyGrid.value
                                                  ? 'فئة'
                                                  : widget.section.type
                                                              .value ==
                                                          SectionTypeEnum
                                                              .horizontalPropertyList.value
                                                      ? 'مخصص'
                                                      : 'غير معروف',
                ),
                const SizedBox(height: 6),
                _buildInfoRow(
                  icon: CupertinoIcons.square_stack,
                  label: 'المحتوى',
                  value: widget.section.contentType.name ==
                          SectionContentType.properties.name
                      ? 'عقارات'
                      : widget.section.contentType.name ==
                              SectionContentType.units.name
                          ? 'وحدات'
                          : widget.section.contentType.name ==
                                  SectionContentType.mixed.name
                              ? 'مختلط'
                              : 'غير معروف',
                ),
                const SizedBox(height: 6),
                _buildInfoRow(
                  icon: CupertinoIcons.eye,
                  label: 'العرض',
                  value: widget.section.displayStyle.name ==
                          SectionDisplayStyle.grid.name
                      ? 'شبكة'
                      : widget.section.displayStyle.name ==
                              SectionDisplayStyle.list.name
                          ? 'قائمة'
                          : widget.section.displayStyle.name ==
                                  SectionDisplayStyle.carousel.name
                              ? 'دائري'
                              : widget.section.displayStyle.name ==
                                      SectionDisplayStyle.map.name
                                  ? 'خريطة'
                                  : 'غير معروف',
                ),
                const SizedBox(height: 6),
                _buildInfoRow(
                  icon: CupertinoIcons.number,
                  label: 'الترتيب',
                  value: widget.section.displayOrder.toString(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // الأزرار
          _buildFullActions(),
        ],
      ),
    );
  }

  // باقي التصاميم من الإصدار الجديد
  Widget _buildCompactContent() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildSmallTypeIcon(size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.section.title ?? widget.section.name ?? 'قسم',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildMiniStatusBadge(),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(CupertinoIcons.layers,
                        size: 10, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      widget.section.type.value,
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(CupertinoIcons.number,
                        size: 10, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.section.displayOrder}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildGridContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.darkCard.withOpacity(0.2),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.darkBorder.withOpacity(0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildSmallTypeIcon(size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.section.title ?? widget.section.name ?? 'قسم',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildMiniStatusBadge(),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMiniInfo(
                    CupertinoIcons.layers, widget.section.type.value),
                const SizedBox(height: 6),
                _buildMiniInfo(CupertinoIcons.square_stack,
                    widget.section.contentType.name),
                const SizedBox(height: 6),
                _buildMiniInfo(CupertinoIcons.number,
                    'ترتيب: ${widget.section.displayOrder}'),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.darkBackground.withOpacity(0.3),
            border: Border(
              top: BorderSide(
                color: AppTheme.darkBorder.withOpacity(0.1),
                width: 0.5,
              ),
            ),
          ),
          child: _buildGridActions(),
        ),
      ],
    );
  }

  // باقي الـ helper methods...
  Widget _buildMiniStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: widget.section.isActive
            ? AppTheme.success.withOpacity(0.15)
            : AppTheme.textMuted.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: widget.section.isActive
              ? AppTheme.success.withOpacity(0.3)
              : AppTheme.textMuted.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.section.isActive
                  ? AppTheme.success
                  : AppTheme.textMuted,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            widget.section.isActive ? 'فعال' : 'غير فعال',
            style: TextStyle(
              fontSize: 10,
              color: widget.section.isActive
                  ? AppTheme.success
                  : AppTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallTypeIcon({required double size}) {
    final (icon, color) = _getTypeIconAndColor();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(size * 0.2),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          color: color,
          size: size * 0.6,
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMiniActionIcon(
          icon: CupertinoIcons.eye,
          onTap: widget.onTap,
          color: AppTheme.info,
        ),
        const SizedBox(width: 6),
        _buildMiniActionIcon(
          icon: CupertinoIcons.pencil,
          onTap: widget.onEdit,
          color: AppTheme.primaryBlue,
        ),
        if (widget.onManageItems != null) ...[
          const SizedBox(width: 6),
          _buildMiniActionIcon(
            icon: CupertinoIcons.square_stack_3d_down_right,
            onTap: widget.onManageItems,
            color: AppTheme.primaryPurple,
          ),
        ],
      ],
    );
  }

  Widget _buildMiniActionIcon({
    required IconData icon,
    VoidCallback? onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  Widget _buildFullActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: CupertinoIcons.eye,
            label: 'عرض',
            onTap: widget.onTap,
            color: AppTheme.info,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            icon: CupertinoIcons.pencil,
            label: 'تعديل',
            onTap: widget.onEdit,
            color: AppTheme.primaryBlue,
          ),
        ),
        if (widget.onManageItems != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              icon: CupertinoIcons.square_stack_3d_down_right,
              label: 'إدارة',
              onTap: widget.onManageItems,
              color: AppTheme.primaryPurple,
            ),
          ),
        ],
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            icon: widget.section.isActive
                ? CupertinoIcons.pause
                : CupertinoIcons.play,
            label: widget.section.isActive ? 'إيقاف' : 'تفعيل',
            onTap: widget.onToggleStatus,
            color:
                widget.section.isActive ? AppTheme.warning : AppTheme.success,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Color? color,
    bool isPrimary = false,
  }) {
    final buttonColor =
        color ?? (isPrimary ? AppTheme.primaryBlue : AppTheme.textMuted);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: buttonColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: buttonColor.withOpacity(0.25),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: buttonColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: buttonColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMiniActionButton(
                icon: CupertinoIcons.eye,
                onTap: widget.onTap,
                color: AppTheme.info,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildMiniActionButton(
                icon: CupertinoIcons.pencil,
                onTap: widget.onEdit,
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (widget.onManageItems != null)
              Expanded(
                child: _buildMiniActionButton(
                  icon: CupertinoIcons.square_stack_3d_down_right,
                  onTap: widget.onManageItems,
                  color: AppTheme.primaryPurple,
                ),
              ),
            if (widget.onManageItems != null) const SizedBox(width: 6),
            Expanded(
              child: _buildMiniActionButton(
                icon: widget.section.isActive
                    ? CupertinoIcons.pause
                    : CupertinoIcons.play,
                onTap: widget.onToggleStatus,
                color: widget.section.isActive
                    ? AppTheme.warning
                    : AppTheme.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniActionButton({
    required IconData icon,
    VoidCallback? onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        height: 26,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: color.withOpacity(0.25),
            width: 0.5,
          ),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  Widget _buildFullWidthActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.8),
              color.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppTheme.textMuted.withOpacity(0.7)),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
            fontSize: 11,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 11, color: AppTheme.textMuted.withOpacity(0.7)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textWhite.withOpacity(0.9),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  (IconData, Color) _getTypeIconAndColor() {
    switch (widget.section.type) {
      case SectionTypeEnum.singlePropertyAd:
        return (CupertinoIcons.star_fill, AppTheme.warning);
      case SectionTypeEnum.multiPropertyAd:
        return (CupertinoIcons.flame_fill, AppTheme.error);
      case SectionTypeEnum.unitShowcaseAd:
        return (CupertinoIcons.sparkles, AppTheme.success);
      case SectionTypeEnum.singlePropertyOffer:
        return (CupertinoIcons.chart_bar_alt_fill, AppTheme.primaryPurple);
      case SectionTypeEnum.flashDeals:
        return (CupertinoIcons.tag_fill, AppTheme.warning);
      case SectionTypeEnum.cityCardsGrid:
        return (CupertinoIcons.location_fill, AppTheme.info);
      case SectionTypeEnum.premiumCarousel:
        return (CupertinoIcons.hand_thumbsup_fill, AppTheme.primaryBlue);
      case SectionTypeEnum.verticalPropertyGrid:
        return (CupertinoIcons.square_grid_2x2_fill, AppTheme.primaryViolet);
      case SectionTypeEnum.horizontalPropertyList:
        return (CupertinoIcons.wrench_fill, AppTheme.textMuted);
      default:
        return (CupertinoIcons.square_fill, AppTheme.textMuted);
    }
  }

  void _setHovered(bool value) {
    setState(() => _isHovered = value);
    if (value) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
}
