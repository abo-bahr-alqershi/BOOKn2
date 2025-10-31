import '../../domain/entities/pricing_method.dart';

class PricingMethodModel {
  static PricingMethod fromString(String value) {
    return PricingMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => PricingMethod.daily,
    );
  }
  
  static String stringValueOf(PricingMethod method) {
    return method.value;
  }
  
  static Map<String, dynamic> toJson(PricingMethod method) {
    return {
      'value': method.value,
      'arabicLabel': method.arabicLabel,
      'icon': method.icon,
    };
  }
}