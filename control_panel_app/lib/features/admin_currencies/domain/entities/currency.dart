import 'package:equatable/equatable.dart';

class Currency extends Equatable {
  final String code;
  final String arabicCode;
  final String name;
  final String arabicName;
  final bool isDefault;
  final double? exchangeRate;
  final DateTime? lastUpdated;

  const Currency({
    required this.code,
    required this.arabicCode,
    required this.name,
    required this.arabicName,
    required this.isDefault,
    this.exchangeRate,
    this.lastUpdated,
  });

  Currency copyWith({
    String? code,
    String? arabicCode,
    String? name,
    String? arabicName,
    bool? isDefault,
    double? exchangeRate,
    DateTime? lastUpdated,
  }) {
    return Currency(
      code: code ?? this.code,
      arabicCode: arabicCode ?? this.arabicCode,
      name: name ?? this.name,
      arabicName: arabicName ?? this.arabicName,
      isDefault: isDefault ?? this.isDefault,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        code,
        arabicCode,
        name,
        arabicName,
        isDefault,
        exchangeRate,
        lastUpdated,
      ];
}