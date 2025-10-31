// lib/features/admin_cities/presentation/widgets/city_search_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class CitySearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback? onFilterTap;

  const CitySearchBar({
    super.key,
    required this.onChanged,
    this.onFilterTap,
  });

  @override
  State<CitySearchBar> createState() => _CitySearchBarState();
}

class _CitySearchBarState extends State<CitySearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late TextEditingController _searchController;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _searchController = TextEditingController();

    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
      if (_focusNode.hasFocus) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: _isFocused ? 20 : 10,
            sigmaY: _isFocused ? 20 : 10,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isFocused
                    ? [
                        AppTheme.primaryBlue.withValues(alpha: 0.1),
                        AppTheme.primaryPurple.withValues(alpha: 0.05),
                      ]
                    : [
                        AppTheme.darkCard.withValues(alpha: 0.5),
                        AppTheme.darkCard.withValues(alpha: 0.3),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFocused
                    ? AppTheme.primaryBlue.withValues(alpha: 0.5)
                    : AppTheme.darkBorder.withValues(alpha: 0.2),
                width: _isFocused ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                // Search Icon with Animation
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _animationController.value * 0.5,
                        child: Icon(
                          CupertinoIcons.search,
                          color: _isFocused
                              ? AppTheme.primaryBlue
                              : AppTheme.textMuted,
                          size: 20,
                        ),
                      );
                    },
                  ),
                ),

                // Search Field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textWhite,
                    ),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن مدينة...',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.textMuted.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onChanged: widget.onChanged,
                  ),
                ),

                // Clear Button
                if (_searchController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _searchController.clear();
                        widget.onChanged('');
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.textMuted.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.xmark,
                          size: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ),

                // Filter Button
                if (widget.onFilterTap != null)
                  Container(
                    margin: const EdgeInsets.only(left: 8, right: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryPurple.withValues(alpha: 0.1),
                          AppTheme.primaryViolet.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          widget.onFilterTap?.call();
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            CupertinoIcons.slider_horizontal_3,
                            color: AppTheme.primaryPurple,
                            size: 18,
                          ),
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
}
