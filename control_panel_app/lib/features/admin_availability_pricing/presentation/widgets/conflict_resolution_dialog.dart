// lib/features/admin_availability_pricing/presentation/widgets/conflict_resolution_dialog.dart

import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/booking_conflict.dart';

class ConflictResolutionDialog extends StatefulWidget {
  final List<BookingConflict> conflicts;
  final Function(ConflictResolution) onResolve;

  const ConflictResolutionDialog({
    super.key,
    required this.conflicts,
    required this.onResolve,
  });

  static Future<void> show(
    BuildContext context, {
    required List<BookingConflict> conflicts,
    required Function(ConflictResolution) onResolve,
  }) async {
    return showDialog(
      fullscreenDialog: true,
      context: context,
      barrierDismissible: false,
      barrierColor: AppTheme.overlayDark,
      builder: (context) => ConflictResolutionDialog(
        conflicts: conflicts,
        onResolve: onResolve,
      ),
    );
  }

  @override
  State<ConflictResolutionDialog> createState() =>
      _ConflictResolutionDialogState();
}

class _ConflictResolutionDialogState extends State<ConflictResolutionDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  ConflictResolution _selectedResolution = ConflictResolution.cancel;
  final Map<String, bool> _selectedConflicts = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();

    // Initialize all conflicts as selected
    for (final conflict in widget.conflicts) {
      _selectedConflicts[conflict.bookingId] = true;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 550,
          constraints: const BoxConstraints(maxHeight: 650),
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
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWarningMessage(),
                          const SizedBox(height: 20),
                          _buildConflictsList(),
                          const SizedBox(height: 24),
                          _buildResolutionOptions(),
                        ],
                      ),
                    ),
                  ),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.error.withOpacity(0.1),
            AppTheme.error.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.error.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.error,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تعارض في الحجوزات',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'تم اكتشاف ${widget.conflicts.length} تعارض يحتاج إلى حل',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close_rounded,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppTheme.warning,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'التغييرات المطلوبة تتعارض مع حجوزات موجودة. يرجى اختيار كيفية التعامل مع هذه التعارضات.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الحجوزات المتعارضة',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.conflicts.map((conflict) => _buildConflictCard(conflict)),
      ],
    );
  }

  Widget _buildConflictCard(BookingConflict conflict) {
    final isSelected = _selectedConflicts[conflict.bookingId] ?? false;
    final impactColor = _getImpactColor(conflict.impactLevel);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            impactColor.withOpacity(0.1),
            impactColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: impactColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            _selectedConflicts[conflict.bookingId] = value ?? false;
          });
        },
        activeColor: impactColor,
        title: Row(
          children: [
            Icon(
              _getConflictIcon(conflict.conflictType),
              size: 18,
              color: impactColor,
            ),
            const SizedBox(width: 8),
            Text(
              'حجز #${conflict.bookingId}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: impactColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _getImpactLabel(conflict.impactLevel),
                style: AppTextStyles.caption.copyWith(
                  color: impactColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (conflict.bookingStatus != null)
              Text(
                'الحالة: ${conflict.bookingStatus}',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            if (conflict.totalAmount != null)
              Text(
                'المبلغ: ${conflict.totalAmount?.toStringAsFixed(0)} ريال',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResolutionOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'خيارات الحل',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildResolutionOption(
          resolution: ConflictResolution.override,
          icon: Icons.published_with_changes_rounded,
          title: 'تجاوز التعارضات',
          description: 'تطبيق التغييرات وإلغاء الحجوزات المتعارضة',
          color: AppTheme.error,
        ),
        const SizedBox(height: 8),
        _buildResolutionOption(
          resolution: ConflictResolution.skip,
          icon: Icons.skip_next_rounded,
          title: 'تخطي المتعارضات',
          description: 'تطبيق التغييرات فقط على الفترات غير المتعارضة',
          color: AppTheme.warning,
        ),
        const SizedBox(height: 8),
        _buildResolutionOption(
          resolution: ConflictResolution.notify,
          icon: Icons.notifications_active_rounded,
          title: 'إشعار العملاء',
          description: 'إرسال إشعارات للعملاء المتأثرين بالتغييرات',
          color: AppTheme.info,
        ),
        const SizedBox(height: 8),
        _buildResolutionOption(
          resolution: ConflictResolution.cancel,
          icon: Icons.cancel_rounded,
          title: 'إلغاء التغييرات',
          description: 'عدم تطبيق أي تغييرات والعودة للوضع السابق',
          color: AppTheme.textMuted,
        ),
      ],
    );
  }

  Widget _buildResolutionOption({
    required ConflictResolution resolution,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    final isSelected = _selectedResolution == resolution;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedResolution = resolution;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppTheme.darkBorder.withOpacity(0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected ? color : AppTheme.textWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: color,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkSurface.withOpacity(0.6),
            AppTheme.darkSurface.withOpacity(0.4),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.darkBorder.withOpacity(0.3),
                    width: 1,
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
            flex: 2,
            child: GestureDetector(
              onTap: () {
                widget.onResolve(_selectedResolution);
                Navigator.of(context).pop();
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: _getResolutionGradient(),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _getResolutionColor().withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _getActionText(),
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
    );
  }

  Color _getImpactColor(ImpactLevel? level) {
    switch (level) {
      case ImpactLevel.critical:
        return AppTheme.error;
      case ImpactLevel.high:
        return AppTheme.warning;
      case ImpactLevel.medium:
        return AppTheme.primaryPurple;
      case ImpactLevel.low:
        return AppTheme.info;
      default:
        return AppTheme.textMuted;
    }
  }

  IconData _getConflictIcon(ConflictType? type) {
    switch (type) {
      case ConflictType.availability:
        return Icons.event_busy_rounded;
      case ConflictType.pricing:
        return Icons.attach_money_rounded;
      default:
        return Icons.warning_rounded;
    }
  }

  String _getImpactLabel(ImpactLevel? level) {
    switch (level) {
      case ImpactLevel.critical:
        return 'حرج';
      case ImpactLevel.high:
        return 'عالي';
      case ImpactLevel.medium:
        return 'متوسط';
      case ImpactLevel.low:
        return 'منخفض';
      default:
        return 'غير محدد';
    }
  }

  LinearGradient _getResolutionGradient() {
    switch (_selectedResolution) {
      case ConflictResolution.override:
        return LinearGradient(
          colors: [
            AppTheme.error,
            AppTheme.error.withOpacity(0.8),
          ],
        );
      case ConflictResolution.skip:
        return LinearGradient(
          colors: [
            AppTheme.warning,
            AppTheme.warning.withOpacity(0.8),
          ],
        );
      case ConflictResolution.notify:
        return LinearGradient(
          colors: [
            AppTheme.info,
            AppTheme.info.withOpacity(0.8),
          ],
        );
      case ConflictResolution.cancel:
      default:
        return LinearGradient(
          colors: [
            AppTheme.textMuted,
            AppTheme.textMuted.withOpacity(0.8),
          ],
        );
    }
  }

  Color _getResolutionColor() {
    switch (_selectedResolution) {
      case ConflictResolution.override:
        return AppTheme.error;
      case ConflictResolution.skip:
        return AppTheme.warning;
      case ConflictResolution.notify:
        return AppTheme.info;
      case ConflictResolution.cancel:
      default:
        return AppTheme.textMuted;
    }
  }

  String _getActionText() {
    switch (_selectedResolution) {
      case ConflictResolution.override:
        return 'تجاوز وتطبيق';
      case ConflictResolution.skip:
        return 'تخطي وتطبيق';
      case ConflictResolution.notify:
        return 'إشعار وتطبيق';
      case ConflictResolution.cancel:
      default:
        return 'إلغاء العملية';
    }
  }
}

enum ConflictResolution {
  override,
  skip,
  notify,
  cancel,
}
