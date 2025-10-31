class Currency {
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
}

