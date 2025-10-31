import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class SortOptionsWidget extends StatefulWidget {
  final String? currentSort;
  final Function(String) onSortChanged;

  const SortOptionsWidget({
    super.key,
    this.currentSort,
    required this.onSortChanged,
  });

  @override
  State<SortOptionsWidget> createState() => _SortOptionsWidgetState();
}

class _SortOptionsWidgetState extends State<SortOptionsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.8),
            AppTheme.darkCard.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.currentSort != null 
              ? AppTheme.primaryBlue.withOpacity(0.3)
              : AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: widget.currentSort != null
            ? [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSortOptions(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: widget.currentSort != null
                        ? AppTheme.primaryGradient
                        : null,
                    color: widget.currentSort == null
                        ? AppTheme.textMuted.withOpacity(0.3)
                        : null,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getSortIcon(),
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getCurrentSortLabel(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: widget.currentSort != null 
                        ? AppTheme.primaryBlue 
                        : AppTheme.textWhite,
                    fontWeight: widget.currentSort != null 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    setState(() {
      _isExpanded = true;
    });
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppTheme.darkBackground.withOpacity(0.8),
      isScrollControlled: true,
      builder: (context) {
        return _SortOptionsBottomSheet(
          currentSort: widget.currentSort,
          onSortChanged: (value) {
            widget.onSortChanged(value);
            Navigator.pop(context);
          },
        );
      },
    ).whenComplete(() {
      setState(() {
        _isExpanded = false;
      });
    });
  }
  
  IconData _getSortIcon() {
    switch (widget.currentSort) {
      case 'price_asc':
        return Icons.arrow_upward_rounded;
      case 'price_desc':
        return Icons.arrow_downward_rounded;
      case 'rating':
        return Icons.star_rounded;
      case 'popularity':
        return Icons.trending_up_rounded;
      case 'distance':
        return Icons.near_me_rounded;
      case 'newest':
        return Icons.new_releases_rounded;
      default:
        return Icons.sort_rounded;
    }
  }

  String _getCurrentSortLabel() {
    switch (widget.currentSort) {
      case 'recommended':
        return 'موصى به';
      case 'price_asc':
        return 'السعر ↑';
      case 'price_desc':
        return 'السعر ↓';
      case 'rating':
        return 'التقييم';
      case 'popularity':
        return 'الشعبية';
      case 'distance':
        return 'المسافة';
      case 'newest':
        return 'الأحدث';
      default:
        return 'ترتيب';
    }
  }
}

class _SortOptionsBottomSheet extends StatefulWidget {
  final String? currentSort;
  final Function(String) onSortChanged;

  const _SortOptionsBottomSheet({
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  State<_SortOptionsBottomSheet> createState() => _SortOptionsBottomSheetState();
}

class _SortOptionsBottomSheetState extends State<_SortOptionsBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final sortOptions = [
    {
      'value': 'recommended',
      'label': 'موصى به',
      'icon': Icons.recommend_rounded,
      'description': 'الأكثر ملاءمة لبحثك',
      'color': AppTheme.primaryBlue,
    },
    {
      'value': 'price_asc',
      'label': 'السعر: الأقل أولاً',
      'icon': Icons.arrow_upward_rounded,
      'description': 'من الأرخص إلى الأغلى',
      'color': AppTheme.success,
    },
    {
      'value': 'price_desc',
      'label': 'السعر: الأعلى أولاً',
      'icon': Icons.arrow_downward_rounded,
      'description': 'من الأغلى إلى الأرخص',
      'color': AppTheme.warning,
    },
    {
      'value': 'rating',
      'label': 'التقييم',
      'icon': Icons.star_rounded,
      'description': 'الأعلى تقييماً أولاً',
      'color': AppTheme.warning,
    },
    {
      'value': 'popularity',
      'label': 'الأكثر شعبية',
      'icon': Icons.trending_up_rounded,
      'description': 'الأكثر حجزاً ومشاهدة',
      'color': AppTheme.primaryPurple,
    },
    {
      'value': 'distance',
      'label': 'المسافة',
      'icon': Icons.near_me_rounded,
      'description': 'الأقرب إليك',
      'color': AppTheme.info,
    },
    {
      'value': 'newest',
      'label': 'الأحدث',
      'icon': Icons.new_releases_rounded,
      'description': 'المضاف حديثاً',
      'color': AppTheme.neonGreen,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, MediaQuery.of(context).size.height * _slideAnimation.value),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.darkCard.withOpacity(0.95),
                  AppTheme.darkSurface.withOpacity(0.98),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowDark.withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHandle(),
                        _buildHeader(),
                        _buildOptions(),
                      ],
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

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 50,
      height: 5,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.sort_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                child: Text(
                  'ترتيب النتائج',
                  style: AppTextStyles.heading2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'اختر طريقة عرض النتائج',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sortOptions.length,
        itemBuilder: (context, index) {
          final option = sortOptions[index];
          final isSelected = widget.currentSort == option['value'];
          
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 50)),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0).toDouble(),
                  child: _buildOptionItem(option, isSelected),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOptionItem(Map<String, dynamic> option, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  (option['color'] as Color).withOpacity(0.2),
                  (option['color'] as Color).withOpacity(0.05),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? (option['color'] as Color).withOpacity(0.3)
              : AppTheme.darkBorder.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onSortChanged(option['value'] as String),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              (option['color'] as Color),
                              (option['color'] as Color).withOpacity(0.7),
                            ],
                          )
                        : null,
                    color: !isSelected
                        ? AppTheme.darkCard.withOpacity(0.5)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (option['color'] as Color).withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    option['icon'] as IconData,
                    color: isSelected
                        ? Colors.white
                        : AppTheme.textMuted,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option['label'] as String,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: isSelected 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                          color: isSelected 
                              ? option['color'] as Color
                              : AppTheme.textWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option['description'] as String,
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (option['color'] as Color).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: option['color'] as Color,
                      size: 18,
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