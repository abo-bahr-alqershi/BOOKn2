// lib/features/admin_notifications/presentation/pages/user_notifications_page.dart

import 'package:bookn_cp_app/features/admin_users/presentation/bloc/user_details/user_details_bloc.dart';
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
import '../../domain/entities/admin_notification.dart';
import '../bloc/admin_notifications_bloc.dart';
import '../bloc/admin_notifications_event.dart';
import '../bloc/admin_notifications_state.dart';

class UserNotificationsPage extends StatefulWidget {
  final String userId;

  const UserNotificationsPage({
    super.key,
    required this.userId,
  });

  @override
  State<UserNotificationsPage> createState() => _UserNotificationsPageState();
}

class _UserNotificationsPageState extends State<UserNotificationsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

  bool? _showUnreadOnly;
  int _currentPage = 1;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _loadUserNotifications();
    context
        .read<UserDetailsBloc>()
        .add(LoadUserDetailsEvent(userId: widget.userId));
    _setupScrollListener();
  }

  void _loadUserNotifications() {
    context.read<AdminNotificationsBloc>().add(
          LoadUserNotificationsEvent(
            userId: widget.userId,
            page: _currentPage,
            pageSize: _pageSize,
            isRead: _showUnreadOnly == true ? false : null,
          ),
        );
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final state = context.read<AdminNotificationsBloc>().state;
        if (state is AdminUserNotificationsLoaded) {
          if (state.items.length >= state.totalCount) return;
          setState(() => _currentPage++);
          _loadUserNotifications();
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
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          _buildFilterChips(),
          _buildNotificationsList(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.darkBackground,
      leading: _buildBackButton(),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إشعارات المستخدم',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            _UserInfoHeader(userId: widget.userId),
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.2),
                    AppTheme.darkBackground,
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 60,
              left: 16,
              right: 16,
              child: _buildUserInfo(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.darkCard.withValues(alpha: 0.5),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: AppTheme.textWhite,
          size: 20,
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                CupertinoIcons.person_fill,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _UserInfoHeader(userId: widget.userId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Wrap(
          spacing: 8,
          children: [
            _buildFilterChip(
              label: 'الكل',
              isSelected: _showUnreadOnly == null,
              onTap: () {
                setState(() {
                  _showUnreadOnly = null;
                  _currentPage = 1;
                });
                _loadUserNotifications();
              },
            ),
            _buildFilterChip(
              label: 'غير مقروءة',
              isSelected: _showUnreadOnly == true,
              onTap: () {
                setState(() {
                  _showUnreadOnly = true;
                  _currentPage = 1;
                });
                _loadUserNotifications();
              },
            ),
            _buildFilterChip(
              label: 'مقروءة',
              isSelected: _showUnreadOnly == false,
              onTap: () {
                setState(() {
                  _showUnreadOnly = false;
                  _currentPage = 1;
                });
                _loadUserNotifications();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : AppTheme.darkCard.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppTheme.darkBorder.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected ? Colors.white : AppTheme.textMuted,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return BlocBuilder<AdminNotificationsBloc, AdminNotificationsState>(
      builder: (context, state) {
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
              onRetry: _loadUserNotifications,
              type: ErrorType.general,
            ),
          );
        }

        if (state is AdminUserNotificationsLoaded) {
          if (state.items.isEmpty) {
            return const SliverFillRemaining(
              child: EmptyWidget(
                message: 'لا توجد إشعارات لهذا المستخدم',
              ),
            );
          }

          return SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final notification = state.items[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildNotificationCard(notification),
                      ),
                    ),
                  );
                },
                childCount: state.items.length,
              ),
            ),
          );
        }

        return const SliverFillRemaining(child: SizedBox.shrink());
      },
    );
  }

  Widget _buildNotificationCard(AdminNotificationEntity notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.darkCard.withValues(alpha: 0.8),
                  AppTheme.darkCard.withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: notification.isRead
                    ? AppTheme.darkBorder.withValues(alpha: 0.2)
                    : AppTheme.primaryBlue.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _viewNotificationDetails(notification),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildNotificationIcon(notification.type),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification.title,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppTheme.textWhite,
                                    fontWeight: FontWeight.w600,
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
                          _buildStatusBadge(notification),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        notification.message,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.textLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!notification.isRead) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'غير مقروء',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(String type) {
    IconData icon;
    Color color;

    switch (type.toLowerCase()) {
      case 'booking':
        icon = CupertinoIcons.calendar;
        color = AppTheme.info;
        break;
      case 'payment':
        icon = CupertinoIcons.creditcard_fill;
        color = AppTheme.warning;
        break;
      case 'promotion':
        icon = CupertinoIcons.gift_fill;
        color = AppTheme.error;
        break;
      case 'system':
        icon = CupertinoIcons.gear_solid;
        color = AppTheme.textMuted;
        break;
      default:
        icon = CupertinoIcons.bell_fill;
        color = AppTheme.primaryBlue;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }

  Widget _buildStatusBadge(AdminNotificationEntity notification) {
    Color statusColor;
    String statusText;

    switch (notification.status.toLowerCase()) {
      case 'sent':
        statusColor = AppTheme.success;
        statusText = 'مُرسل';
        break;
      case 'pending':
        statusColor = AppTheme.warning;
        statusText = 'قيد الانتظار';
        break;
      case 'failed':
        statusColor = AppTheme.error;
        statusText = 'فشل';
        break;
      default:
        statusColor = AppTheme.textMuted;
        statusText = notification.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        statusText,
        style: AppTextStyles.caption.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _viewNotificationDetails(AdminNotificationEntity notification) {
    HapticFeedback.lightImpact();
    _showNotificationDetailsDialog(notification);
  }

  void _showNotificationDetailsDialog(AdminNotificationEntity notification) {
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
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.darkBorder.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        Text(
                          notification.message,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppTheme.textLight,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildDetailRow(
                          'النوع',
                          notification.type,
                          CupertinoIcons.tag,
                        ),
                        _buildDetailRow(
                          'الحالة',
                          notification.status,
                          CupertinoIcons.flag,
                        ),
                        _buildDetailRow(
                          'الأولوية',
                          notification.priority,
                          CupertinoIcons.exclamationmark_triangle,
                        ),
                        if (notification.readAt != null)
                          _buildDetailRow(
                            'تاريخ القراءة',
                            _formatDateTime(notification.readAt!),
                            CupertinoIcons.eye,
                          ),
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

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }
}

class _UserInfoHeader extends StatelessWidget {
  final String userId;

  const _UserInfoHeader({required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserDetailsBloc, UserDetailsState>(
      builder: (context, state) {
        if (state is UserDetailsLoaded) {
          final u = state.userDetails;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                u.userName,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              if (u.email.isNotEmpty)
                Text(
                  'البريد: ${u.email}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              if (u.phoneNumber.isNotEmpty)
                Text(
                  'الهاتف: ${u.phoneNumber}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
            ],
          );
        }
        if (state is UserDetailsError) {
          return Text(
            userId,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
            ),
          );
        }
        return Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CupertinoActivityIndicator(color: AppTheme.primaryBlue),
            ),
            const SizedBox(width: 6),
            Text(
              'جاري تحميل بيانات المستخدم...',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        );
      },
    );
  }
}
