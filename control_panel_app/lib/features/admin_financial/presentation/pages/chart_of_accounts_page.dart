// lib/features/admin_financial/presentation/pages/chart_of_accounts_page.dart

import 'package:bookn_cp_app/core/utils/formatters.dart';
import 'package:bookn_cp_app/features/admin_financial/presentation/widgets/account_details_card.dart';
import 'package:bookn_cp_app/features/admin_financial/presentation/widgets/account_tree_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'dart:math' as math;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/empty_widget.dart';
import '../../domain/entities/chart_of_account.dart';
import '../bloc/accounts/accounts_bloc.dart';

class ChartOfAccountsPage extends StatefulWidget {
  const ChartOfAccountsPage({super.key});

  @override
  State<ChartOfAccountsPage> createState() => _ChartOfAccountsPageState();
}

class _ChartOfAccountsPageState extends State<ChartOfAccountsPage>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _mainAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _fabAnimationController;
  late AnimationController _rotationAnimationController;

  // Animations

  // Controllers
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // State
  bool _isSearchExpanded = false;
  int _selectedViewMode = 0; // 0: Tree, 1: Grid, 2: List
  bool _showBalances = true;
  AccountType? _selectedType;
  ChartOfAccount? _selectedAccount;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAccounts();
  }

  void _initializeAnimations() {
    _mainAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _rotationAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _mainAnimationController.forward();
  }

  void _loadAccounts() {
    context.read<AccountsBloc>().add(const LoadChartOfAccounts());
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _pulseAnimationController.dispose();
    _fabAnimationController.dispose();
    _rotationAnimationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          // Animated Background
          _buildAnimatedBackground(),

          // Main Content
          RefreshIndicator(
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              _loadAccounts();
            },
            color: AppTheme.primaryCyan,
            backgroundColor: AppTheme.darkCard,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                _buildSliverAppBar(),
                _buildFilterSection(),
                _buildAccountsContent(),
              ],
            ),
          ),

          // Floating Action Button
          _buildFloatingActionButton(),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        // Base Gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryPurple.withOpacity(0.05),
                AppTheme.primaryBlue.withOpacity(0.03),
                AppTheme.primaryCyan.withOpacity(0.05),
                AppTheme.darkBackground,
              ],
            ),
          ),
        ),

        // Animated Circles
        ...List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _rotationAnimationController,
            builder: (context, child) {
              final offset = index * (math.pi * 2 / 3);
              final progress =
                  (_rotationAnimationController.value + offset) % 1;

              return Positioned(
                left: MediaQuery.of(context).size.width *
                    (0.2 + math.sin(progress * math.pi * 2) * 0.3),
                top: MediaQuery.of(context).size.height *
                    (0.2 + math.cos(progress * math.pi * 2) * 0.3),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        [
                          AppTheme.primaryCyan,
                          AppTheme.primaryPurple,
                          AppTheme.primaryBlue
                        ][index]
                            .withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 160,
      floating: true,
      pinned: true,
      backgroundColor: AppTheme.darkBackground,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryPurple.withOpacity(0.15),
                    AppTheme.darkBackground,
                  ],
                ),
              ),
            ),

            // Pattern Overlay
            AnimatedBuilder(
              animation: _pulseAnimationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _AccountPatternPainter(
                    progress: _pulseAnimationController.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ],
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Row(
          children: [
            // Back Button
            _buildGlassIconButton(
              icon: CupertinoIcons.arrow_right,
              onPressed: () => context.pop(),
            ),
            const SizedBox(width: 4),

            // Title
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'دليل الحسابات',
                    style: AppTextStyles.heading2.copyWith(
                      color: AppTheme.textWhite,
                      shadows: [
                        Shadow(
                          color: AppTheme.primaryPurple.withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'إدارة وتنظيم شجرة الحسابات المالية',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        _buildViewModeToggle(),
        _buildGlassIconButton(
          icon: _showBalances
              ? CupertinoIcons.eye_fill
              : CupertinoIcons.eye_slash_fill,
          onPressed: () => setState(() => _showBalances = !_showBalances),
        ),
        _buildGlassIconButton(
          icon: CupertinoIcons.search,
          onPressed: _toggleSearch,
        ),
        _buildGlassIconButton(
          icon: CupertinoIcons.arrow_down_doc,
          onPressed: _exportAccounts,
          isPrimary: true,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildViewModeToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewModeButton(
            icon: CupertinoIcons.list_bullet_indent,
            index: 0,
            tooltip: 'عرض شجري',
          ),
          _buildViewModeButton(
            icon: CupertinoIcons.square_grid_2x2_fill,
            index: 1,
            tooltip: 'عرض شبكة',
          ),
          _buildViewModeButton(
            icon: CupertinoIcons.list_bullet,
            index: 2,
            tooltip: 'عرض قائمة',
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeButton({
    required IconData icon,
    required int index,
    required String tooltip,
  }) {
    final isSelected = _selectedViewMode == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedViewMode = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : AppTheme.textMuted,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: isPrimary
            ? AppTheme.primaryGradient
            : LinearGradient(
                colors: [
                  AppTheme.darkCard.withOpacity(0.5),
                  AppTheme.darkCard.withOpacity(0.3),
                ],
              ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPrimary
              ? AppTheme.primaryCyan.withOpacity(0.3)
              : AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: AppTheme.primaryCyan.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onPressed();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  icon,
                  color: isPrimary ? Colors.white : AppTheme.textWhite,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          // Search Bar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isSearchExpanded ? 80 : 0,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child:
                _isSearchExpanded ? _buildSearchBar() : const SizedBox.shrink(),
          ),

          // Account Type Filters
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildFilterChip(
                  label: 'الكل',
                  icon: CupertinoIcons.square_grid_2x2,
                  isSelected: _selectedType == null,
                  onTap: () => _filterByType(null),
                  gradient: [AppTheme.primaryCyan, AppTheme.primaryBlue],
                ),
                _buildFilterChip(
                  label: AccountType.assets.nameAr,
                  icon: CupertinoIcons.building_2_fill,
                  isSelected: _selectedType == AccountType.assets,
                  onTap: () => _filterByType(AccountType.assets),
                  gradient: [AppTheme.success, AppTheme.neonGreen],
                ),
                _buildFilterChip(
                  label: AccountType.liabilities.nameAr,
                  icon: CupertinoIcons.creditcard,
                  isSelected: _selectedType == AccountType.liabilities,
                  onTap: () => _filterByType(AccountType.liabilities),
                  gradient: [AppTheme.error, AppTheme.error.withOpacity(0.7)],
                ),
                _buildFilterChip(
                  label: AccountType.equity.nameAr,
                  icon: CupertinoIcons.briefcase,
                  isSelected: _selectedType == AccountType.equity,
                  onTap: () => _filterByType(AccountType.equity),
                  gradient: [AppTheme.primaryBlue, AppTheme.primaryCyan],
                ),
                _buildFilterChip(
                  label: AccountType.revenue.nameAr,
                  icon: CupertinoIcons.arrow_up_circle_fill,
                  isSelected: _selectedType == AccountType.revenue,
                  onTap: () => _filterByType(AccountType.revenue),
                  gradient: [AppTheme.primaryPurple, AppTheme.primaryViolet],
                ),
                _buildFilterChip(
                  label: AccountType.expenses.nameAr,
                  icon: CupertinoIcons.arrow_down_circle_fill,
                  isSelected: _selectedType == AccountType.expenses,
                  onTap: () => _filterByType(AccountType.expenses),
                  gradient: [AppTheme.warning, AppTheme.neonPurple],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.5),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextField(
            controller: _searchController,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
            ),
            decoration: InputDecoration(
              hintText: 'ابحث في الحسابات...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted.withOpacity(0.5),
              ),
              prefixIcon: Icon(
                CupertinoIcons.search,
                color: AppTheme.primaryCyan,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: AppTheme.textMuted,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _searchAccounts('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: _searchAccounts,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required List<Color> gradient,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected ? LinearGradient(colors: gradient) : null,
            color: isSelected ? null : AppTheme.darkCard.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? gradient.first.withOpacity(0.5)
                  : AppTheme.darkBorder.withOpacity(0.3),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: gradient.first.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppTheme.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected ? Colors.white : AppTheme.textLight,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountsContent() {
    return BlocBuilder<AccountsBloc, AccountsState>(
      builder: (context, state) {
        if (state is AccountsLoading) {
          return const SliverFillRemaining(
            child: LoadingWidget(
              type: LoadingType.futuristic,
              message: 'جاري تحميل دليل الحسابات...',
            ),
          );
        }

        if (state is AccountsError) {
          return SliverFillRemaining(
            child: CustomErrorWidget(
              message: state.message,
              onRetry: _loadAccounts,
            ),
          );
        }

        if (state is AccountsLoaded) {
          if (state.accounts.isEmpty) {
            return const SliverFillRemaining(
              child: EmptyWidget(
                message: 'لا توجد حسابات مضافة',
              ),
            );
          }

          switch (_selectedViewMode) {
            case 0:
              return _buildTreeView(state.accounts);
            case 1:
              return _buildGridView(state.accounts);
            case 2:
              return _buildListView(state.accounts);
            default:
              return _buildTreeView(state.accounts);
          }
        }

        return const SliverFillRemaining(child: SizedBox.shrink());
      },
    );
  }

  Widget _buildTreeView(List<ChartOfAccount> accounts) {
    return SliverToBoxAdapter(
      child: AnimationLimiter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AccountTreeWidget(
            accounts: accounts,
            selectedAccount: _selectedAccount,
            onAccountSelected: (account) {
              setState(() => _selectedAccount = account);
              _showAccountDetails(account);
            },
            onAddSubAccount: _addSubAccount,
            onEditAccount: _editAccount,
            onDeleteAccount: _deleteAccount,
          ),
        ),
      ),
    );
  }

  Widget _buildGridView(List<ChartOfAccount> accounts) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getGridCrossAxisCount(context),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: _getGridAspectRatio(context),
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final account = accounts[index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 375),
              columnCount: _getGridCrossAxisCount(context),
              child: ScaleAnimation(
                scale: 0.95,
                child: FadeInAnimation(
                  child: _buildAccountCard(account),
                ),
              ),
            );
          },
          childCount: accounts.length,
        ),
      ),
    );
  }

  Widget _buildListView(List<ChartOfAccount> accounts) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final account = accounts[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAccountListItem(account),
                  ),
                ),
              ),
            );
          },
          childCount: accounts.length,
        ),
      ),
    );
  }

  Widget _buildAccountCard(ChartOfAccount account) {
    final color = _getAccountColor(account.accountType);

    return GestureDetector(
      onTap: () => _showAccountDetails(account),
      child: Container(
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
            color: color.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getAccountIcon(account.accountType),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      if (_showBalances) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            Formatters.formatCurrency(
                              account.balance,
                              account.currency,
                            ),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Account Number
                  Text(
                    account.accountNumber,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Account Name
                  Text(
                    account.nameAr,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Footer
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryCyan.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.primaryCyan.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            account.category.nameAr,
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.primaryCyan,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (account.isActive) ...[
                        const SizedBox(width: 8),
                        Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          color: AppTheme.success,
                          size: 16,
                        ),
                      ],
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

  Widget _buildAccountListItem(ChartOfAccount account) {
    final color = _getAccountColor(account.accountType);

    return GestureDetector(
      onTap: () => _showAccountDetails(account),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withOpacity(0.5),
              AppTheme.darkCard.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getAccountIcon(account.accountType),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        account.accountNumber,
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryCyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          account.category.nameAr,
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
                    account.nameAr,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (_showBalances) ...[
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.formatCurrency(
                      account.balance,
                      account.currency,
                    ),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (account.isActive)
                    Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      color: AppTheme.success,
                      size: 14,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _fabAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_fabAnimationController.value * 0.05),
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryCyan.withOpacity(
                      0.3 + (_fabAnimationController.value * 0.1),
                    ),
                    blurRadius: 20 + (_fabAnimationController.value * 5),
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: _addNewAccount,
                backgroundColor: Colors.transparent,
                elevation: 0,
                label: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.plus_circle_fill,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'حساب جديد',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper Methods
  int _getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 2;
    if (width < 900) return 3;
    if (width < 1200) return 4;
    return 5;
  }

  double _getGridAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 0.85;
    if (width < 900) return 0.95;
    if (width < 1200) return 1.05;
    return 1.1;
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (!_isSearchExpanded) {
        _searchController.clear();
        _loadAccounts();
      }
    });
  }

  void _searchAccounts(String query) {
    if (query.isEmpty) {
      _loadAccounts();
    } else {
      context.read<AccountsBloc>().add(SearchAccounts(query: query));
    }
  }

  void _filterByType(AccountType? type) {
    setState(() => _selectedType = type);
    if (type == null) {
      _loadAccounts();
    } else {
      context.read<AccountsBloc>().add(FilterAccountsByType(type: type));
    }
  }

  void _showAccountDetails(ChartOfAccount account) {
    showDialog(
      context: context,
      builder: (context) => AccountDetailsCard(
        account: account,
        onEdit: () => _editAccount(account),
        onDelete: () => _deleteAccount(account),
      ),
    );
  }

  void _addNewAccount() {
    _showFeatureUnavailable();
  }

  void _addSubAccount(ChartOfAccount? parent) {
    if (parent == null) {
      _showFeatureUnavailable();
      return;
    }

    _showFeatureUnavailable();
  }

  void _editAccount(ChartOfAccount account) {
    _showFeatureUnavailable();
  }

  void _deleteAccount(ChartOfAccount account) {
    _showFeatureUnavailable();
  }

  void _showFeatureUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('إدارة الحسابات قيد التطوير حاليًا'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.warning,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _exportAccounts() {
    // Show export options
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildExportSheet(),
    );
  }

  Widget _buildExportSheet() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.darkBorder.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'تصدير دليل الحسابات',
                style: AppTextStyles.heading3.copyWith(
                  color: AppTheme.textWhite,
                ),
              ),
              const SizedBox(height: 20),
              _buildExportOption(
                icon: CupertinoIcons.doc_fill,
                label: 'Excel',
                color: AppTheme.success,
                onTap: () {
                  Navigator.pop(context);
                  // Export to Excel
                },
              ),
              _buildExportOption(
                icon: CupertinoIcons.doc_text_fill,
                label: 'PDF',
                color: AppTheme.error,
                onTap: () {
                  Navigator.pop(context);
                  // Export to PDF
                },
              ),
              const SizedBox(height: 20),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.05),
            color.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تصدير كملف $label',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'تحميل دليل الحسابات بصيغة $label',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_forward,
                  color: AppTheme.textMuted,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getAccountColor(AccountType type) {
    switch (type) {
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

  IconData _getAccountIcon(AccountType type) {
    switch (type) {
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

class _AccountPatternPainter extends CustomPainter {
  final double progress;

  _AccountPatternPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryPurple.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const spacing = 50.0;
    final offset = progress * spacing;

    for (double x = -spacing + offset; x < size.width + spacing; x += spacing) {
      for (double y = -spacing + offset;
          y < size.height + spacing;
          y += spacing) {
        canvas.drawCircle(Offset(x, y), 3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_AccountPatternPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
