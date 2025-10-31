import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../bloc/bookings_list/bookings_list_state.dart';

class BookingFiltersWidget extends StatefulWidget {
  final BookingFilters? initialFilters;
  final Function(BookingFilters) onFiltersChanged;

  const BookingFiltersWidget({
    super.key,
    this.initialFilters,
    required this.onFiltersChanged,
  });

  @override
  State<BookingFiltersWidget> createState() => _BookingFiltersWidgetState();
}

class _BookingFiltersWidgetState extends State<BookingFiltersWidget> {
  late BookingFilters _filters;
  final TextEditingController _searchController = TextEditingController();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters ?? const BookingFilters();
    _searchController.text = _filters.guestNameOrEmail ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 400;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCompact) _buildCompactFilters() else _buildFullFilters(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactFilters() {
    return Column(
      children: [
        _buildSearchField(isCompact: true),
        const SizedBox(height: 8),
        _buildCompactDateSelector(),
        const SizedBox(height: 8),
        _buildQuickFilters(isCompact: true),
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          _buildStatusDropdown(isCompact: true),
        ],
        const SizedBox(height: 8),
        _buildExpandButton(),
      ],
    );
  }

  Widget _buildFullFilters() {
    return Column(
      children: [
        _buildDateRangeSelector(),
        const SizedBox(height: 12),
        _buildSearchAndStatusRow(),
        const SizedBox(height: 12),
        _buildAdvancedFiltersRow(),
        const SizedBox(height: 12),
        _buildQuickFilters(isCompact: false),
      ],
    );
  }

  Widget _buildExpandButton() {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.darkBorder.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isExpanded ? 'إخفاء الفلاتر' : 'المزيد من الفلاتر',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                CupertinoIcons.chevron_down,
                size: 14,
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactDateSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                _buildDateButton(
                  label: 'من',
                  date: _filters.startDate,
                  onTap: () => _selectDate(true),
                  isFullWidth: true,
                ),
                const SizedBox(height: 8),
                _buildDateButton(
                  label: 'إلى',
                  date: _filters.endDate,
                  onTap: () => _selectDate(false),
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
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
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.calendar,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateButton(
                    label: 'من',
                    date: _filters.startDate,
                    onTap: () => _selectDate(true),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 20,
                  height: 1,
                  color: AppTheme.darkBorder.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: _buildDateButton(
                    label: 'إلى',
                    date: _filters.endDate,
                    onTap: () => _selectDate(false),
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
    bool isFullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.darkBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: date != null
                ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                : AppTheme.darkBorder.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null ? Formatters.formatDate(date) : 'اختر التاريخ',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: date != null
                          ? AppTheme.textWhite
                          : AppTheme.textMuted,
                      fontWeight: date != null ? FontWeight.w600 : null,
                      fontSize: date != null ? 13 : 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_down,
              size: 14,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndStatusRow() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildSearchField(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusDropdown(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPaymentStatusDropdown(),
        ),
      ],
    );
  }

  Widget _buildSearchField({bool isCompact = false}) {
    return Container(
      height: isCompact ? 40 : null,
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppTheme.textWhite,
          fontSize: isCompact ? 13 : 14,
        ),
        decoration: InputDecoration(
          hintText: isCompact ? 'بحث...' : 'بحث بالاسم أو البريد الإلكتروني...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textMuted,
            fontSize: isCompact ? 13 : 14,
          ),
          prefixIcon: Icon(
            CupertinoIcons.search,
            color: AppTheme.textMuted,
            size: isCompact ? 18 : 20,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 16,
            vertical: isCompact ? 8 : 12,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _filters = _filters.copyWith(guestNameOrEmail: value);
          });
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildStatusDropdown({bool isCompact = false}) {
    return Container(
      height: isCompact ? 40 : null,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
        ),
      ),
      child: DropdownButton<String?>(
        value: _filters.status,
        isExpanded: true,
        dropdownColor: AppTheme.darkCard,
        underline: const SizedBox.shrink(),
        hint: Text(
          'جميع الحالات',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textMuted,
            fontSize: isCompact ? 12 : 14,
          ),
        ),
        icon: Icon(
          CupertinoIcons.chevron_down,
          size: isCompact ? 14 : 16,
          color: AppTheme.textMuted,
        ),
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppTheme.textWhite,
          fontSize: isCompact ? 12 : 14,
        ),
        items: const [
          DropdownMenuItem(value: null, child: Text('جميع الحالات')),
          DropdownMenuItem(value: 'pending', child: Text('معلق')),
          DropdownMenuItem(value: 'confirmed', child: Text('مؤكد')),
          DropdownMenuItem(value: 'checkedIn', child: Text('تم الوصول')),
          DropdownMenuItem(value: 'completed', child: Text('مكتمل')),
          DropdownMenuItem(value: 'cancelled', child: Text('ملغى')),
        ],
        onChanged: (value) {
          setState(() {
            _filters = _filters.copyWith(status: value);
          });
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildQuickFilters({bool isCompact = false}) {
    return SizedBox(
      height: isCompact ? 32 : 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildQuickFilterChip(
            label: 'كل الوقت',
            isSelected: _filters.startDate == null && _filters.endDate == null,
            onTap: () {
              setState(() {
                _filters = _filters.copyWith(startDate: null, endDate: null);
              });
              _applyFilters();
            },
            isCompact: isCompact,
          ),
          _buildQuickFilterChip(
            label: 'اليوم',
            isSelected: _isToday(),
            onTap: _selectToday,
            isCompact: isCompact,
          ),
          _buildQuickFilterChip(
            label: 'هذا الأسبوع',
            isSelected: _isThisWeek(),
            onTap: _selectThisWeek,
            isCompact: isCompact,
          ),
          _buildQuickFilterChip(
            label: 'هذا الشهر',
            isSelected: _isThisMonth(),
            onTap: _selectThisMonth,
            isCompact: isCompact,
          ),
          _buildQuickFilterChip(
            label: 'Walk-in',
            isSelected: _filters.isWalkIn == true,
            onTap: () {
              setState(() {
                _filters = _filters.copyWith(
                  isWalkIn: _filters.isWalkIn == true ? null : true,
                );
              });
              _applyFilters();
            },
            isCompact: isCompact,
          ),
          _buildQuickFilterChip(
            label: 'مسح',
            isSelected: false,
            onTap: _clearFilters,
            isAction: true,
            isCompact: isCompact,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isAction = false,
    bool isCompact = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isCompact ? 16 : 18),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 12 : 16,
            ),
            decoration: BoxDecoration(
              gradient: isSelected ? AppTheme.primaryGradient : null,
              color: isSelected
                  ? null
                  : isAction
                      ? AppTheme.error.withValues(alpha: 0.1)
                      : AppTheme.darkCard.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(isCompact ? 16 : 18),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : isAction
                        ? AppTheme.error.withValues(alpha: 0.3)
                        : AppTheme.darkBorder.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: isSelected
                      ? Colors.white
                      : isAction
                          ? AppTheme.error
                          : AppTheme.textMuted,
                  fontWeight: isSelected ? FontWeight.w600 : null,
                  fontSize: isCompact ? 11 : 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // باقي الدوال كما هي...
  void _selectDate(bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? _filters.startDate ?? DateTime.now()
          : _filters.endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
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
          _filters = _filters.copyWith(startDate: picked);
        } else {
          _filters = _filters.copyWith(endDate: picked);
        }
      });
      _applyFilters();
    }
  }

  bool _isToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _filters.startDate == today &&
        _filters.endDate == today.add(const Duration(days: 1));
  }

  bool _isThisWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    return _filters.startDate == weekStart && _filters.endDate == weekEnd;
  }

  bool _isThisMonth() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    return _filters.startDate == monthStart && _filters.endDate == monthEnd;
  }

  void _selectToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      _filters = _filters.copyWith(
        startDate: today,
        endDate: today.add(const Duration(days: 1)),
      );
    });
    _applyFilters();
  }

  void _selectThisWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    setState(() {
      _filters = _filters.copyWith(
        startDate: weekStart,
        endDate: weekEnd,
      );
    });
    _applyFilters();
  }

  void _selectThisMonth() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    setState(() {
      _filters = _filters.copyWith(
        startDate: monthStart,
        endDate: monthEnd,
      );
    });
    _applyFilters();
  }

  void _clearFilters() {
    setState(() {
      _filters = const BookingFilters();
      _searchController.clear();
      _minPriceController.clear();
      _minGuestsController.clear();
    });
    _applyFilters();
  }

  void _applyFilters() {
    widget.onFiltersChanged(_filters);
  }

  // فلتر حالة الدفع
  Widget _buildPaymentStatusDropdown({bool isCompact = false}) {
    return Container(
      height: isCompact ? 40 : null,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
        ),
      ),
      child: DropdownButton<String?>(
        value: _filters.paymentStatus,
        isExpanded: true,
        dropdownColor: AppTheme.darkCard,
        underline: const SizedBox.shrink(),
        hint: Text(
          'حالة الدفع',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textMuted,
            fontSize: isCompact ? 12 : 14,
          ),
        ),
        icon: Icon(
          CupertinoIcons.chevron_down,
          size: isCompact ? 14 : 16,
          color: AppTheme.textMuted,
        ),
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppTheme.textWhite,
          fontSize: isCompact ? 12 : 14,
        ),
        items: const [
          DropdownMenuItem(value: null, child: Text('جميع الحالات')),
          DropdownMenuItem(value: 'pending', child: Text('معلق')),
          DropdownMenuItem(value: 'completed', child: Text('مكتمل')),
          DropdownMenuItem(value: 'failed', child: Text('فشل')),
          DropdownMenuItem(value: 'refunded', child: Text('مسترجع')),
        ],
        onChanged: (value) {
          setState(() {
            _filters = _filters.copyWith(paymentStatus: value);
          });
          _applyFilters();
        },
      ),
    );
  }

  // صف الفلاتر المتقدمة
  Widget _buildAdvancedFiltersRow() {
    return Row(
      children: [
        Expanded(child: _buildMinPriceField()),
        const SizedBox(width: 12),
        Expanded(child: _buildMinGuestsField()),
        const SizedBox(width: 12),
        Expanded(child: _buildBookingSourceDropdown()),
      ],
    );
  }

  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _minGuestsController = TextEditingController();

  Widget _buildMinPriceField() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
        ),
      ),
      child: TextField(
        controller: _minPriceController,
        keyboardType: TextInputType.number,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppTheme.textWhite,
        ),
        decoration: InputDecoration(
          hintText: 'الحد الأدنى للسعر...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textMuted,
          ),
          prefixIcon: Icon(
            CupertinoIcons.money_dollar_circle,
            color: AppTheme.textMuted,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          final price = double.tryParse(value);
          setState(() {
            _filters = _filters.copyWith(minTotalPrice: price);
          });
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildMinGuestsField() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
        ),
      ),
      child: TextField(
        controller: _minGuestsController,
        keyboardType: TextInputType.number,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppTheme.textWhite,
        ),
        decoration: InputDecoration(
          hintText: 'عدد الضيوف الأدنى...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textMuted,
          ),
          prefixIcon: Icon(
            CupertinoIcons.person_2,
            color: AppTheme.textMuted,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          final guests = int.tryParse(value);
          setState(() {
            _filters = _filters.copyWith(minGuestsCount: guests);
          });
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildBookingSourceDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder.withValues(alpha: 0.2),
        ),
      ),
      child: DropdownButton<String?>(
        value: _filters.bookingSource,
        isExpanded: true,
        dropdownColor: AppTheme.darkCard,
        underline: const SizedBox.shrink(),
        hint: Text(
          'مصدر الحجز',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        icon: Icon(
          CupertinoIcons.chevron_down,
          size: 16,
          color: AppTheme.textMuted,
        ),
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppTheme.textWhite,
        ),
        items: const [
          DropdownMenuItem(value: null, child: Text('جميع المصادر')),
          DropdownMenuItem(value: 'mobile', child: Text('تطبيق الجوال')),
          DropdownMenuItem(value: 'web', child: Text('موقع ويب')),
          DropdownMenuItem(value: 'phone', child: Text('هاتف')),
          DropdownMenuItem(value: 'walkin', child: Text('Walk-in')),
        ],
        onChanged: (value) {
          setState(() {
            _filters = _filters.copyWith(bookingSource: value);
          });
          _applyFilters();
        },
      ),
    );
  }
}
