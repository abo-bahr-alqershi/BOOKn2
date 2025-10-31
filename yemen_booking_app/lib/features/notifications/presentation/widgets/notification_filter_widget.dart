// lib/features/notifications/presentation/widgets/notification_filter_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class NotificationFilterWidget extends StatefulWidget {
  final String? selectedType;
  final bool? showUnreadOnly;
  final Function(String?, bool?) onFilterChanged;

  const NotificationFilterWidget({
    super.key,
    this.selectedType,
    this.showUnreadOnly,
    required this.onFilterChanged,
  });

  @override
  State<NotificationFilterWidget> createState() =>
      _NotificationFilterWidgetState();
}

class _NotificationFilterWidgetState extends State<NotificationFilterWidget> {
  late String? _selectedType;
  late bool _showUnreadOnly;
  bool _isExpanded = false;

  final List<FilterOption> _filterOptions = [
    FilterOption('all', 'الكل', CupertinoIcons.square_grid_2x2),
    FilterOption('booking', 'الحجوزات', CupertinoIcons.calendar),
    FilterOption('payment', 'المدفوعات', CupertinoIcons.creditcard_fill),
    FilterOption('promotion', 'العروض', CupertinoIcons.gift_fill),
    FilterOption('system', 'النظام', CupertinoIcons.gear_solid),
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    _showUnreadOnly = widget.showUnreadOnly ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 400;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isExpanded ? (isCompact ? 150 : 120) : 50,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: AppTheme.darkCard.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.darkBorder.withValues(alpha: 0.2),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(isCompact),
                  if (_isExpanded) ...[
                    const SizedBox(height: 12),
                    if (isCompact)
                      _buildCompactFilters()
                    else
                      _buildFullFilters(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.line_horizontal_3_decrease,
            color: AppTheme.primaryBlue,
            size: isCompact ? 18 : 20,
          ),
          SizedBox(width: isCompact ? 8 : 12),
          Text(
            'الفلاتر',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 14 : 16,
            ),
          ),
          const Spacer(),
          if (_selectedType != null || _showUnreadOnly) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getActiveFiltersCount().toString(),
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 300),
            child: Icon(
              CupertinoIcons.chevron_down,
              color: AppTheme.textMuted,
              size: isCompact ? 14 : 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFilters() {
    return Column(
      children: [
        // Type filters as scrollable chips
        SizedBox(
          height: 32,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filterOptions.length,
            itemBuilder: (context, index) {
              final option = _filterOptions[index];
              return _buildFilterChip(option);
            },
          ),
        ),
        const SizedBox(height: 12),
        // Unread toggle
        _buildUnreadToggle(isCompact: true),
      ],
    );
  }

  Widget _buildFullFilters() {
    return Column(
      children: [
        // Type filter chips in a row
        SizedBox(
          height: 36,
          child: Row(
            children: [
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filterOptions.length,
                  itemBuilder: (context, index) {
                    final option = _filterOptions[index];
                    return _buildFilterChip(option);
                  },
                ),
              ),
              const SizedBox(width: 16),
              _buildUnreadToggle(isCompact: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(FilterOption option) {
    final isSelected = _selectedType == option.value ||
        (option.value == 'all' && _selectedType == null);

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedType = option.value == 'all' ? null : option.value;
            });
            widget.onFilterChanged(_selectedType, _showUnreadOnly);
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: isSelected ? AppTheme.primaryGradient : null,
              color:
                  isSelected ? null : AppTheme.darkCard.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : AppTheme.darkBorder.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  option.icon,
                  size: 14,
                  color: isSelected ? Colors.white : AppTheme.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  option.label,
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected ? Colors.white : AppTheme.textMuted,
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnreadToggle({required bool isCompact}) {
    return GestureDetector(
      onTap: () {
        setState(() => _showUnreadOnly = !_showUnreadOnly);
        widget.onFilterChanged(_selectedType, _showUnreadOnly);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 10 : 12,
          vertical: isCompact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          gradient: _showUnreadOnly ? AppTheme.primaryGradient : null,
          color:
              _showUnreadOnly ? null : AppTheme.darkCard.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _showUnreadOnly
                ? Colors.transparent
                : AppTheme.darkBorder.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _showUnreadOnly
                    ? Colors.white
                    : AppTheme.darkBorder.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: _showUnreadOnly
                  ? Icon(
                      CupertinoIcons.checkmark,
                      size: 12,
                      color: AppTheme.primaryBlue,
                    )
                  : null,
            ),
            const SizedBox(width: 6),
            Text(
              'غير مقروء فقط',
              style: AppTextStyles.caption.copyWith(
                color: _showUnreadOnly ? Colors.white : AppTheme.textMuted,
                fontWeight: _showUnreadOnly ? FontWeight.w600 : null,
                fontSize: isCompact ? 11 : 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getActiveFiltersCount() {
    int count = 0;
    if (_selectedType != null) count++;
    if (_showUnreadOnly) count++;
    return count;
  }
}

class FilterOption {
  final String value;
  final String label;
  final IconData icon;

  FilterOption(this.value, this.label, this.icon);
}
