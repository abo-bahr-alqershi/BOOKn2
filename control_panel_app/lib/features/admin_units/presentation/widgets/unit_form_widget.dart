// lib/features/admin_units/presentation/widgets/unit_form_widget.dart

import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';

class UnitFormWidget extends StatefulWidget {
  final Function(String) onPropertyChanged;
  final Function(String) onUnitTypeChanged;
  final String? initialPropertyId;
  final String? initialUnitTypeId;
  final String? initialName;

  const UnitFormWidget({
    super.key,
    required this.onPropertyChanged,
    required this.onUnitTypeChanged,
    this.initialPropertyId,
    this.initialUnitTypeId,
    this.initialName,
  });

  @override
  State<UnitFormWidget> createState() => _UnitFormWidgetState();
}

class _UnitFormWidgetState extends State<UnitFormWidget>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  String? _selectedPropertyId;
  String? _selectedUnitTypeId;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    _selectedPropertyId = widget.initialPropertyId;
    _selectedUnitTypeId = widget.initialUnitTypeId;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkCard.withOpacity(0.5),
              AppTheme.darkCard.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryBlue.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.home_work_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'معلومات الوحدة',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _buildTextField(
                    label: 'اسم الوحدة',
                    controller: _nameController,
                    icon: Icons.home_rounded,
                    hint: 'أدخل اسم الوحدة',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildDropdown(
                    label: 'العقار',
                    value: _selectedPropertyId,
                    icon: Icons.location_city_rounded,
                    hint: 'اختر العقار',
                    items: _getPropertyItems(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPropertyId = value;
                        _selectedUnitTypeId = null;
                      });
                      widget.onPropertyChanged(value!);
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildDropdown(
                    label: 'نوع الوحدة',
                    value: _selectedUnitTypeId,
                    icon: Icons.apartment_rounded,
                    hint: 'اختر نوع الوحدة',
                    items: _getUnitTypeItems(),
                    onChanged: (value) {
                      setState(() => _selectedUnitTypeId = value);
                      widget.onUnitTypeChanged(value!);
                    },
                    enabled: _selectedPropertyId != null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkSurface.withOpacity(0.5),
                AppTheme.darkSurface.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted.withOpacity(0.5),
              ),
              prefixIcon: Icon(
                icon,
                size: 20,
                color: AppTheme.primaryBlue.withOpacity(0.7),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required IconData icon,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: enabled ? 1.0 : 0.6,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: enabled
                    ? [
                        AppTheme.darkSurface.withOpacity(0.5),
                        AppTheme.darkSurface.withOpacity(0.3),
                      ]
                    : [
                        AppTheme.darkSurface.withOpacity(0.3),
                        AppTheme.darkSurface.withOpacity(0.2),
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: enabled
                    ? AppTheme.darkBorder.withOpacity(0.3)
                    : AppTheme.darkBorder.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: DropdownButtonFormField<String>(
              value: value,
              dropdownColor: AppTheme.darkCard,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textMuted.withOpacity(0.5),
                ),
                prefixIcon: Icon(
                  icon,
                  size: 20,
                  color: enabled 
                      ? AppTheme.primaryBlue.withOpacity(0.7)
                      : AppTheme.textMuted.withOpacity(0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: items,
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          ' *',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.error,
          ),
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _getPropertyItems() {
    return [
      const DropdownMenuItem(
        value: 'prop1',
        child: Text('فندق الهيلتون'),
      ),
      const DropdownMenuItem(
        value: 'prop2',
        child: Text('منتجع البحر الأحمر'),
      ),
    ];
  }

  List<DropdownMenuItem<String>> _getUnitTypeItems() {
    if (_selectedPropertyId == null) return [];
    
    return [
      const DropdownMenuItem(
        value: 'type1',
        child: Text('غرفة مفردة'),
      ),
      const DropdownMenuItem(
        value: 'type2',
        child: Text('جناح'),
      ),
    ];
  }
}