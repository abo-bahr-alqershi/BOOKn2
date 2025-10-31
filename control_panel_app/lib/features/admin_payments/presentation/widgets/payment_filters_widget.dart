import 'package:bookn_cp_app/features/admin_payments/presentation/bloc/payments_list/payments_list_bloc.dart';
import 'package:bookn_cp_app/features/admin_payments/presentation/bloc/payments_list/payments_list_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/enums/payment_method_enum.dart';
import '../../../../../../core/utils/formatters.dart';

class PaymentFiltersWidget extends StatefulWidget {
  const PaymentFiltersWidget({super.key});

  @override
  State<PaymentFiltersWidget> createState() => _PaymentFiltersWidgetState();
}

class _PaymentFiltersWidgetState extends State<PaymentFiltersWidget>
    with SingleTickerProviderStateMixin {
  PaymentStatus? _selectedStatus;
  PaymentMethod? _selectedMethod;
  DateTimeRange? _selectedDateRange;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 450;
        final isMedium =
            constraints.maxWidth >= 450 && constraints.maxWidth < 800;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          constraints: BoxConstraints(
            maxHeight: _calculateMaxHeight(isCompact, isMedium),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.darkCard.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.darkBorder.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isCompact ? 12 : 16),
                  child: isCompact
                      ? _buildCompactLayout()
                      : isMedium
                          ? _buildMediumLayout()
                          : _buildFullLayout(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _calculateMaxHeight(bool isCompact, bool isMedium) {
    if (isCompact) {
      return _isExpanded ? 280 : 180;
    } else if (isMedium) {
      return 160;
    } else {
      return 140;
    }
  }

  // Layout للشاشات الصغيرة (موبايل)
  Widget _buildCompactLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactSearchBar(),
        const SizedBox(height: 8),
        _buildCompactDateSelector(),
        const SizedBox(height: 8),
        _buildCompactFilterChips(),
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          _buildCompactAdvancedFilters(),
        ],
        const SizedBox(height: 8),
        _buildExpandToggle(),
      ],
    );
  }

  // Layout للشاشات المتوسطة (تابلت)
  Widget _buildMediumLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(flex: 2, child: _buildSearchBar()),
            const SizedBox(width: 12),
            Expanded(child: _buildCompactDateButton()),
          ],
        ),
        const SizedBox(height: 12),
        _buildFilterChipsRow(),
      ],
    );
  }

  // Layout للشاشات الكبيرة (ديسكتوب)
  Widget _buildFullLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(flex: 3, child: _buildSearchBar()),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: _buildDateRangeSelector()),
          ],
        ),
        const SizedBox(height: 12),
        _buildFilterChipsRow(),
      ],
    );
  }

  // شريط البحث المُحسّن
  Widget _buildSearchBar({bool isCompact = false}) {
    return Container(
      height: isCompact ? 40 : 48,
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _searchController.text.isNotEmpty
              ? AppTheme.primaryBlue.withValues(alpha: 0.3)
              : AppTheme.darkBorder.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppTheme.textWhite,
          fontSize: isCompact ? 13 : 14,
        ),
        decoration: InputDecoration(
          hintText: isCompact ? 'بحث...' : 'البحث في المدفوعات...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textMuted,
            fontSize: isCompact ? 13 : 14,
          ),
          prefixIcon: Icon(
            CupertinoIcons.search,
            color: AppTheme.textMuted,
            size: isCompact ? 18 : 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: AppTheme.textMuted,
                    size: isCompact ? 16 : 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 16,
            vertical: isCompact ? 8 : 12,
          ),
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _applyFilters(),
      ),
    );
  }

  Widget _buildCompactSearchBar() => _buildSearchBar(isCompact: true);

  // محدد التاريخ المُحسّن
  Widget _buildDateRangeSelector() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedDateRange != null
              ? AppTheme.primaryBlue.withValues(alpha: 0.3)
              : AppTheme.darkBorder.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: _showDatePicker,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.calendar,
              color: _selectedDateRange != null
                  ? AppTheme.primaryBlue
                  : AppTheme.textMuted,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedDateRange != null
                    ? _formatDateRange(_selectedDateRange!)
                    : 'اختر نطاق التاريخ',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _selectedDateRange != null
                      ? AppTheme.textWhite
                      : AppTheme.textMuted,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_selectedDateRange != null)
              GestureDetector(
                onTap: () {
                  setState(() => _selectedDateRange = null);
                  _applyFilters();
                },
                child: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: AppTheme.textMuted,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // محدد التاريخ المضغوط
  Widget _buildCompactDateSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildDateButton(
            label: 'من',
            date: _selectedDateRange?.start,
            onTap: () => _selectSingleDate(true),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDateButton(
            label: 'إلى',
            date: _selectedDateRange?.end,
            onTap: () => _selectSingleDate(false),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactDateButton() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedDateRange != null
              ? AppTheme.primaryBlue.withValues(alpha: 0.3)
              : AppTheme.darkBorder.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showDatePicker,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.calendar,
                  size: 18,
                  color: _selectedDateRange != null
                      ? AppTheme.primaryBlue
                      : AppTheme.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedDateRange != null
                        ? '${_formatCompactDate(_selectedDateRange!.start)} - ${_formatCompactDate(_selectedDateRange!.end)}'
                        : 'التاريخ',
                    style: AppTextStyles.caption.copyWith(
                      color: _selectedDateRange != null
                          ? AppTheme.textWhite
                          : AppTheme.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    DateTime? date,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: date != null
              ? AppTheme.primaryBlue.withValues(alpha: 0.3)
              : AppTheme.darkBorder.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                  ),
                ),
                Text(
                  date != null ? _formatCompactDate(date) : 'اختر',
                  style: AppTextStyles.caption.copyWith(
                    color:
                        date != null ? AppTheme.textWhite : AppTheme.textMuted,
                    fontWeight: date != null ? FontWeight.w600 : null,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // شريط الفلاتر السريعة
  Widget _buildFilterChipsRow() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildQuickFilterChip(
            label: 'اليوم',
            isSelected: _isToday(),
            onTap: _selectToday,
          ),
          _buildQuickFilterChip(
            label: 'هذا الأسبوع',
            isSelected: _isThisWeek(),
            onTap: _selectThisWeek,
          ),
          _buildQuickFilterChip(
            label: 'هذا الشهر',
            isSelected: _isThisMonth(),
            onTap: _selectThisMonth,
          ),
          _buildFilterChip(
            label: 'الحالة',
            value: _selectedStatus != null
                ? _getStatusText(_selectedStatus!)
                : null,
            icon: CupertinoIcons.flag,
            onTap: _showStatusFilter,
          ),
          _buildFilterChip(
            label: 'طريقة الدفع',
            value: _selectedMethod != null
                ? _getMethodText(_selectedMethod!)
                : null,
            icon: CupertinoIcons.creditcard,
            onTap: _showMethodFilter,
          ),
          if (_hasActiveFilters()) _buildClearFiltersButton(),
        ],
      ),
    );
  }

  Widget _buildCompactFilterChips() {
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCompactFilterChip(
            icon: CupertinoIcons.flag,
            label: _selectedStatus != null
                ? _getStatusText(_selectedStatus!)
                : 'الحالة',
            isSelected: _selectedStatus != null,
            onTap: _showStatusFilter,
          ),
          const SizedBox(width: 6),
          _buildCompactFilterChip(
            icon: CupertinoIcons.creditcard,
            label: _selectedMethod != null
                ? _getMethodText(_selectedMethod!)
                : 'الطريقة',
            isSelected: _selectedMethod != null,
            onTap: _showMethodFilter,
          ),
          if (_hasActiveFilters()) ...[
            const SizedBox(width: 6),
            _buildCompactClearButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactAdvancedFilters() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          _buildQuickFilterRow(),
        ],
      ),
    );
  }

  Widget _buildQuickFilterRow() {
    return Row(
      children: [
        Expanded(
          child: _buildMiniQuickFilter('اليوم', _isToday(), _selectToday),
        ),
        const SizedBox(width: 4),
        Expanded(
          child:
              _buildMiniQuickFilter('الأسبوع', _isThisWeek(), _selectThisWeek),
        ),
        const SizedBox(width: 4),
        Expanded(
          child:
              _buildMiniQuickFilter('الشهر', _isThisMonth(), _selectThisMonth),
        ),
      ],
    );
  }

  Widget _buildMiniQuickFilter(
      String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : AppTheme.darkCard.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppTheme.darkBorder.withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isSelected ? Colors.white : AppTheme.textMuted,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: isSelected ? AppTheme.primaryGradient : null,
              color:
                  isSelected ? null : AppTheme.darkCard.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : AppTheme.darkBorder.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: isSelected ? Colors.white : AppTheme.textMuted,
                  fontWeight: isSelected ? FontWeight.w600 : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    String? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null;
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: hasValue ? AppTheme.primaryGradient : null,
              color: hasValue ? null : AppTheme.darkCard.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hasValue
                    ? Colors.transparent
                    : AppTheme.darkBorder.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppTheme.textWhite, size: 16),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: Text(
                    value ?? label,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textWhite,
                      fontWeight:
                          hasValue ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasValue) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      if (icon == CupertinoIcons.flag) {
                        setState(() => _selectedStatus = null);
                      } else if (icon == CupertinoIcons.creditcard) {
                        setState(() => _selectedMethod = null);
                      }
                      _applyFilters();
                    },
                    child: Icon(
                      CupertinoIcons.xmark_circle_fill,
                      color: AppTheme.textWhite,
                      size: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactFilterChip({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : AppTheme.darkCard.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppTheme.darkBorder.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.textWhite),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textWhite,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearFiltersButton() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _clearFilters,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.error.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.clear_circled_solid,
                  color: AppTheme.error,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'مسح',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactClearButton() {
    return GestureDetector(
      onTap: _clearFilters,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.error.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(
          CupertinoIcons.clear_circled_solid,
          color: AppTheme.error,
          size: 14,
        ),
      ),
    );
  }

  Widget _buildExpandToggle() {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppTheme.darkBorder.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isExpanded ? 'إخفاء' : 'المزيد',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.primaryBlue,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                CupertinoIcons.chevron_down,
                size: 12,
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  void _showStatusFilter() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Material(
        color: Colors.transparent,
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.darkBorder.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'اختر حالة الدفعة',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppTheme.textWhite,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: PaymentStatus.values.map((status) {
                    return ListTile(
                      title: Text(
                        _getStatusText(status),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.textWhite,
                        ),
                      ),
                      trailing: _selectedStatus == status
                          ? Icon(
                              CupertinoIcons.checkmark_circle_fill,
                              color: AppTheme.primaryBlue,
                            )
                          : null,
                      onTap: () {
                        setState(() => _selectedStatus = status);
                        Navigator.pop(context);
                        _applyFilters();
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMethodFilter() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Material(
        color: Colors.transparent,
        child: Container(
          height: 350,
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.darkBorder.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'اختر طريقة الدفع',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppTheme.textWhite,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: PaymentMethod.values.map((method) {
                    return ListTile(
                      title: Text(
                        _getMethodText(method),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.textWhite,
                        ),
                      ),
                      trailing: _selectedMethod == method
                          ? Icon(
                              CupertinoIcons.checkmark_circle_fill,
                              color: AppTheme.primaryBlue,
                            )
                          : null,
                      onTap: () {
                        setState(() => _selectedMethod = method);
                        Navigator.pop(context);
                        _applyFilters();
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDatePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryBlue,
              onPrimary: AppTheme.textWhite,
              surface: AppTheme.darkCard,
              onSurface: AppTheme.textWhite,
            ),
            dialogTheme: DialogThemeData(backgroundColor: AppTheme.darkCard),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _applyFilters();
    }
  }

  void _selectSingleDate(bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? _selectedDateRange?.start ?? DateTime.now()
          : _selectedDateRange?.end ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
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
          final endDate = _selectedDateRange?.end ?? picked;
          _selectedDateRange = DateTimeRange(
            start: picked,
            end: endDate.isAfter(picked) ? endDate : picked,
          );
        } else {
          final startDate = _selectedDateRange?.start ?? picked;
          _selectedDateRange = DateTimeRange(
            start: startDate.isBefore(picked) ? startDate : picked,
            end: picked,
          );
        }
      });
      _applyFilters();
    }
  }

  bool _isToday() {
    if (_selectedDateRange == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return _selectedDateRange!.start == today &&
        _selectedDateRange!.end.isBefore(tomorrow);
  }

  bool _isThisWeek() {
    if (_selectedDateRange == null) return false;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return _selectedDateRange!.start == weekStart &&
        _selectedDateRange!.end == weekEnd;
  }

  bool _isThisMonth() {
    if (_selectedDateRange == null) return false;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    return _selectedDateRange!.start == monthStart &&
        _selectedDateRange!.end == monthEnd;
  }

  void _selectToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      _selectedDateRange = DateTimeRange(
        start: today,
        end: today
            .add(const Duration(days: 1))
            .subtract(const Duration(seconds: 1)),
      );
    });
    _applyFilters();
  }

  void _selectThisWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    setState(() {
      _selectedDateRange = DateTimeRange(start: weekStart, end: weekEnd);
    });
    _applyFilters();
  }

  void _selectThisMonth() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    setState(() {
      _selectedDateRange = DateTimeRange(start: monthStart, end: monthEnd);
    });
    _applyFilters();
  }

  void _applyFilters() {
    context.read<PaymentsListBloc>().add(
          FilterPaymentsEvent(
            status: _selectedStatus,
            method: _selectedMethod,
            startDate: _selectedDateRange?.start,
            endDate: _selectedDateRange?.end,
          ),
        );

    if (_searchController.text.isNotEmpty) {
      context.read<PaymentsListBloc>().add(
            SearchPaymentsEvent(searchTerm: _searchController.text),
          );
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedMethod = null;
      _selectedDateRange = null;
      _searchController.clear();
    });
    _applyFilters();
  }

  bool _hasActiveFilters() {
    return _selectedStatus != null ||
        _selectedMethod != null ||
        _selectedDateRange != null ||
        _searchController.text.isNotEmpty;
  }

  String _getStatusText(PaymentStatus status) {
    // Implementation based on PaymentStatus enum
    return status.toString().split('.').last;
  }

  String _getMethodText(PaymentMethod method) {
    // Implementation based on PaymentMethod enum
    return method.toString().split('.').last;
  }

  String _formatDateRange(DateTimeRange range) {
    return '${_formatDate(range.start)} - ${_formatDate(range.end)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatCompactDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}
