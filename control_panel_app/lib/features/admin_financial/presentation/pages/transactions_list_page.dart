// lib/features/admin_financial/presentation/pages/transactions_list_page.dart

import 'package:bookn_cp_app/features/admin_financial/presentation/widgets/financial_stats_cards.dart';
import 'package:bookn_cp_app/features/admin_financial/presentation/widgets/transaction_card.dart';
import 'package:bookn_cp_app/features/admin_financial/presentation/widgets/transaction_details_dialog.dart';
import 'package:bookn_cp_app/features/admin_financial/presentation/widgets/transaction_filters_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/empty_widget.dart';
import '../../domain/entities/financial_transaction.dart';
import '../bloc/transactions/transactions_bloc.dart';

class TransactionsListPage extends StatefulWidget {
  final String? initialBookingId;
  final String? initialUserId;

  const TransactionsListPage({super.key, this.initialBookingId, this.initialUserId});

  @override
  State<TransactionsListPage> createState() => _TransactionsListPageState();
}

class _TransactionsListPageState extends State<TransactionsListPage>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _fabAnimationController;
  late AnimationController _refreshAnimationController;

  // Controllers
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // State
  bool _isGridView = false;
  bool _showFilters = false;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  TransactionStatus? _selectedStatus;
  TransactionType? _selectedType;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadTransactions();
    _setupScrollListener();
  }

  void _initializeAnimations() {
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _refreshAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        // Load more logic
      }
    });
  }

  void _loadTransactions() {
    final bloc = context.read<TransactionsBloc>();
    if (widget.initialBookingId != null && widget.initialBookingId!.isNotEmpty) {
      bloc.add(LoadTransactionsByBooking(bookingId: widget.initialBookingId!));
      return;
    }
    if (widget.initialUserId != null && widget.initialUserId!.isNotEmpty) {
      bloc.add(LoadTransactionsByUser(userId: widget.initialUserId!));
      return;
    }
    bloc.add(
      LoadTransactions(
        startDate: _startDate,
        endDate: _endDate,
        status: _selectedStatus,
        type: _selectedType,
      ),
    );
  }

  @override
  void dispose() {
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
      body: Stack(
        children: [
          // Animated Background
          _buildAnimatedBackground(),

          // Main Content
          RefreshIndicator(
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              _refreshAnimationController.forward().then((_) {
                _refreshAnimationController.reset();
              });
              _loadTransactions();
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
                _buildStatsSection(),
                _buildDateRangeSection(),
                _buildFilterSection(),
                _buildTransactionsList(),
              ],
            ),
          ),

          // Floating Action Button
          // _buildFloatingActionButton(),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryCyan.withOpacity(0.03),
            AppTheme.primaryPurple.withOpacity(0.02),
            AppTheme.primaryBlue.withOpacity(0.03),
            AppTheme.darkBackground,
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 140,
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
                    AppTheme.primaryCyan.withOpacity(0.1),
                    AppTheme.darkBackground,
                  ],
                ),
              ),
            ),

            // Decorative Elements
            Positioned(
              top: 20,
              right: 50,
              child: _buildDecorativeCircle(60),
            ),
            Positioned(
              top: 60,
              right: 130,
              child: _buildDecorativeCircle(50),
            ),
            Positioned(
              top: 100,
              right: 210,
              child: _buildDecorativeCircle(40),
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
                    'المعاملات المالية',
                    style: AppTextStyles.heading2.copyWith(
                      color: AppTheme.textWhite,
                      shadows: [
                        Shadow(
                          color: AppTheme.primaryCyan.withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'إدارة وتتبع جميع المعاملات',
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
          icon: _isGridView
              ? CupertinoIcons.list_bullet
              : CupertinoIcons.square_grid_2x2,
          onPressed: () => setState(() => _isGridView = !_isGridView),
        ),
        _buildGlassIconButton(
          icon: CupertinoIcons.search,
          onPressed: _toggleSearch,
        ),
        _buildGlassIconButton(
          icon: CupertinoIcons.slider_horizontal_3,
          onPressed: () => setState(() => _showFilters = !_showFilters),
        ),
        _buildGlassIconButton(
          icon: CupertinoIcons.arrow_down_doc,
          onPressed: _showExportOptions,
          isPrimary: true,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDecorativeCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryCyan.withOpacity(0.05),
            AppTheme.primaryPurple.withOpacity(0.03),
          ],
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

  Widget _buildStatsSection() {
    return SliverToBoxAdapter(
      child: BlocBuilder<TransactionsBloc, TransactionsState>(
        builder: (context, state) {
          if (state is! TransactionsLoaded) return const SizedBox.shrink();

          return Container(
            height: 140,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: FinancialStatsCards(
              report: state.report,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateRangeSection() {
    return SliverToBoxAdapter(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: _buildDateRangeSelector(),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
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
          child: Column(
            children: [
              // Date Range Display
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildDateCard(
                      title: 'من تاريخ',
                      date: _startDate,
                      onTap: () => _selectDate(true),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        CupertinoIcons.arrow_left,
                        color: AppTheme.primaryCyan,
                        size: 20,
                      ),
                    ),
                    _buildDateCard(
                      title: 'إلى تاريخ',
                      date: _endDate,
                      onTap: () => _selectDate(false),
                    ),
                  ],
                ),
              ),

              // Quick Date Ranges
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildQuickDateChip('اليوم', () => _setQuickDateRange(0)),
                    _buildQuickDateChip('أمس', () => _setQuickDateRange(1)),
                    _buildQuickDateChip(
                        'آخر 7 أيام', () => _setQuickDateRange(7)),
                    _buildQuickDateChip(
                        'آخر 30 يوم', () => _setQuickDateRange(30)),
                    _buildQuickDateChip(
                        'آخر 3 شهور', () => _setQuickDateRange(90)),
                    _buildQuickDateChip('السنة الحالية', () => _setYearRange()),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateCard({
    required String title,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.darkBackground.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryCyan.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    CupertinoIcons.calendar,
                    size: 14,
                    color: AppTheme.primaryCyan,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickDateChip(String label, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryCyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryCyan.withOpacity(0.3),
              ),
            ),
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.primaryCyan,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return SliverToBoxAdapter(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _showFilters ? 200 : 0,
        child: _showFilters
            ? TransactionFiltersSheet(
                selectedStatus: _selectedStatus,
                selectedType: _selectedType,
                onFiltersChanged: (status, type) {
                  setState(() {
                    _selectedStatus = status;
                    _selectedType = type;
                  });
                  final bloc = context.read<TransactionsBloc>();
                  if ((widget.initialBookingId != null && widget.initialBookingId!.isNotEmpty) ||
                      (widget.initialUserId != null && widget.initialUserId!.isNotEmpty)) {
                    bloc.add(FilterTransactions(status: _selectedStatus, type: _selectedType));
                  } else {
                    _loadTransactions();
                  }
                },
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildTransactionsList() {
    return BlocBuilder<TransactionsBloc, TransactionsState>(
      builder: (context, state) {
        if (state is TransactionsLoading) {
          return const SliverFillRemaining(
            child: LoadingWidget(
              type: LoadingType.futuristic,
              message: 'جاري تحميل المعاملات...',
            ),
          );
        }

        if (state is TransactionsError) {
          return SliverFillRemaining(
            child: CustomErrorWidget(
              message: state.message,
              onRetry: _loadTransactions,
            ),
          );
        }

        if (state is TransactionsLoaded) {
          if (state.transactions.isEmpty) {
            return const SliverFillRemaining(
              child: EmptyWidget(
                message: 'لا توجد معاملات في الفترة المحددة',
              ),
            );
          }

          return _isGridView
              ? _buildGridView(state.transactions)
              : _buildListView(state.transactions);
        }

        return const SliverFillRemaining(child: SizedBox.shrink());
      },
    );
  }

  Widget _buildGridView(List<FinancialTransaction> transactions) {
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
            final transaction = transactions[index];
            return TransactionCard(
              transaction: transaction,
              onTap: () => _showTransactionDetails(transaction),
            );
          },
          childCount: transactions.length,
        ),
      ),
    );
  }

  Widget _buildListView(List<FinancialTransaction> transactions) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final transaction = transactions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TransactionCard(
                transaction: transaction,
                isCompact: true,
                onTap: () => _showTransactionDetails(transaction),
              ),
            );
          },
          childCount: transactions.length,
        ),
      ),
    );
  }

  // ignore: unused_element
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
                onPressed: _showQuickActions,
                backgroundColor: Colors.transparent,
                elevation: 0,
                label: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.square_grid_2x2_fill,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'إجراءات سريعة',
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
    if (width < 600) return 1;
    if (width < 900) return 2;
    if (width < 1200) return 3;
    return 4;
  }

  double _getGridAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 1.2;
    if (width < 900) return 1.1;
    return 1.0;
  }

  void _toggleSearch() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildSearchSheet(),
    );
  }

  Widget _buildSearchSheet() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.darkBorder.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ابحث في المعاملات...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textMuted,
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
                              // Implement search reset logic if needed
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.darkBackground.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.darkBorder.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.darkBorder.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.primaryCyan.withOpacity(0.5),
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    // Implement search logic
                  },
                  onSubmitted: (value) {
                    Navigator.pop(context);
                    // Perform search
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Perform search
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryCyan,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'بحث',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryCyan,
              surface: AppTheme.darkCard,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      _loadTransactions();
    }
  }

  void _setQuickDateRange(int days) {
    setState(() {
      _endDate = DateTime.now();
      _startDate = _endDate.subtract(Duration(days: days));
    });
    _loadTransactions();
  }

  void _setYearRange() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, 1, 1);
      _endDate = DateTime(now.year, 12, 31);
    });
    _loadTransactions();
  }

  void _showTransactionDetails(FinancialTransaction transaction) {
    showDialog(
      context: context,
      builder: (context) => TransactionDetailsDialog(
        transaction: transaction,
        onPost: () {
          context.read<TransactionsBloc>().add(
                PostTransaction(transaction.id),
              );
        },
        onReverse: () {
          // Show reverse dialog
        },
      ),
    );
  }

  void _showExportOptions() {
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
                'تصدير المعاملات',
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
              _buildExportOption(
                icon: CupertinoIcons.doc_chart_fill,
                label: 'CSV',
                color: AppTheme.warning,
                onTap: () {
                  Navigator.pop(context);
                  // Export to CSV
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
                        'تحميل المعاملات بصيغة $label',
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

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildQuickActionsSheet(),
    );
  }

  Widget _buildQuickActionsSheet() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.95),
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
                'إجراءات سريعة',
                style: AppTextStyles.heading3.copyWith(
                  color: AppTheme.textWhite,
                ),
              ),
              const SizedBox(height: 20),
              _buildQuickActionItem(
                icon: CupertinoIcons.plus_circle_fill,
                label: 'معاملة جديدة',
                subtitle: 'إنشاء معاملة مالية جديدة',
                gradient: [AppTheme.primaryCyan, AppTheme.primaryBlue],
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to new transaction
                },
              ),
              _buildQuickActionItem(
                icon: CupertinoIcons.arrow_2_circlepath,
                label: 'ترحيل المعاملات',
                subtitle: 'ترحيل المعاملات المعلقة',
                gradient: [AppTheme.success, AppTheme.neonGreen],
                onTap: () {
                  Navigator.pop(context);
                  // Post pending transactions
                },
              ),
              _buildQuickActionItem(
                icon: CupertinoIcons.chart_pie_fill,
                label: 'التقارير المالية',
                subtitle: 'عرض التقارير والإحصائيات',
                gradient: [AppTheme.primaryPurple, AppTheme.primaryViolet],
                onTap: () {
                  Navigator.pop(context);
                  context.push('/admin/financial/reports');
                },
              ),
              _buildQuickActionItem(
                icon: CupertinoIcons.doc_text_search,
                label: 'مراجعة الحسابات',
                subtitle: 'مراجعة وتدقيق المعاملات',
                gradient: [AppTheme.warning, AppTheme.neonPurple],
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to audit
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

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient.map((c) => c.withOpacity(0.05)).toList(),
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gradient.first.withOpacity(0.2),
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
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.first.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
                        label,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
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
}
