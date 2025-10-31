// lib/features/admin_policies/presentation/widgets/futuristic_policies_table.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/policy_identity_card_tooltip.dart';
import '../../../admin_properties/domain/entities/policy.dart'
    as property_policy;
import '../../domain/entities/policy.dart';

class FuturisticPoliciesTable extends StatefulWidget {
  final List<Policy> policies;
  final List<Policy> selectedPolicies;
  final Function(String) onPolicyTap;
  final Function(List<Policy>) onSelectionChanged;
  final bool showActions;
  final void Function(Policy)? onEdit;
  final void Function(Policy)? onDelete;
  final void Function(Policy)? onToggleStatus;
  final void Function(Policy)? onDuplicate;
  final void Function(Policy)? onViewDetails;

  const FuturisticPoliciesTable({
    super.key,
    required this.policies,
    this.selectedPolicies = const [],
    required this.onPolicyTap,
    required this.onSelectionChanged,
    this.showActions = true,
    this.onEdit,
    this.onDelete,
    this.onToggleStatus,
    this.onDuplicate,
    this.onViewDetails,
  });

  @override
  State<FuturisticPoliciesTable> createState() =>
      _FuturisticPoliciesTableState();
}

class _FuturisticPoliciesTableState extends State<FuturisticPoliciesTable>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _fadeInController;

  // State
  int? _hoveredIndex;
  final Set<String> _expandedPolicies = {};
  final Map<String, GlobalKey> _policyRowKeys = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeInController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    _fadeInController.dispose();
    super.dispose();
  }

  GlobalKey _getPolicyRowKey(String policyId, {String scope = 'desktop'}) {
    final cacheKey = scope.isEmpty ? policyId : '$policyId-$scope';
    return _policyRowKeys.putIfAbsent(cacheKey, () => GlobalKey());
  }

  property_policy.PolicyType _mapPolicyType(PolicyType type) {
    switch (type) {
      case PolicyType.cancellation:
        return property_policy.PolicyType.cancellation;
      case PolicyType.checkIn:
        return property_policy.PolicyType.checkIn;
      case PolicyType.children:
        return property_policy.PolicyType.other;
      case PolicyType.pets:
        return property_policy.PolicyType.pets;
      case PolicyType.payment:
        return property_policy.PolicyType.payment;
      case PolicyType.modification:
        return property_policy.PolicyType.other;
    }
  }

  void _showPolicyTooltip(Policy policy, {String scope = 'desktop'}) {
    final targetKey = _getPolicyRowKey(policy.id, scope: scope);
    PolicyIdentityCardTooltip.show(
      context: context,
      targetKey: targetKey,
      policyId: policy.id,
      policyType: _mapPolicyType(policy.type),
      description: policy.description,
      rules: policy.rules,
      isActive: policy.isActive ?? true,
      propertyName: policy.propertyName,
      effectiveDate: policy.createdAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.policies.isEmpty) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth < 900;

        if (isMobile) {
          return _buildMobileView();
        } else if (isTablet) {
          return _buildTabletView();
        } else {
          return _buildDesktopView();
        }
      },
    );
  }

  Widget _buildMobileView() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.policies.length,
      itemBuilder: (context, index) {
        final policy = widget.policies[index];
        final isSelected = widget.selectedPolicies.contains(policy);
        final isExpanded = _expandedPolicies.contains(policy.id);

        return AnimatedBuilder(
          animation: _fadeInController,
          builder: (context, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: _fadeInController,
                curve: Interval(
                  index * 0.1,
                  1.0,
                  curve: Curves.easeOut,
                ),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _fadeInController,
                  curve: Interval(
                    index * 0.1,
                    1.0,
                    curve: Curves.easeOutQuart,
                  ),
                )),
                child: _buildMobilePolicyCard(policy, isSelected, isExpanded),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabletView() {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.8,
      ),
      itemCount: widget.policies.length,
      itemBuilder: (context, index) {
        final policy = widget.policies[index];
        final isSelected = widget.selectedPolicies.contains(policy);

        return AnimatedBuilder(
          animation: _fadeInController,
          builder: (context, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: _fadeInController,
                curve: Interval(
                  index * 0.05,
                  1.0,
                  curve: Curves.easeOut,
                ),
              ),
              child: Transform.scale(
                scale: 0.95 + (0.05 * _fadeInController.value),
                child: _buildTabletPolicyCard(policy, isSelected),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDesktopView() {
    return Column(
      children: widget.policies.asMap().entries.map((entry) {
        final index = entry.key;
        final policy = entry.value;
        final isSelected = widget.selectedPolicies.contains(policy);
        final isHovered = _hoveredIndex == index;

        return AnimatedBuilder(
          animation: _fadeInController,
          builder: (context, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: _fadeInController,
                curve: Interval(
                  index * 0.05,
                  1.0,
                  curve: Curves.easeOut,
                ),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-0.05, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _fadeInController,
                  curve: Interval(
                    index * 0.05,
                    1.0,
                    curve: Curves.easeOutQuart,
                  ),
                )),
                child: _buildDesktopPolicyCard(
                    policy, isSelected, isHovered, index),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildMobilePolicyCard(
      Policy policy, bool isSelected, bool isExpanded) {
    return GestureDetector(
      key: _getPolicyRowKey(policy.id, scope: 'mobile'),
      onTap: () {
        HapticFeedback.lightImpact();
        _showPolicyTooltip(policy, scope: 'mobile');
        widget.onPolicyTap(policy.id);
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showPolicyTooltip(policy, scope: 'mobile');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [
                    _getPolicyTypeColor(policy.type).withOpacity(0.15),
                    _getPolicyTypeColor(policy.type).withOpacity(0.05),
                  ]
                : [
                    AppTheme.darkCard.withOpacity(0.6),
                    AppTheme.darkCard.withOpacity(0.4),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? _getPolicyTypeColor(policy.type).withOpacity(0.4)
                : AppTheme.darkBorder.withOpacity(0.15),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _getPolicyTypeColor(policy.type).withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
              blurRadius: isSelected ? 20 : 10,
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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          // Animated Type Icon
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _getPolicyTypeColor(policy.type)
                                          .withOpacity(0.3 +
                                              _pulseController.value * 0.1),
                                      _getPolicyTypeColor(policy.type)
                                          .withOpacity(0.15 +
                                              _pulseController.value * 0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getPolicyTypeColor(policy.type)
                                          .withOpacity(
                                              0.3 * _pulseController.value),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _getPolicyTypeIcon(policy.type),
                                  color: _getPolicyTypeColor(policy.type),
                                  size: 20,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),

                          // Type and Status
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  policy.type.displayName,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppTheme.textWhite,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _buildStatusBadge(policy.isActive ?? true),
                                    if (policy.propertyName != null) ...[
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          policy.propertyName!,
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppTheme.textMuted,
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Selection
                          if (widget.selectedPolicies.isNotEmpty || isSelected)
                            Checkbox(
                              value: isSelected,
                              onChanged: (value) {
                                final updatedSelection = [
                                  ...widget.selectedPolicies
                                ];
                                if (value!) {
                                  updatedSelection.add(policy);
                                } else {
                                  updatedSelection.remove(policy);
                                }
                                widget.onSelectionChanged(updatedSelection);
                              },
                              activeColor: _getPolicyTypeColor(policy.type),
                              checkColor: Colors.white,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                        ],
                      ),

                      // Description
                      const SizedBox(height: 12),
                      Text(
                        policy.description,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.textLight,
                          height: 1.4,
                        ),
                        maxLines: isExpanded ? null : 2,
                        overflow: isExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                      ),

                      // Expand Button
                      if (policy.description.length > 100)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedPolicies.remove(policy.id);
                              } else {
                                _expandedPolicies.add(policy.id);
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              isExpanded ? 'عرض أقل' : 'عرض المزيد',
                              style: AppTextStyles.caption.copyWith(
                                color: _getPolicyTypeColor(policy.type),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                      // Details when expanded
                      if (isExpanded) ...[
                        const SizedBox(height: 12),
                        _buildPolicyDetailsSection(policy),
                      ],
                    ],
                  ),
                ),

                // Actions Bar
                if (widget.showActions)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.darkBackground.withOpacity(0.5),
                          AppTheme.darkBackground.withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildActionButton(
                          icon: CupertinoIcons.eye,
                          onTap: () => widget.onViewDetails?.call(policy),
                          color: AppTheme.primaryBlue,
                        ),
                        _buildActionButton(
                          icon: CupertinoIcons.pencil,
                          onTap: () => widget.onEdit?.call(policy),
                          color: AppTheme.primaryPurple,
                        ),
                        _buildActionButton(
                          icon: policy.isActive ?? true
                              ? CupertinoIcons.pause_circle
                              : CupertinoIcons.play_circle,
                          onTap: () => widget.onToggleStatus?.call(policy),
                          color: AppTheme.warning,
                        ),
                        _buildActionButton(
                          icon: CupertinoIcons.trash,
                          onTap: () => widget.onDelete?.call(policy),
                          color: AppTheme.error,
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
  }

  Widget _buildTabletPolicyCard(Policy policy, bool isSelected) {
    return GestureDetector(
      key: _getPolicyRowKey(policy.id, scope: 'tablet'),
      onTap: () {
        HapticFeedback.lightImpact();
        _showPolicyTooltip(policy, scope: 'tablet');
        widget.onPolicyTap(policy.id);
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showPolicyTooltip(policy, scope: 'tablet');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [
                    _getPolicyTypeColor(policy.type).withOpacity(0.15),
                    _getPolicyTypeColor(policy.type).withOpacity(0.05),
                  ]
                : [
                    AppTheme.darkCard.withOpacity(0.6),
                    AppTheme.darkCard.withOpacity(0.4),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? _getPolicyTypeColor(policy.type).withOpacity(0.4)
                : AppTheme.darkBorder.withOpacity(0.15),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _getPolicyTypeColor(policy.type).withOpacity(0.15)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
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
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getPolicyTypeColor(policy.type).withOpacity(0.3),
                              _getPolicyTypeColor(policy.type)
                                  .withOpacity(0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getPolicyTypeIcon(policy.type),
                          color: _getPolicyTypeColor(policy.type),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              policy.type.displayName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: _getPolicyTypeColor(policy.type),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            _buildStatusBadge(policy.isActive ?? true),
                          ],
                        ),
                      ),
                      if (widget.showActions)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildActionButton(
                              icon: CupertinoIcons.pencil,
                              onTap: () => widget.onEdit?.call(policy),
                              color: AppTheme.primaryPurple,
                              size: 14,
                            ),
                            _buildActionButton(
                              icon: CupertinoIcons.ellipsis,
                              onTap: () => _showActionsMenu(policy),
                              color: AppTheme.textMuted,
                              size: 14,
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Description
                  Expanded(
                    child: Text(
                      policy.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.textLight,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Footer
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.building_2_fill,
                        size: 12,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          policy.propertyName ?? 'جميع العقارات',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textMuted,
                            fontSize: 11,
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
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopPolicyCard(
    Policy policy,
    bool isSelected,
    bool isHovered,
    int index,
  ) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        key: _getPolicyRowKey(policy.id, scope: 'desktop'),
        onTap: () {
          HapticFeedback.lightImpact();
          _showPolicyTooltip(policy, scope: 'desktop');
          widget.onPolicyTap(policy.id);
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showPolicyTooltip(policy, scope: 'desktop');
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isHovered
                  ? [
                      _getPolicyTypeColor(policy.type).withOpacity(0.12),
                      _getPolicyTypeColor(policy.type).withOpacity(0.05),
                    ]
                  : isSelected
                      ? [
                          _getPolicyTypeColor(policy.type).withOpacity(0.08),
                          _getPolicyTypeColor(policy.type).withOpacity(0.03),
                        ]
                      : [
                          AppTheme.darkCard.withOpacity(0.5),
                          AppTheme.darkCard.withOpacity(0.3),
                        ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered
                  ? _getPolicyTypeColor(policy.type).withOpacity(0.3)
                  : isSelected
                      ? _getPolicyTypeColor(policy.type).withOpacity(0.2)
                      : AppTheme.darkBorder.withOpacity(0.1),
              width: isHovered ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered
                    ? _getPolicyTypeColor(policy.type).withOpacity(0.15)
                    : Colors.black.withOpacity(0.05),
                blurRadius: isHovered ? 20 : 10,
                offset: Offset(0, isHovered ? 6 : 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Checkbox
              if (widget.selectedPolicies.isNotEmpty || isSelected)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Transform.scale(
                    scale: isHovered ? 1.1 : 1.0,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        final updatedSelection = [...widget.selectedPolicies];
                        if (value!) {
                          updatedSelection.add(policy);
                        } else {
                          updatedSelection.remove(policy);
                        }
                        widget.onSelectionChanged(updatedSelection);
                      },
                      activeColor: _getPolicyTypeColor(policy.type),
                      checkColor: Colors.white,
                    ),
                  ),
                ),

              // Type Icon and Name
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getPolicyTypeColor(policy.type)
                          .withOpacity(isHovered ? 0.35 : 0.25),
                      _getPolicyTypeColor(policy.type)
                          .withOpacity(isHovered ? 0.2 : 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isHovered
                      ? [
                          BoxShadow(
                            color: _getPolicyTypeColor(policy.type)
                                .withOpacity(0.3),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  _getPolicyTypeIcon(policy.type),
                  color: _getPolicyTypeColor(policy.type),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),

              // Type Name
              SizedBox(
                width: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      policy.type.displayName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _getPolicyTypeColor(policy.type),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _buildStatusBadge(policy.isActive ?? true),
                  ],
                ),
              ),

              // Description
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    policy.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textLight,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // Property
              SizedBox(
                width: 180,
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryViolet.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        CupertinoIcons.building_2_fill,
                        size: 14,
                        color: AppTheme.primaryViolet,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        policy.propertyName ?? 'جميع العقارات',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.textWhite,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Details
              SizedBox(
                width: 200,
                child: _buildPolicyQuickDetails(policy),
              ),

              // Actions
              if (widget.showActions)
                SizedBox(
                  width: 180,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildActionButton(
                        icon: CupertinoIcons.eye,
                        onTap: () => widget.onViewDetails?.call(policy),
                        tooltip: 'عرض',
                        color: AppTheme.primaryBlue,
                      ),
                      _buildActionButton(
                        icon: CupertinoIcons.pencil,
                        onTap: () => widget.onEdit?.call(policy),
                        tooltip: 'تعديل',
                        color: AppTheme.primaryPurple,
                      ),
                      _buildActionButton(
                        icon: CupertinoIcons.doc_on_doc,
                        onTap: () => widget.onDuplicate?.call(policy),
                        tooltip: 'نسخ',
                        color: AppTheme.success,
                      ),
                      _buildActionButton(
                        icon: CupertinoIcons.trash,
                        onTap: () => widget.onDelete?.call(policy),
                        tooltip: 'حذف',
                        color: AppTheme.error,
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

  Widget _buildPolicyQuickDetails(Policy policy) {
    final details = _getPolicyDetails(policy);

    if (details.isEmpty) {
      return Text(
        'لا توجد تفاصيل',
        style: AppTextStyles.caption.copyWith(
          color: AppTheme.textMuted,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: details.entries.take(2).map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.darkBackground.withOpacity(0.4),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${entry.key}:',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                entry.value.toString(),
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPolicyDetailsSection(Policy policy) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (policy.rules.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  CupertinoIcons.doc_text,
                  size: 14,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  'القواعد',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.darkCard.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                policy.rules,
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textLight,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _getPolicyDetails(policy).entries.map((entry) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getPolicyTypeColor(policy.type).withOpacity(0.15),
                      _getPolicyTypeColor(policy.type).withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getPolicyTypeColor(policy.type).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.key,
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entry.value.toString(),
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getPolicyDetails(Policy policy) {
    final details = <String, dynamic>{};

    switch (policy.type) {
      case PolicyType.cancellation:
        details['نافذة الإلغاء'] = '${policy.cancellationWindowDays} يوم';
        break;
      case PolicyType.payment:
        if (policy.requireFullPaymentBeforeConfirmation == true) {
          details['دفع كامل'] = 'مطلوب';
        }
        details['عربون'] = '${policy.minimumDepositPercentage}%';
        break;
      case PolicyType.checkIn:
      case PolicyType.modification:
        details['مدة مسبقة'] = '${policy.minHoursBeforeCheckIn}س';
        break;
      default:
        break;
    }

    return details;
  }

  Widget _buildStatusBadge(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [
                  AppTheme.success.withOpacity(0.2),
                  AppTheme.success.withOpacity(0.1),
                ]
              : [
                  AppTheme.textMuted.withOpacity(0.2),
                  AppTheme.textMuted.withOpacity(0.1),
                ],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive
              ? AppTheme.success.withOpacity(0.3)
              : AppTheme.textMuted.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.success : AppTheme.textMuted,
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppTheme.success.withOpacity(0.6),
                        blurRadius: 4,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'نشط' : 'غير نشط',
            style: AppTextStyles.caption.copyWith(
              color: isActive ? AppTheme.success : AppTheme.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    VoidCallback? onTap,
    required Color color,
    double size = 16,
    String? tooltip,
  }) {
    final widget = GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: EdgeInsets.all(size == 14 ? 6 : 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          size: size,
          color: color,
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        child: widget,
      );
    }

    return widget;
  }

  void _showActionsMenu(Policy policy) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.darkCard,
              AppTheme.darkCard.withOpacity(0.95),
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.darkBorder.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildSheetAction(
                icon: CupertinoIcons.eye,
                label: 'عرض التفاصيل',
                onTap: () {
                  Navigator.pop(context);
                  widget.onViewDetails?.call(policy);
                },
                color: AppTheme.primaryBlue,
              ),
              _buildSheetAction(
                icon: CupertinoIcons.pencil,
                label: 'تعديل السياسة',
                onTap: () {
                  Navigator.pop(context);
                  widget.onEdit?.call(policy);
                },
                color: AppTheme.primaryPurple,
              ),
              _buildSheetAction(
                icon: policy.isActive ?? true
                    ? CupertinoIcons.pause_circle
                    : CupertinoIcons.play_circle,
                label:
                    policy.isActive ?? true ? 'إيقاف السياسة' : 'تفعيل السياسة',
                onTap: () {
                  Navigator.pop(context);
                  widget.onToggleStatus?.call(policy);
                },
                color: AppTheme.warning,
              ),
              _buildSheetAction(
                icon: CupertinoIcons.doc_on_doc,
                label: 'نسخ السياسة',
                onTap: () {
                  Navigator.pop(context);
                  widget.onDuplicate?.call(policy);
                },
                color: AppTheme.success,
              ),
              Divider(
                color: AppTheme.darkBorder.withOpacity(0.2),
                height: 1,
              ),
              _buildSheetAction(
                icon: CupertinoIcons.trash,
                label: 'حذف السياسة',
                onTap: () {
                  Navigator.pop(context);
                  widget.onDelete?.call(policy);
                },
                color: AppTheme.error,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetAction({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppTheme.textWhite,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryPurple
                          .withOpacity(0.2 + _pulseController.value * 0.1),
                      AppTheme.primaryViolet
                          .withOpacity(0.1 + _pulseController.value * 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPurple
                          .withOpacity(0.2 * _pulseController.value),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.policy_outlined,
                  size: 48,
                  color: AppTheme.primaryPurple,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                AppTheme.primaryPurple,
                AppTheme.primaryViolet,
              ],
            ).createShader(bounds),
            child: Text(
              'لا توجد سياسات',
              style: AppTextStyles.heading3.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم يتم العثور على أي سياسات في النظام',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPolicyTypeColor(PolicyType type) {
    switch (type) {
      case PolicyType.cancellation:
        return AppTheme.error;
      case PolicyType.checkIn:
        return AppTheme.primaryBlue;
      case PolicyType.children:
        return AppTheme.warning;
      case PolicyType.pets:
        return AppTheme.primaryViolet;
      case PolicyType.payment:
        return AppTheme.success;
      case PolicyType.modification:
        return AppTheme.primaryPurple;
    }
  }

  IconData _getPolicyTypeIcon(PolicyType type) {
    switch (type) {
      case PolicyType.cancellation:
        return CupertinoIcons.xmark_circle_fill;
      case PolicyType.checkIn:
        return CupertinoIcons.arrow_right_square_fill;
      case PolicyType.children:
        return CupertinoIcons.person_2_fill;
      case PolicyType.pets:
        return CupertinoIcons.paw;
      case PolicyType.payment:
        return CupertinoIcons.money_dollar_circle_fill;
      case PolicyType.modification:
        return CupertinoIcons.pencil_circle_fill;
    }
  }
}
