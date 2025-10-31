import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';
import 'icon_picker_modal.dart';

class UnitTypeModal extends StatefulWidget {
  final dynamic unitType;
  final String propertyTypeId;
  final Function(Map<String, dynamic>) onSave;

  const UnitTypeModal({
    super.key,
    this.unitType,
    required this.propertyTypeId,
    required this.onSave,
  });

  @override
  State<UnitTypeModal> createState() => _UnitTypeModalState();
}

class _UnitTypeModalState extends State<UnitTypeModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late int _maxCapacity;
  late String _selectedIcon;
  late double? _systemCommissionRate;
  late bool _isHasAdults;
  late bool _isHasChildren;
  late bool _isMultiDays;
  late bool _isRequiredToDetermineTheHour;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.unitType?.name ?? '');
    _maxCapacity = widget.unitType?.maxCapacity ?? 1;
    _selectedIcon = widget.unitType?.icon ?? 'apartment';
    _systemCommissionRate = widget.unitType?.systemCommissionRate;
    _isHasAdults = widget.unitType?.isHasAdults ?? false;
    _isHasChildren = widget.unitType?.isHasChildren ?? false;
    _isMultiDays = widget.unitType?.isMultiDays ?? false;
    _isRequiredToDetermineTheHour =
        widget.unitType?.isRequiredToDetermineTheHour ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isSmall = screenSize.width < 600;
    final EdgeInsets inset = isSmall
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
        : const EdgeInsets.all(20);
    final double dialogWidth =
        isSmall ? (screenSize.width - inset.horizontal) : 640;
    final double maxHeight =
        isSmall ? (screenSize.height * 0.95) : (screenSize.height * 0.85);

    return Dialog(
      insetPadding: const EdgeInsets.all(10),
      backgroundColor: Colors.transparent,
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: maxHeight,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkCard.withOpacity(0.95),
              AppTheme.darkCard.withOpacity(0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.neonGreen.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildNameField(),
                          const SizedBox(height: 16),
                          _buildIconSelector(),
                          const SizedBox(height: 16),
                          _buildCommissionField(),
                          const SizedBox(height: 16),
                          _buildCapacityField(),
                          const SizedBox(height: 20),
                          _buildFeaturesSection(),
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
            AppTheme.neonGreen.withOpacity(0.1),
            AppTheme.primaryBlue.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.3),
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
              gradient: LinearGradient(
                colors: [
                  AppTheme.neonGreen,
                  AppTheme.neonGreen.withOpacity(0.7)
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.home_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.unitType == null
                      ? 'إضافة نوع وحدة جديد'
                      : 'تعديل نوع الوحدة',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'قم بملء البيانات المطلوبة',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اسم النوع',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
          decoration: InputDecoration(
            hintText: 'أدخل اسم نوع الوحدة',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted.withOpacity(0.5),
            ),
            filled: true,
            fillColor: AppTheme.darkSurface.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.darkBorder.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.darkBorder.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.neonGreen.withOpacity(0.5),
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'الرجاء إدخال اسم النوع';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildIconSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الأيقونة',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showIconPicker(),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.darkBorder.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.neonGreen,
                        AppTheme.neonGreen.withOpacity(0.7)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    IconPickerModal.getIconFromString(_selectedIcon),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedIcon,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.textWhite,
                        ),
                      ),
                      Text(
                        'اضغط لتغيير الأيقونة',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppTheme.textMuted,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCapacityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'السعة القصوى',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.darkSurface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  if (_maxCapacity > 1) {
                    setState(() => _maxCapacity--);
                  }
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.darkSurface,
                        AppTheme.darkSurface.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.darkBorder.withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.remove_rounded,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                ),
              ),
              Text(
                '$_maxCapacity',
                style: AppTextStyles.heading2.copyWith(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _maxCapacity++);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.neonGreen,
                        AppTheme.neonGreen.withOpacity(0.7)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommissionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نسبة عمولة النظام (%)',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _systemCommissionRate?.toString() ?? '',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
          decoration: InputDecoration(
            hintText: 'مثال: 12.5',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted.withOpacity(0.5),
            ),
            filled: true,
            fillColor: AppTheme.darkSurface.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.darkBorder.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.darkBorder.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.neonGreen.withOpacity(0.5),
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return null; // optional
            final v = double.tryParse(value);
            if (v == null) return 'قيمة غير صحيحة';
            if (v < 0 || v > 100) return 'يجب أن تكون بين 0 و 100';
            return null;
          },
          onChanged: (value) {
            final v = double.tryParse(value);
            setState(() => _systemCommissionRate = v);
          },
        ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'خصائص نوع الوحدة',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.darkSurface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              _buildFeatureToggle(
                icon: Icons.person_rounded,
                title: 'يحتوي على بالغين',
                subtitle: 'تفعيل حقل عدد البالغين في الحجز',
                value: _isHasAdults,
                onChanged: (value) => setState(() => _isHasAdults = value),
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(height: 12),
              _buildFeatureToggle(
                icon: Icons.child_care_rounded,
                title: 'يحتوي على أطفال',
                subtitle: 'تفعيل حقل عدد الأطفال في الحجز',
                value: _isHasChildren,
                onChanged: (value) => setState(() => _isHasChildren = value),
                color: AppTheme.neonGreen,
              ),
              const SizedBox(height: 12),
              _buildFeatureToggle(
                icon: Icons.calendar_month_rounded,
                title: 'متعدد الأيام',
                subtitle: 'السماح بالحجز لعدة أيام',
                value: _isMultiDays,
                onChanged: (value) => setState(() => _isMultiDays = value),
                color: AppTheme.warning,
              ),
              const SizedBox(height: 12),
              _buildFeatureToggle(
                icon: Icons.access_time_rounded,
                title: 'يتطلب تحديد الساعة',
                subtitle: 'إلزام تحديد الوقت عند الحجز',
                value: _isRequiredToDetermineTheHour,
                onChanged: (value) =>
                    setState(() => _isRequiredToDetermineTheHour = value),
                color: AppTheme.primaryPurple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: value
            ? LinearGradient(
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
              )
            : null,
        color: value ? null : AppTheme.darkSurface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value
              ? color.withOpacity(0.3)
              : AppTheme.darkBorder.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
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
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
            activeTrackColor: color.withOpacity(0.3),
            inactiveThumbColor: AppTheme.textMuted,
            inactiveTrackColor: AppTheme.darkSurface,
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkSurface.withOpacity(0.7),
            AppTheme.darkSurface.withOpacity(0.5),
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
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
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
            child: GestureDetector(
              onTap: _save,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.neonGreen,
                      AppTheme.neonGreen.withOpacity(0.7)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonGreen.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.unitType == null ? 'إضافة' : 'تحديث',
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

  void _showIconPicker() {
    showDialog(
      fullscreenDialog: true,
      context: context,
      builder: (context) => IconPickerModal(
        selectedIcon: _selectedIcon,
        onSelectIcon: (icon) {
          setState(() {
            _selectedIcon = icon;
          });
        },
        iconCategory: 'units',
      ),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'name': _nameController.text,
        'maxCapacity': _maxCapacity,
        'icon': _selectedIcon,
        'systemCommissionRate': _systemCommissionRate,
        'isHasAdults': _isHasAdults,
        'isHasChildren': _isHasChildren,
        'isMultiDays': _isMultiDays,
        'isRequiredToDetermineTheHour': _isRequiredToDetermineTheHour,
      });
      Navigator.pop(context);
    }
  }
}
