// lib/features/home/presentation/widgets/premium_property_types_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yemen_booking_app/core/theme/app_text_styles.dart';
import 'package:yemen_booking_app/core/theme/app_theme.dart';
import 'package:yemen_booking_app/features/home/domain/entities/property_type.dart';
import 'package:yemen_booking_app/features/home/domain/entities/unit_type.dart';
import 'package:yemen_booking_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:yemen_booking_app/features/home/presentation/bloc/home_event.dart';
import 'package:yemen_booking_app/features/home/presentation/bloc/home_state.dart';
import 'dart:ui';
import 'dart:math' as math;

class PremiumPropertyTypesBar extends StatefulWidget {
  final List<PropertyType> propertyTypes;
  final String? selectedTypeId;
  final Function(String?) onTypeSelected;
  final double scrollOffset;

  const PremiumPropertyTypesBar({
    super.key,
    required this.propertyTypes,
    this.selectedTypeId,
    required this.onTypeSelected,
    this.scrollOffset = 0,
  });

  @override
  State<PremiumPropertyTypesBar> createState() =>
      _PremiumPropertyTypesBarState();
}

class _PremiumPropertyTypesBarState extends State<PremiumPropertyTypesBar>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _selectionController;
  late AnimationController _shimmerController;
  late AnimationController _entranceController;
  late AnimationController _expansionController;
  late AnimationController _unitTypesController;
  late AnimationController _pulseController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _expansionAnimation;
  late Animation<double> _unitTypesFadeAnimation;
  late Animation<Offset> _unitTypesSlideAnimation;
  late Animation<double> _pulseAnimation;

  // Scroll Controllers
  final ScrollController _propertyScrollController = ScrollController();
  final ScrollController _unitScrollController = ScrollController();

  // State
  int? _hoveredPropertyIndex;
  int? _hoveredUnitIndex;
  bool _showLeftGradient = false;
  bool _showRightGradient = true;
  bool _showUnitLeftGradient = false;
  bool _showUnitRightGradient = true;
  bool _isExpanded = false;
  String? _selectedUnitTypeId;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _scrollToSelected();
    _setupScrollListeners();

    // Ensure proper initial expansion if a type is already selected on app launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<HomeBloc>().state;
      if (!mounted) return;
      if (state is HomeLoaded && widget.selectedTypeId != null) {
        final units = state.unitTypes[widget.selectedTypeId] ?? const [];
        if (units.isNotEmpty && !_isExpanded) {
          // Set controllers to expanded without waiting for selection change
          setState(() {
            _isExpanded = true;
          });
          _expansionController.value = 1.0;
          _unitTypesController.value = 1.0;
        }
      }
    });
  }

  void _initializeAnimations() {
    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _expansionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _unitTypesController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutQuart),
    ));

    _expansionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _expansionController,
      curve: Curves.easeOutExpo,
    ));

    _unitTypesFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _unitTypesController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _unitTypesSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _unitTypesController,
      curve: Curves.easeOutQuart,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupScrollListeners() {
    _propertyScrollController.addListener(() {
      if (_propertyScrollController.hasClients) {
        setState(() {
          _showLeftGradient = _propertyScrollController.offset > 10;
          _showRightGradient = _propertyScrollController.offset <
              _propertyScrollController.position.maxScrollExtent - 10;
        });
      }
    });

    _unitScrollController.addListener(() {
      if (_unitScrollController.hasClients) {
        setState(() {
          _showUnitLeftGradient = _unitScrollController.offset > 10;
          _showUnitRightGradient = _unitScrollController.offset <
              _unitScrollController.position.maxScrollExtent - 10;
        });
      }
    });
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _entranceController.forward();
      }
    });
  }

  void _scrollToSelected() {
    if (widget.selectedTypeId != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final index = widget.propertyTypes.indexWhere(
          (type) => type.id == widget.selectedTypeId,
        );
        if (index != -1 && _propertyScrollController.hasClients) {
          _propertyScrollController.animateTo(
            index * 120.0,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutExpo,
          );
        }
      });
    }
  }

  @override
  void didUpdateWidget(PremiumPropertyTypesBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTypeId != oldWidget.selectedTypeId) {
      _selectionController.forward(from: 0);
      _scrollToSelected();

      // تحريك توسع/انكماش شريط أنواع الوحدات
      if (widget.selectedTypeId != null) {
        _expandUnitTypes();
      } else {
        _collapseUnitTypes();
      }
    }
  }

  void _expandUnitTypes() {
    setState(() {
      _isExpanded = true;
    });
    _expansionController.forward();
    _unitTypesController.forward();
  }

  void _collapseUnitTypes() {
    _unitTypesController.reverse().then((_) {
      _expansionController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isExpanded = false;
            _selectedUnitTypeId = null;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _selectionController.dispose();
    _shimmerController.dispose();
    _entranceController.dispose();
    _expansionController.dispose();
    _unitTypesController.dispose();
    _pulseController.dispose();
    _propertyScrollController.dispose();
    _unitScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.propertyTypes.isEmpty) return const SizedBox.shrink();

    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        // احصل على أنواع الوحدات للعقار المحدد
        List<UnitType> unitTypes = [];
        if (state is HomeLoaded && widget.selectedTypeId != null) {
          unitTypes = state.unitTypes[widget.selectedTypeId] ?? [];
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: AnimatedBuilder(
              animation: _expansionAnimation,
              builder: (context, child) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final maxH = constraints.maxHeight;
                    // Account for outer bottom border (0.5) which deflates child constraints
                    const double outerBorder = 0.5;
                    final effectiveMaxH =
                        (maxH - outerBorder).clamp(0.0, double.infinity);
                    final topH = math.min(56.0, effectiveMaxH);
                    final unitH = math.max(0.0, effectiveMaxH - topH);

                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard.withOpacity(0.3),
                        border: Border(
                          bottom: BorderSide(
                            color: AppTheme.primaryBlue.withOpacity(0.05),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: LayoutBuilder(
                            builder: (context, innerConstraints) {
                              final innerMaxH = innerConstraints.maxHeight;
                              final innerTopH = math.min(56.0, innerMaxH);
                              final innerUnitH =
                                  math.max(0.0, innerMaxH - innerTopH);

                              final showUnits = innerUnitH > 0 &&
                                  _isExpanded &&
                                  unitTypes.isNotEmpty;
                              return Column(
                                children: [
                                  if (showUnits) ...[
                                    // Top row takes 56 parts
                                    Expanded(
                                      flex: 56,
                                      child: Stack(
                                        children: [
                                          _buildSubtleBackground(),
                                          _buildPropertyTypesContent(),
                                          if (_showLeftGradient ||
                                              _showRightGradient)
                                            _buildEdgeIndicators(
                                              showLeft: _showLeftGradient,
                                              showRight: _showRightGradient,
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Unit row takes 48 parts
                                    Expanded(
                                      flex: 48,
                                      child: FadeTransition(
                                        opacity: _unitTypesFadeAnimation,
                                        child: SlideTransition(
                                          position: _unitTypesSlideAnimation,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  AppTheme.darkCard
                                                      .withOpacity(0.1),
                                                  AppTheme.darkCard
                                                      .withOpacity(0.05),
                                                ],
                                              ),
                                              border: Border(
                                                top: BorderSide(
                                                  color: AppTheme.primaryBlue
                                                      .withOpacity(0.03),
                                                  width: 0.5,
                                                ),
                                              ),
                                            ),
                                            child: Stack(
                                              children: [
                                                _buildUnitTypesContent(
                                                    unitTypes,
                                                    state as HomeLoaded),
                                                if (_showUnitLeftGradient ||
                                                    _showUnitRightGradient)
                                                  _buildEdgeIndicators(
                                                    showLeft:
                                                        _showUnitLeftGradient,
                                                    showRight:
                                                        _showUnitRightGradient,
                                                    isForUnits: true,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    // Only top row, fill all available height (55.5 on some devices)
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          _buildSubtleBackground(),
                                          _buildPropertyTypesContent(),
                                          if (_showLeftGradient ||
                                              _showRightGradient)
                                            _buildEdgeIndicators(
                                              showLeft: _showLeftGradient,
                                              showRight: _showRightGradient,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubtleBackground() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          return CustomPaint(
            painter: _SubtleWavePainter(
              animation: _shimmerController.value,
              color: AppTheme.primaryBlue.withOpacity(0.01),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPropertyTypesContent() {
    return Row(
      children: [
        // زر الكل
        _buildAllButton(),

        // فاصل
        Container(
          width: 0.5,
          height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          color: AppTheme.primaryBlue.withOpacity(0.08),
        ),

        // قائمة أنواع العقارات
        Expanded(
          child: ListView.builder(
            controller: _propertyScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding:
                const EdgeInsets.only(left: 4, right: 8, top: 10, bottom: 10),
            itemCount: widget.propertyTypes.length,
            itemBuilder: (context, index) {
              return _PremiumTypeChip(
                type: widget.propertyTypes[index],
                isSelected:
                    widget.selectedTypeId == widget.propertyTypes[index].id,
                isHovered: _hoveredPropertyIndex == index,
                hasUnits: _checkIfHasUnits(widget.propertyTypes[index].id),
                onTap: () =>
                    _handlePropertyTypeSelection(widget.propertyTypes[index]),
                onHover: (isHovered) {
                  setState(() {
                    _hoveredPropertyIndex = isHovered ? index : null;
                  });
                },
                animationDelay: Duration(milliseconds: index * 50),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUnitTypesContent(List<UnitType> unitTypes, HomeLoaded state) {
    return Row(
      children: [
        // مؤشر أنواع الوحدات
        Container(
          margin: const EdgeInsets.only(left: 12, right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryPurple.withOpacity(0.08),
                AppTheme.primaryCyan.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.primaryPurple.withOpacity(0.15),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryPurple.withOpacity(
                        0.5 + 0.3 * _pulseAnimation.value,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryPurple.withOpacity(
                            0.3 * _pulseAnimation.value,
                          ),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              Text(
                'الوحدات',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryPurple.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),

        // قائمة أنواع الوحدات
        Expanded(
          child: ListView.builder(
            controller: _unitScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            itemCount: unitTypes.length,
            itemBuilder: (context, index) {
              final unitType = unitTypes[index];
              final isSelected = state.selectedUnitTypeId == unitType.id;

              return _CompactUnitTypeChip(
                unitType: unitType,
                isSelected: isSelected,
                isHovered: _hoveredUnitIndex == index,
                onTap: () => _handleUnitTypeSelection(unitType.id),
                onHover: (isHovered) {
                  setState(() {
                    _hoveredUnitIndex = isHovered ? index : null;
                  });
                },
                animationDelay: Duration(milliseconds: index * 30),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAllButton() {
    final isSelected = widget.selectedTypeId == null;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTypeSelected(null);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(left: 10, right: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.12),
                    AppTheme.primaryPurple.withOpacity(0.08),
                  ],
                )
              : null,
          color: !isSelected ? AppTheme.darkCard.withOpacity(0.2) : null,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlue.withOpacity(0.25)
                : AppTheme.darkBorder.withOpacity(0.08),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.grid_view_rounded,
              size: 13,
              color: isSelected
                  ? AppTheme.primaryBlue.withOpacity(0.9)
                  : AppTheme.textMuted.withOpacity(0.5),
            ),
            const SizedBox(width: 5),
            Text(
              'الكل',
              style: AppTextStyles.caption.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppTheme.primaryBlue.withOpacity(0.9)
                    : AppTheme.textMuted.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEdgeIndicators({
    required bool showLeft,
    required bool showRight,
    bool isForUnits = false,
  }) {
    return IgnorePointer(
      child: Row(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: showLeft ? 1.0 : 0.0,
            child: Container(
              width: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkBackground.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 14,
                color: isForUnits
                    ? AppTheme.primaryPurple.withOpacity(0.4)
                    : AppTheme.primaryBlue.withOpacity(0.4),
              ),
            ),
          ),
          const Spacer(),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: showRight ? 1.0 : 0.0,
            child: Container(
              width: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppTheme.darkBackground.withOpacity(0.15),
                  ],
                ),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: isForUnits
                    ? AppTheme.primaryPurple.withOpacity(0.4)
                    : AppTheme.primaryBlue.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _checkIfHasUnits(String propertyTypeId) {
    final state = context.read<HomeBloc>().state;
    if (state is HomeLoaded) {
      final units = state.unitTypes[propertyTypeId];
      return units != null && units.isNotEmpty;
    }
    return false;
  }

  void _handlePropertyTypeSelection(PropertyType type) {
    HapticFeedback.selectionClick();
    if (widget.selectedTypeId == type.id) {
      widget.onTypeSelected(null);
    } else {
      widget.onTypeSelected(type.id);
    }
  }

  void _handleUnitTypeSelection(String unitTypeId) {
    HapticFeedback.lightImpact();
    context.read<HomeBloc>().add(
          UpdateUnitTypeSelectionEvent(unitTypeId: unitTypeId),
        );
  }
}

// Widget محسّن لشريحة نوع العقار
class _PremiumTypeChip extends StatefulWidget {
  final PropertyType type;
  final bool isSelected;
  final bool isHovered;
  final bool hasUnits;
  final VoidCallback onTap;
  final Function(bool) onHover;
  final Duration animationDelay;

  const _PremiumTypeChip({
    required this.type,
    required this.isSelected,
    required this.isHovered,
    required this.hasUnits,
    required this.onTap,
    required this.onHover,
    this.animationDelay = Duration.zero,
  });

  @override
  State<_PremiumTypeChip> createState() => _PremiumTypeChipState();
}

class _PremiumTypeChipState extends State<_PremiumTypeChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    if (widget.isSelected) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_PremiumTypeChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _glowController.repeat(reverse: true);
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _glowController.stop();
      _glowController.reset();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration:
          Duration(milliseconds: 400 + widget.animationDelay.inMilliseconds),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + 0.2 * value,
          child: Opacity(
            opacity: value < 0 ? 0 : (value > 1 ? 1 : value),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: widget.onTap,
              child: MouseRegion(
                onEnter: (_) => widget.onHover(true),
                onExit: (_) => widget.onHover(false),
                child: AnimatedScale(
                  scale: _isPressed ? 0.95 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: widget.isSelected
                          ? LinearGradient(
                              colors: [
                                AppTheme.primaryBlue.withOpacity(0.12),
                                AppTheme.primaryPurple.withOpacity(0.08),
                              ],
                            )
                          : null,
                      color: !widget.isSelected
                          ? widget.isHovered
                              ? AppTheme.darkCard.withOpacity(0.3)
                              : AppTheme.darkCard.withOpacity(0.2)
                          : null,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: widget.isSelected
                            ? AppTheme.primaryBlue.withOpacity(
                                0.25 + 0.15 * _glowAnimation.value,
                              )
                            : AppTheme.darkBorder.withOpacity(0.08),
                        width: 0.5,
                      ),
                      boxShadow: widget.isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withOpacity(
                                  0.08 * _glowAnimation.value,
                                ),
                                blurRadius: 6,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildIcon(),
                        const SizedBox(width: 5),
                        _buildText(),
                        if (widget.type.count > 0) _buildCount(),
                        if (widget.hasUnits && widget.isSelected)
                          _buildExpandIndicator(),
                      ],
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

  Widget _buildIcon() {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: widget.isSelected
            ? AppTheme.primaryBlue.withOpacity(0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Icon(
        _getIconForType(widget.type.icon),
        size: 13,
        color: widget.isSelected
            ? AppTheme.primaryBlue.withOpacity(0.9)
            : AppTheme.textMuted.withOpacity(0.5),
      ),
    );
  }

  Widget _buildText() {
    return Text(
      widget.type.name,
      style: AppTextStyles.caption.copyWith(
        fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
        color: widget.isSelected
            ? AppTheme.primaryBlue.withOpacity(0.9)
            : AppTheme.textLight.withOpacity(0.7),
        fontSize: 11,
      ),
    );
  }

  Widget _buildCount() {
    return Container(
      margin: const EdgeInsets.only(left: 5),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: widget.isSelected
            ? AppTheme.primaryBlue.withOpacity(0.12)
            : AppTheme.darkSurface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        '${widget.type.count}',
        style: AppTextStyles.caption.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: widget.isSelected
              ? AppTheme.primaryBlue.withOpacity(0.8)
              : AppTheme.textMuted.withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildExpandIndicator() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(left: 4),
          child: Icon(
            Icons.expand_more_rounded,
            size: 14,
            color: AppTheme.primaryPurple.withOpacity(
              0.5 + 0.3 * _glowAnimation.value,
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForType(String? icon) {
    if (icon == null) return Icons.home_outlined;

    final iconMap = {
      'apartment': Icons.apartment_rounded,
      'villa': Icons.villa_rounded,
      'hotel': Icons.hotel_rounded,
      'house': Icons.house_rounded,
      'cabin': Icons.cabin_rounded,
      'cottage': Icons.cottage_rounded,
      'resort': Icons.pool_rounded,
      'chalet': Icons.chalet_rounded,
      'farm': Icons.agriculture_rounded,
      'tent': Icons.festival_rounded,
    };

    return iconMap[icon] ?? Icons.home_outlined;
  }
}

// Widget مضغوط لنوع الوحدة
class _CompactUnitTypeChip extends StatefulWidget {
  final UnitType unitType;
  final bool isSelected;
  final bool isHovered;
  final VoidCallback onTap;
  final Function(bool) onHover;
  final Duration animationDelay;

  const _CompactUnitTypeChip({
    required this.unitType,
    required this.isSelected,
    required this.isHovered,
    required this.onTap,
    required this.onHover,
    this.animationDelay = Duration.zero,
  });

  @override
  State<_CompactUnitTypeChip> createState() => _CompactUnitTypeChipState();
}

class _CompactUnitTypeChipState extends State<_CompactUnitTypeChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _selectionController;
  late Animation<double> _selectionAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _selectionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _selectionController,
      curve: Curves.easeInOut,
    ));

    if (widget.isSelected) {
      _selectionController.forward();
    }
  }

  @override
  void didUpdateWidget(_CompactUnitTypeChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _selectionController.forward();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _selectionController.reverse();
    }
  }

  @override
  void dispose() {
    _selectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration:
          Duration(milliseconds: 300 + widget.animationDelay.inMilliseconds),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + 0.1 * value,
          child: Opacity(
            opacity: value < 0 ? 0 : (value > 1 ? 1 : value),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: widget.onTap,
              child: MouseRegion(
                onEnter: (_) => widget.onHover(true),
                onExit: (_) => widget.onHover(false),
                child: AnimatedScale(
                  scale: _isPressed ? 0.92 : 1.0,
                  duration: const Duration(milliseconds: 120),
                  child: AnimatedBuilder(
                    animation: _selectionAnimation,
                    builder: (context, child) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: widget.isSelected
                              ? LinearGradient(
                                  colors: [
                                    AppTheme.primaryPurple.withOpacity(0.15),
                                    AppTheme.primaryCyan.withOpacity(0.10),
                                  ],
                                )
                              : null,
                          color: !widget.isSelected
                              ? widget.isHovered
                                  ? AppTheme.darkCard.withOpacity(0.25)
                                  : AppTheme.darkCard.withOpacity(0.15)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.isSelected
                                ? AppTheme.primaryPurple.withOpacity(
                                    0.3 + 0.2 * _selectionAnimation.value,
                                  )
                                : AppTheme.darkBorder.withOpacity(0.06),
                            width: widget.isSelected ? 1 : 0.5,
                          ),
                          boxShadow: widget.isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryPurple.withOpacity(
                                      0.1 * _selectionAnimation.value,
                                    ),
                                    blurRadius: 8,
                                    spreadRadius: -2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getIconForUnitType(widget.unitType.icon),
                              size: 12,
                              color: widget.isSelected
                                  ? AppTheme.primaryPurple.withOpacity(0.9)
                                  : AppTheme.textMuted.withOpacity(0.4),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.unitType.name,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                                fontWeight: widget.isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: widget.isSelected
                                    ? AppTheme.primaryPurple.withOpacity(0.9)
                                    : AppTheme.textLight.withOpacity(0.6),
                              ),
                            ),
                            if (widget.isSelected)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primaryCyan.withOpacity(
                                    0.7 + 0.3 * _selectionAnimation.value,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryCyan.withOpacity(
                                        0.4 * _selectionAnimation.value,
                                      ),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForUnitType(String? iconName) {
    if (iconName == null || iconName.isEmpty) {
      return Icons.bed_rounded;
    }

    final iconMap = <String, IconData>{
      'bed': Icons.bed_rounded,
      'king_bed': Icons.king_bed_rounded,
      'single_bed': Icons.single_bed_rounded,
      'bedroom_parent': Icons.bedroom_parent_rounded,
      'bedroom_child': Icons.bedroom_child_rounded,
      'living_room': Icons.living_rounded,
      'dining_room': Icons.dining_rounded,
      'kitchen': Icons.kitchen_rounded,
      'bathroom': Icons.bathroom_rounded,
      'bathtub': Icons.bathtub_rounded,
      'shower': Icons.shower_rounded,
      'garage': Icons.garage_rounded,
      'balcony': Icons.balcony_rounded,
      'deck': Icons.deck_rounded,
      'yard': Icons.yard_rounded,
      'studio': Icons.weekend_rounded,
      'suite': Icons.meeting_room_rounded,
      'pool': Icons.pool_rounded,
      'wifi': Icons.wifi_rounded,
      'ac_unit': Icons.ac_unit_rounded,
    };

    return iconMap[iconName] ?? Icons.bed_rounded;
  }
}

// Subtle Wave Painter
class _SubtleWavePainter extends CustomPainter {
  final double animation;
  final Color color;

  _SubtleWavePainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x += 10) {
      final y = size.height * 0.8 +
          math.sin((x / size.width * 2 * math.pi) + (animation * 2 * math.pi)) *
              2;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
