import 'package:equatable/equatable.dart';

/// 💰 Entity للمبالغ المالية
class Money extends Equatable {
  final double amount;
  final String currency;
  final String? formattedAmount;

  const Money({
    required this.amount,
    required this.currency,
    this.formattedAmount,
  });

  @override
  List<Object?> get props => [amount, currency, formattedAmount];
}