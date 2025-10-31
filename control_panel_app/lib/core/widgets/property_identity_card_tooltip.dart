import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';

/// Property Identity Card Tooltip - بطاقة العقار المنبثقة
class PropertyIdentityCardTooltip {
  static OverlayEntry? _overlayEntry;
  static final GlobalKey<_PropertyCardContentState> _contentKey = GlobalKey();

  static void show({
    required BuildContext context,
    required GlobalKey targetKey,
    required String propertyId,
    required String name,
    required String typeName,
    required String ownerName,
    required String address,
    required String city,
    required int starRating,
    String? coverImage,
    required bool isApproved,
    required bool isFeatured,
    required DateTime createdAt,
    int viewCount = 0,
    int bookingCount = 0,
    double averageRating = 0.0,
    String? shortDescription,
    String currency = 'YER',
    int amenitiesCount = 0,
    int policiesCount = 0,
    int unitsCount = 0,
  }) {
    hide();

    _overlayEntry = OverlayEntry(
      builder: (context) => _PropertyCardOverlay(
        targetKey: targetKey,
        propertyId: propertyId,
        name: name,
        typeName: typeName,
        ownerName: ownerName,
        address: address,
        city: city,
        starRating: starRating,
        coverImage: coverImage,
        isApproved: isApproved,
        isFeatured: isFeatured,
        createdAt: createdAt,
        viewCount: viewCount,
        bookingCount: bookingCount,
        averageRating: averageRating,
        shortDescription: shortDescription,
        currency: currency,
        amenitiesCount: amenitiesCount,
        policiesCount: policiesCount,
        unitsCount: unitsCount,
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

class _PropertyCardOverlay extends StatelessWidget {
  final GlobalKey targetKey;
  final String propertyId;
  final String name;
  final String typeName;
  final String ownerName;
  final String address;
  final String city;
  final int starRating;
  final String? coverImage;
  final bool isApproved;
  final bool isFeatured;
  final DateTime createdAt;
  final int viewCount;
  final int bookingCount;
  final double averageRating;
  final String? shortDescription;
  final String currency;
  final int amenitiesCount;
  final int policiesCount;
  final int unitsCount;
  final GlobalKey<_PropertyCardContentState> contentKey;

  const _PropertyCardOverlay({
    required this.targetKey,
    required this.propertyId,
    required this.name,
    required this.typeName,
    required this.ownerName,
    required this.address,
    required this.city,
    required this.starRating,
    this.coverImage,
    required this.isApproved,
    required this.isFeatured,
    required this.createdAt,
    required this.viewCount,
    required this.bookingCount,
    required this.averageRating,
    this.shortDescription,
    required this.currency,
    required this.amenitiesCount,
    required this.policiesCount,
    required this.unitsCount,
    required this.contentKey,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: PropertyIdentityCardTooltip.hide,
          child: Container(
            color: Colors.black.withOpacity(0.3),
          ),
        ),
        _PropertyCardContent(
          key: contentKey,
          targetKey: targetKey,
          propertyId: propertyId,
          name: name,
          typeName: typeName,
          ownerName: ownerName,
          address: address,
          city: city,
          starRating: starRating,
          coverImage: coverImage,
          isApproved: isApproved,
          isFeatured: isFeatured,
          createdAt: createdAt,
          viewCount: viewCount,
          bookingCount: bookingCount,
          averageRating: averageRating,
          shortDescription: shortDescription,
          currency: currency,
          amenitiesCount: amenitiesCount,
          policiesCount: policiesCount,
          unitsCount: unitsCount,
        ),
      ],
    );
  }
}

class _PropertyCardContent extends StatefulWidget {
  final GlobalKey targetKey;
  final String propertyId;
  final String name;
  final String typeName;
  final String ownerName;
  final String address;
  final String city;
  final int starRating;
  final String? coverImage;
  final bool isApproved;
  final bool isFeatured;
  final DateTime createdAt;
  final int viewCount;
  final int bookingCount;
  final double averageRating;
  final String? shortDescription;
  final String currency;
  final int amenitiesCount;
  final int policiesCount;
  final int unitsCount;

  const _PropertyCardContent({
    super.key,
    required this.targetKey,
    required this.propertyId,
    required this.name,
    required this.typeName,
    required this.ownerName,
    required this.address,
    required this.city,
    required this.starRating,
    this.coverImage,
    required this.isApproved,
    required this.isFeatured,
    required this.createdAt,
    required this.viewCount,
    required this.bookingCount,
    required this.averageRating,
    this.shortDescription,
    required this.currency,
    required this.amenitiesCount,
    required this.policiesCount,
    required this.unitsCount,
  });

  @override
  State<_PropertyCardContent> createState() => _PropertyCardContentState();
}

class _PropertyCardContentState extends State<_PropertyCardContent>
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

  Color _getStatusColor() {
    if (!widget.isApproved) return AppTheme.warning;
    if (widget.isFeatured) return AppTheme.primaryBlue;
    return AppTheme.success;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final statusColor = _getStatusColor();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Center(
              child: Container(
                width: isMobile ? size.width * 0.9 : 400,
                constraints: BoxConstraints(maxHeight: size.height * 0.85),
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
                            _buildHeader(statusColor),
                            Flexible(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    _buildPropertyImage(statusColor),
                                    const SizedBox(height: 16),
                                    _buildInfoRow(
                                      CupertinoIcons.building_2_fill,
                                      'نوع العقار',
                                      widget.typeName,
                                      AppTheme.primaryBlue,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      CupertinoIcons.person_fill,
                                      'المالك',
                                      widget.ownerName,
                                      AppTheme.primaryPurple,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      CupertinoIcons.location_solid,
                                      'الموقع',
                                      '${widget.address}, ${widget.city}',
                                      AppTheme.primaryCyan,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildStatsGrid(),
                                    const SizedBox(height: 16),
                                    _buildPropertyId(),
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

  Widget _buildHeader(Color statusColor) {
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
              CupertinoIcons.building_2_fill,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'بطاقة العقار',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: PropertyIdentityCardTooltip.hide,
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

  Widget _buildPropertyImage(Color statusColor) {
    return Container(
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Property Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withOpacity(0.3),
                    statusColor.withOpacity(0.1),
                  ],
                ),
              ),
              child: widget.coverImage != null
                  ? Image.network(
                      widget.coverImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultImage(statusColor),
                    )
                  : _buildDefaultImage(statusColor),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Property Name
                Text(
                  widget.name,
                  style: AppTextStyles.heading2.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                if (widget.shortDescription != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.shortDescription!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textMuted,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                const SizedBox(height: 12),
                
                // Badges Row
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Star Rating
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.star_fill,
                            color: AppTheme.warning,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${widget.starRating}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                            widget.isApproved
                                ? (widget.isFeatured ? 'مميز' : 'موافق عليه')
                                : 'قيد المراجعة',
                            style: AppTextStyles.caption.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultImage(Color color) {
    return Container(
      color: color.withOpacity(0.1),
      child: Center(
        child: Icon(
          CupertinoIcons.photo,
          size: 60,
          color: color.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.chart_bar_fill,
                size: 16,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'إحصائيات العقار',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.2,
            children: [
              _buildStatItem(
                CupertinoIcons.eye_fill,
                widget.viewCount.toString(),
                'مشاهدة',
                AppTheme.info,
              ),
              _buildStatItem(
                CupertinoIcons.calendar,
                widget.bookingCount.toString(),
                'حجز',
                AppTheme.success,
              ),
              _buildStatItem(
                CupertinoIcons.star_fill,
                widget.averageRating.toStringAsFixed(1),
                'تقييم',
                AppTheme.warning,
              ),
              _buildStatItem(
                CupertinoIcons.square_grid_3x2,
                widget.amenitiesCount.toString(),
                'مرافق',
                AppTheme.primaryCyan,
              ),
              _buildStatItem(
                CupertinoIcons.doc_text,
                widget.policiesCount.toString(),
                'سياسات',
                AppTheme.primaryPurple,
              ),
              _buildStatItem(
                CupertinoIcons.square_stack_3d_up,
                widget.unitsCount.toString(),
                'وحدات',
                AppTheme.primaryBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted,
                fontSize: 8,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyId() {
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
              'ID: ${widget.propertyId}',
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
