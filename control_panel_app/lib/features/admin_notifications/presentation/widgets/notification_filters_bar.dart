// lib/features/admin_notifications/presentation/widgets/notification_filters_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class NotificationFiltersBar extends StatelessWidget {
  final String? selectedType;
  final String? selectedStatus;
  final Function(String?, String?) onFiltersChanged;

  const NotificationFiltersBar({
    super.key,
    this.selectedType,
    this.selectedStatus,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildFilterDropdown(
              label: 'النوع',
              value: selectedType,
              items: const [
                {'value': null, 'label': 'الكل'},
                {'value': 'booking', 'label': 'الحجوزات'},
                {'value': 'payment', 'label': 'المدفوعات'},
                {'value': 'promotion', 'label': 'العروض'},
                {'value': 'system', 'label': 'النظام'},
              ],
              onChanged: (value) => onFiltersChanged(value, selectedStatus),
            ),
            const SizedBox(width: 12),
            _buildFilterDropdown(
              label: 'الحالة',
              value: selectedStatus,
              items: const [
                {'value': null, 'label': 'الكل'},
                {'value': 'sent', 'label': 'مُرسل'},
                {'value': 'pending', 'label': 'قيد الانتظار'},
                {'value': 'failed', 'label': 'فشل'},
                {'value': 'scheduled', 'label': 'مجدول'},
              ],
              onChanged: (value) => onFiltersChanged(selectedType, value),
            ),
            const SizedBox(width: 12),
            if (selectedType != null || selectedStatus != null)
              _buildClearButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<Map<String, dynamic>> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value != null
              ? AppTheme.primaryBlue.withValues(alpha: 0.3)
              : AppTheme.darkBorder.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.line_horizontal_3_decrease,
            size: 16,
            color: value != null ? AppTheme.primaryBlue : AppTheme.textMuted,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String?>(
            value: value,
            dropdownColor: AppTheme.darkCard,
            underline: const SizedBox.shrink(),
            icon: Icon(
              CupertinoIcons.chevron_down,
              size: 14,
              color: value != null ? AppTheme.primaryBlue : AppTheme.textMuted,
            ),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textWhite,
            ),
            items: items.map((item) {
              return DropdownMenuItem<String?>(
                value: item['value'],
                child: Text(item['label']),
              );
            }).toList(),
            onChanged: (newValue) {
              HapticFeedback.lightImpact();
              onChanged(newValue);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClearButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onFiltersChanged(null, null);
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.error.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(
          CupertinoIcons.xmark,
          size: 16,
          color: AppTheme.error,
        ),
      ),
    );
  }
}
