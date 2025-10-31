import 'package:bookn_cp_app/core/widgets/error_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/empty_widget.dart';
import '../../domain/entities/section.dart';
import '../bloc/sections_list/sections_list_bloc.dart';
import '../bloc/sections_list/sections_list_event.dart';
import '../bloc/sections_list/sections_list_state.dart';
import '../widgets/futuristic_section_card.dart';
import '../widgets/futuristic_sections_table.dart';
import '../widgets/section_stats_card.dart';
import '../widgets/section_preview_widget.dart';

// تعداد لطرق العرض المختلفة
enum ViewMode {
  compact, // عرض مضغوط
  expanded, // عرض موسع
  grid, // عرض شبكي
  table, // عرض جدولي (للشاشات الكبيرة فقط)
}

class SectionsListPage extends StatefulWidget {
  const SectionsListPage({super.key});

  @override
  State<SectionsListPage> createState() => _SectionsListPageState();
}

class _SectionsListPageState extends State<SectionsListPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseAnimationController;
  final ScrollController _scrollController = ScrollController();

  ViewMode _currentViewMode = ViewMode.table; // الوضع الافتراضي
  bool _showFilters = false;
  Map<String, dynamic> _activeFilters = {};

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

    _loadSections();
    _setupScrollListener();
  }

  void _loadSections() {
    context.read<SectionsListBloc>().add(
          const LoadSectionsEvent(
            pageNumber: 1,
            pageSize: 20,
          ),
        );
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final state = context.read<SectionsListBloc>().state;
        if (state is SectionsListLoaded && state.page.hasNextPage) {
          context.read<SectionsListBloc>().add(
                ChangeSectionsPageEvent(state.page.nextPageNumber!),
              );
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseAnimationController.dispose();
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
                _buildStatsSection(),
                _buildFilterSection(),
                _buildSectionsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _pulseAnimationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkBackground,
                AppTheme.darkBackground2.withValues(alpha: 0.8),
                AppTheme.darkBackground3.withValues(alpha: 0.6),
              ],
            ),
          ),
          child: CustomPaint(
            painter: _SectionsBackgroundPainter(
              glowIntensity: _pulseAnimationController.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: ShaderMask(
          shaderCallback: (bounds) =>
              AppTheme.primaryGradient.createShader(bounds),
          child: Text(
            'الأقسام',
            style: AppTextStyles.heading1.copyWith(
              color: Colors.white,
              shadows: [
                Shadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
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
          onPressed: _navigateToCreate,
        ),
        _buildViewModeButton(),
        _buildActionButton(
          icon: _showFilters
              ? CupertinoIcons.xmark
              : CupertinoIcons.slider_horizontal_3,
          onPressed: () => setState(() => _showFilters = !_showFilters),
        ),
        _buildActionButton(
          icon: CupertinoIcons.arrow_clockwise,
          onPressed: _loadSections,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildViewModeButton() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 500;
    final isMediumScreen = screenWidth < 768;

    // تحديد الأيقونة والوضع التالي
    IconData icon;
    String message;

    switch (_currentViewMode) {
      case ViewMode.compact:
        icon = CupertinoIcons.square_stack;
        message = 'تم التبديل للعرض الموسع';
        break;
      case ViewMode.expanded:
        if (isSmallScreen) {
          icon = CupertinoIcons.rectangle_grid_1x2;
          message = 'تم التبديل للعرض الشبكي المحسن';
        } else {
          icon = CupertinoIcons.square_grid_2x2;
          message = 'تم التبديل للعرض الشبكي';
        }
        break;
      case ViewMode.grid:
        if (!isSmallScreen && !isMediumScreen) {
          icon = CupertinoIcons.table;
          message = 'تم التبديل للعرض الجدولي';
        } else {
          icon = CupertinoIcons.rectangle_compress_vertical;
          message = 'تم التبديل للعرض المضغوط';
        }
        break;
      case ViewMode.table:
        icon = CupertinoIcons.rectangle_compress_vertical;
        message = 'تم التبديل للعرض المضغوط';
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentViewMode = _getNextViewMode();
            });

            // عرض رسالة توضيحية
            ScaffoldMessenger.of(context).clearSnackBars();
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

  ViewMode _getNextViewMode() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 500;
    final isMediumScreen = screenWidth < 768;
    if (!isSmallScreen && !isMediumScreen) {
      switch (_currentViewMode) {
        case ViewMode.compact:
          return ViewMode.expanded;
        case ViewMode.expanded:
          return ViewMode.grid;
        case ViewMode.grid:
          // في الشاشات الكبيرة فقط نعرض الجدول
          if (!isSmallScreen && !isMediumScreen) {
            return ViewMode.table;
          }
          return ViewMode.compact;
        case ViewMode.table:
          return ViewMode.compact;
      }
    }
    return _currentViewMode == ViewMode.table
        ? ViewMode.expanded
        : ViewMode.table;
  }

  void _showSectionPreview(Section section) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: SectionPreviewWidget(
                  section: section,
                  isExpanded: false,
                  onExpand: () {
                    Navigator.pop(context);
                    _showExpandedSectionPreview(section);
                  },
                  onEdit: () {
                    Navigator.pop(context);
                    _navigateToEdit(section.id);
                  },
                  onManageItems: () {
                    Navigator.pop(context);
                    _navigateToManageItems(section);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpandedSectionPreview(Section section) {
    showDialog(
      fullscreenDialog: true,
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(10),
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'معاينة القسم',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppTheme.textWhite,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SectionPreviewWidget(
                    section: section,
                    isExpanded: true,
                    onEdit: () {
                      Navigator.pop(context);
                      _navigateToEdit(section.id);
                    },
                    onManageItems: () {
                      Navigator.pop(context);
                      _navigateToManageItems(section);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToManageItems(Section section) {
    context.push('/admin/sections/${section.id}/items', extra: section.target);
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
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
      child: BlocBuilder<SectionsListBloc, SectionsListState>(
        builder: (context, state) {
          if (state is! SectionsListLoaded) return const SizedBox.shrink();

          // حساب الارتفاع بناءً على حجم الشاشة
          final screenWidth = MediaQuery.of(context).size.width;
          final statsHeight = screenWidth < 400
              ? 140.0 // للهواتف الصغيرة
              : screenWidth < 600
                  ? 150.0 // للهواتف المتوسطة
                  : 160.0; // للأجهزة اللوحية والكبيرة

          return AnimationLimiter(
            child: Container(
              height: statsHeight,
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth < 400 ? 8 : 16,
                vertical: 8,
              ),
              child: SectionStatsCard(
                sections: state.page.items,
                totalCount: state.page.totalCount,
                onRefresh: _loadSections,
                onStatTap: (type) {
                  // handle stat tap
                },
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
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildFiltersRow(),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildFiltersRow() {
    return Row(
      children: [
        Expanded(
          child: _buildFilterChip(
            label: 'النوع',
            value: _activeFilters['type'],
            onTap: () => _showFilterDialog('type'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterChip(
            label: 'المحتوى',
            value: _activeFilters['contentType'],
            onTap: () => _showFilterDialog('contentType'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterChip(
            label: 'الهدف',
            value: _activeFilters['target'],
            onTap: () => _showFilterDialog('target'),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _clearFilters,
          icon: Icon(
            CupertinoIcons.xmark_circle_fill,
            color: AppTheme.error,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    dynamic value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: value != null ? AppTheme.primaryGradient : null,
          color:
              value == null ? AppTheme.darkCard.withValues(alpha: 0.5) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value != null
                ? Colors.transparent
                : AppTheme.darkBorder.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: value != null ? Colors.white : AppTheme.textMuted,
                fontWeight: value != null ? FontWeight.w600 : null,
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 4),
              const Icon(
                CupertinoIcons.checkmark_circle_fill,
                size: 12,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionsList() {
    return BlocBuilder<SectionsListBloc, SectionsListState>(
      builder: (context, state) {
        if (state is SectionsListLoading) {
          return const SliverFillRemaining(
            child: LoadingWidget(
              type: LoadingType.futuristic,
              message: 'جاري تحميل الأقسام...',
            ),
          );
        }

        if (state is SectionsListError) {
          return SliverFillRemaining(
            child: CustomErrorWidget(
              message: state.message,
              onRetry: _loadSections,
            ),
          );
        }

        if (state is SectionsListLoaded) {
          if (state.page.items.isEmpty) {
            return const SliverFillRemaining(
              child: EmptyWidget(
                message: 'لا توجد أقسام حالياً',
              ),
            );
          }

          // اختيار طريقة العرض بناءً على الوضع الحالي
          switch (_currentViewMode) {
            case ViewMode.compact:
              return _buildListView(state.page.items, CardDisplayMode.compact);
            case ViewMode.expanded:
              return _buildListView(state.page.items, CardDisplayMode.expanded);
            case ViewMode.grid:
              final screenWidth = MediaQuery.of(context).size.width;
              if (screenWidth < 500) {
                // في الشاشات الصغيرة نعرض قائمة بتصميم grid محسن
                return _buildOptimizedGridList(state.page.items);
              }
              return _buildGridView(state.page.items);
            case ViewMode.table:
              return _buildTableView(state.page.items);
          }
        }

        return const SliverFillRemaining(child: SizedBox.shrink());
      },
    );
  }

  Widget _buildListView(List<Section> sections, CardDisplayMode cardMode) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(
          horizontal: cardMode == CardDisplayMode.compact ? 8 : 12,
          vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final section = sections[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 30.0,
                child: FadeInAnimation(
                  child: Padding(
                    padding: EdgeInsets.only(
                        bottom: cardMode == CardDisplayMode.compact ? 8 : 12),
                    child: FuturisticSectionCard(
                      section: section,
                      onTap: () => _showSectionPreview(section),
                      onEdit: () => _navigateToEdit(section.id),
                      onDelete: () => _confirmDelete(section),
                      onToggleStatus: () => _toggleStatus(section),
                      onManageItems: () => _navigateToManageItems(section),
                      cardMode: cardMode,
                    ),
                  ),
                ),
              ),
            );
          },
          childCount: sections.length,
        ),
      ),
    );
  }

  // قائمة محسنة للشاشات الصغيرة بتصميم شبكي
  Widget _buildOptimizedGridList(List<Section> sections) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final section = sections[index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 375),
              columnCount: 2,
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: FuturisticSectionCard(
                    section: section,
                    onTap: () => _showSectionPreview(section),
                    onEdit: () => _navigateToEdit(section.id),
                    onDelete: () => _confirmDelete(section),
                    onToggleStatus: () => _toggleStatus(section),
                    onManageItems: () => _navigateToManageItems(section),
                    cardMode: CardDisplayMode.grid,
                  ),
                ),
              ),
            );
          },
          childCount: sections.length,
        ),
      ),
    );
  }

  Widget _buildGridView(List<Section> sections) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;

          int crossAxisCount;
          double childAspectRatio;
          double spacing;

          if (screenWidth < 768) {
            crossAxisCount = 2;
            childAspectRatio = 0.95;
            spacing = 12;
          } else if (screenWidth < 1024) {
            crossAxisCount = 3;
            childAspectRatio = 0.9;
            spacing = 16;
          } else if (screenWidth < 1440) {
            crossAxisCount = 4;
            childAspectRatio = 0.85;
            spacing = 16;
          } else {
            crossAxisCount = 5;
            childAspectRatio = 0.85;
            spacing = 20;
          }

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: childAspectRatio,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final section = sections[index];
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  columnCount: crossAxisCount,
                  child: ScaleAnimation(
                    child: FadeInAnimation(
                      child: FuturisticSectionCard(
                        section: section,
                        onTap: () => _showSectionPreview(section),
                        onEdit: () => _navigateToEdit(section.id),
                        onDelete: () => _confirmDelete(section),
                        onToggleStatus: () => _toggleStatus(section),
                        onManageItems: () => _navigateToManageItems(section),
                        cardMode: CardDisplayMode.grid,
                      ),
                    ),
                  ),
                );
              },
              childCount: sections.length,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTableView(List<Section> sections) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FuturisticSectionsTable(
          sections: sections,
          onSectionTap: _navigateToDetails,
          onEdit: _navigateToEdit,
          onDelete: _confirmDelete,
          onToggleStatus: _toggleStatus,
          onManageItems: _navigateToManageItems,
        ),
      ),
    );
  }

  // Removed FAB: Add action moved to AppBar

  void _navigateToCreate() {
    HapticFeedback.lightImpact();
    context.push('/admin/sections/create').then((value) {
      if (value == true) {
        _loadSections();
      }
    });
  }

  void _navigateToDetails(String sectionId) {
    context.push('/admin/sections/$sectionId');
  }

  void _navigateToEdit(String sectionId) {
    context.push('/admin/sections/$sectionId/edit').then((value) {
      if (value == true) {
        _loadSections();
      }
    });
  }

  void _toggleStatus(Section section) {
    context.read<SectionsListBloc>().add(
          ToggleSectionStatusEvent(
            sectionId: section.id,
            isActive: !section.isActive,
          ),
        );
  }

  void _confirmDelete(Section section) {
    showDialog(
      fullscreenDialog: true,
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Text(
          'حذف القسم',
          style: AppTextStyles.heading3.copyWith(color: AppTheme.textWhite),
        ),
        content: Text(
          'هل أنت متأكد من حذف القسم "${section.title ?? section.name}"؟',
          style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'إلغاء',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(AppTheme.error),
            ),
            onPressed: () {
              context.read<SectionsListBloc>().add(
                    DeleteSectionEvent(section.id),
                  );
              Navigator.of(ctx).pop();
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(String filterType) {
    // TODO: Implement filter dialog
  }

  void _clearFilters() {
    setState(() {
      _activeFilters = {};
    });
    _loadSections();
  }
}

class _SectionsBackgroundPainter extends CustomPainter {
  final double glowIntensity;

  _SectionsBackgroundPainter({required this.glowIntensity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.shader = RadialGradient(
      colors: [
        AppTheme.primaryBlue.withValues(alpha: 0.1 * glowIntensity),
        AppTheme.primaryBlue.withValues(alpha: 0.05 * glowIntensity),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.8, size.height * 0.2),
      radius: 150,
    ));

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      150,
      paint,
    );

    paint.shader = RadialGradient(
      colors: [
        AppTheme.primaryPurple.withValues(alpha: 0.1 * glowIntensity),
        AppTheme.primaryPurple.withValues(alpha: 0.05 * glowIntensity),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.2, size.height * 0.7),
      radius: 100,
    ));

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.7),
      100,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
