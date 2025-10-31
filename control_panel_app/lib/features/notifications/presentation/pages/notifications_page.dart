// lib/features/notifications/presentation/pages/notifications_page.dart

import 'package:bookn_cp_app/core/constants/route_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/empty_widget.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import '../widgets/notification_item_widget.dart';
import '../widgets/notification_filter_widget.dart';
import '../widgets/notification_badge_widget.dart';
import '../../domain/entities/notification.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  String? _selectedType;
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadNotifications();
    _setupScrollListener();
  }

  void _loadNotifications() {
    context.read<NotificationBloc>().add(
          LoadNotificationsEvent(
            type: _selectedType,
            refresh: true,
          ),
        );
    context.read<NotificationBloc>().add(const LoadUnreadCountEvent());
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final state = context.read<NotificationBloc>().state;
        if (state is NotificationLoaded && !state.hasReachedMax) {
          context.read<NotificationBloc>().add(
                LoadNotificationsEvent(
                  page: state.currentPage + 1,
                  type: _selectedType,
                ),
              );
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
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
                  'الإشعارات',
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
                  BlocBuilder<NotificationBloc, NotificationState>(
                    builder: (context, state) {
                      int unreadCount = 0;
                      if (state is NotificationLoaded) {
                        unreadCount = state.unreadCount;
                      } else if (state is NotificationUnreadCountLoaded) {
                        unreadCount = state.unreadCount;
                      }
                      return NotificationBadgeWidget(
                        count: unreadCount,
                        onTap: null,
                        showAnimation: false,
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
          icon: CupertinoIcons.settings,
          onPressed: () => context.push(RouteConstants.notificationSettings),
        ),
        _buildActionButton(
          icon: CupertinoIcons.check_mark_circled,
          onPressed: _markAllAsRead,
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
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
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

  Widget _buildFilterSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: NotificationFilterWidget(
          selectedType: _selectedType,
          showUnreadOnly: _showUnreadOnly,
          onFilterChanged: (type, unreadOnly) {
            setState(() {
              _selectedType = type;
              _showUnreadOnly = unreadOnly ?? false;
            });
            _loadNotifications();
          },
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return BlocBuilder<NotificationBloc, NotificationState>(
      buildWhen: (previous, current) {
        return current is NotificationInitial ||
            current is NotificationLoading ||
            current is NotificationLoaded ||
            current is NotificationError;
      },
      builder: (context, state) {
        if (state is NotificationInitial) {
          return const SliverFillRemaining(
            child: LoadingWidget(
              type: LoadingType.futuristic,
              message: 'جاري تجهيز الإشعارات...',
            ),
          );
        }

        if (state is NotificationLoading) {
          return const SliverFillRemaining(
            child: LoadingWidget(
              type: LoadingType.futuristic,
              message: 'جاري تحميل الإشعارات...',
            ),
          );
        }

        if (state is NotificationError) {
          return SliverFillRemaining(
            child: CustomErrorWidget(
              message: state.message,
              onRetry: _loadNotifications,
              type: ErrorType.general,
            ),
          );
        }

        if (state is NotificationLoaded) {
          final notifications = _filterNotifications(state.notifications);

          if (notifications.isEmpty) {
            return SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width *
                          0.7, // 70% من عرض الشاشة
                      height: MediaQuery.of(context).size.width *
                          0.7, // نفس العرض للحفاظ على النسبة
                      child: SvgPicture.asset(
                        'assets/images/empty_notifications.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'لا توجد إشعارات',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ستظهر الإشعارات هنا عند وصولها',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final notification = notifications[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: NotificationItemWidget(
                          key: ValueKey(notification.id),
                          notification: notification,
                          onTap: () => _openNotificationDetails(notification),
                          onDismiss: () =>
                              _dismissNotification(notification.id),
                          onMarkAsRead: () => _markAsRead(notification.id),
                        ),
                      ),
                    ),
                  );
                },
                childCount: notifications.length,
              ),
            ),
          );
        }

        return const SliverFillRemaining(child: SizedBox.shrink());
      },
    );
  }

  List<NotificationEntity> _filterNotifications(
      List<NotificationEntity> notifications) {
    var filtered = notifications;

    if (_showUnreadOnly) {
      filtered = filtered.where((n) => !n.isRead).toList();
    }

    if (_selectedType != null) {
      filtered = filtered
          .where((n) => _mapTypeToCategory(n.type) == _selectedType)
          .toList();
    }

    return filtered;
  }

  void _openNotificationDetails(NotificationEntity notification) {
    _markAsRead(notification.id);

    // Navigate based on notification type and data
    if (notification.data != null) {
      // Parse notification data and navigate accordingly
      // Example: Navigator.pushNamed(context, '/booking-details', arguments: notification.data);
    }

    _showNotificationDetailsSheet(notification);
  }

  void _showNotificationDetailsSheet(NotificationEntity notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.darkBorder.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            _buildNotificationIcon(notification.type),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notification.title,
                                    style: AppTextStyles.heading3.copyWith(
                                      color: AppTheme.textWhite,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDateTime(notification.createdAt),
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Message
                        Text(
                          notification.message,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppTheme.textLight,
                            height: 1.6,
                          ),
                        ),
                        if (notification.data != null) ...[
                          const SizedBox(height: 24),
                          _buildActionButtons(notification),
                        ],
                      ],
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

  Widget _buildNotificationIcon(String type) {
    final IconData icon;
    final List<Color> gradient;

    final String category = _mapTypeToCategory(type);

    switch (category) {
      case 'booking':
        icon = CupertinoIcons.calendar;
        gradient = [AppTheme.info, AppTheme.neonBlue];
        break;
      case 'payment':
        icon = CupertinoIcons.creditcard_fill;
        gradient = [AppTheme.warning, const Color(0xFFFFD700)];
        break;
      case 'promotion':
        icon = CupertinoIcons.gift_fill;
        gradient = [AppTheme.error, const Color(0xFFFF69B4)];
        break;
      case 'system':
        icon = CupertinoIcons.gear_solid;
        gradient = [AppTheme.textMuted, AppTheme.darkBorder];
        break;
      default:
        icon = CupertinoIcons.bell_fill;
        gradient = [AppTheme.primaryBlue, AppTheme.primaryCyan];
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  String _mapTypeToCategory(String rawType) {
    final String t = rawType.trim();
    if (t.isEmpty) return 'other';
    final upper = t.toUpperCase();
    // Support both SNAKE_CASE (BOOKING_CREATED) and PascalCase (BookingCreated)
    if (upper.startsWith('BOOKING')) return 'booking';
    if (upper.startsWith('PAYMENT')) return 'payment';
    if (upper.startsWith('PROMOTION')) return 'promotion';
    if (upper.startsWith('SYSTEM') || upper == 'SECURITY_ALERT') return 'system';
    final lower = t.toLowerCase();
    if (['booking', 'payment', 'promotion', 'system'].contains(lower)) {
      return lower;
    }
    return 'other';
  }

  Widget _buildActionButtons(NotificationEntity notification) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to relevant page based on notification data
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      'عرض التفاصيل',
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
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.darkBorder.withValues(alpha: 0.3),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Icon(
                  CupertinoIcons.xmark,
                  color: AppTheme.textMuted,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _markAsRead(String notificationId) {
    context.read<NotificationBloc>().add(
          MarkNotificationAsReadEvent(notificationId: notificationId),
        );
  }

  void _markAllAsRead() {
    HapticFeedback.mediumImpact();
    context.read<NotificationBloc>().add(
          const MarkAllNotificationsAsReadEvent(),
        );
  }

  void _dismissNotification(String notificationId) {
    context.read<NotificationBloc>().add(
          DismissNotificationEvent(notificationId: notificationId),
        );
  }

  String _formatDateTime(DateTime dateTime) {
    // Format date and time nicely
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} - ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
