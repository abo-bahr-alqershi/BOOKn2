import '../../domain/entities/money.dart';

/// 💰 Model للمبالغ المالية
class MoneyModel extends Money {
  const MoneyModel({
    required super.amount,
    required super.currency,
    super.formattedAmount,
  });

  factory MoneyModel.fromJson(Map<String, dynamic> json) {
    return MoneyModel(
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] ?? 'SAR',
      formattedAmount: json['formattedAmount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      if (formattedAmount != null) 'formattedAmount': formattedAmount,
    };
  }

  Money toEntity() => Money(
        amount: amount,
        currency: currency,
        formattedAmount: formattedAmount,
      );
}