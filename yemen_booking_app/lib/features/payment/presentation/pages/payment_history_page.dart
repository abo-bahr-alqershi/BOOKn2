import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/enums/payment_method_enum.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';
import '../widgets/transaction_item_widget.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _backgroundAnimationController;
  late AnimationController _headerAnimationController;
  late AnimationController _statsAnimationController;
  late AnimationController _filterAnimationController;
  late AnimationController _particleAnimationController;
  late TabController _tabController;
  
  // Animations
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late List<Animation<double>> _statsAnimations;
  late Animation<double> _filterScaleAnimation;
  
  // Scroll Controller
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingHeader = false;
  
  // Filter states
  PaymentStatus? _selectedStatus;
  PaymentMethod? _selectedMethod;
  DateTimeRange? _selectedDateRange;
  
  // Statistics
  double _totalSpent = 0;
  int _totalTransactions = 0;
  double _averageTransaction = 0;
  Map<PaymentStatus, int> _statusCounts = {};
  
  // Particles
  final List<_AnimatedStar> _stars = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateStars();
    _startAnimations();
    _loadPaymentHistory();
    _scrollController.addListener(_onScroll);
    _tabController = TabController(length: 3, vsync: this);
  }

  void _initializeAnimations() {
    // Background Animation
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    // Header Animation
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));
    
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
    ));
    
    // Stats Animation
    _statsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _statsAnimations = List.generate(
      3,
      (index) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _statsAnimationController,
          curve: Interval(
            index * 0.2,
            (index * 0.2) + 0.4,
            curve: Curves.easeOutBack,
          ),
        ),
      ),
    );
    
    // Filter Animation
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _filterScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.elasticOut,
    ));
    
    // Particle Animation
    _particleAnimationController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
  }
  
  void _generateStars() {
    for (int i = 0; i < 30; i++) {
      _stars.add(_AnimatedStar());
    }
  }
  
  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _headerAnimationController.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        _statsAnimationController.forward();
        _filterAnimationController.forward();
      });
    });
  }
  
  void _onScroll() {
    final shouldShow = _scrollController.offset > 250;
    if (shouldShow != _showFloatingHeader) {
      setState(() {
        _showFloatingHeader = shouldShow;
      });
    }
    
    // Load more when reaching bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _loadMoreTransactions();
    }
  }
  
  void _loadPaymentHistory() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<PaymentBloc>().add(
        GetPaymentHistoryEvent(
          userId: authState.user.userId,
          status: _selectedStatus?.name,
          paymentMethod: _selectedMethod?.name,
          fromDate: _selectedDateRange?.start,
          toDate: _selectedDateRange?.end,
        ),
      );
    }
  }
  
  void _loadMoreTransactions() {
    final state = context.read<PaymentBloc>().state;
    if (state is PaymentHistoryLoaded && !state.isLoadingMore && state.hasMore) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        context.read<PaymentBloc>().add(
          LoadMorePaymentHistoryEvent(
            userId: authState.user.userId,
            status: _selectedStatus?.name,
            paymentMethod: _selectedMethod?.name,
            fromDate: _selectedDateRange?.start,
            toDate: _selectedDateRange?.end,
          ),
        );
      }
    }
  }
  
  void _calculateStatistics(List<Transaction> transactions) {
    _totalTransactions = transactions.length;
    _totalSpent = transactions
        .where((t) => t.isSuccessful)
        .fold(0, (sum, t) => sum + t.totalAmount);
    _averageTransaction = _totalTransactions > 0 
        ? _totalSpent / _totalTransactions 
        : 0;
    
    // Count by status
    _statusCounts = {};
    for (var transaction in transactions) {
      _statusCounts[transaction.status] = 
          (_statusCounts[transaction.status] ?? 0) + 1;
    }
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _headerAnimationController.dispose();
    _statsAnimationController.dispose();
    _filterAnimationController.dispose();
    _particleAnimationController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
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
          
          // Animated Stars
          _buildAnimatedStars(),
          
          // Main Content
          NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildFuturisticAppBar(),
              _buildStatisticsSection(),
              _buildFilterSection(),
            ],
            body: _buildTransactionsList(),
          ),
          
          // Floating Header
          if (_showFloatingHeader) _buildFloatingHeader(),
          
          // Export FAB
          _buildExportFAB(),
        ],
      ),
    );
  }
  
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                math.cos(_backgroundAnimationController.value * 2 * math.pi),
                math.sin(_backgroundAnimationController.value * 2 * math.pi),
              ),
              end: Alignment(
                -math.cos(_backgroundAnimationController.value * 2 * math.pi),
                -math.sin(_backgroundAnimationController.value * 2 * math.pi),
              ),
              colors: [
                AppTheme.darkBackground,
                AppTheme.darkBackground2,
                AppTheme.darkBackground3.withOpacity(0.8),
              ],
            ),
          ),
          child: CustomPaint(
            painter: _GridPatternPainter(
              animationValue: _backgroundAnimationController.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
  
  Widget _buildAnimatedStars() {
    return AnimatedBuilder(
      animation: _particleAnimationController,
      builder: (context, child) {
        return CustomPaint(
          painter: _StarPainter(
            stars: _stars,
            animationValue: _particleAnimationController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
  
  Widget _buildFuturisticAppBar() {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: AnimatedBuilder(
          animation: _headerFadeAnimation,
          builder: (context, child) {
            return FadeTransition(
              opacity: _headerFadeAnimation,
              child: SlideTransition(
                position: _headerSlideAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primaryBlue.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative Elements
                      Positioned(
                        right: -50,
                        top: 50,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppTheme.primaryPurple.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      Positioned(
                        left: -30,
                        bottom: 30,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppTheme.primaryCyan.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Center Content
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppTheme.primaryGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryBlue.withOpacity(0.5),
                                    blurRadius: 30,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    color: AppTheme.darkCard.withOpacity(0.3),
                                    child: const Icon(
                                      Icons.history,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppTheme.primaryGradient.createShader(bounds),
                              child: Text(
                                'سجل المدفوعات',
                                style: AppTextStyles.displaySmall.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            Text(
                              'تتبع جميع معاملاتك المالية',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppTheme.textMuted,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      leading: _buildGlassBackButton(),
      actions: [
        _buildGlassActionButton(
          icon: Icons.filter_list,
          onPressed: _showAdvancedFilters,
        ),
      ],
    );
  }
  
  Widget _buildGlassBackButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkCard.withOpacity(0.6),
                  AppTheme.darkCard.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              color: AppTheme.textWhite,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildGlassActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkCard.withOpacity(0.6),
                  AppTheme.darkCard.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(icon, size: 20),
              color: AppTheme.textWhite,
              onPressed: onPressed,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatisticsSection() {
    return SliverToBoxAdapter(
      child: BlocBuilder<PaymentBloc, PaymentState>(
        builder: (context, state) {
          if (state is PaymentHistoryLoaded) {
            _calculateStatistics(state.transactions);
          }
          
          return Container(
            height: 140,
            margin: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: AnimatedBuilder(
                    animation: _statsAnimations[0],
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _statsAnimations[0].value,
                                                  child: Opacity(
                            opacity: _statsAnimations[0].value.clamp(0.0, 1.0).toDouble(),
                            child: _buildFuturisticStatCard(
                            icon: Icons.account_balance_wallet,
                            title: 'إجمالي المصروفات',
                            value: '${_totalSpent.toStringAsFixed(0)} ريال',
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryBlue,
                                AppTheme.primaryBlue.withOpacity(0.7),
                              ],
                            ),
                            iconColor: AppTheme.primaryBlue,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _statsAnimations[1],
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _statsAnimations[1].value,
                                                  child: Opacity(
                            opacity: _statsAnimations[1].value.clamp(0.0, 1.0).toDouble(),
                            child: _buildFuturisticStatCard(
                            icon: Icons.receipt_long,
                            title: 'عدد المعاملات',
                            value: _totalTransactions.toString(),
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryPurple,
                                AppTheme.primaryPurple.withOpacity(0.7),
                              ],
                            ),
                            iconColor: AppTheme.primaryPurple,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _statsAnimations[2],
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _statsAnimations[2].value,
                                                  child: Opacity(
                            opacity: _statsAnimations[2].value.clamp(0.0, 1.0).toDouble(),
                            child: _buildFuturisticStatCard(
                            icon: Icons.trending_up,
                            title: 'متوسط المعاملة',
                            value: '${_averageTransaction.toStringAsFixed(0)} ريال',
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryCyan,
                                AppTheme.primaryCyan.withOpacity(0.7),
                              ],
                            ),
                            iconColor: AppTheme.primaryCyan,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildFuturisticStatCard({
    required IconData icon,
    required String title,
    required String value,
    required LinearGradient gradient,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.6),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: iconColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              ShaderMask(
                shaderCallback: (bounds) => gradient.createShader(bounds),
                child: Text(
                  value,
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFilterSection() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _filterScaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _filterScaleAnimation.value,
            child: Container(
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildFuturisticFilterChip(
                    label: 'الكل',
                    isSelected: _selectedStatus == null && _selectedMethod == null,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedStatus = null;
                        _selectedMethod = null;
                      });
                      _loadPaymentHistory();
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFuturisticFilterChip(
                    label: 'ناجحة',
                    isSelected: _selectedStatus == PaymentStatus.successful,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedStatus = PaymentStatus.successful;
                      });
                      _loadPaymentHistory();
                    },
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: 8),
                  _buildFuturisticFilterChip(
                    label: 'معلقة',
                    isSelected: _selectedStatus == PaymentStatus.pending,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedStatus = PaymentStatus.pending;
                      });
                      _loadPaymentHistory();
                    },
                    color: AppTheme.warning,
                  ),
                  const SizedBox(width: 8),
                  _buildFuturisticFilterChip(
                    label: 'فاشلة',
                    isSelected: _selectedStatus == PaymentStatus.failed,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedStatus = PaymentStatus.failed;
                      });
                      _loadPaymentHistory();
                    },
                    color: AppTheme.error,
                  ),
                  const SizedBox(width: 8),
                  _buildFuturisticFilterChip(
                    label: 'التاريخ',
                    icon: Icons.calendar_today,
                    isSelected: _selectedDateRange != null,
                    onTap: _selectDateRange,
                  ),
                  const SizedBox(width: 8),
                  _buildFuturisticFilterChip(
                    label: 'طريقة الدفع',
                    icon: Icons.payment,
                    isSelected: _selectedMethod != null,
                    onTap: _selectPaymentMethod,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildFuturisticFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    color ?? AppTheme.primaryBlue,
                    (color ?? AppTheme.primaryBlue).withOpacity(0.7),
                  ],
                )
              : null,
          color: !isSelected ? AppTheme.darkCard.withOpacity(0.5) : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (color ?? AppTheme.primaryBlue)
                : AppTheme.darkBorder.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (color ?? AppTheme.primaryBlue).withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppTheme.textMuted,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? Colors.white : AppTheme.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTransactionsList() {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        if (state is PaymentHistoryLoading) {
          return Center(
            child: _buildFuturisticLoader(),
          );
        }

        if (state is PaymentError) {
          return Center(
            child: _buildFuturisticError(state),
          );
        }

        if (state is PaymentHistoryLoaded) {
          if (state.transactions.isEmpty) {
            return Center(
              child: _buildFuturisticEmpty(),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadPaymentHistory(),
            color: AppTheme.primaryBlue,
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: state.transactions.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.transactions.length) {
                  return Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  );
                }

                final transaction = state.transactions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TransactionItemWidget(
                    transaction: transaction,
                    onTap: () => _showTransactionDetails(transaction),
                  ),
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
  
  Widget _buildFuturisticLoader() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ShaderMask(
          shaderCallback: (bounds) =>
              AppTheme.primaryGradient.createShader(bounds),
          child: Text(
            'جاري تحميل السجل...',
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFuturisticError(PaymentError state) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.8),
            AppTheme.darkCard.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppTheme.error.withOpacity(0.2),
                  AppTheme.error.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 40,
              color: AppTheme.error,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'حدث خطأ',
            style: AppTextStyles.heading2.copyWith(
              color: AppTheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            state.message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _loadPaymentHistory,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'إعادة المحاولة',
                        style: AppTextStyles.buttonMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFuturisticEmpty() {
    return Container(
      margin: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.1),
                  AppTheme.primaryBlue.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long,
              size: 60,
              color: AppTheme.primaryBlue.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد معاملات',
            style: AppTextStyles.heading2.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم تقم بأي معاملات مالية بعد',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFloatingHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withOpacity(0.95),
              AppTheme.darkCard.withOpacity(0.85),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: SafeArea(
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildGlassBackButton(),
                    const SizedBox(width: 16),
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppTheme.primaryGradient.createShader(bounds),
                      child: Text(
                        'سجل المدفوعات',
                        style: AppTextStyles.heading3.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_totalTransactions معاملة',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildExportFAB() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _exportTransactions,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.download,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'تصدير',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
  
  void _selectDateRange() async {
    HapticFeedback.lightImpact();
    
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              surface: AppTheme.darkCard,
              onSurface: AppTheme.textWhite,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      _loadPaymentHistory();
    }
  }
  
  void _selectPaymentMethod() {
    HapticFeedback.lightImpact();
    _showPaymentMethodSelector();
  }
  
  void _showPaymentMethodSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _buildPaymentMethodModal(ctx),
    );
  }
  
  Widget _buildPaymentMethodModal(BuildContext ctx) {
    return Container(
      height: MediaQuery.of(ctx).size.height * 0.6,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.darkCard,
            AppTheme.darkSurface,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'اختر طريقة الدفع',
                  style: AppTextStyles.heading2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                  ),
                ),
              ),
              
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: PaymentMethod.values.map((method) {
                    final isSelected = _selectedMethod == method;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _selectedMethod = method;
                          });
                          Navigator.pop(ctx);
                          _loadPaymentHistory();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? AppTheme.primaryGradient
                                : LinearGradient(
                                    colors: [
                                      AppTheme.darkCard.withOpacity(0.5),
                                      AppTheme.darkCard.withOpacity(0.3),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : AppTheme.darkBorder.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryBlue.withOpacity(0.4),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getMethodIcon(method),
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textMuted,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                method.displayNameAr,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textWhite,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              if (isSelected) ...[
                                const Spacer(),
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showTransactionDetails(Transaction transaction) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _buildTransactionDetailsModal(ctx, transaction),
    );
  }
  
  Widget _buildTransactionDetailsModal(BuildContext ctx, Transaction transaction) {
    return Container(
      height: MediaQuery.of(ctx).size.height * 0.8,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.darkCard,
            AppTheme.darkSurface,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'تفاصيل المعاملة',
                            style: AppTextStyles.heading2.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textWhite,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                            color: AppTheme.textMuted,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Transaction Info Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getStatusColor(transaction.status).withOpacity(0.1),
                              _getStatusColor(transaction.status).withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(transaction.status).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _getStatusIcon(transaction.status),
                              size: 50,
                              color: _getStatusColor(transaction.status),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              transaction.status.displayNameAr,
                              style: AppTextStyles.heading3.copyWith(
                                color: _getStatusColor(transaction.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${transaction.totalAmount.toStringAsFixed(2)} ${transaction.currency}',
                              style: AppTextStyles.displaySmall.copyWith(
                                color: AppTheme.textWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Details List
                      _buildDetailItem(
                        icon: Icons.tag,
                        label: 'رقم المعاملة',
                        value: transaction.transactionId ?? 'غير متوفر',
                      ),
                      _buildDetailItem(
                        icon: Icons.confirmation_number,
                        label: 'رقم الحجز',
                        value: transaction.bookingNumber,
                      ),
                      _buildDetailItem(
                        icon: Icons.home,
                        label: 'اسم العقار',
                        value: transaction.propertyName,
                      ),
                      _buildDetailItem(
                        icon: Icons.meeting_room,
                        label: 'الوحدة',
                        value: transaction.unitName,
                      ),
                      _buildDetailItem(
                        icon: Icons.payment,
                        label: 'طريقة الدفع',
                        value: transaction.paymentMethod.displayNameAr,
                      ),
                      _buildDetailItem(
                        icon: Icons.calendar_today,
                        label: 'التاريخ',
                        value: DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Price Breakdown
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.darkCard.withOpacity(0.5),
                              AppTheme.darkCard.withOpacity(0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.darkBorder.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تفاصيل السعر',
                              style: AppTextStyles.heading3.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildPriceRow('المبلغ الأساسي', transaction.amount),
                            _buildPriceRow('الرسوم', transaction.fees),
                            _buildPriceRow('الضرائب', transaction.taxes),
                            Divider(color: AppTheme.darkBorder),
                            _buildPriceRow(
                              'المجموع',
                              transaction.totalAmount,
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Action Buttons
                      if (transaction.canRefund)
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.warning,
                                AppTheme.warning.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.warning.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _requestRefund(transaction),
                              borderRadius: BorderRadius.circular(16),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.replay,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'طلب استرداد',
                                      style: AppTextStyles.buttonLarge.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.2),
                  AppTheme.primaryBlue.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isTotal ? AppTheme.textWhite : AppTheme.textMuted,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} ريال',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isTotal ? AppTheme.primaryBlue : AppTheme.textWhite,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showAdvancedFilters() {
    HapticFeedback.mediumImpact();
    // Implementation for advanced filters
  }
  
  void _requestRefund(Transaction transaction) {
    HapticFeedback.mediumImpact();
    // Implementation for refund request
  }
  
  void _exportTransactions() {
    HapticFeedback.mediumImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'جاري تصدير البيانات...',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: AppTheme.primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  IconData _getMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.creditCard:
        return Icons.credit_card;
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.paypal:
        return Icons.payment;
      default:
        return Icons.account_balance_wallet;
    }
  }
  
  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.successful:
        return AppTheme.success;
      case PaymentStatus.failed:
        return AppTheme.error;
      case PaymentStatus.pending:
        return AppTheme.warning;
      case PaymentStatus.refunded:
      case PaymentStatus.partiallyRefunded:
        return AppTheme.info;
      case PaymentStatus.voided:
        return AppTheme.textMuted;
    }
  }
  
  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.successful:
        return Icons.check_circle;
      case PaymentStatus.failed:
        return Icons.cancel;
      case PaymentStatus.pending:
        return Icons.hourglass_empty;
      case PaymentStatus.refunded:
      case PaymentStatus.partiallyRefunded:
        return Icons.replay;
      case PaymentStatus.voided:
        return Icons.block;
    }
  }
}

// Grid Pattern Painter
class _GridPatternPainter extends CustomPainter {
  final double animationValue;
  
  _GridPatternPainter({required this.animationValue});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3;
    
    const spacing = 40.0;
    final offset = animationValue * spacing;
    
    // Create gradient effect
    paint.shader = LinearGradient(
      colors: [
        AppTheme.primaryBlue.withOpacity(0.05),
        AppTheme.primaryPurple.withOpacity(0.03),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // Draw diagonal lines
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i + offset, 0),
        Offset(i + offset - size.height, size.height),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Animated Star Model
class _AnimatedStar {
  late double x;
  late double y;
  late double size;
  late double opacity;
  late double twinkleSpeed;
  
  _AnimatedStar() {
    reset();
  }
  
  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    size = math.Random().nextDouble() * 2 + 1;
    opacity = math.Random().nextDouble() * 0.5 + 0.2;
    twinkleSpeed = math.Random().nextDouble() * 2 + 1;
  }
  
  void update(double animationValue) {
    opacity = 0.2 + 0.5 * math.sin(animationValue * twinkleSpeed * 2 * math.pi).abs();
  }
}

// Star Painter
class _StarPainter extends CustomPainter {
  final List<_AnimatedStar> stars;
  final double animationValue;
  
  _StarPainter({
    required this.stars,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    for (var star in stars) {
      star.update(animationValue);
      
      final paint = Paint()
        ..color = AppTheme.textWhite.withOpacity(star.opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}