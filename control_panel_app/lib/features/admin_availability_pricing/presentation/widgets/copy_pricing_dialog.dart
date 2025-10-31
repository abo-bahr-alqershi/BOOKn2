// lib/features/admin_availability_pricing/presentation/widgets/copy_pricing_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/pricing/pricing_bloc.dart';

class CopyPricingDialog extends StatefulWidget {
  final String unitId;
  final DateTime? initialSourceStart;
  final DateTime? initialSourceEnd;
  final DateTime? initialTargetStart;

  const CopyPricingDialog(
      {super.key,
      required this.unitId,
      this.initialSourceStart,
      this.initialSourceEnd,
      this.initialTargetStart});

  static Future<void> show(
    BuildContext context, {
    required String unitId,
    DateTime? initialSourceStart,
    DateTime? initialSourceEnd,
    DateTime? initialTargetStart,
  }) async {
    return showDialog(
      fullscreenDialog: true,
      context: context,
      barrierDismissible: false,
      barrierColor: AppTheme.overlayDark,
      builder: (context) => CopyPricingDialog(
        unitId: unitId,
        initialSourceStart: initialSourceStart,
        initialSourceEnd: initialSourceEnd,
        initialTargetStart: initialTargetStart,
      ),
    );
  }

  @override
  State<CopyPricingDialog> createState() => _CopyPricingDialogState();
}

class _CopyPricingDialogState extends State<CopyPricingDialog> {
  DateTime? _sourceStart;
  DateTime? _sourceEnd;
  late DateTime _targetStart;
  int _repeatCount = 1;
  String _adjustmentType = 'none'; // none, fixed, percentage
  double _adjustmentValue = 0;
  bool _overwrite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _sourceStart = widget.initialSourceStart;
    _sourceEnd = widget.initialSourceEnd ?? widget.initialSourceStart;
    _targetStart = widget.initialTargetStart ??
        widget.initialSourceStart ??
        DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width.clamp(520.0, 900.0);
    final maxH = size.height * 0.9;

    return Dialog(
      insetPadding: const EdgeInsets.all(10),
      backgroundColor: Colors.transparent,
      child: Container(
        width: width,
        constraints:
            BoxConstraints(maxHeight: maxH, maxWidth: size.width * 0.95),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            AppTheme.darkCard.withOpacity(0.95),
            AppTheme.darkCard.withOpacity(0.85),
          ]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppTheme.primaryPurple.withOpacity(0.25), width: 1),
          boxShadow: [
            BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.12),
                blurRadius: 24,
                spreadRadius: 4),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الفترة المصدر',
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: AppTheme.textWhite,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                              child: _dateField('من تاريخ', _sourceStart,
                                  () => _pickDate(true))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _dateField('إلى تاريخ', _sourceEnd,
                                  () => _pickDate(false, source: true))),
                        ]),
                        const SizedBox(height: 16),
                        Text('الفترة الهدف',
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: AppTheme.textWhite,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        _dateField('تاريخ البداية', _targetStart,
                            () => _pickDate(false)),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(
                              child: _numberField(
                                  label: 'عدد التكرار',
                                  initial: _repeatCount.toString(),
                                  onChanged: (v) => setState(() =>
                                      _repeatCount = int.tryParse(v) ?? 1))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _dropdownField(
                                  label: 'نوع التعديل',
                                  value: _adjustmentType,
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'none', child: Text('بدون')),
                                    DropdownMenuItem(
                                        value: 'fixed',
                                        child: Text('قيمة ثابتة')),
                                    DropdownMenuItem(
                                        value: 'percentage',
                                        child: Text('نسبة مئوية')),
                                  ],
                                  onChanged: (val) => setState(
                                      () => _adjustmentType = val ?? 'none'))),
                        ]),
                        const SizedBox(height: 12),
                        _numberField(
                            label: 'قيمة التعديل',
                            initial: _adjustmentValue.toString(),
                            onChanged: (v) => setState(() =>
                                _adjustmentValue = double.tryParse(v) ?? 0)),
                        const SizedBox(height: 12),
                        Row(children: [
                          Switch(
                              value: _overwrite,
                              onChanged: (v) => setState(() => _overwrite = v),
                              activeThumbColor: AppTheme.warning),
                          const SizedBox(width: 8),
                          Text('استبدال البيانات الموجودة',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppTheme.textWhite)),
                        ]),
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
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppTheme.primaryPurple.withOpacity(0.1),
          AppTheme.primaryBlue.withOpacity(0.05),
        ]),
        border: Border(
            bottom: BorderSide(
                color: AppTheme.darkBorder.withOpacity(0.3), width: 1)),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.content_copy_rounded,
              color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Text('نسخ الإعدادات',
            style: AppTextStyles.heading3.copyWith(
                color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close_rounded, color: AppTheme.textMuted)),
      ]),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: AppTheme.darkBorder.withOpacity(0.3), width: 1))),
      child: Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: _isLoading ? null : () => Navigator.of(context).pop(),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.darkSurface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.darkBorder.withOpacity(0.3), width: 1),
              ),
              child: Center(
                  child: Text('إلغاء',
                      style: AppTextStyles.buttonMedium
                          .copyWith(color: AppTheme.textMuted))),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _isLoading ? null : _submit,
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('نسخ الإعدادات',
                        style: AppTextStyles.buttonMedium.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _pickDate(bool isStart, {bool source = false}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (source ? (_sourceStart ?? now) : _targetStart)
        : (source ? (_sourceEnd ?? _sourceStart ?? now) : _targetStart);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppTheme.primaryBlue,
            onPrimary: Colors.white,
            surface: AppTheme.darkCard,
            onSurface: AppTheme.textWhite,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (source) {
          if (isStart) {
            _sourceStart = picked;
            if (_sourceEnd != null && _sourceEnd!.isBefore(_sourceStart!)) {
              _sourceEnd = _sourceStart;
            }
          } else {
            _sourceEnd = picked;
            if (_sourceStart != null && _sourceEnd!.isBefore(_sourceStart!)) {
              _sourceStart = _sourceEnd;
            }
          }
        } else {
          _targetStart = picked;
        }
      });
    }
  }

  Widget _dateField(String label, DateTime? value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            AppTheme.darkSurface.withOpacity(0.6),
            AppTheme.darkSurface.withOpacity(0.4)
          ]),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppTheme.darkBorder.withOpacity(0.3), width: 1),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded,
              size: 18, color: AppTheme.primaryPurple),
          const SizedBox(width: 8),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: AppTextStyles.caption
                      .copyWith(color: AppTheme.textMuted)),
              Text(
                value != null
                    ? DateFormat('dd/MM/yyyy').format(value)
                    : 'اختر التاريخ',
                style: AppTextStyles.bodySmall.copyWith(
                    color:
                        value != null ? AppTheme.textWhite : AppTheme.textMuted,
                    fontWeight: FontWeight.w600),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _numberField(
      {required String label,
      required String initial,
      required void Function(String) onChanged}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextFormField(
        initialValue: initial,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true, signed: false),
        style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppTheme.darkSurface.withOpacity(0.5),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppTheme.darkBorder.withOpacity(0.3))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppTheme.darkBorder.withOpacity(0.3))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppTheme.primaryPurple.withOpacity(0.5))),
        ),
        onChanged: onChanged,
      ),
    ]);
  }

  Widget _dropdownField(
      {required String label,
      required String value,
      required List<DropdownMenuItem<String>> items,
      required ValueChanged<String?> onChanged}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textWhite, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        initialValue: value,
        dropdownColor: AppTheme.darkCard,
        style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textWhite),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppTheme.darkSurface.withOpacity(0.5),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppTheme.darkBorder.withOpacity(0.3))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppTheme.darkBorder.withOpacity(0.3))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppTheme.primaryPurple.withOpacity(0.5))),
        ),
        items: items,
        onChanged: onChanged,
      ),
    ]);
  }

  void _submit() {
    if (_sourceStart == null || _sourceEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يرجى تحديد الفترات المطلوبة'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    context.read<PricingBloc>().add(
          CopyPricing(
            unitId: widget.unitId,
            sourceStartDate: _sourceStart!,
            sourceEndDate: _sourceEnd!,
            targetStartDate: _targetStart,
            repeatCount: _repeatCount,
            adjustmentType: _adjustmentType,
            adjustmentValue: _adjustmentValue,
            overwriteExisting: _overwrite,
          ),
        );
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم نسخ الإعدادات بنجاح'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });
  }
}
