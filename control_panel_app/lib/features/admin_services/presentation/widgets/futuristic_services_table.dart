import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/service.dart';
import '../utils/service_icons.dart';

/// 📊 Premium Services Table
class FuturisticServicesTable extends StatefulWidget {
  final List<Service> services;
  final Function(Service) onServiceTap;
  final Function(Service)? onEdit;
  final Function(Service)? onDelete;
  final VoidCallback? onLoadMore;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final ScrollController? controller;
  // When embedded inside a parent CustomScrollView (Slivers), disable internal scrolling
  // and rely on the parent for scrolling and bottom loader.
  final bool embeddedInScrollView;

  const FuturisticServicesTable({
    super.key,
    required this.services,
    required this.onServiceTap,
    this.onEdit,
    this.onDelete,
    this.onLoadMore,
    this.hasReachedMax = true,
    this.isLoadingMore = false,
    this.controller,
    this.embeddedInScrollView = false,
  });

  @override
  State<FuturisticServicesTable> createState() => _FuturisticServicesTableState();
}

class _FuturisticServicesTableState extends State<FuturisticServicesTable>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  int? _hoveredIndex;
  String _sortBy = 'none';
  bool _isAscending = true;
  late final ScrollController _scrollController;
  bool _ownsController = false;

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
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();

    _scrollController = widget.controller ?? ScrollController();
    _ownsController = widget.controller == null;
    if (!widget.embeddedInScrollView) {
      _scrollController.addListener(_handleScroll);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (!widget.embeddedInScrollView) {
      if (_ownsController) {
        _scrollController.dispose();
      } else {
        _scrollController.removeListener(_handleScroll);
      }
    }
    super.dispose();
  }

  void _handleScroll() {
    if (widget.onLoadMore == null || widget.hasReachedMax) return;
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent * 0.9) {
      widget.onLoadMore!.call();
    }
  }

  List<Service> get _sortedServices {
    if (_sortBy == 'none') {
      return List<Service>.from(widget.services);
    }

    final sorted = List<Service>.from(widget.services);
    sorted.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'property':
          comparison = a.propertyName.compareTo(b.propertyName);
          break;
        case 'price':
          comparison = a.price.amount.compareTo(b.price.amount);
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
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1200;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.isDark 
            ? AppTheme.darkCard.withOpacity(0.6)
            : Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          border: Border.all(
            color: AppTheme.darkBorder.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(AppTheme.isDark ? 0.2 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            if (!isMobile) _buildDesktopHeader(),
            if (isMobile) _buildMobileHeader(),
            // Content
            if (widget.embeddedInScrollView)
              (isMobile ? _buildMobileList() : _buildDesktopTable())
            else
              Expanded(
                child: isMobile 
                  ? _buildMobileList() 
                  : _buildDesktopTable(),
              ),
            // Inline loader only when not embedded (standalone usage)
            if (widget.isLoadingMore && !widget.embeddedInScrollView) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.isDark 
          ? AppTheme.darkSurface.withOpacity(0.3)
          : AppTheme.lightBackground.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildHeaderCell(
            'الخدمة',
            'name',
            flex: 3,
            icon: Icons.room_service_outlined,
          ),
          _buildHeaderCell(
            'العقار',
            'property',
            flex: 2,
            icon: Icons.business_outlined,
          ),
          _buildHeaderCell(
            'السعر',
            'price',
            flex: 2,
            icon: Icons.payments_outlined,
          ),
          const SizedBox(width: 100),
        ],
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.isDark 
          ? AppTheme.darkSurface.withOpacity(0.3)
          : AppTheme.lightBackground.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'الخدمات (${widget.services.length})',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.sort_rounded,
              color: AppTheme.textMuted,
              size: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: AppTheme.isDark ? AppTheme.darkCard : Colors.white,
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
              _buildSortMenuItem('name', 'الاسم', Icons.text_fields),
              _buildSortMenuItem('property', 'العقار', Icons.business_outlined),
              _buildSortMenuItem('price', 'السعر', Icons.payments_outlined),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildSortMenuItem(String value, String label, IconData icon) {
    final isActive = _sortBy == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isActive ? AppTheme.primaryBlue : AppTheme.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isActive ? AppTheme.primaryBlue : AppTheme.textWhite,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (isActive)
            Icon(
              _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: AppTheme.primaryBlue,
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
    String title,
    String sortKey, {
    required int flex,
    IconData? icon,
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
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: isActive ? AppTheme.primaryBlue : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isActive ? AppTheme.primaryBlue : AppTheme.textLight,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  isActive
                    ? (_isAscending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded)
                    : Icons.unfold_more_rounded,
                  size: 14,
                  color: isActive 
                    ? AppTheme.primaryBlue 
                    : AppTheme.textMuted.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTable() {
    final sortedServices = _sortedServices;
    if (widget.embeddedInScrollView) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sortedServices.length,
        itemBuilder: (context, index) {
          final service = sortedServices[index];
          final isHovered = _hoveredIndex == index;
          
          return MouseRegion(
            onEnter: (_) => setState(() => _hoveredIndex = index),
            onExit: (_) => setState(() => _hoveredIndex = null),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onServiceTap(service);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 2,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isHovered
                      ? AppTheme.primaryBlue.withOpacity(0.05)
                      : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isHovered 
                      ? Border.all(
                          color: AppTheme.primaryBlue.withOpacity(0.2),
                          width: 1,
                        )
                      : null,
                  ),
                  child: Row(
                    children: [
                      // Service Info
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                ServiceIcons.getIconByName(service.icon),
                                color: AppTheme.primaryBlue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppTheme.textWhite,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Icons.${service.icon}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppTheme.textMuted,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Property
                      Expanded(
                        flex: 2,
                        child: Text(
                          service.propertyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppTheme.textLight,
                          ),
                        ),
                      ),
                      
                      // Price
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${service.price.amount} ${service.price.currency}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppTheme.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              service.pricingModel.label,
                              style: AppTextStyles.caption.copyWith(
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Actions
                      SizedBox(
                        width: 100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (widget.onEdit != null)
                              IconButton(
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  widget.onEdit!(service);
                                },
                                icon: Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: AppTheme.textMuted,
                                ),
                                tooltip: 'تعديل',
                              ),
                            if (widget.onDelete != null)
                              IconButton(
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  widget.onDelete!(service);
                                },
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: AppTheme.error.withOpacity(0.8),
                                ),
                                tooltip: 'حذف',
                              ),
                          ],
                        ),
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
    
    return Scrollbar(
      controller: _scrollController,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sortedServices.length,
        itemBuilder: (context, index) {
          final service = sortedServices[index];
          final isHovered = _hoveredIndex == index;
          
          return MouseRegion(
            onEnter: (_) => setState(() => _hoveredIndex = index),
            onExit: (_) => setState(() => _hoveredIndex = null),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onServiceTap(service);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 2,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isHovered
                      ? AppTheme.primaryBlue.withOpacity(0.05)
                      : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isHovered 
                      ? Border.all(
                          color: AppTheme.primaryBlue.withOpacity(0.2),
                          width: 1,
                        )
                      : null,
                  ),
                  child: Row(
                    children: [
                      // Service Info
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                ServiceIcons.getIconByName(service.icon),
                                color: AppTheme.primaryBlue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppTheme.textWhite,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Icons.${service.icon}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppTheme.textMuted,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Property
                      Expanded(
                        flex: 2,
                        child: Text(
                          service.propertyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppTheme.textLight,
                          ),
                        ),
                      ),
                      
                      // Price
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${service.price.amount} ${service.price.currency}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppTheme.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              service.pricingModel.label,
                              style: AppTextStyles.caption.copyWith(
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Actions
                      SizedBox(
                        width: 100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (widget.onEdit != null)
                              IconButton(
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  widget.onEdit!(service);
                                },
                                icon: Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: AppTheme.textMuted,
                                ),
                                tooltip: 'تعديل',
                              ),
                            if (widget.onDelete != null)
                              IconButton(
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  widget.onDelete!(service);
                                },
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: AppTheme.error.withOpacity(0.8),
                                ),
                                tooltip: 'حذف',
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileList() {
    final sortedServices = _sortedServices;
    if (widget.embeddedInScrollView) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: sortedServices.length,
        itemBuilder: (context, index) {
          final service = sortedServices[index];
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onServiceTap(service);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.isDark
                      ? AppTheme.darkSurface.withOpacity(0.3)
                      : AppTheme.lightSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.darkBorder.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              ServiceIcons.getIconByName(service.icon),
                              color: AppTheme.primaryBlue,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.name,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppTheme.textWhite,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  service.propertyName,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.onEdit != null || widget.onDelete != null)
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert_rounded,
                                color: AppTheme.textMuted,
                                size: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: AppTheme.isDark ? AppTheme.darkCard : Colors.white,
                              onSelected: (value) {
                                HapticFeedback.selectionClick();
                                if (value == 'edit') {
                                  widget.onEdit?.call(service);
                                } else if (value == 'delete') {
                                  widget.onDelete?.call(service);
                                }
                              },
                              itemBuilder: (context) => [
                                if (widget.onEdit != null)
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                          color: AppTheme.textMuted,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'تعديل',
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            color: AppTheme.textWhite,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (widget.onDelete != null)
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
                                          style: AppTextStyles.bodyMedium.copyWith(
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
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              service.pricingModel.label,
                              style: AppTextStyles.caption.copyWith(
                                color: AppTheme.textMuted,
                              ),
                            ),
                            Text(
                              '${service.price.amount} ${service.price.currency}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppTheme.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
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
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: sortedServices.length,
      itemBuilder: (context, index) {
        final service = sortedServices[index];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onServiceTap(service);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.isDark
                    ? AppTheme.darkSurface.withOpacity(0.3)
                    : AppTheme.lightSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.darkBorder.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            ServiceIcons.getIconByName(service.icon),
                            color: AppTheme.primaryBlue,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.name,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppTheme.textWhite,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                service.propertyName,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.onEdit != null || widget.onDelete != null)
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert_rounded,
                              color: AppTheme.textMuted,
                              size: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: AppTheme.isDark ? AppTheme.darkCard : Colors.white,
                            onSelected: (value) {
                              HapticFeedback.selectionClick();
                              if (value == 'edit') {
                                widget.onEdit?.call(service);
                              } else if (value == 'delete') {
                                widget.onDelete?.call(service);
                              }
                            },
                            itemBuilder: (context) => [
                              if (widget.onEdit != null)
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: AppTheme.textMuted,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'تعديل',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppTheme.textWhite,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (widget.onDelete != null)
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
                                        style: AppTextStyles.bodyMedium.copyWith(
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
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            service.pricingModel.label,
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          ),
                          Text(
                            '${service.price.amount} ${service.price.currency}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppTheme.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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
}