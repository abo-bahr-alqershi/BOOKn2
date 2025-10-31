// lib/features/admin_users/presentation/pages/users_list_page.dart

import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:bookn_cp_app/core/widgets/loading_widget.dart';
import 'package:bookn_cp_app/features/admin_users/domain/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:bookn_cp_app/core/theme/app_colors.dart';
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';
import '../bloc/users_list/users_list_bloc.dart';
import '../widgets/futuristic_users_table.dart';
import '../widgets/user_filters_widget.dart';
import '../widgets/user_stats_card.dart';
import '../widgets/last_seen_widget.dart';

class UsersListPage extends StatefulWidget {
  const UsersListPage({super.key});

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _backgroundAnimationController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late AnimationController _contentAnimationController;

  // Animations
  late Animation<double> _backgroundRotation;
  late Animation<double> _glowAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;

  // State
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;
  String _selectedView = 'table'; // table, grid, chart

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUsers();
    _setupScrollListener();
  }

  void _initializeAnimations() {
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _particleController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _backgroundRotation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _backgroundAnimationController,
      curve: Curves.linear,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _contentFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOut,
    ));

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOutQuart,
    ));

    // Start animations
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _contentAnimationController.forward();
      }
    });
  }

  void _loadUsers() {
    context.read<UsersListBloc>().add(LoadUsersEvent());
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.9) {
        final state = context.read<UsersListBloc>().state;
        if (state is UsersListLoaded && state.hasMore && !state.isLoadingMore) {
          context.read<UsersListBloc>().add(LoadMoreUsersEvent());
        }
      }
    });
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _contentAnimationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<UsersListBloc>().add(RefreshUsersEvent());
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
          _buildSliverAppBar(),
          _buildStatsSliver(),
          _buildSearchSliver(),
          _buildFiltersSliver(),
          _buildContentSliver(),
          ],
        ),
      ),
      floatingActionButton: _buildFabButton(),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: AppTheme.darkBackground,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Text(
          'إدارة المستخدمين',
          style: AppTextStyles.heading1.copyWith(
            color: AppTheme.textWhite,
            shadows: [
              Shadow(
                color: AppTheme.primaryBlue.withOpacity(0.3),
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
                AppTheme.primaryBlue.withOpacity(0.1),
                AppTheme.darkBackground,
              ],
            ),
          ),
        ),
      ),
      actions: [
        _buildHeaderAction(
            icon: Icons.grid_view_rounded,
            isActive: _selectedView == 'grid',
            onPressed: () => setState(() => _selectedView = 'grid')),
        _buildHeaderAction(
            icon: Icons.table_chart_rounded,
            isActive: _selectedView == 'table',
            onPressed: () => setState(() => _selectedView = 'table')),
        _buildHeaderAction(
            icon: Icons.analytics_rounded,
            isActive: _selectedView == 'chart',
            onPressed: () => setState(() => _selectedView = 'chart')),
        _buildHeaderAction(
            icon:
                _showFilters ? Icons.close_rounded : Icons.filter_list_rounded,
            isActive: _showFilters,
            onPressed: () => setState(() => _showFilters = !_showFilters)),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isActive ? AppTheme.primaryBlue : AppTheme.darkBorder)
              .withOpacity(0.3),
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
              color: isActive ? AppTheme.primaryBlue : AppTheme.textWhite,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildStatsSliver() {
    return SliverToBoxAdapter(
      child: Container(
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: BlocBuilder<UsersListBloc, UsersListState>(
          builder: (context, state) {
            final totalUsers = state is UsersListLoaded ? state.totalCount : 0;
            final activeUsers = state is UsersListLoaded
                ? state.users.where((u) => u.isActive).length
                : 0;
            final newUsers =
                state is UsersListLoaded ? _getNewUsersCount(state.users) : 0;
            final inactiveUsers = state is UsersListLoaded
                ? state.users.where((u) => !u.isActive).length
                : 0;
            return Row(
              children: [
                Expanded(
                    child: UserStatsCard(
                        title: 'إجمالي المستخدمين',
                        value: totalUsers.toString(),
                        icon: Icons.people_rounded,
                        color: AppTheme.primaryBlue,
                        trend: '+15%',
                        isPositive: true)),
                const SizedBox(width: 12),
                Expanded(
                    child: UserStatsCard(
                        title: 'المستخدمين النشطين',
                        value: activeUsers.toString(),
                        icon: Icons.verified_user_rounded,
                        color: AppTheme.success,
                        trend: '+8%',
                        isPositive: true)),
                const SizedBox(width: 12),
                Expanded(
                    child: UserStatsCard(
                        title: 'المستخدمين الجدد',
                        value: newUsers.toString(),
                        icon: Icons.person_add_rounded,
                        color: AppTheme.warning,
                        trend: '12',
                        isPositive: true)),
                const SizedBox(width: 12),
                Expanded(
                    child: UserStatsCard(
                        title: 'غير النشطين',
                        value: inactiveUsers.toString(),
                        icon: Icons.person_off_rounded,
                        color: AppTheme.error,
                        trend: '-3%',
                        isPositive: false)),
              ],
            );
          },
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildSearchSliver() {
    return SliverToBoxAdapter(child: _buildSearchBar());
  }

  SliverToBoxAdapter _buildFiltersSliver() {
    return SliverToBoxAdapter(child: _buildFiltersSection());
  }

  Widget _buildFabButton() {
    return FloatingActionButton(
      onPressed: () async {
        await context.push('/admin/users/create');
        if (!mounted) return;
        context.read<UsersListBloc>().add(RefreshUsersEvent());
      },
      backgroundColor: AppTheme.primaryBlue,
      child: const Icon(
        Icons.person_add_rounded,
        color: Colors.white,
      ),
    );
  }

  Widget _buildContentSliver() {
    return BlocBuilder<UsersListBloc, UsersListState>(
      builder: (context, state) {
        if (state is UsersRefreshing) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: LoadingWidget(
                type: LoadingType.futuristic,
                message: 'جاري تحديث القائمة...',
              ),
            ),
          );
        }
        if (state is UsersListLoading) {
          return const SliverFillRemaining(
            child: LoadingWidget(
              type: LoadingType.futuristic,
              message: 'جاري تحميل المستخدمين...',
            ),
          );
        }
        if (state is UsersListError) {
          return SliverFillRemaining(
            child: _buildErrorState(state.message),
          );
        }
        if (state is UsersListLoaded) {
          if (state.users.isEmpty) {
            return const SliverFillRemaining(
              child: SizedBox.shrink(),
            );
          }
          switch (_selectedView) {
            case 'grid':
              return _buildGridSliver(state);
            case 'table':
              return SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: FuturisticUsersTable(
                    users: state.users,
                    onUserTap: (userId) => _navigateToUserDetails(userId),
                    onStatusToggle: (userId, activate) {
                      context.read<UsersListBloc>().add(
                            ToggleUserStatusEvent(
                                userId: userId, activate: activate),
                          );
                    },
                    onDelete: (userId) => _showDeleteConfirmation(userId),
                  ),
                ),
              );
            case 'chart':
              return SliverToBoxAdapter(child: _buildChartView(state));
            default:
              return _buildGridSliver(state);
          }
        }
        return const SliverFillRemaining(child: SizedBox.shrink());
      },
    );
  }

  SliverPadding _buildGridSliver(UsersListLoaded state) {
    // Compute responsive columns
    int crossAxisCount = 4;
    final width = MediaQuery.of(context).size.width;
    if (width < 1200) crossAxisCount = 3;
    if (width < 900) crossAxisCount = 2;
    if (width < 600) crossAxisCount = 1;

    final itemCount = state.users.length + (state.hasMore ? 1 : 0);

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= state.users.length) {
              return _buildLoadMoreIndicator();
            }
            final user = state.users[index];
            return _UserGridCard(
              user: user,
              onTap: () => _navigateToUserDetails(user.id),
              onEdit: () => _navigateToEditUser(user.id),
              onDelete: () => _showDeleteConfirmation(user.id),
              onStatusToggle: (activate) {
                context.read<UsersListBloc>().add(
                      ToggleUserStatusEvent(
                          userId: user.id, activate: activate),
                    );
              },
            );
          },
          childCount: itemCount,
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([_backgroundRotation, _glowAnimation]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkBackground,
                AppTheme.darkBackground2.withOpacity(0.8),
                AppTheme.darkBackground3.withOpacity(0.6),
              ],
            ),
          ),
          child: CustomPaint(
            painter: _FuturisticBackgroundPainter(
              rotation: _backgroundRotation.value,
              glowIntensity: _glowAnimation.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.7),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: [
              // Title with gradient
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppTheme.primaryGradient.createShader(bounds),
                      child: Text(
                        'إدارة المستخدمين',
                        style: AppTextStyles.heading1.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'إدارة جميع حسابات المستخدمين والصلاحيات',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildActionButton(
                        icon: Icons.filter_list_rounded,
                        label: 'فلتر',
                        onTap: () =>
                            setState(() => _showFilters = !_showFilters),
                        isActive: _showFilters,
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.grid_view_rounded,
                        label: 'شبكة',
                        onTap: () => setState(() => _selectedView = 'grid'),
                        isActive: _selectedView == 'grid',
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.table_chart_rounded,
                        label: 'جدول',
                        onTap: () => setState(() => _selectedView = 'table'),
                        isActive: _selectedView == 'table',
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.analytics_rounded,
                        label: 'إحصائيات',
                        onTap: () => setState(() => _selectedView = 'chart'),
                        isActive: _selectedView == 'chart',
                      ),
                      const SizedBox(width: 16),
                      _buildPrimaryActionButton(
                        icon: Icons.person_add_rounded,
                        label: 'إضافة مستخدم',
                        onTap: () async {
                          await context.push('/admin/users/create');
                          if (!mounted) return;
                          context.read<UsersListBloc>().add(RefreshUsersEvent());
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.file_download_outlined,
                        label: 'تصدير',
                        onTap: _exportUsers,
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
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
          gradient: isActive
              ? AppTheme.primaryGradient
              : LinearGradient(
                  colors: [
                    AppTheme.darkCard.withOpacity(0.5),
                    AppTheme.darkCard.withOpacity(0.3),
                  ],
                ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppTheme.primaryBlue.withOpacity(0.5)
                : AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isActive ? Colors.white : AppTheme.textMuted,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.buttonMedium.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      child: BlocBuilder<UsersListBloc, UsersListState>(
        builder: (context, state) {
          final totalUsers = state is UsersListLoaded ? state.totalCount : 0;
          final activeUsers = state is UsersListLoaded
              ? state.users.where((u) => u.isActive).length
              : 0;
          final newUsers =
              state is UsersListLoaded ? _getNewUsersCount(state.users) : 0;
          final inactiveUsers = state is UsersListLoaded
              ? state.users.where((u) => !u.isActive).length
              : 0;

          return Row(
            children: [
              Expanded(
                child: UserStatsCard(
                  title: 'إجمالي المستخدمين',
                  value: totalUsers.toString(),
                  icon: Icons.people_rounded,
                  color: AppTheme.primaryBlue,
                  trend: '+15%',
                  isPositive: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: UserStatsCard(
                  title: 'المستخدمين النشطين',
                  value: activeUsers.toString(),
                  icon: Icons.verified_user_rounded,
                  color: AppTheme.success,
                  trend: '+8%',
                  isPositive: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: UserStatsCard(
                  title: 'المستخدمين الجدد',
                  value: newUsers.toString(),
                  icon: Icons.person_add_rounded,
                  color: AppTheme.warning,
                  trend: '12',
                  isPositive: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: UserStatsCard(
                  title: 'غير النشطين',
                  value: inactiveUsers.toString(),
                  icon: Icons.person_off_rounded,
                  color: AppTheme.error,
                  trend: '-3%',
                  isPositive: false,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.5),
            AppTheme.darkCard.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(
            Icons.search_rounded,
            color: AppTheme.primaryBlue.withOpacity(0.7),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite,
              ),
              decoration: InputDecoration(
                hintText: 'البحث عن مستخدم...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textMuted.withOpacity(0.5),
                ),
                border: InputBorder.none,
              ),
              onSubmitted: (value) {
                context.read<UsersListBloc>().add(
                      SearchUsersEvent(searchTerm: value),
                    );
              },
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                context.read<UsersListBloc>().add(LoadUsersEvent());
              },
              icon: Icon(
                Icons.clear_rounded,
                color: AppTheme.textMuted,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _showFilters ? 80 : 0,
      child: SingleChildScrollView(
        child: UserFiltersWidget(
          onApplyFilters: (filters) {
            context.read<UsersListBloc>().add(
                  FilterUsersEvent(
                    roleId: filters['roleId'],
                    isActive: filters['isActive'],
                    createdAfter: filters['createdAfter'],
                    createdBefore: filters['createdBefore'],
                  ),
                );
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<UsersListBloc, UsersListState>(
      builder: (context, state) {
        if (state is UsersListLoading) {
          return _buildLoadingState();
        }

        if (state is UsersListError) {
          return _buildErrorState(state.message);
        }

        if (state is UsersListLoaded) {
          if (state.users.isEmpty) {
            return _buildEmptyState();
          }

          switch (_selectedView) {
            case 'grid':
              return _buildGridView(state);
            case 'table':
              return FuturisticUsersTable(
                users: state.users,
                onUserTap: (userId) => _navigateToUserDetails(userId),
                onStatusToggle: (userId, activate) {
                  context.read<UsersListBloc>().add(
                        ToggleUserStatusEvent(
                          userId: userId,
                          activate: activate,
                        ),
                      );
                },
                onDelete: (userId) {
                  _showDeleteConfirmation(userId);
                },
              );
            case 'chart':
              return _buildChartView(state);
            default:
              return _buildGridView(state);
          }
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildGridView(UsersListLoaded state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // حساب عدد الأعمدة بناءً على عرض الشاشة
        int crossAxisCount = 4;
        if (constraints.maxWidth < 1200) {
          crossAxisCount = 3;
        }
        if (constraints.maxWidth < 900) {
          crossAxisCount = 2;
        }
        if (constraints.maxWidth < 600) {
          crossAxisCount = 1;
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<UsersListBloc>().add(RefreshUsersEvent());
          },
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: state.users.length + (state.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.users.length) {
                return _buildLoadMoreIndicator();
              }

              final user = state.users[index];
              return _UserGridCard(
                user: user,
                onTap: () => _navigateToUserDetails(user.id),
                onEdit: () => _navigateToEditUser(user.id),
                onDelete: () => _showDeleteConfirmation(user.id),
                onStatusToggle: (activate) {
                  context.read<UsersListBloc>().add(
                        ToggleUserStatusEvent(
                          userId: user.id,
                          activate: activate,
                        ),
                      );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildChartView(UsersListLoaded state) {
    // TODO: Implement chart view
    return const Center(
      child: Text('Chart View - Coming Soon'),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل المستخدمين...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppTheme.error.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _loadUsers,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'إعادة المحاولة',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.1),
                  AppTheme.primaryPurple.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: AppTheme.primaryBlue.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا يوجد مستخدمين',
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم يتم العثور على أي مستخدمين',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => context.push('/admin/users/create'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'إضافة أول مستخدم',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: const Center(
        child: LoadingWidget(
            type: LoadingType.futuristic, message: 'جاري التحميل...'),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Positioned(
      bottom: 24,
      right: 24,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue
                      .withOpacity(0.4 * _glowAnimation.value),
                  blurRadius: 20 + 10 * _glowAnimation.value,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () => context.push('/admin/users/create'),
              backgroundColor: AppTheme.primaryBlue,
              child: const Icon(
                Icons.person_add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToUserDetails(String userId) {
    context.push('/admin/users/$userId');
  }

  Future<void> _navigateToEditUser(String userId) async {
    await context.push('/admin/users/$userId/edit');
    if (!mounted) return;
    context.read<UsersListBloc>().add(RefreshUsersEvent());
  }

  void _showDeleteConfirmation(String userId) {
    HapticFeedback.mediumImpact();
    showDialog(
      fullscreenDialog: true,
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => BackdropFilter(
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
                  'حذف المستخدم؟',
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
                        onPressed: () => Navigator.pop(context),
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
                          Navigator.pop(context);
                          context
                              .read<UsersListBloc>()
                              .add(DeleteUserEvent(userId));
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

  int _getNewUsersCount(List<User> users) {
    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));
    return users.where((user) {
      return user.createdAt.isAfter(lastWeek);
    }).length;
  }

  void _exportUsers() {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('جاري تصدير البيانات...'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }
}

// User Grid Card Widget
class _UserGridCard extends StatefulWidget {
  final User user;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(bool) onStatusToggle;

  const _UserGridCard({
    required this.user,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusToggle,
  });

  @override
  State<_UserGridCard> createState() => _UserGridCardState();
}

class _UserGridCardState extends State<_UserGridCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _hoverAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _hoverAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isHovered
                        ? [
                            AppTheme.primaryBlue.withOpacity(0.1),
                            AppTheme.primaryPurple.withOpacity(0.05),
                          ]
                        : [
                            AppTheme.darkCard.withOpacity(0.7),
                            AppTheme.darkCard.withOpacity(0.5),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isHovered
                        ? AppTheme.primaryBlue.withOpacity(0.5)
                        : AppTheme.darkBorder.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isHovered
                          ? AppTheme.primaryBlue.withOpacity(0.2)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: _isHovered ? 20 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Stack(
                      children: [
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Avatar
                              Flexible(
                                flex: 2,
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: widget.user.profileImage != null
                                        ? null
                                        : AppTheme.primaryGradient,
                                    border: Border.all(
                                      color: widget.user.isActive
                                          ? AppTheme.success.withOpacity(0.5)
                                          : AppTheme.textMuted.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: widget.user.profileImage != null &&
                                          widget.user.profileImage!
                                              .trim()
                                              .isNotEmpty
                                      ? ClipOval(
                                          child: Image.network(
                                            widget.user.profileImage!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return _buildDefaultAvatar(
                                                  widget.user.name);
                                            },
                                          ),
                                        )
                                      : _buildDefaultAvatar(widget.user.name),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Name
                              Flexible(
                                child: Text(
                                  widget.user.name,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppTheme.textWhite,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              const SizedBox(height: 4),

                              // Email
                              Flexible(
                                child: Text(
                                  widget.user.email,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Last Seen Widget
                              LastSeenWidget(
                                lastSeen: widget.user.lastSeen,
                                style: LastSeenStyle.compact,
                                showIcon: true,
                                showAnimation: true,
                              ),

                              const Spacer(),

                              // Role Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _getRoleGradient(widget.user.role),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getRoleText(widget.user.role),
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Status Indicator
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.user.isActive
                                  ? AppTheme.success
                                  : AppTheme.textMuted,
                              boxShadow: widget.user.isActive
                                  ? [
                                      BoxShadow(
                                        color:
                                            AppTheme.success.withOpacity(0.5),
                                        blurRadius: 6,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),

                        // Action Buttons (on hover)
                        if (_isHovered)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            right: 8,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildActionIcon(
                                  widget.user.isActive
                                      ? Icons.toggle_off_rounded
                                      : Icons.toggle_on_rounded,
                                  () => widget
                                      .onStatusToggle(!widget.user.isActive),
                                  color: widget.user.isActive
                                      ? AppTheme.warning
                                      : AppTheme.success,
                                ),
                                _buildActionIcon(
                                  Icons.edit_rounded,
                                  widget.onEdit,
                                ),
                                _buildActionIcon(
                                  Icons.delete_rounded,
                                  widget.onDelete,
                                  color: AppTheme.error,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Center(
      child: Text(
        initial,
        style: AppTextStyles.heading3.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionIcon(
    IconData icon,
    VoidCallback onTap, {
    Color? color,
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
          color: AppTheme.darkBackground.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (color ?? AppTheme.primaryBlue).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: color ?? AppTheme.primaryBlue,
        ),
      ),
    );
  }

  List<Color> _getRoleGradient(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return [AppTheme.error, AppTheme.primaryViolet];
      case 'owner':
        return [AppTheme.primaryBlue, AppTheme.primaryPurple];
      case 'staff':
        return [AppTheme.warning, AppTheme.neonBlue];
      default:
        return [AppTheme.primaryCyan, AppTheme.neonGreen];
    }
  }

  String _getRoleText(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'مدير';
      case 'owner':
        return 'مالك';
      case 'staff':
        return 'موظف';
      case 'customer':
        return 'عميل';
      default:
        return role;
    }
  }
}

// Delete Confirmation Dialog
class _DeleteConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const _DeleteConfirmationDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(10),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withOpacity(0.95),
              AppTheme.darkCard.withOpacity(0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.error.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.error.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.error.withOpacity(0.2),
                    AppTheme.error.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_rounded,
                color: AppTheme.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'تأكيد الحذف',
              style: AppTextStyles.heading3.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'هل أنت متأكد من حذف هذا المستخدم؟\nلا يمكن التراجع عن هذا الإجراء.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.darkBorder.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'إلغاء',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onConfirm();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.error,
                            AppTheme.error.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.error.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'حذف',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Background Painter
class _FuturisticBackgroundPainter extends CustomPainter {
  final double rotation;
  final double glowIntensity;

  _FuturisticBackgroundPainter({
    required this.rotation,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw grid
    paint.color = AppTheme.primaryBlue.withOpacity(0.05);
    const spacing = 50.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw rotating circles
    final center = Offset(size.width / 2, size.height / 2);
    paint.color = AppTheme.primaryBlue.withOpacity(0.03 * glowIntensity);

    for (int i = 0; i < 3; i++) {
      final radius = 200.0 + i * 100;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation + i * 0.5);
      canvas.translate(-center.dx, -center.dy);
      canvas.drawCircle(center, radius, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
