// lib/features/admin_currencies/presentation/pages/currencies_management_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/empty_widget.dart';
import '../bloc/currencies_bloc.dart';
import '../bloc/currencies_event.dart';
import '../bloc/currencies_state.dart';
import '../widgets/futuristic_currency_card.dart';
import '../widgets/futuristic_currency_form_modal.dart';
import '../widgets/currency_stats_card.dart';
import '../widgets/exchange_rate_indicator.dart';
import '../../domain/entities/currency.dart';

class CurrenciesManagementPage extends StatefulWidget {
  const CurrenciesManagementPage({super.key});

  @override
  State<CurrenciesManagementPage> createState() =>
      _CurrenciesManagementPageState();
}

class _CurrenciesManagementPageState extends State<CurrenciesManagementPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late AnimationController _refreshAnimationController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _isGridView = true;
  final String _searchQuery = '';
  Currency? _selectedCurrency;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _refreshAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _loadCurrencies();
  }

  void _loadCurrencies() {
    context.read<CurrenciesBloc>().add(LoadCurrenciesEvent());
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    _refreshAnimationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: BlocListener<CurrenciesBloc, CurrenciesState>(
        listener: _handleStateChanges,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            _buildSliverAppBar(),
            _buildExchangeRateIndicator(),
            _buildStatsSection(),
            _buildSearchBar(),
            _buildCurrenciesContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      floating: true,
      pinned: true,
      backgroundColor: AppTheme.darkBackground,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Animated gradient background
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryCyan.withValues(
                          alpha: 0.15 * _animationController.value,
                        ),
                        AppTheme.primaryBlue.withValues(
                          alpha: 0.1 * _animationController.value,
                        ),
                        AppTheme.primaryPurple.withValues(
                          alpha: 0.05 * _animationController.value,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Floating currency symbols animation
            ...List.generate(4, (index) {
              final symbols = ['﷼', '\$', '€', '£'];
              return AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Positioned(
                    top: 20 + (index * 35) * _animationController.value,
                    right: 30 + (index * 50) * _animationController.value,
                    child: Transform.rotate(
                      angle: _animationController.value * 0.3 * (index + 1),
                      child: Opacity(
                        opacity: 0.1 * _animationController.value,
                        child: Text(
                          symbols[index],
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Row(
          children: [
            // Animated icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryCyan,
                          AppTheme.primaryBlue,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryCyan.withValues(alpha: 0.3),
                          blurRadius: 10 * value,
                          offset: Offset(0, 5 * value),
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.money_dollar_circle_fill,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Text(
              'إدارة العملات',
              style: AppTextStyles.heading1.copyWith(
                color: AppTheme.textWhite,
                shadows: [
                  Shadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        _buildActionButton(
          icon: CupertinoIcons.plus,
          onPressed: () => _showCurrencyForm(),
        ),
        _buildActionButton(
          icon: _isGridView
              ? CupertinoIcons.list_bullet
              : CupertinoIcons.square_grid_2x2,
          onPressed: () => setState(() => _isGridView = !_isGridView),
        ),
        _buildActionButton(
          icon: CupertinoIcons.arrow_2_circlepath,
          onPressed: _handleRefresh,
          isAnimated: true,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isAnimated = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: isAnimated
                ? AnimatedBuilder(
                    animation: _refreshAnimationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _refreshAnimationController.value * 2 * 3.14159,
                        child: Icon(
                          icon,
                          color: AppTheme.textWhite,
                          size: 20,
                        ),
                      );
                    },
                  )
                : Icon(
                    icon,
                    color: AppTheme.textWhite,
                    size: 20,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildExchangeRateIndicator() {
    return SliverToBoxAdapter(
      child: BlocBuilder<CurrenciesBloc, CurrenciesState>(
        builder: (context, state) {
          if (state is! CurrenciesLoaded) return const SizedBox.shrink();

          Currency? defaultCurrency;
          if (state.currencies.isNotEmpty) {
            final maybeDefault = state.currencies.where((c) => c.isDefault);
            defaultCurrency = maybeDefault.isNotEmpty
                ? maybeDefault.first
                : state.currencies.first;
          } else {
            defaultCurrency = null;
          }

          if (defaultCurrency == null) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ExchangeRateIndicator(
              baseCurrency: defaultCurrency,
              currencies: state.currencies.where((c) => !c.isDefault).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsSection() {
    return SliverToBoxAdapter(
      child: BlocBuilder<CurrenciesBloc, CurrenciesState>(
        builder: (context, state) {
          if (state is! CurrenciesLoaded) return const SizedBox.shrink();

          return AnimationLimiter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CurrencyStatsCard(
                    currencies: state.currencies,
                    stats: state.stats,
                    startDate: DateTime.now().subtract(const Duration(days: 30)),
                    endDate: DateTime.now(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'الاتجاهات محسوبة لآخر 30 يومًا',
                    style: AppTextStyles.caption.copyWith(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowDark.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.darkCard.withValues(alpha: 0.5),
                      AppTheme.darkCard.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.darkBorder.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن عملة...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textMuted.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    prefixIcon: Icon(
                      CupertinoIcons.search,
                      color: AppTheme.textMuted,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              CupertinoIcons.xmark_circle_fill,
                              color: AppTheme.textMuted,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              context.read<CurrenciesBloc>().add(
                                    const SearchCurrenciesEvent(query: ''),
                                  );
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    context.read<CurrenciesBloc>().add(
                          SearchCurrenciesEvent(query: value),
                        );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrenciesContent() {
    return BlocBuilder<CurrenciesBloc, CurrenciesState>(
      builder: (context, state) {
        if (state is CurrenciesLoading) {
          return const SliverFillRemaining(
            child: LoadingWidget(
              type: LoadingType.futuristic,
              message: 'جاري تحميل العملات...',
            ),
          );
        }

        if (state is CurrenciesError) {
          return SliverFillRemaining(
            child: CustomErrorWidget(
              message: state.message,
              onRetry: _loadCurrencies,
            ),
          );
        }

        if (state is CurrenciesLoaded) {
          if (state.filteredCurrencies.isEmpty) {
            return SliverFillRemaining(
              child: EmptyWidget(
                message: state.searchQuery.isNotEmpty
                    ? 'لا توجد نتائج للبحث "${state.searchQuery}"'
                    : 'لا توجد عملات مضافة حالياً',
                actionWidget: state.searchQuery.isEmpty
                    ? _buildAddCurrencyButton()
                    : null,
              ),
            );
          }

          if (_isGridView) {
            return _buildGridView(state.filteredCurrencies);
          } else {
            return _buildListView(state.filteredCurrencies);
          }
        }

        return const SliverFillRemaining(child: SizedBox.shrink());
      },
    );
  }

  Widget _buildGridView(List<Currency> currencies) {
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
            final currency = currencies[index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 375),
              columnCount: _getGridCrossAxisCount(context),
              child: ScaleAnimation(
                scale: 0.95,
                child: FadeInAnimation(
                  child: FuturisticCurrencyCard(
                    currency: currency,
                    isSelected: _selectedCurrency == currency,
                    onTap: () => _handleCurrencyTap(currency),
                    onEdit: () => _showCurrencyForm(currency: currency),
                    onDelete: () => _confirmDeleteCurrency(currency),
                    onSetDefault: () => _setDefaultCurrency(currency),
                  ),
                ),
              ),
            );
          },
          childCount: currencies.length,
        ),
      ),
    );
  }

  Widget _buildListView(List<Currency> currencies) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final currency = currencies[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FuturisticCurrencyCard(
                      currency: currency,
                      isCompact: true,
                      isSelected: _selectedCurrency == currency,
                      onTap: () => _handleCurrencyTap(currency),
                      onEdit: () => _showCurrencyForm(currency: currency),
                      onDelete: () => _confirmDeleteCurrency(currency),
                      onSetDefault: () => _setDefaultCurrency(currency),
                    ),
                  ),
                ),
              ),
            );
          },
          childCount: currencies.length,
        ),
      ),
    );
  }

  // Removed FAB: Add action moved to AppBar

  Widget _buildAddCurrencyButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryCyan, AppTheme.primaryBlue],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCurrencyForm(),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.plus_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'إضافة أول عملة',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 1;
    if (width < 600) return 2;
    if (width < 900) return 3;
    return 4;
  }

  double _getGridAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 1.3;
    if (width < 600) return 1.1;
    return 0.9;
  }

  void _handleStateChanges(BuildContext context, CurrenciesState state) {
    if (state is CurrencyOperationSuccess) {
      _showSuccessMessage(state.message);
    } else if (state is CurrenciesError) {
      _showErrorMessage(state.message);
    }
  }

  void _handleCurrencyTap(Currency currency) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedCurrency = _selectedCurrency == currency ? null : currency;
    });
  }

  void _handleRefresh() {
    HapticFeedback.mediumImpact();
    _refreshAnimationController.forward().then((_) {
      _refreshAnimationController.reset();
    });
    context.read<CurrenciesBloc>().add(RefreshCurrenciesEvent());
  }

  void _showCurrencyForm({Currency? currency}) {
    HapticFeedback.mediumImpact();
    final currenciesBloc = context.read<CurrenciesBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => FuturisticCurrencyFormModal(
        currency: currency,
        onSave: (updatedCurrency) {
          if (currency == null) {
            currenciesBloc.add(
              AddCurrencyEvent(currency: updatedCurrency),
            );
          } else {
            currenciesBloc.add(
              UpdateCurrencyEvent(
                currency: updatedCurrency,
                oldCode: currency.code,
              ),
            );
          }
          Navigator.pop(sheetContext);
        },
      ),
    );
  }

  void _confirmDeleteCurrency(Currency currency) {
    HapticFeedback.heavyImpact();
    final currenciesBloc = context.read<CurrenciesBloc>();
    showDialog(
      fullscreenDialog: true,
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.error.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.error.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: AppTheme.error,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'حذف ${currency.arabicName}؟',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'لا يمكن التراجع عن هذا الإجراء',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'إلغاء',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppTheme.textLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          currenciesBloc.add(
                            DeleteCurrencyEvent(code: currency.code),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'حذف',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setDefaultCurrency(Currency currency) {
    HapticFeedback.mediumImpact();
    context.read<CurrenciesBloc>().add(
          SetDefaultCurrencyEvent(code: currency.code),
        );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(CupertinoIcons.checkmark_circle_fill,
                color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
