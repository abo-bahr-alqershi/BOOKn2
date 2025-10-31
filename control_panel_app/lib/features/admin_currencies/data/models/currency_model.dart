import '../../domain/entities/currency.dart';

class CurrencyModel extends Currency {
  const CurrencyModel({
    required String code,
    required String arabicCode,
    required String name,
    required String arabicName,
    required bool isDefault,
    double? exchangeRate,
    DateTime? lastUpdated,
  }) : super(
          code: code,
          arabicCode: arabicCode,
          name: name,
          arabicName: arabicName,
          isDefault: isDefault,
          exchangeRate: exchangeRate,
          lastUpdated: lastUpdated,
        );

  factory CurrencyModel.fromJson(Map<String, dynamic> json) {
    return CurrencyModel(
      code: json['code'] ?? '',
      arabicCode: json['arabicCode'] ?? '',
      name: json['name'] ?? '',
      arabicName: json['arabicName'] ?? '',
      isDefault: json['isDefault'] ?? false,
      exchangeRate: json['exchangeRate']?.toDouble(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'arabicCode': arabicCode,
      'name': name,
      'arabicName': arabicName,
      'isDefault': isDefault,
      'exchangeRate': exchangeRate,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory CurrencyModel.fromEntity(Currency currency) {
    return CurrencyModel(
      code: currency.code,
      arabicCode: currency.arabicCode,
      name: currency.name,
      arabicName: currency.arabicName,
      isDefault: currency.isDefault,
      exchangeRate: currency.exchangeRate,
      lastUpdated: currency.lastUpdated,
    );
  }
}