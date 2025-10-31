// lib/features/property/presentation/widgets/policies_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:yemen_booking_app/features/property/domain/entities/property_policy.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class PoliciesWidget extends StatefulWidget {
  final List<PropertyPolicy> policies;

  const PoliciesWidget({
    super.key,
    required this.policies,
  });

  @override
  State<PoliciesWidget> createState() => _PoliciesWidgetState();
}

class _PoliciesWidgetState extends State<PoliciesWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final Map<String, bool> _expandedPolicies = {};
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePolicyStates();
  }
  
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    _fadeController.forward();
  }
  
  void _initializePolicyStates() {
    final groupedPolicies = _groupPoliciesByType();
    for (final type in groupedPolicies.keys) {
      _expandedPolicies[type] = true;
    }
  }
  
  Map<String, List<PropertyPolicy>> _groupPoliciesByType() {
    final groupedPolicies = <String, List<PropertyPolicy>>{};
    for (final policy in widget.policies) {
      final type = policy.policyType;
      if (!groupedPolicies.containsKey(type)) {
        groupedPolicies[type] = [];
      }
      groupedPolicies[type]!.add(policy);
    }
    return groupedPolicies;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.policies.isEmpty) {
      return const SizedBox.shrink();
    }

    final groupedPolicies = _groupPoliciesByType();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: groupedPolicies.entries.map((entry) {
          return _buildUltraMinimalPolicySection(
            entry.key,
            entry.value,
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildUltraMinimalPolicySection(String type, List<PropertyPolicy> policies) {
    final isExpanded = _expandedPolicies[type] ?? false;
    final typeColor = _getPolicyTypeColor(type);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            typeColor.withOpacity(0.03),
            typeColor.withOpacity(0.01),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: typeColor.withOpacity(0.08),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              _buildMinimalPolicyHeader(type, typeColor, policies.length),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: isExpanded ? null : 0,
                child: isExpanded
                    ? _buildMinimalPoliciesList(policies, typeColor)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMinimalPolicyHeader(String type, Color color, int count) {
    final isExpanded = _expandedPolicies[type] ?? false;
    
    return InkWell(
      onTap: () {
        setState(() {
          _expandedPolicies[type] = !isExpanded;
        });
        HapticFeedback.selectionClick();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.05),
              color.withOpacity(0.02),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.1),
                    color.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getPolicyTypeIcon(type),
                size: 16,
                color: color.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getPolicyTypeTitle(type),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textWhite.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '$count سياسة',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.expand_more,
                color: AppTheme.textMuted.withOpacity(0.3),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMinimalPoliciesList(List<PropertyPolicy> policies, Color typeColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: policies.map((policy) {
          return _buildUltraMinimalPolicyItem(policy, typeColor);
        }).toList(),
      ),
    );
  }
  
  Widget _buildUltraMinimalPolicyItem(PropertyPolicy policy, Color typeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: policy.isActive
              ? typeColor.withOpacity(0.08)
              : AppTheme.darkBorder.withOpacity(0.05),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: policy.isActive
                  ? typeColor.withOpacity(0.05)
                  : AppTheme.darkCard.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getPolicyIcon(policy.policyContent),
              size: 14,
              color: policy.isActive
                  ? typeColor.withOpacity(0.7)
                  : AppTheme.textMuted.withOpacity(0.3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        policy.policyContent,
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textWhite.withOpacity(0.85),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (policy.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'إلزامي',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.error.withOpacity(0.7),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  policy.description,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted.withOpacity(0.6),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                if (!policy.isActive) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 10,
                        color: AppTheme.warning.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'غير مفعل',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.warning.withOpacity(0.6),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPolicyTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'checkin':
      case 'check-in':
        return Icons.login;
      case 'checkout':
      case 'check-out':
        return Icons.logout;
      case 'cancellation':
        return Icons.cancel_outlined;
      case 'payment':
        return Icons.payment_outlined;
      case 'house_rules':
      case 'rules':
        return Icons.rule;
      case 'safety':
        return Icons.security_outlined;
      case 'health':
        return Icons.health_and_safety_outlined;
      default:
        return Icons.policy_outlined;
    }
  }
  
  IconData _getPolicyIcon(String content) {
    final lowerContent = content.toLowerCase();
    if (lowerContent.contains('وقت') || lowerContent.contains('time')) return Icons.access_time;
    if (lowerContent.contains('دفع') || lowerContent.contains('payment')) return Icons.payment;
    if (lowerContent.contains('إلغاء') || lowerContent.contains('cancel')) return Icons.cancel;
    if (lowerContent.contains('تدخين') || lowerContent.contains('smoking')) return Icons.smoke_free;
    if (lowerContent.contains('حيوان') || lowerContent.contains('pet')) return Icons.pets;
    if (lowerContent.contains('حفلة') || lowerContent.contains('party')) return Icons.celebration;
    return Icons.check_circle_outline;
  }

  Color _getPolicyTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'checkin':
      case 'check-in':
      case 'checkout':
      case 'check-out':
        return AppTheme.info;
      case 'cancellation':
        return AppTheme.warning;
      case 'payment':
        return AppTheme.success;
      case 'house_rules':
      case 'rules':
        return AppTheme.primaryBlue;
      case 'safety':
      case 'health':
        return AppTheme.error;
      default:
        return AppTheme.primaryPurple;
    }
  }

  String _getPolicyTypeTitle(String type) {
    switch (type.toLowerCase()) {
      case 'checkin':
      case 'check-in':
        return 'تسجيل الدخول';
      case 'checkout':
      case 'check-out':
        return 'تسجيل الخروج';
      case 'cancellation':
        return 'الإلغاء';
      case 'payment':
        return 'الدفع';
      case 'house_rules':
      case 'rules':
        return 'قوانين المكان';
      case 'safety':
        return 'السلامة';
      case 'health':
        return 'الصحة';
      default:
        return 'سياسات أخرى';
    }
  }
}