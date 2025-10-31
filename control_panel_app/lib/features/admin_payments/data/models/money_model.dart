import '../../domain/entities/payment.dart';

class MoneyModel extends Money {
  const MoneyModel({
    required super.amount,
    required super.currency,
    required super.formattedAmount,
  });

  factory MoneyModel.fromJson(dynamic json) {
    // Handle null case
    if (json == null) {
      return MoneyModel.zero('YER');
    }

    // Case 1: json is a number (double or int) - direct amount value
    if (json is num) {
      return MoneyModel(
        amount: json.toDouble(),
        currency: 'YER', // default currency
        formattedAmount: 'YER ${json.toStringAsFixed(2)}',
      );
    }

    // Case 2: json is a Map - Money object with nested structure
    if (json is Map<String, dynamic>) {
      // Check if it's a flat structure {amount: x, currency: y}
      if (json.containsKey('amount') && json['amount'] is num) {
        final amount = (json['amount'] ?? 0).toDouble();
        final currency = json['currency']?.toString().toUpperCase() ?? 'YER';
        
        return MoneyModel(
          amount: amount,
          currency: currency,
          formattedAmount:
              json['formattedAmount'] ?? '$currency ${amount.toStringAsFixed(2)}',
        );
      }
      
      // Check if it's EF Core owned entity structure {amount: {amount: x, currency: y}}
      // This shouldn't happen but we handle it for safety
      if (json.containsKey('amount') && json['amount'] is Map) {
        return MoneyModel.fromJson(json['amount']);
      }
    }

    // Fallback: return zero money
    return MoneyModel.zero('YER');
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      'formattedAmount': formattedAmount,
    };
  }

  factory MoneyModel.fromEntity(Money entity) {
    return MoneyModel(
      amount: entity.amount,
      currency: entity.currency,
      formattedAmount: entity.formattedAmount,
    );
  }

  factory MoneyModel.zero(String currency) {
    return MoneyModel(
      amount: 0,
      currency: currency,
      formattedAmount: '$currency 0.00',
    );
  }
}
