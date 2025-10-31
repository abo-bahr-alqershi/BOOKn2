// lib/features/admin_properties/presentation/widgets/property_policies_list.dart

import 'package:bookn_cp_app/features/admin_properties/domain/entities/policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/policy.dart' as domain;
import '../../../../core/widgets/policy_identity_card_tooltip.dart';

class PropertyPoliciesList extends StatefulWidget {
  final List<domain.Policy> policies;
  final bool isReadOnly;

  const PropertyPoliciesList({
    super.key,
    required this.policies,
    this.isReadOnly = true,
  });

  @override
  State<PropertyPoliciesList> createState() => _PropertyPoliciesListState();
}

class _PropertyPoliciesListState extends State<PropertyPoliciesList>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int? _expandedIndex;
  int? _hoveredIndex;
  String? _pressedPolicyId;
  final Map<String, GlobalKey> _policyKeys = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  GlobalKey _getPolicyKey(String policyId) {
    if (!_policyKeys.containsKey(policyId)) {
      _policyKeys[policyId] = GlobalKey();
    }
    return _policyKeys[policyId]!;
  }

  void _showPolicyCard(domain.Policy policy) {
    setState(() => _pressedPolicyId = policy.id);

    HapticFeedback.mediumImpact();

    PolicyIdentityCardTooltip.show(
      context: context,
      targetKey: _getPolicyKey(policy.id),
      policyId: policy.id,
      policyType: policy.policyType,
      description: policy.description,
      rules: policy.rules,
      isActive: policy.isActive,
      effectiveDate: policy.effectiveDate,
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _pressedPolicyId = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.policies.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.all(4),
          itemCount: widget.policies.length,
          itemBuilder: (context, index) {
            final policy = widget.policies[index];
            final delay = index * 0.1;

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.2, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    delay,
                    delay + 0.5,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
              child: FadeTransition(
                opacity: Tween<double>(
                  begin: 0,
                  end: 1,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      delay,
                      delay + 0.5,
                      curve: Curves.easeOut,
                    ),
                  ),
                ),
                child: _buildPolicyCard(policy, index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.1),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.doc_text,
              size: 48,
              color: AppTheme.textMuted.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد سياسات مضافة',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'يجب إضافة سياسات العقار',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyCard(domain.Policy policy, int index) {
    final isExpanded = _expandedIndex == index;
    final isHovered = _hoveredIndex == index;
    final policyConfig = _getPolicyConfig(policy.policyType);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        key: _getPolicyKey(policy.id),
        onLongPress: () => _showPolicyCard(policy),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isHovered || isExpanded
                  ? policyConfig.gradient
                      .map((c) => c.withValues(alpha: 0.1))
                      .toList()
                  : [
                      AppTheme.darkCard.withValues(alpha: 0.3),
                      AppTheme.darkCard.withValues(alpha: 0.2),
                    ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _pressedPolicyId == policy.id
                  ? policyConfig.gradient.first.withValues(alpha: 0.6)
                  : isHovered || isExpanded
                      ? policyConfig.gradient.first.withValues(alpha: 0.3)
                      : AppTheme.darkBorder.withValues(alpha: 0.2),
              width: _pressedPolicyId == policy.id || isExpanded ? 1.5 : 1,
            ),
            boxShadow: isHovered || isExpanded
                ? [
                    BoxShadow(
                      color:
                          policyConfig.gradient.first.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: isHovered ? 15 : 10,
                sigmaY: isHovered ? 15 : 10,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _expandedIndex = isExpanded ? null : index;
                    });
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Header Row
                        Row(
                          children: [
                            // Icon Container
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: isExpanded
                                    ? LinearGradient(
                                        colors: policyConfig.gradient)
                                    : null,
                                color: isExpanded
                                    ? null
                                    : policyConfig.gradient.first
                                        .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: policyConfig.gradient.first
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              child: Icon(
                                policyConfig.icon,
                                size: 20,
                                color: isExpanded
                                    ? Colors.white
                                    : policyConfig.gradient.first,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Title & Subtitle
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    policy.policyTypeLabel,
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: AppTheme.textWhite,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    policy.policyType.name,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppTheme.textMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            // Expand Icon
                            AnimatedRotation(
                              duration: const Duration(milliseconds: 200),
                              turns: isExpanded ? 0.5 : 0,
                              child: Icon(
                                CupertinoIcons.chevron_down,
                                size: 18,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),

                        // Expandable Content
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppTheme.darkBorder
                                          .withValues(alpha: 0.2),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Policy Details
                              Text(
                                policy.description,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppTheme.textLight,
                                  height: 1.5,
                                ),
                              ),

                              // Policy Rules (if any)
                              if (policy.rules.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                ...policy.rules
                                    .split('\n')
                                    .map((rule) => _buildRuleItem(rule)),
                              ],

                              // No additional info in domain model
                            ],
                          ),
                          crossFadeState: isExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 200),
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
  }

  Widget _buildRuleItem(String rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              rule,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _PolicyConfig _getPolicyConfig(domain.PolicyType type) {
    switch (type) {
      case PolicyType.cancellation:
        return _PolicyConfig(
          icon: CupertinoIcons.xmark_circle_fill,
          gradient: [AppTheme.warning, AppTheme.neonPurple],
        );
      case PolicyType.checkIn:
        return _PolicyConfig(
          icon: CupertinoIcons.arrow_down_circle_fill,
          gradient: [AppTheme.success, AppTheme.neonGreen],
        );
      case PolicyType.checkOut:
        return _PolicyConfig(
          icon: CupertinoIcons.arrow_up_circle_fill,
          gradient: [AppTheme.info, AppTheme.neonBlue],
        );
      case PolicyType.pets:
        return _PolicyConfig(
          icon: CupertinoIcons.paw,
          gradient: [AppTheme.primaryPurple, AppTheme.primaryViolet],
        );
      case PolicyType.smoking:
        return _PolicyConfig(
          icon: CupertinoIcons.smoke_fill,
          gradient: [AppTheme.error, AppTheme.primaryViolet],
        );
      case PolicyType.payment:
        return _PolicyConfig(
          icon: CupertinoIcons.creditcard_fill,
          gradient: [AppTheme.primaryBlue, AppTheme.primaryCyan],
        );
      case PolicyType.damage:
        return _PolicyConfig(
          icon: CupertinoIcons.exclamationmark_triangle_fill,
          gradient: [AppTheme.error, AppTheme.warning],
        );
      case PolicyType.other:
      default:
        return _PolicyConfig(
          icon: CupertinoIcons.doc_text_fill,
          gradient: [AppTheme.primaryBlue, AppTheme.primaryPurple],
        );
    }
  }
}

// Helper Classes
class _PolicyConfig {
  final IconData icon;
  final List<Color> gradient;

  const _PolicyConfig({
    required this.icon,
    required this.gradient,
  });
}
