// lib/features/admin_users/presentation/widgets/user_filters_widget.dart

import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';

class UserFiltersWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onApplyFilters;
  
  const UserFiltersWidget({
    super.key,
    required this.onApplyFilters,
  });
  
  @override
  State<UserFiltersWidget> createState() => _UserFiltersWidgetState();
}

class _UserFiltersWidgetState extends State<UserFiltersWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  
  String? _selectedRole;
  bool? _isActive;
  DateTime? _createdAfter;
  DateTime? _createdBefore;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.2),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: FadeTransition(
        opacity: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withOpacity(0.5),
                AppTheme.darkCard.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildRoleFilter(),
                        _buildStatusFilter(),
                        _buildDateFilter('من تاريخ', _createdAfter, (date) {
                          setState(() => _createdAfter = date);
                        }),
                        _buildDateFilter('إلى تاريخ', _createdBefore, (date) {
                          setState(() => _createdBefore = date);
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildRoleFilter() {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRole,
          hint: Text(
            'الدور',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            color: AppTheme.primaryBlue.withOpacity(0.7),
            size: 20,
          ),
          dropdownColor: AppTheme.darkCard,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textWhite,
          ),
          items: [
            DropdownMenuItem(value: null, child: Text('الكل')),
            DropdownMenuItem(value: 'admin', child: Text('مدير')),
            DropdownMenuItem(value: 'owner', child: Text('مالك')),
            DropdownMenuItem(value: 'staff', child: Text('موظف')),
            DropdownMenuItem(value: 'customer', child: Text('عميل')),
          ],
          onChanged: (value) => setState(() => _selectedRole = value),
        ),
      ),
    );
  }
  
  Widget _buildStatusFilter() {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<bool?>(
          value: _isActive,
          hint: Text(
            'الحالة',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            color: AppTheme.primaryBlue.withOpacity(0.7),
            size: 20,
          ),
          dropdownColor: AppTheme.darkCard,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textWhite,
          ),
          items: [
            DropdownMenuItem(value: null, child: Text('الكل')),
            DropdownMenuItem(
              value: true,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('نشط'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: false,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('غير نشط'),
                ],
              ),
            ),
          ],
          onChanged: (value) => setState(() => _isActive = value),
        ),
      ),
    );
  }
  
  Widget _buildDateFilter(
    String label,
    DateTime? date,
    Function(DateTime?) onChanged,
  ) {
    return GestureDetector(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.dark(
                  primary: AppTheme.primaryBlue,
                  surface: AppTheme.darkCard,
                ),
              ),
              child: child!,
            );
          },
        );
        
        if (pickedDate != null) {
          onChanged(pickedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.darkBorder.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: AppTheme.primaryBlue.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Text(
              date != null
                  ? '${date.day}/${date.month}/${date.year}'
                  : label,
              style: AppTextStyles.bodySmall.copyWith(
                color: date != null ? AppTheme.textWhite : AppTheme.textMuted,
              ),
            ),
            if (date != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => onChanged(null),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      children: [
        TextButton(
          onPressed: _resetFilters,
          child: Text(
            'إعادة تعيين',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _applyFilters,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'تطبيق',
              style: AppTextStyles.buttonSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  void _resetFilters() {
    setState(() {
      _selectedRole = null;
      _isActive = null;
      _createdAfter = null;
      _createdBefore = null;
    });
    
    widget.onApplyFilters({});
  }
  
  void _applyFilters() {
    HapticFeedback.lightImpact();
    widget.onApplyFilters({
      'roleId': _selectedRole,
      'isActive': _isActive,
      'createdAfter': _createdAfter,
      'createdBefore': _createdBefore,
    });
  }
}