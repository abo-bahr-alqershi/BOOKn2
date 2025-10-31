// lib/features/admin_financial/presentation/widgets/account_tree_widget.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/chart_of_account.dart';

/// 🌳 عرض شجرة الحسابات
class AccountTreeWidget extends StatelessWidget {
  final List<ChartOfAccount> accounts;
  final ChartOfAccount? selectedAccount;
  final Function(ChartOfAccount) onAccountSelected;
  final Function(ChartOfAccount?) onAddSubAccount;
  final Function(ChartOfAccount) onEditAccount;
  final Function(ChartOfAccount) onDeleteAccount;

  const AccountTreeWidget({
    super.key,
    required this.accounts,
    this.selectedAccount,
    required this.onAccountSelected,
    required this.onAddSubAccount,
    required this.onEditAccount,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    // Build tree structure
    final mainAccounts =
        accounts.where((a) => a.parentAccountId == null).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mainAccounts.length,
      itemBuilder: (context, index) {
        final account = mainAccounts[index];
        return _AccountNode(
          account: account,
          allAccounts: accounts,
          selectedAccount: selectedAccount,
          onAccountSelected: onAccountSelected,
          onAddSubAccount: onAddSubAccount,
          onEditAccount: onEditAccount,
          onDeleteAccount: onDeleteAccount,
          level: 0,
        );
      },
    );
  }
}

class _AccountNode extends StatefulWidget {
  final ChartOfAccount account;
  final List<ChartOfAccount> allAccounts;
  final ChartOfAccount? selectedAccount;
  final Function(ChartOfAccount) onAccountSelected;
  final Function(ChartOfAccount?) onAddSubAccount;
  final Function(ChartOfAccount) onEditAccount;
  final Function(ChartOfAccount) onDeleteAccount;
  final int level;

  const _AccountNode({
    required this.account,
    required this.allAccounts,
    this.selectedAccount,
    required this.onAccountSelected,
    required this.onAddSubAccount,
    required this.onEditAccount,
    required this.onDeleteAccount,
    required this.level,
  });

  @override
  State<_AccountNode> createState() => _AccountNodeState();
}

class _AccountNodeState extends State<_AccountNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  List<ChartOfAccount> _getSubAccounts() {
    return widget.allAccounts
        .where((a) => a.parentAccountId == widget.account.id)
        .toList()
      ..sort((a, b) => a.accountNumber.compareTo(b.accountNumber));
  }

  @override
  Widget build(BuildContext context) {
    final hasSubAccounts = _getSubAccounts().isNotEmpty;
    final isSelected = widget.selectedAccount?.id == widget.account.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: InkWell(
            onTap: () => widget.onAccountSelected(widget.account),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                left: widget.level * 24.0,
                bottom: 8,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSelected
                      ? [
                          AppColors.primary.withOpacity(0.15),
                          AppColors.primary.withOpacity(0.08),
                        ]
                      : _isHovered
                          ? [
                              AppColors.surface,
                              AppColors.surface.withOpacity(0.8),
                            ]
                          : [
                              AppColors.background,
                              AppColors.background.withOpacity(0.95),
                            ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.5)
                      : _isHovered
                          ? AppColors.primary.withOpacity(0.3)
                          : AppColors.primary.withOpacity(0.1),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected || _isHovered
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  // Expand Icon
                  if (hasSubAccounts)
                    InkWell(
                      onTap: _toggleExpand,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: AnimatedRotation(
                          turns: _isExpanded ? 0.25 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 28),
                  const SizedBox(width: 12),

                  // Account Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getAccountTypeColor(widget.account.accountType)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getAccountTypeIcon(widget.account.accountType),
                      size: 20,
                      color: _getAccountTypeColor(widget.account.accountType),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Account Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) {
                            final badgeWidgets = <Widget>[];

                            if (widget.account.isSystemAccount) {
                              badgeWidgets.add(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.accent.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'نظام',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                              );
                            }

                            if (!widget.account.isActive) {
                              badgeWidgets.add(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.error.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Text(
                                    'غير نشط',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              );
                            }

                            return Row(
                              children: [
                                // Account Number
                                Flexible(
                                  flex: 0,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        widget.account.accountNumber,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Account Name
                                Expanded(
                                  child: Text(
                                    widget.account.nameAr,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                if (badgeWidgets.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Flexible(
                                    fit: FlexFit.loose,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        alignment: WrapAlignment.end,
                                        children: badgeWidgets,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 4),

                        // English Name & Balance
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.account.nameEn,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.account.balance != 0) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      CurrencyFormatter.format(
                                        widget.account.balance,
                                        currency: widget.account.currency,
                                      ),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: widget.account.balance > 0
                                            ? AppColors.success
                                            : AppColors.error,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  if (_isHovered && !widget.account.isSystemAccount) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      fit: FlexFit.loose,
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          _buildActionButton(
                            icon: Icons.add,
                            tooltip: 'إضافة حساب فرعي',
                            color: AppColors.success,
                            onTap: () => widget.onAddSubAccount(widget.account),
                          ),
                          _buildActionButton(
                            icon: Icons.edit,
                            tooltip: 'تعديل',
                            color: AppColors.primary,
                            onTap: () => widget.onEditAccount(widget.account),
                          ),
                          _buildActionButton(
                            icon: Icons.delete_outline,
                            tooltip: 'حذف',
                            color: AppColors.error,
                            onTap: () => widget.onDeleteAccount(widget.account),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Sub Accounts
        if (hasSubAccounts)
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              children: _getSubAccounts().map((subAccount) {
                return _AccountNode(
                  account: subAccount,
                  allAccounts: widget.allAccounts,
                  selectedAccount: widget.selectedAccount,
                  onAccountSelected: widget.onAccountSelected,
                  onAddSubAccount: widget.onAddSubAccount,
                  onEditAccount: widget.onEditAccount,
                  onDeleteAccount: widget.onDeleteAccount,
                  level: widget.level + 1,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
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

  Color _getAccountTypeColor(AccountType type) {
    switch (type) {
      case AccountType.assets:
        return Colors.green;
      case AccountType.liabilities:
        return Colors.red;
      case AccountType.equity:
        return Colors.blue;
      case AccountType.revenue:
        return Colors.teal;
      case AccountType.expenses:
        return Colors.orange;
    }
  }

  IconData _getAccountTypeIcon(AccountType type) {
    switch (type) {
      case AccountType.assets:
        return Icons.account_balance_rounded;
      case AccountType.liabilities:
        return Icons.money_off_rounded;
      case AccountType.equity:
        return Icons.business_center_rounded;
      case AccountType.revenue:
        return Icons.trending_up_rounded;
      case AccountType.expenses:
        return Icons.trending_down_rounded;
    }
  }
}
