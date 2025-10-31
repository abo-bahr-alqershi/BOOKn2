// lib/features/admin_units/presentation/widgets/pricing_form_widget.dart

import 'package:bookn_cp_app/core/theme/app_theme.dart';
import 'package:bookn_cp_app/core/usecases/usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:bookn_cp_app/core/theme/app_text_styles.dart';
import 'package:bookn_cp_app/injection_container.dart';
import 'package:bookn_cp_app/services/local_storage_service.dart';
import 'package:bookn_cp_app/features/admin_currencies/domain/usecases/get_currencies_usecase.dart'
    as ac_uc1;
import 'package:bookn_cp_app/features/admin_currencies/domain/entities/currency.dart'
    as ac_entity;
import '../../domain/entities/money.dart';
import '../../domain/entities/pricing_method.dart';

class PricingFormWidget extends StatefulWidget {
  final Function(Money, PricingMethod) onPricingChanged;
  final Money? initialBasePrice;
  final PricingMethod? initialPricingMethod;

  const PricingFormWidget({
    super.key,
    required this.onPricingChanged,
    this.initialBasePrice,
    this.initialPricingMethod,
  });

  @override
  State<PricingFormWidget> createState() => _PricingFormWidgetState();
}

class _PricingFormWidgetState extends State<PricingFormWidget>
    with SingleTickerProviderStateMixin {
  late TextEditingController _amountController;
  late String _selectedCurrency;
  late PricingMethod _selectedMethod;
  bool _isAdmin = false;
  List<String> _currencyOptions = const ['YER'];
  bool _isLoadingCurrencies = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialBasePrice?.amount.toString() ?? '',
    );
    final localStorage = sl<LocalStorageService>();
    final accountRole = localStorage.getAccountRole().toLowerCase();
    _isAdmin = accountRole == 'admin';
    // Default currency resolution order: initial -> property -> app selected -> YER
    final propertyCurrency = localStorage.getPropertyCurrency();
    final appSelectedCurrency = localStorage.getSelectedCurrency();
    _selectedCurrency = widget.initialBasePrice?.currency ??
        (propertyCurrency.isNotEmpty
            ? propertyCurrency
            : (appSelectedCurrency.isNotEmpty ? appSelectedCurrency : 'YER'));
    if (_isAdmin) {
      _loadCurrencies();
    } else {
      _currencyOptions = [_selectedCurrency];
    }
    _selectedMethod = widget.initialPricingMethod ?? PricingMethod.daily;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updatePricing() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final money = Money(
      amount: amount,
      currency: _selectedCurrency,
    );
    widget.onPricingChanged(money, _selectedMethod);
  }

  Future<void> _loadCurrencies() async {
    try {
      setState(() => _isLoadingCurrencies = true);
      final result = await sl<ac_uc1.GetCurrenciesUseCase>()(NoParams());
      result.fold((_) {
        setState(() {
          _currencyOptions = [_selectedCurrency];
          _isLoadingCurrencies = false;
        });
      }, (list) {
        setState(() {
          _currencyOptions = (list).map((c) => c.code).toList();
          if (!_currencyOptions.contains(_selectedCurrency) &&
              _currencyOptions.isNotEmpty) {
            _selectedCurrency = _currencyOptions.first;
          }
          _isLoadingCurrencies = false;
        });
      });
    } catch (_) {
      setState(() {
        _currencyOptions = [_selectedCurrency];
        _isLoadingCurrencies = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.success.withOpacity(0.1),
              AppTheme.success.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.success.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.success.withOpacity(0.1),
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
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.success,
                              AppTheme.success.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.attach_money,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'التسعير',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildAmountField(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCurrencySelector(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _buildPricingMethodSelector(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المبلغ',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.darkSurface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.darkBorder.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.success,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              prefixIcon: Icon(
                Icons.payments,
                size: 20,
                color: AppTheme.success.withOpacity(0.7),
              ),
            ),
            onChanged: (_) => _updatePricing(),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'العملة',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (_isAdmin)
          Container(
            decoration: BoxDecoration(
              color: AppTheme.darkSurface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.darkBorder.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedCurrency,
              dropdownColor: AppTheme.darkCard,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textWhite,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                suffixIcon: _isLoadingCurrencies
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      )
                    : null,
              ),
              items: _currencyOptions.map((currency) {
                return DropdownMenuItem(
                  value: currency,
                  child: Text(currency),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedCurrency = value);
                _updatePricing();
              },
            ),
          )
        else
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
              children: [
                Icon(Icons.lock, size: 16, color: AppTheme.textMuted),
                const SizedBox(width: 8),
                Text(
                  _selectedCurrency,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textWhite,
                  ),
                ),
                const Spacer(),
                Text(
                  'عملة المالك',
                  style:
                      AppTextStyles.caption.copyWith(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPricingMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'طريقة التسعير',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: PricingMethod.values.map((method) {
            final isSelected = _selectedMethod == method;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedMethod = method);
                _updatePricing();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.primaryGradient : null,
                  color:
                      isSelected ? null : AppTheme.darkSurface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryBlue.withOpacity(0.5)
                        : AppTheme.darkBorder.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      method.icon,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      method.arabicLabel,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected ? Colors.white : AppTheme.textMuted,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
