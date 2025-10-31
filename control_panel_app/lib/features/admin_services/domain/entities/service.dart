import 'package:equatable/equatable.dart';
import 'money.dart';
import 'pricing_model.dart';

/// 🛎️ Entity للخدمة
class Service extends Equatable {
  final String id;
  final String propertyId;
  final String propertyName;
  final String name;
  final Money price;
  final PricingModel pricingModel;
  final String icon;
  final String? description;

  const Service({
    required this.id,
    required this.propertyId,
    required this.propertyName,
    required this.name,
    required this.price,
    required this.pricingModel,
    required this.icon,
    this.description,
  });

  @override
  List<Object?> get props => [
        id,
        propertyId,
        propertyName,
        name,
        price,
        pricingModel,
        icon,
        description,
      ];
}