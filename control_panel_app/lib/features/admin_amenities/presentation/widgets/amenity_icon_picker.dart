import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../utils/amenity_icons.dart';

/// 🎨 Premium Service Icon Picker Dialog
class AmenityIconPicker extends StatefulWidget {
  final String selectedIcon;
  final Function(String) onIconSelected;

  const AmenityIconPicker({
    super.key,
    required this.selectedIcon,
    required this.onIconSelected,
  });

  @override
  State<AmenityIconPicker> createState() => _AmenityIconPickerState();
}

class _AmenityIconPickerState extends State<AmenityIconPicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  final _searchController = TextEditingController();
  String _selectedCategory = 'الكل';
  String _searchQuery = '';
  
  List<AmenityIcon> _filteredIcons = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _filterIcons();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _animationController.forward();
  }

  void _filterIcons() {
    setState(() {
      List<AmenityIcon> icons = AmenityIcons.allIcons;
      
      if (_selectedCategory != 'الكل') {
        icons = AmenityIcons.searchIcons(_searchQuery,category: _selectedCategory);
      }
      
      if (_searchQuery.isNotEmpty) {
        icons = icons.where((icon) {
          return icon.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 icon.label.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      }
      
      _filteredIcons = icons;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isMobile = size.width < 400;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 40,
                vertical: isMobile ? 60 : 40,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 720 : 600,
                  maxHeight: size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.isDark 
                    ? AppTheme.darkCard.withOpacity(0.98)
                    : Colors.white,
                  borderRadius: BorderRadius.circular(isMobile ? 20 : 28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(AppTheme.isDark ? 0.3 : 0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isMobile ? 20 : 28),
                  child: Column(
                    children: [
                      _buildHeader(isMobile),
                      _buildSearchBar(isMobile),
                      _buildCategoryTabs(isMobile),
                      Expanded(
                        child: _buildIconGrid(isMobile, isTablet),
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

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: AppTheme.isDark 
          ? AppTheme.darkSurface.withOpacity(0.5)
          : AppTheme.lightBackground.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.palette_outlined,
              color: AppTheme.primaryBlue,
              size: isMobile ? 18 : 20,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اختر أيقونة',
                  style: (isMobile ? AppTextStyles.heading3 : AppTextStyles.heading2).copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'حدد الأيقونة المناسبة للخدمة',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.close_rounded,
                  color: AppTheme.textMuted,
                  size: isMobile ? 20 : 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 12 : 16,
      ),
      child: TextField(
        controller: _searchController,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppTheme.textWhite,
        ),
        decoration: InputDecoration(
          hintText: 'ابحث عن أيقونة...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textMuted,
          ),
          filled: true,
          fillColor: AppTheme.isDark
            ? AppTheme.darkSurface.withOpacity(0.5)
            : AppTheme.inputBackground,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isMobile ? 12 : 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: AppTheme.darkBorder.withOpacity(0.1),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              width: 1,
            ),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppTheme.textMuted,
            size: isMobile ? 20 : 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear_rounded,
                  color: AppTheme.textMuted,
                  size: isMobile ? 18 : 20,
                ),
                onPressed: () {
                  _searchController.clear();
                  _searchQuery = '';
                  _filterIcons();
                },
              )
            : null,
        ),
        onChanged: (value) {
          _searchQuery = value;
          _filterIcons();
        },
      ),
    );
  }

  Widget _buildCategoryTabs(bool isMobile) {
    final categories = AmenityIcons.searchIcons(_searchQuery,category: _selectedCategory);
    
    return Container(
      height: isMobile ? 36 : 42,
      margin: EdgeInsets.only(
        left: isMobile ? 16 : 24,
        right: isMobile ? 16 : 24,
        bottom: isMobile ? 8 : 12,
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          
          return Padding(
            padding: EdgeInsets.only(right: isMobile ? 6 : 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedCategory = category.category;
                    _filterIcons();
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 14 : 18,
                    vertical: isMobile ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                      ? AppTheme.primaryBlue.withOpacity(0.1)
                      : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                        ? AppTheme.primaryBlue.withOpacity(0.3)
                        : AppTheme.darkBorder.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    category.category,
                    style: (isMobile ? AppTextStyles.caption : AppTextStyles.bodySmall).copyWith(
                      color: isSelected 
                        ? AppTheme.primaryBlue 
                        : AppTheme.textMuted,
                      fontWeight: isSelected 
                        ? FontWeight.w600 
                        : FontWeight.normal,
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

  Widget _buildIconGrid(bool isMobile, bool isTablet) {
    if (_filteredIcons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: isMobile ? 40 : 48,
                color: AppTheme.textMuted.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد نتائج',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'جرب البحث بكلمات أخرى',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      );
    }
    
    final crossAxisCount = isMobile ? 4 : (isTablet ? 6 : 8);
    final aspectRatio = isMobile ? 0.85 : 0.9; // تعديل نسبة العرض للطول
    
    return GridView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 8,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: isMobile ? 8 : 12,
        mainAxisSpacing: isMobile ? 8 : 12,
        childAspectRatio: aspectRatio, // استخدام النسبة المعدلة
      ),
      itemCount: _filteredIcons.length,
      itemBuilder: (context, index) {
        final iconData = _filteredIcons[index];
        final isSelected = widget.selectedIcon == iconData.name;
        
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onIconSelected(iconData.name);
              Navigator.of(context).pop();
            },
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(isMobile ? 4 : 6),
              decoration: BoxDecoration(
                color: isSelected
                  ? AppTheme.primaryBlue.withOpacity(0.1)
                  : AppTheme.isDark
                    ? AppTheme.darkSurface.withOpacity(0.3)
                    : AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                    ? AppTheme.primaryBlue.withOpacity(0.4)
                    : AppTheme.darkBorder.withOpacity(0.1),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        flex: 3,
                        child: Container(
                          alignment: Alignment.center,
                          child: Icon(
                            iconData.icon,
                            color: isSelected 
                              ? AppTheme.primaryBlue 
                              : AppTheme.textLight,
                            size: isMobile ? 20 : 24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Flexible(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            iconData.label,
                            style: TextStyle(
                              fontSize: isMobile ? 7 : 8,
                              height: 1.1, // تقليل ارتفاع السطر
                              color: isSelected 
                                ? AppTheme.primaryBlue 
                                : AppTheme.textMuted,
                              fontWeight: isSelected 
                                ? FontWeight.w600 
                                : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}