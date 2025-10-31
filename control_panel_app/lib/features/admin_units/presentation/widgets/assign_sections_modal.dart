import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_dimensions.dart';

class AssignSectionsModal extends StatefulWidget {
  final String unitId;
  final VoidCallback onClose;
  final Function(List<String>) onAssign;

  const AssignSectionsModal({
    super.key,
    required this.unitId,
    required this.onClose,
    required this.onAssign,
  });

  @override
  State<AssignSectionsModal> createState() => _AssignSectionsModalState();
}

class _AssignSectionsModalState extends State<AssignSectionsModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final List<String> _selectedSections = [];
  
  // Mock sections data
  final List<Map<String, dynamic>> _sections = [
    {'id': '1', 'name': 'عروض خاصة', 'icon': '🎯'},
    {'id': '2', 'name': 'الأكثر مشاهدة', 'icon': '👁️'},
    {'id': '3', 'name': 'جديد', 'icon': '✨'},
    {'id': '4', 'name': 'موصى به', 'icon': '⭐'},
    {'id': '5', 'name': 'عروض الصيف', 'icon': '☀️'},
    {'id': '6', 'name': 'عروض العائلات', 'icon': '👨‍👩‍👧‍👦'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: const BoxConstraints(maxWidth: 400),
              margin: const EdgeInsets.all(AppDimensions.paddingLarge),
              decoration: BoxDecoration(
                gradient: AppTheme.darkGradient,
                borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
                border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      _buildContent(),
                      _buildFooter(),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.1),
            AppTheme.primaryPurple.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: const Icon(
              Icons.category,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimensions.spaceMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إضافة إلى الأقسام',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
                Text(
                  'حدد الأقسام لإضافة الوحدة إليها',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onClose();
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.darkCard.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Icon(
                Icons.close,
                size: 16,
                color: AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      constraints: const BoxConstraints(maxHeight: 300),
      child: SingleChildScrollView(
        child: Column(
          children: _sections.map((section) {
            final isSelected = _selectedSections.contains(section['id']);
            
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  if (isSelected) {
                    _selectedSections.remove(section['id']);
                  } else {
                    _selectedSections.add(section['id']);
                  }
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: AppDimensions.spaceSmall),
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            AppTheme.primaryBlue.withOpacity(0.2),
                            AppTheme.primaryPurple.withOpacity(0.1),
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            AppTheme.darkCard.withOpacity(0.3),
                            AppTheme.darkCard.withOpacity(0.1),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryBlue.withOpacity(0.5)
                        : AppTheme.darkBorder.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? AppTheme.primaryGradient
                            : null,
                        color: isSelected ? null : AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : AppTheme.darkBorder.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: AppDimensions.spaceMedium),
                    Text(
                      section['icon']!,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: AppDimensions.spaceMedium),
                    Expanded(
                      child: Text(
                        section['name']!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isSelected
                              ? AppTheme.textWhite
                              : AppTheme.textLight,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          if (_selectedSections.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMedium,
                vertical: AppDimensions.paddingSmall,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Text(
                'تم تحديد ${_selectedSections.length} قسم',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          const Spacer(),
          _buildButton(
            label: 'إلغاء',
            onTap: widget.onClose,
            isPrimary: false,
          ),
          const SizedBox(width: AppDimensions.spaceSmall),
          _buildButton(
            label: 'تطبيق',
            onTap: () {
              widget.onAssign(_selectedSections);
              widget.onClose();
            },
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingLarge,
          vertical: AppDimensions.paddingMedium,
        ),
        decoration: BoxDecoration(
          gradient: isPrimary ? AppTheme.primaryGradient : null,
          color: isPrimary ? null : AppTheme.darkCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: isPrimary
              ? null
              : Border.all(
                  color: AppTheme.darkBorder.withOpacity(0.3),
                  width: 1,
                ),
        ),
        child: Text(
          label,
          style: AppTextStyles.buttonMedium.copyWith(
            color: isPrimary ? Colors.white : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}