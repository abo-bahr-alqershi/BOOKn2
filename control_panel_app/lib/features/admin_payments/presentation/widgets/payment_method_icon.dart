import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/enums/payment_method_enum.dart';

class PaymentMethodIcon extends StatelessWidget {
  final PaymentMethod method;
  final double size;
  final bool showLabel;
  final Color? color;

  const PaymentMethodIcon({
    super.key,
    required this.method,
    this.size = 32,
    this.showLabel = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getMethodColor().withValues(alpha: 0.2),
                _getMethodColor().withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(size / 4),
            border: Border.all(
              color: _getMethodColor().withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              _getMethodIcon(),
              color: color ?? _getMethodColor(),
              size: size * 0.6,
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            _getMethodLabel(),
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ],
    );
  }

  IconData _getMethodIcon() {
    switch (method) {
      case PaymentMethod.creditCard:
        return CupertinoIcons.creditcard_fill;
      case PaymentMethod.jwaliWallet:
        return Icons.account_balance_wallet;
      case PaymentMethod.cashWallet:
        return Icons.account_balance_wallet;
      case PaymentMethod.oneCashWallet:
        return Icons.account_balance_wallet;
      case PaymentMethod.floskWallet:
        return Icons.account_balance_wallet;
      case PaymentMethod.jaibWallet:
        return Icons.account_balance_wallet;
      case PaymentMethod.cash:
        return CupertinoIcons.money_dollar_circle_fill;
      case PaymentMethod.paypal:
        return Icons.paypal;
      // Fallback
      default:
        return Icons.payment;
    }
  }

  Color _getMethodColor() {
    switch (method) {
      case PaymentMethod.creditCard:
        return AppTheme.primaryBlue;
      case PaymentMethod.jwaliWallet:
      case PaymentMethod.cashWallet:
      case PaymentMethod.oneCashWallet:
      case PaymentMethod.floskWallet:
      case PaymentMethod.jaibWallet:
        return AppTheme.primaryViolet;
      case PaymentMethod.cash:
        return AppTheme.success;
      case PaymentMethod.paypal:
        return const Color(0xFF00457C);
      default:
        return AppTheme.textMuted;
    }
  }

  String _getMethodLabel() {
    switch (method) {
      case PaymentMethod.creditCard:
        return 'بطاقة ائتمان';
      case PaymentMethod.jwaliWallet:
        return 'محفظة جوالي';
      case PaymentMethod.cashWallet:
        return 'كاش محفظة';
      case PaymentMethod.oneCashWallet:
        return 'ون كاش';
      case PaymentMethod.floskWallet:
        return 'فلوسك';
      case PaymentMethod.jaibWallet:
        return 'جيب';
      case PaymentMethod.cash:
        return 'نقدي';
      case PaymentMethod.paypal:
        return 'PayPal';
      default:
        return 'أخرى';
    }
  }
}
