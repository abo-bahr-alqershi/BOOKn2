// lib/features/admin_cities/presentation/pages/admin_cities_page.dart

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
import '../bloc/cities_bloc.dart';
import '../bloc/cities_event.dart';
import '../bloc/cities_state.dart';
import '../widgets/futuristic_cities_grid.dart';
import '../widgets/city_stats_card.dart';
import '../widgets/city_search_bar.dart';
import '../../domain/entities/city.dart';

class AdminCitiesPage extends StatefulWidget {
  const AdminCitiesPage({super.key});

  @override
  State<AdminCitiesPage> createState() => _AdminCitiesPageState();
}

class _AdminCitiesPageState extends State<AdminCitiesPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late AnimationController _statsAnimationController;
  final ScrollController _scrollController = ScrollController();

  bool _isGridView = true;
  bool _showStats = true;
  String? _selectedCountry;
  bool? _activeFilter;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _statsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _loadCities();
    _loadStatistics();
  }

  void _loadCities() {
    context.read<CitiesBloc>().add(const LoadCitiesEvent());
  }

  void _loadStatistics() {
    context.read<CitiesBloc>().add(LoadCitiesStatisticsEvent());
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    _statsAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: BlocListener<CitiesBloc, CitiesState>(
        listener: _handleStateChanges,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            _buildSliverAppBar(),
            _buildStatsSection(),
            _buildSearchSection(),
            _buildFilterChips(),
            _buildCitiesContent(),
          ],
        ),
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
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Row(
          children: [
            // Animated Icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                          blurRadius: 10 * value,
                          offset: Offset(0, 5 * value),
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.building_2_fill,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Text(
              'إدارة المدن',
              style: AppTextStyles.heading1.copyWith(
                color: AppTheme.textWhite,
                shadows: [
                  Shadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ],
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
          child: Stack(
            children: [
              // Background pattern
              ...List.generate(5, (index) {
                return Positioned(
                  top: -50 + (index * 30).toDouble(),
                  right: -50 + (index * 40).toDouble(),
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.primaryBlue.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        _buildActionButton(
          icon: CupertinoIcons.plus,
          onPressed: () => _showCityForm(),
        ),
        _buildActionButton(
          icon: _showStats
              ? CupertinoIcons.chart_bar_square_fill
              : CupertinoIcons.chart_bar_square,
          onPressed: () {
            setState(() => _showStats = !_showStats);
            if (_showStats) {
              _statsAnimationController.forward();
            } else {
              _statsAnimationController.reverse();
            }
          },
          isActive: _showStats,
        ),
        _buildActionButton(
          icon: _isGridView
              ? CupertinoIcons.list_bullet
              : CupertinoIcons.square_grid_2x2,
          onPressed: () => setState(() => _isGridView = !_isGridView),
        ),
        _buildActionButton(
          icon: CupertinoIcons.arrow_clockwise,
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.read<CitiesBloc>().add(const RefreshCitiesEvent());
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withValues(alpha: 0.2),
                  AppTheme.primaryPurple.withValues(alpha: 0.1),
                ],
              )
            : null,
        color: isActive ? null : AppTheme.darkCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppTheme.primaryBlue.withValues(alpha: 0.3)
              : AppTheme.darkBorder.withValues(alpha: 0.3),
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

  Widget _buildStatsSection() {
    return SliverToBoxAdapter(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _showStats ? 130 : 0,
        child: _showStats
            ? BlocBuilder<CitiesBloc, CitiesState>(
                builder: (context, state) {
                  if (state is CitiesLoaded && state.statistics != null) {
                    return SizeTransition(
                      sizeFactor: CurvedAnimation(
                        parent: _statsAnimationController,
                        curve: Curves.easeOutBack,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: CityStatsCard(
                          statistics: state.statistics!,
                          citiesCount: state.cities.length,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildSearchSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: CitySearchBar(
          onChanged: (query) {
            context.read<CitiesBloc>().add(SearchCitiesEvent(query: query));
          },
          onFilterTap: _showFilterOptions,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SliverToBoxAdapter(
      child: BlocBuilder<CitiesBloc, CitiesState>(
        builder: (context, state) {
          if (state is! CitiesLoaded) return const SizedBox.shrink();

          final countries =
              state.cities.map((city) => city.country).toSet().toList();

          if (countries.isEmpty) return const SizedBox.shrink();

          return Container(
            height: 40,
            margin: const EdgeInsets.only(bottom: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: countries.length + 2, // +2 for "All" and active filter
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildFilterChip(
                    label: 'الكل',
                    isSelected:
                        _selectedCountry == null && _activeFilter == null,
                    onTap: () {
                      setState(() {
                        _selectedCountry = null;
                        _activeFilter = null;
                      });
                      _loadCities();
                    },
                  );
                } else if (index == 1) {
                  return _buildFilterChip(
                    label: 'نشط فقط',
                    isSelected: _activeFilter == true,
                    onTap: () {
                      setState(() {
                        _activeFilter = _activeFilter == true ? null : true;
                      });
                      context.read<CitiesBloc>().add(LoadCitiesEvent(
                            isActive: _activeFilter,
                            country: _selectedCountry,
                          ));
                    },
                    icon: CupertinoIcons.checkmark_circle,
                  );
                }

                final country = countries[index - 2];
                return _buildFilterChip(
                  label: country,
                  isSelected: _selectedCountry == country,
                  onTap: () {
                    setState(() => _selectedCountry = country);
                    context.read<CitiesBloc>().add(LoadCitiesEvent(
                          country: country,
                          isActive: _activeFilter,
                        ));
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: isSelected ? AppTheme.primaryGradient : null,
              color:
                  isSelected ? null : AppTheme.darkCard.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : AppTheme.darkBorder.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected ? Colors.white : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected ? Colors.white : AppTheme.textLight,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCitiesContent() {
    return BlocBuilder<CitiesBloc, CitiesState>(
      builder: (context, state) {
        if (state is CitiesLoading) {
          return const SliverFillRemaining(
            child: LoadingWidget(
              type: LoadingType.futuristic,
              message: 'جاري تحميل المدن...',
            ),
          );
        }

        if (state is CitiesError) {
          return SliverFillRemaining(
            child: CustomErrorWidget(
              message: state.message,
              onRetry: _loadCities,
            ),
          );
        }

        if (state is CitiesLoaded) {
          if (state.filteredCities.isEmpty) {
            return SliverFillRemaining(
              child: EmptyWidget(
                message: state.searchQuery != null
                    ? 'لا توجد نتائج للبحث "${state.searchQuery}"'
                    : 'لا توجد مدن مضافة حالياً',
                actionWidget:
                    state.searchQuery == null ? _buildAddCityButton() : null,
              ),
            );
          }

          return SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: FuturisticCitiesGrid(
              cities: state.filteredCities,
              isGridView: _isGridView,
              onCityTap: (city) => _showCityDetails(city),
              onCityEdit: (city) => _showCityForm(city: city),
              onCityDelete: (city) => _confirmDeleteCity(city),
            ),
          );
        }

        return const SliverFillRemaining(child: SizedBox.shrink());
      },
    );
  }

  // Removed FAB: Add action moved to AppBar

  Widget _buildAddCityButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCityForm(),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.plus_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'إضافة أول مدينة',
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

  void _handleStateChanges(BuildContext context, CitiesState state) {
    if (state is CityOperationInProgress && state.operation == 'deleting') {
      _showDeletingDialog(cityName: state.cityName);
    } else if (state is CityOperationSuccess) {
      _dismissDeletingDialog();
      _showSuccessMessage(state.message);
    } else if (state is CityOperationFailure) {
      _dismissDeletingDialog();
      _showErrorMessage(state.message);
    }
  }

  bool _isDeleting = false;
  void _showDeletingDialog({String? cityName}) {
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
              type: LoadingType.futuristic, message: 'جاري حذف المدينة...'),
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

  Future<void> _showCityForm({City? city}) async {
    HapticFeedback.lightImpact();

    final String path = city == null
        ? '/admin/cities/create'
        : '/admin/cities/${Uri.encodeComponent(city.name)}/edit';

    await context.push<City>(
      path,
      extra: city,
    );

    if (!mounted) return;
    // عند الرجوع من صفحة الإنشاء/التعديل قم بتحديث القائمة مباشرةً
    context.read<CitiesBloc>().add(const RefreshCitiesEvent());
  }

  void _showCityDetails(City city) {
    HapticFeedback.lightImpact();
    // Navigate to city details page
  }

  void _confirmDeleteCity(City city) {
    HapticFeedback.mediumImpact();
    showDialog(
      fullscreenDialog: true,
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => BackdropFilter(
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
                  'حذف المدينة؟',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'هل أنت متأكد من حذف ${city.name}?\nلا يمكن التراجع عن هذا الإجراء.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
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
                          Navigator.pop(dialogContext);
                          context
                              .read<CitiesBloc>()
                              .add(DeleteCityEvent(name: city.name));
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

  void _showFilterOptions() {
    HapticFeedback.mediumImpact();
    // Show filter bottom sheet
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(CupertinoIcons.checkmark_circle_fill,
                color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
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

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
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
