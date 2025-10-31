import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';

/// Amenity Identity Card Tooltip - بطاقة المرفق المنبثقة
class AmenityIdentityCardTooltip {
  static OverlayEntry? _overlayEntry;
  static final GlobalKey<_AmenityCardContentState> _contentKey = GlobalKey();

  static void show({
    required BuildContext context,
    required GlobalKey targetKey,
    required String amenityId,
    required String name,
    required String description,
    required String icon,
    required bool isAvailable,
    double? extraCost,
    String? currency,
    int? propertiesCount,
    String? category,
  }) {
    hide();

    _overlayEntry = OverlayEntry(
      builder: (context) => _AmenityCardOverlay(
        targetKey: targetKey,
        amenityId: amenityId,
        name: name,
        description: description,
        icon: icon,
        isAvailable: isAvailable,
        extraCost: extraCost,
        currency: currency,
        propertiesCount: propertiesCount,
        category: category,
        contentKey: _contentKey,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide() {
    _contentKey.currentState?.animateOut(() {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }
}

class _AmenityCardOverlay extends StatelessWidget {
  final GlobalKey targetKey;
  final String amenityId;
  final String name;
  final String description;
  final String icon;
  final bool isAvailable;
  final double? extraCost;
  final String? currency;
  final int? propertiesCount;
  final String? category;
  final GlobalKey<_AmenityCardContentState> contentKey;

  const _AmenityCardOverlay({
    required this.targetKey,
    required this.amenityId,
    required this.name,
    required this.description,
    required this.icon,
    required this.isAvailable,
    this.extraCost,
    this.currency,
    this.propertiesCount,
    this.category,
    required this.contentKey,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: AmenityIdentityCardTooltip.hide,
          child: Container(
            color: Colors.black.withOpacity(0.3),
          ),
        ),
        _AmenityCardContent(
          key: contentKey,
          targetKey: targetKey,
          amenityId: amenityId,
          name: name,
          description: description,
          icon: icon,
          isAvailable: isAvailable,
          extraCost: extraCost,
          currency: currency,
          propertiesCount: propertiesCount,
          category: category,
        ),
      ],
    );
  }
}

class _AmenityCardContent extends StatefulWidget {
  final GlobalKey targetKey;
  final String amenityId;
  final String name;
  final String description;
  final String icon;
  final bool isAvailable;
  final double? extraCost;
  final String? currency;
  final int? propertiesCount;
  final String? category;

  const _AmenityCardContent({
    super.key,
    required this.targetKey,
    required this.amenityId,
    required this.name,
    required this.description,
    required this.icon,
    required this.isAvailable,
    this.extraCost,
    this.currency,
    this.propertiesCount,
    this.category,
  });

  @override
  State<_AmenityCardContent> createState() => _AmenityCardContentState();
}

class _AmenityCardContentState extends State<_AmenityCardContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void animateOut(VoidCallback onComplete) {
    _controller.reverse().then((_) => onComplete());
  }

  Color get statusColor {
    if (!widget.isAvailable) return AppTheme.error;
    if (isFree) return AppTheme.success;
    return AppTheme.primaryBlue;
  }

  bool get isFree => widget.extraCost == null || widget.extraCost == 0;

  IconData _getIconData() {
    // Map common icon names to Flutter icons
    final iconName = widget.icon.toLowerCase();
    if (iconName.contains('wifi')) return CupertinoIcons.wifi;
    if (iconName.contains('pool') || iconName.contains('swim'))
      return CupertinoIcons.drop_fill;
    if (iconName.contains('parking') || iconName.contains('car'))
      return CupertinoIcons.car_fill;
    if (iconName.contains('gym') || iconName.contains('fitness'))
      return CupertinoIcons.sportscourt_fill;
    if (iconName.contains('restaurant') || iconName.contains('food'))
      return CupertinoIcons.square_favorites_alt_fill;
    if (iconName.contains('spa')) return CupertinoIcons.heart_fill;
    if (iconName.contains('tv') || iconName.contains('television'))
      return CupertinoIcons.tv_fill;
    if (iconName.contains('ac') || iconName.contains('air'))
      return CupertinoIcons.wind;
    if (iconName.contains('coffee')) return CupertinoIcons.circle_fill;
    return CupertinoIcons.star_fill; // default
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Center(
              child: Container(
                width: isMobile ? size.width * 0.9 : 360,
                constraints: BoxConstraints(maxHeight: size.height * 0.75),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: DefaultTextStyle(
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.textWhite,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHeader(),
                            Flexible(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    _buildIconSection(),
                                    const SizedBox(height: 16),
                                    _buildInfoCard(
                                      CupertinoIcons.doc_text,
                                      'الوصف',
                                      widget.description,
                                      AppTheme.primaryPurple,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildDetailsGrid(),
                                    const SizedBox(height: 16),
                                    _buildAmenityId(),
                                  ],
                                ),
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
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: statusColor.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              CupertinoIcons.star_fill,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'بطاقة المرفق',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: AmenityIdentityCardTooltip.hide,
            icon: Icon(
              CupertinoIcons.xmark_circle_fill,
              color: AppTheme.textMuted,
              size: 22,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildIconSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Large Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [statusColor, statusColor.withOpacity(0.6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              _getIconData(),
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            widget.name,
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Badges
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              // Status Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: statusColor.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.isAvailable ? 'متاح' : 'غير متاح',
                      style: AppTextStyles.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Free/Paid Badge
              if (widget.isAvailable)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (isFree ? AppTheme.success : AppTheme.warning)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (isFree ? AppTheme.success : AppTheme.warning)
                          .withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFree
                            ? CupertinoIcons.gift_fill
                            : CupertinoIcons.money_dollar_circle_fill,
                        size: 12,
                        color: isFree ? AppTheme.success : AppTheme.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isFree ? 'مجاني' : 'مدفوع',
                        style: AppTextStyles.caption.copyWith(
                          color: isFree ? AppTheme.success : AppTheme.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.info_circle_fill,
                size: 16,
                color: AppTheme.primaryCyan,
              ),
              const SizedBox(width: 8),
              Text(
                'التفاصيل',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!isFree && widget.extraCost != null) ...[
                Expanded(
                  child: _buildDetailItem(
                    CupertinoIcons.money_dollar_circle,
                    widget.extraCost!.toStringAsFixed(0),
                    widget.currency ?? 'YER',
                    AppTheme.success,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (widget.propertiesCount != null)
                Expanded(
                  child: _buildDetailItem(
                    CupertinoIcons.building_2_fill,
                    widget.propertiesCount.toString(),
                    'عقار',
                    AppTheme.primaryBlue,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
      IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityId() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.number,
            size: 12,
            color: AppTheme.textMuted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'ID: ${widget.amenityId}',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
