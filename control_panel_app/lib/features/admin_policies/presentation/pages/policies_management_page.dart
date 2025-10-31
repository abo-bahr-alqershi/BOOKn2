import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get_it/get_it.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/empty_widget.dart';
import '../../../../services/local_storage_service.dart';
import '../../domain/entities/policy.dart';
import '../bloc/policies_bloc.dart';
import '../bloc/policies_event.dart';
import '../bloc/policies_state.dart';
import '../widgets/futuristic_policy_card.dart';
import '../widgets/futuristic_policies_table.dart';
import '../widgets/policy_filters_widget.dart';
import '../widgets/policy_stats_card.dart';

class PoliciesManagementPage extends StatefulWidget {
  const PoliciesManagementPage({super.key});

  @override
  State<PoliciesManagementPage> createState() => _PoliciesManagementPageState();
}

class _PoliciesManagementPageState extends State<PoliciesManagementPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseAnimationController;
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final _storage = GetIt.I<LocalStorageService>();

  bool _isGridView = false;
  bool _showFilters = false;
  final List<Policy> _selectedPolicies = [];
  String? _userPropertyId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _tabController = TabController(length: 6, vsync: this);
    _checkUserRoleAndLoadPolicies();
    _setupScrollListener();
  }

  void _checkUserRoleAndLoadPolicies() {
    final role = _storage.getAccountRole();
    // إذا كان Owner أو Staff، احصل على propertyId
    if (role.toLowerCase() != 'admin') {
      final propertyId = _storage.getPropertyId();
      // تمرير propertyId فقط إذا كان غير فارغ
      if (propertyId.isNotEmpty) {
        _userPropertyId = propertyId;
      }
    }
    _loadPolicies();
  }

  void _loadPolicies() {
    context.read<PoliciesBloc>().add(
          LoadPoliciesEvent(
            pageNumber: 1,
            pageSize: 20,
            propertyId: _userPropertyId, // تمرير propertyId للـ Owner/Staff
          ),
        );
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final state = context.read<PoliciesBloc>().state;
        if (state is PoliciesLoaded && state.policies.hasNextPage) {
          final nextPage = state.policies.nextPageNumber;
          if (nextPage != null) {
            context.read<PoliciesBloc>().add(
                  ChangePageEvent(
                    pageNumber: nextPage,
                  ),
                );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseAnimationController.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PoliciesBloc, PoliciesState>(
      listener: (context, state) {
        if (state is PolicyOperationInProgress && state.operation == 'delete') {
          _showDeletingDialog();
        } else if (state is PolicyOperationSuccess) {
          _dismissDeletingDialog();
          _showSnack(state.message, AppTheme.success);
        } else if (state is PolicyOperationFailure) {
          _dismissDeletingDialog();
          _showSnack(state.message, AppTheme.error);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: RefreshIndicator(
          onRefresh: () async {
            context.read<PoliciesBloc>().add(const RefreshPoliciesEvent());
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              _buildSliverAppBar(),
              _buildStatsSection(),
              _buildTabsSection(),
              _buildFilterSection(),
              _buildPoliciesList(),
            ],
          ),
        ),
      ),
    );
  }

  bool _isDeleting = false;
  void _showDeletingDialog() {
    if (_isDeleting) return;
    _isDeleting = true;
    showDialog(
      fullscreenDialog: true,
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (_) => const Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        elevation: 0,
        child: Center(
          child: LoadingWidget(
            type: LoadingType.futuristic,
            message: 'جاري حذف السياسة...',
          ),
        ),
      ),
    );
  }

  void _dismissDeletingDialog() {
    if (_isDeleting) {
      _isDeleting = false;
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: AppTheme.darkBackground,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Text(
          'السياسات',
          style: AppTextStyles.heading1.copyWith(
            color: AppTheme.textWhite,
            shadows: [
              Shadow(
                color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryPurple.withValues(alpha: 0.1),
                AppTheme.darkBackground,
              ],
            ),
          ),
        ),
      ),
      actions: [
        _buildActionButton(
          icon: _isGridView
              ? CupertinoIcons.list_bullet
              : CupertinoIcons.square_grid_2x2,
          onPressed: () => setState(() => _isGridView = !_isGridView),
        ),
        _buildActionButton(
          icon: CupertinoIcons.add,
          onPressed: () {
            context.push('/admin/policies/create');
          },
        ),
        _buildActionButton(
          icon: _showFilters
              ? CupertinoIcons.xmark
              : CupertinoIcons.slider_horizontal_3,
          onPressed: () => setState(() => _showFilters = !_showFilters),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
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
            child: Icon(
              icon,
              color: AppTheme.textWhite,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return SliverToBoxAdapter(
      child: BlocBuilder<PoliciesBloc, PoliciesState>(
        builder: (context, state) {
          // Show loading indicator while fetching stats
          if (state is PoliciesLoading ||
              (state is PoliciesLoaded && state.stats == null)) {
            return SizedBox(
              height: 120,
              child: Center(
                child: CupertinoActivityIndicator(
                  color: AppTheme.primaryBlue,
                  radius: 12,
                ),
              ),
            );
          }

          // Show stats if loaded
          if (state is PoliciesLoaded && state.stats != null) {
            return AnimationLimiter(
              child: Container(
                height: 120,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildStatsCards(state.stats!),
              ),
            );
          }

          // Hide if error or no stats
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStatsCards(PolicyStats stats) {
    // Calculate inactive policies
    final inactivePolicies = stats.totalPolicies - stats.activePolicies;
    final activePercentage = stats.totalPolicies > 0
        ? ((stats.activePolicies / stats.totalPolicies) * 100)
            .toStringAsFixed(1)
        : '0';

    return AnimationLimiter(
      child: Row(
        children: [
          Expanded(
            child: AnimationConfiguration.staggeredList(
              position: 0,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                horizontalOffset: 50.0,
                child: FadeInAnimation(
                  child: PolicyStatsCard(
                    title: 'إجمالي السياسات',
                    value: stats.totalPolicies.toString(),
                    icon: Icons.policy_rounded,
                    color: AppTheme.primaryBlue,
                    trend: '+0%',
                    isPositive: true,
                    detailedDescription: 'العدد الإجمالي للسياسات في النظام',
                    additionalStats: {
                      'سياسات نشطة': '${stats.activePolicies} سياسة',
                      'سياسات غير نشطة': '$inactivePolicies سياسة',
                      'نسبة التفعيل': '$activePercentage%',
                      ...stats.policyTypeDistribution.map(
                        (key, value) =>
                            MapEntry(_translatePolicyType(key), '$value سياسة'),
                      ),
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimationConfiguration.staggeredList(
              position: 1,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                horizontalOffset: 50.0,
                child: FadeInAnimation(
                  child: PolicyStatsCard(
                    title: 'السياسات النشطة',
                    value: stats.activePolicies.toString(),
                    icon: Icons.check_circle_rounded,
                    color: AppTheme.success,
                    trend: '${stats.activePolicies}',
                    isPositive: true,
                    detailedDescription:
                        'السياسات المفعلة والتي تُطبق حالياً على الحجوزات',
                    additionalStats: {
                      'إجمالي السياسات': '${stats.totalPolicies} سياسة',
                      'سياسات معطلة': '$inactivePolicies سياسة',
                      'نسبة النشطة': '$activePercentage%',
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimationConfiguration.staggeredList(
              position: 2,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                horizontalOffset: 50.0,
                child: FadeInAnimation(
                  child: PolicyStatsCard(
                    title: 'متوسط نافذة الإلغاء',
                    value: '${stats.averageCancellationWindow.toInt()} يوم',
                    icon: Icons.calendar_month_rounded,
                    color: AppTheme.warning,
                    trend: '${stats.averageCancellationWindow.toInt()}',
                    isPositive: true,
                    detailedDescription:
                        'متوسط المدة المسموح بها للإلغاء قبل موعد الوصول',
                    additionalStats: {
                      'إجمالي السياسات': '${stats.totalPolicies} سياسة',
                      'المتوسط بالأيام':
                          '${stats.averageCancellationWindow.toStringAsFixed(1)} يوم',
                      'المتوسط بالساعات':
                          '${(stats.averageCancellationWindow * 24).toStringAsFixed(0)} ساعة',
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(8), // ✅ هامش داخلي للـ Container
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.darkBorder.withValues(alpha: 0.3),
          ),
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          padding: const EdgeInsets.symmetric(
              horizontal: 4), // ✅ هامش جانبي للـ TabBar
          indicatorPadding: const EdgeInsets.symmetric(
              horizontal: 4, vertical: 4), // ✅ هامش للمؤشر
          labelPadding:
              const EdgeInsets.symmetric(horizontal: 12), // ✅ هامش بين الـ tabs
          indicator: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryPurple, AppTheme.primaryViolet],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: AppTextStyles.bodyMedium,
          onTap: (index) {
            PolicyType? selectedType;
            if (index > 0) {
              selectedType = PolicyType.values[index - 1];
            }
            context.read<PoliciesBloc>().add(
                  ApplyFiltersEvent(
                    propertyId:
                        _userPropertyId, // تمرير propertyId للـ Owner/Staff
                    policyType: selectedType,
                  ),
                );
          },
          tabs: [
            _buildTab('الكل', CupertinoIcons.list_bullet),
            _buildTab('الإلغاء', CupertinoIcons.xmark_circle),
            _buildTab('الدخول', CupertinoIcons.arrow_right_square),
            _buildTab('الأطفال', CupertinoIcons.person_2),
            _buildTab('الحيوانات', CupertinoIcons.paw),
            _buildTab('الدفع', CupertinoIcons.money_dollar_circle),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, IconData icon) {
    return Tab(
      height: 48, // ✅ ارتفاع ثابت للـ tab
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8), // ✅ هامش داخلي للـ tab
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return SliverToBoxAdapter(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _showFilters ? null : 0,
        child: _showFilters
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PolicyFiltersWidget(
                  onFilterChanged: (propertyId, policyType) {
                    context.read<PoliciesBloc>().add(
                          ApplyFiltersEvent(
                            propertyId: propertyId,
                            policyType: policyType,
                          ),
                        );
                  },
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildPoliciesList() {
    return BlocBuilder<PoliciesBloc, PoliciesState>(
      builder: (context, state) {
        if (state is PoliciesLoading) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: LoadingWidget(
              type: LoadingType.futuristic,
              message: 'جاري تحميل السياسات...',
            ),
          );
        }

        if (state is PoliciesError) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: CustomErrorWidget(
              message: state.message,
              onRetry: _loadPolicies,
            ),
          );
        }

        if (state is PoliciesLoaded) {
          if (state.policies.items.isEmpty) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyWidget(
                message: 'لا توجد سياسات حالياً',
                actionWidget: ElevatedButton.icon(
                  onPressed: () => context.push('/admin/policies/create'),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة سياسة جديدة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            );
          }

          // عرض الجدول على جميع الأجهزة (responsive)
          return _isGridView ? _buildGridView(state) : _buildTableView(state);
        }

        return const SliverFillRemaining(
          hasScrollBody: false,
          child: SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildGridView(PoliciesLoaded state) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final policy = state.policies.items[index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 375),
              columnCount: 2,
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: FuturisticPolicyCard(
                    policy: policy,
                    onTap: () => _navigateToDetails(policy.id),
                    onLongPress: () => _toggleSelection(policy),
                    onEdit: () => _navigateToEditPolicy(policy.id),
                    onDelete: () => _showDeleteConfirmation(policy),
                  ),
                ),
              ),
            );
          },
          childCount: state.policies.items.length,
        ),
      ),
    );
  }

  Widget _buildTableView(PoliciesLoaded state) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FuturisticPoliciesTable(
          policies: state.policies.items,
          onPolicyTap: (policyId) => _navigateToDetails(policyId),
          onEdit: (policy) => _navigateToEditPolicy(policy.id),
          onDelete: (policy) => _showDeleteConfirmation(policy),
          onSelectionChanged: (List<Policy> p1) {},
        ),
      ),
    );
  }

  // بناء كارت السياسة (مشابه لكروت الحجوزات)
  Widget _buildPolicyCard(Policy policy) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowDark.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkCard.withValues(alpha: 0.95),
                AppTheme.darkCard.withValues(alpha: 0.8),
              ],
            ),
            border: Border.all(
              color: _getPolicyTypeColor(policy.type).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToDetails(policy.id),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // رأس الكارت
                    Row(
                      children: [
                        // أيقونة النوع
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getPolicyTypeColor(policy.type),
                                _getPolicyTypeColor(policy.type)
                                    .withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getPolicyTypeIcon(policy.type),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // النوع والعقار
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getPolicyTypeLabel(policy.type),
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppTheme.textWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (policy.propertyName != null)
                                Text(
                                  policy.propertyName!,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Actions
                        PopupMenuButton(
                          icon:
                              Icon(Icons.more_vert, color: AppTheme.textMuted),
                          color: AppTheme.darkSurface,
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              onTap: () => _navigateToEditPolicy(policy.id),
                              child: Row(
                                children: [
                                  Icon(Icons.edit,
                                      size: 18, color: AppTheme.primaryBlue),
                                  const SizedBox(width: 8),
                                  Text('تعديل',
                                      style:
                                          TextStyle(color: AppTheme.textWhite)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              onTap: () => _showDeleteConfirmation(policy),
                              child: Row(
                                children: [
                                  Icon(Icons.delete,
                                      size: 18, color: AppTheme.error),
                                  const SizedBox(width: 8),
                                  Text('حذف',
                                      style:
                                          TextStyle(color: AppTheme.textWhite)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // الوصف
                    Text(
                      policy.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.textMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 16),

                    // معلومات إضافية
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (policy.cancellationWindowDays > 0)
                          _buildInfoChip(
                            icon: Icons.event_busy_rounded,
                            label: '${policy.cancellationWindowDays} يوم',
                            color: AppTheme.error,
                          ),
                        if (policy.minimumDepositPercentage > 0)
                          _buildInfoChip(
                            icon: Icons.percent_rounded,
                            label: '${policy.minimumDepositPercentage}%',
                            color: AppTheme.warning,
                          ),
                        if (policy.minHoursBeforeCheckIn > 0)
                          _buildInfoChip(
                            icon: Icons.access_time_rounded,
                            label: '${policy.minHoursBeforeCheckIn} ساعة',
                            color: AppTheme.primaryBlue,
                          ),
                        if (policy.requireFullPaymentBeforeConfirmation)
                          _buildInfoChip(
                            icon: Icons.payment_rounded,
                            label: 'دفع كامل',
                            color: AppTheme.success,
                          ),
                      ],
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

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
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

  void _navigateToDetails(String policyId) {
    context.push('/admin/policies/$policyId');
  }

  Future<void> _navigateToEditPolicy(String policyId) async {
    final result = await context.push('/admin/policies/$policyId/edit');
    if (result is Map && result['refresh'] == true) {
      _loadPolicies();
    }
  }

  void _toggleSelection(Policy policy) {
    setState(() {
      if (_selectedPolicies.contains(policy)) {
        _selectedPolicies.remove(policy);
      } else {
        _selectedPolicies.add(policy);
      }
    });
  }

  void _showDeleteConfirmation(Policy policy) {
    showDialog(
      fullscreenDialog: true,
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogCtx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.error.withOpacity(0.3),
                width: 1,
              ),
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
                  'حذف السياسة؟',
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
                        onPressed: () => Navigator.pop(dialogCtx),
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
                          Navigator.pop(dialogCtx);
                          context.read<PoliciesBloc>().add(
                                DeletePolicyEvent(policyId: policy.id),
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

  // Helper methods for policy type styling
  Color _getPolicyTypeColor(PolicyType type) {
    switch (type) {
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

  IconData _getPolicyTypeIcon(PolicyType type) {
    switch (type) {
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

  String _getPolicyTypeLabel(PolicyType type) {
    return type.displayName;
  }

  String _translatePolicyType(String type) {
    switch (type.toLowerCase()) {
      case 'cancellation':
        return 'سياسات الإلغاء';
      case 'checkin':
        return 'سياسات تسجيل الدخول';
      case 'children':
        return 'سياسات الأطفال';
      case 'pets':
        return 'سياسات الحيوانات الأليفة';
      case 'payment':
        return 'سياسات الدفع';
      case 'modification':
        return 'سياسات التعديل';
      default:
        return type;
    }
  }
}
