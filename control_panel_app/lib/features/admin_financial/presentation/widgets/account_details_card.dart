// lib/features/admin_financial/presentation/widgets/futuristic_account_details.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/chart_of_account.dart';

class AccountDetailsCard extends StatefulWidget {
  final ChartOfAccount account;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AccountDetailsCard({
    super.key,
    required this.account,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<AccountDetailsCard> createState() => _AccountDetailsCardState();
}

class _AccountDetailsCardState extends State<AccountDetailsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width < 600 ? 16 : 40,
              vertical: MediaQuery.of(context).size.height < 700 ? 20 : 40,
            ),
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 500;
                  return Container(
                    constraints: BoxConstraints(
                      maxWidth: 600,
                      maxHeight: MediaQuery.of(context).size.height * 0.9,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.darkCard.withOpacity(0.95),
                          AppTheme.darkCard.withOpacity(0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _getAccountColor().withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Column(
                          children: [
                            _buildHeader(isCompact),
                            Expanded(
                              child: _buildContent(isCompact),
                            ),
                            _buildActions(isCompact),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    final color = _getAccountColor();

    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: isCompact ? 40 : 48,
            height: isCompact ? 40 : 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _getAccountIcon(),
              color: Colors.white,
              size: isCompact ? 20 : 24,
            ),
          ),

          SizedBox(width: isCompact ? 12 : 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.account.accountNumber,
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.account.nameAr,
                  style: (isCompact
                          ? AppTextStyles.bodyLarge
                          : AppTextStyles.heading3)
                      .copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.account.nameEn,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Close Button
          IconButton(
            icon: Icon(
              CupertinoIcons.xmark_circle_fill,
              color: AppTheme.textMuted,
              size: isCompact ? 20 : 24,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isCompact) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Card
          _buildBalanceCard(isCompact),

          SizedBox(height: isCompact ? 16 : 20),

          // Account Type & Nature
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: CupertinoIcons.square_stack_3d_up,
                  label: 'نوع الحساب',
                  value: widget.account.accountType.nameAr,
                  color: _getAccountColor(),
                  isCompact: isCompact,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  icon: CupertinoIcons.arrow_right_arrow_left,
                  label: 'طبيعة الحساب',
                  value: widget.account.normalBalance.nameAr,
                  color: widget.account.normalBalance == AccountNature.debit
                      ? AppTheme.success
                      : AppTheme.warning,
                  isCompact: isCompact,
                ),
              ),
            ],
          ),

          SizedBox(height: isCompact ? 12 : 16),

          // Category & Level
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: CupertinoIcons.tag,
                  label: 'التصنيف',
                  value: widget.account.category.nameAr,
                  color: AppTheme.primaryCyan,
                  isCompact: isCompact,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  icon: CupertinoIcons.layers,
                  label: 'المستوى',
                  value: 'المستوى ${widget.account.level}',
                  color: AppTheme.primaryViolet,
                  isCompact: isCompact,
                ),
              ),
            ],
          ),

          SizedBox(height: isCompact ? 16 : 20),

          // Status Badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (widget.account.isActive)
                _buildBadge(
                  icon: CupertinoIcons.checkmark_circle_fill,
                  label: 'نشط',
                  color: AppTheme.success,
                )
              else
                _buildBadge(
                  icon: CupertinoIcons.xmark_circle_fill,
                  label: 'غير نشط',
                  color: AppTheme.error,
                ),
              if (widget.account.canPost)
                _buildBadge(
                  icon: CupertinoIcons.pencil_circle_fill,
                  label: 'يمكن الترحيل',
                  color: AppTheme.primaryCyan,
                ),
              if (widget.account.isSystemAccount)
                _buildBadge(
                  icon: CupertinoIcons.lock_circle_fill,
                  label: 'حساب نظام',
                  color: AppTheme.primaryViolet,
                ),
            ],
          ),

          // Description
          if (widget.account.description != null &&
              widget.account.description!.isNotEmpty) ...[
            SizedBox(height: isCompact ? 16 : 20),
            _buildDescriptionSection(isCompact),
          ],

          // Dates
          SizedBox(height: isCompact ? 16 : 20),
          _buildDatesSection(isCompact),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(bool isCompact) {
    final isPositive = widget.account.balance >= 0;
    final color = isPositive ? AppTheme.success : AppTheme.error;

    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: isCompact ? 48 : 56,
            height: isCompact ? 48 : 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              CupertinoIcons.money_dollar_circle_fill,
              color: Colors.white,
              size: isCompact ? 24 : 28,
            ),
          ),
          SizedBox(width: isCompact ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الرصيد الحالي',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatCurrency(
                    widget.account.balance,
                    widget.account.currency,
                  ),
                  style: (isCompact
                          ? AppTextStyles.heading3
                          : AppTextStyles.heading2)
                      .copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 10 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.08),
            color.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: isCompact ? 14 : 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                  fontSize: isCompact ? 10 : 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style:
                (isCompact ? AppTextStyles.bodySmall : AppTextStyles.bodyMedium)
                    .copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 10 : 12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.doc_text,
                size: isCompact ? 14 : 16,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                'الوصف',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.account.description!,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatesSection(bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 10 : 12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildDateRow(
            icon: CupertinoIcons.plus_circle,
            label: 'تاريخ الإنشاء',
            date: widget.account.createdAt,
            isCompact: isCompact,
          ),
          if (widget.account.updatedAt != null) ...[
            const SizedBox(height: 8),
            _buildDateRow(
              icon: CupertinoIcons.arrow_2_circlepath,
              label: 'آخر تحديث',
              date: widget.account.updatedAt!,
              isCompact: isCompact,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateRow({
    required IconData icon,
    required String label,
    required DateTime date,
    required bool isCompact,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: isCompact ? 14 : 16,
          color: AppTheme.textMuted,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
            fontSize: isCompact ? 10 : 11,
          ),
        ),
        const Spacer(),
        Text(
          Formatters.formatDateTime(date),
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textLight,
            fontWeight: FontWeight.w600,
            fontSize: isCompact ? 10 : 11,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.5),
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!widget.account.isSystemAccount) ...[
            _buildActionButton(
              label: 'حذف',
              icon: CupertinoIcons.trash,
              color: AppTheme.error,
              onTap: () {
                Navigator.of(context).pop();
                widget.onDelete();
              },
              isCompact: isCompact,
            ),
            SizedBox(width: isCompact ? 8 : 12),
          ],
          _buildActionButton(
            label: 'تعديل',
            icon: CupertinoIcons.pencil,
            color: AppTheme.primaryCyan,
            onTap: () {
              Navigator.of(context).pop();
              widget.onEdit();
            },
            isCompact: isCompact,
          ),
          SizedBox(width: isCompact ? 8 : 12),
          _buildActionButton(
            label: 'إغلاق',
            icon: CupertinoIcons.xmark,
            color: AppTheme.textMuted,
            onTap: () => Navigator.of(context).pop(),
            isCompact: isCompact,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isCompact,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: isCompact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: isCompact ? 14 : 16,
            ),
            SizedBox(width: isCompact ? 6 : 8),
            Text(
              label,
              style:
                  (isCompact ? AppTextStyles.caption : AppTextStyles.bodySmall)
                      .copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAccountColor() {
    switch (widget.account.accountType) {
      case AccountType.assets:
        return AppTheme.success;
      case AccountType.liabilities:
        return AppTheme.error;
      case AccountType.equity:
        return AppTheme.primaryBlue;
      case AccountType.revenue:
        return AppTheme.primaryPurple;
      case AccountType.expenses:
        return AppTheme.warning;
    }
  }

  IconData _getAccountIcon() {
    switch (widget.account.accountType) {
      case AccountType.assets:
        return CupertinoIcons.building_2_fill;
      case AccountType.liabilities:
        return CupertinoIcons.creditcard;
      case AccountType.equity:
        return CupertinoIcons.briefcase;
      case AccountType.revenue:
        return CupertinoIcons.arrow_up_circle_fill;
      case AccountType.expenses:
        return CupertinoIcons.arrow_down_circle_fill;
    }
  }
}
