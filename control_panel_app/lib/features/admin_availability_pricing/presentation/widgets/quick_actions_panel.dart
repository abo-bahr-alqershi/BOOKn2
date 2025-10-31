// lib/features/admin_availability_pricing/presentation/widgets/quick_actions_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../pages/availability_pricing_page.dart';

class QuickActionsPanel extends StatefulWidget {
  final ViewMode viewMode;
  final Function(QuickAction) onActionTap;
  final bool isHorizontal;

  const QuickActionsPanel({
    super.key,
    required this.viewMode,
    required this.onActionTap,
    this.isHorizontal = false,
  });

  @override
  State<QuickActionsPanel> createState() => _QuickActionsPanelState();
}

class _QuickActionsPanelState extends State<QuickActionsPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
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
    final actions = _getActionsForMode();
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkCard.withOpacity(0.7),
                  AppTheme.darkCard.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.darkBorder.withOpacity(0.3),
                width: 0.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: widget.isHorizontal
                    ? _buildHorizontalLayout(actions)
                    : _buildVerticalLayout(actions),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHorizontalLayout(List<QuickActionItem> actions) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: actions.map((action) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildActionButton(action, isCompact: true),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVerticalLayout(List<QuickActionItem> actions) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          ...actions.map((action) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildActionButton(action),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.flash_on_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'إجراءات سريعة',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(QuickActionItem action, {bool isCompact = false}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onActionTap(action.action);
      },
      child: Container(
        height: isCompact ? 44 : 48,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: isCompact ? 8 : 12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              action.color.withOpacity(0.2),
              action.color.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: action.color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Icon(
              action.icon,
              color: action.color,
              size: isCompact ? 18 : 20,
            ),
            SizedBox(width: isCompact ? 8 : 12),
            Text(
              action.label,
              style: (isCompact ? AppTextStyles.caption : AppTextStyles.bodySmall).copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!isCompact) const Spacer(),
            if (!isCompact)
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: action.color.withOpacity(0.5),
                size: 14,
              ),
          ],
        ),
      ),
    );
  }

  List<QuickActionItem> _getActionsForMode() {
    final List<QuickActionItem> commonActions = [
      QuickActionItem(
        action: QuickAction.bulkUpdate,
        icon: Icons.edit_calendar_rounded,
        label: 'تحديث مجمع',
        color: AppTheme.primaryBlue,
      ),
      QuickActionItem(
        action: QuickAction.cloneSettings,
        icon: Icons.content_copy_rounded,
        label: 'نسخ الإعدادات',
        color: AppTheme.primaryPurple,
      ),
    ];

    if (widget.viewMode == ViewMode.availability) {
      return [
        ...commonActions,
        QuickActionItem(
          action: QuickAction.exportData,
          icon: Icons.download_rounded,
          label: 'تصدير البيانات',
          color: AppTheme.success,
        ),
      ];
    } else if (widget.viewMode == ViewMode.pricing) {
      return [
        QuickActionItem(
          action: QuickAction.seasonalPricing,
          icon: Icons.calendar_month_rounded,
          label: 'تسعير موسمي',
          color: AppTheme.warning,
        ),
        ...commonActions,
      ];
    } else {
      return [
        ...commonActions,
        QuickActionItem(
          action: QuickAction.seasonalPricing,
          icon: Icons.calendar_month_rounded,
          label: 'تسعير موسمي',
          color: AppTheme.warning,
        ),
        QuickActionItem(
          action: QuickAction.exportData,
          icon: Icons.download_rounded,
          label: 'تصدير البيانات',
          color: AppTheme.success,
        ),
        QuickActionItem(
          action: QuickAction.importData,
          icon: Icons.upload_rounded,
          label: 'استيراد البيانات',
          color: AppTheme.info,
        ),
      ];
    }
  }
}

class QuickActionItem {
  final QuickAction action;
  final IconData icon;
  final String label;
  final Color color;

  QuickActionItem({
    required this.action,
    required this.icon,
    required this.label,
    required this.color,
  });
}