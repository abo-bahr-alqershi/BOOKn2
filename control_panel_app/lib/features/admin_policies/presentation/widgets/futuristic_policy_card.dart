import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/policy_identity_card_tooltip.dart';
import '../../../admin_properties/domain/entities/policy.dart'
    as property_policy;
import '../../domain/entities/policy.dart';

class FuturisticPolicyCard extends StatefulWidget {
  final Policy policy;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;

  const FuturisticPolicyCard({
    super.key,
    required this.policy,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onLongPress,
  });

  @override
  State<FuturisticPolicyCard> createState() => _FuturisticPolicyCardState();
}

class _FuturisticPolicyCardState extends State<FuturisticPolicyCard> {
  final GlobalKey _cardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final policy = widget.policy;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkCard.withValues(alpha: 0.8),
            AppTheme.darkCard.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getPolicyTypeColor(policy).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _getPolicyTypeColor(policy).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: _cardKey,
          onTap: _handleTap,
          onLongPress: _handleLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(policy),
                const SizedBox(height: 12),
                _buildContent(policy),
                const Spacer(),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap() {
    _showPolicyTooltip();
    widget.onTap?.call();
  }

  void _handleLongPress() {
    _showPolicyTooltip();
    widget.onLongPress?.call();
  }

  void _showPolicyTooltip() {
    final policy = widget.policy;
    PolicyIdentityCardTooltip.show(
      context: context,
      targetKey: _cardKey,
      policyId: policy.id,
      policyType: _mapPolicyType(policy.type),
      description: policy.description,
      rules: policy.rules,
      isActive: policy.isActive ?? true,
      propertyName: policy.propertyName,
      effectiveDate: policy.createdAt,
    );
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

  Widget _buildHeader(Policy policy) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getPolicyTypeColor(policy),
                _getPolicyTypeColor(policy).withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getPolicyTypeIcon(policy),
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            policy.type.displayName,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildStatusBadge(policy),
      ],
    );
  }

  Widget _buildStatusBadge(Policy policy) {
    final isActive = policy.isActive ?? true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.success.withValues(alpha: 0.2)
            : AppTheme.textMuted.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive
              ? AppTheme.success.withValues(alpha: 0.4)
              : AppTheme.textMuted.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        isActive ? 'نشط' : 'غير نشط',
        style: AppTextStyles.caption.copyWith(
          color: isActive ? AppTheme.success : AppTheme.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildContent(Policy policy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          policy.description.length > 80
              ? '${policy.description.substring(0, 80)}...'
              : policy.description,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textMuted,
            height: 1.5,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        if (policy.type == PolicyType.cancellation)
          _buildInfoRow(
            policy,
            Icons.calendar_today,
            'نافذة الإلغاء: ${policy.cancellationWindowDays} يوم',
          ),
        if (policy.type == PolicyType.payment)
          _buildInfoRow(
            policy,
            Icons.payment,
            'دفعة مقدمة: ${policy.minimumDepositPercentage.toInt()}%',
          ),
        if (policy.type == PolicyType.checkIn)
          _buildInfoRow(
            policy,
            Icons.schedule,
            'قبل ${policy.minHoursBeforeCheckIn} ساعة',
          ),
      ],
    );
  }

  Widget _buildInfoRow(Policy policy, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 12,
            color: _getPolicyTypeColor(policy),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textLight,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.onEdit != null)
          IconButton(
            onPressed: widget.onEdit,
            icon: Icon(
              CupertinoIcons.pencil,
              size: 16,
              color: AppTheme.primaryBlue,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        const SizedBox(width: 8),
        if (widget.onDelete != null)
          IconButton(
            onPressed: widget.onDelete,
            icon: Icon(
              CupertinoIcons.trash,
              size: 16,
              color: AppTheme.error,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  Color _getPolicyTypeColor(Policy policy) {
    switch (policy.type) {
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

  IconData _getPolicyTypeIcon(Policy policy) {
    switch (policy.type) {
      case PolicyType.cancellation:
        return CupertinoIcons.xmark_circle;
      case PolicyType.checkIn:
        return CupertinoIcons.arrow_right_square;
      case PolicyType.children:
        return CupertinoIcons.person_2;
      case PolicyType.pets:
        return CupertinoIcons.paw;
      case PolicyType.payment:
        return CupertinoIcons.money_dollar_circle;
      case PolicyType.modification:
        return CupertinoIcons.pencil_circle;
    }
  }
}
