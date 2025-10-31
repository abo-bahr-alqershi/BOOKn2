import 'package:bookn_cp_app/features/admin_amenities/presentation/bloc/amenities_bloc.dart';
import 'package:bookn_cp_app/features/admin_amenities/presentation/bloc/amenities_event.dart';
import 'package:bookn_cp_app/features/admin_amenities/presentation/utils/amenity_icons.dart';
import 'package:bookn_cp_app/features/admin_amenities/presentation/widgets/assign_amenity_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/amenity_identity_card_tooltip.dart';
import '../../domain/entities/amenity.dart';

/// 📊 Premium Amenities Table - Enhanced Version
class FuturisticAmenitiesTable extends StatefulWidget {
  final List<Amenity> amenities;
  final Function(Amenity) onAmenitySelected;
  final Function(Amenity)? onEditAmenity;
  final Function(Amenity)? onDeleteAmenity;
  final Function(Amenity)? onAssignAmenity;
  final VoidCallback? onLoadMore;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final ScrollController? controller; // will not be used for inner scrolling

  const FuturisticAmenitiesTable({
    super.key,
    required this.amenities,
    required this.onAmenitySelected,
    this.onEditAmenity,
    this.onDeleteAmenity,
    this.onAssignAmenity,
    this.onLoadMore,
    this.hasReachedMax = true,
    this.isLoadingMore = false,
    this.controller,
  });

  @override
  State<FuturisticAmenitiesTable> createState() =>
      _FuturisticAmenitiesTableState();
}

class _FuturisticAmenitiesTableState extends State<FuturisticAmenitiesTable>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _fadeAnimationController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;

  // State
  int? _hoveredIndex;
  int? _selectedIndex;
  String _sortBy = 'name';
  bool _isAscending = true;
  late final ScrollController _scrollController;
  bool _ownsController = false;
  final Map<String, GlobalKey> _amenityRowKeys = {};

  // Responsive breakpoints (match units table)
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 1024;

  // Filters similar to units design
  bool? _activeFilter; // null=all, true=active, false=inactive
  bool? _paidFilter; // null=all, true=paid (>0), false=free (==0)
  late List<Amenity> _filteredAmenities;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeControllers();
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1,
      end: 2,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimationController.forward();
  }

  void _initializeControllers() {
    // Do not attach internal scroll to avoid nested scrolling; use page scroll only
    _scrollController = ScrollController();
    _ownsController = true;
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    if (_ownsController) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_handleScroll);
    }
    super.dispose();
  }

  void _handleScroll() {}

  GlobalKey _getAmenityRowKey(String amenityId, {String scope = 'default'}) {
    final cacheKey = scope.isEmpty ? amenityId : '$amenityId-$scope';
    return _amenityRowKeys.putIfAbsent(cacheKey, () => GlobalKey());
  }

  void _showAmenityTooltip(Amenity amenity, {String scope = 'default'}) {
    final targetKey = _getAmenityRowKey(amenity.id, scope: scope);
    AmenityIdentityCardTooltip.show(
      context: context,
      targetKey: targetKey,
      amenityId: amenity.id,
      name: amenity.name,
      description: amenity.description,
      icon: amenity.icon,
      isAvailable: amenity.isActive ?? true,
      extraCost: amenity.averageExtraCost,
      currency: null,
      propertiesCount: amenity.propertiesCount,
      category: null,
    );
  }

  List<Amenity> get _sortedAmenities {
    final sorted = List<Amenity>.from(widget.amenities);

    sorted.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'properties':
          comparison =
              (a.propertiesCount ?? 0).compareTo(b.propertiesCount ?? 0);
          break;
        case 'cost':
          comparison =
              (a.averageExtraCost ?? 0).compareTo(b.averageExtraCost ?? 0);
          break;
        case 'status':
          comparison = (a.isActive == true ? 1 : 0)
              .compareTo(b.isActive == true ? 1 : 0);
          break;
        default:
          comparison = 0;
      }
      return _isAscending ? comparison : -comparison;
    });

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < _mobileBreakpoint;
    final isTablet =
        size.width >= _mobileBreakpoint && size.width < _tabletBreakpoint;

    // derive filtered list
    _filteredAmenities = widget.amenities.where((a) {
      if (_activeFilter != null) {
        if ((a.isActive == true) != _activeFilter) return false;
      }
      if (_paidFilter != null) {
        final hasCost = (a.averageExtraCost ?? 0) > 0;
        if (hasCost != _paidFilter) return false;
      }
      return true;
    }).toList();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (isMobile) return _buildMobileView();
          if (isTablet) return _buildTabletView();
          return _buildDesktopView();
        },
      ),
    );
  }

  // ================= Units-like Table: Mobile/Tablet/Desktop =================
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
            itemCount: _sortedAmenitiesForDisplay.length,
            itemBuilder: (context, index) {
              final amenity = _sortedAmenitiesForDisplay[index];
              return _buildMobileAmenityRowCard(amenity, index);
            },
          ),
          if (widget.isLoadingMore) _buildLoadingIndicator(),
        ],
      ),
    );
  }

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
                    width: MediaQuery.of(context).size.width,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _sortedAmenitiesForDisplay.length,
                      itemBuilder: (context, index) {
                        final amenity = _sortedAmenitiesForDisplay[index];
                        return _buildTabletRow(amenity, index);
                      },
                    ),
                  ),
                ),
                if (widget.isLoadingMore) _buildLoadingIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopView() {
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
          borderRadius: BorderRadius.circular(24),
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
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDesktopHeader(),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sortedAmenitiesForDisplay.length,
                  itemBuilder: (context, index) => _buildDesktopRow(
                      _sortedAmenitiesForDisplay[index], index),
                ),
                if (widget.isLoadingMore) _buildLoadingIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortMenu() {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryPurple.withOpacity(0.1),
              AppTheme.primaryBlue.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.primaryPurple.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.sort_rounded,
          color: AppTheme.primaryPurple,
          size: 20,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.primaryPurple.withOpacity(0.2),
          width: 1,
        ),
      ),
      color: AppTheme.isDark ? AppTheme.darkCard : Colors.white,
      elevation: 8,
      onSelected: (value) {
        setState(() {
          if (_sortBy == value) {
            _isAscending = !_isAscending;
          } else {
            _sortBy = value;
            _isAscending = true;
          }
        });
      },
      itemBuilder: (context) => [
        _buildEnhancedSortMenuItem('name', 'الاسم', Icons.text_fields),
        _buildEnhancedSortMenuItem(
            'properties', 'العقارات', Icons.business_rounded),
        _buildEnhancedSortMenuItem(
            'cost', 'التكلفة', Icons.attach_money_rounded),
        _buildEnhancedSortMenuItem('status', 'الحالة', Icons.toggle_on_rounded),
      ],
    );
  }

  PopupMenuItem<String> _buildEnhancedSortMenuItem(
      String value, String label, IconData icon) {
    final isActive = _sortBy == value;
    return PopupMenuItem(
      value: value,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(
                        colors: [
                          AppTheme.primaryPurple.withOpacity(0.2),
                          AppTheme.primaryBlue.withOpacity(0.1),
                        ],
                      )
                    : null,
                color: !isActive ? AppTheme.darkSurface.withOpacity(0.3) : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 16,
                color: isActive ? AppTheme.primaryPurple : AppTheme.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isActive ? AppTheme.primaryPurple : AppTheme.textWhite,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 12,
                  color: AppTheme.primaryPurple,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedHeaderCell(
    String title,
    String sortKey, {
    required int flex,
    IconData? icon,
    bool isPrimary = false,
  }) {
    final isActive = _sortBy == sortKey;

    return Expanded(
      flex: flex,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              if (_sortBy == sortKey) {
                _isAscending = !_isAscending;
              } else {
                _sortBy = sortKey;
                _isAscending = true;
              }
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                if (icon != null) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: isActive || isPrimary
                          ? LinearGradient(
                              colors: [
                                AppTheme.primaryPurple.withOpacity(0.2),
                                AppTheme.primaryBlue.withOpacity(0.1),
                              ],
                            )
                          : null,
                      color: !isActive && !isPrimary
                          ? AppTheme.darkSurface.withOpacity(0.2)
                          : null,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      icon,
                      size: 14,
                      color: isActive || isPrimary
                          ? AppTheme.primaryPurple
                          : AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isActive
                          ? AppTheme.primaryPurple
                          : AppTheme.textLight,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: isActive && !_isAscending ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isActive
                        ? Icons.arrow_upward_rounded
                        : Icons.unfold_more_rounded,
                    size: 14,
                    color: isActive
                        ? AppTheme.primaryPurple
                        : AppTheme.textMuted.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== Header & Rows (units style) =====
  Widget _buildDesktopHeader() {
    return Container(
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
          _buildHeaderCell('المرفق', flex: 3),
          _buildHeaderCell('العقارات', flex: 1),
          _buildHeaderCell('التكلفة', flex: 1),
          _buildHeaderCell('الحالة', flex: 1),
          _buildHeaderCell('الإجراءات', flex: 2),
        ],
      ),
    );
  }

  Widget _buildTabletHeader() {
    return Column(
      children: [
        _buildTabletFilterBar(),
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
              _buildHeaderCell('المرفق', flex: 3),
              _buildHeaderCell('العقارات', flex: 2),
              _buildHeaderCell('التكلفة', flex: 2),
              _buildHeaderCell('الحالة', flex: 1),
              _buildHeaderCell('الإجراءات', flex: 2),
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

  List<Amenity> get _sortedAmenitiesForDisplay =>
      _sortedAmenities.where((a) => _filteredAmenities.contains(a)).toList();

  Widget _buildDesktopRow(Amenity amenity, int index) {
    final isEven = index % 2 == 0;
    final isHovered = _hoveredIndex == index;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        key: _getAmenityRowKey(amenity.id, scope: 'desktop'),
        onTap: () {
          HapticFeedback.lightImpact();
          _showAmenityTooltip(amenity, scope: 'desktop');
          setState(() => _selectedIndex = index);
          widget.onAmenitySelected(amenity);
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showAmenityTooltip(amenity, scope: 'desktop');
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
              // Amenity info (icon + name + desc)
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
                        _getAmenityIcon(amenity.icon),
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
                            amenity.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppTheme.textWhite,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            amenity.description,
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

              // Properties count
              Expanded(
                flex: 1,
                child: Text(
                  '${amenity.propertiesCount ?? 0}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textLight,
                  ),
                ),
              ),

              // Cost
              Expanded(
                flex: 1,
                child: Text(
                  (amenity.averageExtraCost != null &&
                          amenity.averageExtraCost! > 0)
                      ? '\$${amenity.averageExtraCost!.toStringAsFixed(0)}'
                      : 'مجاني',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: (amenity.averageExtraCost != null &&
                            amenity.averageExtraCost! > 0)
                        ? AppTheme.primaryBlue
                        : AppTheme.textMuted,
                    fontWeight: (amenity.averageExtraCost != null &&
                            amenity.averageExtraCost! > 0)
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),

              // Status
              Expanded(
                flex: 1,
                child: _buildStatusBadge(amenity),
              ),

              // Actions
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionButton(
                      icon: Icons.visibility_rounded,
                      color: AppTheme.primaryBlue,
                      onTap: () => widget.onAmenitySelected(amenity),
                    ),
                    if (widget.onEditAmenity != null) ...[
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.edit,
                        color: AppTheme.primaryBlue,
                        onTap: () => widget.onEditAmenity!(amenity),
                      ),
                    ],
                    if (widget.onAssignAmenity != null) ...[
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.assignment_rounded,
                        color: AppTheme.primaryPurple,
                        onTap: () => widget.onAssignAmenity!(amenity),
                      ),
                    ],
                    if (widget.onDeleteAmenity != null) ...[
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.delete,
                        color: AppTheme.error,
                        onTap: () => widget.onDeleteAmenity!(amenity),
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

  Widget _buildTabletRow(Amenity amenity, int index) {
    // For tablet, reuse desktop row (width handled by SizedBox in tablet view)
    return _buildDesktopRow(amenity, index);
  }

  // ===== Mobile components =====
  Widget _buildMobileFilterBar() {
    final totalActive =
        widget.amenities.where((a) => a.isActive == true).length;
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('الكل (${widget.amenities.length})', null, null),
            const SizedBox(width: 8),
            _buildFilterChip('نشط ($totalActive)', true, null),
            const SizedBox(width: 8),
            _buildFilterChip('معطل', false, null),
            const SizedBox(width: 8),
            _buildFilterChip('مدفوع', null, true),
            const SizedBox(width: 8),
            _buildFilterChip('مجاني', null, false),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletFilterBar() {
    return _buildMobileFilterBar();
  }

  Widget _buildFilterChip(String label, bool? activeFilter, bool? paidFilter) {
    final isSelected =
        (_activeFilter == activeFilter) && (_paidFilter == paidFilter);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _activeFilter = activeFilter;
          _paidFilter = paidFilter;
        });
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

  Widget _buildMobileAmenityRowCard(Amenity amenity, int index) {
    final isHovered = _hoveredIndex == index;
    return GestureDetector(
      key: _getAmenityRowKey(amenity.id, scope: 'mobile'),
      onTap: () {
        HapticFeedback.lightImpact();
        _showAmenityTooltip(amenity, scope: 'mobile');
        widget.onAmenitySelected(amenity);
      },
      onTapDown: (_) => setState(() => _hoveredIndex = index),
      onTapUp: (_) => setState(() => _hoveredIndex = null),
      onTapCancel: () => setState(() => _hoveredIndex = null),
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showAmenityTooltip(amenity, scope: 'mobile');
      },
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
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getAmenityIcon(amenity.icon),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              amenity.name,
                              style: AppTextStyles.heading3.copyWith(
                                fontSize: 16,
                                color: AppTheme.textWhite,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              amenity.description,
                              style: AppTextStyles.caption.copyWith(
                                color: AppTheme.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(amenity),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.business_rounded,
                                size: 16,
                                color: AppTheme.primaryBlue,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${amenity.propertiesCount ?? 0}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'عقار',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppTheme.primaryBlue.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                (amenity.averageExtraCost ?? 0) > 0
                                    ? Icons.attach_money_rounded
                                    : Icons.money_off_rounded,
                                size: 16,
                                color: (amenity.averageExtraCost ?? 0) > 0
                                    ? AppTheme.success
                                    : AppTheme.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                (amenity.averageExtraCost ?? 0) > 0
                                    ? amenity.averageExtraCost!
                                        .toStringAsFixed(0)
                                    : 'مجاني',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: (amenity.averageExtraCost ?? 0) > 0
                                      ? AppTheme.success
                                      : AppTheme.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionTextButton(
                          label: 'عرض التفاصيل',
                          icon: Icons.visibility_rounded,
                          color: AppTheme.primaryBlue,
                          onTap: () => widget.onAmenitySelected(amenity),
                        ),
                      ),
                      if (widget.onEditAmenity != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionTextButton(
                            label: 'تعديل',
                            icon: Icons.edit_rounded,
                            color: AppTheme.primaryPurple,
                            onTap: () => widget.onEditAmenity!(amenity),
                          ),
                        ),
                      ],
                      if (widget.onDeleteAmenity != null) ...[
                        const SizedBox(width: 8),
                        _buildActionButton(
                          icon: Icons.delete_rounded,
                          color: AppTheme.error,
                          onTap: () => widget.onDeleteAmenity!(amenity),
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

  Widget _buildCostWidget(Amenity amenity) {
    final hasCost =
        amenity.averageExtraCost != null && amenity.averageExtraCost! > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasCost
              ? [
                  AppTheme.success.withOpacity(0.15),
                  AppTheme.neonGreen.withOpacity(0.08),
                ]
              : [
                  AppTheme.textMuted.withOpacity(0.1),
                  AppTheme.textMuted.withOpacity(0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasCost
              ? AppTheme.success.withOpacity(0.3)
              : AppTheme.textMuted.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasCost) ...[
            Text(
              '\$',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.success.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              amenity.averageExtraCost!.toStringAsFixed(0),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else ...[
            Icon(
              Icons.money_off_rounded,
              size: 14,
              color: AppTheme.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              'مجاني',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusWidget(Amenity amenity) {
    final isActive = amenity.isActive == true;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // Toggle status functionality
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isActive
                ? [
                    AppTheme.success.withOpacity(0.2),
                    AppTheme.neonGreen.withOpacity(0.1),
                  ]
                : [
                    AppTheme.textMuted.withOpacity(0.2),
                    AppTheme.textMuted.withOpacity(0.1),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppTheme.success.withOpacity(0.5)
                : AppTheme.textMuted.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.success.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.success : AppTheme.textMuted,
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppTheme.success.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isActive ? 'نشط' : 'معطل',
              style: AppTextStyles.caption.copyWith(
                color: isActive ? AppTheme.success : AppTheme.textMuted,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Compatibility badge API used by the units-like table rows
  Widget _buildStatusBadge(Amenity amenity) {
    return _buildStatusWidget(amenity);
  }

  Widget _buildPremiumActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.9), color.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(8), // زوايا حادة هادئة
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
      ),
    );
  }

  // Reusable actions/buttons for table rows
  Widget _buildActionButton({
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
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: color.withOpacity(0.1),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildActionTextButton({
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
              Icon(icon, size: 16, color: color),
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

  Widget _buildEnhancedMobileList() {
    final sortedAmenities = _sortedAmenities;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: sortedAmenities.length,
      itemBuilder: (context, index) {
        final amenity = sortedAmenities[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onAmenitySelected(amenity);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppTheme.isDark
                        ? [
                            AppTheme.darkSurface.withOpacity(0.4),
                            const Color(0xFF1A0E2E).withOpacity(0.2),
                          ]
                        : [
                            AppTheme.lightSurface,
                            AppTheme.lightBackground,
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryPurple.withOpacity(0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryPurple.withOpacity(0.2),
                                AppTheme.primaryBlue.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryPurple.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            _getAmenityIcon(amenity.icon),
                            color: AppTheme.primaryPurple,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      amenity.name,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppTheme.textWhite,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryPurple
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '#${amenity.id.substring(0, 6).toUpperCase()}',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppTheme.primaryPurple,
                                        fontSize: 9,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                amenity.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.onEditAmenity != null ||
                            widget.onAssignAmenity != null ||
                            widget.onDeleteAmenity != null)
                          PopupMenuButton<String>(
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.darkSurface.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.more_vert_rounded,
                                color: AppTheme.textMuted,
                                size: 20,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: AppTheme.isDark
                                ? AppTheme.darkCard
                                : Colors.white,
                            onSelected: (value) {
                              HapticFeedback.selectionClick();
                              if (value == 'edit') {
                                widget.onEditAmenity?.call(amenity);
                              } else if (value == 'assign') {
                                widget.onAssignAmenity?.call(amenity);
                              } else if (value == 'delete') {
                                widget.onDeleteAmenity?.call(amenity);
                              }
                            },
                            itemBuilder: (context) => [
                              if (widget.onEditAmenity != null)
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: AppTheme.primaryPurple,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'تعديل',
                                        style:
                                            AppTextStyles.bodyMedium.copyWith(
                                          color: AppTheme.textWhite,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (widget.onAssignAmenity != null)
                                PopupMenuItem(
                                  value: 'assign',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.assignment_outlined,
                                        size: 18,
                                        color: AppTheme.primaryPurple,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'تعيين',
                                        style:
                                            AppTextStyles.bodyMedium.copyWith(
                                          color: AppTheme.textWhite,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (widget.onDeleteAmenity != null)
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: AppTheme.error,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'حذف',
                                        style:
                                            AppTextStyles.bodyMedium.copyWith(
                                          color: AppTheme.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryBlue.withOpacity(0.1),
                                  AppTheme.primaryBlue.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.primaryBlue.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.business_rounded,
                                  size: 18,
                                  color: AppTheme.primaryBlue,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${amenity.propertiesCount ?? 0}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'عقار',
                                  style: AppTextStyles.caption.copyWith(
                                    color:
                                        AppTheme.primaryBlue.withOpacity(0.7),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: amenity.averageExtraCost != null &&
                                        amenity.averageExtraCost! > 0
                                    ? [
                                        AppTheme.success.withOpacity(0.15),
                                        AppTheme.neonGreen.withOpacity(0.08),
                                      ]
                                    : [
                                        AppTheme.textMuted.withOpacity(0.1),
                                        AppTheme.textMuted.withOpacity(0.05),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: amenity.averageExtraCost != null &&
                                        amenity.averageExtraCost! > 0
                                    ? AppTheme.success.withOpacity(0.3)
                                    : AppTheme.textMuted.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  amenity.averageExtraCost != null &&
                                          amenity.averageExtraCost! > 0
                                      ? Icons.attach_money_rounded
                                      : Icons.money_off_rounded,
                                  size: 18,
                                  color: amenity.averageExtraCost != null &&
                                          amenity.averageExtraCost! > 0
                                      ? AppTheme.success
                                      : AppTheme.textMuted,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  amenity.averageExtraCost != null &&
                                          amenity.averageExtraCost! > 0
                                      ? '\$${amenity.averageExtraCost!.toStringAsFixed(0)}'
                                      : 'مجاني',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: amenity.averageExtraCost != null &&
                                            amenity.averageExtraCost! > 0
                                        ? AppTheme.success
                                        : AppTheme.textMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'التكلفة',
                                  style: AppTextStyles.caption.copyWith(
                                    color: amenity.averageExtraCost != null &&
                                            amenity.averageExtraCost! > 0
                                        ? AppTheme.success.withOpacity(0.7)
                                        : AppTheme.textMuted.withOpacity(0.7),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildStatusWidget(amenity),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'جاري التحميل...',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterStats() {
    final totalCount = widget.amenities.length;
    final activeCount =
        widget.amenities.where((a) => a.isActive == true).length;
    final averageCost = _calculateAverageCost();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkSurface.withOpacity(0.4),
            AppTheme.darkSurface.withOpacity(0.2),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: AppTheme.primaryPurple.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useWrap = constraints.maxWidth < 700;
          if (useWrap) {
            return Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildFooterStat(
                  icon: Icons.checklist_rounded,
                  label: 'المجموع',
                  value: totalCount.toString(),
                  color: AppTheme.primaryPurple,
                ),
                _buildFooterStat(
                  icon: Icons.toggle_on_rounded,
                  label: 'نشط',
                  value: activeCount.toString(),
                  color: AppTheme.success,
                ),
                _buildFooterStat(
                  icon: Icons.toggle_off_rounded,
                  label: 'معطل',
                  value: (totalCount - activeCount).toString(),
                  color: AppTheme.textMuted,
                ),
                _buildFooterStat(
                  icon: Icons.attach_money_rounded,
                  label: 'متوسط التكلفة',
                  value: '\$$averageCost',
                  color: AppTheme.warning,
                ),
              ],
            );
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFooterStat(
                icon: Icons.checklist_rounded,
                label: 'المجموع',
                value: totalCount.toString(),
                color: AppTheme.primaryPurple,
              ),
              _buildFooterStat(
                icon: Icons.toggle_on_rounded,
                label: 'نشط',
                value: activeCount.toString(),
                color: AppTheme.success,
              ),
              _buildFooterStat(
                icon: Icons.toggle_off_rounded,
                label: 'معطل',
                value: (totalCount - activeCount).toString(),
                color: AppTheme.textMuted,
              ),
              _buildFooterStat(
                icon: Icons.attach_money_rounded,
                label: 'متوسط التكلفة',
                value: '\$$averageCost',
                color: AppTheme.warning,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFooterStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted,
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _calculateAverageCost() {
    if (widget.amenities.isEmpty) return '0';

    final costs = widget.amenities
        .where((a) => a.averageExtraCost != null && a.averageExtraCost! > 0)
        .map((a) => a.averageExtraCost!)
        .toList();

    if (costs.isEmpty) return '0';

    final average = costs.reduce((a, b) => a + b) / costs.length;
    return average.toStringAsFixed(0);
  }

  IconData _getAmenityIcon(String iconName) {
    return AmenityIcons.getIconByName(iconName)?.icon ?? Icons.star_rounded;
  }
}
