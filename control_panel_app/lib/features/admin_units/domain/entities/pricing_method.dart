enum PricingMethod {
  hourly('Hourly', 'بالساعة', '⏰'),
  daily('Daily', 'يومي', '📅'),
  weekly('Weekly', 'أسبوعي', '📆'),
  monthly('Monthly', 'شهري', '🗓️');

  final String value;
  final String arabicLabel;
  final String icon;

  const PricingMethod(this.value, this.arabicLabel, this.icon);

  static PricingMethod fromString(String value) {
    return PricingMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => PricingMethod.daily,
    );
  }
}