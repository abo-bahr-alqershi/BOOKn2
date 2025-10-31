// lib/features/admin_properties/presentation/widgets/futuristic_property_table.dart

import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:bookn_cp_app/core/theme/app_colors.dart';
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';
import 'package:bookn_cp_app/core/theme/app_dimensions.dart';
import '../../domain/entities/property.dart';
import '../../../../core/widgets/property_identity_card_tooltip.dart';

class FuturisticPropertyTable extends StatefulWidget {
  final List<Property> properties;
  final Function(Property) onPropertyTap;
  final Function(Property) onEdit;
  final Function(String) onApprove;
  final Function(String) onReject;
  final Function(String) onDelete;
  final Function(Property) onAssignAmenities;

  const FuturisticPropertyTable({
    super.key,
    required this.properties,
    required this.onPropertyTap,
    required this.onEdit,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
    required this.onAssignAmenities,
  });

  @override
  State<FuturisticPropertyTable> createState() =>
      _FuturisticPropertyTableState();
}

class _FuturisticPropertyTableState extends State<FuturisticPropertyTable>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String? _sortColumn;
  bool _isAscending = true;
  String? _hoveredRowId;
  String? _pressedRowId;
  final Map<String, GlobalKey> _rowKeys = {};

  // Breakpoints
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 1024;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  GlobalKey _getRowKey(String propertyId) {
    if (!_rowKeys.containsKey(propertyId)) {
      _rowKeys[propertyId] = GlobalKey();
    }
    return _rowKeys[propertyId]!;
  }

  void _showPropertyCard(Property property) {
    setState(() => _pressedRowId = property.id);
    
    HapticFeedback.mediumImpact();
    
    PropertyIdentityCardTooltip.show(
      context: context,
      targetKey: _getRowKey(property.id),
      propertyId: property.id,
      name: property.name,
      typeName: property.typeName,
      ownerName: property.ownerName,
      address: property.address,
      city: property.city,
      starRating: property.starRating,
      coverImage: property.images.isNotEmpty ? property.images.first.thumbnails.large : null,
      isApproved: property.isApproved,
      isFeatured: property.isFeatured,
      createdAt: property.createdAt,
      viewCount: property.viewCount,
      bookingCount: property.bookingCount,
      averageRating: property.averageRating,
      shortDescription: property.shortDescription,
      currency: property.currency,
      amenitiesCount: property.amenities.length,
      policiesCount: property.policies.length,
      unitsCount: property.stats?.totalBookings ?? 0,
    );
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _pressedRowId = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // تحديد نوع الشاشة
        if (constraints.maxWidth < _mobileBreakpoint) {
          return _buildMobileView();
        } else if (constraints.maxWidth < _tabletBreakpoint) {
          return _buildTabletView();
        } else {
          return _buildDesktopView();
        }
      },
    );
  }

  // عرض الموبايل - بطاقات عمودية
  Widget _buildMobileView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: widget.properties.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final property = widget.properties[index];
          return _buildMobileCard(property);
        },
      ),
    );
  }

  Widget _buildMobileCard(Property property) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withValues(alpha: 0.9),
            AppTheme.darkCard.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: _getRowKey(property.id),
              onTap: () => widget.onPropertyTap(property),
              onLongPress: () => _showPropertyCard(property),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with image and status
                    Row(
                      children: [
                        // Property Image
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: property.images.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    property.images.first.thumbnails.small,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.business_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.business_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                        ),
                        const SizedBox(width: 12),
                        // Property Name and Type
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                property.name,
                                style: AppTextStyles.heading3.copyWith(
                                  fontSize: 16,
                                  color: AppTheme.textWhite,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  property.typeName,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Status Badge
                        _buildStatusBadge(property.isApproved),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Property Details Grid
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildMobileDetailRow(
                            icon: Icons.location_on_rounded,
                            label: 'المدينة',
                            value: property.city,
                            iconColor: AppTheme.primaryBlue,
                          ),
                          const SizedBox(height: 8),
                          _buildMobileDetailRow(
                            icon: Icons.location_city_rounded,
                            label: 'العنوان',
                            value: property.address,
                            iconColor: AppTheme.primaryPurple,
                          ),
                          const SizedBox(height: 8),
                          _buildMobileDetailRow(
                            icon: Icons.star_rounded,
                            label: 'التقييم',
                            value: '${property.starRating} نجوم',
                            iconColor: AppTheme.warning,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Action Buttons (responsive)
                    LayoutBuilder(
                      builder: (context, box) {
                        final bool isSmall = box.maxWidth < 380;

                        final List<Widget> actions = <Widget>[
                          if (!property.isApproved) ...[
                            _buildMobileActionButton(
                              label: 'موافقة',
                              icon: Icons.check_rounded,
                              color: AppTheme.success,
                              onTap: () => widget.onApprove(property.id),
                            ),
                            _buildMobileActionButton(
                              label: 'رفض',
                              icon: Icons.close_rounded,
                              color: AppTheme.warning,
                              onTap: () => widget.onReject(property.id),
                            ),
                          ] else
                            _buildMobileActionButton(
                              label: 'تعديل',
                              icon: Icons.edit_rounded,
                              color: AppTheme.primaryBlue,
                              onTap: () => widget.onEdit(property),
                            ),
                          _buildMobileActionButton(
                            label: 'تعيين مرافق',
                            icon: Icons.link_rounded,
                            color: AppTheme.primaryPurple,
                            onTap: () => widget.onAssignAmenities(property),
                          ),
                          _buildMobileActionButton(
                            label: 'حذف',
                            icon: Icons.delete_rounded,
                            color: AppTheme.error,
                            onTap: () => widget.onDelete(property.id),
                          ),
                        ];

                        if (isSmall) {
                          final double itemWidth = (box.maxWidth - 8) / 2;
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: actions
                                .map(
                                    (w) => SizedBox(width: itemWidth, child: w))
                                .toList(),
                          );
                        }

                        return Row(
                          children: [
                            for (int i = 0; i < actions.length; i++) ...[
                              Expanded(child: actions[i]),
                              if (i != actions.length - 1)
                                const SizedBox(width: 8),
                            ]
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: iconColor.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textLight,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
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
        ),
      ),
    );
  }

  // عرض التابلت - جدول مبسط قابل للتمرير
  Widget _buildTabletView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withValues(alpha: 0.7),
              AppTheme.darkCard.withValues(alpha: 0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryBlue.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              children: [
                // Simplified Header
                _buildTabletHeader(),

                // Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 800, // Fixed width for tablet
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: widget.properties.length,
                        itemBuilder: (context, index) {
                          final property = widget.properties[index];
                          return _buildTabletRow(property);
                        },
                      ),
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

  Widget _buildTabletHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.1),
            AppTheme.primaryPurple.withValues(alpha: 0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'العقار',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'الموقع',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                'الحالة',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                'الإجراءات',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletRow(Property property) {
    final isHovered = _hoveredRowId == property.id;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRowId = property.id),
      onExit: (_) => setState(() => _hoveredRowId = null),
      child: GestureDetector(
        key: _getRowKey(property.id),
        onTap: () => widget.onPropertyTap(property),
        onLongPress: () => _showPropertyCard(property),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: isHovered
                ? LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withValues(alpha: 0.08),
                      AppTheme.primaryPurple.withValues(alpha: 0.04),
                    ],
                  )
                : null,
            color:
                !isHovered ? AppTheme.darkSurface.withValues(alpha: 0.3) : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHovered
                  ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Property Info
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: property.images.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                property.images.first.thumbnails.small,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.business_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.business_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppTheme.textWhite,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Text(
                                property.typeName,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.star_rounded,
                                size: 12,
                                color: AppTheme.warning,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                property.starRating.toString(),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppTheme.warning,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Location
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.city,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.textLight,
                      ),
                    ),
                    Text(
                      property.address,
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Status
              Expanded(
                flex: 1,
                child: Center(
                  child: _buildStatusBadge(property.isApproved),
                ),
              ),

              // Actions
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!property.isApproved) ...[
                      _buildActionButton(
                        icon: Icons.check_rounded,
                        color: AppTheme.success,
                        onTap: () => widget.onApprove(property.id),
                      ),
                      const SizedBox(width: 4),
                      _buildActionButton(
                        icon: Icons.close_rounded,
                        color: AppTheme.warning,
                        onTap: () => widget.onReject(property.id),
                      ),
                    ] else
                      _buildActionButton(
                        icon: Icons.edit_rounded,
                        color: AppTheme.primaryBlue,
                        onTap: () {
                          // Navigate to edit
                        },
                      ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      icon: Icons.link_rounded,
                      color: AppTheme.primaryPurple,
                      onTap: () => widget.onAssignAmenities(property),
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      icon: Icons.delete_rounded,
                      color: AppTheme.error,
                      onTap: () => widget.onDelete(property.id),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // عرض سطح المكتب - الجدول الكامل
  Widget _buildDesktopView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withValues(alpha: 0.7),
              AppTheme.darkCard.withValues(alpha: 0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryBlue.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              children: [
                _buildDesktopHeader(),
                Expanded(
                  child: _buildDesktopBody(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader() {
    final headers = [
      {'label': 'العقار', 'key': 'name', 'flex': 3},
      {'label': 'النوع', 'key': 'type', 'flex': 2},
      {'label': 'المدينة', 'key': 'city', 'flex': 2},
      {'label': 'التقييم', 'key': 'rating', 'flex': 1},
      {'label': 'الحالة', 'key': 'status', 'flex': 2},
      {'label': 'الإجراءات', 'key': 'actions', 'flex': 2},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.1),
            AppTheme.primaryPurple.withValues(alpha: 0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: headers.map((header) {
          final isActionColumn = header['key'] == 'actions';
          return Expanded(
            flex: header['flex'] as int,
            child: isActionColumn
                ? Center(
                    child: Text(
                      header['label'] as String,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: () => _sort(header['key'] as String),
                    child: Row(
                      children: [
                        Text(
                          header['label'] as String,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_sortColumn == header['key'])
                          Icon(
                            _isAscending
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 14,
                            color: AppTheme.primaryBlue,
                          ),
                      ],
                    ),
                  ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDesktopBody() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.properties.length,
      itemBuilder: (context, index) {
        final property = widget.properties[index];
        return _buildDesktopRow(property);
      },
    );
  }

  Widget _buildDesktopRow(Property property) {
    final isHovered = _hoveredRowId == property.id;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRowId = property.id),
      onExit: (_) => setState(() => _hoveredRowId = null),
      child: GestureDetector(
        key: _getRowKey(property.id),
        onTap: () => widget.onPropertyTap(property),
        onLongPress: () => _showPropertyCard(property),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: isHovered
                ? LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withValues(alpha: 0.08),
                      AppTheme.primaryPurple.withValues(alpha: 0.04),
                    ],
                  )
                : null,
            color:
                !isHovered ? AppTheme.darkSurface.withValues(alpha: 0.3) : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHovered
                  ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Property Name & Image
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: property.images.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                property.images.first.thumbnails.small,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.business_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.business_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppTheme.textWhite,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            property.address,
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textMuted,
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

              // Type
              Expanded(
                flex: 2,
                child: Text(
                  property.typeName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textLight,
                  ),
                ),
              ),

              // City
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: AppTheme.primaryBlue.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      property.city,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),

              // Rating
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: AppTheme.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      property.starRating.toString(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Status
              Expanded(
                flex: 2,
                child: _buildStatusBadge(property.isApproved),
              ),

              // Actions
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!property.isApproved) ...[
                      _buildActionButton(
                        icon: Icons.check_rounded,
                        color: AppTheme.success,
                        onTap: () => widget.onApprove(property.id),
                      ),
                      const SizedBox(width: 4),
                      _buildActionButton(
                        icon: Icons.close_rounded,
                        color: AppTheme.warning,
                        onTap: () => widget.onReject(property.id),
                      ),
                    ] else
                      _buildActionButton(
                        icon: Icons.edit_rounded,
                        color: AppTheme.primaryBlue,
                        onTap: () {
                          // Navigate to edit
                        },
                      ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      icon: Icons.link_rounded,
                      color: AppTheme.primaryPurple,
                      onTap: () => widget.onAssignAmenities(property),
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      icon: Icons.delete_rounded,
                      color: AppTheme.error,
                      onTap: () => widget.onDelete(property.id),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isApproved) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isApproved
              ? [
                  AppTheme.success.withValues(alpha: 0.2),
                  AppTheme.success.withValues(alpha: 0.1),
                ]
              : [
                  AppTheme.warning.withValues(alpha: 0.2),
                  AppTheme.warning.withValues(alpha: 0.1),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isApproved
              ? AppTheme.success.withValues(alpha: 0.5)
              : AppTheme.warning.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Text(
        isApproved ? 'معتمد' : 'قيد المراجعة',
        style: AppTextStyles.caption.copyWith(
          color: isApproved ? AppTheme.success : AppTheme.warning,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          size: 14,
          color: color,
        ),
      ),
    );
  }

  void _sort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _isAscending = !_isAscending;
      } else {
        _sortColumn = column;
        _isAscending = true;
      }

      // TODO: Implement sorting logic
    });
  }
}
