import 'package:bookn_cp_app/features/admin_services/domain/entities/service_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/service.dart';
import '../../domain/entities/money.dart';
import '../../domain/entities/pricing_model.dart';
import 'service_icon_picker.dart';

/// 📝 Service Form Dialog
class ServiceFormDialog extends StatefulWidget {
  final Service? service;
  final String? propertyId;
  final Function(Map<String, dynamic>) onSubmit;

  const ServiceFormDialog({
    super.key,
    this.service,
    this.propertyId,
    required this.onSubmit,
  });

  @override
  State<ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends State<ServiceFormDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedIcon = 'room_service';
  String _selectedCurrency = 'SAR';
  PricingModel _selectedPricingModel = PricingModel.perBooking;
  String? _selectedPropertyId;
  bool _isFree = false;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeForm();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  void _initializeForm() {
    if (widget.service != null) {
      _nameController.text = widget.service!.name;
      _amountController.text = widget.service!.price.amount.toString();
      _selectedIcon = widget.service!.icon;
      _selectedCurrency = widget.service!.price.currency;
      _selectedPricingModel = widget.service!.pricingModel;
      _selectedPropertyId = widget.service!.propertyId;
      if (widget.service is ServiceDetails) {
        _descriptionController.text =
            (widget.service as ServiceDetails).description ?? '';
      }
      _isFree = (double.tryParse(_amountController.text) ?? 0) == 0;
    } else {
      _selectedPropertyId = widget.propertyId;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _showIconPicker() {
    showDialog(
      fullscreenDialog: true,
      context: context,
      builder: (context) => ServiceIconPicker(
        selectedIcon: _selectedIcon,
        onIconSelected: (icon) {
          setState(() => _selectedIcon = icon);
        },
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      setState(() => _isSubmitting = true);

      final data = {
        'propertyId': _selectedPropertyId,
        'name': _nameController.text,
        'price': Money(
          amount: double.tryParse(_amountController.text) ?? 0,
          currency: _selectedCurrency,
        ),
        'pricingModel': _selectedPricingModel,
        'icon': _selectedIcon,
        if (_descriptionController.text.trim().isNotEmpty)
          'description': _descriptionController.text.trim(),
      };

      widget.onSubmit(data);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkCard.withOpacity(0.95),
                AppTheme.darkCard.withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildNameField(),
                            const SizedBox(height: 20),
                            _buildIconSelector(),
                            const SizedBox(height: 20),
                            _buildPriceSection(),
                            const SizedBox(height: 20),
                            _buildPricingModelSelector(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildFooter(),
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
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.room_service_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            widget.service != null ? 'تعديل الخدمة' : 'إضافة خدمة جديدة',
            style: AppTextStyles.heading2.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            color: AppTheme.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
      decoration: InputDecoration(
        labelText: 'اسم الخدمة',
        labelStyle: AppTextStyles.bodySmall.copyWith(color: AppTheme.textMuted),
        filled: true,
        fillColor: AppTheme.darkSurface.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.5),
            width: 1,
          ),
        ),
        prefixIcon: Icon(
          Icons.label_rounded,
          color: AppTheme.primaryBlue.withOpacity(0.7),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'الرجاء إدخال اسم الخدمة';
        }
        return null;
      },
    );
  }

  Widget _buildIconSelector() {
    return GestureDetector(
      onTap: _showIconPicker,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.darkBorder.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.2),
                    AppTheme.primaryPurple.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                IconData(
                  Icons.room_service.codePoint,
                  fontFamily: Icons.room_service.fontFamily,
                ),
                color: AppTheme.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أيقونة الخدمة',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textWhite,
                    ),
                  ),
                  Text(
                    'Icons.$_selectedIcon',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textMuted,
                      fontFamily: 'monospace',
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
    );
  }

  Widget _buildPriceSection() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
            decoration: InputDecoration(
              labelText: 'السعر',
              labelStyle:
                  AppTextStyles.bodySmall.copyWith(color: AppTheme.textMuted),
              filled: true,
              fillColor: AppTheme.darkSurface.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.darkBorder.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.success.withOpacity(0.5),
                  width: 1,
                ),
              ),
              prefixIcon: Icon(
                Icons.attach_money_rounded,
                color: AppTheme.success.withOpacity(0.7),
              ),
            ),
            validator: (value) {
              if (_isFree) return null;
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال السعر';
              }
              final parsed = double.tryParse(value);
              if (parsed == null || parsed < 0) {
                return 'السعر غير صحيح';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedCurrency,
            decoration: InputDecoration(
              labelText: 'العملة',
              labelStyle:
                  AppTextStyles.bodySmall.copyWith(color: AppTheme.textMuted),
              filled: true,
              fillColor: AppTheme.darkSurface.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            dropdownColor: AppTheme.darkCard,
            style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
            items: ['SAR', 'USD', 'EUR', 'YER'].map((currency) {
              return DropdownMenuItem(
                value: currency,
                child: Text(currency),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedCurrency = value!);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPricingModelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نموذج التسعير',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textLight,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PricingModel.values.map((model) {
            final isSelected = _selectedPricingModel == model;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedPricingModel = model);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.primaryGradient : null,
                  color:
                      isSelected ? null : AppTheme.darkSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryBlue.withOpacity(0.5)
                        : AppTheme.darkBorder.withOpacity(0.2),
                    width: isSelected ? 1.5 : 0.5,
                  ),
                ),
                child: Text(
                  model.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? Colors.white : AppTheme.textMuted,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 4,
      style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
      decoration: InputDecoration(
        labelText: 'الوصف',
        labelStyle: AppTextStyles.bodySmall.copyWith(color: AppTheme.textMuted),
        filled: true,
        fillColor: AppTheme.darkSurface.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(
          Icons.description_rounded,
          color: AppTheme.primaryBlue.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed:
                  _isSubmitting ? null : () => Navigator.of(context).pop(),
              child: Text(
                'إلغاء',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.service != null ? 'تحديث' : 'إضافة',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: Colors.white,
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
}
