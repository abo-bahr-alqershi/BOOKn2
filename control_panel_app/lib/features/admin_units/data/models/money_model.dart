import '../../domain/entities/money.dart';

class MoneyModel extends Money {
  const MoneyModel({
    required double amount,
    required String currency,
    String? formattedAmount,
  }) : super(
          amount: amount,
          currency: currency,
          formattedAmount: formattedAmount,
        );

  factory MoneyModel.fromJson(Map<String, dynamic> json) {
    return MoneyModel(
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      formattedAmount: json['formattedAmount'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      if (formattedAmount != null) 'formattedAmount': formattedAmount,
    };
  }

  factory MoneyModel.fromEntity(Money entity) {
    return MoneyModel(
      amount: entity.amount,
      currency: entity.currency,
      formattedAmount: entity.formattedAmount,
    );
  }
}