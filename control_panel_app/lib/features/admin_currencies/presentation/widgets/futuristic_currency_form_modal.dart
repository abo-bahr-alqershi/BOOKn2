// lib/features/admin_currencies/presentation/widgets/futuristic_currency_form_modal.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/currency.dart';

class FuturisticCurrencyFormModal extends StatefulWidget {
  final Currency? currency;
  final Function(Currency) onSave;

  const FuturisticCurrencyFormModal({
    super.key,
    this.currency,
    required this.onSave,
  });

  @override
  State<FuturisticCurrencyFormModal> createState() =>
      _FuturisticCurrencyFormModalState();
}

class _FuturisticCurrencyFormModalState
    extends State<FuturisticCurrencyFormModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late TextEditingController _codeController;
  late TextEditingController _arabicCodeController;
  late TextEditingController _nameController;
  late TextEditingController _arabicNameController;
  late TextEditingController _exchangeRateController;

  bool _isDefault = false;
  final bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    _codeController = TextEditingController(text: widget.currency?.code ?? '');
    _arabicCodeController =
        TextEditingController(text: widget.currency?.arabicCode ?? '');
    _nameController = TextEditingController(text: widget.currency?.name ?? '');
    _arabicNameController =
        TextEditingController(text: widget.currency?.arabicName ?? '');
    _exchangeRateController = TextEditingController(
      text: widget.currency?.exchangeRate?.toString() ?? '',
    );
    _isDefault = widget.currency?.isDefault ?? false;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _codeController.dispose();
    _arabicCodeController.dispose();
    _nameController.dispose();
    _arabicNameController.dispose();
    _exchangeRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          )),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: AppTheme.darkCard.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(
                  color: AppTheme.darkBorder.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          left: 20,
                          right: 20,
                          bottom: bottomPadding + 100,
                        ),
                        physics: const BouncingScrollPhysics(),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              _buildSectionTitle(
                                  'معلومات العملة', CupertinoIcons.info_circle),
                              const SizedBox(height: 20),
                              _buildCodeFields(),
                              const SizedBox(height: 20),
                              _buildNameFields(),
                              const SizedBox(height: 24),
                              _buildSectionTitle('سعر الصرف',
                                  CupertinoIcons.arrow_2_circlepath),
                              const SizedBox(height: 20),
                              _buildExchangeRateField(),
                              const SizedBox(height: 24),
                              _buildDefaultSwitch(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildBottomActions(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkBorder.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryCyan, AppTheme.primaryBlue],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryCyan, AppTheme.primaryBlue],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.currency == null
                      ? CupertinoIcons.plus_circle_fill
                      : CupertinoIcons.pencil_circle_fill,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.currency == null
                          ? 'إضافة عملة جديدة'
                          : 'تعديل العملة',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.currency == null
                          ? 'أدخل معلومات العملة الجديدة'
                          : 'قم بتحديث معلومات العملة',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryCyan.withValues(alpha: 0.2),
                AppTheme.primaryBlue.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppTheme.primaryCyan,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCodeFields() {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            controller: _codeController,
            label: 'الرمز (لاتيني)',
            hint: 'USD',
            icon: CupertinoIcons.textformat,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال رمز العملة';
              }
              if (value.length != 3) {
                return 'الرمز يجب أن يكون 3 أحرف';
              }
              return null;
            },
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Z]')),
              LengthLimitingTextInputFormatter(3),
            ],
            textCapitalization: TextCapitalization.characters,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTextField(
            controller: _arabicCodeController,
            label: 'الرمز (عربي)',
            hint: 'دولار',
            icon: CupertinoIcons.text_alignright,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال الرمز العربي';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNameFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'الاسم (انجليزي)',
          hint: 'US Dollar',
          icon: CupertinoIcons.textformat_abc,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'الرجاء إدخال اسم العملة بالإنجليزية';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _arabicNameController,
          label: 'الاسم (عربي)',
          hint: 'الدولار الأمريكي',
          icon: CupertinoIcons.text_alignright,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'الرجاء إدخال اسم العملة بالعربية';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildExchangeRateField() {
    return _buildTextField(
      controller: _exchangeRateController,
      label: 'سعر الصرف',
      hint: '1.0000',
      icon: CupertinoIcons.arrow_2_circlepath,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,4}')),
      ],
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final rate = double.tryParse(value);
          if (rate == null || rate <= 0) {
            return 'الرجاء إدخال سعر صرف صحيح';
          }
        }
        return null;
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textWhite,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textMuted.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: AppTheme.inputBackground.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.inputBorder.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.inputBorder.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.primaryCyan,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.error,
              ),
            ),
            prefixIcon: Icon(
              icon,
              color: AppTheme.textMuted,
              size: 20,
            ),
          ),
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
        ),
      ],
    );
  }

  Widget _buildDefaultSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.success.withValues(alpha: 0.05),
            AppTheme.neonGreen.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.success.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isDefault
                      ? AppTheme.success.withValues(alpha: 0.1)
                      : AppTheme.textMuted.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _isDefault ? CupertinoIcons.star_fill : CupertinoIcons.star,
                  color: _isDefault ? AppTheme.success : AppTheme.textMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'عملة افتراضية',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isDefault
                        ? 'هذه هي العملة الأساسية'
                        : 'تعيين كعملة أساسية',
                    style: AppTextStyles.caption.copyWith(
                      color: _isDefault ? AppTheme.success : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          CupertinoSwitch(
            value: _isDefault,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              setState(() => _isDefault = value);
            },
            activeTrackColor: AppTheme.success,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorder.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.darkCard.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.darkBorder.withValues(alpha: 0.3),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
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
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryCyan, AppTheme.primaryBlue],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryCyan.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _handleSave,
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  widget.currency == null
                                      ? CupertinoIcons.plus_circle_fill
                                      : CupertinoIcons.checkmark_circle_fill,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.currency == null
                                      ? 'إضافة'
                                      : 'حفظ التغييرات',
                                  style: AppTextStyles.buttonMedium.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();

      final currency = Currency(
        code: _codeController.text.trim(),
        arabicCode: _arabicCodeController.text.trim(),
        name: _nameController.text.trim(),
        arabicName: _arabicNameController.text.trim(),
        isDefault: _isDefault,
        exchangeRate: _exchangeRateController.text.isNotEmpty
            ? double.tryParse(_exchangeRateController.text)
            : null,
        lastUpdated: DateTime.now(),
      );

      widget.onSave(currency);
    }
  }
}
