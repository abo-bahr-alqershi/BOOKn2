// lib/features/admin_financial/presentation/pages/financial_dashboard_page.dart

import 'package:bookn_cp_app/features/admin_financial/presentation/widgets/accounts_overview_widget.dart';
import 'package:bookn_cp_app/features/admin_financial/presentation/widgets/account_details_card.dart';
import 'package:bookn_cp_app/features/admin_financial/presentation/widgets/financial_chart_widget.dart';
import 'package:bookn_cp_app/features/admin_financial/presentation/widgets/financial_stats_cards.dart';
import 'package:bookn_cp_app/features/admin_financial/presentation/widgets/financial_summary_card.dart';
import 'package:bookn_cp_app/features/admin_financial/presentation/widgets/period_selector_widget.dart';
import 'package:bookn_cp_app/features/admin_financial/presentation/widgets/recent_transactions_widget.dart';
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
import '../../domain/entities/chart_of_account.dart';
import '../bloc/financial_overview/financial_overview_bloc.dart';

class FinancialDashboardPage extends StatefulWidget {
  const FinancialDashboardPage({super.key});

  @override
  State<FinancialDashboardPage> createState() => _FinancialDashboardPageState();
}

class _FinancialDashboardPageState extends State<FinancialDashboardPage>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _pulseAnimationController;

  // Controllers
  final ScrollController _scrollController = ScrollController();

  // State
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  int _selectedChartIndex = 0;
  bool _isFullScreen = false;
  bool _showQuickActions = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  void _loadData() {
    context.read<FinancialOverviewBloc>().add(
          LoadFinancialOverview(startDate: _startDate, endDate: _endDate),
        );
  }

  @override
  void dispose() {
    _pulseAnimationController.dispose();
    _scrollController.dispose();
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
            onRefresh: _handleRefresh,
            color: AppTheme.primaryCyan,
            backgroundColor: AppTheme.darkCard,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                _buildSliverAppBar(),
                _buildPeriodSelector(),
                _buildContent(),
              ],
            ),
          ),

          // Floating Quick Actions
          if (_showQuickActions) _buildQuickActionsOverlay(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildAnimatedBackground() {
    final circleGradients = [
      [AppTheme.primaryCyan, AppTheme.primaryPurple],
      [AppTheme.primaryBlue, AppTheme.primaryViolet],
      [AppTheme.primaryPurple, AppTheme.primaryCyan],
      [AppTheme.primaryBlue, AppTheme.success],
    ];

    final circleAlignments = [
      const Alignment(-0.8, -0.7),
      const Alignment(0.7, -0.6),
      const Alignment(-0.5, 0.6),
      const Alignment(0.6, 0.7),
    ];

    return Stack(
      children: [
        // Base Gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryBlue.withOpacity(0.05),
                AppTheme.primaryPurple.withOpacity(0.03),
                AppTheme.primaryCyan.withOpacity(0.05),
                AppTheme.darkBackground,
              ],
            ),
          ),
        ),

        // Static Grid Pattern
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _DashboardPatternPainter(progress: 0.2),
            ),
          ),
        ),

        // Soft Glow Circles
        ...List.generate(circleGradients.length, (index) {
          final colors = circleGradients[index];
          return Align(
            alignment: circleAlignments[index],
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.first.withOpacity(0.08),
                    colors.last.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          );
        }),

        // Ambient Floating Particles (static snapshot)
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _FloatingElementsPainter(progress: 0.35),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 180,
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
                    AppTheme.primaryBlue.withOpacity(0.2),
                    AppTheme.primaryPurple.withOpacity(0.1),
                    AppTheme.darkBackground,
                  ],
                ),
              ),
            ),

            // Pattern Overlay
            CustomPaint(
              painter: _DashboardPatternPainter(progress: 0.2),
              size: Size.infinite,
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
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimationController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale:
                                1.0 + (_pulseAnimationController.value * 0.1),
                            child: Text(
                              '💰',
                              style: TextStyle(
                                fontSize: 24,
                                shadows: [
                                  Shadow(
                                    color:
                                        AppTheme.primaryCyan.withOpacity(0.5),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'النظام المحاسبي',
                        style: AppTextStyles.heading2.copyWith(
                          color: AppTheme.textWhite,
                          shadows: [
                            Shadow(
                              color: AppTheme.primaryBlue.withOpacity(0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'لوحة التحكم المالية',
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
        _buildGlassIconButton(
          icon: CupertinoIcons.doc_chart_fill,
          onPressed: _showReports,
        ),
        _buildGlassIconButton(
          icon: CupertinoIcons.arrow_down_doc,
          onPressed: _exportReport,
        ),
        _buildGlassIconButton(
          icon: CupertinoIcons.arrow_2_circlepath,
          onPressed: _handleRefresh,
          isPrimary: true,
        ),
        const SizedBox(width: 8),
      ],
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

  Widget _buildPeriodSelector() {
    return SliverToBoxAdapter(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        child: PeriodSelectorWidget(
          startDate: _startDate,
          endDate: _endDate,
          onPeriodChanged: (start, end) {
            setState(() {
              _startDate = start;
              _endDate = end;
            });
            context.read<FinancialOverviewBloc>().add(
                  ChangePeriod(startDate: start, endDate: end),
                );
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<FinancialOverviewBloc, FinancialOverviewState>(
      builder: (context, state) {
        if (state is FinancialOverviewLoading) {
          return const SliverFillRemaining(
            child: LoadingWidget(
              type: LoadingType.futuristic,
              message: 'جاري تحميل البيانات المالية...',
            ),
          );
        }

        if (state is FinancialOverviewError) {
          return SliverFillRemaining(
            child: CustomErrorWidget(
              message: state.message,
              onRetry: _loadData,
            ),
          );
        }

        if (state is FinancialOverviewLoaded) {
          return SliverList(
            delegate: SliverChildListDelegate([
              // Financial Stats
              _buildStatsSection(state),

              // Charts Section
              _buildChartsSection(state),

              // Summary & Accounts
              _buildSummaryAndAccountsSection(state),

              // Recent Transactions
              _buildRecentTransactionsSection(state),

              const SizedBox(height: 100),
            ]),
          );
        }

        return const SliverFillRemaining(child: SizedBox.shrink());
      },
    );
  }

  Widget _buildStatsSection(FinancialOverviewLoaded state) {
    return AnimationLimiter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: AnimationConfiguration.synchronized(
          duration: const Duration(milliseconds: 600),
          child: SlideAnimation(
            verticalOffset: 50,
            child: FadeInAnimation(
              child: FinancialStatsCards(
                report: state.report,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartsSection(FinancialOverviewLoaded state) {
    return AnimationLimiter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimationConfiguration.synchronized(
          duration: const Duration(milliseconds: 700),
          child: SlideAnimation(
            verticalOffset: 50,
            child: FadeInAnimation(
              child: Column(
                children: [
                  // Chart Tabs
                  _buildChartTabs(),
                  const SizedBox(height: 16),

                  // Chart Container
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    height: _isFullScreen
                        ? MediaQuery.of(context).size.height * 0.6
                        : 350,
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
                        color: AppTheme.darkBorder.withOpacity(0.2),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Stack(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              child: FinancialChartWidget(
                                key: ValueKey(_selectedChartIndex),
                                chartData: _getChartData(state),
                                chartType: _getChartType(),
                              ),
                            ),

                            // Fullscreen Toggle
                            Positioned(
                              top: 16,
                              right: 16,
                              child: _buildFullscreenToggle(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartTabs() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          _buildChartTab('الإيرادات', 0, CupertinoIcons.arrow_up_circle_fill,
              AppTheme.success),
          _buildChartTab('المصروفات', 1, CupertinoIcons.arrow_down_circle_fill,
              AppTheme.error),
          _buildChartTab('التدفق النقدي', 2, CupertinoIcons.chart_bar_alt_fill,
              AppTheme.primaryCyan),
        ],
      ),
    );
  }

  Widget _buildChartTab(String title, int index, IconData icon, Color color) {
    final isSelected = _selectedChartIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _selectedChartIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      color.withOpacity(0.3),
                      color.withOpacity(0.2),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: color.withOpacity(0.5),
                    width: 1,
                  )
                : null,
          ),
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showLabel = constraints.maxWidth > 60;

                if (!showLabel) {
                  return Icon(
                    icon,
                    color: isSelected ? color : AppTheme.textMuted,
                    size: 18,
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: isSelected ? color : AppTheme.textMuted,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        title,
                        style: AppTextStyles.caption.copyWith(
                          color: isSelected ? color : AppTheme.textMuted,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullscreenToggle() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _isFullScreen = !_isFullScreen);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.darkBackground.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.darkBorder.withOpacity(0.2),
          ),
        ),
        child: Icon(
          _isFullScreen
              ? CupertinoIcons.fullscreen_exit
              : CupertinoIcons.fullscreen,
          color: AppTheme.textMuted,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildSummaryAndAccountsSection(FinancialOverviewLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;
          final isTablet = constraints.maxWidth > 600;

          if (isDesktop) {
            // Desktop: Side by side
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: AnimationConfiguration.synchronized(
                    duration: const Duration(milliseconds: 800),
                    child: SlideAnimation(
                      horizontalOffset: -50,
                      child: FadeInAnimation(
                        child: FinancialSummaryCard(
                          summary: state.summary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: AnimationConfiguration.synchronized(
                    duration: const Duration(milliseconds: 900),
                    child: SlideAnimation(
                      horizontalOffset: 50,
                      child: FadeInAnimation(
                        child: AccountsOverviewWidget(
                          accounts: state.mainAccounts,
                          onAccountTap: _navigateToAccountDetails,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else if (isTablet) {
            // Tablet: Side by side with smaller flex
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AnimationConfiguration.synchronized(
                    duration: const Duration(milliseconds: 800),
                    child: SlideAnimation(
                      horizontalOffset: -30,
                      child: FadeInAnimation(
                        child: FinancialSummaryCard(
                          summary: state.summary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimationConfiguration.synchronized(
                    duration: const Duration(milliseconds: 900),
                    child: SlideAnimation(
                      horizontalOffset: 30,
                      child: FadeInAnimation(
                        child: AccountsOverviewWidget(
                          accounts: state.mainAccounts,
                          onAccountTap: _navigateToAccountDetails,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Mobile: Stacked
            return Column(
              children: [
                AnimationConfiguration.synchronized(
                  duration: const Duration(milliseconds: 800),
                  child: SlideAnimation(
                    verticalOffset: 50,
                    child: FadeInAnimation(
                      child: FinancialSummaryCard(
                        summary: state.summary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AnimationConfiguration.synchronized(
                  duration: const Duration(milliseconds: 900),
                  child: SlideAnimation(
                    verticalOffset: 50,
                    child: FadeInAnimation(
                      child: AccountsOverviewWidget(
                        accounts: state.mainAccounts,
                        onAccountTap: _navigateToAccountDetails,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildRecentTransactionsSection(FinancialOverviewLoaded state) {
    return AnimationLimiter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimationConfiguration.synchronized(
          duration: const Duration(milliseconds: 1000),
          child: SlideAnimation(
            verticalOffset: 50,
            child: FadeInAnimation(
              child: RecentTransactionsWidget(
                transactions: state.recentTransactions,
                onTransactionTap: _navigateToTransactionDetails,
                onViewAllTap: _navigateToTransactionsList,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _pulseAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_pulseAnimationController.value * 0.05),
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryCyan.withOpacity(
                    0.3 + (_pulseAnimationController.value * 0.1),
                  ),
                  blurRadius: 20 + (_pulseAnimationController.value * 5),
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                setState(() => _showQuickActions = true);
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(
                CupertinoIcons.square_grid_2x2_fill,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionsOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _showQuickActions = false),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: AppTheme.darkBackground.withOpacity(0.3),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
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
                  color: AppTheme.primaryCyan.withOpacity(0.3),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'إجراءات سريعة',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppTheme.textWhite,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildQuickAction(
                        icon: CupertinoIcons.list_bullet,
                        label: 'القيود المحاسبية',
                        gradient: [AppTheme.primaryCyan, AppTheme.primaryBlue],
                        onTap: () {
                          setState(() => _showQuickActions = false);
                          context.push('/admin/financial/transactions');
                        },
                      ),
                      _buildQuickAction(
                        icon: CupertinoIcons.doc_chart_fill,
                        label: 'التقارير',
                        gradient: [
                          AppTheme.primaryPurple,
                          AppTheme.primaryViolet
                        ],
                        onTap: () {
                          setState(() => _showQuickActions = false);
                          _showReports();
                        },
                      ),
                      _buildQuickAction(
                        icon: CupertinoIcons.list_bullet_indent,
                        label: 'دليل الحسابات',
                        gradient: [AppTheme.success, AppTheme.neonGreen],
                        onTap: () {
                          setState(() => _showQuickActions = false);
                          context.push('/admin/financial/accounts');
                        },
                      ),
                      _buildQuickAction(
                        icon: CupertinoIcons.settings,
                        label: 'الإعدادات',
                        gradient: [AppTheme.warning, AppTheme.neonPurple],
                        onTap: () {
                          setState(() => _showQuickActions = false);
                          context.push('/admin/financial/settings');
                        },
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

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient.map((c) => c.withOpacity(0.1)).toList(),
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: gradient.first.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textWhite,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  dynamic _getChartData(FinancialOverviewLoaded state) {
    switch (_selectedChartIndex) {
      case 0:
        return state.revenueChartData;
      case 1:
        return state.expenseChartData;
      case 2:
      default:
        return state.cashFlowChartData;
    }
  }

  String _getChartType() {
    switch (_selectedChartIndex) {
      case 0:
        return 'revenue';
      case 1:
        return 'expense';
      case 2:
      default:
        return 'cashflow';
    }
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    context.read<FinancialOverviewBloc>().add(RefreshFinancialOverview());
  }

  void _showReports() {
    context.push('/admin/financial/reports');
  }

  void _exportReport() {
    context.read<FinancialOverviewBloc>().add(
          const ExportReport(format: 'pdf'),
        );
  }

  void _navigateToAccountDetails(String accountId) {
    // البحث عن الحساب في البيانات المحملة
    final currentState = context.read<FinancialOverviewBloc>().state;
    if (currentState is FinancialOverviewLoaded) {
      final account = currentState.accounts.firstWhere(
        (acc) => acc.id == accountId,
        orElse: () => currentState.mainAccounts.firstWhere(
          (acc) => acc.id == accountId,
        ),
      );

      // عرض ديالوج تفاصيل الحساب
      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black87,
        builder: (BuildContext context) {
          return AccountDetailsCard(
            account: account,
            onEdit: () {
              Navigator.of(context).pop();
              // يمكن إضافة منطق التعديل هنا
              context.push('/admin/financial/accounts/$accountId/edit');
            },
            onDelete: () {
              Navigator.of(context).pop();
              // يمكن إضافة منطق الحذف هنا
              _showDeleteAccountConfirmation(account);
            },
          );
        },
      );
    }
  }

  void _showDeleteAccountConfirmation(ChartOfAccount account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Text(
          'تأكيد الحذف',
          style: AppTextStyles.heading3.copyWith(color: AppTheme.textWhite),
        ),
        content: Text(
          'هل أنت متأكد من حذف الحساب "${account.nameAr}"؟',
          style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'إلغاء',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: تنفيذ عملية الحذف عند إضافة DeleteAccount event
              // context.read<AccountsBloc>().add(DeleteAccount(account.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('عملية الحذف قيد التطوير'),
                  backgroundColor: AppTheme.warning,
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.error,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _navigateToTransactionDetails(String transactionId) {
    context.push('/admin/financial/transactions/$transactionId');
  }

  void _navigateToTransactionsList() {
    context.push('/admin/financial/transactions');
  }
}

// Custom Painters
class _DashboardPatternPainter extends CustomPainter {
  final double progress;

  _DashboardPatternPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryCyan.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    final offset = progress * spacing;

    // Draw grid pattern
    for (double x = -spacing + offset; x < size.width + spacing; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = -spacing + offset;
        y < size.height + spacing;
        y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashboardPatternPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _FloatingElementsPainter extends CustomPainter {
  final double progress;

  _FloatingElementsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw floating circles
    for (int i = 0; i < 5; i++) {
      final offset = Offset(
        size.width * (0.1 + i * 0.2),
        size.height * (0.2 + math.sin(progress * math.pi * 2 + i) * 0.1),
      );

      paint.color = [
        AppTheme.primaryCyan,
        AppTheme.primaryPurple,
        AppTheme.primaryBlue,
        AppTheme.primaryViolet,
        AppTheme.success,
      ][i]
          .withOpacity(0.02 + progress * 0.01);

      canvas.drawCircle(offset, 30 + progress * 10, paint);
    }
  }

  @override
  bool shouldRepaint(_FloatingElementsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
