// lib/features/admin_cities/presentation/widgets/futuristic_city_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/city.dart';
import 'city_images_collage.dart';

class FuturisticCityCard extends StatefulWidget {
  final City city;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isCompact;

  const FuturisticCityCard({
    super.key,
    required this.city,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isCompact = false,
  });

  @override
  State<FuturisticCityCard> createState() => _FuturisticCityCardState();
}

class _FuturisticCityCardState extends State<FuturisticCityCard>
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
        child: widget.isCompact ? _buildCompactCard() : _buildFullCard(),
      ),
    );
  }

  // الكارد الكامل - استخدام AspectRatio بدلاً من الارتفاع الثابت
  Widget _buildFullCard() {
    return AspectRatio(
      aspectRatio: 1.0, // نسبة 1:1 للكارد المربع
      child: Stack(
        children: [
          // الخلفية والإطار
          Container(
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.city.isActive == true
                    ? AppTheme.success.withOpacity(0.3)
                    : AppTheme.darkBorder.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowDark.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),

          // المحتوى
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final imageHeight = constraints.maxHeight * 0.65;
                final contentHeight = constraints.maxHeight * 0.35;

                return Stack(
                  children: [
                    // قسم الصور
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: imageHeight,
                      child: CityImagesCollage(
                        images: widget.city.images,
                        height: imageHeight,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                        ),
                        onTap: widget.onTap,
                        showImageCount: widget.city.images.length > 1,
                        enableHoverEffect: false,
                      ),
                    ),

                    // شارة الحالة
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _buildStatusBadge(),
                    ),

                    // قسم المحتوى
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: contentHeight,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: _buildContentSection(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // طبقة الإجراءات
          if (_showActions)
            Positioned.fill(
              child: _buildActionsOverlay(),
            ),
        ],
      ),
    );
  }

  // الكارد المضغوط
  Widget _buildCompactCard() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.city.isActive == true
              ? AppTheme.success.withOpacity(0.3)
              : AppTheme.darkBorder.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowDark.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Row(
              children: [
                // قسم الصور
                SizedBox(
                  width: 100,
                  child: CityImagesCollage(
                    images: widget.city.images.take(2).toList(),
                    height: 98, // نقص 2 بكسل للـ border
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(11),
                      bottomRight: Radius.circular(11),
                    ),
                    onTap: widget.onTap,
                    showImageCount: false,
                    enableHoverEffect: false,
                  ),
                ),

                // قسم المحتوى
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: _buildCompactContent(),
                  ),
                ),
              ],
            ),
          ),

          // طبقة الإجراءات
          if (_showActions)
            Positioned.fill(
              child: _buildActionsOverlay(),
            ),
        ],
      ),
    );
  }

  // محتوى القسم السفلي للكارد الكامل
  Widget _buildContentSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // معلومات المدينة
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // اسم المدينة
              Text(
                widget.city.name,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // الموقع
              Row(
                children: [
                  Icon(
                    CupertinoIcons.location_solid,
                    size: 9,
                    color: AppTheme.textMuted.withOpacity(0.7),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      widget.city.country,
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted.withOpacity(0.7),
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (widget.city.propertiesCount != null) ...[
                const SizedBox(height: 2),
                _buildPropertiesCount(),
              ],
            ],
          ),
        ),
        // أزرار الإجراءات
        Row(
          children: [
            _buildActionIcon(
              icon: CupertinoIcons.pencil,
              onTap: widget.onEdit,
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(width: 6),
            _buildActionIcon(
              icon: CupertinoIcons.trash,
              onTap: widget.onDelete,
              color: AppTheme.error,
            ),
          ],
        ),
      ],
    );
  }

  // محتوى الكارد المضغوط
  Widget _buildCompactContent() {
    return Row(
      children: [
        // معلومات المدينة
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الاسم والحالة
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.city.name,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildStatusBadge(isSmall: true),
                ],
              ),
              const SizedBox(height: 3),
              // الموقع
              Row(
                children: [
                  Icon(
                    CupertinoIcons.location,
                    size: 9,
                    color: AppTheme.textMuted.withOpacity(0.7),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      widget.city.country,
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted.withOpacity(0.7),
                        fontSize: 9,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              // المعلومات الإضافية
              Row(
                children: [
                  if (widget.city.images.length > 2) ...[
                    _buildImageBadge(),
                    const SizedBox(width: 4),
                  ],
                  if (widget.city.propertiesCount != null)
                    _buildPropertiesCount(isSmall: true),
                ],
              ),
            ],
          ),
        ),
        // أزرار صغيرة
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionIcon(
              icon: CupertinoIcons.pencil,
              onTap: widget.onEdit,
              color: AppTheme.primaryBlue,
              size: 8,
            ),
            const SizedBox(height: 4),
            _buildActionIcon(
              icon: CupertinoIcons.trash,
              onTap: widget.onDelete,
              color: AppTheme.error,
              size: 8,
            ),
          ],
        ),
      ],
    );
  }

  // أيقونة الإجراء
  Widget _buildActionIcon({
    required IconData icon,
    required VoidCallback? onTap,
    required Color color,
    double size = 10,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Icon(icon, size: size, color: color),
      ),
    );
  }

  // شارة الحالة
  Widget _buildStatusBadge({bool isSmall = false}) {
    final isActive = widget.city.isActive == true;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 4 : 6,
        vertical: isSmall ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.success.withOpacity(0.8)
            : AppTheme.textMuted.withOpacity(0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 3,
            height: 3,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            isActive ? 'نشط' : 'غير',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontSize: isSmall ? 8 : 9,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  // عداد العقارات
  Widget _buildPropertiesCount({bool isSmall = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.house_fill,
            size: isSmall ? 8 : 9,
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(width: 2),
          Text(
            '${widget.city.propertiesCount ?? 0}',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.primaryBlue,
              fontSize: isSmall ? 8 : 9,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  // شارة عدد الصور
  Widget _buildImageBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.photo,
            size: 8,
            color: AppTheme.primaryPurple,
          ),
          const SizedBox(width: 2),
          Text(
            '${widget.city.images.length}',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.primaryPurple,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  // طبقة الإجراءات
  Widget _buildActionsOverlay() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.isCompact ? 11 : 15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          color: AppTheme.darkBackground.withOpacity(0.85),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildOverlayAction(
                  icon: CupertinoIcons.pencil,
                  label: 'تعديل',
                  onTap: () {
                    setState(() => _showActions = false);
                    widget.onEdit?.call();
                  },
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 12),
                _buildOverlayAction(
                  icon: CupertinoIcons.trash,
                  label: 'حذف',
                  onTap: () {
                    setState(() => _showActions = false);
                    widget.onDelete?.call();
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

  // زر الإجراء في الطبقة العلوية
  Widget _buildOverlayAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
