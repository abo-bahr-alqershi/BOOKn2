// lib/features/admin_hub/presentation/widgets/screen_search_dialog.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/searchable_screen.dart';
import '../../data/services/screen_search_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class ScreenSearchDialog extends StatefulWidget {
  final ScreenSearchService searchService;

  const ScreenSearchDialog({
    super.key,
    required this.searchService,
  });

  @override
  State<ScreenSearchDialog> createState() => _ScreenSearchDialogState();
}

class _ScreenSearchDialogState extends State<ScreenSearchDialog>
    with TickerProviderStateMixin {
  // Controllers
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  // State
  List<SearchableScreen> _searchResults = [];
  List<SearchableScreen> _quickSuggestions = [];
  List<String> _searchHistory = [];
  bool _isSearching = false;
  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeControllers();
    _loadInitialData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  void _initializeControllers() {
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();

    _searchController.addListener(_onSearchChanged);

    // Auto-focus on the search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _loadInitialData() async {
    final (isAdmin, isOwner) = context.select((AuthBloc bloc) {
      final s = bloc.state;
      if (s is AuthAuthenticated) return (s.user.isAdmin, s.user.isOwner);
      if (s is AuthLoginSuccess) return (s.user.isAdmin, s.user.isOwner);
      if (s is AuthProfileUpdateSuccess) return (s.user.isAdmin, s.user.isOwner);
      if (s is AuthProfileImageUploadSuccess) return (s.user.isAdmin, s.user.isOwner);
      return (false, false);
    });

    final quickSuggestions = widget.searchService
        .getQuickSuggestions()
        .where((s) => isAdmin || !s.adminOnly || (isOwner && s.visibleForOwner))
        .toList();
    final searchHistory = await widget.searchService.getSearchHistory();

    setState(() {
      _quickSuggestions = quickSuggestions;
      _searchHistory = searchHistory;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text;

    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _searchResults = [];
      } else {
        final (isAdmin, isOwner) = context.select((AuthBloc bloc) {
          final s = bloc.state;
          if (s is AuthAuthenticated) return (s.user.isAdmin, s.user.isOwner);
          if (s is AuthLoginSuccess) return (s.user.isAdmin, s.user.isOwner);
          if (s is AuthProfileUpdateSuccess) return (s.user.isAdmin, s.user.isOwner);
          if (s is AuthProfileImageUploadSuccess) return (s.user.isAdmin, s.user.isOwner);
          return (false, false);
        });
        final results = widget.searchService.searchScreens(query);
        _searchResults = isAdmin
            ? results
            : results
                .where((s) => !s.adminOnly || (isOwner && s.visibleForOwner))
                .toList();
      }
    });
  }

  void _navigateToScreen(SearchableScreen screen) async {
    HapticFeedback.lightImpact();

    // حفظ البحث والزيارة
    if (_searchController.text.isNotEmpty) {
      await widget.searchService.saveSearchHistory(_searchController.text);
    }
    await widget.searchService.saveScreenVisit(screen.id);

    // إغلاق النافذة والانتقال
    if (mounted) {
      Navigator.of(context).pop();
      context.push(screen.path);
    }
  }

  void _searchFromHistory(String query) {
    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = _selectedCategory == category ? '' : category;
      if (_selectedCategory.isNotEmpty) {
        final (isAdmin, isOwner) = context.select((AuthBloc bloc) {
          final s = bloc.state;
          if (s is AuthAuthenticated) return (s.user.isAdmin, s.user.isOwner);
          if (s is AuthLoginSuccess) return (s.user.isAdmin, s.user.isOwner);
          if (s is AuthProfileUpdateSuccess) return (s.user.isAdmin, s.user.isOwner);
          if (s is AuthProfileImageUploadSuccess) return (s.user.isAdmin, s.user.isOwner);
          return (false, false);
        });
        final base = widget.searchService.searchScreens('');
        final filteredByCategory = base.where((s) => s.category == category);
        _searchResults = isAdmin
            ? filteredByCategory.toList()
            : filteredByCategory
                .where((s) => !s.adminOnly || (isOwner && s.visibleForOwner))
                .toList();
        _isSearching = true;
      } else {
        _searchResults = [];
        _isSearching = false;
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? size.width * 0.15 : 20,
        vertical: isTablet ? size.height * 0.1 : 40,
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Stack(
              children: [
                // خلفية رخامية مثل الصفحة الرئيسية
                Container(
                  constraints: BoxConstraints(
                    maxWidth: 800,
                    maxHeight: size.height * 0.8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.darkBackground,
                        AppTheme.darkBackground2,
                        AppTheme.darkBackground3.withOpacity(0.5),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Animated Orbs للتأثير الرخامي
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Stack(
                            children: [
                              // Top Orb
                              Positioned(
                                top: -50 + (20 * _pulseController.value),
                                right: -50,
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        AppTheme.primaryBlue.withOpacity(0.2),
                                        AppTheme.primaryBlue.withOpacity(0.05),
                                        AppTheme.primaryBlue.withOpacity(0.01),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Bottom Orb
                              Positioned(
                                bottom: -80 + (15 * _pulseController.value),
                                left: -60,
                                child: Container(
                                  width: 250,
                                  height: 250,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        AppTheme.primaryPurple.withOpacity(0.15),
                                        AppTheme.primaryPurple.withOpacity(0.04),
                                        AppTheme.primaryPurple.withOpacity(0.01),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Center Orb
                              Positioned(
                                top: size.height * 0.3,
                                right: size.width * 0.2,
                                child: Transform.scale(
                                  scale: 0.9 + (0.1 * _pulseController.value),
                                  child: Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          AppTheme.primaryViolet.withOpacity(0.1),
                                          AppTheme.primaryViolet.withOpacity(0.02),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // المحتوى مع شفافية
                Container(
                  constraints: BoxConstraints(
                    maxWidth: 800,
                    maxHeight: size.height * 0.8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.darkCard.withOpacity(0.6),
                        AppTheme.darkCard.withOpacity(0.3),
                      ],
                    ),
                    border: Border.all(
                      color: AppTheme.glowBlue.withOpacity(0.1),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Column(
                        children: [
                          _buildHeader(),
                          _buildSearchBar(),
                          _buildCategories(),
                          Expanded(child: _buildContent()),
                        ],
                      ),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Icon with Glow Effect
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(
                        0.3 + (0.2 * _pulseController.value),
                      ),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              );
            },
          ),
          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'البحث في الشاشات',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
                Text(
                  'ابحث عن أي شاشة في النظام',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          // Close Button
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.inputBackground.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.close_rounded,
                color: AppTheme.textMuted,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppTheme.inputBackground.withOpacity(0.5),
            AppTheme.inputBackground.withOpacity(0.3),
          ],
        ),
        border: Border.all(
          color: _searchFocusNode.hasFocus
              ? AppTheme.primaryBlue.withOpacity(0.3)
              : AppTheme.darkBorder.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: _searchFocusNode.hasFocus
            ? [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppTheme.textWhite,
        ),
        decoration: InputDecoration(
          hintText: 'ابحث عن شاشة، صفحة، أو ميزة...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textMuted.withOpacity(0.5),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppTheme.primaryCyan,
            size: 22,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _searchFocusNode.requestFocus();
                  },
                  icon: Icon(
                    Icons.clear_rounded,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {'name': ScreenCategory.financial, 'icon': Icons.account_balance_rounded},
      {'name': ScreenCategory.bookings, 'icon': Icons.calendar_month_rounded},
      {'name': ScreenCategory.properties, 'icon': Icons.apartment_rounded},
      {'name': ScreenCategory.users, 'icon': Icons.people_rounded},
      {'name': ScreenCategory.settings, 'icon': Icons.settings_rounded},
      {'name': ScreenCategory.reports, 'icon': Icons.assessment_rounded},
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category['name'];

          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              horizontalOffset: 50.0,
              child: FadeInAnimation(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _filterByCategory(category['name'] as String);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppTheme.primaryGradient : null,
                        color: isSelected
                            ? null
                            : AppTheme.darkCard.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryBlue.withOpacity(0.5)
                              : AppTheme.darkBorder.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withOpacity(0.2),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            category['icon'] as IconData,
                            size: 16,
                            color:
                                isSelected ? Colors.white : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            category['name'] as String,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textLight,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
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
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_isSearching) {
      return _buildSearchResults();
    } else {
      return _buildSuggestions();
    }
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return _buildEmptyState();
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final screen = _searchResults[index];

          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildScreenTile(screen),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Suggestions
          if (_quickSuggestions.isNotEmpty) ...[
            _buildSectionTitle('اقتراحات سريعة', Icons.flash_on_rounded),
            const SizedBox(height: 12),
            AnimationLimiter(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 68,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _quickSuggestions.length,
                itemBuilder: (context, index) {
                  final screen = _quickSuggestions[index];

                  return AnimationConfiguration.staggeredGrid(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    columnCount: 2,
                    child: ScaleAnimation(
                      child: FadeInAnimation(
                        child: _buildQuickSuggestionCard(screen),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Search History
          if (_searchHistory.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('سجل البحث', Icons.history_rounded),
                IconButton(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await widget.searchService.clearSearchHistory();
                    setState(() {
                      _searchHistory.clear();
                    });
                  },
                  icon: Icon(
                    Icons.clear_all_rounded,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _searchHistory.take(10).map((query) {
                return GestureDetector(
                  onTap: () => _searchFromHistory(query),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.inputBackground.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.darkBorder.withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 14,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          query,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue.withOpacity(0.2),
                AppTheme.primaryCyan.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppTheme.primaryCyan,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildScreenTile(SearchableScreen screen) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.6),
            AppTheme.darkCard.withOpacity(0.4),
          ],
        ),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToScreen(screen),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: screen.gradientColors),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: screen.gradientColors[0].withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    screen.icon,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              screen.titleAr,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppTheme.textWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (screen.isPinned)
                            Icon(
                              Icons.push_pin_rounded,
                              size: 14,
                              color: AppTheme.warning,
                            ),
                          if (screen.visitCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.primaryBlue.withOpacity(0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.visibility_rounded,
                                    size: 12,
                                    color: AppTheme.primaryBlue,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${screen.visitCount}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppTheme.primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        screen.descriptionAr,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.inputBackground.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              screen.category,
                              style: AppTextStyles.caption.copyWith(
                                color: AppTheme.textLight,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              screen.path,
                              style: AppTextStyles.caption.copyWith(
                                color: AppTheme.textMuted.withOpacity(0.5),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppTheme.textMuted.withOpacity(0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSuggestionCard(SearchableScreen screen) {
    return GestureDetector(
      onTap: () => _navigateToScreen(screen),
      onLongPress: () async {
        HapticFeedback.heavyImpact();
        await widget.searchService.togglePinScreen(screen.id);
        _loadInitialData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              screen.gradientColors[0].withOpacity(0.1),
              screen.gradientColors[1].withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: screen.gradientColors[0].withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: screen.gradientColors),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                screen.icon,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    screen.titleAr,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (screen.visitCount > 0)
                    Text(
                      'زيارات: ${screen.visitCount}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
            if (screen.isPinned)
              Icon(
                Icons.push_pin_rounded,
                size: 12,
                color: AppTheme.warning,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              maxWidth: constraints.maxWidth,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryBlue.withOpacity(0.1),
                          AppTheme.primaryCyan.withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_off_rounded,
                      size: 40,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'لا توجد نتائج',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppTheme.textWhite,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'جرب البحث بكلمات مختلفة',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
