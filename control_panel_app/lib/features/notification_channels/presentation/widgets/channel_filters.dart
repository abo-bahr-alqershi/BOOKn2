import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';

class ChannelFilters extends StatefulWidget {
  final Function(String) onSearchChanged;
  final Function(String?) onTypeChanged;
  final Function(bool?) onActiveFilterChanged;

  const ChannelFilters({
    super.key,
    required this.onSearchChanged,
    required this.onTypeChanged,
    required this.onActiveFilterChanged,
  });

  @override
  State<ChannelFilters> createState() => _ChannelFiltersState();
}

class _ChannelFiltersState extends State<ChannelFilters> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedType;
  bool? _isActive;

  final List<ChannelTypeFilter> _types = [
    ChannelTypeFilter('all', 'الكل', CupertinoIcons.square_grid_2x2),
    ChannelTypeFilter('SYSTEM', 'النظام', CupertinoIcons.gear),
    ChannelTypeFilter('CUSTOM', 'مخصص', CupertinoIcons.star),
    ChannelTypeFilter('ROLE_BASED', 'حسب الدور', CupertinoIcons.person_2_square_stack),
    ChannelTypeFilter('EVENT_BASED', 'حسب الحدث', CupertinoIcons.bell_circle),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        const SizedBox(height: 12),
        _buildTypeFilters(),
        const SizedBox(height: 12),
        _buildStatusFilters(),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.inputBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.2),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: widget.onSearchChanged,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppTheme.textWhite,
        ),
        decoration: InputDecoration(
          hintText: 'البحث في القنوات...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textMuted.withOpacity(0.5),
          ),
          prefixIcon: Icon(
            CupertinoIcons.search,
            color: AppTheme.textMuted,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: AppTheme.textMuted,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    widget.onSearchChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeFilters() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _types.length,
        itemBuilder: (context, index) {
          final type = _types[index];
          final isSelected = (_selectedType ?? 'all') == type.value;

          return Padding(
            padding: EdgeInsets.only(
              right: index == 0 ? 0 : 8,
            ),
            child: FilterChip(
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedType = type.value == 'all' ? null : type.value;
                  } else {
                    _selectedType = null;
                  }
                });
                widget.onTypeChanged(_selectedType);
              },
              avatar: Icon(
                type.icon,
                size: 16,
                color: isSelected ? Colors.white : AppTheme.textMuted,
              ),
              label: Text(
                type.label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected ? Colors.white : AppTheme.textLight,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              backgroundColor: AppTheme.darkCard.withOpacity(0.5),
              selectedColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.primaryBlue
                      : AppTheme.darkBorder.withOpacity(0.3),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusFilters() {
    return Row(
      children: [
        _buildStatusChip(
          label: 'الكل',
          value: null,
          icon: CupertinoIcons.square_grid_2x2,
        ),
        const SizedBox(width: 8),
        _buildStatusChip(
          label: 'نشط',
          value: true,
          icon: CupertinoIcons.checkmark_circle,
          color: AppTheme.success,
        ),
        const SizedBox(width: 8),
        _buildStatusChip(
          label: 'غير نشط',
          value: false,
          icon: CupertinoIcons.xmark_circle,
          color: AppTheme.error,
        ),
        const Spacer(),
        _buildSortButton(),
      ],
    );
  }

  Widget _buildStatusChip({
    required String label,
    required bool? value,
    required IconData icon,
    Color? color,
  }) {
    final isSelected = _isActive == value;
    final chipColor = color ?? AppTheme.primaryBlue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _isActive = value;
          });
          widget.onActiveFilterChanged(value);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? chipColor.withOpacity(0.2)
                : AppTheme.darkCard.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? chipColor.withOpacity(0.4)
                  : AppTheme.darkBorder.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? chipColor : AppTheme.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected ? chipColor : AppTheme.textLight,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showSortOptions,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.arrow_up_arrow_down,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  'ترتيب',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'ترتيب حسب',
              style: AppTextStyles.heading3.copyWith(
                color: AppTheme.textWhite,
              ),
            ),
            const SizedBox(height: 20),
            _buildSortOption('الاسم', CupertinoIcons.textformat_abc),
            _buildSortOption('التاريخ', CupertinoIcons.calendar),
            _buildSortOption('المشتركين', CupertinoIcons.person_2),
            _buildSortOption('النشاط', CupertinoIcons.graph_circle),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, IconData icon) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textWhite,
                ),
              ),
              const Spacer(),
              Icon(
                CupertinoIcons.chevron_left,
                color: AppTheme.textMuted,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChannelTypeFilter {
  final String value;
  final String label;
  final IconData icon;

  ChannelTypeFilter(this.value, this.label, this.icon);
}
