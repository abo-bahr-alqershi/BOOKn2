import 'package:equatable/equatable.dart';

class Money extends Equatable {
  final double amount;
  final String currency;
  final String? formattedAmount;

  const Money({
    required this.amount,
    required this.currency,
    this.formattedAmount,
  });

  String get displayAmount {
    if (formattedAmount != null) return formattedAmount!;
    
    // Format based on currency
    switch (currency) {
      case 'YER':
        return '${amount.toStringAsFixed(0)} ﷼';
      case 'USD':
        return '\$${amount.toStringAsFixed(2)}';
      case 'EUR':
        return '€${amount.toStringAsFixed(2)}';
      default:
        return '${amount.toStringAsFixed(2)} $currency';
    }
  }

  Money copyWith({
    double? amount,
    String? currency,
    String? formattedAmount,
  }) {
    return Money(
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      formattedAmount: formattedAmount ?? this.formattedAmount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      if (formattedAmount != null) 'formattedAmount': formattedAmount,
    };
  }

  @override
  List<Object?> get props => [amount, currency, formattedAmount];
}