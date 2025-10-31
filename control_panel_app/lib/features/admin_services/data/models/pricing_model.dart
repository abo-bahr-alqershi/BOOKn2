/// 📊 نماذج التسعير
enum PricingModel {
  perBooking('PerBooking', 'لكل حجز'),
  perDay('PerDay', 'لكل يوم'),
  perPerson('PerPerson', 'لكل شخص'),
  perUnit('PerUnit', 'لكل وحدة'),
  perHour('PerHour', 'لكل ساعة'),
  fixed('Fixed', 'سعر ثابت');

  final String value;
  final String label;

  const PricingModel(this.value, this.label);

  /// يحاول مطابقة قيمة التطبيق أولاً ثم يدعم قيم الباك اند (Fixed/PerPerson/PerNight)
  static PricingModel fromValue(String value) {
    final normalized = value.trim();
    // Direct app values
    for (final model in PricingModel.values) {
      if (model.value == normalized) return model;
    }
    // Backend enum values mapping
    switch (normalized) {
      case 'Fixed':
        return PricingModel.fixed;
      case 'PerPerson':
        return PricingModel.perPerson;
      case 'PerNight':
        // أقرب تمثيل لدينا هو لكل يوم
        return PricingModel.perDay;
      default:
        return PricingModel.perBooking;
    }
  }
}