import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../booking/presentation/widgets/guest_selector_widget.dart';

class DynamicFieldsWidget extends StatefulWidget {
  final List<dynamic> fields;
  final Map<String, dynamic> values;
  final Function(Map<String, dynamic>) onChanged;
  final bool isCompact;

  const DynamicFieldsWidget({
    super.key,
    required this.fields,
    required this.values,
    required this.onChanged,
    this.isCompact = false,
  });

  @override
  State<DynamicFieldsWidget> createState() => 
      _DynamicFieldsWidgetState();
}

class _DynamicFieldsWidgetState 
    extends State<DynamicFieldsWidget> 
    with TickerProviderStateMixin {
  
  late Map<String, dynamic> _values;
  final Map<String, AnimationController> _fieldAnimations = {};
  final Map<String, AnimationController> _focusAnimations = {};
  final Map<String, FocusNode> _focusNodes = {};
  late AnimationController _shimmerController;
  late AnimationController _glowController;
  
  // Field type icons with futuristic design
  final Map<String, IconData> _fieldIcons = {
    'text': Icons.text_fields_rounded,
    'textarea': Icons.notes_rounded,
    'number': Icons.pin_rounded,
    'currency': Icons.payments_rounded,
    'boolean': Icons.toggle_on_rounded,
    'select': Icons.arrow_drop_down_circle_rounded,
    'multiselect': Icons.checklist_rounded,
    'date': Icons.event_rounded,
    'email': Icons.email_rounded,
    'phone': Icons.phone_rounded,
    'file': Icons.attach_file_rounded,
    'image': Icons.image_rounded,
    'checkbox': Icons.check_box_rounded,
    'radio': Icons.radio_button_checked_rounded,
    'range': Icons.tune_rounded,
  };

  @override
  void initState() {
    super.initState();
    _values = Map.from(widget.values);
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    for (var field in widget.fields) {
      final name = field['name'] ?? '';
      
      _fieldAnimations[name] = AnimationController(
        duration: Duration(milliseconds: 600 + (widget.fields.indexOf(field) * 100)),
        vsync: this,
      )..forward();
      
      _focusAnimations[name] = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
      
      _focusNodes[name] = FocusNode()
        ..addListener(() {
          if (_focusNodes[name]!.hasFocus) {
            _focusAnimations[name]?.forward();
            HapticFeedback.selectionClick();
          } else {
            _focusAnimations[name]?.reverse();
          }
        });
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _glowController.dispose();
    for (var controller in _fieldAnimations.values) {
      controller.dispose();
    }
    for (var controller in _focusAnimations.values) {
      controller.dispose();
    }
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fields.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.isCompact) _buildHeader(),
        ...widget.fields.asMap().entries.map((entry) {
          final index = entry.key;
          final field = entry.value;
          final name = field['name'] ?? '';
          
          return AnimatedBuilder(
            animation: _fieldAnimations[name]!,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  0,
                  20 * (1 - _fieldAnimations[name]!.value),
                ),
                child: Opacity(
                  opacity: _fieldAnimations[name]!.value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.95 + (0.05 * _fieldAnimations[name]!.value),
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: widget.isCompact ? 12 : 16,
                      ),
                      child: _buildFieldWrapper(field),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(
                        0.3 + (0.2 * _glowController.value),
                      ),
                      blurRadius: 10 + (5 * _glowController.value),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.filter_alt_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          ShaderMask(
            shaderCallback: (bounds) => 
                AppTheme.primaryGradient.createShader(bounds),
            child: Text(
              'الفلاتر المتقدمة',
              style: AppTextStyles.heading3.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          if (_values.isNotEmpty)
            _buildClearButton(),
        ],
      ),
    );
  }

  Widget _buildClearButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _values.clear();
        });
        widget.onChanged(_values);
        HapticFeedback.mediumImpact();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.error.withOpacity(0.2),
              AppTheme.error.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.error.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.clear_all_rounded,
              size: 16,
              color: AppTheme.error,
            ),
            const SizedBox(width: 6),
            Text(
              'مسح الكل',
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkCard.withOpacity(0.3),
                AppTheme.darkCard.withOpacity(0.2),
                AppTheme.primaryBlue.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryBlue.withOpacity(0.2),
                      AppTheme.primaryPurple.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.filter_alt_off_rounded,
                      size: 35,
                      color: AppTheme.textMuted.withOpacity(0.5),
                    ),
                    CustomPaint(
                      size: const Size(80, 80),
                      painter: _CircularShimmerPainter(
                        animation: _shimmerController,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    colors: [
                      AppTheme.textMuted.withOpacity(0.6),
                      AppTheme.textMuted.withOpacity(0.3),
                    ],
                  ).createShader(bounds);
                },
                child: Text(
                  'لا توجد فلاتر إضافية',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'جميع الخيارات متاحة',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textMuted.withOpacity(0.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFieldWrapper(dynamic field) {
    final fieldType = field['fieldTypeId'] ?? field['type'] ?? 'text';
    final fieldName = field['fieldName'] ?? field['name'] ?? '';
    
    return AnimatedBuilder(
      animation: _focusAnimations[fieldName] ?? 
                 AlwaysStoppedAnimation(0),
      builder: (context, child) {
        final focusValue = _focusAnimations[fieldName]?.value ?? 0.0;
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCard.withOpacity(0.4 + (0.2 * focusValue)),
                AppTheme.darkCard.withOpacity(0.2 + (0.1 * focusValue)),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.1 + (0.3 * focusValue)),
              width: 1 + focusValue,
            ),
            boxShadow: [
              if (focusValue > 0)
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.2 * focusValue),
                  blurRadius: 20 * focusValue,
                  spreadRadius: 2 * focusValue,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 10,
                sigmaY: 10,
              ),
              child: _buildField(field),
            ),
          ),
        );
      },
    );
  }

  Widget _buildField(dynamic field) {
    final fieldType = field['fieldTypeId'] ?? field['type'] ?? 'text';
    final fieldName = field['fieldName'] ?? field['name'] ?? '';
    final fieldLabel = field['displayName'] ?? field['label'] ?? fieldName;
    final isRequired = field['isRequired'] ?? field['required'] ?? false;
    
    switch (fieldType) {
      case 'text':
      case 'email':
      case 'phone':
        return _buildFuturisticTextField(field, fieldName, fieldLabel, isRequired, fieldType);
      case 'textarea':
        return _buildFuturisticTextArea(field, fieldName, fieldLabel, isRequired);
      case 'number':
      case 'currency':
        return _buildFuturisticNumberField(field, fieldName, fieldLabel, isRequired, fieldType);
      case 'select':
        return _buildFuturisticSelectField(field, fieldName, fieldLabel, isRequired);
      case 'multiselect':
        return _buildFuturisticMultiSelectField(field, fieldName, fieldLabel, isRequired);
      case 'checkbox':
      case 'boolean':
        return _buildFuturisticCheckbox(field, fieldName, fieldLabel);
      case 'radio':
        return _buildFuturisticRadioField(field, fieldName, fieldLabel, isRequired);
      case 'range':
        return _buildFuturisticRangeField(field, fieldName, fieldLabel);
      case 'date':
        return _buildFuturisticDateField(field, fieldName, fieldLabel, isRequired);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFuturisticTextField(
    dynamic field,
    String name,
    String label,
    bool isRequired,
    String type,
  ) {
    final currentValue = _values[name]?.toString() ?? '';
    final icon = _fieldIcons[type] ?? Icons.text_fields_rounded;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompactLabel(label, isRequired, icon),
          const SizedBox(height: 10),
          Container(
            height: 45,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkSurface.withOpacity(0.5),
                  AppTheme.darkSurface.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: currentValue.isNotEmpty 
                    ? AppTheme.primaryBlue.withOpacity(0.3)
                    : AppTheme.darkBorder.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: TextField(
              focusNode: _focusNodes[name],
              controller: TextEditingController(text: currentValue)
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: currentValue.length),
                ),
              keyboardType: type == 'email' 
                  ? TextInputType.emailAddress
                  : type == 'phone'
                      ? TextInputType.phone
                      : TextInputType.text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite,
              ),
              decoration: InputDecoration(
                hintText: field['placeholder'] ?? 'أدخل $label',
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textMuted.withOpacity(0.4),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(right: 12, left: 8),
                  child: Icon(
                    icon,
                    size: 18,
                    color: currentValue.isNotEmpty
                        ? AppTheme.primaryBlue.withOpacity(0.7)
                        : AppTheme.textMuted.withOpacity(0.3),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                suffixIcon: currentValue.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          setState(() {
                            _values.remove(name);
                          });
                          widget.onChanged(_values);
                          HapticFeedback.lightImpact();
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 8),
                          child: Icon(
                            Icons.clear_rounded,
                            size: 16,
                            color: AppTheme.textMuted.withOpacity(0.5),
                          ),
                        ),
                      )
                    : null,
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  if (value.isEmpty) {
                    _values.remove(name);
                  } else {
                    _values[name] = value;
                  }
                });
                widget.onChanged(_values);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticTextArea(
    dynamic field,
    String name,
    String label,
    bool isRequired,
  ) {
    final currentValue = _values[name]?.toString() ?? '';
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompactLabel(label, isRequired, Icons.notes_rounded),
          const SizedBox(height: 10),
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkSurface.withOpacity(0.5),
                  AppTheme.darkSurface.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: currentValue.isNotEmpty 
                    ? AppTheme.primaryBlue.withOpacity(0.3)
                    : AppTheme.darkBorder.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: TextField(
              focusNode: _focusNodes[name],
              controller: TextEditingController(text: currentValue)
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: currentValue.length),
                ),
              maxLines: 4,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite,
              ),
              decoration: InputDecoration(
                hintText: field['placeholder'] ?? 'أدخل $label',
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textMuted.withOpacity(0.4),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
              onChanged: (value) {
                setState(() {
                  if (value.isEmpty) {
                    _values.remove(name);
                  } else {
                    _values[name] = value;
                  }
                });
                widget.onChanged(_values);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticNumberField(
    dynamic field,
    String name,
    String label,
    bool isRequired,
    String type,
  ) {
    final min = (field['validationRules']?['min'] ??
            field['min'] ??
            0)
        .toDouble();
    final max = (field['validationRules']?['max'] ??
            field['max'] ??
            100)
        .toDouble();
    final currentValue = (_values[name] ?? min).toDouble();
    final icon = type == 'currency'
        ? Icons.payments_rounded
        : Icons.pin_rounded;

    // Use the exact GuestSelectorWidget design for numeric fields
    if (type == 'number') {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: GuestSelectorWidget(
          label: label,
          count: currentValue.toInt().clamp(min.toInt(), max.toInt()),
          minCount: min.toInt(),
          maxCount: max.toInt(),
          onChanged: (value) {
            setState(() {
              _values[name] = value;
            });
            widget.onChanged(_values);
            HapticFeedback.selectionClick();
          },
        ),
      );
    }

    // Preserve slider UI for currency fields
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCompactLabel(label, isRequired, icon),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(
                  '${currentValue.toStringAsFixed(0)} ريال',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withOpacity(0.1),
                      AppTheme.primaryPurple.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  trackHeight: 6,
                  thumbColor: AppTheme.primaryBlue,
                  overlayColor: AppTheme.primaryBlue.withOpacity(0.2),
                  thumbShape: _GlowingSliderThumbShape(
                    enabledThumbRadius: 10,
                    glowRadius: 20,
                  ),
                ),
                child: Slider(
                  value: currentValue,
                  min: min,
                  max: max,
                  onChanged: (value) {
                    setState(() {
                      _values[name] = value;
                    });
                    widget.onChanged(_values);
                    HapticFeedback.selectionClick();
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${min.toInt()} ريال',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
                Text(
                  '${max.toInt()} ريال',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textMuted.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticSelectField(
    dynamic field,
    String name,
    String label,
    bool isRequired,
  ) {
    final options = (field['fieldOptions']?['options'] ?? 
                    field['options'] ?? []) as List<dynamic>;
    final currentValue = _values[name]?.toString();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompactLabel(label, isRequired, Icons.arrow_drop_down_circle_rounded),
          const SizedBox(height: 10),
          Container(
            height: 45,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkSurface.withOpacity(0.5),
                  AppTheme.darkSurface.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: currentValue != null 
                    ? AppTheme.primaryBlue.withOpacity(0.3)
                    : AppTheme.darkBorder.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentValue,
                isExpanded: true,
                isDense: true,
                icon: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.primaryBlue.withOpacity(0.7),
                    size: 20,
                  ),
                ),
                hint: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'اختر $label',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textMuted.withOpacity(0.4),
                    ),
                  ),
                ),
                selectedItemBuilder: (context) {
                  return options.map((option) {
                    final optionValue = option is Map 
                        ? option['value']?.toString() ?? option.toString()
                        : option.toString();
                    final optionLabel = option is Map 
                        ? option['label']?.toString() ?? optionValue
                        : optionValue;
                    
                    return Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: AppTheme.primaryBlue.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              optionLabel,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppTheme.textWhite,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                },
                dropdownColor: AppTheme.darkCard,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textWhite,
                ),
                items: options.map((option) {
                  final optionValue = option is Map 
                      ? option['value']?.toString() ?? option.toString()
                      : option.toString();
                  final optionLabel = option is Map 
                      ? option['label']?.toString() ?? optionValue
                      : optionValue;
                  
                  return DropdownMenuItem<String>(
                    value: optionValue,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        optionLabel,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    if (value == null) {
                      _values.remove(name);
                    } else {
                      _values[name] = value;
                    }
                  });
                  widget.onChanged(_values);
                  HapticFeedback.lightImpact();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticMultiSelectField(
    dynamic field,
    String name,
    String label,
    bool isRequired,
  ) {
    final options = (field['fieldOptions']?['options'] ?? 
                    field['options'] ?? []) as List<dynamic>;
    final selectedValues = (_values[name] as List<dynamic>?)
        ?.map((e) => e.toString()).toList() ?? [];
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompactLabel(label, isRequired, Icons.checklist_rounded),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final optionValue = option is Map 
                  ? option['value']?.toString() ?? option.toString()
                  : option.toString();
              final optionLabel = option is Map 
                  ? option['label']?.toString() ?? optionValue
                  : optionValue;
              final isSelected = selectedValues.contains(optionValue);
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    final newValues = List<String>.from(selectedValues);
                    if (isSelected) {
                      newValues.remove(optionValue);
                    } else {
                      newValues.add(optionValue);
                    }
                    
                    if (newValues.isEmpty) {
                      _values.remove(name);
                    } else {
                      _values[name] = newValues;
                    }
                  });
                  widget.onChanged(_values);
                  HapticFeedback.lightImpact();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? AppTheme.primaryGradient
                        : null,
                    color: !isSelected
                        ? AppTheme.darkSurface.withOpacity(0.5)
                        : null,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : AppTheme.darkBorder.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isSelected 
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          size: 14,
                          color: isSelected 
                              ? Colors.white
                              : AppTheme.textMuted.withOpacity(0.5),
                          key: ValueKey(isSelected),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        optionLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: isSelected 
                              ? Colors.white 
                              : AppTheme.textLight,
                          fontWeight: isSelected 
                              ? FontWeight.w600 
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticCheckbox(
    dynamic field,
    String name,
    String label,
  ) {
    final value = _values[name] ?? false;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _values[name] = !value;
        });
        widget.onChanged(_values);
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 40,
              height: 24,
              decoration: BoxDecoration(
                gradient: value ? AppTheme.primaryGradient : null,
                color: !value 
                    ? AppTheme.darkSurface.withOpacity(0.5)
                    : null,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: value 
                      ? Colors.transparent
                      : AppTheme.darkBorder.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: value
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    left: value ? 18 : 2,
                    top: 2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (field['description'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      field['description'],
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticRadioField(
    dynamic field,
    String name,
    String label,
    bool isRequired,
  ) {
    final options = (field['fieldOptions']?['options'] ?? 
                    field['options'] ?? []) as List<dynamic>;
    final currentValue = _values[name]?.toString();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompactLabel(label, isRequired, Icons.radio_button_checked_rounded),
          const SizedBox(height: 10),
          ...options.map((option) {
            final optionValue = option is Map 
                ? option['value']?.toString() ?? option.toString()
                : option.toString();
            final optionLabel = option is Map 
                ? option['label']?.toString() ?? optionValue
                : optionValue;
            final isSelected = currentValue == optionValue;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _values[name] = optionValue;
                });
                widget.onChanged(_values);
                HapticFeedback.lightImpact();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            AppTheme.primaryBlue.withOpacity(0.1),
                            AppTheme.primaryPurple.withOpacity(0.05),
                          ],
                        )
                      : null,
                  color: !isSelected
                      ? AppTheme.darkSurface.withOpacity(0.3)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryBlue.withOpacity(0.5)
                        : AppTheme.darkBorder.withOpacity(0.2),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isSelected 
                            ? AppTheme.primaryGradient 
                            : null,
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : AppTheme.darkBorder.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      optionLabel,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: isSelected 
                            ? FontWeight.w600 
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFuturisticRangeField(
    dynamic field,
    String name,
    String label,
  ) {
    final min = (field['validationRules']?['min'] ?? 
                 field['min'] ?? 0).toDouble();
    final max = (field['validationRules']?['max'] ?? 
                 field['max'] ?? 100).toDouble();
    final currentRange = _values[name] as RangeValues? ?? 
                         RangeValues(min, max);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompactLabel(label, false, Icons.tune_rounded),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRangeValue(currentRange.start, 'من'),
              Container(
                height: 1,
                width: 20,
                color: AppTheme.primaryBlue.withOpacity(0.3),
              ),
              _buildRangeValue(currentRange.end, 'إلى'),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              activeTrackColor: AppTheme.primaryBlue,
              inactiveTrackColor: AppTheme.primaryBlue.withOpacity(0.1),
              rangeThumbShape: _GlowingRangeSliderThumbShape(
                enabledThumbRadius: 10,
              ),
              overlayColor: AppTheme.primaryBlue.withOpacity(0.2),
              rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
            ),
            child: RangeSlider(
              values: currentRange,
              min: min,
              max: max,
              onChanged: (values) {
                setState(() {
                  _values[name] = values;
                });
                widget.onChanged(_values);
                HapticFeedback.selectionClick();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeValue(double value, String prefix) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.2),
            AppTheme.primaryPurple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            prefix,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value.toStringAsFixed(0),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticDateField(
    dynamic field,
    String name,
    String label,
    bool isRequired,
  ) {
    final selectedDate = _values[name] as DateTime?;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompactLabel(label, isRequired, Icons.event_rounded),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime.now(),
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
                      dialogBackgroundColor: AppTheme.darkCard,
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              
              if (date != null) {
                setState(() {
                  _values[name] = date;
                });
                widget.onChanged(_values);
              }
            },
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkSurface.withOpacity(0.5),
                    AppTheme.darkSurface.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedDate != null
                      ? AppTheme.primaryBlue.withOpacity(0.3)
                      : AppTheme.darkBorder.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: selectedDate != null
                          ? AppTheme.primaryBlue.withOpacity(0.7)
                          : AppTheme.textMuted.withOpacity(0.3),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedDate != null
                            ? _formatDate(selectedDate)
                            : 'اختر التاريخ',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: selectedDate != null
                              ? AppTheme.textWhite
                              : AppTheme.textMuted.withOpacity(0.4),
                          fontWeight: selectedDate != null
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (selectedDate != null)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _values.remove(name);
                          });
                          widget.onChanged(_values);
                          HapticFeedback.lightImpact();
                        },
                        child: Icon(
                          Icons.clear_rounded,
                          size: 16,
                          color: AppTheme.textMuted.withOpacity(0.5),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLabel(String label, bool isRequired, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue.withOpacity(0.15),
                AppTheme.primaryPurple.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 14,
            color: AppTheme.primaryBlue.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textLight,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppTheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// Custom Slider Thumb Shapes
class _GlowingSliderThumbShape extends SliderComponentShape {
  final double enabledThumbRadius;
  final double glowRadius;

  const _GlowingSliderThumbShape({
    required this.enabledThumbRadius,
    this.glowRadius = 20.0,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(enabledThumbRadius + glowRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // Glow effect
    final glowPaint = Paint()
      ..color = AppTheme.primaryBlue.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    
    canvas.drawCircle(center, enabledThumbRadius + 5, glowPaint);

    // Gradient thumb
    final paint = Paint()
      ..shader = AppTheme.primaryGradient.createShader(
        Rect.fromCircle(center: center, radius: enabledThumbRadius),
      );
    
    canvas.drawCircle(center, enabledThumbRadius, paint);

    // Inner white circle
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, enabledThumbRadius * 0.4, innerPaint);
  }
}

class _GlowingRangeSliderThumbShape extends RangeSliderThumbShape {
  final double enabledThumbRadius;

  const _GlowingRangeSliderThumbShape({
    required this.enabledThumbRadius,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(enabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool isOnTop = false,
    bool isPressed = false,
    required SliderThemeData sliderTheme,
    TextDirection? textDirection,
    Thumb? thumb,
  }) {
    final Canvas canvas = context.canvas;

    // Glow effect
    final glowPaint = Paint()
      ..color = AppTheme.primaryBlue.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    canvas.drawCircle(center, enabledThumbRadius + 3, glowPaint);

    // Gradient thumb
    final paint = Paint()
      ..shader = AppTheme.primaryGradient.createShader(
        Rect.fromCircle(center: center, radius: enabledThumbRadius),
      );
    
    canvas.drawCircle(center, enabledThumbRadius, paint);

    // Inner white circle
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, enabledThumbRadius * 0.3, innerPaint);
  }
}

// Shimmer Painter for empty state
class _CircularShimmerPainter extends CustomPainter {
  final Animation<double> animation;

  _CircularShimmerPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Create shimmer gradient
    final gradient = SweepGradient(
      colors: [
        Colors.transparent,
        AppTheme.primaryBlue.withOpacity(0.3),
        AppTheme.primaryPurple.withOpacity(0.3),
        Colors.transparent,
      ],
      stops: const [0.0, 0.25, 0.5, 1.0],
      transform: GradientRotation(animation.value * 2 * math.pi),
    );

    paint.shader = gradient.createShader(
      Rect.fromCircle(center: center, radius: radius),
    );

    canvas.drawCircle(center, radius - 5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}