import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';

class SectionSchedulePicker extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?, DateTime?) onScheduleChanged;

  const SectionSchedulePicker({
    super.key,
    this.startDate,
    this.endDate,
    required this.onScheduleChanged,
  });

  @override
  State<SectionSchedulePicker> createState() => _SectionSchedulePickerState();
}

class _SectionSchedulePickerState extends State<SectionSchedulePicker>
    with SingleTickerProviderStateMixin {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _hasSchedule = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    _hasSchedule = _startDate != null || _endDate != null;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (_hasSchedule) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'جدولة القسم',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withValues(alpha: 0.5),
                AppTheme.darkCard.withValues(alpha: 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.darkBorder.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                children: [
                  _buildScheduleToggle(),
                  SizeTransition(
                    sizeFactor: _expandAnimation,
                    child: _buildScheduleContent(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _hasSchedule
                ? AppTheme.primaryBlue.withValues(alpha: 0.2)
                : Colors.transparent,
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
              gradient: _hasSchedule ? AppTheme.primaryGradient : null,
              color: !_hasSchedule
                  ? AppTheme.darkBackground.withValues(alpha: 0.5)
                  : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              CupertinoIcons.calendar_badge_plus,
              color: _hasSchedule ? Colors.white : AppTheme.textMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تفعيل الجدولة',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _hasSchedule
                      ? 'القسم سيظهر في التواريخ المحددة فقط'
                      : 'القسم سيظهر دائماً',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: _hasSchedule,
            onChanged: (value) {
              setState(() {
                _hasSchedule = value;
                if (!value) {
                  _startDate = null;
                  _endDate = null;
                  widget.onScheduleChanged(null, null);
                }
              });
              if (value) {
                _animationController.forward();
              } else {
                _animationController.reverse();
              }
            },
            activeTrackColor: AppTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDatePicker(
            label: 'تاريخ البداية',
            date: _startDate,
            icon: CupertinoIcons.play_circle_fill,
            color: AppTheme.success,
            onTap: () => _selectDate(true),
          ),
          const SizedBox(height: 12),
          _buildDatePicker(
            label: 'تاريخ النهاية',
            date: _endDate,
            icon: CupertinoIcons.stop_circle_fill,
            color: AppTheme.error,
            onTap: () => _selectDate(false),
          ),
          if (_startDate != null && _endDate != null) ...[
            const SizedBox(height: 16),
            _buildDurationInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    DateTime? date,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkBackground.withValues(alpha: 0.5),
              AppTheme.darkBackground.withValues(alpha: 0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: date != null
                ? color.withValues(alpha: 0.3)
                : AppTheme.darkBorder.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null ? Formatters.formatDate(date) : 'اختر التاريخ',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: date != null
                          ? AppTheme.textWhite
                          : AppTheme.textMuted.withValues(alpha: 0.5),
                      fontWeight: date != null ? FontWeight.w600 : null,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_down,
              size: 16,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationInfo() {
    final duration = _endDate!.difference(_startDate!);
    final days = duration.inDays;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.1),
            AppTheme.primaryPurple.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.time,
            size: 16,
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(width: 8),
          Text(
            'مدة العرض: ',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
          Text(
            '$days يوم',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _selectDate(bool isStartDate) async {
    final initialDate = isStartDate
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now().add(const Duration(days: 7)));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              surface: AppTheme.darkCard,
              onSurface: AppTheme.textWhite,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = picked.add(const Duration(days: 7));
          }
        } else {
          _endDate = picked;
          if (_startDate != null && _startDate!.isAfter(picked)) {
            _startDate = picked.subtract(const Duration(days: 7));
          }
        }
      });
      widget.onScheduleChanged(_startDate, _endDate);
    }
  }
}
