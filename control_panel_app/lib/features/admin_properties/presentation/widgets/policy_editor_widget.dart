// lib/features/admin_properties/presentation/widgets/policy_editor_widget.dart

import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bookn_cp_app/core/theme/app_colors.dart';
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';
import '../../domain/entities/policy.dart';

class PolicyEditorWidget extends StatefulWidget {
  final Policy? policy;
  final Function(Policy) onSave;
  final VoidCallback onCancel;
  
  const PolicyEditorWidget({
    super.key,
    this.policy,
    required this.onSave,
    required this.onCancel,
  });
  
  @override
  State<PolicyEditorWidget> createState() => _PolicyEditorWidgetState();
}

class _PolicyEditorWidgetState extends State<PolicyEditorWidget> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _rulesController = TextEditingController();
  PolicyType _selectedType = PolicyType.cancellation;
  
  @override
  void initState() {
    super.initState();
    if (widget.policy != null) {
      _descriptionController.text = widget.policy!.description;
      _rulesController.text = widget.policy!.rules;
      _selectedType = widget.policy!.policyType;
    }
  }
  
  @override
  void dispose() {
    _descriptionController.dispose();
    _rulesController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withValues(alpha: 0.95),
            AppTheme.darkCard.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                  child: Text(
                    widget.policy != null ? 'تعديل السياسة' : 'إضافة سياسة جديدة',
                    style: AppTextStyles.heading3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onCancel,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: AppTheme.textMuted,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Policy Type Selector
            Text(
              'نوع السياسة',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkSurface.withValues(alpha: 0.5),
                    AppTheme.darkSurface.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.darkBorder.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<PolicyType>(
                  value: _selectedType,
                  isExpanded: true,
                  dropdownColor: AppTheme.darkCard,
                  icon: Icon(
                    Icons.arrow_drop_down_rounded,
                    color: AppTheme.primaryBlue.withValues(alpha: 0.7),
                  ),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                  ),
                  items: PolicyType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getPolicyTypeLabel(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Description Field
            Text(
              'الوصف',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkSurface.withValues(alpha: 0.5),
                    AppTheme.darkSurface.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.darkBorder.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textWhite,
                ),
                decoration: InputDecoration(
                  hintText: 'أدخل وصف السياسة',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textMuted.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال الوصف';
                  }
                  return null;
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Rules Field
            Text(
              'القواعد',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkSurface.withValues(alpha: 0.5),
                    AppTheme.darkSurface.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.darkBorder.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: TextFormField(
                controller: _rulesController,
                maxLines: 3,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textWhite,
                ),
                decoration: InputDecoration(
                  hintText: 'أدخل قواعد السياسة',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textMuted.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال القواعد';
                  }
                  return null;
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onCancel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.darkBorder.withValues(alpha: 0.3),
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
                    onTap: _savePolicy,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'حفظ',
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
          ],
        ),
      ),
    );
  }
  
  void _savePolicy() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      
      final policy = Policy(
        id: widget.policy?.id ?? '',
        propertyId: widget.policy?.propertyId ?? '',
        policyType: _selectedType,
        description: _descriptionController.text,
        rules: _rulesController.text,
        isActive: true,
      );
      
      widget.onSave(policy);
    }
  }
  
  String _getPolicyTypeLabel(PolicyType type) {
    switch (type) {
      case PolicyType.cancellation:
        return 'سياسة الإلغاء';
      case PolicyType.checkIn:
        return 'تسجيل الدخول';
      case PolicyType.checkOut:
        return 'تسجيل الخروج';
      case PolicyType.payment:
        return 'الدفع';
      case PolicyType.smoking:
        return 'التدخين';
      case PolicyType.pets:
        return 'الحيوانات الأليفة';
      case PolicyType.damage:
        return 'الأضرار';
      case PolicyType.other:
        return 'أخرى';
    }
  }
}