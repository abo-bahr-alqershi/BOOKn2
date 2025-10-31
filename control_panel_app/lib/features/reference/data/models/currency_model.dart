import '../../domain/entities/currency.dart' as domain;

class CurrencyModel {
  final String code;
  final String arabicCode;
  final String name;
  final String arabicName;
  final bool isDefault;
  final double? exchangeRate;
  final DateTime? lastUpdated;

  const CurrencyModel({
    required this.code,
    required this.arabicCode,
    required this.name,
    required this.arabicName,
    required this.isDefault,
    this.exchangeRate,
    this.lastUpdated,
  });

  factory CurrencyModel.fromJson(Map<String, dynamic> json) {
    return CurrencyModel(
      code: json['code'] ?? '',
      arabicCode: json['arabicCode'] ?? '',
      name: json['name'] ?? '',
      arabicName: json['arabicName'] ?? '',
      isDefault: json['isDefault'] ?? false,
      exchangeRate: (json['exchangeRate'] as num?)?.toDouble(),
      lastUpdated: json['lastUpdated'] != null ? DateTime.tryParse(json['lastUpdated']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'arabicCode': arabicCode,
        'name': name,
        'arabicName': arabicName,
        'isDefault': isDefault,
        'exchangeRate': exchangeRate,
        'lastUpdated': lastUpdated?.toIso8601String(),
      };

  domain.Currency toEntity() => domain.Currency(
        code: code,
        arabicCode: arabicCode,
        name: name,
        arabicName: arabicName,
        isDefault: isDefault,
        exchangeRate: exchangeRate,
        lastUpdated: lastUpdated,
      );
}

