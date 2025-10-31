// lib/features/admin_financial/presentation/widgets/futuristic_transaction_filters.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/financial_transaction.dart';

class TransactionFiltersSheet extends StatefulWidget {
  final TransactionStatus? selectedStatus;
  final TransactionType? selectedType;
  final Function(TransactionStatus?, TransactionType?) onFiltersChanged;

  const TransactionFiltersSheet({
    super.key,
    this.selectedStatus,
    this.selectedType,
    required this.onFiltersChanged,
  });

  @override
  State<TransactionFiltersSheet> createState() =>
      _TransactionFiltersSheetState();
}

class _TransactionFiltersSheetState extends State<TransactionFiltersSheet>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _expandController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  TransactionStatus? _selectedStatus;
  TransactionType? _selectedType;
  bool _isStatusExpanded = true;
  bool _isTypeExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.selectedStatus;
    _selectedType = widget.selectedType;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<double>(
      begin: -20,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.darkCard.withOpacity(0.8),
                    AppTheme.darkCard.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.darkBorder.withOpacity(0.2),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildContent(),
                      _buildActions(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              CupertinoIcons.slider_horizontal_3,
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
                  'فلترة المعاملات',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'اختر معايير التصفية',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          _buildQuickAction(
            icon: CupertinoIcons.refresh,
            onTap: _resetFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildStatusSection(),
            const SizedBox(height: 16),
            _buildTypeSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return _buildExpandableSection(
      title: 'حالة المعاملة',
      icon: CupertinoIcons.flag_fill,
      iconColor: AppTheme.primaryCyan,
      isExpanded: _isStatusExpanded,
      onToggle: () => setState(() => _isStatusExpanded = !_isStatusExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _isStatusExpanded ? null : 0,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              label: 'الكل',
              isSelected: _selectedStatus == null,
              onTap: () => setState(() => _selectedStatus = null),
            ),
            ...TransactionStatus.values.map((status) {
              return _buildFilterChip(
                label: status.nameAr,
                isSelected: _selectedStatus == status,
                color: _getStatusColor(status),
                icon: _getStatusIcon(status),
                onTap: () => setState(() => _selectedStatus = status),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSection() {
    return _buildExpandableSection(
      title: 'نوع المعاملة',
      icon: CupertinoIcons.square_stack_3d_up_fill,
      iconColor: AppTheme.primaryPurple,
      isExpanded: _isTypeExpanded,
      onToggle: () => setState(() => _isTypeExpanded = !_isTypeExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _isTypeExpanded ? 300 : 0,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.darkBackground.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.1),
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(8),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildTypeItem(
                label: 'الكل',
                icon: '📋',
                isSelected: _selectedType == null,
                onTap: () => setState(() => _selectedType = null),
              ),
              const SizedBox(height: 8),
              ...TransactionType.values.map((type) {
                return _buildTypeItem(
                  label: type.nameAr,
                  icon: _getTypeIcon(type),
                  isSelected: _selectedType == type,
                  onTap: () => setState(() => _selectedType = type),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onToggle();
            },
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      CupertinoIcons.chevron_down,
                      color: AppTheme.textMuted,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    Color? color,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected && color != null
              ? LinearGradient(
                  colors: [
                    color.withOpacity(0.2),
                    color.withOpacity(0.1),
                  ],
                )
              : null,
          color: isSelected ? null : AppTheme.darkBackground.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? (color ?? AppTheme.primaryCyan).withOpacity(0.5)
                : AppTheme.darkBorder.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 12,
                color: isSelected
                    ? (color ?? AppTheme.primaryCyan)
                    : AppTheme.textMuted,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected
                    ? (color ?? AppTheme.primaryCyan)
                    : AppTheme.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeItem({
    required String label,
    required String icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryCyan.withOpacity(0.1),
                    AppTheme.primaryCyan.withOpacity(0.05),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(
                  color: AppTheme.primaryCyan.withOpacity(0.3),
                )
              : null,
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected ? AppTheme.primaryCyan : AppTheme.textLight,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: AppTheme.primaryCyan,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              label: 'إعادة تعيين',
              icon: CupertinoIcons.refresh,
              color: AppTheme.textMuted,
              onTap: _resetFilters,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _buildActionButton(
              label: 'تطبيق الفلاتر',
              icon: CupertinoIcons.checkmark_circle_fill,
              isPrimary: true,
              onTap: () {
                widget.onFiltersChanged(_selectedStatus, _selectedType);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    Color? color,
    bool isPrimary = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isPrimary ? AppTheme.primaryGradient : null,
          color: isPrimary ? null : color?.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary
                ? AppTheme.primaryCyan.withOpacity(0.5)
                : color?.withOpacity(0.3) ??
                    AppTheme.darkBorder.withOpacity(0.3),
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppTheme.primaryCyan.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isPrimary ? Colors.white : color,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isPrimary ? Colors.white : color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppTheme.darkBackground.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.darkBorder.withOpacity(0.2),
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedType = null;
    });
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.draft:
        return AppTheme.textMuted;
      case TransactionStatus.pending:
        return AppTheme.warning;
      case TransactionStatus.approved:
        return AppTheme.success;
      case TransactionStatus.posted:
        return AppTheme.primaryCyan;
      case TransactionStatus.rejected:
        return AppTheme.error;
      case TransactionStatus.cancelled:
        return AppTheme.textMuted;
      case TransactionStatus.reversed:
        return AppTheme.primaryPurple;
    }
  }

  IconData _getStatusIcon(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.draft:
        return CupertinoIcons.doc;
      case TransactionStatus.pending:
        return CupertinoIcons.clock;
      case TransactionStatus.approved:
        return CupertinoIcons.checkmark_circle;
      case TransactionStatus.posted:
        return CupertinoIcons.checkmark_seal;
      case TransactionStatus.rejected:
        return CupertinoIcons.xmark_circle;
      case TransactionStatus.cancelled:
        return CupertinoIcons.xmark_octagon;
      case TransactionStatus.reversed:
        return CupertinoIcons.arrow_2_squarepath;
    }
  }

  String _getTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.newBooking:
        return '📝';
      case TransactionType.advancePayment:
        return '💵';
      case TransactionType.finalPayment:
        return '✅';
      case TransactionType.bookingCancellation:
        return '❌';
      case TransactionType.refund:
        return '💸';
      case TransactionType.platformCommission:
        return '💰';
      case TransactionType.ownerPayout:
        return '🏦';
      case TransactionType.tax:
        return '📊';
      case TransactionType.serviceFee:
        return '🛠️';
      case TransactionType.lateFee:
        return '⏰';
      case TransactionType.compensation:
        return '🔧';
      case TransactionType.securityDeposit:
        return '🔒';
      case TransactionType.securityDepositRefund:
        return '🔓';
      case TransactionType.discount:
        return '🎯';
      case TransactionType.interAccountTransfer:
        return '🔁';
      case TransactionType.adjustment:
        return '⚖️';
      case TransactionType.openingBalance:
        return '📊';
      case TransactionType.agentCommission:
        return '👤';
      case TransactionType.operationalExpense:
        return '💼';
      case TransactionType.otherIncome:
        return '➕';
    }
  }
}
