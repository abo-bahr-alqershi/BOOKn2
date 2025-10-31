import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class DatePickerWidget extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Function(DateTime) onDateSelected;
  final bool enabled;
  final IconData? icon;
  final String? errorText;

  const DatePickerWidget({
    super.key,
    required this.label,
    this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateSelected,
    this.enabled = true,
    this.icon,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'ar');
    
    return InkWell(
      onTap: enabled ? () => _selectDate(context) : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: enabled
                      ? (errorText != null 
                          ? AppTheme.error.withOpacity(0.08)
                          : AppTheme.primaryBlue.withOpacity(0.08))
                      : AppTheme.darkBorder.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: enabled
                      ? (errorText != null 
                          ? AppTheme.error.withOpacity(0.8)
                          : AppTheme.primaryBlue.withOpacity(0.8))
                      : AppTheme.darkBorder.withOpacity(0.3),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: enabled
                          ? (errorText != null 
                              ? AppTheme.error.withOpacity(0.8)
                              : AppTheme.textMuted.withOpacity(0.7))
                          : AppTheme.darkBorder.withOpacity(0.3),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    selectedDate != null
                        ? dateFormat.format(selectedDate!)
                        : 'اختر التاريخ',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: enabled
                          ? (selectedDate != null
                              ? AppTheme.textWhite.withOpacity(0.9)
                              : AppTheme.textMuted.withOpacity(0.5))
                          : AppTheme.darkBorder.withOpacity(0.3),
                      fontWeight: selectedDate != null ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      errorText!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.error.withOpacity(0.8),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.calendar_today_outlined,
              color: enabled 
                  ? AppTheme.textMuted.withOpacity(0.5)
                  : AppTheme.darkBorder.withOpacity(0.3),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    HapticFeedback.selectionClick();
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryBlue.withOpacity(0.9),
              onPrimary: AppTheme.textWhite,
              surface: AppTheme.darkCard,
              onSurface: AppTheme.textWhite,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue.withOpacity(0.9),
                textStyle: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: AppTheme.darkCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: AppTheme.darkCard,
              surfaceTintColor: Colors.transparent,
              headerBackgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
              headerForegroundColor: AppTheme.primaryBlue.withOpacity(0.9),
              dayForegroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                if (states.contains(MaterialState.disabled)) {
                  return AppTheme.textMuted.withOpacity(0.3);
                }
                return AppTheme.textWhite.withOpacity(0.9);
              }),
              dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return AppTheme.primaryBlue.withOpacity(0.8);
                }
                return Colors.transparent;
              }),
              dayOverlayColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.hovered)) {
                  return AppTheme.primaryBlue.withOpacity(0.1);
                }
                if (states.contains(MaterialState.pressed)) {
                  return AppTheme.primaryBlue.withOpacity(0.2);
                }
                return Colors.transparent;
              }),
              todayForegroundColor: MaterialStateProperty.all(
                AppTheme.primaryBlue.withOpacity(0.9),
              ),
              todayBorder: BorderSide(
                color: AppTheme.primaryBlue.withOpacity(0.5),
                width: 1,
              ),
              yearForegroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                if (states.contains(MaterialState.disabled)) {
                  return AppTheme.textMuted.withOpacity(0.3);
                }
                return AppTheme.textWhite.withOpacity(0.9);
              }),
              yearBackgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return AppTheme.primaryBlue.withOpacity(0.8);
                }
                return Colors.transparent;
              }),
              yearOverlayColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.hovered)) {
                  return AppTheme.primaryBlue.withOpacity(0.1);
                }
                if (states.contains(MaterialState.pressed)) {
                  return AppTheme.primaryBlue.withOpacity(0.2);
                }
                return Colors.transparent;
              }),
              rangePickerBackgroundColor: AppTheme.darkCard,
              rangePickerSurfaceTintColor: Colors.transparent,
              rangePickerHeaderBackgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
              rangePickerHeaderForegroundColor: AppTheme.primaryBlue.withOpacity(0.9),
              rangeSelectionBackgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
              dividerColor: AppTheme.darkBorder.withOpacity(0.1),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != selectedDate) {
      HapticFeedback.lightImpact();
      onDateSelected(picked);
    }
  }
}