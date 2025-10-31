// lib/features/admin_units/presentation/widgets/futuristic_units_table.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../domain/entities/unit.dart';

class FuturisticUnitsTable extends StatefulWidget {
  final List<Unit> units;
  final Function(Unit) onUnitSelected;
  final Function(Unit)? onEditUnit;
  final Function(Unit)? onDeleteUnit;

  const FuturisticUnitsTable({
    super.key,
    required this.units,
    required this.onUnitSelected,
    this.onEditUnit,
    this.onDeleteUnit,
  });

  @override
  State<FuturisticUnitsTable> createState() => _FuturisticUnitsTableState();
}

class _FuturisticUnitsTableState extends State<FuturisticUnitsTable>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String? _hoveredUnitId;
  String? _selectedUnitType;
  List<String> _unitTypes = [];
  List<Unit> _filteredUnits = [];
  bool _isLoadingTypes = false;

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
    _extractUnitTypes();
    _filterUnits();
  }

  void _extractUnitTypes() {
    setState(() => _isLoadingTypes = true);
    final typesSet = <String>{};
    for (final unit in widget.units) {
      typesSet.add(unit.unitTypeName);
    }
    _unitTypes = typesSet.toList()..sort();
    setState(() => _isLoadingTypes = false);
  }

  void _filterUnits() {
    if (_selectedUnitType == null) {
      _filteredUnits = List.from(widget.units);
    } else {
      _filteredUnits = widget.units
          .where((unit) => unit.unitTypeName == _selectedUnitType)
          .toList();
    }
  }

  @override
  void didUpdateWidget(FuturisticUnitsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.units.length != widget.units.length) {
      _extractUnitTypes();
      _filterUnits();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
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

  // ================ MOBILE VIEW ================
  Widget _buildMobileView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMobileFilterBar(),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: _filteredUnits.length,
            itemBuilder: (context, index) {
              final unit = _filteredUnits[index];
              return _buildMobileUnitCard(unit, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFilterBar() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.9),
            AppTheme.darkCard.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('الكل', null),
                const SizedBox(width: 8),
                ..._unitTypes.map((type) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _buildFilterChip(type, type),
                    )),
              ],
            ),
          ),
          if (_isLoadingTypes)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryBlue.withOpacity(0.3),
                ),
                minHeight: 2,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _selectedUnitType == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUnitType = value;
          _filterUnits();
        });
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.3),
                    AppTheme.primaryPurple.withOpacity(0.2),
                  ],
                )
              : null,
          color: !isSelected ? AppTheme.darkSurface.withOpacity(0.5) : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlue.withOpacity(0.5)
                : AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.textLight,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileUnitCard(Unit unit, int index) {
    final isHovered = _hoveredUnitId == unit.id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onUnitSelected(unit);
      },
      onTapDown: (_) => setState(() => _hoveredUnitId = unit.id),
      onTapUp: (_) => setState(() => _hoveredUnitId = null),
      onTapCancel: () => setState(() => _hoveredUnitId = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        transform: Matrix4.identity()..scale(isHovered ? 0.98 : 1.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withOpacity(0.9),
              AppTheme.darkCard.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHovered
                ? AppTheme.primaryBlue.withOpacity(0.4)
                : AppTheme.darkBorder.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isHovered
                  ? AppTheme.primaryBlue.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
              blurRadius: isHovered ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      // Unit Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getUnitIcon(unit.unitTypeName),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Unit Name & Property
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              unit.name,
                              style: AppTextStyles.heading3.copyWith(
                                fontSize: 16,
                                color: AppTheme.textWhite,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.business_rounded,
                                  size: 12,
                                  color:
                                      AppTheme.primaryPurple.withOpacity(0.7),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    unit.propertyName,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppTheme.textMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Status Badge
                      _buildMobileStatusBadge(unit.isAvailable),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Details Grid
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildMobileDetailRow(
                          icon: Icons.category_rounded,
                          label: 'النوع',
                          value: unit.unitTypeName,
                          iconColor: AppTheme.primaryBlue,
                        ),
                        const SizedBox(height: 8),
                        _buildMobileDetailRow(
                          icon: Icons.attach_money_rounded,
                          label: 'السعر',
                          value: unit.basePrice.displayAmount,
                          iconColor: AppTheme.success,
                          valueStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppTheme.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildMobileDetailRow(
                          icon: Icons.people_rounded,
                          label: 'السعة',
                          value: unit.capacityDisplay.isEmpty
                              ? 'غير محدد'
                              : unit.capacityDisplay,
                          iconColor: AppTheme.warning,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Dynamic Fields (Primary Filters)
                  Builder(builder: (context) {
                    final fields = _getPrimaryFilterFields(unit);
                    if (fields.isEmpty) return const SizedBox.shrink();
                    final visible = fields.take(3).toList();
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.darkBorder.withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.filter_list_rounded,
                                size: 14,
                                color: AppTheme.neonPurple,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'المعلومات الأساسية',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppTheme.neonPurple,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ...visible.map((f) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: _buildDynamicFieldRow(
                                  displayName: f['displayName'] as String,
                                  value: f['value'],
                                  fieldType: f['fieldTypeId'] as String,
                                ),
                              )),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildMobileActionButton(
                          label: 'عرض التفاصيل',
                          icon: Icons.visibility_rounded,
                          color: AppTheme.primaryBlue,
                          onTap: () => widget.onUnitSelected(unit),
                        ),
                      ),
                      if (widget.onEditUnit != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMobileActionButton(
                            label: 'تعديل',
                            icon: Icons.edit_rounded,
                            color: AppTheme.primaryPurple,
                            onTap: () => widget.onEditUnit!(unit),
                          ),
                        ),
                      ],
                      if (widget.onDeleteUnit != null) ...[
                        const SizedBox(width: 8),
                        _buildMobileIconButton(
                          icon: Icons.delete_rounded,
                          color: AppTheme.error,
                          onTap: () => widget.onDeleteUnit!(unit),
                        ),
                      ],
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

  Widget _buildMobileDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    TextStyle? valueStyle,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: iconColor.withOpacity(0.7),
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
            style: valueStyle ??
                AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileStatusBadge(bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAvailable
              ? [
                  AppTheme.success.withOpacity(0.2),
                  AppTheme.success.withOpacity(0.1),
                ]
              : [
                  AppTheme.error.withOpacity(0.2),
                  AppTheme.error.withOpacity(0.1),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAvailable
              ? AppTheme.success.withOpacity(0.5)
              : AppTheme.error.withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isAvailable ? AppTheme.success : AppTheme.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isAvailable ? 'متاحة' : 'غير متاحة',
            style: AppTextStyles.caption.copyWith(
              color: isAvailable ? AppTheme.success : AppTheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withOpacity(0.3),
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

  Widget _buildMobileIconButton({
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
      ),
    );
  }

  // ================ TABLET VIEW ================
  Widget _buildTabletView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.glassLight.withOpacity(0.05),
              AppTheme.glassDark.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.darkBorder.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTabletHeader(),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 900,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredUnits.length,
                      itemBuilder: (context, index) {
                        final unit = _filteredUnits[index];
                        return _buildTabletRow(unit, index);
                      },
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
    return Column(
      children: [
        // Filter Bar for tablet
        Container(
          padding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('الكل', null),
                    const SizedBox(width: 8),
                    ..._unitTypes.map((type) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _buildFilterChip(type, type),
                        )),
                  ],
                ),
              ),
              if (_isLoadingTypes)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryBlue.withOpacity(0.3),
                    ),
                    minHeight: 2,
                  ),
                ),
            ],
          ),
        ),

        // Table Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue.withOpacity(0.1),
                AppTheme.primaryPurple.withOpacity(0.05),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              _buildHeaderCell('الوحدة', flex: 3),
              _buildHeaderCell('النوع', flex: 2),
              _buildHeaderCell('السعر', flex: 2),
              _buildHeaderCell('الحالة', flex: 1),
              _buildHeaderCell('الإجراءات', flex: 2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletRow(Unit unit, int index) {
    final isHovered = _hoveredUnitId == unit.id;
    final isEven = index % 2 == 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredUnitId = unit.id),
      onExit: (_) => setState(() => _hoveredUnitId = null),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onUnitSelected(unit);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isHovered
                ? LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withOpacity(0.08),
                      AppTheme.primaryPurple.withOpacity(0.04),
                    ],
                  )
                : null,
            color: !isHovered
                ? isEven
                    ? AppTheme.darkCard.withOpacity(0.03)
                    : Colors.transparent
                : null,
            border: Border(
              bottom: BorderSide(
                color: AppTheme.darkBorder.withOpacity(0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Unit Info
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getUnitIcon(unit.unitTypeName),
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unit.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppTheme.textWhite,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            unit.propertyName,
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Builder(builder: (context) {
                            final fields = _getPrimaryFilterFields(unit);
                            if (fields.isEmpty) return const SizedBox.shrink();
                            final visible = fields.take(2).toList();
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: visible
                                    .map((f) => _buildDynamicFieldRow(
                                          displayName:
                                              f['displayName'] as String,
                                          value: f['value'],
                                          fieldType: f['fieldTypeId'] as String,
                                        ))
                                    .toList(),
                              ),
                            );
                          }),
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
                  unit.unitTypeName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textLight,
                  ),
                ),
              ),

              // Price
              Expanded(
                flex: 2,
                child: Text(
                  unit.basePrice.displayAmount,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Status
              Expanded(
                flex: 1,
                child: _buildStatusCell(unit.isAvailable),
              ),

              // Actions
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.onEditUnit != null)
                      _buildActionButton(
                        Icons.edit,
                        AppTheme.primaryBlue,
                        () => widget.onEditUnit!(unit),
                      ),
                    if (widget.onDeleteUnit != null) ...[
                      const SizedBox(width: 8),
                      _buildActionButton(
                        Icons.delete,
                        AppTheme.error,
                        () => widget.onDeleteUnit!(unit),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================ DESKTOP VIEW ================
  Widget _buildDesktopView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(AppDimensions.paddingLarge),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.glassLight.withOpacity(0.05),
              AppTheme.glassDark.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
          border: Border.all(
            color: AppTheme.darkBorder.withOpacity(0.3),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDesktopHeader(),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredUnits.length,
                  itemBuilder: (context, index) =>
                      _buildDesktopRow(_filteredUnits[index], index),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Column(
      children: [
        // Filter Bar for desktop
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Stack(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('الكل', null),
                    const SizedBox(width: 8),
                    ..._unitTypes.map((type) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _buildFilterChip(type, type),
                        )),
                  ],
                ),
              ),
              if (_isLoadingTypes)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryBlue.withOpacity(0.3),
                    ),
                    minHeight: 2,
                  ),
                ),
            ],
          ),
        ),

        // Table Header
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue.withOpacity(0.1),
                AppTheme.primaryPurple.withOpacity(0.05),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              _buildHeaderCell('الوحدة', flex: 2),
              _buildHeaderCell('النوع', flex: 1),
              _buildHeaderCell('الكيان', flex: 2),
              _buildHeaderCell('السعر', flex: 1),
              _buildHeaderCell('السعة', flex: 1),
              _buildHeaderCell('الحالة', flex: 1),
              _buildHeaderCell('الإجراءات', flex: 1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppTheme.primaryBlue,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDesktopRow(Unit unit, int index) {
    final isEven = index % 2 == 0;
    final isHovered = _hoveredUnitId == unit.id;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredUnitId = unit.id),
      onExit: (_) => setState(() => _hoveredUnitId = null),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onUnitSelected(unit);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          decoration: BoxDecoration(
            gradient: isHovered
                ? LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withOpacity(0.08),
                      AppTheme.primaryPurple.withOpacity(0.04),
                    ],
                  )
                : null,
            color: !isHovered
                ? isEven
                    ? AppTheme.darkCard.withOpacity(0.03)
                    : Colors.transparent
                : null,
            border: Border(
              bottom: BorderSide(
                color: AppTheme.darkBorder.withOpacity(0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Name + compact primary fields under it
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.name,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Builder(builder: (context) {
                      final fields = _getPrimaryFilterFields(unit);
                      if (fields.isEmpty) return const SizedBox.shrink();
                      final visible = fields.take(2).toList();
                      return Row(
                        children: visible
                            .map((f) => Expanded(
                                  child: _buildDynamicFieldRow(
                                    displayName: f['displayName'] as String,
                                    value: f['value'],
                                    fieldType: f['fieldTypeId'] as String,
                                  ),
                                ))
                            .toList(),
                      );
                    }),
                  ],
                ),
              ),
              _buildCell(unit.unitTypeName, flex: 1),
              _buildCell(unit.propertyName, flex: 2),
              _buildCell(unit.basePrice.displayAmount, flex: 1, isPrice: true),
              _buildCell(
                  unit.capacityDisplay.isEmpty ? '-' : unit.capacityDisplay,
                  flex: 1),
              _buildStatusCell(unit.isAvailable, flex: 1),
              _buildActionsCell(unit, flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(String text,
      {int flex = 1, bool isName = false, bool isPrice = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: isName
              ? AppTheme.textWhite
              : isPrice
                  ? AppTheme.primaryBlue
                  : AppTheme.textLight,
          fontWeight: isName || isPrice ? FontWeight.w600 : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildStatusCell(bool isAvailable, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingSmall,
          vertical: AppDimensions.paddingXSmall,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isAvailable
                ? [
                    AppTheme.success.withOpacity(0.2),
                    AppTheme.success.withOpacity(0.1)
                  ]
                : [
                    AppTheme.error.withOpacity(0.2),
                    AppTheme.error.withOpacity(0.1)
                  ],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        child: Text(
          isAvailable ? 'متاحة' : 'غير متاحة',
          style: AppTextStyles.caption.copyWith(
            color: isAvailable ? AppTheme.success : AppTheme.error,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildActionsCell(Unit unit, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.onEditUnit != null)
            _buildActionButton(
              Icons.edit,
              AppTheme.primaryBlue,
              () => widget.onEditUnit!(unit),
            ),
          if (widget.onDeleteUnit != null) ...[
            const SizedBox(width: AppDimensions.spaceXSmall),
            _buildActionButton(
              Icons.delete,
              AppTheme.error,
              () => widget.onDeleteUnit!(unit),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          border: Border.all(
            color: color.withOpacity(0.3),
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

  IconData _getUnitIcon(String unitType) {
    switch (unitType.toLowerCase()) {
      case 'room':
      case 'غرفة':
        return Icons.bed_rounded;
      case 'suite':
      case 'جناح':
        return Icons.king_bed_rounded;
      case 'villa':
      case 'فيلا':
        return Icons.villa_rounded;
      case 'apartment':
      case 'شقة':
        return Icons.apartment_rounded;
      case 'chalet':
      case 'شاليه':
        return Icons.house_rounded;
      case 'studio':
      case 'ستوديو':
        return Icons.meeting_room_rounded;
      case 'الكل':
        return Icons.dashboard_rounded;
      default:
        return Icons.home_rounded;
    }
  }

  // =============== Dynamic Fields helpers ===============
  List<Map<String, dynamic>> _getPrimaryFilterFields(Unit unit) {
    final fields = <Map<String, dynamic>>[];
    final seen = <String>{};

    // From flat fieldValues
    for (final fv in unit.fieldValues) {
      if (fv.isPrimaryFilter == true && !seen.contains(fv.fieldId)) {
        fields.add({
          'displayName': fv.displayName ?? fv.fieldName ?? 'حقل',
          'value': fv.fieldValue,
          'fieldTypeId': fv.fieldTypeId ?? 'text',
        });
        seen.add(fv.fieldId);
      }
    }

    // From grouped dynamicFields
    for (final group in unit.dynamicFields) {
      for (final f in group.fieldValues) {
        if (f.isPrimaryFilter == true && !seen.contains(f.fieldId)) {
          fields.add({
            'displayName': f.displayName ?? f.fieldName ?? 'حقل',
            'value': f.fieldValue,
            'fieldTypeId': f.fieldTypeId ?? 'text',
          });
          seen.add(f.fieldId);
        }
      }
    }

    if (fields.isNotEmpty) return fields;

    // Fallback: first non-empty values
    for (final fv in unit.fieldValues) {
      if (fv.fieldValue.isNotEmpty && !seen.contains(fv.fieldId)) {
        fields.add({
          'displayName': fv.displayName ?? fv.fieldName ?? 'حقل',
          'value': fv.fieldValue,
          'fieldTypeId': fv.fieldTypeId ?? 'text',
        });
        seen.add(fv.fieldId);
      }
    }
    for (final group in unit.dynamicFields) {
      for (final f in group.fieldValues) {
        if (f.fieldValue.isNotEmpty && !seen.contains(f.fieldId)) {
          fields.add({
            'displayName': f.displayName ?? f.fieldName ?? 'حقل',
            'value': f.fieldValue,
            'fieldTypeId': f.fieldTypeId ?? 'text',
          });
          seen.add(f.fieldId);
        }
      }
    }
    return fields;
  }

  Widget _buildDynamicFieldRow({
    required String displayName,
    required dynamic value,
    required String fieldType,
  }) {
    final formatted = _formatDynamicFieldValue(value, fieldType);
    final icon = _getFieldTypeIcon(fieldType);
    final color = _getFieldTypeColor(fieldType);

    return Row(
      children: [
        Icon(icon, size: 12, color: color.withOpacity(0.7)),
        const SizedBox(width: 6),
        Text(
          '$displayName:',
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
            fontSize: 10,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            formatted,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDynamicFieldValue(dynamic value, String fieldType) {
    if (value == null || value.toString().isEmpty) return 'غير محدد';
    switch (fieldType) {
      case 'boolean':
        final v = value.toString().toLowerCase();
        return (v == 'true' || v == '1' || v == 'yes') ? 'نعم' : 'لا';
      case 'currency':
        final num? n = value is num ? value : num.tryParse(value.toString());
        return n != null ? '${n.toStringAsFixed(0)} ريال' : '$value ريال';
      case 'date':
        try {
          final d =
              value is DateTime ? value : DateTime.parse(value.toString());
          final mm = d.month.toString().padLeft(2, '0');
          final dd = d.day.toString().padLeft(2, '0');
          return '${d.year}-$mm-$dd';
        } catch (_) {
          return value.toString();
        }
      case 'number':
        if (value is num) return value.toString();
        return value.toString();
      case 'multiselect':
        if (value is List) return value.join(', ');
        return value.toString();
      case 'text':
      case 'textarea':
      case 'select':
      case 'email':
      case 'phone':
      case 'file':
      case 'image':
      default:
        final s = value.toString();
        return s.length > 20 ? '${s.substring(0, 20)}...' : s;
    }
  }

  IconData _getFieldTypeIcon(String fieldType) {
    switch (fieldType) {
      case 'text':
        return Icons.text_fields_rounded;
      case 'textarea':
        return Icons.notes_rounded;
      case 'number':
        return Icons.numbers_rounded;
      case 'currency':
        return Icons.attach_money_rounded;
      case 'boolean':
        return Icons.toggle_on_rounded;
      case 'select':
        return Icons.arrow_drop_down_circle_rounded;
      case 'multiselect':
        return Icons.checklist_rounded;
      case 'date':
        return Icons.calendar_today_rounded;
      case 'email':
        return Icons.email_rounded;
      case 'phone':
        return Icons.phone_rounded;
      case 'file':
        return Icons.attach_file_rounded;
      case 'image':
        return Icons.image_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color _getFieldTypeColor(String fieldType) {
    switch (fieldType) {
      case 'boolean':
        return AppTheme.info;
      case 'currency':
      case 'number':
        return AppTheme.success;
      case 'date':
        return AppTheme.primaryPurple;
      case 'select':
      case 'multiselect':
        return AppTheme.neonPurple;
      case 'email':
        return AppTheme.primaryBlue;
      case 'phone':
        return AppTheme.primaryCyan;
      case 'file':
      case 'image':
        return AppTheme.warning;
      default:
        return AppTheme.primaryBlue;
    }
  }
}
