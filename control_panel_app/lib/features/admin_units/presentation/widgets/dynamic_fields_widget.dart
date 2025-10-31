// lib/features/admin_units/presentation/widgets/dynamic_fields_widget.dart

import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';
import '../../domain/entities/unit_type.dart';
import 'package:intl/intl.dart';

class DynamicFieldsWidget extends StatefulWidget {
  final List<UnitTypeField> fields;
  final Map<String, dynamic> values;
  final Function(Map<String, dynamic>) onChanged;
  final bool isReadOnly;

  const DynamicFieldsWidget({
    super.key,
    required this.fields,
    required this.values,
    required this.onChanged,
    this.isReadOnly = false,
  });

  @override
  State<DynamicFieldsWidget> createState() => _DynamicFieldsWidgetState();
}

class _DynamicFieldsWidgetState extends State<DynamicFieldsWidget> {
  late Map<String, TextEditingController> _textControllers;
  late Map<String, dynamic> _currentValues;

  // Safely coerce dynamic values into a boolean
  bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is String) {
      final s = v.toLowerCase().trim();
      return s == 'true' || s == '1' || s == 'yes' || s == 'y';
    }
    if (v is num) return v != 0;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _currentValues = Map<String, dynamic>.from(widget.values);

    // Ensure sensible defaults (especially booleans -> false)
    bool changed = false;
    for (final field in widget.fields) {
      if (field.fieldTypeId == 'boolean' && _currentValues[field.fieldId] == null) {
        _currentValues[field.fieldId] = false;
        changed = true;
      }
    }

    // Propagate defaults to parent if anything changed
    if (changed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChanged(_currentValues);
      });
    }
  }

  void _initializeControllers() {
    _textControllers = {};
    for (final field in widget.fields) {
      if (_isTextBasedField(field.fieldTypeId)) {
        _textControllers[field.fieldId] = TextEditingController(
          text: widget.values[field.fieldId]?.toString() ?? '',
        );
      }
    }
  }

  @override
  void didUpdateWidget(covariant DynamicFieldsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Rebuild controllers for text-based fields when fields/values change
    final Set<String> newTextFieldIds = {
      for (final f in widget.fields)
        if (_isTextBasedField(f.fieldTypeId)) f.fieldId
    };

    // Remove controllers for fields no longer present
    final idsToRemove = _textControllers.keys
        .where((id) => !newTextFieldIds.contains(id))
        .toList();
    for (final id in idsToRemove) {
      _textControllers[id]?.dispose();
      _textControllers.remove(id);
    }

    // Add controllers for new text fields and sync their text
    for (final field in widget.fields) {
      if (_isTextBasedField(field.fieldTypeId)) {
        _textControllers.putIfAbsent(field.fieldId, () => TextEditingController());
      }
    }

    // Build new values map and ensure boolean defaults
    final Map<String, dynamic> newValues = Map<String, dynamic>.from(widget.values);
    bool changed = false;
    for (final field in widget.fields) {
      if (field.fieldTypeId == 'boolean' && newValues[field.fieldId] == null) {
        newValues[field.fieldId] = false;
        changed = true;
      }
    }

    // Sync controller texts for text-based fields
    for (final id in newTextFieldIds) {
      final String text = newValues[id]?.toString() ?? '';
      final controller = _textControllers[id]!;
      if (controller.text != text) {
        controller.text = text;
      }
    }

    // Update local snapshot
    _currentValues = newValues;

    // Notify parent if defaults were injected (avoids missing required bool fields)
    if (changed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChanged(_currentValues);
      });
    }
  }

  bool _isTextBasedField(String fieldType) {
    return ['text', 'textarea', 'email', 'phone', 'number', 'currency']
        .contains(fieldType);
  }

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fields.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
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
                        Icons.dynamic_form_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'معلومات إضافية',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ...widget.fields.map((field) => _buildField(field)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.3),
            AppTheme.darkCard.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.2),
                    AppTheme.primaryPurple.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.dynamic_form_rounded,
                size: 30,
                color: AppTheme.primaryBlue.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد حقول إضافية',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(UnitTypeField field) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel(field),
          const SizedBox(height: 8),
          _buildFieldInput(field),
          if (field.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildFieldDescription(field.description),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldLabel(UnitTypeField field) {
    return Row(
      children: [
        Text(
          field.displayName,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (field.isRequired)
          Text(
            ' *',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.error,
            ),
          ),
      ],
    );
  }

  Widget _buildFieldDescription(String description) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Text(
        description,
        style: AppTextStyles.caption.copyWith(
          color: AppTheme.textMuted.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildFieldInput(UnitTypeField field) {
    switch (field.fieldTypeId) {
      case 'text':
        return _buildTextField(field);
      case 'textarea':
        return _buildTextArea(field);
      case 'number':
        return _buildNumberField(field);
      case 'currency':
        return _buildCurrencyField(field);
      case 'email':
        return _buildEmailField(field);
      case 'phone':
        return _buildPhoneField(field);
      case 'boolean':
        return _buildBooleanField(field);
      case 'select':
        return _buildSelectField(field);
      case 'multiselect':
        return _buildMultiSelectField(field);
      case 'date':
        return _buildDateField(field);
      case 'file':
        return _buildFileField(field);
      case 'image':
        return _buildImageField(field);
      default:
        return _buildTextField(field);
    }
  }

  Widget _buildTextField(UnitTypeField field) {
    return Container(
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
        controller: _textControllers[field.fieldId],
        style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
        readOnly: widget.isReadOnly,
        decoration: InputDecoration(
          hintText: 'أدخل ${field.displayName}',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textMuted.withOpacity(0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          prefixIcon: Icon(
            Icons.text_fields_rounded,
            size: 20,
            color: AppTheme.primaryBlue.withOpacity(0.7),
          ),
        ),
        onChanged: widget.isReadOnly
            ? null
            : (value) {
                _updateValue(field.fieldId, value);
              },
      ),
    );
  }

  Widget _buildTextArea(UnitTypeField field) {
    return Container(
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
        controller: _textControllers[field.fieldId],
        style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
        readOnly: widget.isReadOnly,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: 'أدخل ${field.displayName}',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textMuted.withOpacity(0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          alignLabelWithHint: true,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Icon(
              Icons.subject_rounded,
              size: 20,
              color: AppTheme.primaryPurple.withOpacity(0.7),
            ),
          ),
        ),
        onChanged: widget.isReadOnly
            ? null
            : (value) {
                _updateValue(field.fieldId, value);
              },
      ),
    );
  }

  Widget _buildNumberField(UnitTypeField field) {
    return Container(
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
        controller: _textControllers[field.fieldId],
        style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
        readOnly: widget.isReadOnly,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          hintText: 'أدخل ${field.displayName}',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textMuted.withOpacity(0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          prefixIcon: Icon(
            Icons.numbers_rounded,
            size: 20,
            color: AppTheme.success.withOpacity(0.7),
          ),
        ),
        onChanged: widget.isReadOnly
            ? null
            : (value) {
                final numValue = int.tryParse(value) ?? 0;
                _updateValue(field.fieldId, numValue);
              },
      ),
    );
  }

  Widget _buildCurrencyField(UnitTypeField field) {
    return Container(
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
        controller: _textControllers[field.fieldId],
        style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
        readOnly: widget.isReadOnly,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        decoration: InputDecoration(
          hintText: 'أدخل ${field.displayName}',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textMuted.withOpacity(0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          prefixIcon: Icon(
            Icons.attach_money_rounded,
            size: 20,
            color: AppTheme.warning.withOpacity(0.7),
          ),
          suffixText: 'ريال',
          suffixStyle: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        onChanged: widget.isReadOnly
            ? null
            : (value) {
                final numValue = double.tryParse(value) ?? 0.0;
                _updateValue(field.fieldId, numValue);
              },
      ),
    );
  }

  Widget _buildEmailField(UnitTypeField field) {
    return Container(
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
        controller: _textControllers[field.fieldId],
        style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
        readOnly: widget.isReadOnly,
        keyboardType: TextInputType.emailAddress,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]')),
        ],
        decoration: InputDecoration(
          hintText: 'example@email.com',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textMuted.withOpacity(0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          prefixIcon: Icon(
            Icons.email_rounded,
            size: 20,
            color: AppTheme.primaryBlue.withOpacity(0.7),
          ),
        ),
        onChanged: widget.isReadOnly
            ? null
            : (value) {
                _updateValue(field.fieldId, value);
              },
      ),
    );
  }

  Widget _buildPhoneField(UnitTypeField field) {
    return Container(
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
        controller: _textControllers[field.fieldId],
        style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
        readOnly: widget.isReadOnly,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        decoration: InputDecoration(
          hintText: '05XXXXXXXX',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textMuted.withOpacity(0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          prefixIcon: Icon(
            Icons.phone_rounded,
            size: 20,
            color: AppTheme.success.withOpacity(0.7),
          ),
        ),
        onChanged: widget.isReadOnly
            ? null
            : (value) {
                _updateValue(field.fieldId, value);
              },
      ),
    );
  }

  Widget _buildBooleanField(UnitTypeField field) {
    final bool value = _asBool(_currentValues[field.fieldId]);

    return GestureDetector(
      onTap: widget.isReadOnly
          ? null
          : () {
              HapticFeedback.lightImpact();
              _updateValue(field.fieldId, !value);
            },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: value
                ? [
                    AppTheme.primaryBlue.withOpacity(0.2),
                    AppTheme.primaryPurple.withOpacity(0.1),
                  ]
                : [
                    AppTheme.darkSurface.withOpacity(0.5),
                    AppTheme.darkSurface.withOpacity(0.3),
                  ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? AppTheme.primaryBlue.withOpacity(0.5)
                : AppTheme.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: value ? AppTheme.primaryGradient : null,
                color: value ? null : AppTheme.darkCard,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value
                      ? AppTheme.primaryBlue
                      : AppTheme.darkBorder.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: value
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              value ? 'نعم' : 'لا',
              style: AppTextStyles.bodyMedium.copyWith(
                color: value ? AppTheme.primaryBlue : AppTheme.textMuted,
                fontWeight: value ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectField(UnitTypeField field) {
    final options = field.fieldOptions['options'] as List<dynamic>? ?? [];
    final value = _currentValues[field.fieldId];

    return Container(
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
      child: DropdownButtonFormField<String>(
        value: value?.toString(),
        dropdownColor: AppTheme.darkCard,
        style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          prefixIcon: Icon(
            Icons.arrow_drop_down_circle_rounded,
            color: AppTheme.neonPurple.withOpacity(0.7),
            size: 20,
          ),
        ),
        hint: Text(
          'اختر ${field.displayName}',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textMuted.withOpacity(0.5),
          ),
        ),
        items: options.map((option) {
          return DropdownMenuItem<String>(
            value: option.toString(),
            child: Text(
              option.toString(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite,
              ),
            ),
          );
        }).toList(),
        onChanged: widget.isReadOnly
            ? null
            : (newValue) {
                _updateValue(field.fieldId, newValue);
              },
      ),
    );
  }

  Widget _buildMultiSelectField(UnitTypeField field) {
    final options = field.fieldOptions['options'] as List<dynamic>? ?? [];
    final selectedValues =
        (_currentValues[field.fieldId] as List<dynamic>?) ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options.map((option) {
              final isSelected = selectedValues.contains(option);

              return GestureDetector(
                onTap: widget.isReadOnly
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        final newSelected = List<dynamic>.from(selectedValues);

                        if (isSelected) {
                          newSelected.remove(option);
                        } else {
                          newSelected.add(option);
                        }

                        _updateValue(field.fieldId, newSelected);
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppTheme.primaryGradient : null,
                    color: isSelected ? null : AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryBlue
                          : AppTheme.darkBorder.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    option.toString(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected ? Colors.white : AppTheme.textMuted,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(UnitTypeField field) {
    final value = _currentValues[field.fieldId];
    DateTime? selectedDate;
    if (value != null) {
      if (value is DateTime) {
        selectedDate = value;
      } else if (value is String) {
        selectedDate = DateTime.tryParse(value);
      }
    }

    return GestureDetector(
      onTap: widget.isReadOnly
          ? null
          : () async {
              HapticFeedback.lightImpact();
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
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
                _updateValue(field.fieldId, picked.toIso8601String());
              }
            },
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: AppTheme.primaryPurple.withOpacity(0.7),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedDate != null
                    ? DateFormat('yyyy-MM-dd').format(selectedDate)
                    : 'اختر التاريخ',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: selectedDate != null
                      ? AppTheme.textWhite
                      : AppTheme.textMuted.withOpacity(0.5),
                ),
              ),
            ),
            if (selectedDate != null && !widget.isReadOnly)
              GestureDetector(
                onTap: () {
                  _updateValue(field.fieldId, null);
                },
                child: Icon(
                  Icons.clear_rounded,
                  size: 18,
                  color: AppTheme.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileField(UnitTypeField field) {
    final fileName = _currentValues[field.fieldId];

    return GestureDetector(
      onTap: widget.isReadOnly
          ? null
          : () {
              HapticFeedback.lightImpact();
              // TODO: Implement file picker
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('اختيار الملف قيد التطوير')),
              );
            },
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Icon(
              Icons.attach_file_rounded,
              size: 20,
              color: AppTheme.warning.withOpacity(0.7),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fileName ?? 'اختر ملف',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: fileName != null
                      ? AppTheme.textWhite
                      : AppTheme.textMuted.withOpacity(0.5),
                ),
              ),
            ),
            if (!widget.isReadOnly)
              Icon(
                Icons.upload_rounded,
                size: 18,
                color: AppTheme.primaryBlue,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageField(UnitTypeField field) {
    final imagePath = _currentValues[field.fieldId];

    return GestureDetector(
      onTap: widget.isReadOnly
          ? null
          : () {
              HapticFeedback.lightImpact();
              // TODO: Implement image picker
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('اختيار الصورة قيد التطوير')),
              );
            },
      child: Container(
        height: 120,
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
        child: imagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildImagePlaceholder();
                  },
                ),
              )
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_rounded,
            size: 40,
            color: AppTheme.info.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'اختر صورة',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _updateValue(String fieldId, dynamic value) {
    setState(() {
      _currentValues[fieldId] = value;
    });
    widget.onChanged(_currentValues);
  }
}
