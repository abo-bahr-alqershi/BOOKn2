// lib/features/admin_financial/presentation/widgets/accounts_overview_widget.dart

import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/chart_of_account.dart';

/// 🏦 ويدجت نظرة عامة على الحسابات
class AccountsOverviewWidget extends StatefulWidget {
  final List<ChartOfAccount> accounts;
  final Function(String)? onAccountTap;

  const AccountsOverviewWidget({
    super.key,
    required this.accounts,
    this.onAccountTap,
  });

  @override
  State<AccountsOverviewWidget> createState() => _AccountsOverviewWidgetState();
}

class _AccountsOverviewWidgetState extends State<AccountsOverviewWidget>
    with TickerProviderStateMixin {
  late AnimationController _expansionController;
  late AnimationController _rotationController;

  final Map<String, bool> _expandedAccounts = {};
  String _selectedAccountType = 'all';

  @override
  void initState() {
    super.initState();
    _expansionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _expansionController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  List<ChartOfAccount> get filteredAccounts {
    if (_selectedAccountType == 'all') {
      return widget.accounts;
    }
    return widget.accounts.where((account) {
      switch (_selectedAccountType) {
        case 'assets':
          return account.accountType == AccountType.assets;
        case 'liabilities':
          return account.accountType == AccountType.liabilities;
        case 'equity':
          return account.accountType == AccountType.equity;
        case 'revenue':
          return account.accountType == AccountType.revenue;
        case 'expenses':
          return account.accountType == AccountType.expenses;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkCard.withOpacity(0.8),
            AppTheme.darkCard.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),

              // Filter Chips
              _buildFilterChips(),

              // Accounts Tree
              if (filteredAccounts.isEmpty)
                _buildEmptyState()
              else
                _buildAccountsTree(),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎯 Header
  Widget _buildHeader() {
    final totalBalance = widget.accounts.fold<double>(
      0,
      (sum, account) => sum + account.balance,
    );

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * math.pi,
                    child: child,
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.chart_pie_fill,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'دليل الحسابات',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.accounts.length} حساب نشط',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Total Balance Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryCyan.withOpacity(0.2),
                  AppTheme.primaryPurple.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryCyan.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إجمالي الأرصدة',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppTheme.primaryGradient.createShader(bounds),
                      child: Text(
                        CurrencyFormatter.format(totalBalance.abs()),
                        style: AppTextStyles.heading3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryCyan.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.money_dollar_circle_fill,
                    color: AppTheme.primaryCyan,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Filter Chips
  Widget _buildFilterChips() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('الكل', 'all', '📊'),
          const SizedBox(width: 8),
          _buildFilterChip('أصول', 'assets', '💎'),
          const SizedBox(width: 8),
          _buildFilterChip('التزامات', 'liabilities', '📈'),
          const SizedBox(width: 8),
          _buildFilterChip('حقوق ملكية', 'equity', '🏦'),
          const SizedBox(width: 8),
          _buildFilterChip('إيرادات', 'revenue', '💰'),
          const SizedBox(width: 8),
          _buildFilterChip('مصروفات', 'expenses', '💸'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String emoji) {
    final isSelected = _selectedAccountType == value;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedAccountType = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryCyan.withOpacity(0.3),
                    AppTheme.primaryPurple.withOpacity(0.3),
                  ],
                )
              : null,
          color: isSelected ? null : AppTheme.darkBackground.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryCyan.withOpacity(0.5)
                : AppTheme.darkBorder.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppTheme.textWhite : AppTheme.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🌳 Accounts Tree
  Widget _buildAccountsTree() {
    return AnimationLimiter(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        itemCount: filteredAccounts.length,
        itemBuilder: (context, index) {
          final account = filteredAccounts[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              horizontalOffset: 50,
              child: FadeInAnimation(
                child: AccountTreeItem(
                  account: account,
                  isExpanded: _expandedAccounts[account.id] ?? false,
                  onTap: () {
                    if (account.hasSubAccounts) {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _expandedAccounts[account.id] =
                            !(_expandedAccounts[account.id] ?? false);
                      });
                    } else {
                      widget.onAccountTap?.call(account.id);
                    }
                  },
                  onAccountTap: widget.onAccountTap,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 🔍 Empty State
  Widget _buildEmptyState() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.darkBorder.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.doc_text,
              color: AppTheme.textMuted,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد حسابات',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// 🌳 Account Tree Item
class AccountTreeItem extends StatefulWidget {
  final ChartOfAccount account;
  final bool isExpanded;
  final VoidCallback onTap;
  final Function(String)? onAccountTap;

  const AccountTreeItem({
    super.key,
    required this.account,
    required this.isExpanded,
    required this.onTap,
    this.onAccountTap,
  });

  @override
  State<AccountTreeItem> createState() => _AccountTreeItemState();
}

class _AccountTreeItemState extends State<AccountTreeItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: math.pi / 2,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isExpanded) {
      _rotationController.forward();
    }
  }

  @override
  void didUpdateWidget(AccountTreeItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _rotationController.forward();
      } else {
        _rotationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountColor = Color(
      int.parse(widget.account.accountColor.replaceFirst('#', '0xFF')),
    );

    return Column(
      children: [
        GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: EdgeInsets.only(
              left: widget.account.level * 16.0,
              bottom: 8,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.darkBackground.withOpacity(0.7),
                  AppTheme.darkBackground.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accountColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Account Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accountColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      widget.account.accountIcon,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Account Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.account.accountNumber,
                            style: AppTextStyles.caption.copyWith(
                              color: accountColor,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (widget.account.isSystemAccount)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryCyan.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'نظام',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppTheme.primaryCyan,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.account.displayName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Balance
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.formatCompact(widget.account.balance),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: widget.account.balance >= 0
                            ? AppTheme.success
                            : AppTheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.account.normalBalance.nameAr,
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),

                // Expand Icon
                if (widget.account.hasSubAccounts) ...[
                  const SizedBox(width: 8),
                  AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnimation.value,
                        child: Icon(
                          CupertinoIcons.chevron_left,
                          color: AppTheme.textMuted,
                          size: 16,
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),

        // Sub Accounts
        if (widget.isExpanded && widget.account.subAccounts != null)
          ...widget.account.subAccounts!.map((subAccount) {
            return AccountTreeItem(
              account: subAccount,
              isExpanded: false,
              onTap: () => widget.onAccountTap?.call(subAccount.id),
              onAccountTap: widget.onAccountTap,
            );
          }),
      ],
    );
  }
}
