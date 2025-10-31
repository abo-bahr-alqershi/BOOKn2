// lib/features/admin_notifications/presentation/pages/admin_notifications_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/empty_widget.dart';
import '../bloc/admin_notifications_bloc.dart';
import '../bloc/admin_notifications_event.dart';
import '../bloc/admin_notifications_state.dart';
import '../widgets/admin_notifications_table.dart';
import '../widgets/notification_filters_bar.dart';
import '../widgets/notifications_stats_card.dart';
import '../../../helpers/presentation/utils/search_navigation_helper.dart';

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseAnimationController;
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  bool _showFilters = false;
  String? _selectedType;
  String? _selectedStatus;
  int _currentPage = 1;
  final int _pageSize = 20;

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

    _tabController = TabController(length: 3, vsync: this);

    _loadNotifications();
    _loadStats();
    _setupScrollListener();
  }

  void _loadNotifications() {
    context.read<AdminNotificationsBloc>().add(
          LoadSystemNotificationsEvent(
            page: _currentPage,
            pageSize: _pageSize,
            type: _normalizeAdminTypeFilter(_selectedType),
            status: _selectedStatus,
          ),
        );
  }

  void _loadStats() {
    context.read<AdminNotificationsBloc>().add(
          const LoadAdminNotificationsStatsEvent(),
        );
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final state = context.read<AdminNotificationsBloc>().state;
        if (state is AdminSystemNotificationsLoaded) {
          if (state.items.length >= state.totalCount) return;
          setState(() => _currentPage++);
          _loadNotifications();
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
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          _buildSliverAppBar(),
          _buildStatsSection(),
          _buildFilterSection(),
          _buildNotificationsList(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      pinned: true,
      backgroundColor: AppTheme.darkBackground,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16, right: 16),
        title: LayoutBuilder(
          builder: (context, constraints) {
            final isExpanded = constraints.maxHeight > 100;
            return Row(
              children: [
                Text(
                  'إدارة الإشعارات',
                  style: isExpanded
                      ? AppTextStyles.heading1.copyWith(
                          color: AppTheme.textWhite,
                          shadows: [
                            Shadow(
                              color:
                                  AppTheme.primaryBlue.withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ],
                        )
                      : AppTextStyles.bodyLarge.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                ),
                const Spacer(),
                if (isExpanded)
                  BlocBuilder<AdminNotificationsBloc, AdminNotificationsState>(
                    buildWhen: (previous, current) =>
                        previous.stats != current.stats,
                    builder: (context, state) {
                      final total = state.stats?['total'];
                      if (total == null) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$total',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryBlue.withValues(alpha: 0.1),
                AppTheme.darkBackground,
              ],
            ),
          ),
        ),
      ),
      actions: [
        _buildActionButton(
          icon: CupertinoIcons.plus,
          onPressed: _navigateToCreateNotification,
          tooltip: 'إنشاء إشعار',
        ),
        _buildActionButton(
          icon: CupertinoIcons.person_2,
          onPressed: _navigateToUserNotifications,
          tooltip: 'إشعارات المستخدمين',
        ),
        _buildActionButton(
          icon: CupertinoIcons.paperplane,
          onPressed: _showBroadcastDialog,
          tooltip: 'بث إشعار',
        ),
        _buildActionButton(
          icon: CupertinoIcons.speaker_2,
          onPressed: _navigateToNotificationChannels,
          tooltip: 'إدارة قنوات الإشعارات',
        ),
        AnimatedBuilder(
          animation: _pulseAnimationController,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryPurple.withValues(alpha: 0.2),
                          AppTheme.primaryViolet.withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryPurple.withValues(
                          alpha: 0.3 + (_pulseAnimationController.value * 0.2),
                        ),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _showFilters = !_showFilters);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            _showFilters
                                ? CupertinoIcons.xmark
                                : CupertinoIcons.slider_horizontal_3,
                            color: AppTheme.primaryPurple,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
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
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          borderRadius: BorderRadius.circular(12),
          child: Tooltip(
            message: tooltip ?? '',
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
      ),
    );
  }

  Widget _buildStatsSection() {
    return SliverToBoxAdapter(
      child: BlocBuilder<AdminNotificationsBloc, AdminNotificationsState>(
        buildWhen: (previous, current) =>
            previous.stats != current.stats ||
            previous.statsError != current.statsError,
        builder: (context, state) {
          final stats = state.stats;
          if (stats != null) {
            final now = DateTime.now();
            final last30 = now.subtract(const Duration(days: 30));
            return AnimationLimiter(
              child: Container(
                height: 130,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: NotificationsStatsCard(
                        stats: stats,
                        startDate: last30,
                        endDate: now,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: Text(
                        'الاتجاهات محسوبة لآخر 30 يومًا',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          }

          if (state.statsError != null) {
            return SizedBox(
              height: 130,
              child: Center(
                child: Text(
                  state.statsError!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return SizedBox(
            height: 130,
            child: Center(
              child: CupertinoActivityIndicator(
                color: AppTheme.primaryBlue,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterSection() {
    return SliverToBoxAdapter(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _showFilters ? 100 : 0,
        child: _showFilters
            ? NotificationFiltersBar(
                selectedType: _selectedType,
                selectedStatus: _selectedStatus,
                onFiltersChanged: (type, status) {
                  setState(() {
                    _selectedType = type;
                    _selectedStatus = status;
                    _currentPage = 1;
                  });
                  _loadNotifications();
                },
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  String? _normalizeAdminTypeFilter(String? category) {
    if (category == null) return null;
    // High-level categories should not be sent to backend; leave null to get all and filter server-side by exact types if needed
    // Admin API expects exact Type values; here we keep it null to avoid mismatches.
    return null;
  }

  Widget _buildNotificationsList() {
    return BlocBuilder<AdminNotificationsBloc, AdminNotificationsState>(
      builder: (context, state) {
        if (state is AdminNotificationsInitial) {
          return const SliverFillRemaining(
            child: LoadingWidget(
              type: LoadingType.futuristic,
              message: 'جاري تحميل الإشعارات...',
            ),
          );
        }

        if (state is AdminNotificationsLoading) {
          return const SliverFillRemaining(
            child: LoadingWidget(
              type: LoadingType.futuristic,
              message: 'جاري تحميل الإشعارات...',
            ),
          );
        }

        if (state is AdminNotificationsError) {
          return SliverFillRemaining(
            child: CustomErrorWidget(
              message: state.message,
              onRetry: _loadNotifications,
              type: ErrorType.general,
            ),
          );
        }

        if (state is AdminSystemNotificationsLoaded) {
          if (state.items.isEmpty) {
            return SliverFillRemaining(
              child: EmptyWidget(
                message: 'لا توجد إشعارات',
                actionWidget: ElevatedButton.icon(
                  onPressed: _navigateToCreateNotification,
                  icon: const Icon(CupertinoIcons.plus, size: 18),
                  label: const Text('إنشاء إشعار'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
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

          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AdminNotificationsTable(
                notifications: state.items,
                onNotificationTap: _viewNotificationDetails,
                onResend: _resendNotification,
                onDelete: _deleteNotification,
              ),
            ),
          );
        }

        return const SliverFillRemaining(child: SizedBox.shrink());
      },
    );
  }

  // Removed FAB: Add action moved to AppBar

  void _navigateToCreateNotification() {
    HapticFeedback.lightImpact();
    context.push('/admin/notifications/create');
  }

  void _navigateToUserNotifications() {
    HapticFeedback.lightImpact();
    _showUserSelectionDialog();
  }

  Future<void> _showUserSelectionDialog() async {
    final user = await SearchNavigationHelper.searchSingleUser(context);
    if (user != null && mounted) {
      context.push('/admin/notifications/user/${user.id}');
    }
  }

  void _showBroadcastDialog() {
    HapticFeedback.lightImpact();
    context.push('/admin/notifications/broadcast');
  }

  void _navigateToNotificationChannels() {
    HapticFeedback.lightImpact();
    context.push('/admin/notification-channels');
  }

  void _viewNotificationDetails(String notificationId) {
    HapticFeedback.lightImpact();
    // يمكن إضافة صفحة تفاصيل الإشعار إذا لزم الأمر
  }

  void _resendNotification(String notificationId) {
    HapticFeedback.mediumImpact();
    context.read<AdminNotificationsBloc>().add(
          ResendAdminNotificationEvent(notificationId),
        );
  }

  void _deleteNotification(String notificationId) {
    HapticFeedback.mediumImpact();
    _showDeleteConfirmationDialog(notificationId);
  }

  void _showDeleteConfirmationDialog(String notificationId) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.darkCard.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.error.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.error.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    CupertinoIcons.trash,
                    color: AppTheme.error,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'حذف الإشعار',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'هل أنت متأكد من حذف هذا الإشعار؟',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'إلغاء',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(ctx);
                              context.read<AdminNotificationsBloc>().add(
                                    DeleteAdminNotificationEvent(
                                        notificationId),
                                  );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              child: Center(
                                child: Text(
                                  'حذف',
                                  style: AppTextStyles.buttonMedium.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
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
        ),
      ),
    );
  }
}
