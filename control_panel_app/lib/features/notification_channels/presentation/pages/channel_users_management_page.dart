// lib/features/notifications/presentation/pages/channel_users_management_page.dart

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
import '../../../helpers/presentation/utils/search_navigation_helper.dart';
import '../../../admin_users/domain/entities/user.dart';
import '../../domain/entities/notification_channel.dart';
import '../bloc/channels_bloc.dart';
import '../bloc/channels_event.dart';
import '../bloc/channels_state.dart';

class ChannelUsersManagementPage extends StatefulWidget {
  final String channelId;

  const ChannelUsersManagementPage({
    super.key,
    required this.channelId,
  });

  @override
  State<ChannelUsersManagementPage> createState() =>
      _ChannelUsersManagementPageState();
}

class _ChannelUsersManagementPageState extends State<ChannelUsersManagementPage>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _floatingActionController;
  late TabController _tabController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  // Controllers
  final ScrollController _subscribersScrollController = ScrollController();
  final ScrollController _addUsersScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // State
  final List<User> _selectedUsersToAdd = [];
  final List<String> _selectedUsersToRemove = [];
  bool _showOnlyActive = true;
  final String _searchQuery = '';
  String? _hoveredSubscriptionId;
  bool _isSelectionMode = false;
  String _sortBy = 'date';
  bool _isAscending = false;

  // View Mode
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    _loadChannelDetails();
    _loadSubscribers();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _floatingActionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutQuart),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 0.8, curve: Curves.elasticOut),
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _floatingActionController.forward();
  }

  void _handleTabChange() {
    if (_tabController.index == 0) {
      _selectedUsersToAdd.clear();
    } else {
      _selectedUsersToRemove.clear();
      setState(() => _isSelectionMode = false);
    }
    setState(() {});
  }

  void _loadChannelDetails() {
    context.read<ChannelsBloc>().add(LoadChannelDetailsEvent(widget.channelId));
  }

  void _loadSubscribers() {
    context.read<ChannelsBloc>().add(
          LoadChannelSubscribersEvent(
            channelId: widget.channelId,
            activeOnly: _showOnlyActive,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _floatingActionController.dispose();
    _tabController.dispose();
    _subscribersScrollController.dispose();
    _addUsersScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildChannelInfo(),
                _buildTabs(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSubscribersList(),
                      _buildAddUsersSection(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildAnimatedBackground() {
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
        painter: _UsersBackgroundPainter(
          pulseValue: _pulseAnimation.value,
        ),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withOpacity(0.7),
              AppTheme.darkCard.withOpacity(0.3),
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: AppTheme.primaryBlue.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            _buildBackButton(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppTheme.primaryGradient.createShader(bounds),
                    child: Text(
                      'إدارة مستخدمي القناة',
                      style: AppTextStyles.heading2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  BlocBuilder<ChannelsBloc, ChannelsState>(
                    builder: (context, state) {
                      if (state.selectedChannel != null) {
                        return Text(
                          state.selectedChannel!.name,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkSurface.withOpacity(0.5),
              AppTheme.darkSurface.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          color: AppTheme.textWhite,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (_tabController.index == 0) ...[
          _buildViewToggleButton(),
          const SizedBox(width: 8),
          _buildSelectionModeButton(),
          const SizedBox(width: 8),
        ],
        _buildFilterButton(),
        const SizedBox(width: 8),
        _buildSortButton(),
      ],
    );
  }

  Widget _buildViewToggleButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _isGridView = !_isGridView);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.darkBorder.withOpacity(0.3),
          ),
        ),
        child: Icon(
          _isGridView ? Icons.list_rounded : Icons.grid_view_rounded,
          color: AppTheme.textMuted,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSelectionModeButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _isSelectionMode = !_isSelectionMode;
          if (!_isSelectionMode) {
            _selectedUsersToRemove.clear();
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: _isSelectionMode ? AppTheme.primaryGradient : null,
          color: _isSelectionMode ? null : AppTheme.darkCard.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isSelectionMode
                ? Colors.transparent
                : AppTheme.darkBorder.withOpacity(0.3),
          ),
        ),
        child: Icon(
          Icons.checklist_rounded,
          color: _isSelectionMode ? Colors.white : AppTheme.textMuted,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return GestureDetector(
      onTap: _toggleActiveFilter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: _showOnlyActive ? AppTheme.primaryGradient : null,
          color: _showOnlyActive ? null : AppTheme.darkCard.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _showOnlyActive
                ? Colors.transparent
                : AppTheme.darkBorder.withOpacity(0.3),
          ),
        ),
        child: Icon(
          _showOnlyActive ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: _showOnlyActive ? Colors.white : AppTheme.textMuted,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    return GestureDetector(
      onTap: _showSortOptions,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.darkBorder.withOpacity(0.3),
          ),
        ),
        child: Icon(
          _isAscending
              ? Icons.arrow_upward_rounded
              : Icons.arrow_downward_rounded,
          color: AppTheme.textMuted,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildChannelInfo() {
    return BlocBuilder<ChannelsBloc, ChannelsState>(
      builder: (context, state) {
        if (state.selectedChannel == null) {
          return _buildChannelInfoLoading();
        }

        final channel = state.selectedChannel!;

        return SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.1),
                    AppTheme.primaryPurple.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Row(
                    children: [
                      _buildChannelIcon(channel),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildChannelStats(channel),
                            if (channel.description != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                channel.description!,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChannelInfoLoading() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.3),
            AppTheme.darkCard.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
          ),
        ),
      ),
    );
  }

  Widget _buildChannelIcon(NotificationChannel channel) {
    Color channelColor = AppTheme.primaryBlue;
    if (channel.color != null && channel.color!.isNotEmpty) {
      try {
        channelColor =
            Color(int.parse(channel.color!.replaceFirst('#', '0xff')));
      } catch (_) {}
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: channelColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: channelColor.withOpacity(0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: channelColor.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                channel.displayIcon,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChannelStats(NotificationChannel channel) {
    return Row(
      children: [
        _buildStatItem(
          icon: Icons.people_rounded,
          value: channel.subscribersCount.toString(),
          label: 'مشترك',
          color: AppTheme.primaryBlue,
        ),
        const SizedBox(width: 20),
        _buildStatItem(
          icon: Icons.send_rounded,
          value: channel.notificationsSentCount.toString(),
          label: 'إشعار',
          color: AppTheme.primaryPurple,
        ),
        const SizedBox(width: 20),
        _buildStatItem(
          icon: Icons.access_time_rounded,
          value: _getLastActivity(channel.lastNotificationAt),
          label: 'آخر نشاط',
          color: AppTheme.warning,
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppTheme.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_rounded, size: 18),
                const SizedBox(width: 8),
                BlocBuilder<ChannelsBloc, ChannelsState>(
                  builder: (context, state) {
                    final count = state.subscribers.length;
                    return Text('المشتركين ($count)');
                  },
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add_rounded, size: 18),
                const SizedBox(width: 8),
                Text('إضافة (${_selectedUsersToAdd.length})'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribersList() {
    return BlocBuilder<ChannelsBloc, ChannelsState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const LoadingWidget(
            type: LoadingType.futuristic,
            message: 'جاري تحميل المشتركين...',
          );
        }

        if (state.error != null) {
          return CustomErrorWidget(
            message: state.error!,
            onRetry: _loadSubscribers,
            type: ErrorType.general,
          );
        }

        if (state.subscribers.isEmpty) {
          return EmptyWidget(
            message: 'لا يوجد مشتركين في هذه القناة',
            icon: Icons.people_outline_rounded,
            actionWidget: _buildAddSubscribersButton(),
          );
        }

        final sortedSubscribers = _sortSubscribers(state.subscribers);

        if (_isGridView) {
          return _buildSubscribersGrid(sortedSubscribers);
        } else {
          return _buildSubscribersListView(sortedSubscribers);
        }
      },
    );
  }

  Widget _buildSubscribersGrid(List<UserChannelSubscription> subscribers) {
    return GridView.builder(
      controller: _subscribersScrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: subscribers.length,
      itemBuilder: (context, index) {
        final subscription = subscribers[index];
        return AnimationConfiguration.staggeredGrid(
          position: index,
          duration: const Duration(milliseconds: 375),
          columnCount: 2,
          child: ScaleAnimation(
            child: FadeInAnimation(
              child: _buildSubscriberGridCard(subscription),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubscribersListView(List<UserChannelSubscription> subscribers) {
    return ListView.builder(
      controller: _subscribersScrollController,
      padding: const EdgeInsets.all(16),
      itemCount: subscribers.length,
      itemBuilder: (context, index) {
        final subscription = subscribers[index];
        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: _buildSubscriberCard(subscription),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubscriberCard(UserChannelSubscription subscription) {
    final isSelected = _selectedUsersToRemove.contains(subscription.userId);
    final isHovered = _hoveredSubscriptionId == subscription.userId;

    return MouseRegion(
      onEnter: (_) =>
          setState(() => _hoveredSubscriptionId = subscription.userId),
      onExit: (_) => setState(() => _hoveredSubscriptionId = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        transform: Matrix4.identity()..translate(0.0, isHovered ? -3.0 : 0.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [
                    AppTheme.error.withOpacity(0.15),
                    AppTheme.error.withOpacity(0.05),
                  ]
                : isHovered
                    ? [
                        AppTheme.primaryBlue.withOpacity(0.08),
                        AppTheme.primaryPurple.withOpacity(0.04),
                      ]
                    : [
                        AppTheme.darkCard.withOpacity(0.7),
                        AppTheme.darkCard.withOpacity(0.5),
                      ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.error.withOpacity(0.3)
                : isHovered
                    ? AppTheme.primaryBlue.withOpacity(0.3)
                    : AppTheme.darkBorder.withOpacity(0.3),
            width: isHovered ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.error.withOpacity(0.1)
                  : isHovered
                      ? AppTheme.primaryBlue.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
              blurRadius: isHovered ? 20 : 10,
              offset: Offset(0, isHovered ? 8 : 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isSelectionMode
                    ? () => _toggleUserSelection(subscription.userId)
                    : () => _showUserDetails(subscription),
                onLongPress: () => _showUserOptions(subscription),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildUserAvatar(subscription),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (subscription.userName != null &&
                                      subscription.userName!.isNotEmpty)
                                  ? subscription.userName!
                                  : 'مستخدم #${subscription.userId.substring(0, 8)}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppTheme.textWhite,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildSubscriptionInfo(subscription),
                          ],
                        ),
                      ),
                      _buildSubscriptionActions(subscription, isSelected),
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

  Widget _buildSubscriberGridCard(UserChannelSubscription subscription) {
    final isSelected = _selectedUsersToRemove.contains(subscription.userId);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSelected
              ? [
                  AppTheme.error.withOpacity(0.15),
                  AppTheme.error.withOpacity(0.05),
                ]
              : [
                  AppTheme.darkCard.withOpacity(0.7),
                  AppTheme.darkCard.withOpacity(0.5),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? AppTheme.error.withOpacity(0.3)
              : AppTheme.darkBorder.withOpacity(0.3),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isSelectionMode
                  ? () => _toggleUserSelection(subscription.userId)
                  : () => _showUserDetails(subscription),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildUserAvatar(subscription, size: 60),
                    const SizedBox(height: 12),
                    Text(
                      (subscription.userName != null &&
                              subscription.userName!.isNotEmpty)
                          ? subscription.userName!
                          : (subscription.userEmail != null &&
                                  subscription.userEmail!.isNotEmpty)
                              ? subscription.userEmail!
                              : 'مستخدم',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subscription.userEmail ??
                          '#${subscription.userId.substring(0, 6)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSubscriptionBadges(subscription),
                    const Spacer(),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'محدد للحذف',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
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

  Widget _buildUserAvatar(UserChannelSubscription subscription,
      {double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: subscription.isActive
            ? AppTheme.primaryGradient
            : LinearGradient(
                colors: [
                  AppTheme.textMuted.withOpacity(0.3),
                  AppTheme.textMuted.withOpacity(0.1),
                ],
              ),
        shape: BoxShape.circle,
        border: Border.all(
          color: subscription.isActive
              ? AppTheme.success.withOpacity(0.5)
              : AppTheme.darkBorder,
          width: 2,
        ),
        boxShadow: subscription.isActive
            ? [
                BoxShadow(
                  color: AppTheme.success.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }

  Widget _buildSubscriptionInfo(UserChannelSubscription subscription) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _buildSubscriptionBadge(
          icon: Icons.calendar_today_rounded,
          label: _formatDate(subscription.subscribedAt),
          color: AppTheme.primaryBlue,
        ),
        _buildSubscriptionBadge(
          icon: Icons.notifications_rounded,
          label: '${subscription.notificationsReceivedCount}',
          color: AppTheme.primaryPurple,
        ),
        if (subscription.isMuted)
          _buildSubscriptionBadge(
            icon: Icons.notifications_off_rounded,
            label: 'مكتوم',
            color: AppTheme.warning,
          ),
        if (!subscription.isActive)
          _buildSubscriptionBadge(
            icon: Icons.block_rounded,
            label: 'غير نشط',
            color: AppTheme.error,
          ),
      ],
    );
  }

  Widget _buildSubscriptionBadges(UserChannelSubscription subscription) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_rounded,
              size: 14,
              color: AppTheme.primaryPurple,
            ),
            const SizedBox(width: 4),
            Text(
              '${subscription.notificationsReceivedCount}',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.primaryPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (subscription.isMuted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'مكتوم',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.warning,
                fontSize: 10,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubscriptionBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
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

  Widget _buildSubscriptionActions(
      UserChannelSubscription subscription, bool isSelected) {
    if (_isSelectionMode) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : AppTheme.darkSurface.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppTheme.darkBorder.withOpacity(0.3),
          ),
        ),
        child: isSelected
            ? const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 18,
              )
            : null,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!subscription.isActive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'غير نشط',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: AppTheme.textMuted,
            ),
            onSelected: (value) =>
                _handleSubscriptionAction(value, subscription),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'mute',
                child: Row(
                  children: [
                    Icon(
                      subscription.isMuted
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_off_rounded,
                      size: 18,
                      color: AppTheme.warning,
                    ),
                    const SizedBox(width: 8),
                    Text(subscription.isMuted ? 'إلغاء الكتم' : 'كتم'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(
                      Icons.remove_circle_outline_rounded,
                      size: 18,
                      color: AppTheme.error,
                    ),
                    const SizedBox(width: 8),
                    const Text('إزالة'),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildAddUsersSection() {
    return Column(
      children: [
        _buildAddUsersHeader(),
        if (_selectedUsersToAdd.isEmpty)
          Expanded(
            child: EmptyWidget(
              message: 'لم يتم اختيار أي مستخدمين بعد',
              icon: Icons.person_add_rounded,
              actionWidget: _buildSelectUsersButton(),
            ),
          )
        else
          Expanded(
            child: AnimationLimiter(
              child: ListView.builder(
                controller: _addUsersScrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _selectedUsersToAdd.length,
                itemBuilder: (context, index) {
                  final user = _selectedUsersToAdd[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildSelectedUserCard(user),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        if (_selectedUsersToAdd.isNotEmpty) _buildAddUsersFooter(),
      ],
    );
  }

  Widget _buildAddUsersHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.info.withOpacity(0.1),
            AppTheme.info.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.info.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppTheme.info,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'اختر المستخدمين لإضافتهم إلى القناة',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedUserCard(User user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.success.withOpacity(0.1),
            AppTheme.success.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.success.withOpacity(0.3),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppTheme.textWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          user.email,
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeUserFromSelection(user),
                    icon: Icon(
                      Icons.remove_circle_rounded,
                      color: AppTheme.error,
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

  Widget _buildAddUsersFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.7),
            AppTheme.darkCard.withOpacity(0.5),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSelectUsersButton(),
          ),
          const SizedBox(width: 12),
          Text(
            '${_selectedUsersToAdd.length} مستخدم محدد',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    final hasSelection =
        _selectedUsersToAdd.isNotEmpty || _selectedUsersToRemove.isNotEmpty;

    if (!hasSelection) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _floatingActionController,
      builder: (context, child) {
        return Transform.scale(
          scale: _floatingActionController.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: _selectedUsersToRemove.isNotEmpty
                  ? LinearGradient(colors: [
                      AppTheme.error,
                      AppTheme.error.withOpacity(0.8),
                    ])
                  : AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (_selectedUsersToRemove.isNotEmpty
                          ? AppTheme.error
                          : AppTheme.primaryBlue)
                      .withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _applyChanges,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _selectedUsersToRemove.isNotEmpty
                            ? Icons.delete_sweep_rounded
                            : Icons.group_add_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedUsersToRemove.isNotEmpty
                            ? 'إزالة ${_selectedUsersToRemove.length} مشترك'
                            : 'إضافة ${_selectedUsersToAdd.length} مشترك',
                        style: AppTextStyles.bodyMedium.copyWith(
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
      },
    );
  }

  Widget _buildAddSubscribersButton() {
    return ElevatedButton.icon(
      onPressed: () => _tabController.animateTo(1),
      icon: const Icon(Icons.person_add_rounded, size: 18),
      label: const Text('إضافة مشتركين'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSelectUsersButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _selectUsersToAdd,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_search_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedUsersToAdd.isEmpty
                      ? 'اختيار مستخدمين'
                      : 'إضافة مستخدمين آخرين',
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

  // ==================== Helper Methods ====================

  List<UserChannelSubscription> _sortSubscribers(
      List<UserChannelSubscription> subscribers) {
    final sorted = List<UserChannelSubscription>.from(subscribers);

    sorted.sort((a, b) {
      int comparison = 0;

      switch (_sortBy) {
        case 'date':
          comparison = a.subscribedAt.compareTo(b.subscribedAt);
          break;
        case 'notifications':
          comparison = a.notificationsReceivedCount.compareTo(
            b.notificationsReceivedCount,
          );
          break;
        case 'status':
          comparison = a.isActive.toString().compareTo(b.isActive.toString());
          break;
        case 'muted':
          comparison = a.isMuted.toString().compareTo(b.isMuted.toString());
          break;
        default:
          comparison = a.userId.compareTo(b.userId);
      }

      return _isAscending ? comparison : -comparison;
    });

    return sorted;
  }

  String _formatDate(DateTime date) {
    final difference = DateTime.now().difference(date);

    if (difference.inDays > 365) {
      return 'منذ ${difference.inDays ~/ 365} سنة';
    } else if (difference.inDays > 30) {
      return 'منذ ${difference.inDays ~/ 30} شهر';
    } else if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }

  String _getLastActivity(DateTime? lastActivity) {
    if (lastActivity == null) return 'لا يوجد';
    return _formatDate(lastActivity);
  }

  // ==================== Action Methods ====================

  void _toggleActiveFilter() {
    HapticFeedback.lightImpact();
    setState(() {
      _showOnlyActive = !_showOnlyActive;
    });
    _loadSubscribers();
  }

  void _toggleUserSelection(String userId) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedUsersToRemove.contains(userId)) {
        _selectedUsersToRemove.remove(userId);
      } else {
        _selectedUsersToRemove.add(userId);
      }
    });
  }

  void _removeUserFromSelection(User user) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedUsersToAdd.remove(user);
    });
  }

  Future<void> _selectUsersToAdd() async {
    HapticFeedback.lightImpact();
    final users = await SearchNavigationHelper.searchMultipleUsers(context);
    if (users != null && users.isNotEmpty) {
      setState(() {
        for (final user in users) {
          if (!_selectedUsersToAdd.any((u) => u.id == user.id)) {
            _selectedUsersToAdd.add(user);
          }
        }
      });
    }
  }

  void _applyChanges() {
    HapticFeedback.mediumImpact();

    if (_selectedUsersToAdd.isNotEmpty) {
      context.read<ChannelsBloc>().add(
            AddSubscribersEvent(
              channelId: widget.channelId,
              userIds: _selectedUsersToAdd.map((u) => u.id).toList(),
            ),
          );

      _showSuccessMessage('تم إضافة ${_selectedUsersToAdd.length} مشترك بنجاح');

      setState(() {
        _selectedUsersToAdd.clear();
      });
      _tabController.animateTo(0);
    }

    if (_selectedUsersToRemove.isNotEmpty) {
      context.read<ChannelsBloc>().add(
            RemoveSubscribersEvent(
              channelId: widget.channelId,
              userIds: _selectedUsersToRemove,
            ),
          );

      _showSuccessMessage(
          'تم إزالة ${_selectedUsersToRemove.length} مشترك بنجاح');

      setState(() {
        _selectedUsersToRemove.clear();
        _isSelectionMode = false;
      });
    }
  }

  void _showSortOptions() {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.darkCard.withOpacity(0.95),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.3),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.darkBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'ترتيب حسب',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppTheme.textWhite,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSortOption(
                    'تاريخ الاشتراك',
                    Icons.calendar_today_rounded,
                    'date',
                  ),
                  _buildSortOption(
                    'عدد الإشعارات',
                    Icons.notifications_rounded,
                    'notifications',
                  ),
                  _buildSortOption(
                    'الحالة',
                    Icons.toggle_on_rounded,
                    'status',
                  ),
                  _buildSortOption(
                    'الكتم',
                    Icons.notifications_off_rounded,
                    'muted',
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _isAscending = true);
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isAscending
                                  ? AppTheme.primaryBlue.withOpacity(0.2)
                                  : AppTheme.darkSurface.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isAscending
                                    ? AppTheme.primaryBlue.withOpacity(0.5)
                                    : AppTheme.darkBorder.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_upward_rounded,
                                  color: _isAscending
                                      ? AppTheme.primaryBlue
                                      : AppTheme.textMuted,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'تصاعدي',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: _isAscending
                                        ? AppTheme.primaryBlue
                                        : AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _isAscending = false);
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isAscending
                                  ? AppTheme.primaryBlue.withOpacity(0.2)
                                  : AppTheme.darkSurface.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: !_isAscending
                                    ? AppTheme.primaryBlue.withOpacity(0.5)
                                    : AppTheme.darkBorder.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_downward_rounded,
                                  color: !_isAscending
                                      ? AppTheme.primaryBlue
                                      : AppTheme.textMuted,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'تنازلي',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: !_isAscending
                                        ? AppTheme.primaryBlue
                                        : AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, IconData icon, String value) {
    final isSelected = _sortBy == value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _sortBy = value);
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryBlue.withOpacity(0.2)
                      : AppTheme.darkSurface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.textMuted,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.textWhite,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Icon(
                  Icons.check_rounded,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserDetails(UserChannelSubscription subscription) {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: AppTheme.darkCard.withOpacity(0.95),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.darkBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUserDetailsHeader(subscription),
                        const SizedBox(height: 24),
                        _buildUserDetailsStats(subscription),
                        const SizedBox(height: 24),
                        _buildUserDetailsActions(subscription),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildUserDetailsFooter(subscription),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserDetailsHeader(UserChannelSubscription subscription) {
    return Row(
      children: [
        _buildUserAvatar(subscription, size: 60),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مستخدم #${subscription.userId.substring(0, 8)}',
                style: AppTextStyles.heading3.copyWith(
                  color: AppTheme.textWhite,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'مشترك منذ ${_formatDate(subscription.subscribedAt)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: subscription.isActive
                ? AppTheme.success.withOpacity(0.2)
                : AppTheme.error.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: subscription.isActive
                  ? AppTheme.success.withOpacity(0.5)
                  : AppTheme.error.withOpacity(0.5),
            ),
          ),
          child: Text(
            subscription.isActive ? 'نشط' : 'غير نشط',
            style: AppTextStyles.caption.copyWith(
              color: subscription.isActive ? AppTheme.success : AppTheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserDetailsStats(UserChannelSubscription subscription) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.notifications_rounded,
                  label: 'الإشعارات المستلمة',
                  value: subscription.notificationsReceivedCount.toString(),
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.mail_outline_rounded,
                  label: 'غير مقروءة',
                  value: '0',
                  color: AppTheme.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.access_time_rounded,
                  label: 'آخر تسليم اشعار',
                  value: subscription.lastNotificationReceivedAt != null
                      ? _formatDate(subscription.lastNotificationReceivedAt!)
                      : 'لا يوجد',
                  color: AppTheme.primaryPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: subscription.isMuted
                      ? Icons.notifications_off_rounded
                      : Icons.notifications_active_rounded,
                  label: 'حالة الإشعارات',
                  value: subscription.isMuted ? 'مكتوم' : 'مفعل',
                  color:
                      subscription.isMuted ? AppTheme.error : AppTheme.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textWhite,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetailsActions(UserChannelSubscription subscription) {
    return Column(
      children: [
        _buildActionButton(
          icon: subscription.isMuted
              ? Icons.notifications_active_rounded
              : Icons.notifications_off_rounded,
          label: subscription.isMuted ? 'إلغاء الكتم' : 'كتم الإشعارات',
          color: AppTheme.warning,
          onTap: () {
            Navigator.pop(context);
            _toggleMuteSubscription(subscription);
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.block_rounded,
          label: subscription.isActive ? 'إيقاف الاشتراك' : 'تفعيل الاشتراك',
          color: subscription.isActive ? AppTheme.error : AppTheme.success,
          onTap: () {
            Navigator.pop(context);
            _toggleSubscriptionStatus(subscription);
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.remove_circle_outline_rounded,
          label: 'إزالة من القناة',
          color: AppTheme.error,
          onTap: () {
            Navigator.pop(context);
            _confirmRemoveSubscription(subscription);
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserDetailsFooter(UserChannelSubscription subscription) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppTheme.textMuted,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'معرف المستخدم: ${subscription.userId}',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserOptions(UserChannelSubscription subscription) {
    HapticFeedback.mediumImpact();
    _showUserDetails(subscription);
  }

  void _handleSubscriptionAction(
      String action, UserChannelSubscription subscription) {
    HapticFeedback.lightImpact();

    switch (action) {
      case 'mute':
        _toggleMuteSubscription(subscription);
        break;
      case 'remove':
        _confirmRemoveSubscription(subscription);
        break;
    }
  }

  void _toggleMuteSubscription(UserChannelSubscription subscription) {
    _showSuccessMessage('ميزة كتم/إلغاء الكتم غير مدعومة حالياً');
  }

  void _toggleSubscriptionStatus(UserChannelSubscription subscription) {
    _showSuccessMessage('ميزة تفعيل/إيقاف الاشتراك غير مدعومة حالياً');
  }

  void _confirmRemoveSubscription(UserChannelSubscription subscription) {
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
              color: AppTheme.darkCard.withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.error.withOpacity(0.3),
              ),
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
                    Icons.person_remove_rounded,
                    color: AppTheme.error,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'إزالة المشترك',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'هل أنت متأكد من إزالة هذا المستخدم من القناة؟',
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
                              context.read<ChannelsBloc>().add(
                                    RemoveSubscribersEvent(
                                      channelId: widget.channelId,
                                      userIds: [subscription.userId],
                                    ),
                                  );
                              _showSuccessMessage('تم إزالة المشترك بنجاح');
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              child: Center(
                                child: Text(
                                  'إزالة',
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

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message),
            ),
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
}

// Background Painter
class _UsersBackgroundPainter extends CustomPainter {
  final double pulseValue;

  _UsersBackgroundPainter({required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw animated circles
    paint.shader = RadialGradient(
      colors: [
        AppTheme.primaryBlue.withOpacity(0.1 * pulseValue),
        AppTheme.primaryBlue.withOpacity(0.05 * pulseValue),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.8, size.height * 0.2),
      radius: 150 * pulseValue,
    ));

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      150 * pulseValue,
      paint,
    );

    paint.shader = RadialGradient(
      colors: [
        AppTheme.primaryPurple.withOpacity(0.08 * pulseValue),
        AppTheme.primaryPurple.withOpacity(0.04 * pulseValue),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.2, size.height * 0.7),
      radius: 120 * pulseValue,
    ));

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.7),
      120 * pulseValue,
      paint,
    );

    // Draw grid pattern
    final gridPaint = Paint()
      ..color = AppTheme.darkBorder.withOpacity(0.02)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 30.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        gridPaint,
      );
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
