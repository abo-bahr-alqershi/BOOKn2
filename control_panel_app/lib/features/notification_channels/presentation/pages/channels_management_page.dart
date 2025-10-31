// lib/features/notifications/presentation/pages/channels_management_page.dart

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
import '../../domain/entities/notification_channel.dart';
import '../bloc/channels_bloc.dart';
import '../bloc/channels_event.dart';
import '../bloc/channels_state.dart';
import '../widgets/channel_card.dart';
import '../widgets/channel_statistics_card.dart';
import '../widgets/channel_filters.dart';

class ChannelsManagementPage extends StatefulWidget {
  const ChannelsManagementPage({super.key});

  @override
  State<ChannelsManagementPage> createState() => _ChannelsManagementPageState();
}

class _ChannelsManagementPageState extends State<ChannelsManagementPage>
    with TickerProviderStateMixin {
  static const double _baseStatsSectionHeight = 168;
  // Animation Controllers
  late AnimationController _animationController;
  late AnimationController _floatingButtonController;
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;

  // Controllers
  final ScrollController _scrollController = ScrollController();

  // State
  String? _selectedType;
  bool? _isActiveFilter;
  String _searchQuery = '';
  bool _showStats = true;
  String? _hoveredChannelId;
  bool _isFloatingButtonExpanded = false;

  // Sort options
  String _sortBy = 'name';
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadChannels();
    _loadStatistics();
    _setupScrollListener();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _floatingButtonController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutQuart),
    ));

    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _floatingButtonController.forward();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels > 100 &&
          !_isFloatingButtonExpanded) {
        setState(() => _isFloatingButtonExpanded = true);
      } else if (_scrollController.position.pixels <= 100 &&
          _isFloatingButtonExpanded) {
        setState(() => _isFloatingButtonExpanded = false);
      }
    });
  }

  void _loadChannels() {
    context.read<ChannelsBloc>().add(
          LoadChannelsEvent(
            search: _searchQuery.isEmpty ? null : _searchQuery,
            type: _selectedType,
            isActive: _isActiveFilter,
          ),
        );
  }

  void _loadStatistics() {
    context.read<ChannelsBloc>().add(const LoadChannelStatisticsEvent());
  }

  @override
  void dispose() {
    _animationController.dispose();
    _floatingButtonController.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
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
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                _buildSliverAppBar(),
                _buildStatisticsSection(),
                _buildFiltersSection(),
                _buildChannelsList(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowController, _pulseController]),
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
          child: Stack(
            children: [
              // Animated orbs
              Positioned(
                top: -100 + (20 * _glowAnimation.value),
                left: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primaryBlue
                            .withOpacity(0.15 * _glowAnimation.value),
                        AppTheme.primaryBlue
                            .withOpacity(0.05 * _glowAnimation.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -150,
                right: -150 + (30 * _glowAnimation.value),
                child: Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.primaryPurple
                              .withOpacity(0.1 * _glowAnimation.value),
                          AppTheme.primaryPurple
                              .withOpacity(0.03 * _glowAnimation.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Custom paint pattern
              if (_showStats)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ChannelsBackgroundPainter(
                      glowIntensity: _glowAnimation.value,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16, right: 16),
        title: LayoutBuilder(
          builder: (context, constraints) {
            final isExpanded = constraints.maxHeight > 100;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: Row(
                children: [
                  if (!isExpanded)
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.darkBorder.withOpacity(0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: AppTheme.textWhite,
                          size: 18,
                        ),
                      ),
                    ),
                  if (!isExpanded) const SizedBox(width: 12),
                  Expanded(
                    child: ShaderMask(
                      shaderCallback: (bounds) =>
                          AppTheme.primaryGradient.createShader(bounds),
                      child: Text(
                        isExpanded ? 'إدارة القنوات' : 'القنوات',
                        style: isExpanded
                            ? AppTextStyles.heading1.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color:
                                        AppTheme.primaryBlue.withOpacity(0.3),
                                    blurRadius: 10,
                                  ),
                                ],
                              )
                            : AppTextStyles.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                      ),
                    ),
                  ),
                  if (isExpanded) ...[
                    _buildStatToggleButton(),
                    const SizedBox(width: 8),
                    _buildSortButton(),
                  ],
                ],
              ),
            );
          },
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryBlue.withOpacity(0.1),
                AppTheme.darkBackground.withOpacity(0.9),
                AppTheme.darkBackground,
              ],
            ),
          ),
        ),
      ),
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.darkCard.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.3),
            ),
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.textWhite,
            size: 20,
          ),
        ),
      ),
      actions: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: IconButton(
                onPressed: _loadStatistics,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatToggleButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _showStats = !_showStats);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: _showStats ? AppTheme.primaryGradient : null,
          color: _showStats ? null : AppTheme.darkCard.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          boxShadow: _showStats
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          Icons.analytics_rounded,
          color: _showStats ? Colors.white : AppTheme.textMuted,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    return GestureDetector(
      onTap: _showSortOptions,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.darkBorder.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isAscending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: AppTheme.textMuted,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              _getSortLabel(),
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _statsSectionHeight(BuildContext context) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final clampedScale = textScaleFactor.clamp(1.0, 1.35);
    return _baseStatsSectionHeight * clampedScale;
  }

  Widget _buildStatisticsSection() {
    return SliverToBoxAdapter(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: !_showStats
            ? const SizedBox.shrink()
            : BlocBuilder<ChannelsBloc, ChannelsState>(
                builder: (context, state) {
                  if (state.statistics == null) {
                    return _buildStatisticsLoading(context);
                  }

                  final statsHeight = _statsSectionHeight(context);
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        height: statsHeight,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: AnimationLimiter(
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: AnimationConfiguration.toStaggeredList(
                              duration: const Duration(milliseconds: 375),
                              childAnimationBuilder: (widget) => SlideAnimation(
                                horizontalOffset: 50.0,
                                child: FadeInAnimation(child: widget),
                              ),
                              children: [
                                _buildStatCard(
                                  title: 'إجمالي القنوات',
                                  value: state.statistics!.totalChannels
                                      .toString(),
                                  icon: Icons.dashboard_rounded,
                                  color: AppTheme.primaryBlue,
                                  trend: '+12%',
                                  isPositive: true,
                                ),
                                const SizedBox(width: 12),
                                _buildStatCard(
                                  title: 'القنوات النشطة',
                                  value: state.statistics!.activeChannels
                                      .toString(),
                                  icon: Icons.check_circle_rounded,
                                  color: AppTheme.success,
                                  trend: '+8%',
                                  isPositive: true,
                                ),
                                const SizedBox(width: 12),
                                _buildStatCard(
                                  title: 'إجمالي المشتركين',
                                  value: _formatNumber(
                                      state.statistics!.totalSubscriptions),
                                  icon: Icons.people_rounded,
                                  color: AppTheme.primaryPurple,
                                  trend: '+24%',
                                  isPositive: true,
                                ),
                                const SizedBox(width: 12),
                                _buildStatCard(
                                  title: 'الإشعارات المرسلة',
                                  value: _formatNumber(
                                      state.statistics!.totalNotificationsSent),
                                  icon: Icons.send_rounded,
                                  color: AppTheme.warning,
                                  trend: '+156',
                                  isPositive: true,
                                ),
                                const SizedBox(width: 12),
                                _buildStatCard(
                                  title: 'معدل القراءة',
                                  value: '87%',
                                  icon: Icons.visibility_rounded,
                                  color: AppTheme.info,
                                  trend: '-2%',
                                  isPositive: false,
                                ),
                              ],
                            ),
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

  Widget _buildStatisticsLoading(BuildContext context) {
    return Container(
      height: _statsSectionHeight(context),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
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
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
    required bool isPositive,
  }) {
    return MouseRegion(
      onEnter: (_) => HapticFeedback.selectionClick(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                onTap: () => _navigateToStatDetails(title),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              icon,
                              color: color,
                              size: 22,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isPositive
                                  ? AppTheme.success.withOpacity(0.1)
                                  : AppTheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isPositive
                                      ? Icons.trending_up_rounded
                                      : Icons.trending_down_rounded,
                                  size: 12,
                                  color: isPositive
                                      ? AppTheme.success
                                      : AppTheme.error,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  trend,
                                  style: AppTextStyles.caption.copyWith(
                                    color: isPositive
                                        ? AppTheme.success
                                        : AppTheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value,
                            style: AppTextStyles.heading2.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textLight,
                            ),
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
      ),
    );
  }

  Widget _buildFiltersSection() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ChannelFilters(
            onSearchChanged: (query) {
              setState(() => _searchQuery = query);
              _loadChannels();
            },
            onTypeChanged: (type) {
              setState(() => _selectedType = type);
              _loadChannels();
            },
            onActiveFilterChanged: (isActive) {
              setState(() => _isActiveFilter = isActive);
              _loadChannels();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChannelsList() {
    return BlocBuilder<ChannelsBloc, ChannelsState>(
      builder: (context, state) {
        if (state.isLoading && state.channels.isEmpty) {
          return const SliverFillRemaining(
            child: LoadingWidget(
              type: LoadingType.futuristic,
              message: 'جاري تحميل القنوات...',
            ),
          );
        }

        if (state.error != null && state.channels.isEmpty) {
          return SliverFillRemaining(
            child: CustomErrorWidget(
              message: state.error!,
              onRetry: _loadChannels,
              type: ErrorType.general,
            ),
          );
        }

        if (state.channels.isEmpty) {
          return SliverFillRemaining(
            child: EmptyWidget(
              message: 'لا توجد قنوات',
              icon: Icons.notifications_off_rounded,
              actionWidget: _buildCreateChannelButton(),
            ),
          );
        }

        final sortedChannels = _sortChannels(state.channels);

        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final channel = sortedChannels[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildChannelCard(channel, index),
                    ),
                  ),
                );
              },
              childCount: sortedChannels.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildChannelCard(NotificationChannel channel, int index) {
    final isHovered = _hoveredChannelId == channel.id;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: MouseRegion(
            onEnter: (_) => setState(() => _hoveredChannelId = channel.id),
            onExit: (_) => setState(() => _hoveredChannelId = null),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: Matrix4.identity()
                ..translate(0.0, isHovered ? -5.0 : 0.0),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: channel.isActive
                        ? AppTheme.primaryBlue
                            .withOpacity(isHovered ? 0.2 : 0.1)
                        : AppTheme.shadowDark.withOpacity(0.1),
                    blurRadius: isHovered ? 20 : 15,
                    offset: Offset(0, isHovered ? 8 : 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isHovered
                            ? [
                                AppTheme.primaryBlue.withOpacity(0.08),
                                AppTheme.primaryPurple.withOpacity(0.04),
                              ]
                            : [
                                AppTheme.darkCard.withOpacity(0.7),
                                AppTheme.darkCard.withOpacity(0.5),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: channel.isActive
                            ? AppTheme.primaryBlue
                                .withOpacity(isHovered ? 0.4 : 0.2)
                            : AppTheme.darkBorder.withOpacity(0.3),
                        width: isHovered ? 2 : 1,
                      ),
                    ),
                    child: ChannelCard(
                      channel: channel,
                      onTap: () => _navigateToChannelDetails(channel),
                      onEdit: () => _navigateToEditChannel(channel),
                      onDelete: () => _confirmDeleteChannel(channel),
                      onManageUsers: () => _navigateToManageUsers(channel),
                      onSendNotification: () =>
                          _navigateToSendNotification(channel),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _floatingButtonController,
      builder: (context, child) {
        return Transform.scale(
          scale: _floatingButtonController.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius:
                  BorderRadius.circular(_isFloatingButtonExpanded ? 24 : 20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppTheme.primaryPurple.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _navigateToCreateChannel,
                borderRadius:
                    BorderRadius.circular(_isFloatingButtonExpanded ? 24 : 20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.symmetric(
                    horizontal: _isFloatingButtonExpanded ? 24 : 20,
                    vertical: _isFloatingButtonExpanded ? 16 : 20,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        child: _isFloatingButtonExpanded
                            ? const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text(
                                  'قناة جديدة',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
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

  Widget _buildCreateChannelButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToCreateChannel,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'إنشاء قناة جديدة',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteChannel(NotificationChannel channel) {
    if (!channel.isDeletable) {
      _showErrorMessage('لا يمكن حذف قنوات النظام');
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: _DeleteConfirmationDialog(
            channel: channel,
            onConfirm: () {
              Navigator.pop(ctx);
              _deleteChannel(channel);
            },
            onCancel: () => Navigator.pop(ctx),
          ),
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _SortOptionsSheet(
        currentSort: _sortBy,
        isAscending: _isAscending,
        onSortChanged: (sortBy, isAscending) {
          setState(() {
            _sortBy = sortBy;
            _isAscending = isAscending;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  List<NotificationChannel> _sortChannels(List<NotificationChannel> channels) {
    final sorted = List<NotificationChannel>.from(channels);

    sorted.sort((a, b) {
      int comparison = 0;

      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'date':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'subscribers':
          comparison = a.subscribersCount.compareTo(b.subscribersCount);
          break;
        case 'activity':
          final aActivity =
              a.lastNotificationAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bActivity =
              b.lastNotificationAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          comparison = aActivity.compareTo(bActivity);
          break;
      }

      return _isAscending ? comparison : -comparison;
    });

    return sorted;
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'name':
        return 'الاسم';
      case 'date':
        return 'التاريخ';
      case 'subscribers':
        return 'المشتركين';
      case 'activity':
        return 'النشاط';
      default:
        return 'ترتيب';
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  void _navigateToCreateChannel() {
    HapticFeedback.lightImpact();
    context.push('/admin/notification-channels/create');
  }

  void _navigateToEditChannel(NotificationChannel channel) {
    HapticFeedback.lightImpact();
    context.push('/admin/notification-channels/${channel.id}/edit');
  }

  void _navigateToChannelDetails(NotificationChannel channel) {
    HapticFeedback.lightImpact();
    context.push('/admin/notification-channels/${channel.id}');
  }

  void _navigateToManageUsers(NotificationChannel channel) {
    HapticFeedback.lightImpact();
    context.push('/admin/notification-channels/${channel.id}/users');
  }

  void _navigateToSendNotification(NotificationChannel channel) {
    HapticFeedback.lightImpact();
    context.push('/admin/notifications/broadcast?channelId=${channel.id}');
  }

  void _navigateToStatDetails(String statType) {
    HapticFeedback.lightImpact();
    // Navigate to statistics details page
  }

  void _deleteChannel(NotificationChannel channel) {
    HapticFeedback.mediumImpact();
    context.read<ChannelsBloc>().add(DeleteChannelEvent(channel.id));
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message),
            ),
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

// Delete Confirmation Dialog
class _DeleteConfirmationDialog extends StatelessWidget {
  final NotificationChannel channel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _DeleteConfirmationDialog({
    required this.channel,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.95),
            AppTheme.darkCard.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.error.withOpacity(0.2),
                  AppTheme.error.withOpacity(0.1),
                ],
              ),
            ),
            child: Icon(
              Icons.delete_rounded,
              color: AppTheme.error,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'حذف القناة',
            style: AppTextStyles.heading2.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'هل أنت متأكد من حذف قناة "${channel.name}"؟',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          if (channel.subscribersCount > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.warning.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: AppTheme.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'هذه القناة لديها ${channel.subscribersCount} مشترك',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.darkBorder.withOpacity(0.3),
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                          blurRadius: 8,
                          offset: const Offset(0, 4),
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
    );
  }
}

// Sort Options Sheet
class _SortOptionsSheet extends StatelessWidget {
  final String currentSort;
  final bool isAscending;
  final Function(String, bool) onSortChanged;

  const _SortOptionsSheet({
    required this.currentSort,
    required this.isAscending,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.95),
            AppTheme.darkCard.withOpacity(0.85),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
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
                'ترتيب القنوات',
                style: AppTextStyles.heading3.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildSortOption(
                'الاسم',
                'name',
                Icons.sort_by_alpha_rounded,
                AppTheme.primaryBlue,
              ),
              _buildSortOption(
                'التاريخ',
                'date',
                Icons.calendar_today_rounded,
                AppTheme.primaryPurple,
              ),
              _buildSortOption(
                'المشتركين',
                'subscribers',
                Icons.people_rounded,
                AppTheme.warning,
              ),
              _buildSortOption(
                'النشاط',
                'activity',
                Icons.trending_up_rounded,
                AppTheme.success,
              ),
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOrderOption(
                      'تصاعدي',
                      true,
                      Icons.arrow_upward_rounded,
                    ),
                    _buildOrderOption(
                      'تنازلي',
                      false,
                      Icons.arrow_downward_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final isSelected = currentSort == value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSortChanged(value, isAscending),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      color.withOpacity(0.2),
                      color.withOpacity(0.1),
                    ],
                  )
                : null,
            color: !isSelected ? AppTheme.darkSurface.withOpacity(0.3) : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? color.withOpacity(0.4)
                  : AppTheme.darkBorder.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? color : AppTheme.textMuted,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected ? color : AppTheme.textLight,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_rounded,
                  color: color,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderOption(String label, bool ascending, IconData icon) {
    final isSelected = isAscending == ascending;

    return GestureDetector(
      onTap: () => onSortChanged(currentSort, ascending),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: !isSelected ? AppTheme.darkCard.withOpacity(0.5) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppTheme.darkBorder.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.textMuted,
              size: 18,
            ),
            const SizedBox(width: 8),
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
}

// Background Painter
class _ChannelsBackgroundPainter extends CustomPainter {
  final double glowIntensity;

  _ChannelsBackgroundPainter({required this.glowIntensity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = AppTheme.primaryBlue.withOpacity(0.03 * glowIntensity);

    // Draw grid pattern
    const spacing = 30.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }

    // Draw diagonal lines
    paint.color = AppTheme.primaryPurple.withOpacity(0.02 * glowIntensity);
    for (double i = -size.height; i < size.width; i += spacing * 2) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
